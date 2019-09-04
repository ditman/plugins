import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker.dart'; // For types, and the fs FileSystem object

final String _kImagePickerInputsDomId = '__image_picker_web-file-input';
final String _kAcceptImageMimeType = 'image/*';
final String _kAcceptVideoMimeType = 'video/*';


class ImagePickerPlugin {

  static html.Element target;
  static Directory tmpDir;

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'plugins.flutter.io/image_picker',
      const StandardMethodCodec(), 
      registrar.messenger);

    final ImagePickerPlugin instance = ImagePickerPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);

    target = html.querySelector('#${_kImagePickerInputsDomId}');
    if (target == null) {
      final html.Element targetElement = html.Element.tag('flt-image-picker-inputs')
        ..id=_kImagePickerInputsDomId;

      html.querySelector('body').children.add(targetElement);
      target = targetElement;
    }

    tmpDir = fs.systemTempDirectory;
  }

  /// Reads bytes from an html.File
  Future<Uint8List> _readFileContents(html.File file) {
    assert(file != null);

    // Wrap html.FileReader in a Completer
    final Completer<Uint8List> _fileReader = Completer<Uint8List>();
    html.FileReader reader = html.FileReader();

    reader.onLoad.listen((html.ProgressEvent event) {
      final html.FileReader reader = event.target;
      _fileReader.complete(reader.result);
    });
    reader.onError.listen((html.ProgressEvent event) {
      final html.FileReader reader = event.target;
      _fileReader.completeError(reader.error);
    });
    reader.readAsArrayBuffer(file);

    return _fileReader.future;
  }

  /// Handles the OnChange event from a FileUploadInputElement object
  /// Returns the selected file, written to an in-memory FileSystem
  Future<File> _handleOnChangeEvent(html.Event event) async {
    // load the file...
    final html.FileUploadInputElement input = event.target;
    final html.File file = input.files[0];

    if (file != null) {
      final Uint8List result = await _readFileContents(file); // Returns bytes...
      final File output = tmpDir.childFile(file.name);
      output.writeAsBytesSync(result);
      return output;
    }
    return null;
  }

  /// Monitors an <input type="file"> and returns the selected file.
  Future<File> _getSelectedFile(html.FileUploadInputElement input) async {
    // Observe the input until we can return something
    final Completer<File> _completer = Completer<File>();
    input
      .onChange
        .listen((html.Event event) async {
          _completer.complete(_handleOnChangeEvent(event));
        });
    input
      .onError // What other events signal failure?
        .listen((html.Event event) {
          _completer.completeError(event);
        });

    return _completer.future;
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch(call.method) {
      case 'pickImage':
        html.FileUploadInputElement input = _createInputElement(_kAcceptImageMimeType, call.arguments);
        _injectAndActivate(input);
        File file = await _getSelectedFile(input);
        return file.path;
        break;
      case 'pickVideo':
        html.FileUploadInputElement input = _createInputElement(_kAcceptVideoMimeType, call.arguments);
        _injectAndActivate(input);
        File file = await _getSelectedFile(input);
        return file.path;
        break;
      default:
        throw PlatformException(
                code: 'Unimplemented', 
                details: 'The image_picker plugin for web doesn\'t implement the method \'${call.method}\''
              );
    }
  }

  /// Injects the file input element, and clicks on it
  void _injectAndActivate(html.Element element) {
    target.children.clear();
    target.children.add(element);
    element.click();
  }

  html.Element _createInputElement(String accept, dynamic arguments) {
    html.Element element;

    if (arguments['source'] == ImageSource.camera.index) {
      // Capture is not supported by dart:html :/
      element = html.Element.html(
          '<input type="file" accept="$accept" capture />',
          validator: html.NodeValidatorBuilder()
                      ..allowElement(
                        'input', 
                        attributes: ['type', 'accept', 'capture']
                      )
      );
    } else {
      element = html.FileUploadInputElement()
        ..accept = accept;
    }

    return element;
  }
}
