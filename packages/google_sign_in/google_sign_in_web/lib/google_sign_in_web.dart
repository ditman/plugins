import 'dart:async';
import 'dart:html' as html;

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:meta/meta.dart';

import 'src/gapi.dart';
import 'src/utils.dart';

const String _kClientIdMetaSelector = 'meta[name=google-signin-client_id]';
const String _kClientIdAttributeName = 'content';
const List<String> _kJsLibraries = <String>[
  'https://apis.google.com/js/platform.js'
];

/// Implementation of the google_sign_in plugin for Web
class GoogleSignInPlugin extends GoogleSignInPlatform {
  GoogleSignInPlugin() {
    _autoDetectedClientId = html
        .querySelector(_kClientIdMetaSelector)
        ?.getAttribute(_kClientIdAttributeName);

    _isGapiInitialized = injectJSLibraries(_kJsLibraries).then((_) => _initGapi());
  }

  Future<void> _isGapiInitialized;
  String _autoDetectedClientId;

  static void registerWith(Registrar registrar) {
    GoogleSignInPlatform.instance = GoogleSignInPlugin();
  }

  @override
  Future<void> init({@required String hostedDomain, List<String> scopes = const <String>[], SignInOption signInOption = SignInOption.standard, String clientId}) async {
    final String appClientId = clientId ?? _autoDetectedClientId;
    assert(appClientId != null, 'ClientID not set. Either set it on a <meta name="google-signin-client_id" content="CLIENT_ID" /> tag, or pass clientId when calling init()');

    await _isGapiInitialized;

    gapi.auth2.init(Auth2ClientConfig(
        hosted_domain: hostedDomain,
        // The js lib wants a space-separated list of values
        scope: scopes.join(' '),
        client_id: appClientId,
    ));

    return null;
  }

  @override
  Future<GoogleSignInUserData> signInSilently() async {
    final GoogleUser currentUser = await _signIn(Auth2SignInOptions(
      prompt: 'none',
    ));

    return gapiUserToPluginUserData(currentUser);
  }

  @override
  Future<GoogleSignInUserData> signIn() async {
    final GoogleUser currentUser = await _signIn(null);

    return gapiUserToPluginUserData(currentUser);
  }

  @override
  Future<GoogleSignInTokenData> getTokens({@required String email, bool shouldRecoverAuth}) async {
    await _isGapiInitialized;

    final GoogleAuth authInstance = gapi.auth2.getAuthInstance();
    final GoogleUser currentUser = authInstance?.currentUser?.get();
    final Auth2AuthResponse response = currentUser.getAuthResponse();

    return GoogleSignInTokenData(idToken: response.id_token, accessToken: response.access_token);
  }

  @override
  Future<void> signOut() async {
    await _isGapiInitialized;

    return html.promiseToFuture<void>(gapi.auth2.getAuthInstance().signOut());
  }

  @override
  Future<void> disconnect() async {
    await _isGapiInitialized;

    final GoogleAuth authInstance = gapi.auth2.getAuthInstance();
    final GoogleUser currentUser = authInstance?.currentUser?.get();

    return currentUser.disconnect();
  }

  @override
  Future<bool> isSignedIn() async {
    await _isGapiInitialized;

    final GoogleAuth authInstance = gapi.auth2.getAuthInstance();
    final GoogleUser currentUser = authInstance?.currentUser?.get();

    return currentUser.isSignedIn();
  }

  @override
  Future<void> clearAuthCache({String token}) async {
    await _isGapiInitialized;

    final GoogleAuth authInstance = gapi.auth2.getAuthInstance();

    return authInstance.disconnect();
  }

  // This is used both by signIn and signInSilently
  Future<GoogleUser> _signIn(Auth2SignInOptions signInOptions) async {
    await _isGapiInitialized;

    return html.promiseToFuture<GoogleUser>(
        gapi.auth2.getAuthInstance().signIn(signInOptions));

    // return gapi.auth2.getAuthInstance()?.currentUser?.get();
  }

  /// Initialize the global gapi object so 'auth2' can be used.
  /// Returns a promise that resolves when 'auth2' is ready.
  Future<void> _initGapi() {
    final Completer<void> gapiLoadCompleter = Completer<void>();
    gapi.load('auth2', allowInterop(() {
      gapiLoadCompleter.complete();
    }));

    // After this resolves, we can use gapi.auth2!
    return gapiLoadCompleter.future;
  }
}
