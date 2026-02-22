import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _isFooterVisible = true;

  int get selectedIndex => _selectedIndex;
  bool get isFooterVisible => _isFooterVisible;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setFooterVisible(bool visible) {
    if (_isFooterVisible != visible) {
      _isFooterVisible = visible;
      notifyListeners();
    }
  }
}
