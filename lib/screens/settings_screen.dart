import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/theme.dart';
import '../core/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surface : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final dividerColor = isDark ? const Color(0x14FFFFFF) : const Color(0x18000000);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: TextStyle(
                color: textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            // ─── APPEARANCE ───
            _SectionLabel('APPEARANCE', textSecondary),
            const SizedBox(height: 8),
            _SettingsGroup(surface: surface, children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => _ToggleRow(
                  icon: Icons.dark_mode_rounded,
                  iconBg: const Color(0xFF2D1766),
                  title: 'Dark Mode',
                  value: mode == ThemeMode.dark,
                  onChanged: setDarkMode,
                  textPrimary: textPrimary,
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ─── ABOUT ───
            _SectionLabel('ABOUT', textSecondary),
            const SizedBox(height: 8),
            _SettingsGroup(surface: surface, children: [
              _InfoRow(
                icon: Icons.play_circle_fill_rounded,
                iconBg: const Color(0xFF1A56DB),
                title: 'Streaming',
                value: 'v3.0',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _divider(dividerColor),
              _InfoRow(
                icon: Icons.auto_awesome_rounded,
                iconBg: const Color(0xFFB45309),
                title: 'Design',
                value: 'iOS 26 Glassmorphism',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _divider(dividerColor),
              _InfoRow(
                icon: Icons.font_download_rounded,
                iconBg: const Color(0xFF065F46),
                title: 'Fonts',
                value: 'Inter / Cairo',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _divider(dividerColor),
              _InfoRow(
                icon: Icons.code_rounded,
                iconBg: const Color(0xFF155E75),
                title: 'Framework',
                value: 'Flutter',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ]),
            const SizedBox(height: 28),

            // ─── DATA SOURCE ───
            _SectionLabel('DATA SOURCE', textSecondary),
            const SizedBox(height: 8),
            _SettingsGroup(surface: surface, children: [
              _InfoRow(
                icon: Icons.link_rounded,
                iconBg: const Color(0xFF1A56DB),
                title: 'JSON Source',
                value: 'GitHub / illyassvvv',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _divider(dividerColor),
              _InfoRow(
                icon: Icons.sports_soccer_rounded,
                iconBg: const Color(0xFF1A7A56),
                title: 'Matches API',
                value: 'kora-api.space',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _divider(Color color) => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(height: 1, thickness: 0.4, color: color),
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
        color: color.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final Color surface;
  const _SettingsGroup({required this.children, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _RowIcon(icon: icon, iconBg: iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  color: textSecondary.withOpacity(0.8),
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _RowIcon(icon: icon, iconBg: iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
