import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void setTabByKey(String key, List tabs) {
    final idx = tabs.indexWhere((t) => t.key == key);
    if (idx >= 0) setTab(idx);
  }
}
