import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vee/core/widgets/modern_ui_components.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MarsRoverScreen extends StatefulWidget {
  const MarsRoverScreen({super.key});

  @override
  State<MarsRoverScreen> createState() => _MarsRoverScreenState();
}

class _MarsRoverScreenState extends State<MarsRoverScreen> {
  int _selectedRoverIndex = 0;
  DateTime _selectedDate =
      DateTime(2021, 3, 15); // Start with a date that likely has images
  final List<String> _rovers = [
    'curiosity',
    'opportunity',
    'perseverance',
    'spirit'
  ];
  final List<Map<String, String>> _roverInfo = [
    {'name': 'Curiosity', 'landing': '2012-08-06', 'status': 'Active'},
    {
      'name': 'Opportunity',
      'landing': '2004-01-25',
      'status': 'End of Mission'
    },
    {'name': 'Perseverance', 'landing': '2021-02-18', 'status': 'Active'},
    {'name': 'Spirit', 'landing': '2004-01-04', 'status': 'End of Mission'},
  ];
  bool _isLoading = false;
  List<String> _roverImages = [];
  String? _apiKey;
  DateTime? _lastApiCall;
  static const Duration _rateLimitDelay =
      Duration(seconds: 1); // Reduced since you have personal key

  @override
  void initState() {
    super.initState();
    // Get NASA API key from .env file
    _apiKey = dotenv.isInitialized
        ? (dotenv.env['NASA_API_KEY'] ?? 'DEMO_KEY')
        : 'DEMO_KEY';
    _fetchRoverImages();
  }

  Future<void> _fetchRoverImages() async {
    // Rate limiting to avoid API limits
    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall < _rateLimitDelay) {
        final remainingTime = _rateLimitDelay - timeSinceLastCall;
        print('Rate limiting: waiting ${remainingTime.inMilliseconds}ms');
        await Future.delayed(remainingTime);
      }
    }
    _lastApiCall = DateTime.now();

    setState(() => _isLoading = true);
    try {
      // Use selected rover and date
      final rover = _rovers[_selectedRoverIndex];
      final date =
          '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
      final url =
          'https://api.nasa.gov/mars-photos/api/v1/rovers/$rover/photos?earth_date=$date&api_key=${_apiKey ?? 'DEMO_KEY'}';

      print('Fetching images from: $url'); // Debug log
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;
        print('Found ${photos.length} photos for $rover on $date'); // Debug log

        setState(() {
          _roverImages = photos
              .take(12) // Show more images
              .map((photo) => photo['img_src'] as String)
              .toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        setState(() {
          _roverImages = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Rate limit exceeded. Please wait a moment and try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Error response: ${response.body}'); // Debug log
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching images: $e'); // Debug log
      setState(() {
        _roverImages = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageDetails(String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image in modal: $error');
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.black, Colors.black]
                : [
                    Colors.red[900]!,
                    Colors.black,
                  ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernAppBar(
              title: 'Mars Rover',
              fontSize: 20,
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: _fetchRoverImages,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rover selection
                  ModernSegmentedControl(
                    segments: _roverInfo.map((r) => r['name']!).toList(),
                    selectedIndex: _selectedRoverIndex,
                    fontSize: 12,
                    onChanged: (index) {
                      setState(() => _selectedRoverIndex = index);
                      _fetchRoverImages();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Rover info card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _roverInfo[_selectedRoverIndex]['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Landing: ${_roverInfo[_selectedRoverIndex]['landing']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Status: ${_roverInfo[_selectedRoverIndex]['status']}',
                                style: TextStyle(
                                  color: _roverInfo[_selectedRoverIndex]
                                              ['status'] ==
                                          'Active'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ModernDateButton(
                          date: _selectedDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2012),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                              _fetchRoverImages();
                            }
                          },
                          isSelected: true,
                        ),
                        const SizedBox(width: 8),
                        ModernDateButton(
                          date: DateTime.now(),
                          onTap: () {
                            setState(() => _selectedDate = DateTime.now());
                            _fetchRoverImages();
                          },
                          isSelected: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildSkeletonImageCard();
                    },
                    childCount: 8, // Show 8 skeleton cards
                  ),
                ),
              )
            else if (_roverImages.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No images available for this date',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageDetails(_roverImages[index]),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _roverImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _roverImages.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonImageCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          child: _buildShimmerEffect(),
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
