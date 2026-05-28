import 'package:flutter/foundation.dart';

class TopupWebViewModel extends ChangeNotifier {
  bool _loading = true;

  bool get loading => _loading;

  void pageStarted() {
    _setLoading(true);
  }

  void pageFinished() {
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}
