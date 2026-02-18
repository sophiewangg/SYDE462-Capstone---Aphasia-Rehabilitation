import 'package:flutter/material.dart';

class Character extends StatefulWidget {
  const Character({super.key});

  @override
  State<Character> createState() => _CharacterState();
}

class _CharacterState extends State<Character> {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/characters/server_1.png',
      height: 450, // Set a specific height
      fit: BoxFit.contain, // Ensures the whole image fits without cropping
    );
  }
}
