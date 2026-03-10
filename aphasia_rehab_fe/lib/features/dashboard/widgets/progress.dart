import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/progress_metric.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/share_button.dart';
import 'package:flutter/material.dart';

class Progress extends StatelessWidget {
  final int numHintsUsed;
  final int numDisfluencies;
  final double unclearPercentage;
  Progress(
    this.numHintsUsed,
    this.numDisfluencies,
    this.unclearPercentage, {
    super.key,
  });
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
      if (unclearPercentage >= 0.6) {
        return "Developing";
      } else if (unclearPercentage >= 0.2) {
        return "Good";
      } else {
        return "Strong";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15.0,
      children: [
        Text(
          "Your progress",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w100),
        ),
        Column(
          spacing: 10.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10.0,
              children: [
                ProgressMetric(
                  title: "Hints",
                  value: "$numHintsUsed used",
                  width: 145.0,
                ),
                ProgressMetric(
                  title: "Disfluencies",
                  value: "$numDisfluencies flagged",
                  width: 145.0,
                ),
              ],
            ),

            ProgressMetric(
              title: "Clarity",
              value: "${getClarityScore()} response relevancy",
              width: 300.0,
            ),
          ],
        ),
      ],
    );
  }
}
