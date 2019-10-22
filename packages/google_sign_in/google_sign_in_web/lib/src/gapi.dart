@JS()
/// This library implements the global gapi object
library gapi; // Poor man's package:googleapis

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:js/js.dart';

// Global window.gapi, we need to call `load('auth2', cb)` on it...
@JS('gapi')
external Gapi get gapi;

@JS()
abstract class Gapi {
  external void load(String module, Function callback);
  external Auth2 get auth2;
}

@JS()
abstract class Auth2 {
  external GoogleAuth init(Auth2ClientConfig params);
  external GoogleAuth getAuthInstance();
  // todo
  external void authorize(Auth2AuthorizeConfig params, Auth2AuthorizeCallback callback);
}

typedef Auth2AuthorizeCallback = void Function(Auth2AuthorizeResponse response);


@JS()
abstract class Auth2CurrentUser {
  external GoogleUser get();
  external void listen(Auth2CurrentUserListener listener);
}

typedef Auth2CurrentUserListener = void Function(bool);

@JS()
// https://developers.google.com/identity/sign-in/web/reference#gapiauth2initparams
abstract class GoogleAuth {
  external Future<void> then(Function onInit, Function onError);
  // Authentication: https://developers.google.com/identity/sign-in/web/reference#authentication
  external Future<GoogleUser> signIn([Auth2SignInOptions options]);
  external Future<void> signOut();
  external void disconnect();
  // Offline access not implemented
  external void attachClickHandler(html.HtmlElement container, Auth2SignInOptions options, Function onSuccess, Function onFailure);
  external Auth2CurrentUser get currentUser;
}

@JS()
abstract class Auth2BasicProfile {
  external String getId();
  external String getName();
  external String getGivenName();
  external String getFamilyName();
  external String getImageUrl();
  external String getEmail();
}

@JS()
@anonymous
abstract class Auth2AuthResponse {
  external String get access_token;
  external String get id_token;
  external String get scope;
  external num get expires_in;
  external num get first_issued_at;
  external num get expires_at;
}

@JS()
abstract class Auth2AuthorizeResponse {
  external String get access_token;
  external String get id_token;
  external String get code;
  external String get scope;
  external int get expires_in;
  external int get first_issued_at;
  external int get expires_at;
  external String get error;
  external String get error_subtype;
}

@JS()
abstract class GoogleUser {
  external String getId();
  external bool isSignedIn();
  external String getHostedDomain();
  external String getGrantedScopes();
  external Auth2BasicProfile getBasicProfile();
  external Auth2AuthResponse getAuthResponse([bool includeAuthorizationData]);
  external Future<Auth2AuthResponse> reloadAuthResponse();
  external bool hasGrantedScopes(String scopes);
  external void grant(Auth2SignInOptions options);
  // Offline access not implemented
  external void disconnect();
}

@JS()
@anonymous
// https://developers.google.com/identity/sign-in/web/reference#gapiauth2signinoptions
abstract class Auth2SignInOptions {
  external factory Auth2SignInOptions({
    String prompt,
    String scope,
    String uxMode,
    String redirectUri
  });

  external String get prompt;
  external String get scope;
  @JS('ux_mode')
  external String get uxMode;
  @JS('redirect_uri')
  external String get redirectUri;
}

@JS()
@anonymous
/// https://developers.google.com/identity/sign-in/web/reference#gapiauth2clientconfig
abstract class Auth2ClientConfig {
  external factory Auth2ClientConfig({
    String clientId,
    String cookiePolicy,
    String scope,
    bool fetchBasicProfile,
    String hostedDomain,
    String openIdRealm,
    String uxMode,
    String redirectUri
  });

  @JS('client_id')
  external String get clientId;

  @JS('cookie_policy')
  external String get cookiePolicy;

  @JS('scope')
  external String get scope;

  @JS('fetch_basic_profile')
  external bool get fetchBasicProfile;

  @JS('hosted_domain')
  external String get hostedDomain;

  @JS('openid_realm')
  external String get openIdRealm;

  @JS('ux_mode')
  external String get uxMode;

  @JS('redirect_uri')
  external String get redirectUri;
}

@JS()
@anonymous
/// https://developers.google.com/identity/sign-in/web/reference#gapiauth2authorizeconfig
abstract class Auth2AuthorizeConfig {
  external factory Auth2AuthorizeConfig({
    String clientId,
    String scope,
    String responseType,
    String prompt,
    String cookiePolicy,
    String hostedDomain,
    String loginHint,
    String openIdRealm,
    bool includeGrantedScopes,
  });

  @JS('client_id')
  external String get clientId;

  @JS('scope')
  external String get scope;

  @JS('response_type')
  external String get responseType;

  external String get prompt;

  @JS('cookie_policy')
  external String get cookiePolicy;

  @JS('hosted_domain')
  external String get hostedDomain;

  @JS('login_hint')
  external String get loginHint;

  @JS('openid_realm')
  external String get openIdRealm;

  @JS('include_granted_scopes')
  external bool get includeGrantedScopes;
}
