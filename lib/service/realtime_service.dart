import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';

import '../model/notification_model.dart';
import '../route.dart';
import '../utils/app_config.dart';
import 'api_service.dart';
import 'local_service.dart';

class RealtimeService with WidgetsBindingObserver {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  final unreadCount = 0.obs;
  final _notifications = StreamController<NotificationModel>.broadcast();

  /// New notifications as they arrive, for screens that want to refresh.
  Stream<NotificationModel> get notifications => _notifications.stream;

  // Có tin nhắn mới ở một cuộc trò chuyện (id phòng). Tab Chat nghe để tải lại danh sách.
  final _chatUpdates = StreamController<String>.broadcast();

  Stream<String> get chatUpdates => _chatUpdates.stream;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    _connect();
    refreshUnreadCount();
  }

  void stop() {
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    _close();
    unreadCount.value = 0;
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await ApiService.getUnreadNotificationCount();
    } on ApiException {
      // Not critical; the next event or screen load corrects it.
    }
  }

  // iOS/Android suspend the socket in the background, so close it there and reconnect on return.
  // Events sent while away are not lost: they are saved in D1, and the count is refetched.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.resumed) {
      _attempt = 0;
      _connect();
      refreshUnreadCount();
    } else if (state == AppLifecycleState.paused) {
      _close();
    }
  }

  Future<void> _connect() async {
    _close();
    final token = LocalService.accessToken;
    if (!_running || token == null) return;

    final uri =
        Uri.parse('${AppConfig.apiBaseUrl.replaceFirst('http', 'ws')}/ws');
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': 'Bearer $token'},
      // Keeps mobile networks and proxies from dropping an idle connection.
      pingInterval: const Duration(seconds: 25),
    );
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      if (_channel == channel) _scheduleRetry();
      return;
    }
    if (_channel != channel) return;
    _attempt = 0;
    _subscription = channel.stream.listen(_onMessage,
        onDone: _scheduleRetry, onError: (_) => _scheduleRetry());
  }

  /// Waits 1, 2, 4 … up to 30 seconds between attempts, so a server outage is not hammered.
  void _scheduleRetry() {
    if (!_running) return;
    _retryTimer?.cancel();
    final delay = Duration(seconds: min(30, 1 << _attempt));
    _attempt = min(_attempt + 1, 5);
    _retryTimer = Timer(delay, _connect);
  }

  void _close() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _retryTimer = null;
    _subscription = null;
    _channel = null;
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final count = message['unreadCount'];
    if (count is int) unreadCount.value = count;

    // ChatRoom báo qua UserHub khi có tin nhắn mới cho mình.
    if (message['event'] == 'chat_message') {
      _chatUpdates.add(message['conversationId'] as String);
      return;
    }

    if (message['event'] == 'notification') {
      final notification = NotificationModel.fromJson(
          message['notification'] as Map<String, dynamic>);
      _notifications.add(notification);
      _showBanner(notification);
    }
  }

  void _showBanner(NotificationModel n) {
    Get.snackbar(
      n.actor.displayName,
      n.action,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.notifications_active),
      onTap: (_) => Get.toNamed(AppPage.notifications.routeName),
    );
  }
}
