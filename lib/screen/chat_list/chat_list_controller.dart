import 'dart:async';

import 'package:get/get.dart';

import '../../model/conversation_model.dart';
import '../../model/presence_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';
import '../../service/realtime_service.dart';

class ChatListController extends GetxController {
  final conversations = <ConversationModel>[].obs;
  final isLoading = true.obs;
  StreamSubscription<String>? _live;
  StreamSubscription<({String userId, PresenceModel presence})>? _presenceSub;

  String? get meId => LocalService.user?.id;

  // Tổng số tin chưa đọc, hiện thành số đỏ trên tab Chat.
  int get totalUnread => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  void onInit() {
    super.onInit();
    load();
    // Có tin mới ở bất kỳ cuộc trò chuyện nào thì tải lại danh sách
    // (để tin cuối, thứ tự và số chưa đọc luôn đúng).
    _live = RealtimeService.instance.chatUpdates.listen((_) => load());
    // Bạn bè vào / rời app: chỉ đổi đúng dòng của người đó, không cần tải lại cả danh sách.
    _presenceSub = RealtimeService.instance.presence.listen((p) {
      final i = conversations.indexWhere((c) => c.other.id == p.userId);
      if (i >= 0) conversations[i] = conversations[i].copyWithPresence(p.presence);
    });
  }

  @override
  void onClose() {
    _live?.cancel();
    _presenceSub?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    try {
      conversations.assignAll(await ApiService.getConversations());
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> open(ConversationModel c) async {
    await Get.toNamed(AppPage.chat.routeName, arguments: c.other);
    // Quay lại từ màn chat: tải lại để số chưa đọc về 0 và tin cuối được cập nhật.
    await load();
  }

  void onBack() {
    Get.back();
  }
}
