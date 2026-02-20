import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
class SelectHint extends StatefulWidget {
  const SelectHint({super.key});

  @override
  State<SelectHint> createState() => _SelectHintState();
}

class _SelectHintState extends State<SelectHint> {
  @override
  Widget build(BuildContext context) {
    const double borderRadius = 8.0;

    return Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.boxBorder, width: 1.0),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 35,
                child: InkWell(
                  onTap: () => print("Help finding word tapped"),
                  // Wrap the image here
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(borderRadius),
                    ),
                    child: Image.asset(
                      'assets/images/help_finding_word_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.boxBorder),
              Expanded(
                flex: 35,
                child: InkWell(
                  onTap: () => print("I don't understand tapped"),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(borderRadius),
                      bottomRight: Radius.circular(borderRadius),
                    ),
                    child: Image.asset(
                      'assets/images/i_dont_understand_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}