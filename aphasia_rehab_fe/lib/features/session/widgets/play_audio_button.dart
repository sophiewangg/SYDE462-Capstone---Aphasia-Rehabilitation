import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

class PlayAudioButton extends StatefulWidget {
  const PlayAudioButton({super.key});

  @override
  State<PlayAudioButton> createState() => _PlayAudioButtonState();
}

class _PlayAudioButtonState extends State<PlayAudioButton> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    return ElevatedButton(
      onPressed: () {
        scenarioSimManager.playCharacterAudio();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.grey100,
        foregroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        elevation: 2,
      ),
      child: SvgPicture.asset(
        'assets/icons/audio_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 20,
      ),
    );
  }
}
