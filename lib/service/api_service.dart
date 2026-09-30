import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../model/comment_model.dart';
import '../model/conversation_model.dart';
import '../model/friend_request_model.dart';
import '../model/notification_model.dart';
import '../model/page_model.dart';
import '../model/post_model.dart';
import '../model/presence_model.dart';
import '../model/relationship_model.dart';
import '../model/user_model.dart';
import '../model/user_profile_model.dart';
import '../route.dart';
import '../utils/app_config.dart';
import 'local_service.dart';
import 'push_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String code;

  ApiException(this.code, [this.statusCode]);

  String get message => switch (code) {
        'invalid_username' => 'Tên đăng nhập không hợp lệ',
        'invalid_password' => 'Mật khẩu tối thiểu 6 ký tự',
        'username_taken' => 'Tên đăng nhập đã có người dùng',
        'invalid_credentials' => 'Sai tên đăng nhập hoặc mật khẩu',
        'wrong_current_password' => 'Mật khẩu hiện tại không đúng',
        'invalid_display_name' => 'Tên hiển thị không hợp lệ',
        'invalid_handle' => 'Mã không hợp lệ',
        'invalid_content' => 'Nội dung không được để trống',
        'not_friends' => 'Hai bạn chưa là bạn bè',
        'post_not_found' =>
          'Bài viết không tồn tại hoặc bạn không có quyền xem',
        'comment_not_found' => 'Bình luận không tồn tại',
        'user_not_found' => 'Không tìm thấy người dùng',
        'already_friends' => 'Hai bạn đã là bạn bè',
        'request_already_sent' => 'Bạn đã gửi lời mời rồi',
        'request_not_found' => 'Lời mời không còn nữa',
        'handle_taken' => 'Mã này đã có người dùng',
        'connectionTimeout' ||
        'receiveTimeout' ||
        'connectionError' =>
          'Không kết nối được máy chủ',
        _ => 'Có lỗi xảy ra ($code)',
      };

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

typedef Session = ({String accessToken, UserModel user});

