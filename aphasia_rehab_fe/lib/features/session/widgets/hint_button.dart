import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HintButton extends StatefulWidget {
  final bool hintButtonPressed;
  final Function() toggleHintButton;

  const HintButton({
    super.key,
    required this.hintButtonPressed,
    required this.toggleHintButton,
  });

  @override
  State<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<HintButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            widget.toggleHintButton();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            fixedSize: const Size(72, 72),
            // tapTargetSize ensures the hit area is comfortable
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.all(12),
            // This is the key change for a circle
            shape: const CircleBorder(),
            // Optional: Add a subtle border if it needs to match your speech bubble
            side: const BorderSide(color: AppColors.boxBorder, width: 1),
          ),
          child: SvgPicture.asset(
            'assets/icons/hint_icon.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
            width:
                24, // Increased slightly for better visual balance in a circle
          ),
        ),
        Text("Hint", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
