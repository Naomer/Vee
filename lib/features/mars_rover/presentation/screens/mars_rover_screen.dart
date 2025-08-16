import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vee/core/widgets/modern_ui_components.dart';

class MarsRoverScreen extends StatefulWidget {
  const MarsRoverScreen({super.key});

  @override
  State<MarsRoverScreen> createState() => _MarsRoverScreenState();
}

class _MarsRoverScreenState extends State<MarsRoverScreen> {
  int _selectedRoverIndex = 0;
  DateTime _selectedDate = DateTime.now();
  final List<String> _rovers = ['curiosity', 'opportunity'];
  bool _isLoading = false;
  List<String> _roverImages = [];
  static const String _apiKey = 'DEMO_KEY'; // Using NASA's demo key for testing

  @override
  void initState() {
    super.initState();
    _fetchRoverImages();
  }

  Future<void> _fetchRoverImages() async {
    setState(() => _isLoading = true);
    try {
      // Use Curiosity rover and a date we know has images
      const rover = 'curiosity';
      const date = '2015-6-3';
      const url =
          'https://api.nasa.gov/mars-photos/api/v1/rovers/$rover/photos?earth_date=$date&api_key=DEMO_KEY';

      print('Fetching images from: $url'); // Debug log
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;
        print('Found ${photos.length} photos'); // Debug log

        if (photos.isEmpty) {
          throw Exception('No photos found for this date');
        }

        setState(() {
          _roverImages = photos
              .take(6)
              .map((photo) => photo['img_src'] as String)
              .toList();
          _isLoading = false;
        });
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
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
                  ModernSegmentedControl(
                    segments: _rovers.map((r) => r.toUpperCase()).toList(),
                    selectedIndex: _selectedRoverIndex,
                    onChanged: (index) {
                      setState(() => _selectedRoverIndex = index);
                      _fetchRoverImages();
                    },
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
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
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
}
