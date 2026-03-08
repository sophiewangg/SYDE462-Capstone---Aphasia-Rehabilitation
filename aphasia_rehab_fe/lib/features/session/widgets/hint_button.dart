import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class HintButton extends StatefulWidget {
  const HintButton({super.key});

  @override
  State<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<HintButton> {
  @override
  Widget build(BuildContext context) {
    final hintManager = context.watch<HintManager>();
    return Column(
      spacing: 5.0,
      children: [
        ElevatedButton(
          onPressed: () {
            hintManager.toggleHintButton();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: hintManager.hintButtonPressed
                ? AppColors.grey100
                : Colors.white,
            foregroundColor: AppColors.textPrimary,
            fixedSize: const Size(72, 72),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.all(12),
            shape: const CircleBorder(),
            side: const BorderSide(color: AppColors.boxBorder, width: 1),
          ),
          child: SvgPicture.asset(
            'assets/icons/hint_icon.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
            width: 24,
          ),
        ),
        Text("Hint", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
