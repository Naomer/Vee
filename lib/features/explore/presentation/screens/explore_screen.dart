import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vee/features/missions/presentation/screens/missions_screen.dart';
import 'package:vee/features/mars_rover/presentation/screens/mars_rover_screen.dart';
import 'package:vee/features/apod_history/presentation/screens/apod_history_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Explore'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Space Missions Section
                const Text(
                  'Space Missions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExploreCard(
                  context,
                  PhosphorIcons.rocket(PhosphorIconsStyle.fill),
                  'Missions',
                  'Explore current and past space missions',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MissionsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildExploreCard(
                  context,
                  PhosphorIcons.martini(PhosphorIconsStyle.fill),
                  'Mars Rover',
                  'View latest images from Mars',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarsRoverScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Astronomy Section
                const Text(
                  'Astronomy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExploreCard(
                  context,
                  PhosphorIcons.image(PhosphorIconsStyle.fill),
                  'APOD History',
                  'Browse Astronomy Picture of the Day archive',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApodHistoryScreen(),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
