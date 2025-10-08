import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // iOS-style AppBar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            // Settings content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // Appearance Section
                  _buildIOSSection(
                    context,
                    title: 'APPEARANCE',
                    children: [
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.moon(PhosphorIconsStyle.regular),
                        title: 'Theme',
                        trailing: _buildThemeSelector(context, themeProvider),
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.bell(PhosphorIconsStyle.regular),
                        title: 'Notifications',
                        trailing: _buildIOSSwitch(
                          context,
                          value: true,
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Preferences Section
                  _buildIOSSection(
                    context,
                    title: 'PREFERENCES',
                    children: [
                      _buildIOSSettingTile(
                        context,
                        icon:
                            PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                        title: 'APOD Date Format',
                        subtitle: 'MM/DD/YYYY',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon:
                            PhosphorIcons.translate(PhosphorIconsStyle.regular),
                        title: 'Language',
                        subtitle: 'English',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
                        title: 'Auto-refresh',
                        subtitle: 'Every 5 minutes',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Data Section
                  _buildIOSSection(
                    context,
                    title: 'DATA',
                    children: [
                      _buildIOSSettingTile(
                        context,
                        icon:
                            PhosphorIcons.download(PhosphorIconsStyle.regular),
                        title: 'Cache Management',
                        subtitle: 'Clear cached images',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon:
                            PhosphorIcons.database(PhosphorIconsStyle.regular),
                        title: 'Storage Usage',
                        subtitle: '12.5 MB',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // About Section
                  _buildIOSSection(
                    context,
                    title: 'ABOUT',
                    children: [
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
                        title: 'App Version',
                        subtitle: '1.0.0',
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.heart(PhosphorIconsStyle.regular),
                        title: 'Credits',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () => _showCreditsDialog(context),
                      ),
                      _buildIOSDivider(),
                      _buildIOSSettingTile(
                        context,
                        icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
                        title: 'Privacy Policy',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              letterSpacing: -0.08,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: isDark
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildIOSSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon with iOS-style background
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing widget
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 58),
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildIOSSwitch(
    BuildContext context, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value
              ? const Color(0xFF34C759) // iOS green
              : (isDark ? Colors.grey[600] : Colors.grey[300]),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: DropdownButton<AppThemeMode>(
        value: themeProvider.themeMode,
        onChanged: (AppThemeMode? newValue) {
          if (newValue != null) {
            themeProvider.setThemeMode(newValue);
          }
        },
        underline: const SizedBox(),
        icon: Icon(
          PhosphorIcons.caretDown(PhosphorIconsStyle.regular),
          size: 20,
          color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
        ),
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        items: [
          DropdownMenuItem<AppThemeMode>(
            value: AppThemeMode.light,
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.sun(PhosphorIconsStyle.fill),
                  size: 18,
                  //color: Colors.orange[600],
                ),
                const SizedBox(width: 12),
                Text(
                  'Light',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem<AppThemeMode>(
            value: AppThemeMode.dark,
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.moon(PhosphorIconsStyle.fill),
                  size: 18,
                  //color: Colors.blue[400],
                ),
                const SizedBox(width: 12),
                Text(
                  'Dark',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem<AppThemeMode>(
            value: AppThemeMode.system,
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.desktop(PhosphorIconsStyle.fill),
                  size: 18,
                  //color: Colors.purple[400],
                ),
                const SizedBox(width: 12),
                Text(
                  'System',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreditsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Credits',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data provided by:',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildCreditItem(context, '• NASA API'),
            _buildCreditItem(context, '• Open Notify API'),
            const SizedBox(height: 20),
            Text(
              'Images:',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildCreditItem(context, '• NASA Image and Video Library'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditItem(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
          fontSize: 15,
        ),
      ),
    );
  }
}
