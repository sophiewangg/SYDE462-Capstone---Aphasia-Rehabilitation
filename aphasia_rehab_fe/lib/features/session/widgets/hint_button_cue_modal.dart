import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HintButtonCueModal extends StatefulWidget {
  final Function() updateCueNumber;
  const HintButtonCueModal({super.key, required this.updateCueNumber});

  @override
  State<HintButtonCueModal> createState() => _HintButtonCueModalState();
}

class _HintButtonCueModalState extends State<HintButtonCueModal> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip
              .none, // 1. Allows children to be drawn outside the Stack's box
          children: [
            // Main Button
            ElevatedButton(
              onPressed: widget.updateCueNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: const Size(72, 72),
                shape: const CircleBorder(),
                elevation: 4,
                padding: const EdgeInsets.all(16),
              ),
              child: SvgPicture.asset(
                'assets/icons/hint_icon.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),

            // The "Retry" circle - move it further out with larger negative numbers
            Positioned(
              right: -4, // 2. Increase negative value to push it further right
              bottom: -4, // 3. Adjust this to move it up/down
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.yellowPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ), // The white "cutout" border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.yellowSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Replaces spacing: 5.0 for better control
        const Text(
          "Hint",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
