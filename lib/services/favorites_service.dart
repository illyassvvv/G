import 'package:flutter/material.dart';
import '../models/channel.dart';

/// In-memory favorites store with a separate channel catalog.
/// Registration is explicit so build() stays side-effect free.
class FavoritesService {
  FavoritesService._();

  static final ValueNotifier<Set<int>> _ids = ValueNotifier<Set<int>>(<int>{});
  static final Map<int, Channel> _catalog = <int, Channel>{};

  static ValueNotifier<Set<int>> get notifier => _ids;

  static void registerChannel(Channel channel) {
    _catalog[channel.id] = channel;
  }

  static void registerChannels(Iterable<Channel> channels) {
    for (final channel in channels) {
      _catalog[channel.id] = channel;
    }
  }

  static bool isFavorite(int channelId) => _ids.value.contains(channelId);

  static void toggle(Channel channel) {
    registerChannel(channel);
    final updated = Set<int>.from(_ids.value);
    if (updated.contains(channel.id)) {
      updated.remove(channel.id);
    } else {
      updated.add(channel.id);
    }
    _ids.value = updated;
  }

  static void toggleById(int channelId) {
    final updated = Set<int>.from(_ids.value);
    if (updated.contains(channelId)) {
      updated.remove(channelId);
    } else {
      updated.add(channelId);
    }
    _ids.value = updated;
  }

  static List<Channel> get favoriteChannels => _ids.value
      .map((id) => _catalog[id])
      .whereType<Channel>()
      .toList(growable: false);
}
