import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SkillsPracticed extends StatelessWidget {
  final Map<String, int> skillsPracticed;

  SkillsPracticed(this.skillsPracticed, {super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardManager dashboardManager = context.watch<DashboardManager>();
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
                for (var skill in skillsPracticed.entries)
                  Row(
                    spacing: 12.0,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/checkmark_icon.svg',
                        height: 15,
                        width: 15,
                        // ignore: deprecated_member_use
                        color: skill.value == 0
                            ? AppColors.checkmarkSuccess
                            : AppColors.textSecondary,
                      ),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: dashboardManager.getSkillName(skill.key),
                          builder: (context, snapshot) {
                            // While waiting, show the ID or a placeholder
                            if (!snapshot.hasData) {
                              return Text(
                                skill.key,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey),
                              );
                            }
                            // Once the name arrives, show it
                            return Text(
                              snapshot.data!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            );
                          },
                        ),
                      ),
                      if (skill.value != 0)
                        _buildHintsUsed(context, skill.value),
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
  Widget _buildHintsUsed(BuildContext context, int hintsUsed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        "$hintsUsed hints used",
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
