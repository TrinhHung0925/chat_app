import 'package:get_storage/get_storage.dart';

class LocalService {
  LocalService._();

  static final GetStorage _box = GetStorage();

  static Future<void> init() => GetStorage.init();

  static T? read<T>(String key) => _box.read<T>(key);

  static Future<void> write(String key, dynamic value) => _box.write(key, value);

  static Future<void> remove(String key) => _box.remove(key);

  static Future<void> clear() => _box.erase();
}
