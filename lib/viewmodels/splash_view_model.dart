import 'package:flutter/foundation.dart';

import '../services/app_session_service.dart';
import '../services/greenpoint_api_service.dart';

class SplashDestination {
  const SplashDestination(this.routeName, {this.arguments});

  final String routeName;
  final Object? arguments;
}

class SplashViewModel {
  const SplashViewModel({this.initialization});

  final Future<void>? initialization;

  Future<SplashDestination> resolveDestination() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 850),
    );

    try {
      await Future.wait([
        minimumSplash,
        initialization ?? Future<void>.value(),
      ]);
    } catch (e) {
      debugPrint('App initialization finished with warning: $e');
      await minimumSplash;
    }

    final session = await AppSessionService.restoreValidSession();
    if (session == null) {
      GreenPointApiService.clearAuthToken();
      return const SplashDestination('/welcome');
    }

    GreenPointApiService.restoreAuthToken(session.accessToken);
    return SplashDestination('/dashboard', arguments: {'email': session.email});
  }
}
