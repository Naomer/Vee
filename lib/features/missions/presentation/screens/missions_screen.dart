import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vee/core/widgets/modern_ui_components.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _missions = [];
  String? _error;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    // Get NASA API key from .env file
    _apiKey = dotenv.isInitialized
        ? (dotenv.env['NASA_API_KEY'] ?? 'DEMO_KEY')
        : 'DEMO_KEY';
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch current NASA missions from the NASA API
      final response = await http.get(
        Uri.parse(
            'https://api.nasa.gov/planetary/apod?api_key=${_apiKey ?? 'DEMO_KEY'}&count=10'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _missions = data
              .map((item) => {
                    'title': item['title'] ?? 'NASA Mission',
                    'description':
                        item['explanation'] ?? 'No description available',
                    'launchDate': item['date'] ?? 'Unknown',
                    'searchQuery':
                        item['title']?.toString().toLowerCase() ?? 'nasa',
                    'imageUrl': item['url'],
                    'hdUrl': item['hdurl'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load missions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading missions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.black, Colors.black]
                : [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.surface,
                  ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Space Missions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _fetchMissions();
                  },
                ),
              ],
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildSkeletonCard(),
                          );
                        },
                        childCount: 5, // Show 5 skeleton cards
                      ),
                    )
                  : _error != null
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                Text(_error!),
                                ElevatedButton(
                                  onPressed: _fetchMissions,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final mission = _missions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ModernCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Use the image from NASA API directly
                                      Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          image: mission['imageUrl'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      mission['imageUrl']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: mission['imageUrl'] == null
                                              ? Colors.grey[800]
                                              : null,
                                        ),
                                        child: mission['imageUrl'] == null
                                            ? const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white,
                                                  size: 48,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ModernTitle(
                                              mission['title'],
                                              fontSize: 24,
                                            ),
                                            const SizedBox(height: 8),
                                            ModernBodyText(
                                              mission['description'],
                                              fontSize: 16,
                                            ),
                                            const SizedBox(height: 8),
                                            ModernBodyText(
                                              'Date: ${mission['launchDate']}',
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _missions.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? Colors.white.withOpacity(0.12) : null,
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 0 : 10,
            sigmaY: isDark ? 0 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.3),
                ),
                child: _buildShimmerEffect(),
              ),
              // Skeleton content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton title
                    Container(
                      height: 24,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(height: 8),
                    // Skeleton description lines
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(height: 8),
                    // Skeleton date
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
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

  Widget _buildShimmerEffect() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const _ShimmerAnimation(),
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  const _ShimmerAnimation();

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * 200, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
