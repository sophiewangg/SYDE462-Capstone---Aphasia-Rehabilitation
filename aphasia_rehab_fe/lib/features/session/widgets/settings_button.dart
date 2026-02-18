import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsButton extends StatefulWidget {
  const SettingsButton({super.key});

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Implement Settings button
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        fixedSize: const Size(64, 64),
        // tapTargetSize ensures the hit area is comfortable
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(12),
        // This is the key change for a circle
        shape: const CircleBorder(),
        // Optional: Add a subtle border if it needs to match your speech bubble
        side: const BorderSide(color: AppColors.boxBorder, width: 1),
      ),
      child: SvgPicture.asset(
        'assets/icons/settings_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 24, // Increased slightly for better visual balance in a circle
      ),
    );
  }
}