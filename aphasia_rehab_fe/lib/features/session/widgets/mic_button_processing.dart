import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MicButtonProcessing extends StatefulWidget {
  const MicButtonProcessing({super.key});

  @override
  State<MicButtonProcessing> createState() => _MicButtonProcessingState();
}

class _MicButtonProcessingState extends State<MicButtonProcessing> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Implement audio play logic
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
            'assets/icons/processing_icon.svg', // Update with your actual icon
            colorFilter: const ColorFilter.mode(
              AppColors.yellowSecondary,
              BlendMode.srcIn,
            ),
            width: 38, // Slightly larger for a circular button
          ),
        ],
      ),
    );
  }
}