import 'dart:async';
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
  static const _keyThemeMode   = 'theme_mode';
  static const _keyLastChId    = 'last_ch_id';
  static const _keyLastChName  = 'last_ch_name';
  static const _keyLastChUrl   = 'last_ch_url';
  static const _keyLastChLogo  = 'last_ch_logo';
  static const _keyLastChNum   = 'last_ch_num';
  static const _keyLastChCat   = 'last_ch_cat';
  static const _keyVolume      = 'volume_level';
  static const _keyDataSaver   = 'data_saver';
  static const _keyFavorites   = 'favorite_ids';

  // ── Theme ───────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDark = true;

  // ── Cached SharedPreferences (avoids repeated getInstance calls) ──
  SharedPreferences? _prefs;

  // ── Connectivity ────────────────────────────────────────────
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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

  // ── Volume level ────────────────────────────────────────────
  double _volumeLevel = 1.0;

  // ── Data saver mode ─────────────────────────────────────────
  bool _dataSaverEnabled = false;

  // ── Favorites ─────────────────────────────────────────────
  Set<int> _favoriteIds = {};

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
  double get volumeLevel     => _volumeLevel;
  bool get dataSaverEnabled  => _dataSaverEnabled;
  Set<int> get favoriteIds   => _favoriteIds;

  TC get colors => TC(_isDark);

  /// Returns the last watched channel as a [Channel] object, or null.
  Channel? get lastChannel {
    if (_lastChannelId == null ||
        _lastChannelUrl == null ||
        _lastChannelUrl!.isEmpty) {
      return null;
    }
    return Channel(
      id: _lastChannelId!,
      name: _lastChannelName ?? 'Unknown',
      number: _lastChannelNum ?? '00',
      logoUrl: _lastChannelLogo ?? '',
      streamUrl: _lastChannelUrl!,
      category: _lastChannelCat ?? '',
    );
  }

  // ── Init ────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await _getPrefs();

    // Theme: default to dark for TV
    final themeStr = prefs.getString(_keyThemeMode) ?? 'dark';
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

    // Volume level
    _volumeLevel = prefs.getDouble(_keyVolume) ?? 1.0;

    // Data saver
    _dataSaverEnabled = prefs.getBool(_keyDataSaver) ?? false;

    // Favorites
    final favList = prefs.getStringList(_keyFavorites) ?? [];
    _favoriteIds = favList.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toSet();

    _applySystemUI();
    notifyListeners();

    // Listen to connectivity changes — cancel any previous subscription first
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
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

  // ── Cached prefs helper ───────────────────────────────────
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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
    final prefs = await _getPrefs();
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
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.setInt(_keyLastChId, id),
      prefs.setString(_keyLastChName, name),
      prefs.setString(_keyLastChUrl, url),
      prefs.setString(_keyLastChLogo, logo),
      prefs.setString(_keyLastChNum, number),
      prefs.setString(_keyLastChCat, category),
    ]);
  }

  Future<void> clearLastChannel() async {
    _lastChannelId   = null;
    _lastChannelName = null;
    _lastChannelUrl  = null;
    _lastChannelLogo = null;
    _lastChannelNum  = null;
    _lastChannelCat  = null;
    notifyListeners();
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.remove(_keyLastChId),
      prefs.remove(_keyLastChName),
      prefs.remove(_keyLastChUrl),
      prefs.remove(_keyLastChLogo),
      prefs.remove(_keyLastChNum),
      prefs.remove(_keyLastChCat),
    ]);
  }

  // ── Volume level ────────────────────────────────────────────
  Future<void> saveVolume(double volume) async {
    _volumeLevel = volume;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyVolume, volume);
  }

  // ── Favorites ────────────────────────────────────────────────
  bool isFavorite(int channelId) => _favoriteIds.contains(channelId);

  Future<void> toggleFavorite(int channelId) async {
    if (_favoriteIds.contains(channelId)) {
      _favoriteIds.remove(channelId);
    } else {
      _favoriteIds.add(channelId);
    }
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _keyFavorites,
      _favoriteIds.map((id) => id.toString()).toList(),
    );
  }

  // ── Data saver mode ─────────────────────────────────────────
  Future<void> toggleDataSaver() async {
    _dataSaverEnabled = !_dataSaverEnabled;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs.setBool(_keyDataSaver, _dataSaverEnabled);
  }

  /// Fully close the player and reset all state
  void closePlayer() {
    _activeChannel = null;
    _playerState = PlayerState.hidden;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    super.dispose();
  }
}
