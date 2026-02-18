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
        // 1. Change to StadiumBorder for the pill shape
        shape: const StadiumBorder(),

        side: const BorderSide(color: Colors.black, width: 1.0),

        // 2. Adjust fixedSize: Width should be greater than Height
        // For a pill, try a 2:1 or 1.5:1 ratio
        fixedSize: const Size(240, 75),

        padding: EdgeInsets.zero, // Center the icon perfectly
        elevation: 2,
      ),
      // No text here, just the SVG
      child: SvgPicture.asset(
        'assets/icons/pause_icon.svg',
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        width: 30, // Adjust icon size to fit the pill height
      ),
    );
  }
}
