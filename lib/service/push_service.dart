import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../route.dart';
import 'api_service.dart';

// Thông báo đẩy qua Firebase: hiện lên cả khi app chạy nền hoặc đã tắt hẳn.
// Khi app đang mở thì KHÔNG hiện thông báo hệ thống (mặc định của Firebase), vì app đã có
// banner và badge riêng qua WebSocket (RealtimeService) rồi.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openSub;
  bool _started = false;

  // Gọi khi vào Home (tức là đã đăng nhập).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // 1. Xin quyền hiện thông báo (iOS, và Android 13 trở lên). Người dùng từ chối thì thôi.
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Lấy token của máy và báo cho server "máy này là của tôi".
    //    Firebase thỉnh thoảng cấp token mới, lúc đó báo lại.
    await _register();
    _tokenSub = _messaging.onTokenRefresh.listen(_sendToken);

    // 3. Người dùng bấm vào thông báo:
    //    - lúc app đang chạy nền → onMessageOpenedApp
    //    - lúc app đã tắt hẳn (bấm vào thì app mở lên) → getInitialMessage
    _openSub = FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _open(initial);
  }

  Future<void> _register() async {
    try {
      // iOS: token của Firebase chỉ có sau khi Apple (APNs) cấp token cho máy, nên chờ một chút.
      if (Platform.isIOS) {
        for (var i = 0; i < 10 && await _messaging.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      final token = await _messaging.getToken();
      if (token != null) await _sendToken(token);
    } catch (_) {
      // Không lấy được token (máy ảo không có quyền push, mất mạng...): app vẫn chạy bình thường.
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await ApiService.registerDevice(token, Platform.isIOS ? 'ios' : 'android');
    } on ApiException {
      // Lần mở app sau sẽ gửi lại.
    }
  }

  // Mở màn hình ứng với thông báo, dựa vào `data` mà server gửi kèm.
  Future<void> _open(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] == 'chat_message' && data['senderId'] is String) {
      try {
        final profile = await ApiService.getUserProfile(data['senderId'] as String);
        Get.toNamed(AppPage.chat.routeName, arguments: profile.user);
      } on ApiException catch (e) {
        Get.snackbar('Lỗi', e.message);
      }
    } else if (data['type'] == 'notification') {
      Get.toNamed(AppPage.notifications.routeName);
    }
  }

  // Gọi khi đăng xuất: máy này thôi nhận thông báo của tài khoản vừa thoát.
  // [notifyServer] = false khi phiên đã hết hạn (token đăng nhập hỏng, gọi server cũng bị từ chối).
  Future<void> stop({bool notifyServer = true}) async {
    _started = false;
    await _tokenSub?.cancel();
    await _openSub?.cancel();
    _tokenSub = null;
    _openSub = null;
    try {
      final token = await _messaging.getToken();
      if (notifyServer && token != null) await ApiService.unregisterDevice(token);
      // Hủy luôn token trên máy: kể cả khi server chưa kịp xóa, token cũ cũng không dùng được nữa.
      await _messaging.deleteToken();
    } catch (_) {
      // Đăng xuất vẫn phải thành công dù bước này lỗi.
    }
  }
}
