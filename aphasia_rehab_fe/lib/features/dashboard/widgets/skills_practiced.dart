import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SkillsPracticed extends StatelessWidget {
  SkillsPracticed({super.key});
  final List<Map<String, dynamic>> skills = [
    {'name': 'Ordering Food', 'icon': 'assets/icons/food.svg', 'success': true},
    {'name': 'Small Talk', 'icon': 'assets/icons/chat.svg', 'success': false},
    {
      'name': 'Public Speaking',
      'icon': 'assets/icons/mic.svg',
      'success': false,
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Text(
            "Skills Practiced",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w100),
          ),
          // Using a for-in loop with the spread operator (...)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              spacing: 8.0,
              children: [
                for (var skill in skills)
                  Row(
                    spacing: 12.0,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/checkmark_icon.svg',
                        height: 15,
                        width: 15,
                        // ignore: deprecated_member_use
                        color: skill['success']
                            ? AppColors.checkmarkSuccess
                            : AppColors.textSecondary,
                      ),
                      Text(
                        skill['name']!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (!skill['success']) _buildHintsUsed(context),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Extracted for readability
  Widget _buildHintsUsed(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        "1 hint used",
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
