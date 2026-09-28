import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screen/home/home_view.dart';
import 'screen/login/login_view.dart';
import 'screen/splash/splash_view.dart';

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

  switch (settings.name) {
    case "/splash":
      return page(settings, () => SplashView());
    case "/login":
      return page(settings, () => LoginView());
    case "/home":
      return page(settings, () => HomeView());

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

enum AppPage { splash, login, home }

extension AppPageExtension on AppPage {
  String get routeName {
    switch (this) {
      case AppPage.splash:
        return '/${AppPage.splash.name}';
      case AppPage.login:
        return '/${AppPage.login.name}';
      case AppPage.home:
        return '/${AppPage.home.name}';
    }
  }
}
