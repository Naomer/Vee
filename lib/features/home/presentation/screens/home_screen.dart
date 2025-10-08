import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vee/features/missions/presentation/screens/missions_screen.dart';
import 'package:vee/features/apod_history/presentation/screens/apod_history_screen.dart';
import 'apod_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine text color based on theme brightness
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      extendBodyBehindAppBar:
          true, // Crucial for content to scroll behind transparent app bar
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white, // Use pure white in light mode
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120.0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Colors.white,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final double currentHeight = constraints.biggest.height;
                  final double percentage = ((currentHeight - kToolbarHeight) /
                          (120.0 - kToolbarHeight))
                      .clamp(0.0, 1.0);
                  if (!isDark) {
                    return FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 16.0),
                      title: Visibility(
                        visible: percentage < 0.5,
                        child: const Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      background: Container(
                        color: Colors.white.withOpacity(0.5),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          bottom: 0.0 + kToolbarHeight,
                        ),
                        child: Visibility(
                          visible: percentage > 0.5,
                          child: const Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  // Calculate the collapse percentage to control blur amount
                  final double blurAmount =
                      (1 - percentage) * 12.0; // Max blur of 12.0

                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: blurAmount, sigmaY: blurAmount),
                      child: FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(bottom: 16.0),
                        title: Visibility(
                          visible: percentage < 0.5,
                          child: Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        background: Container(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.5),
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.only(
                              left: 16.0, bottom: 0.0 + kToolbarHeight),
                          child: Visibility(
                            visible: percentage > 0.5,
                            child: Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main scrollable content below the AppBar
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // APOD Preview
                  const Card(
                    child: ApodScreen(),
                  ),
                  const SizedBox(height: 16),
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor, // Ensure this text also adapts
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildQuickActionCard(
                        context,
                        PhosphorIcons.rocket(PhosphorIconsStyle.fill),
                        'Missions',
                        () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const MissionsScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        PhosphorIcons.image(PhosphorIconsStyle.fill),
                        'APOD History',
                        () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ApodHistoryScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 100), // Add extra space to ensure scrolling
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
