import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_sign_in_web/src/gapi.dart';
import 'package:js/js.dart';

const String _kClientIdMetaSelector = 'meta[name=google-signin-client_id]';
const String _kClientIdAttributeName = 'content';
const List<String> _kJsLibraries = <String>[
  'https://apis.google.com/js/platform.js'
];

/// Implementation of the google_sign_in plugin for Web
class GoogleSignInPlugin {
  GoogleSignInPlugin() {
    _autoDetectedClientId = html
        .querySelector(_kClientIdMetaSelector)
        ?.getAttribute(_kClientIdAttributeName);

    _isGapiInitialized =
        Future.wait(_injectJSLibraries(_kJsLibraries)).then(_initGapi);
  }

  Future<void> _isGapiInitialized;
  String _autoDetectedClientId;

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
    await _isGapiInitialized;

    html.window.console.debug(call);

    final GoogleUser currentUser =
        gapi.auth2.getAuthInstance()?.currentUser?.get();

    switch (call.method) {
      case 'init': // void
        return _init(call.arguments)
            .toString(); // Anything serializable, really!
        break;
      case 'signInSilently':
        await _silentSignIn(currentUser, call.arguments);
        return _currentUserToPluginMap(currentUser);
        break;
      case 'signIn':
        await _signIn(call.arguments);
        return _currentUserToPluginMap(currentUser);
        break;
      case 'disconnect':
        currentUser.disconnect();
        return null;
      case 'getTokens':
        final Auth2AuthResponse response = currentUser.getAuthResponse();
        return <String, String>{
          'idToken': response.id_token,
          'accessToken': response.access_token,
        };
        break;
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The google_sign_in plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  Map<String, dynamic> _currentUserToPluginMap(GoogleUser currentUser) {
    assert(currentUser != null);
    final Auth2BasicProfile profile = currentUser.getBasicProfile();
    return <String, dynamic>{
      'displayName': profile?.getName(),
      'email': profile?.getEmail(),
      'id': profile?.getId(),
      'photoUrl': profile?.getImageUrl(),
      'idToken': currentUser?.getAuthResponse()?.id_token,
    };
  }

  // Load the auth2 library
  GoogleAuth _init(dynamic arguments) => gapi.auth2.init(Auth2ClientConfig(
        hostedDomain: arguments['hostedDomain'],
        scope: arguments['scopes'].join(
            ' '), // The backend wants a space-separated list of values, not an array
        clientId: arguments['clientId'] ?? _autoDetectedClientId,
      ));

  Future<dynamic> _signIn(dynamic arguments) async {
    return html.promiseToFuture<dynamic>(gapi.auth2.getAuthInstance().signIn());
  }

  Future<dynamic> _silentSignIn(
      GoogleUser currentUser, dynamic arguments) async {
    return html.promiseToFuture<dynamic>(
        gapi.auth2.getAuthInstance().signIn(Auth2SignInOptions(
              prompt: 'none',
            )));
  }

  Future<void> _initGapi(dynamic _) {
    // JS-interop with the global gapi method and call gapi.load('auth2'), and wait for the
    // promise to resolve...
    final Completer<void> gapiLoadCompleter = Completer<void>();
    gapi.load('auth2', allowInterop(() {
      gapiLoadCompleter.complete();
    }));

    return gapiLoadCompleter
        .future; // After this is resolved, we can use gapi.auth2!
  }

  /// Injects a bunch of libraries in the <head> and returns a
  /// Future that resolves when all load.
  List<Future<void>> _injectJSLibraries(List<String> libraries,
      {Duration timeout}) {
    final List<Future<void>> loading = <Future<void>>[];
    final List<html.HtmlElement> tags = <html.HtmlElement>[];

    libraries.forEach((String library) {
      final html.ScriptElement script = html.ScriptElement()
        ..async = true
        ..defer = true
        ..src = library;
      loading.add(
          script.onLoad.first); // TODO add a timeout race to fail this future
      tags.add(script);
    });
    html.querySelector('head').children.addAll(tags);
    return loading;
  }
}
