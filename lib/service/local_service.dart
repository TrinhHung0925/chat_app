import 'package:get_storage/get_storage.dart';

import '../model/user_model.dart';

class LocalService {
  LocalService._();

  static const String keyAccessToken = 'access_token';
  static const String keyUser = 'user';

  static final GetStorage _box = GetStorage();

  static Future<void> init() => GetStorage.init();

  static T? read<T>(String key) => _box.read<T>(key);

  static Future<void> write(String key, dynamic value) =>
      _box.write(key, value);

  static Future<void> remove(String key) => _box.remove(key);

  static Future<void> clear() => _box.erase();

  static String? get accessToken => read<String>(keyAccessToken);

  /// Needs both a token and a readable saved user; Home builds the "Tôi" tab from the user.
  static bool get isLoggedIn =>
      (accessToken?.isNotEmpty ?? false) && user != null;

  static UserModel? get user {
    final json = read<Map<String, dynamic>>(keyUser);
    if (json == null) return null;
    try {
      return UserModel.fromJson(json);
    } catch (_) {
      // Saved by an older app version with a different shape: treat as signed out.
      return null;
    }
  }

  static Future<void> saveSession(String accessToken, UserModel user) async {
    await write(keyAccessToken, accessToken);
    await write(keyUser, user.toJson());
  }

  static Future<void> saveUser(UserModel user) => write(keyUser, user.toJson());

  static Future<void> logout() async {
    await remove(keyAccessToken);
    await remove(keyUser);
  }
}
