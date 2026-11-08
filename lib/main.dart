import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const EvNaviApp());
}

class EvNaviApp extends StatelessWidget {
  const EvNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvNavi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7), // Neutral light background
        primaryColor: const Color(0xFF222222),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF222222), // Softer black
          onPrimary: Colors.white,
          secondary: Color(0xFFE50010),
          surface: Colors.white,
          onSurface: Color(0xFF222222),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF222222),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF222222),
          unselectedItemColor: Color(0xFF666666), // Slightly darker gray
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        fontFamily: '.SF Pro Text', // System font for clean look
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
