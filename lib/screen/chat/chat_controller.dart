import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/chat_message_model.dart';
import '../../model/user_model.dart';
import '../../service/chat_realtime_service.dart';
import '../../service/local_service.dart';

// Trạng thái tin cuối cùng mình gửi, hiện ngay dưới tin đó.
enum MessageStatus { sent, delivered, seen }

// WidgetsBindingObserver: để biết lúc app quay lại từ chạy nền (khi đó mới tính là "đã xem").
class ChatController extends GetxController with WidgetsBindingObserver {
  // Người mình đang chat cùng.
  final UserModel other;

  ChatController(this.other);

  final _realtime = ChatRealtimeService();
  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<ChatConnectionState>? _stateSub;
  StreamSubscription<List<ChatMessageModel>>? _historySub;
  StreamSubscription<({String userId, String name, bool isTyping})>? _typingSub;
  StreamSubscription<({String userId, int deliveredAt, int readAt})>?
      _receiptSub;

  // Mốc của người kia: tin nào của mình gửi lúc <= mốc thì họ đã nhận / đã xem.
  final otherDeliveredAt = 0.obs;
  final otherReadAt = 0.obs;

  final messages = <ChatMessageModel>[].obs;
  final connection = ChatConnectionState.connecting.obs;
  final textController = TextEditingController();
  final canSend = false.obs;

  // Người kia có đang gõ không. Tự tắt sau 5 giây nếu không nhận thêm tín hiệu,
  // phòng khi họ gõ dở rồi thoát app (lúc đó sẽ không bao giờ có tín hiệu "thôi gõ").
  final otherIsTyping = false.obs;
  Timer? _typingTimeout;

  String? get meId => LocalService.user?.id;

  // Tin cuối cùng mình gửi (null nếu mình chưa gửi tin nào).
  ChatMessageModel? get lastMine {
    for (final m in messages.reversed) {
      if (m.senderId == meId) return m;
    }
    return null;
  }

  MessageStatus statusOf(ChatMessageModel m) {
    if (otherReadAt.value >= m.createdAt) return MessageStatus.seen;
    if (otherDeliveredAt.value >= m.createdAt) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  // App đang hiện trên màn hình (không phải chạy nền, không bị che bởi màn khóa...).
  bool get _isVisible =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void _markReadIfVisible() {
    if (_isVisible) _realtime.markRead();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    textController.addListener(() {
      final hasText = textController.text.trim().isNotEmpty;
      canSend.value = hasText;
      // Có chữ = đang gõ, xóa hết = thôi gõ. Service tự lo việc không gửi quá dày.
      _realtime.notifyTyping(hasText);
    });

    // Nghe service: có tin mới thì thêm vào danh sách, đổi trạng thái thì cập nhật.
    _messageSub = _realtime.messages.listen((m) {
      messages.add(m);
      if (m.senderId == other.id) {
        // Người kia đã gửi tin thì chắc chắn họ không còn "đang nhập" nữa.
        _hideTyping();
        // Mình đang mở màn chat và thấy tin này ngay: báo "đã xem".
        _markReadIfVisible();
      }
    });
    // Lịch sử thay thế toàn bộ danh sách: vào lại phòng hay kết nối lại đều không bị trùng tin.
    _historySub = _realtime.history.listen((list) {
      messages.assignAll(list);
      _markReadIfVisible();
    });
    // Chỉ quan tâm mốc của người kia; mốc của chính mình thì mình biết rồi.
    _receiptSub = _realtime.receipts.listen((r) {
      if (r.userId != other.id) return;
      otherDeliveredAt.value = r.deliveredAt;
      otherReadAt.value = r.readAt;
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

  // Quay lại app khi màn chat vẫn đang mở: những tin tới lúc chạy nền giờ mới được xem.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _realtime.markRead();
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
    _historySub?.cancel();
    _receiptSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _typingTimeout?.cancel();
    _realtime.dispose();
    textController.dispose();
    super.onClose();
  }

  void onBack() {
    Get.back();
  }
}
