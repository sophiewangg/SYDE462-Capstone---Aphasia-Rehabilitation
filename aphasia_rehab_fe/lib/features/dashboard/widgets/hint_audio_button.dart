import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class HintAudioButton extends StatelessWidget {
  final String text;
  final String promptId;
  const HintAudioButton(this.text, this.promptId, {super.key});
  @override
  Widget build(BuildContext context) {
    final DashboardManager dashboardManager = context.watch<DashboardManager>();
    return ElevatedButton(
      onPressed: () {
        dashboardManager.playElevenLabsAudio(text, promptId);
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
