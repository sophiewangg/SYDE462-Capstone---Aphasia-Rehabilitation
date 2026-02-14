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
        // TODO: Implement processing logic
        widget.updateCurrentPromptState();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.audioButton,
        foregroundColor: AppColors.textPrimary,
        // ADD THIS LINE:
        side: const BorderSide(
          color: AppColors.buttonBorder, // Or any color from your AppColors
          width: 2.0, // Thickness of the border
        ),

        padding: const EdgeInsets.all(
          18,
        ), // Adjust padding to change circle size
        elevation: 2, // Optional: gives it a slight shadow
        fixedSize: const Size.fromHeight(74),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/mic_button.svg', // Update with your actual icon
            colorFilter: const ColorFilter.mode(
              AppColors.yellowSecondary,
              BlendMode.srcIn,
            ),
            width: 38, // Slightly larger for a circular button
          ),
          const SizedBox(width: 10),
          Text(
            "Speak now",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.yellowSecondary),
          ),
        ],
      ),
    );
  }
}
