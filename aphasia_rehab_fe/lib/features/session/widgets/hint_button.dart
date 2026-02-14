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
    return ElevatedButton.icon(
      onPressed: () {
        widget.toggleHintButton();
      },
      icon: SvgPicture.asset(
        'assets/icons/hint_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 20,
      ),
      label: Text('Hint', style: Theme.of(context).textTheme.titleMedium),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        
        minimumSize: Size.zero, 
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}