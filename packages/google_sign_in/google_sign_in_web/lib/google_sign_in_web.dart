import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';

import 'src/gapi.dart';

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

    _isGapiInitialized = _injectJSLibraries(_kJsLibraries).then((_) => _initGapi());
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

    final GoogleAuth authInstance = gapi.auth2.getAuthInstance();
    final GoogleUser currentUser = authInstance?.currentUser?.get();

    switch (call.method) {
      case 'init':
        _init(call.arguments);
        return true;
        break;
      case 'signInSilently':
        // TODO: convert call.arguments to an Auth2SignInOptions object (when needed)
        await _signIn(Auth2SignInOptions(
          prompt: 'none',
        ));
        return _currentUserToPluginMap(currentUser);
        break;
      case 'signIn':
        // TODO: convert call.arguments to an Auth2SignInOptions object (when needed)
        await _signIn(null);
        return _currentUserToPluginMap(currentUser);
        break;
      case 'getTokens':
        final Auth2AuthResponse response = currentUser.getAuthResponse();
        return <String, String>{
          'idToken': response.id_token,
          'accessToken': response.access_token,
        };
        break;
      case 'signOut':
        await _signOut();
        return null;
        break;
      case 'disconnect':
        currentUser.disconnect();
        return null;
        break;
      case 'isSignedIn':
        return currentUser.isSignedIn();
        break;
      case 'clearAuthCache':
        // We really don't keep any cache here, but let's try to be drastic:
        authInstance.disconnect();
        return null;
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
        hosted_domain: arguments['hostedDomain'],
        // The js lib wants a space-separated list of values
        scope: arguments['scopes'].join(' '),
        client_id: arguments['clientId'] ?? _autoDetectedClientId,
      ));

  Future<dynamic> _signIn(Auth2SignInOptions signInOptions) async {
    return html.promiseToFuture<dynamic>(
        gapi.auth2.getAuthInstance().signIn(signInOptions));
  }

  Future<void> _signOut() async {
    return html.promiseToFuture<void>(gapi.auth2.getAuthInstance().signOut());
  }

  Future<void> _initGapi() {
    // JS-interop with the global gapi method and call gapi.load('auth2'),
    // then wait for the promise to resolve...
    final Completer<void> gapiLoadCompleter = Completer<void>();
    gapi.load('auth2', allowInterop(() {
      gapiLoadCompleter.complete();
    }));

    // After this is resolved, we can use gapi.auth2!
    return gapiLoadCompleter.future;
  }

  /// Injects a bunch of libraries in the <head> and returns a
  /// Future that resolves when all load.
  Future<void> _injectJSLibraries(List<String> libraries,
      {Duration timeout}) {
    final List<Future<void>> loading = <Future<void>>[];
    final List<html.HtmlElement> tags = <html.HtmlElement>[];

    libraries.forEach((String library) {
      final html.ScriptElement script = html.ScriptElement()
        ..async = true
        ..defer = true
        ..src = library;
      // TODO add a timeout race to fail this future
      loading.add(script.onLoad.first);
      tags.add(script);
    });
    html.querySelector('head').children.addAll(tags);
    return Future.wait(loading);
  }
}
