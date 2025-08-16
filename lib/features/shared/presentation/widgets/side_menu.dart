import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CosmosViewer',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore the cosmos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            _buildMenuItem(
              context,
              icon: PhosphorIcons.house(PhosphorIconsStyle.regular),
              selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
              title: 'Home',
              index: 0,
            ),
            _buildMenuItem(
              context,
              icon: PhosphorIcons.rocket(PhosphorIconsStyle.regular),
              selectedIcon: PhosphorIcons.rocket(PhosphorIconsStyle.fill),
              title: 'Missions',
              index: 1,
            ),
            _buildMenuItem(
              context,
              icon: PhosphorIcons.planet(PhosphorIconsStyle.regular),
              selectedIcon: PhosphorIcons.planet(PhosphorIconsStyle.fill),
              title: 'ISS Tracker',
              index: 2,
            ),
            _buildMenuItem(
              context,
              icon: PhosphorIcons.image(PhosphorIconsStyle.regular),
              selectedIcon: PhosphorIcons.image(PhosphorIconsStyle.fill),
              title: 'APOD History',
              index: 3,
            ),
            _buildMenuItem(
              context,
              icon: PhosphorIcons.gear(PhosphorIconsStyle.regular),
              selectedIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
              title: 'Settings',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        onItemSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
