import 'package:flutter/material.dart';
import 'features/session/session_page.dart'; // Import your new page

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
      ),
      // Point home to your new feature page
      home: const SessionPage(title: 'Rehab Session'),
    );
  }
}
