import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final Function() onPressed;
  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: widget.onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellowPrimary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),

        child: Text(
          widget.text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
