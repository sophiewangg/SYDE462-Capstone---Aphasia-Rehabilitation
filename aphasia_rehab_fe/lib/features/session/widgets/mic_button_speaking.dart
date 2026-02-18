import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MicButtonSpeaking extends StatefulWidget {
  final Function() updateCurrentPromptState;

  const MicButtonSpeaking({super.key, required this.updateCurrentPromptState});

  @override
  State<MicButtonSpeaking> createState() => _MicButtonSpeakingState();
}

class _MicButtonSpeakingState extends State<MicButtonSpeaking> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        widget.updateCurrentPromptState();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        shape: const StadiumBorder(),
        side: const BorderSide(color: Colors.black, width: 1.0),
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
