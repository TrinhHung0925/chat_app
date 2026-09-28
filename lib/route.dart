import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'model/post_model.dart';
import 'screen/home/home_view.dart';
import 'screen/login/login_view.dart';
import 'screen/post_detail/post_detail_view.dart';
import 'screen/post_editor/post_editor_view.dart';
import 'screen/profile/profile_view.dart';
import 'screen/register/register_view.dart';
import 'screen/search_user/search_user_view.dart';
import 'screen/splash/splash_view.dart';
import 'screen/user_profile/user_profile_view.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  GetPageRoute page(
    RouteSettings settings,
    Widget Function() genPage, [
    Bindings? bindings,
  ]) {
    var page = GetPage(
      name: settings.name!,
      page: genPage,
      arguments: settings.arguments,
      binding: bindings,
    );
    return PageRedirect(route: page, unknownRoute: page).page();
  }

  // Screens that can be open more than once at the same time get a unique controller tag.
  // It is created here, once per navigation, not inside the page builder.
  final tag = DateTime.now().microsecondsSinceEpoch.toString();

  switch (settings.name) {
    case "/splash":
      return page(settings, () => SplashView());
    case "/login":
      return page(settings, () => LoginView());
    case "/register":
      return page(settings, () => RegisterView());
    case "/home":
      return page(settings, () => HomeView());
    case "/profile":
      return page(settings, () => ProfileView());
    case "/userProfile":
      return page(
        settings,
        () => UserProfileView(userId: settings.arguments as String, tag: tag),
      );
    case "/searchUser":
      return page(settings, () => SearchUserView());
    case "/postEditor":
      return page(
        settings,
        () => PostEditorView(post: settings.arguments as PostModel?),
      );
    case "/postDetail":
      return page(
        settings,
        () => PostDetailView(post: settings.arguments as PostModel, tag: tag),
      );

    default:
      return page(
        settings,
        () => Scaffold(
          appBar: AppBar(title: const Text('404')),
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}

enum AppPage {
  splash,
  login,
  register,
  home,
  profile,
  userProfile,
  searchUser,
  postEditor,
  postDetail,
}

extension AppPageExtension on AppPage {
  String get routeName {
    switch (this) {
      case AppPage.splash:
        return '/${AppPage.splash.name}';
      case AppPage.login:
        return '/${AppPage.login.name}';
      case AppPage.register:
        return '/${AppPage.register.name}';
      case AppPage.home:
        return '/${AppPage.home.name}';
      case AppPage.profile:
        return '/${AppPage.profile.name}';
      case AppPage.userProfile:
        return '/${AppPage.userProfile.name}';
      case AppPage.searchUser:
        return '/${AppPage.searchUser.name}';
      case AppPage.postEditor:
        return '/${AppPage.postEditor.name}';
      case AppPage.postDetail:
        return '/${AppPage.postDetail.name}';
    }
  }
}
