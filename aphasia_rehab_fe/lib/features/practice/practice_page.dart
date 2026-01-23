import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/colors.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background);
  }
}
