import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> setupAppIcon() async {
  // Space-themed icon URL (a beautiful space icon)
  const iconUrl =
      'https://raw.githubusercontent.com/flutter/website/main/examples/layout/responsive/_grid_icons/app_icon.png';

  try {
    final response = await http.get(Uri.parse(iconUrl));
    if (response.statusCode == 200) {
      // Save to Android mipmap directories
      final androidDirs = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];

      for (final dir in androidDirs) {
        final directory = Directory('android/app/src/main/res/$dir');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File('${directory.path}/ic_launcher.png');
        await file.writeAsBytes(response.bodyBytes);
        print('Icon saved to: ${file.path}');
      }
    }
  } catch (e) {
    print('Error setting up icon: $e');
  }
}
