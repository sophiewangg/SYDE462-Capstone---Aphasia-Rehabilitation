import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/ai_analytic_play_button.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/overflow_menu_button.dart';
import 'package:flutter/material.dart';

class SessionFeeling extends StatefulWidget {
  const SessionFeeling({super.key});

  @override
  State<SessionFeeling> createState() => _SessionFeelingState();
}

class _SessionFeelingState extends State<SessionFeeling> {
  int? _clickedIndex;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> feelingOptions = [
      {'label': 'Confident', 'icon': 'assets/images/confident.png'},
      {'label': 'Okay', 'icon': 'assets/images/okay.png'},
      {'label': 'Frustrated', 'icon': 'assets/images/frustrated.png'},
    ];

    Widget _buildBox(
      BuildContext context,
      String label,
      String icon,
      int index,
    ) {
      return Material(
        color: Colors
            .transparent, // Prevents Material from blocking your Container color
        child: InkWell(
          onTap: () {
            setState(() {
              _clickedIndex = index;
            });
            // Add your navigation or logic here
          },
          borderRadius: BorderRadius.circular(
            10,
          ), // Ensures the splash stays in the lines
          child: Container(
            width: 105,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _clickedIndex == index
                  ? AppColors.grey100
                  : AppColors.dashboardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keeps the button tight
              children: [
                Image.asset(icon, height: 50, fit: BoxFit.contain),
                const SizedBox(height: 4), // Add a tiny gap for better spacing
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w100),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Text(
          "How did you feel?",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w100),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: feelingOptions.indexed.map((entry) {
            int index = entry.$1;
            var option = entry.$2;

            return _buildBox(context, option['label'], option['icon'], index);
          }).toList(),
        ),
      ],
    );
  }
}
