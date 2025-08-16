import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/app_icon.dart';

Future<void> generateAppIcon() async {
  // Create a screenshot controller
  final screenshotController = ScreenshotController();

  // Create the app icon widget
  const appIcon = AppIcon(size: 1024);

  // Take the screenshot
  final bytes = await screenshotController.captureFromWidget(
    appIcon,
    delay: const Duration(milliseconds: 100),
    context: null,
  );

  // Save the image
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/app_icon.png');
  await file.writeAsBytes(bytes);

  print('App icon generated at: ${file.path}');
}
