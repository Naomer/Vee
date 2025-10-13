import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/explore/presentation/screens/explore_screen.dart';
import 'features/iss_tracker/presentation/screens/iss_tracker_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'core/theme/theme_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'core/utils/setup_app_icon.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/env/.env");
    debugPrint(
        "dotenv initialized: ${dotenv.isInitialized}, key present: ${dotenv.env['OPENROUTER_API_KEY'] != null}");
  } catch (e) {
    debugPrint("⚠️ Could not load .env file: $e");
  }

  try {
    await setupAppIcon();
  } catch (e) {
    debugPrint("⚠️ Could not setup app icon: $e");
  }

  try {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'vee.db');
    databaseFactory.setDatabasesPath(dbPath);
  } catch (e) {
    debugPrint("⚠️ Database initialization failed: $e");
  }

  // Get system brightness immediately to avoid flicker
  final systemBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(initialBrightness: systemBrightness),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Brightness initialBrightness;

  const MyApp({super.key, required this.initialBrightness});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Determine the effective theme mode
        ThemeMode effectiveThemeMode;
        switch (themeProvider.themeMode) {
          case AppThemeMode.light:
            effectiveThemeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
            effectiveThemeMode = ThemeMode.dark;
            break;
          case AppThemeMode.system:
            // Use the initial brightness to avoid flicker
            effectiveThemeMode = initialBrightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light;
            break;
        }

        return MaterialApp(
          title: 'Vee',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              height: 45,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (Set<WidgetState> states) => const TextStyle(fontSize: 12.0),
              ),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (Set<WidgetState> states) => const IconThemeData(
                  size: 24,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              height: 45,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (Set<WidgetState> states) => const TextStyle(fontSize: 10.0),
              ),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (Set<WidgetState> states) => const IconThemeData(
                  size: 24,
                ),
              ),
            ),
          ),
          themeMode: effectiveThemeMode,
          home: const AppInitializer(),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add a small delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: 64,
                color: const Color(0xFF1E88E5),
              ),
              const SizedBox(height: 16),
              Text(
                'Vee',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
              ),
              const SizedBox(height: 8),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
              ),
            ],
          ),
        ),
      );
    }

    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: const [
              HomeScreen(),
              ExploreScreen(),
              AIChatScreen(),
              IssTrackerScreen(),
              SettingsScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Theme.of(context).brightness == Brightness.dark
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: SizedBox(
                        height: 65,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 0
                                    ? PhosphorIcons.house(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.house(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _selectedIndex = 0);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 1
                                    ? PhosphorIcons.compass(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.compass(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _selectedIndex = 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 2
                                    ? PhosphorIcons.sparkle(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.sparkle(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _selectedIndex = 2);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 3
                                    ? PhosphorIcons.planet(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.planet(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _selectedIndex = 3);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 4
                                    ? PhosphorIcons.gear(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.gear(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _selectedIndex = 4);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _selectedIndex == 0
                                ? PhosphorIcons.house(PhosphorIconsStyle.fill)
                                : PhosphorIcons.house(
                                    PhosphorIconsStyle.regular),
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 0),
                        ),
                        IconButton(
                          icon: Icon(
                            _selectedIndex == 1
                                ? PhosphorIcons.compass(PhosphorIconsStyle.fill)
                                : PhosphorIcons.compass(
                                    PhosphorIconsStyle.regular),
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 1),
                        ),
                        IconButton(
                          icon: Icon(
                            _selectedIndex == 2
                                ? PhosphorIcons.sparkle(PhosphorIconsStyle.fill)
                                : PhosphorIcons.sparkle(
                                    PhosphorIconsStyle.regular),
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 2),
                        ),
                        IconButton(
                          icon: Icon(
                            _selectedIndex == 3
                                ? PhosphorIcons.planet(PhosphorIconsStyle.fill)
                                : PhosphorIcons.planet(
                                    PhosphorIconsStyle.regular),
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 3),
                        ),
                        IconButton(
                          icon: Icon(
                            _selectedIndex == 4
                                ? PhosphorIcons.gear(PhosphorIconsStyle.fill)
                                : PhosphorIcons.gear(
                                    PhosphorIconsStyle.regular),
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 4),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
