import 'package:flutter/material.dart';

class Food extends StatefulWidget {
  final String foodUrl;
  const Food({super.key, required this.foodUrl});

  @override
  State<Food> createState() => _FoodState();
}

class _FoodState extends State<Food> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.foodUrl,
      height: 75, // Set a specific height
      fit: BoxFit.contain, // Ensures the whole image fits without cropping
    );
  }
}
