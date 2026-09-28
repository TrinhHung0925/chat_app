import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/auth_service.dart';
import '../../service/local_service.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;

  Future<void> loginWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final idToken = await AuthService.signInWithGoogle();
      if (idToken == null) return;

      final session = await ApiService.loginWithGoogle(idToken);
      await LocalService.saveSession(session.accessToken, session.user);
      Get.offAllNamed(AppPage.home.routeName);
    } on GoogleSignInException catch (e) {
      Get.snackbar('Đăng nhập thất bại', 'Google: ${e.code.name}');
    } on ApiException catch (e) {
      Get.snackbar('Đăng nhập thất bại', 'Server: ${e.code}');
    } finally {
      isLoading.value = false;
    }
  }

  void onBack() {
    Get.back();
  }
}
