import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRealtimeService {
  WebSocketChannel? _channel;

  StreamSubscription<dynamic>? _subscription;

  final _messages = StreamController<String>.broadcast();

  Stream<String> get messages => _messages.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String url) async {
    close();

    // 1. Bắt đầu bắt tay với server. Hàm này trả về ngay, lúc server còn chưa trả lời.
    final channel = WebSocketChannel.connect(Uri.parse(url));

    // 2. Chờ server đồng ý kết nối ("nhấc máy").
    await channel.ready;
    _channel = channel;

    // 3. Từ giờ, hàm trong `listen` chạy mỗi khi server gửi xuống một thứ gì đó,
    //    kể cả khi mình không hỏi gì. Đây là điều HTTP không làm được.
    _subscription = channel.stream.listen(
      (message) => _messages.add(message.toString()),
      onDone: () => _channel = null, // server hoặc mạng đã ngắt kết nối
      onError: (_) => _channel = null,
    );
  }

  void send(String text) {
    _channel?.sink.add(text);
  }

  void close() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
