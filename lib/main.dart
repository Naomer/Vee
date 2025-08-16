import 'package:flutter/material.dart';
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
  // Initialize FFI for sqflite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();
  await setupAppIcon();

  // Get the application documents directory
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDir.path, 'vee.db');

  // Set the database factory
  databaseFactory.setDatabasesPath(dbPath);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      themeMode: switch (themeProvider.themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      home: const MainScreen(),
    );
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
                              onPressed: () =>
                                  setState(() => _selectedIndex = 0),
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 1
                                    ? PhosphorIcons.compass(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.compass(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () =>
                                  setState(() => _selectedIndex = 1),
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 2
                                    ? PhosphorIcons.brain(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.brain(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () =>
                                  setState(() => _selectedIndex = 2),
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 3
                                    ? PhosphorIcons.planet(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.planet(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () =>
                                  setState(() => _selectedIndex = 3),
                            ),
                            IconButton(
                              icon: Icon(
                                _selectedIndex == 4
                                    ? PhosphorIcons.gear(
                                        PhosphorIconsStyle.fill)
                                    : PhosphorIcons.gear(
                                        PhosphorIconsStyle.regular),
                              ),
                              onPressed: () =>
                                  setState(() => _selectedIndex = 4),
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
                                ? PhosphorIcons.brain(PhosphorIconsStyle.fill)
                                : PhosphorIcons.brain(
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
