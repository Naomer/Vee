import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApodScreen extends StatefulWidget {
  const ApodScreen({super.key});

  @override
  State<ApodScreen> createState() => _ApodScreenState();
}

class _ApodScreenState extends State<ApodScreen> {
  Map<String, dynamic>? _apodData;
  bool _isLoading = true;
  String? _error;
  String? _apiKey;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.isInitialized
        ? (dotenv.env['NASA_API_KEY'] ?? 'DEMO_KEY')
        : 'DEMO_KEY';
    _fetchApod();
  }

  Future<void> _fetchApod() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Fetching APOD data...');
      final response = await http.get(
        Uri.parse(
            'https://api.nasa.gov/planetary/apod?api_key=${_apiKey ?? 'DEMO_KEY'}'),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _apodData = json.decode(response.body);
          _isLoading = false;
        });
        print('APOD data loaded successfully');
        print('Image URL: ${_apodData?['url']}');
      } else {
        setState(() {
          _error = 'Error fetching APOD: ${response.statusCode}';
          _isLoading = false;
        });
        print('Error loading APOD: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching APOD: $e';
        _isLoading = false;
      });
      print('Exception while loading APOD: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.08),
                  ],
                )
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
                sigmaX: isDark ? 0 : 10, sigmaY: isDark ? 0 : 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchApod,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.white.withOpacity(0.2) : Colors.blue,
                      foregroundColor: isDark ? Colors.white : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
              )
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
              sigmaX: isDark ? 0 : 10, sigmaY: isDark ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              if (_apodData?['url'] != null)
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Image.network(
                      _apodData!['url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.3),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.grey[600]!,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.3),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 48,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _apodData?['title'] ?? 'No title available',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      _apodData?['explanation'] ?? 'No explanation available',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: _isExpanded ? null : 4,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // See More/Less Button (positioned below text)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(
                          _isExpanded ? 'See Less' : 'See More',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date and copyright
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _apodData?['date'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_apodData?['copyright'] != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.copyright_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _apodData!['copyright'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
              )
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
              sigmaX: isDark ? 0 : 10, sigmaY: isDark ? 0 : 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton image
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildShimmerEffect(),
                ),
                const SizedBox(height: 20),
                // Skeleton title
                Container(
                  height: 24,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildShimmerEffect(),
                ),
                const SizedBox(height: 12),
                // Skeleton description lines
                ...List.generate(
                    4,
                    (index) => Padding(
                          padding: EdgeInsets.only(bottom: index < 3 ? 8.0 : 0),
                          child: Container(
                            height: 16,
                            width: index == 3 ? 200 : double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildShimmerEffect(),
                          ),
                        )),
                const SizedBox(height: 16),
                // Skeleton date
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildShimmerEffect(),
                ),
              ],
            ),
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
