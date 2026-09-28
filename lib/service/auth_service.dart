import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../utils/app_config.dart';

class AuthService {
  AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void> init() {
    return _googleSignIn.initialize(
      clientId: Platform.isIOS && AppConfig.googleIosClientId.isNotEmpty
          ? AppConfig.googleIosClientId
          : null,
      serverClientId: AppConfig.googleWebClientId,
    );
  }

  /// Shows the Google account picker and returns the idToken, or null if the user cancelled.
  static Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();
}
