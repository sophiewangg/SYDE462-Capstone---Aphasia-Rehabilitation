import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CueAudioButton extends StatelessWidget {
  const CueAudioButton({super.key});
  @override
  Widget build(BuildContext context) {
    final HintManager hintManager = context.watch<HintManager>();
    return ElevatedButton(
      onPressed: () {
        hintManager.playElevenLabsAudio(hintManager.hintText, hintManager.currentCachedAudioId);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
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