class ApiService {
  ApiService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // An expired or invalid session: drop it and send the user back to Login.
          final isAuthCall = error.requestOptions.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthCall &&
              LocalService.isLoggedIn) {
            await LocalService.logout();
            // Token đăng nhập đã hỏng nên không báo server được; chỉ hủy token push trên máy.
            PushService.instance.stop(notifyServer: false);
            Get.offAllNamed(AppPage.login.routeName);
            Get.snackbar(
              'Phiên đăng nhập đã hết hạn',
              'Vui lòng đăng nhập lại',
            );
          }
          handler.next(error);
        },
      ),
    );

  static Future<T> _call<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map && data['error'] is String
          ? data['error'] as String
          : e.type.name;
      throw ApiException(code, e.response?.statusCode);
    }
  }

  static Session _parseSession(dynamic data) => (
        accessToken: data['accessToken'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );

  static UserModel _parseUser(dynamic data) =>
      UserModel.fromJson(data['user'] as Map<String, dynamic>);

  static Future<Session> register(
    String username,
    String password,
    String displayName,
  ) =>
      _call(
        () => _dio.post(
          '/auth/register',
          data: {
            'username': username,
            'password': password,
            'displayName': displayName,
          },
        ),
        _parseSession,
      );

  static Future<Session> login(String username, String password) => _call(
        () => _dio.post(
          '/auth/login',
          data: {'username': username, 'password': password},
        ),
        _parseSession,
      );

  static Future<UserModel> getMe() => _call(() => _dio.get('/me'), _parseUser);

  /// Sends only the fields that are not null.
  static Future<UserModel> updateProfile({
    String? displayName,
    String? handle,
  }) =>
      _call(
        () => _dio.patch(
          '/me',
          data: {'displayName': displayName, 'handle': handle},
        ),
        _parseUser,
      );

  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) =>
      _call(
        () => _dio.put(
          '/me/password',
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword
          },
        ),
        (_) {},
      );

  // ---------- Users ----------

  static Future<List<UserProfileModel>> searchUsers(String query) => _call(
        () => _dio.get('/users/search', queryParameters: {'q': query}),
        (data) => (data['users'] as List)
            .cast<Map<String, dynamic>>()
            .map(
              (json) => UserProfileModel(
                user: UserModel.fromJson(json),
                relationship: RelationshipModel.fromJson(
                  json['relationship'] as Map<String, dynamic>,
                ),
              ),
            )
            .toList(),
      );

  static Future<UserProfileModel> getUserProfile(String userId) => _call(
        () => _dio.get('/users/$userId'),
        (data) => UserProfileModel(
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
          relationship: RelationshipModel.fromJson(
            data['relationship'] as Map<String, dynamic>,
          ),
          friendCount: data['friendCount'] as int,
          postCount: data['postCount'] as int,
        ),
      );

  // ---------- Friends ----------

  static Future<List<UserModel>> getFriends() => _call(
        () => _dio.get('/friends'),
        (data) => (data['friends'] as List)
            .cast<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList(),
      );

  static Future<
          ({
            List<FriendRequestModel> incoming,
            List<FriendRequestModel> outgoing
          })>
      getFriendRequests() => _call(() => _dio.get('/friends/requests'), (data) {
            List<FriendRequestModel> parse(dynamic list) => (list as List)
                .cast<Map<String, dynamic>>()
                .map(FriendRequestModel.fromJson)
                .toList();
            return (
              incoming: parse(data['incoming']),
              outgoing: parse(data['outgoing']),
            );
          });

  static Future<RelationshipModel> sendFriendRequest(String userId) => _call(
        () => _dio.post('/friends/requests', data: {'userId': userId}),
        (data) => RelationshipModel.fromJson(
          data['relationship'] as Map<String, dynamic>,
        ),
      );

  static Future<void> acceptFriendRequest(String requestId) =>
      _call(() => _dio.post('/friends/requests/$requestId/accept'), (_) {});

  /// Declines an incoming request or cancels an outgoing one.
  static Future<void> deleteFriendRequest(String requestId) =>
      _call(() => _dio.delete('/friends/requests/$requestId'), (_) {});

  static Future<void> unfriend(String userId) =>
      _call(() => _dio.delete('/friends/$userId'), (_) {});

  // ---------- Posts ----------

  static PageModel<PostModel> _parsePostPage(dynamic data) => PageModel(
        (data['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(PostModel.fromJson)
            .toList(),
        data['nextBefore'] as int?,
      );

  static PostModel _parsePost(dynamic data) =>
      PostModel.fromJson(data['post'] as Map<String, dynamic>);

  static Future<PageModel<PostModel>> getFeed({int? before}) => _call(
        () => _dio.get('/posts/feed', queryParameters: {'before': before}),
        _parsePostPage,
      );

  static Future<PageModel<PostModel>> getUserPosts(
    String userId, {
    int? before,
  }) =>
      _call(
        () => _dio
            .get('/users/$userId/posts', queryParameters: {'before': before}),
        _parsePostPage,
      );

  static Future<PostModel> getPost(String postId) =>
      _call(() => _dio.get('/posts/$postId'), _parsePost);

  static Future<PostModel> createPost(String content) =>
      _call(() => _dio.post('/posts', data: {'content': content}), _parsePost);

  static Future<PostModel> updatePost(String postId, String content) => _call(
        () => _dio.patch('/posts/$postId', data: {'content': content}),
        _parsePost,
      );

  static Future<void> deletePost(String postId) =>
      _call(() => _dio.delete('/posts/$postId'), (_) {});

  static Future<PostModel> likePost(String postId) =>
      _call(() => _dio.put('/posts/$postId/like'), _parsePost);

  static Future<PostModel> unlikePost(String postId) =>
      _call(() => _dio.delete('/posts/$postId/like'), _parsePost);

  // ---------- Comments ----------

  static Future<List<CommentModel>> getComments(String postId) => _call(
        () => _dio.get('/posts/$postId/comments'),
        (data) => (data['comments'] as List)
            .cast<Map<String, dynamic>>()
            .map(CommentModel.fromJson)
            .toList(),
      );

  static Future<CommentModel> createComment(String postId, String content) =>
      _call(
        () => _dio.post('/posts/$postId/comments', data: {'content': content}),
        (data) =>
            CommentModel.fromJson(data['comment'] as Map<String, dynamic>),
      );

  static Future<void> deleteComment(String postId, String commentId) =>
      _call(() => _dio.delete('/posts/$postId/comments/$commentId'), (_) {});

  // ---------- Notifications ----------

  static Future<({List<NotificationModel> items, int unreadCount})>
      getNotifications() => _call(
            () => _dio.get('/notifications'),
            (data) => (
              items: (data['notifications'] as List)
                  .cast<Map<String, dynamic>>()
                  .map(NotificationModel.fromJson)
                  .toList(),
              unreadCount: data['unreadCount'] as int,
            ),
          );

  static Future<int> getUnreadNotificationCount() => _call(
        () => _dio.get('/notifications/unread-count'),
        (data) => data['unreadCount'] as int,
      );

  static Future<void> markAllNotificationsRead() =>
      _call(() => _dio.post('/notifications/read-all'), (_) {});

  // ---------- Chat ----------

  // Danh sách chat của mình, mới nhất lên đầu.
  static Future<List<ConversationModel>> getConversations() => _call(
        () => _dio.get('/chat/conversations'),
        (data) => (data['conversations'] as List)
            .cast<Map<String, dynamic>>()
            .map(ConversationModel.fromJson)
            .toList(),
      );

  // Người bạn [userId] có đang hoạt động không (cho dòng chữ dưới tên trên màn chat).
  static Future<PresenceModel> getPresence(String userId) => _call(
        () => _dio.get('/chat/direct/$userId/presence'),
        (data) =>
            PresenceModel.fromJson(data['presence'] as Map<String, dynamic>),
      );

  // ---------- Devices (thông báo đẩy) ----------

  // Báo server: máy có FCM [token] này là của tôi, gửi thông báo của tôi tới đây.
  static Future<void> registerDevice(String token, String platform) => _call(
        () => _dio.post('/devices', data: {'token': token, 'platform': platform}),
        (_) {},
      );

  // Đăng xuất: máy này thôi nhận thông báo của tôi.
  static Future<void> unregisterDevice(String token) => _call(
        () => _dio.delete('/devices', data: {'token': token}),
        (_) {},
      );
}
