import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/progress_metric.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/share_button.dart';
import 'package:flutter/material.dart';

class Progress extends StatelessWidget {
  final int numHintsUsed;
  final double avgWords;
  final double clearPercentage;
  Progress(this.numHintsUsed, this.avgWords, this.clearPercentage, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375,
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              spacing: 40.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildProgressMetrics(context),
                const ShareButton(),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            right: 0, // Set to 0 to touch the true edge of the Container
            child: Image.asset(
              'assets/images/character_dashboard.png',
              height: 150, // Increased slightly to overlap nicely
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  // Extracted for readability
  Widget _buildHeader(BuildContext context) {
    return Column(
      spacing: 10.0,
      children: [
        Text("Nice one Kelly!", style: Theme.of(context).textTheme.titleLarge),
        Text(
          "You've successfully ordered at Bob's Eatery",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressMetrics(BuildContext context) {
    String getClarityScore() {
      return switch (clearPercentage) {
        >= 0.95 => "Expert",
        >= 0.90 => "Strong",
        >= 0.70 => "Good",
        >= 0.5 => "Developing",
        _ => "Beginner", // The 'default' case
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15.0,
      children: [
        Column(
          spacing: 10.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10.0,
              children: [
                ProgressMetric(
                  title: "Clarity",
                  value: getClarityScore(),
                  width: 145.0,
                  hasTooltip: true,
                  clearPercentage: clearPercentage,
                ),
                ProgressMetric(
                  title: "Hints",
                  value: "$numHintsUsed used",
                  width: 145.0,
                  hasTooltip: false,
                ),
              ],
            ),
            ProgressMetric(
              title: "Average words per response",
              value: "${avgWords.round()} words",
              width: 300.0,
              hasTooltip: false,
            ),
          ],
        ),
      ],
    );
  }
}
