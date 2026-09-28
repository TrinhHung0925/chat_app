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

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

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
              if (token != null && options.headers['Authorization'] == null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              // An expired or invalid session: drop it and send the user back to Login.
              final isAuthCall = error.requestOptions.path.startsWith('/auth/');
              if (error.response?.statusCode == 401 &&
                  !isAuthCall &&
                  LocalService.isLoggedIn) {
                await LocalService.logout();
                Get.offAllNamed(AppPage.login.routeName);
              }
              handler.next(error);
            },
          ),
        );

  static Future<T> _call<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map && data['error'] is String
          ? data['error'] as String
          : e.type.name;
      throw ApiException(code, e.response?.statusCode);
    }
  }

  /// Exchanges a Google idToken for this app's access token.
  static Future<({String accessToken, UserModel user})> loginWithGoogle(
    String idToken,
  ) {
    return _call(
      () => _dio.post('/auth/google', data: {'idToken': idToken}),
      (data) => (
        accessToken: data['accessToken'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      ),
    );
  }

  static Future<UserModel> getMe() {
    return _call(
      () => _dio.get('/me'),
      (data) => UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
