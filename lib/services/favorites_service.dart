import 'package:flutter/material.dart';
import '../models/channel.dart';

/// Simple in-memory favorites store.
/// ValueNotifier lets the UI react instantly when favorites change.
class FavoritesService {
  FavoritesService._();

  static final ValueNotifier<Set<int>> _ids = ValueNotifier({});

  /// Listen to this from widgets to rebuild on change.
  static ValueNotifier<Set<int>> get notifier => _ids;

  static bool isFavorite(int channelId) => _ids.value.contains(channelId);

  static void toggle(int channelId) {
    final updated = Set<int>.from(_ids.value);
    if (updated.contains(channelId)) {
      updated.remove(channelId);
    } else {
      updated.add(channelId);
    }
    _ids.value = updated;
  }

  /// All channels that have been marked favorite (must be cached externally).
  static final List<Channel> _cache = [];

  static void cacheChannel(Channel c) {
    if (!_cache.any((ch) => ch.id == c.id)) _cache.add(c);
  }

  static List<Channel> get favoriteChannels =>
      _cache.where((c) => _ids.value.contains(c.id)).toList();
}
