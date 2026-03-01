import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';

class SecondaryButton extends StatefulWidget {
  final String text;
  final Function() onPressed;
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: widget.onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.yellowSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(
            color: AppColors.yellowSecondary,
            width: 1.0,
          ),
        ),

        child: Text(
          widget.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.yellowSecondary,
          ),
        ),
      ),
    );
  }
}
