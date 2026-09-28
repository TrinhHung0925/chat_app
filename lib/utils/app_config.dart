abstract class AppConfig {
  static const String apiBaseUrl = 'https://chat-app.hung09112000.workers.dev';

  /// Web OAuth client. Passed as serverClientId so the Google idToken's `aud` is this ID,
  /// which is what the backend checks (GOOGLE_CLIENT_IDS in backend/wrangler.jsonc).
  static const String googleWebClientId =
      '984366939036-iko5hvk3cl8tfo5k36qurvs9qrhaof42.apps.googleusercontent.com';

  /// iOS OAuth client (bundle ID com.hungtv.chatapp). Android needs no client ID in code:
  /// Google matches the Android client by package name + SHA-1.
  static const String googleIosClientId = '';
}
