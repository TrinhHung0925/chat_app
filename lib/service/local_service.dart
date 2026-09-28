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

  static bool get isLoggedIn => accessToken?.isNotEmpty ?? false;

  static UserModel? get user {
    final json = read<Map<String, dynamic>>(keyUser);
    return json == null ? null : UserModel.fromJson(json);
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
