import 'package:get/get.dart';

import '../../model/user_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/auth_service.dart';
import '../../service/local_service.dart';

class HomeController extends GetxController {
  final user = Rxn<UserModel>(LocalService.user);

  @override
  void onInit() {
    super.onInit();
    refreshMe();
  }

  Future<void> refreshMe() async {
    try {
      final me = await ApiService.getMe();
      user.value = me;
      await LocalService.saveUser(me);
    } on ApiException {
      // Keep showing the cached user; a 401 is already handled by the Dio interceptor.
    }
  }

  Future<void> logout() async {
    await AuthService.signOut();
    await LocalService.logout();
    Get.offAllNamed(AppPage.login.routeName);
  }

  void onBack() {
    Get.back();
  }
}
