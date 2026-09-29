import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../model/comment_model.dart';
import '../model/friend_requests_model.dart';
import '../model/page_model.dart';
import '../model/post_model.dart';
import '../model/relationship_model.dart';
import '../model/session_model.dart';
import '../model/user_model.dart';
import '../model/user_profile_model.dart';
import '../route.dart';
import '../utils/app_config.dart';
import 'local_service.dart';

class ApiService {
  ApiService._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthCall = error.requestOptions.path.startsWith('/auth/');
          final isUnauthorized = error.response?.statusCode == 401;
          if (isUnauthorized && !isAuthCall && LocalService.isLoggedIn) {
            await LocalService.logout();
            Get.offAllNamed(AppPage.login.routeName);
            Get.snackbar('Phiên đăng nhập đã hết hạn', 'Vui lòng đăng nhập lại');
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static String _errorMessage(DioException e) {
    final data = e.response?.data;
    final code = data is Map && data['error'] is String
        ? data['error'] as String
        : e.type.name;

    switch (code) {
      case 'invalid_username':
        return 'Tên đăng nhập không hợp lệ';
      case 'invalid_password':
        return 'Mật khẩu tối thiểu 6 ký tự';
      case 'username_taken':
        return 'Tên đăng nhập đã có người dùng';
      case 'invalid_credentials':
        return 'Sai tên đăng nhập hoặc mật khẩu';
      case 'wrong_current_password':
        return 'Mật khẩu hiện tại không đúng';
      case 'invalid_display_name':
        return 'Tên hiển thị không hợp lệ';
      case 'invalid_handle':
        return 'Mã không hợp lệ';
      case 'invalid_content':
        return 'Nội dung không được để trống';
      case 'not_friends':
        return 'Hai bạn chưa là bạn bè';
      case 'post_not_found':
        return 'Bài viết không tồn tại hoặc bạn không có quyền xem';
      case 'comment_not_found':
        return 'Bình luận không tồn tại';
      case 'user_not_found':
        return 'Không tìm thấy người dùng';
      case 'already_friends':
        return 'Hai bạn đã là bạn bè';
      case 'request_already_sent':
        return 'Bạn đã gửi lời mời rồi';
      case 'request_not_found':
        return 'Lời mời không còn nữa';
      case 'handle_taken':
        return 'Mã này đã có người dùng';
      case 'connectionTimeout':
      case 'receiveTimeout':
      case 'connectionError':
        return 'Không kết nối được máy chủ';
      default:
        return 'Có lỗi xảy ra ($code)';
    }
  }

  static Future<SessionModel> register(
    String username,
    String password,
    String displayName,
  ) async {
    try {
      final res = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'displayName': displayName,
        },
      );
      return SessionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<SessionModel> login(String username, String password) async {
    try {
      final res = await dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return SessionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<UserModel> getMe() async {
    try {
      final res = await dio.get('/me');
      return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<UserModel> updateProfile({
    String? displayName,
    String? handle,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (handle != null) body['handle'] = handle;

      final res = await dio.patch('/me', data: body);
      return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await dio.put(
        '/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<List<UserProfileModel>> searchUsers(String query) async {
    try {
      final res = await dio.get('/users/search', queryParameters: {'q': query});
      final list = res.data['users'] as List;
      return list.map((item) {
        final json = item as Map<String, dynamic>;
        return UserProfileModel(
          user: UserModel.fromJson(json),
          relationship: RelationshipModel.fromJson(
            json['relationship'] as Map<String, dynamic>,
          ),
        );
      }).toList();
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final res = await dio.get('/users/$userId');
      final data = res.data as Map<String, dynamic>;
      return UserProfileModel(
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        relationship: RelationshipModel.fromJson(
          data['relationship'] as Map<String, dynamic>,
        ),
        friendCount: data['friendCount'] as int,
        postCount: data['postCount'] as int,
      );
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<List<UserModel>> getFriends() async {
    try {
      final res = await dio.get('/friends');
      final list = res.data['friends'] as List;
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<FriendRequestsModel> getFriendRequests() async {
    try {
      final res = await dio.get('/friends/requests');
      return FriendRequestsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<RelationshipModel> sendFriendRequest(String userId) async {
    try {
      final res = await dio.post('/friends/requests', data: {'userId': userId});
      return RelationshipModel.fromJson(
        res.data['relationship'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> acceptFriendRequest(String requestId) async {
    try {
      await dio.post('/friends/requests/$requestId/accept');
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> deleteFriendRequest(String requestId) async {
    try {
      await dio.delete('/friends/requests/$requestId');
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> unfriend(String userId) async {
    try {
      await dio.delete('/friends/$userId');
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static PageModel<PostModel> _parsePostPage(dynamic data) {
    final items = (data['items'] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PageModel(items, data['nextBefore'] as int?);
  }

  static Future<PageModel<PostModel>> getFeed({int? before}) async {
    try {
      final res = await dio.get(
        '/posts/feed',
        queryParameters: {if (before != null) 'before': before},
      );
      return _parsePostPage(res.data);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PageModel<PostModel>> getUserPosts(
    String userId, {
    int? before,
  }) async {
    try {
      final res = await dio.get(
        '/users/$userId/posts',
        queryParameters: {if (before != null) 'before': before},
      );
      return _parsePostPage(res.data);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PostModel> getPost(String postId) async {
    try {
      final res = await dio.get('/posts/$postId');
      return PostModel.fromJson(res.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PostModel> createPost(String content) async {
    try {
      final res = await dio.post('/posts', data: {'content': content});
      return PostModel.fromJson(res.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PostModel> updatePost(String postId, String content) async {
    try {
      final res = await dio.patch('/posts/$postId', data: {'content': content});
      return PostModel.fromJson(res.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> deletePost(String postId) async {
    try {
      await dio.delete('/posts/$postId');
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PostModel> likePost(String postId) async {
    try {
      final res = await dio.put('/posts/$postId/like');
      return PostModel.fromJson(res.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<PostModel> unlikePost(String postId) async {
    try {
      final res = await dio.delete('/posts/$postId/like');
      return PostModel.fromJson(res.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<List<CommentModel>> getComments(String postId) async {
    try {
      final res = await dio.get('/posts/$postId/comments');
      final list = res.data['comments'] as List;
      return list.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<CommentModel> createComment(String postId, String content) async {
    try {
      final res = await dio.post(
        '/posts/$postId/comments',
        data: {'content': content},
      );
      return CommentModel.fromJson(res.data['comment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    try {
      await dio.delete('/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      throw _errorMessage(e);
    }
  }
}
