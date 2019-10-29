// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show required;

import 'google_sign_in_platform_interface.dart';
import 'src/utils.dart';

const MethodChannel _channel =
    MethodChannel('plugins.flutter.io/google_sign_in');

/// An implementation of [GoogleSignInPlatform] that uses method channels.
class MethodChannelGoogleSignIn extends GoogleSignInPlatform {
  @override
  Future<void> init(
      {@required String hostedDomain,
      List<String> scopes = const <String>[],
      SignInOption signInOption = SignInOption.standard,
      String clientId}) async {
    return _channel.invokeMethod<void>('init', <String, dynamic>{
      'signInOption': signInOption.toString(),
      'scopes': scopes,
      'hostedDomain': hostedDomain,
    });
  }

  @override
  Future<GoogleSignInUserData> signInSilently() async {
    return _channel.invokeMapMethod<String, dynamic>('signInSilently').then(
        (Map<String, dynamic> data) => nativeUserDataToPluginUserData(data));
  }

  @override
  Future<GoogleSignInUserData> signIn() async {
    return _channel.invokeMapMethod<String, dynamic>('signIn').then(
        (Map<String, dynamic> data) => nativeUserDataToPluginUserData(data));
  }

  @override
  Future<GoogleSignInTokenData> getTokens(
      {String email, bool shouldRecoverAuth = true}) async {
    return _channel.invokeMapMethod<String, dynamic>(
        'getTokens', <String, dynamic>{
      'email': email,
      'shouldRecoverAuth': shouldRecoverAuth,
    }).then(
        (Map<String, dynamic> data) => nativeTokenDataToPluginTokenData(data));
  }

  @override
  Future<void> signOut() async {
    return _channel.invokeMapMethod<String, dynamic>('signOut');
  }

  @override
  Future<void> disconnect() async {
    return _channel.invokeMapMethod<String, dynamic>('disconnect');
  }

  @override
  Future<bool> isSignedIn() async {
    return _channel.invokeMethod<bool>('isSignedIn');
  }

  @override
  Future<void> clearAuthCache({String token}) async {
    return _channel.invokeMethod<void>(
      'clearAuthCache',
      <String, String>{'token': token},
    );
  }
}
