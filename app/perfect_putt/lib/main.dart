import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'globals/globals.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect Putt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: greenColor,
          primary: greenColor,
          secondary: accentColor,
          surface: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,

        // Text Styles
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),

        // Button Styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: greenColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 2,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: Colors.white,
          shadowColor: Colors.black26,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: greenColor,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

      ),
      home: const HomePage(),
    );
  }
}