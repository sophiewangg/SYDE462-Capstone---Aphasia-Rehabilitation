import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/ai_analytic_play_button.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/overflow_menu_button.dart';
import 'package:flutter/material.dart';

class AiAnalytic extends StatefulWidget {
  final List<Map<String, dynamic>> files;
  final Function(String, String) onDeleteSuccess;

  const AiAnalytic({
    super.key,
    required this.files,
    required this.onDeleteSuccess,
  });

  @override
  State<AiAnalytic> createState() => _AiAnalyticState();
}

class _AiAnalyticState extends State<AiAnalytic> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Text(
          "Where you may have struggled",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w100),
        ),

        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: widget.files
              .map(
                (file) => _buildBox(
                  context,
                  file['filename'],
                  file['disfluencyType'],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBox(
    BuildContext context,
    String filename,
    String disfluencyType,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // This ensures the box never gets wider than the screen minus padding
          maxWidth: MediaQuery.of(context).size.width - 80,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keeps the box tight around content
          children: [
            AiAnalyticPlayButton(
              filename: filename,
              disfluencyType: disfluencyType,
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                "0:03",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 20),
            OverflowMenuButton(
              filename: filename,
              disfluencyType: disfluencyType,
              onDeleteSuccess: widget.onDeleteSuccess,
            ),
          ],
        ),
      ),
    );
  }
}
