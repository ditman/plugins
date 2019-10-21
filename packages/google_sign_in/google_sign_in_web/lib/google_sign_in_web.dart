import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Implementation of the google_sign_in plugin for Web
class GoogleSignInPlugin {
  GoogleSignInPlugin() {
    _jsLibrariesLoading = _injectJSLibraries(<String>[
      'https://apis.google.com/js/platform.js',
    ])..then(_initGapi);    
  }

  Future<List<void>> _jsLibrariesLoading;

  Future<void> get isJsLoaded => _jsLibrariesLoading;
  
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
        'plugins.flutter.io/google_sign_in',
        const StandardMethodCodec(),
        registrar.messenger);

    final GoogleSignInPlugin instance = GoogleSignInPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    // Await for initialization promises to complete, then do your thing...
    await isJsLoaded;

    html.window.console.log('Doing things! $call');

    switch (call.method) {
      case 'init':
        // Initialize the gapi
        return _init(call.arguments);
        break;
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The google_sign_in plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  // Load the auth2 library
  Future<void> _init(Map<String, dynamic> arguments) {
    // 
  }

  Future<void> _initGapi(List<void> _) {
    // JS-interop with the global gapi method and call gapi.load('auth2'), and wait for the 
    // promise to resolve...
    
  }

  /// Injects a bunch of libraries in the <head> and returns a 
  /// Future that resolves when all load.
  Future<List<void>> _injectJSLibraries(List<String> libraries, { Duration timeout }) {
    final List<Future<void>> loading = <Future<void>>[
      Future<bool>.delayed(const Duration(seconds: 10), () => true) // TODO: Remove this delay before submitting :)
    ];
    final List<html.HtmlElement> tags = <html.HtmlElement>[];

    libraries.forEach((String library) {
      final html.ScriptElement script = html.ScriptElement()
        ..async = true
        ..defer = true
        ..src = library;
      loading.add(script.onLoad.first); // TODO add a timeout race to fail this future
      tags.add(script);
    });
    html.querySelector('head').children.addAll(tags);
    return Future.wait(loading);
  }
}
