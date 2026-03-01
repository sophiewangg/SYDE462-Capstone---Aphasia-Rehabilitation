import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MicButtonSpeaking extends StatefulWidget {
  const MicButtonSpeaking({super.key});

  @override
  State<MicButtonSpeaking> createState() => _MicButtonSpeakingState();
}

class _MicButtonSpeakingState extends State<MicButtonSpeaking> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return ElevatedButton(
      onPressed: () {
        scenarioSimManager.handleMicToggle();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        shape: const StadiumBorder(),
        fixedSize: const Size(250, 75),
        padding: EdgeInsets.zero,
        elevation: 2,
      ),
      child: SvgPicture.asset(
        'assets/icons/pause_icon.svg',
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        width: 30,
      ),
    );
  }
}
