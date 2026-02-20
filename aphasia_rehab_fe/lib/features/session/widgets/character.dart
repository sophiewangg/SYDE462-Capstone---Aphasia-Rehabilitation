import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Character extends StatefulWidget {
  const Character({super.key});

  @override
  State<Character> createState() => _CharacterState();
}

class _CharacterState extends State<Character> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    return Image.asset(
      scenarioSimManager.currentCharacter,
      height: 750, // Set a specific height
      fit: BoxFit.contain, // Ensures the whole image fits without cropping
    );
  }
}
