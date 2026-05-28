import 'package:flutter/foundation.dart';

class SplashViewModel {
  const SplashViewModel({this.initialization});

  final Future<void>? initialization;

  Future<void> waitUntilReady() async {
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
  }
}
