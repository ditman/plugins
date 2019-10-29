// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required;

import 'method_channel_google_sign_in.dart';

enum SignInOption { standard, games }

class GoogleSignInUserData {
  GoogleSignInUserData({
    this.displayName, this.email, this.id, this.photoUrl, this.idToken
  });
  String displayName;
  String email;
  String id;
  String photoUrl;
  String idToken;
}

class GoogleSignInTokenData {
  GoogleSignInTokenData({this.idToken, this.accessToken});
  String idToken;
  String accessToken;
}

/// The interface that implementations of google_sign_in must implement.
///
/// Platform implementations that live in a separate package should extend this
/// class rather than implement it as `google_sign_in` does not consider newly
/// added methods to be breaking changes. Extending this class (using `extends`)
/// ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by
/// newly added [GoogleSignInPlatform] methods.
abstract class GoogleSignInPlatform {
  /// The default instance of [GoogleSignInPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [GoogleSignInPlatform] when they
  /// register themselves.
  ///
  /// Defaults to [MethodChannelGoogleSignIn].
  static GoogleSignInPlatform instance = MethodChannelGoogleSignIn();

  Future<void> init({@required String hostedDomain, List<String> scopes, SignInOption signInOption, String clientId}) async {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<GoogleSignInUserData> signInSilently() async {
    throw UnimplementedError('signInSilently() has not been implemented.');
  }

  Future<GoogleSignInUserData> signIn() async {
    throw UnimplementedError('signIn() has not been implemented.');
  }

  Future<GoogleSignInTokenData> getTokens({@required String email, bool shouldRecoverAuth}) async {
    throw UnimplementedError('getTokens() has not been implemented.');
  }

  Future<void> signOut() async {
    throw UnimplementedError('signOut() has not been implemented.');
  }

  Future<void> disconnect() async {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Future<bool> isSignedIn() async {
    throw UnimplementedError('isSignedIn() has not been implemented.');
  }

  Future<void> clearAuthCache({@required String token}) async {
    throw UnimplementedError('clearAuthCache() has not been implemented.');
  }
}
