import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApodHistoryScreen extends StatefulWidget {
  const ApodHistoryScreen({super.key});

  @override
  State<ApodHistoryScreen> createState() => _ApodHistoryScreenState();
}

class _ApodHistoryScreenState extends State<ApodHistoryScreen> {
  List<Map<String, dynamic>> _apodHistory = [];
  bool _isLoading = true;
  String? _error;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.isInitialized
        ? (dotenv.env['NASA_API_KEY'] ?? 'DEMO_KEY')
        : 'DEMO_KEY';
    _fetchApodHistory();
  }

  Future<void> _fetchApodHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch last 10 APOD entries
      final response = await http.get(
        Uri.parse(
            'https://api.nasa.gov/planetary/apod?api_key=${_apiKey ?? 'DEMO_KEY'}&count=10'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _apodHistory = data
              .map((item) => {
                    'title': item['title'] ?? 'No title',
                    'explanation': item['explanation'] ?? 'No description',
                    'date': item['date'] ?? 'Unknown',
                    'url': item['url'],
                    'hdurl': item['hdurl'],
                    'copyright': item['copyright'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load APOD history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading APOD history: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildSkeletonCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: isDark ? 0 : 10, sigmaY: isDark ? 0 : 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Skeleton image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildShimmerEffect(),
                ),
                const SizedBox(width: 16),
                // Skeleton content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 200,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildShimmerEffect(),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _buildShimmerEffect(),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
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
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return const _ShimmerAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'APOD History',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: _fetchApodHistory,
                ),
              ],
              flexibleSpace: isDark
                  ? ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                    ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildSkeletonCard(),
                        childCount: 5,
                      ),
                    )
                  : _error != null
                      ? SliverToBoxAdapter(
                          child: Center(
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
                                  onPressed: _fetchApodHistory,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.blue,
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final apod = _apodHistory[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isDark ? null : Colors.white,
                                  gradient: isDark
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.12),
                                            Colors.white.withOpacity(0.08),
                                          ],
                                        )
                                      : null,
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: isDark
                                      ? BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: InkWell(
                                            onTap: () {
                                              // TODO: Navigate to APOD detail
                                            },
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Row(
                                                children: [
                                                  // Thumbnail
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.network(
                                                        apod['url'],
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context,
                                                            child,
                                                            loadingProgress) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                value: loadingProgress
                                                                            .expectedTotalBytes !=
                                                                        null
                                                                    ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                    : null,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                        Color>(
                                                                  Colors.white
                                                                      .withOpacity(
                                                                          0.6),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Center(
                                                              child: Icon(
                                                                Icons
                                                                    .image_not_supported_rounded,
                                                                size: 24,
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.6),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Content
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          apod['title'],
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          apod['date'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.6),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        if (apod['copyright'] !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            apod['copyright'],
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.5),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    PhosphorIcons.arrowRight(
                                                        PhosphorIconsStyle
                                                            .fill),
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () {
                                            // TODO: Navigate to APOD detail
                                          },
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                // Thumbnail
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(
                                                      apod['url'],
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.3),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              value: loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                          .cumulativeBytesLoaded /
                                                                      loadingProgress
                                                                          .expectedTotalBytes!
                                                                  : null,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Colors
                                                                    .grey[600]!,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.3),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported_rounded,
                                                              size: 24,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        apod['title'],
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        apod['date'],
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (apod['copyright'] !=
                                                          null) ...[
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          apod['copyright'],
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .grey[500],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  PhosphorIcons.arrowRight(
                                                      PhosphorIconsStyle.fill),
                                                  color: Colors.black87
                                                      .withOpacity(0.6),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                            childCount: _apodHistory.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
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
