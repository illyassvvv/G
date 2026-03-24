import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';

/// Player display state — single source of truth
enum PlayerState { hidden, mini, expanded, full }

class AppProvider extends ChangeNotifier {
  // ── Preference keys ─────────────────────────────────────────
  static const _keyThemeMode   = 'theme_mode'; // 'system', 'dark', 'light'
  static const _keyLastChId    = 'last_ch_id';
  static const _keyLastChName  = 'last_ch_name';
  static const _keyLastChUrl   = 'last_ch_url';
  static const _keyLastChLogo  = 'last_ch_logo';
  static const _keyLastChNum   = 'last_ch_num';
  static const _keyLastChCat   = 'last_ch_cat';
  static const _keyFavorites   = 'favorites';
  static const _keyRecent      = 'recent_channels';

  // ── Theme ───────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDark = true;

  // ── Connectivity ────────────────────────────────────────────
  bool _hasInternet = true;

  // ── Player state (single source of truth) ───────────────────
  PlayerState _playerState = PlayerState.hidden;
  Channel? _activeChannel;

  // ── Last channel ────────────────────────────────────────────
  int?    _lastChannelId;
  String? _lastChannelName;
  String? _lastChannelUrl;
  String? _lastChannelLogo;
  String? _lastChannelNum;
  String? _lastChannelCat;

  // ── Favorites ───────────────────────────────────────────────
  Set<int> _favoriteIds = {};

  // ── Recently watched ────────────────────────────────────────
  List<Map<String, dynamic>> _recentChannels = [];
  static const _maxRecent = 10;

  // ── Getters ─────────────────────────────────────────────────
  ThemeMode get themeMode    => _themeMode;
  bool get isDark            => _isDark;
  bool get hasInternet       => _hasInternet;
  PlayerState get playerState => _playerState;
  Channel? get activeChannel => _activeChannel;
  int?    get lastChannelId   => _lastChannelId;
  String? get lastChannelName => _lastChannelName;
  String? get lastChannelUrl  => _lastChannelUrl;
  String? get lastChannelLogo => _lastChannelLogo;
  String? get lastChannelNum  => _lastChannelNum;
  String? get lastChannelCat  => _lastChannelCat;
  Set<int> get favoriteIds   => _favoriteIds;
  List<Map<String, dynamic>> get recentChannels => _recentChannels;

  TC get colors => TC(_isDark);

  // ── Init ────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme: default to system
    final themeStr = prefs.getString(_keyThemeMode) ?? 'system';
    switch (themeStr) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        _isDark = true;
        break;
      case 'light':
        _themeMode = ThemeMode.light;
        _isDark = false;
        break;
      default:
        _themeMode = ThemeMode.system;
        _isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }

    // Last channel
    _lastChannelId   = prefs.getInt(_keyLastChId);
    _lastChannelName = prefs.getString(_keyLastChName);
    _lastChannelUrl  = prefs.getString(_keyLastChUrl);
    _lastChannelLogo = prefs.getString(_keyLastChLogo);
    _lastChannelNum  = prefs.getString(_keyLastChNum);
    _lastChannelCat  = prefs.getString(_keyLastChCat);

    // Favorites
    final favJson = prefs.getStringList(_keyFavorites);
    if (favJson != null) {
      _favoriteIds = favJson.map((e) => int.tryParse(e) ?? 0).toSet();
    }

    // Recent channels
    final recentJson = prefs.getString(_keyRecent);
    if (recentJson != null) {
      final decoded = json.decode(recentJson) as List<dynamic>;
      _recentChannels = decoded.cast<Map<String, dynamic>>();
    }

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

    // Listen to system brightness changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        _isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        _applySystemUI();
        notifyListeners();
      }
    };
  }

  // ── Theme ───────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
      _isDark = false;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      _isDark = true;
    } else {
      _themeMode = ThemeMode.system;
      _isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    _applySystemUI();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeMode == ThemeMode.dark ? 'dark' : _themeMode == ThemeMode.light ? 'light' : 'system');
  }

  void _applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDark ? AppTheme.darkBg : AppTheme.lightBg,
    ));
  }

  // ── Player state management ─────────────────────────────────
  void setPlayerState(PlayerState state) {
    _playerState = state;
    notifyListeners();
  }

  void setActiveChannel(Channel? ch) {
    _activeChannel = ch;
    if (ch == null) {
      _playerState = PlayerState.hidden;
    }
    notifyListeners();
  }

  // ── Save last watched channel ───────────────────────────────
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

  // ── Favorites ───────────────────────────────────────────────
  bool isFavorite(int channelId) => _favoriteIds.contains(channelId);

  Future<void> toggleFavorite(int channelId) async {
    if (_favoriteIds.contains(channelId)) {
      _favoriteIds.remove(channelId);
    } else {
      _favoriteIds.add(channelId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, _favoriteIds.map((e) => e.toString()).toList());
  }

  // ── Recently watched ────────────────────────────────────────
  Future<void> addRecentChannel(Channel ch) async {
    // Remove if already exists
    _recentChannels.removeWhere((e) => e['id'] == ch.id);
    // Add to front
    _recentChannels.insert(0, {
      'id': ch.id,
      'name': ch.name,
      'number': ch.number,
      'logo': ch.logoUrl,
      'stream': ch.streamUrl,
      'category': ch.category,
    });
    // Trim to max
    if (_recentChannels.length > _maxRecent) {
      _recentChannels = _recentChannels.sublist(0, _maxRecent);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecent, json.encode(_recentChannels));
  }

  Future<void> removeRecentChannel(int channelId) async {
    _recentChannels.removeWhere((e) => e['id'] == channelId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecent, json.encode(_recentChannels));
  }

  List<Channel> getRecentAsChannels() {
    return _recentChannels.map((e) => Channel(
      id: e['id'] as int,
      name: e['name'] as String,
      number: e['number'] as String,
      logoUrl: e['logo'] as String,
      streamUrl: e['stream'] as String,
      category: e['category'] as String,
    )).toList();
  }

  /// Fully close the player and reset all state
  void closePlayer() {
    _activeChannel = null;
    _playerState = PlayerState.hidden;
    notifyListeners();
  }
}
