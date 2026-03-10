import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/hint_audio_button.dart';
import 'package:flutter/material.dart';

class HintsUsed extends StatelessWidget {
  final List<String> hintsGiven;
  HintsUsed(this.hintsGiven, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Text(
          "Hints you used",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w100),
        ),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: hintsGiven.asMap().entries.map((entry) {
            int index = entry.key;
            String hint = entry.value;

            return _buildHintBox(context, hint, index); // Pass index here
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHintBox(BuildContext context, String text, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      // We use a Row, but we wrap it in a ConstrainedBox to set a "speed limit" on width
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // This ensures the box never gets wider than the screen minus padding
          maxWidth: MediaQuery.of(context).size.width - 80,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keeps the box tight around content
          children: [
            HintAudioButton(text, index.toString()),
            const SizedBox(width: 8),
            // Flexible with FlexFit.loose is the secret to keeping the UI look
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
