import 'package:flutter/foundation.dart';

class MainTabViewModel extends ChangeNotifier {
  MainTabViewModel({required this.maxIndex, required int initialIndex})
    : _selectedIndex = _normalizeIndex(initialIndex, maxIndex);

  final int maxIndex;
  late final List<bool> _initializedPages = List<bool>.filled(
    maxIndex + 1,
    false,
  );
  int _selectedIndex;

  int get selectedIndex => _selectedIndex;
  List<bool> get initializedPages => List.unmodifiable(_initializedPages);

  void ensurePage(int index) {
    _initializedPages[_normalizeIndex(index, maxIndex)] = true;
  }

  void updateInitialIndex(int index) {
    final nextIndex = _normalizeIndex(index, maxIndex);
    ensurePage(nextIndex);
    if (_selectedIndex == nextIndex) return;
    _selectedIndex = nextIndex;
    notifyListeners();
  }

  void selectTab(int index) {
    final nextIndex = _normalizeIndex(index, maxIndex);
    if (_selectedIndex == nextIndex) return;

    ensurePage(nextIndex);
    _selectedIndex = nextIndex;
    notifyListeners();
  }

  static int _normalizeIndex(int index, int maxIndex) {
    if (index < 0) return 0;
    if (index > maxIndex) return maxIndex;
    return index;
  }
}
