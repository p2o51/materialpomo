import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'focus_page.dart';
import 'todo_page.dart';
import 'stats_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = FlexColorScheme.light(
            scheme: FlexScheme.mandyRed,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 20,
            subThemesData: const FlexSubThemesData(
              blendOnLevel: 10,
              blendOnColors: false,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            useMaterial3: true,
          ).toScheme;
          darkColorScheme = FlexColorScheme.dark(
            scheme: FlexScheme.mandyRed,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 15,
            subThemesData: const FlexSubThemesData(
              blendOnLevel: 20,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            useMaterial3: true,
          ).toScheme;
        }

        return MaterialApp(
          title: '番茄钟',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightColorScheme.surfaceContainerHighest,
              indicatorColor: lightColorScheme.secondaryContainer,
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(color: lightColorScheme.onSecondaryContainer),
              ),
              iconTheme: WidgetStateProperty.all(
                IconThemeData(color: lightColorScheme.onSecondaryContainer),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: darkColorScheme.surfaceContainerHighest,
              indicatorColor: darkColorScheme.secondaryContainer,
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(color: darkColorScheme.onSecondaryContainer),
              ),
              iconTheme: WidgetStateProperty.all(
                IconThemeData(color: darkColorScheme.onSecondaryContainer),
              ),
            ),
          ),
          themeMode: ThemeMode.system,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // 当前选中的标签页索引

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Center(
        child: _selectedIndex == 0
            ? const FocusPage()
            : _selectedIndex == 1
                ? const TodoPage()
                : const StatsPage(),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.timer),
              label: '专注',
            ),
            NavigationDestination(
              icon: Icon(Icons.list),
              label: '待办',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: '统计',
            ),
          ],
        ),
      ),
    );
  }
}
