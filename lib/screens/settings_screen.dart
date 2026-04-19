import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/theme.dart';
import '../core/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            // ─── APPEARANCE ───
            _SectionLabel('APPEARANCE'),
            const SizedBox(height: 8),
            _SettingsGroup(children: [
              // ValueListenableBuilder so the toggle reflects the real theme state
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => _ToggleRow(
                  icon: Icons.dark_mode_rounded,
                  iconBg: const Color(0xFF2D1766),
                  title: 'Dark Mode',
                  value: mode == ThemeMode.dark,
                  onChanged: setDarkMode, // directly calls themeNotifier
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ─── ABOUT ───
            _SectionLabel('ABOUT'),
            const SizedBox(height: 8),
            _SettingsGroup(children: [
              _InfoRow(
                icon: Icons.grid_view_rounded,
                iconBg: const Color(0xFF1A56DB),
                title: 'AppStore',
                value: 'v3.0',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.auto_awesome_rounded,
                iconBg: const Color(0xFFB45309),
                title: 'Design',
                value: 'iOS 26 Glassmorphism',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.font_download_rounded,
                iconBg: const Color(0xFF065F46),
                title: 'Fonts',
                value: 'Inter / Cairo',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.code_rounded,
                iconBg: const Color(0xFF155E75),
                title: 'Framework',
                value: 'Flutter',
              ),
            ]),
            const SizedBox(height: 28),

            // ─── DATA SOURCE ───
            _SectionLabel('DATA SOURCE'),
            const SizedBox(height: 8),
            _SettingsGroup(children: [
              _InfoRow(
                icon: Icons.link_rounded,
                iconBg: const Color(0xFF1A56DB),
                title: 'JSON Source',
                value: 'GitHub / illyassvvv',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.sports_soccer_rounded,
                iconBg: const Color(0xFF1A7A56),
                title: 'Matches API',
                value: 'kora-api.space',
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.only(left: 56),
        child: Divider(height: 1, thickness: 0.4, color: Color(0x14FFFFFF)),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
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
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
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
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.onChanged,
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
                style: const TextStyle(
                    color: AppColors.textPrimary,
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
