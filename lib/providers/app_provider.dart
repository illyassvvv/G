import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/theme.dart';

class AppProvider extends ChangeNotifier {
  static const _keyDark      = 'is_dark';
  static const _keyLastChId  = 'last_ch_id';
  static const _keyLastChName= 'last_ch_name';
  static const _keyLastChUrl = 'last_ch_url';
  static const _keyLastChLogo= 'last_ch_logo';
  static const _keyLastChNum = 'last_ch_num';
  static const _keyLastChCat = 'last_ch_cat';

  bool _isDark = true;
  bool _hasInternet = true;
  int?    _lastChannelId;
  String? _lastChannelName;
  String? _lastChannelUrl;
  String? _lastChannelLogo;
  String? _lastChannelNum;
  String? _lastChannelCat;

  bool get isDark       => _isDark;
  bool get hasInternet  => _hasInternet;
  int?    get lastChannelId   => _lastChannelId;
  String? get lastChannelName => _lastChannelName;
  String? get lastChannelUrl  => _lastChannelUrl;
  String? get lastChannelLogo => _lastChannelLogo;
  String? get lastChannelNum  => _lastChannelNum;
  String? get lastChannelCat  => _lastChannelCat;

  TC get colors => TC(_isDark);

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark          = prefs.getBool(_keyDark) ?? true;
    _lastChannelId   = prefs.getInt(_keyLastChId);
    _lastChannelName = prefs.getString(_keyLastChName);
    _lastChannelUrl  = prefs.getString(_keyLastChUrl);
    _lastChannelLogo = prefs.getString(_keyLastChLogo);
    _lastChannelNum  = prefs.getString(_keyLastChNum);
    _lastChannelCat  = prefs.getString(_keyLastChCat);
    _applySystemUI();
    notifyListeners();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected != _hasInternet) {
        _hasInternet = connected;
        notifyListeners();
      }
    });
  }

  // ── Theme toggle ──────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    _applySystemUI();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, _isDark);
  }

  void _applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDark ? AppTheme.darkBg : AppTheme.lightBg,
    ));
  }

  // ── Save last watched channel ─────────────────────────────────
  Future<void> saveLastChannel({
    required int id,
    required String name,
    required String url,
    required String logo,
    required String number,
    required String category,
  }) async {
    _lastChannelId   = id;
    _lastChannelName = name;
    _lastChannelUrl  = url;
    _lastChannelLogo = logo;
    _lastChannelNum  = number;
    _lastChannelCat  = category;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastChId, id);
    await prefs.setString(_keyLastChName, name);
    await prefs.setString(_keyLastChUrl, url);
    await prefs.setString(_keyLastChLogo, logo);
    await prefs.setString(_keyLastChNum, number);
    await prefs.setString(_keyLastChCat, category);
  }

  Future<void> clearLastChannel() async {
    _lastChannelId   = null;
    _lastChannelName = null;
    _lastChannelUrl  = null;
    _lastChannelLogo = null;
    _lastChannelNum  = null;
    _lastChannelCat  = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastChId);
    await prefs.remove(_keyLastChName);
    await prefs.remove(_keyLastChUrl);
    await prefs.remove(_keyLastChLogo);
    await prefs.remove(_keyLastChNum);
    await prefs.remove(_keyLastChCat);
  }
}
