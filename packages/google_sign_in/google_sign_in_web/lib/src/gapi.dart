/// This library describes the global gapi object, and the 'auth2' module
/// as described here: https://developers.google.com/identity/sign-in/web/reference
@JS()
library gapi;

import 'dart:async';
import 'dart:html' as html;

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
  // https://developers.google.com/identity/sign-in/web/reference#gapiauth2initparams
  external GoogleAuth init(Auth2ClientConfig params);
  external GoogleAuth getAuthInstance();
  external void authorize(
      Auth2AuthorizeConfig params, Auth2AuthorizeCallback callback);
}

typedef Auth2AuthorizeCallback = void Function(Auth2AuthorizeResponse response);

@JS()
abstract class Auth2CurrentUser {
  external GoogleUser get();
  external void listen(Auth2CurrentUserListener listener);
}

typedef Auth2CurrentUserListener = void Function(bool);

@JS()
abstract class GoogleAuth {
  external Future<void> then(Function onInit, Function onError);
  // Authentication: https://developers.google.com/identity/sign-in/web/reference#authentication
  external Future<GoogleUser> signIn([Auth2SignInOptions options]);
  external Future<void> signOut();
  external void disconnect();
  // Offline access not implemented
  external void attachClickHandler(html.HtmlElement container,
      Auth2SignInOptions options, Function onSuccess, Function onFailure);
  external Auth2CurrentUser get currentUser;
}

// https://developers.google.com/identity/sign-in/web/reference#googleusergetbasicprofile
@JS()
abstract class Auth2BasicProfile {
  external String getId();
  external String getName();
  external String getGivenName();
  external String getFamilyName();
  external String getImageUrl();
  external String getEmail();
}

// https://developers.google.com/identity/sign-in/web/reference#gapiauth2authresponse
@JS()
abstract class Auth2AuthResponse {
  external String get access_token;
  external String get id_token;
  external String get scope;
  external num get expires_in;
  external num get first_issued_at;
  external num get expires_at;
}

// https://developers.google.com/identity/sign-in/web/reference#gapiauth2authorizeresponse
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

// https://developers.google.com/identity/sign-in/web/reference#users
@JS()
@anonymous
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

// https://developers.google.com/identity/sign-in/web/reference#gapiauth2signinoptions
@JS()
@anonymous
abstract class Auth2SignInOptions {
  external factory Auth2SignInOptions(
      {String prompt, String scope, String ux_mode, String redirect_uri});

  external String get prompt;
  external String get scope;
  external String get ux_mode;
  external String get redirect_uri;
}

// https://developers.google.com/identity/sign-in/web/reference#gapiauth2clientconfig
@JS()
@anonymous
abstract class Auth2ClientConfig {
  external factory Auth2ClientConfig({
    String client_id,
    String cookie_policy,
    String scope,
    bool fetch_basic_profile,
    String hosted_domain,
    String open_id_realm,
    String ux_mode,
    String redirect_uri,
  });

  external String get client_id;
  external String get cookie_policy;
  external String get scope;
  external bool get fetch_basic_profile;
  external String get hosted_domain;
  external String get open_id_realm;
  external String get ux_mode;
  external String get redirect_uri;
}

// https://developers.google.com/identity/sign-in/web/reference#gapiauth2authorizeconfig
@JS()
@anonymous
abstract class Auth2AuthorizeConfig {
  external factory Auth2AuthorizeConfig({
    String client_id,
    String scope,
    String response_type,
    String prompt,
    String cookie_policy,
    String hosted_domain,
    String login_hint,
    String open_id_realm,
    bool include_granted_scopes,
  });

  external String get client_id;
  external String get scope;
  external String get response_type;
  external String get prompt;
  external String get cookie_policy;
  external String get hosted_domain;
  external String get login_hint;
  external String get open_id_realm;
  external bool get include_granted_scopes;
}
