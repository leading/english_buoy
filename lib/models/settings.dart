import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  bool isJump = false;
  bool isDark = false;
  bool isAutoplay = true;
  bool isHideFullMastered = false;
  double filertPercent = 70;
  String isHideFullMasteredKey = "hideFullMastered";
  String filertPercentKey = "filertPercent";
  String isJumpKey = "isJump";
  String isDarkKey = "isDark";
  String isAutoplayKey = "isAutoplay";
  SharedPreferences prefs;

  // 构造函数从缓存获取
  Settings() {
    SharedPreferences.getInstance().then((d) {
      prefs = d;
      getFromLocal();
    });
  }

  setIsHideFullMastered(bool v) async {
    await prefs.setBool(isHideFullMasteredKey, v);
    isHideFullMastered = v;
    notifyListeners();
  }

  setIsAutoplay(bool v) async {
    await prefs.setBool(isAutoplayKey, v);
    isAutoplay = v;
    notifyListeners();
  }

  setIsJump(bool v) async {
    await prefs.setBool(isJumpKey, v);
    isJump = v;
    notifyListeners();
  }

  setIsDark(bool v) async {
    await prefs.setBool(isDarkKey, v);
    isDark = v;
    notifyListeners();
  }

  Future setFilertPercent(double v) async {
    filertPercent = v;
    notifyListeners();
    await prefs.setDouble(filertPercentKey, v);
  }

  getFromLocal() async {
    setIsHideFullMastered(prefs.getBool(isHideFullMasteredKey) ?? false);
    setIsJump(prefs.getBool(isJumpKey) ?? false);
    setIsDark(prefs.getBool(isDarkKey) ?? false);
    setIsAutoplay(prefs.getBool(isAutoplayKey) ?? false);

    /*
    if (prefs.containsKey(isAutoplayKey))
      isAutoplay = prefs.getBool(isAutoplayKey);
    else
      isAutoplay = true;
    setIsAutoplay(isAutoplay);
    */

    setFilertPercent(prefs.getDouble(filertPercentKey) ?? 70);
  }
}
