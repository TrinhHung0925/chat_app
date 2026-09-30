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

  final messages = <ChatMessageModel>[].obs;
  final connection = ChatConnectionState.connecting.obs;
  final textController = TextEditingController();
  final canSend = false.obs;

  String? get meId => LocalService.user?.id;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(
      () => canSend.value = textController.text.trim().isNotEmpty,
    );

    // Nghe service: có tin mới thì thêm vào danh sách, đổi trạng thái thì cập nhật.
    _messageSub = _realtime.messages.listen(messages.add);
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
    _realtime.dispose();
    textController.dispose();
    super.onClose();
  }

  void onBack() {
    Get.back();
  }
}
