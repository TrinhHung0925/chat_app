import 'package:get/get.dart';

class ApiService extends GetConnect {
  static const String apiBaseUrl = '';

  @override
  void onInit() {
    httpClient.baseUrl = apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    super.onInit();
  }
}
