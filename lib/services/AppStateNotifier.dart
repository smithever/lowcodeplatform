import 'package:flutter/material.dart';

class ThemeChanger with ChangeNotifier {
  ThemeData _themeData = new ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity);
  MaterialColor _themeColor;

  ThemeChanger(this._themeData, this._themeColor);

  getTheme() => _themeData;
  setTheme(ThemeData theme) {
    _themeData = theme;

    notifyListeners();
  }

  getThemeColor() => _themeColor;
  setThemeColor(MaterialColor color) {
    _themeColor = color;

    notifyListeners();
  }

}

class LayoutChanger with ChangeNotifier {
  bool? _landscape;

  getLandscape() => _landscape;

  setLandscape(bool landscape) {
    _landscape = landscape;
    notifyListeners();
  }
}
