import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import '../model/chat_message_model.dart';
import '../utils/app_config.dart';
import 'local_service.dart';

// Trạng thái đường dây, để màn chat hiện "Đang kết nối..." hay "Mất kết nối".
enum ChatConnectionState { connecting, connected, disconnected }

// Quản lý WebSocket của MỘT phòng chat. Mỗi màn chat tạo một service riêng
// và đóng nó khi thoát màn.
class ChatRealtimeService {
  IOWebSocketChannel? _channel;

  StreamSubscription<dynamic>? _subscription;

  // Tin nhắn mới từ server đổ vào đây; màn chat `listen` để hiện lên.
  final _messages = StreamController<ChatMessageModel>.broadcast();

  Stream<ChatMessageModel> get messages => _messages.stream;

  final _state = StreamController<ChatConnectionState>.broadcast();

  Stream<ChatConnectionState> get state => _state.stream;

  bool get isConnected => _channel != null;

  // Vào phòng chat 1-1 với người có id là [otherUserId].
  Future<void> connectDirect(String otherUserId) {
    // Đổi https:// thành wss:// (http:// thành ws://): cùng server, khác giao thức.
    final base = AppConfig.apiBaseUrl.replaceFirst('http', 'ws');
    return _connect(Uri.parse('$base/chat/direct/$otherUserId/ws'));
  }

  Future<void> _connect(Uri uri) async {
    close();
    _state.add(ChatConnectionState.connecting);

    // 1. Bắt đầu bắt tay. Khác bước 1: gửi kèm accessToken trong header, để Worker
    //    biết mình là ai và kiểm tra hai người có phải bạn bè không.
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': 'Bearer ${LocalService.accessToken}'},
      // Cứ 25 giây gửi một gói ping nhỏ, để nhà mạng không tưởng đường dây đã chết mà cắt.
      pingInterval: const Duration(seconds: 25),
    );

    // 2. Chờ server nhấc máy. Nếu Worker từ chối (không phải bạn bè, token sai…) thì lỗi ở đây.
    try {
      await channel.ready;
    } catch (_) {
      _state.add(ChatConnectionState.disconnected);
      rethrow;
    }
    _channel = channel;
    _state.add(ChatConnectionState.connected);

    // 3. Nghe server gửi xuống. Server gửi JSON dạng {"type":"message","message":{...}}.
    _subscription = channel.stream.listen(
      _onData,
      onDone: _onLost,
      onError: (_) => _onLost(),
    );
  }

  void _onData(dynamic raw) {
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return; // không phải JSON (ví dụ "pong") thì bỏ qua
    }

    // `type` cho biết đây là loại sự kiện gì. Hiện chỉ có "message";
    // bước 4 sẽ thêm "typing" (đang nhập).
    if (event['type'] == 'message') {
      _messages.add(
        ChatMessageModel.fromJson(event['message'] as Map<String, dynamic>),
      );
    }
  }

  // Mất mạng hoặc server ngắt đường dây.
  void _onLost() {
    _channel = null;
    _state.add(ChatConnectionState.disconnected);
  }

  // Gửi một tin nhắn. Không tự thêm vào danh sách ở đây: tin sẽ hiện ra khi server
  // phát lại cho cả phòng, lúc đó mới chắc chắn là server đã nhận.
  void sendMessage(String text) {
    _channel?.sink.add(jsonEncode({'type': 'message', 'text': text}));
  }

  // Thoát phòng: thôi nghe và cúp máy (mã 1000 = đóng bình thường).
  void close() {
    _subscription?.cancel();
    _channel?.sink.close(1000);
    _subscription = null;
    _channel = null;
  }

  // Gọi khi không dùng service nữa (thoát màn chat).
  void dispose() {
    close();
    _messages.close();
    _state.close();
  }
}
