import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/chat_message_model.dart';
import '../../model/user_model.dart';
import '../../service/chat_realtime_service.dart';
import '../../service/local_service.dart';

class ChatController extends GetxController {
  // Người mình đang chat cùng.
  final UserModel other;

  ChatController(this.other);

  final _realtime = ChatRealtimeService();
  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<ChatConnectionState>? _stateSub;
  StreamSubscription<({String userId, String name, bool isTyping})>? _typingSub;

  final messages = <ChatMessageModel>[].obs;
  final connection = ChatConnectionState.connecting.obs;
  final textController = TextEditingController();
  final canSend = false.obs;

  // Người kia có đang gõ không. Tự tắt sau 5 giây nếu không nhận thêm tín hiệu,
  // phòng khi họ gõ dở rồi thoát app (lúc đó sẽ không bao giờ có tín hiệu "thôi gõ").
  final otherIsTyping = false.obs;
  Timer? _typingTimeout;

  String? get meId => LocalService.user?.id;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() {
      final hasText = textController.text.trim().isNotEmpty;
      canSend.value = hasText;
      // Có chữ = đang gõ, xóa hết = thôi gõ. Service tự lo việc không gửi quá dày.
      _realtime.notifyTyping(hasText);
    });

    // Nghe service: có tin mới thì thêm vào danh sách, đổi trạng thái thì cập nhật.
    _messageSub = _realtime.messages.listen((m) {
      messages.add(m);
      // Người kia đã gửi tin thì chắc chắn họ không còn "đang nhập" nữa.
      if (m.senderId == other.id) _hideTyping();
    });
    _typingSub = _realtime.typing.listen((t) {
      if (t.userId != other.id) return;
      if (!t.isTyping) return _hideTyping();
      otherIsTyping.value = true;
      _typingTimeout?.cancel();
      _typingTimeout = Timer(const Duration(seconds: 5), _hideTyping);
    });
    _stateSub = _realtime.state.listen((s) => connection.value = s);

    connect();
  }

  Future<void> connect() async {
    try {
      await _realtime.connectDirect(other.id);
    } catch (_) {
      // Trạng thái đã chuyển sang "disconnected"; màn chat hiện nút thử lại.
    }
  }

  void _hideTyping() {
    _typingTimeout?.cancel();
    otherIsTyping.value = false;
  }

  void send() {
    final text = textController.text.trim();
    if (text.isEmpty || !_realtime.isConnected) return;
    _realtime.sendMessage(text);
    textController.clear();
  }

  @override
  void onClose() {
    // Thoát màn chat: hủy nghe, đóng đường dây, giải phóng ô nhập.
    _messageSub?.cancel();
    _stateSub?.cancel();
    _typingSub?.cancel();
    _typingTimeout?.cancel();
    _realtime.dispose();
    textController.dispose();
    super.onClose();
  }

  void onBack() {
    Get.back();
  }
}
