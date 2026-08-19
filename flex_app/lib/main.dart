import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/nutrition_screen.dart';

void main() {
  runApp(const FlexApp());
}

class FlexApp extends StatefulWidget {
  const FlexApp({super.key});

  @override
  State<FlexApp> createState() => _FlexAppState();
}

class _FlexAppState extends State<FlexApp> {
  bool _isDark = false;

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDark ? AppColors.dark : AppColors.light;
    return AppTheme(
      colors: colors,
      isDark: _isDark,
      toggleMode: _toggleTheme,
      child: MaterialApp(
        title: 'Flex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: colors.bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.accent,
            brightness: _isDark ? Brightness.dark : Brightness.light,
            primary: colors.accent,
            surface: colors.surface,
          ),
          cardTheme: CardThemeData(
            color: colors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.border),
            ),
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    NutritionScreen(),
    PlaceholderScreen(label: 'Workout'),
    PlaceholderScreen(label: 'Weight'),
    PlaceholderScreen(label: 'Graphs'),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withOpacity(0.18),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Weight'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Graphs'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String label;
  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(label), backgroundColor: colors.bg, foregroundColor: colors.text),
      body: Center(
        child: Text('$label screen - coming soon', style: TextStyle(color: colors.textMuted)),
      ),
    );
  }
}