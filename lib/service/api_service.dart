import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../model/user_model.dart';
import '../route.dart';
import '../utils/app_config.dart';
import 'local_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String code;

  ApiException(this.code, [this.statusCode]);

  String get message => switch (code) {
    'invalid_username' => 'Tên đăng nhập không hợp lệ',
    'invalid_password' => 'Mật khẩu tối thiểu 6 ký tự',
    'username_taken' => 'Tên đăng nhập đã có người dùng',
    'invalid_credentials' => 'Sai tên đăng nhập hoặc mật khẩu',
    'wrong_current_password' => 'Mật khẩu hiện tại không đúng',
    'invalid_display_name' => 'Tên hiển thị không hợp lệ',
    'connectionTimeout' || 'receiveTimeout' || 'connectionError' => 'Không kết nối được máy chủ',
    _ => 'Có lỗi xảy ra ($code)',
  };

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

typedef Session = ({String accessToken, UserModel user});

class ApiService {
  ApiService._();

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            contentType: Headers.jsonContentType,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final token = LocalService.accessToken;
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              // An expired or invalid session: drop it and send the user back to Login.
              final isAuthCall = error.requestOptions.path.startsWith('/auth/');
              if (error.response?.statusCode == 401 && !isAuthCall && LocalService.isLoggedIn) {
                await LocalService.logout();
                Get.offAllNamed(AppPage.login.routeName);
                Get.snackbar('Phiên đăng nhập đã hết hạn', 'Vui lòng đăng nhập lại');
              }
              handler.next(error);
            },
          ),
        );

  static Future<T> _call<T>(Future<Response<dynamic>> Function() request, T Function(dynamic data) parse) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map && data['error'] is String ? data['error'] as String : e.type.name;
      throw ApiException(code, e.response?.statusCode);
    }
  }

  static Session _parseSession(dynamic data) =>
      (accessToken: data['accessToken'] as String, user: UserModel.fromJson(data['user'] as Map<String, dynamic>));

  static UserModel _parseUser(dynamic data) => UserModel.fromJson(data['user'] as Map<String, dynamic>);

  static Future<Session> register(String username, String password) =>
      _call(() => _dio.post('/auth/register', data: {'username': username, 'password': password}), _parseSession);

  static Future<Session> login(String username, String password) =>
      _call(() => _dio.post('/auth/login', data: {'username': username, 'password': password}), _parseSession);

  static Future<UserModel> getMe() => _call(() => _dio.get('/me'), _parseUser);

  static Future<UserModel> updateDisplayName(String displayName) =>
      _call(() => _dio.patch('/me', data: {'displayName': displayName}), _parseUser);

  static Future<void> changePassword(String currentPassword, String newPassword) => _call(
    () => _dio.put('/me/password', data: {'currentPassword': currentPassword, 'newPassword': newPassword}),
    (_) {},
  );
}
