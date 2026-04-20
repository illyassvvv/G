import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/theme_notifier.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/premium_surface.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = dark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary = dark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Design, appearance, and app details.',
                style: TextStyle(
                  color: textSecondary.withOpacity(0.84),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 26),
              _SectionLabel('APPEARANCE', textSecondary),
              const SizedBox(height: 10),
              PremiumSurface(
                borderRadius: BorderRadius.circular(24),
                padding: EdgeInsets.zero,
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) => _ToggleRow(
                    icon: Icons.dark_mode_rounded,
                    iconBg: const Color(0xFF3A1D8D),
                    title: 'Dark Mode',
                    subtitle: 'Ultra-modern premium theme',
                    value: mode == ThemeMode.dark,
                    onChanged: setDarkMode,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _SectionLabel('ABOUT', textSecondary),
              const SizedBox(height: 10),
              PremiumSurface(
                borderRadius: BorderRadius.circular(24),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.play_circle_fill_rounded,
                      iconBg: const Color(0xFF1A56DB),
                      title: 'Streaming',
                      value: 'v3.0',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _divider(dark),
                    _InfoRow(
                      icon: Icons.auto_awesome_rounded,
                      iconBg: const Color(0xFFB45309),
                      title: 'Design',
                      value: 'Luxury motion system',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _divider(dark),
                    _InfoRow(
                      icon: Icons.font_download_rounded,
                      iconBg: const Color(0xFF065F46),
                      title: 'Typography',
                      value: 'Inter-style scale',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _divider(dark),
                    _InfoRow(
                      icon: Icons.code_rounded,
                      iconBg: const Color(0xFF155E75),
                      title: 'Framework',
                      value: 'Flutter',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _SectionLabel('DATA SOURCE', textSecondary),
              const SizedBox(height: 10),
              PremiumSurface(
                borderRadius: BorderRadius.circular(24),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.link_rounded,
                      iconBg: const Color(0xFF1A56DB),
                      title: 'JSON Source',
                      value: 'GitHub / illyassvvv',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _divider(dark),
                    _InfoRow(
                      icon: Icons.sports_soccer_rounded,
                      iconBg: const Color(0xFF1A7A56),
                      title: 'Matches API',
                      value: 'kora-api.space',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool dark) => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(
          height: 1,
          thickness: 0.8,
          color: dark ? Colors.white.withOpacity(0.08) : const Color(0x12000000),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color.withOpacity(0.72),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  const _RowIcon({required this.icon, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _RowIcon(icon: icon, iconBg: iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textSecondary.withOpacity(0.82),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  final Color textSecondary;
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      secondary: _RowIcon(icon: icon, iconBg: iconBg),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textSecondary.withOpacity(0.8),
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
