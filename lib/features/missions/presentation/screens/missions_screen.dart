import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vee/core/widgets/modern_ui_components.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final bool _isLoading = false;
  static const String _apiKey =
      'YOUR_NASA_API_KEY'; // Replace with your actual NASA API key

  final List<Map<String, dynamic>> _missions = [
    {
      'title': 'James Webb Space Telescope',
      'description':
          'The most powerful space telescope ever built, studying the universe in infrared.',
      'launchDate': 'December 25, 2021',
      'searchQuery': 'james webb space telescope',
    },
    {
      'title': 'Artemis II',
      'description':
          'NASA\'s mission to return humans to the Moon and establish a sustainable presence.',
      'launchDate': 'November 2024',
      'searchQuery': 'artemis ii mission',
    },
    {
      'title': 'Mars Perseverance',
      'description':
          'Exploring Mars and searching for signs of ancient microbial life.',
      'launchDate': 'July 30, 2020',
      'searchQuery': 'mars perseverance rover',
    },
  ];

  Future<String?> _fetchImage(String query) async {
    try {
      final url =
          'https://images-api.nasa.gov/search?q=$query&media_type=image';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['collection']['items'] as List;
        if (items.isNotEmpty) {
          final firstItem = items.first;
          final links = firstItem['links'] as List;
          if (links.isNotEmpty) {
            final imageUrl = links.first['href'] as String;
            // Verify the image URL is accessible
            final imageResponse = await http.head(Uri.parse(imageUrl));
            if (imageResponse.statusCode == 200) {
              return imageUrl;
            }
          }
        }
      }
      print('Failed to fetch image for query: $query');
      return null;
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
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
              Colors.blue[900]!,
              Colors.black,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernAppBar(
              title: 'Space Missions',
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mission = _missions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String?>(
                              future: _fetchImage(mission['searchQuery']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                }

                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    snapshot.data!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
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
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'Launch Date: ${mission['launchDate']}',
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
}
