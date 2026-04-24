import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const _SectionHeader('Apparence'),
          _Section(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: theme.mode,
                onChanged: (m) => theme.setMode(m!),
                title: const Text('Système'),
                subtitle: const Text('Suivre le thème de mon appareil'),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: theme.mode,
                onChanged: (m) => theme.setMode(m!),
                title: const Text('Clair'),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: theme.mode,
                onChanged: (m) => theme.setMode(m!),
                title: const Text('Sombre'),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('À propos'),
          _Section(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Flutter Chat App'),
                subtitle: Text(
                  'Chat temps réel avec Firebase',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}
