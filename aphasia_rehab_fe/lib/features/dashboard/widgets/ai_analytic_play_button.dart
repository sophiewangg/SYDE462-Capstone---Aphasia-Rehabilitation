import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AiAnalyticPlayButton extends StatelessWidget {
  final String filename;
  final String disfluencyType;

  const AiAnalyticPlayButton({
    super.key,
    required this.filename,
    required this.disfluencyType,
  });
  @override
  Widget build(BuildContext context) {
    final SessionDashboardService dashboardService = SessionDashboardService();
    final AudioPlayer audioPlayer = AudioPlayer();

    return ElevatedButton(
      onPressed: () async {
        String url = dashboardService.getAudioUrl(filename, disfluencyType);
        try {
          await audioPlayer.play(UrlSource(url));
        } catch (e) {
          print("Error playing audio: $e");
        }
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
        'assets/icons/start_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 15,
      ),
    );
  }
}
