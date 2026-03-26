import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';
import '../services/channel_service.dart';
import '../widgets/channel_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data
  List<ChannelCategory> _categories = [];
  bool _loadingData = true;
  String? _dataError;

  // Currently selected category index in left sidebar
  int _selectedCatIndex = 0;

  // Focus management for TV remote
  final FocusNode _sidebarFocus = FocusNode();
  final ScrollController _sidebarScrollCtrl = ScrollController();
  final ScrollController _gridScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _sidebarFocus.dispose();
    _sidebarScrollCtrl.dispose();
    _gridScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) {
        setState(() { _categories = cats; _loadingData = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingData = false; _dataError = e.toString(); });
      }
    }
  }

  void _openPlayer(Channel ch) async {
    if (ch.streamUrl.isEmpty) return;
    final prov = context.read<AppProvider>();
    prov.setActiveChannel(ch);
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);

    final intent = AndroidIntent(
      action: 'action_view',
      data: ch.streamUrl,
      type: 'video/*',
      arguments: <String, dynamic>{
        'title': ch.name,
      },
    );
    await intent.launch();
  }

  IconData _catIcon(String name) {
    switch (name) {
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports': return Icons.sports;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'tv': return Icons.tv;
      case 'movie': return Icons.movie;
      case 'music_note': return Icons.music_note;
      case 'news': return Icons.newspaper;
      default: return Icons.live_tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final c = prov.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Ambient glows
        Positioned(top: -120, right: -80,
          child: _glow(AppTheme.accent, 350, prov.isDark ? 0.06 : 0.03)),
        Positioned(bottom: -150, left: -50,
          child: _glow(AppTheme.primaryDark, 300, prov.isDark ? 0.04 : 0.02)),

        // No internet banner
        if (!prov.hasInternet)
          Positioned(top: 0, left: 0, right: 0,
            child: Material(color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.live.withOpacity(0.95),
                      AppTheme.live.withOpacity(0.85),
                    ])),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                  child: Row(children: const [
                    Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text('No internet connection',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 13)),
                  ])))
              .animate()
              .slideY(begin: -1, end: 0, duration: 300.ms))),

        // Main TV layout: sidebar + content grid
        if (_loadingData)
          Center(child: CircularProgressIndicator(color: AppTheme.accent))
        else if (_dataError != null)
          _buildError(c)
        else
          Row(children: [
            // Left sidebar - category list
            _buildSidebar(prov, c),
            // Vertical divider
            Container(width: 1, color: c.border),
            // Right content - channel grid
            Expanded(child: _buildChannelGrid(prov, c)),
          ]),
      ]),
    );
  }

  Widget _buildSidebar(AppProvider prov, TC c) {
    return Container(
      width: 220,
      color: c.surface.withOpacity(0.5),
      child: Column(children: [
        // App title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                    blurRadius: 12, spreadRadius: -2),
                ]),
              child: const Icon(Icons.live_tv_rounded,
                color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            RichText(text: TextSpan(
              style: TextStyle(fontFamily: 'Inter', fontSize: 20,
                fontWeight: FontWeight.w800, color: c.text,
                letterSpacing: -0.5),
              children: const [
                TextSpan(text: 'VarGas'),
                TextSpan(text: 'Tv',
                  style: TextStyle(color: AppTheme.accent)),
              ])),
          ])),
        Divider(height: 1, color: c.border),
        // Category list
        Expanded(
          child: ListView.builder(
            controller: _sidebarScrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = i == _selectedCatIndex;
              return _TVFocusableItem(
                autofocus: i == 0,
                onSelect: () {
                  setState(() => _selectedCatIndex = i);
                  _gridScrollCtrl.jumpTo(0);
                },
                builder: (focused) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: (isSelected || focused)
                        ? LinearGradient(colors: [
                            AppTheme.accent.withOpacity(focused ? 0.25 : 0.12),
                            AppTheme.accent.withOpacity(focused ? 0.15 : 0.06),
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: focused
                          ? AppTheme.accent.withOpacity(0.8)
                          : isSelected
                              ? AppTheme.accent.withOpacity(0.3)
                              : Colors.transparent,
                      width: focused ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(_catIcon(cat.icon),
                      color: (isSelected || focused) ? AppTheme.accent : c.textDim,
                      size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isSelected || focused) ? FontWeight.w700 : FontWeight.w500,
                        color: (isSelected || focused) ? AppTheme.accent : c.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${cat.channels.length}',
                      style: TextStyle(fontSize: 11, color: c.textDim,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
        ),
      ]),
    );
  }

  Widget _buildChannelGrid(AppProvider prov, TC c) {
    if (_categories.isEmpty) return const SizedBox.shrink();
    final cat = _categories[_selectedCatIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(children: [
            Icon(_catIcon(cat.icon), color: AppTheme.accent, size: 24),
            const SizedBox(width: 12),
            Text(cat.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: c.text, letterSpacing: -0.3)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Text('${cat.channels.length} channels',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.accent))),
          ])),
        // Channel grid
        Expanded(
          child: GridView.builder(
            controller: _gridScrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: cat.channels.length,
            itemBuilder: (_, idx) {
              final ch = cat.channels[idx];
              return TVChannelCard(
                channel: ch,
                provider: prov,
                onSelect: () => _openPlayer(ch),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(TC c) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(
          color: c.surface2.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(Icons.cloud_off_rounded,
          color: c.textDim, size: 36)),
      const SizedBox(height: 20),
      Text('Failed to load channels',
        style: TextStyle(color: c.text, fontSize: 17,
          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text('Check your connection and try again',
        style: TextStyle(color: c.textDim, fontSize: 13)),
      const SizedBox(height: 24),
      _TVFocusableItem(
        autofocus: true,
        onSelect: _loadChannels,
        builder: (focused) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? Colors.white : Colors.transparent,
              width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4)),
            ]),
          child: const Text('Retry',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 14))),
      ),
    ]));

  Widget _glow(Color color, double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent])));
}

/// A focusable item for TV remote D-pad navigation.
class _TVFocusableItem extends StatefulWidget {
  final Widget Function(bool focused) builder;
  final VoidCallback onSelect;
  final bool autofocus;

  const _TVFocusableItem({
    required this.builder,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_TVFocusableItem> createState() => _TVFocusableItemState();
}

class _TVFocusableItemState extends State<_TVFocusableItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: widget.builder(_focused),
      ),
    );
  }
}
