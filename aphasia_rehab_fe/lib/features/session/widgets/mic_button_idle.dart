import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MicButtonIdle extends StatefulWidget {
  const MicButtonIdle({super.key});

  @override
  State<MicButtonIdle> createState() => _MicButtonIdleState();
}

class _MicButtonIdleState extends State<MicButtonIdle> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Implement audio play logic
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.audioButton,
        foregroundColor: AppColors.textPrimary,
        shape: const CircleBorder(), // Makes it a circle

        // ADD THIS LINE:
        side: const BorderSide(
          color: AppColors.buttonBorder, // Or any color from your AppColors
          width: 2.0,                 // Thickness of the border
        ),

        padding: const EdgeInsets.all(18), // Adjust padding to change circle size
        elevation: 2, // Optional: gives it a slight shadow
        fixedSize: const Size(74, 74), // Sets both width and height to 74px
      ),
      // Use a Column or just the SVG if you want it centered
      child: SvgPicture.asset(
        'assets/icons/mic_button.svg', // Update with your actual icon
        colorFilter: const ColorFilter.mode(
          AppColors.yellowSecondary,
          BlendMode.srcIn,
        ),
        width: 38, // Slightly larger for a circular button
      ),
    );
  }
}