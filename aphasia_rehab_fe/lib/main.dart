import 'package:flutter/material.dart';
import 'common/bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aphasia Rehab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(
          const TextTheme(
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontSize: 16),
          ),
        ),
      ),
      // Point home to your new feature page
      home: const BottomNavBar(),
    );
  }
}
