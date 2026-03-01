import 'package:aphasia_rehab_fe/common/primary_button.dart';
import 'package:aphasia_rehab_fe/common/secondary_button.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/ai_analytic.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/hints_used.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/progress.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/session_feeling.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/skills_practiced.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    void onPressedDone() {
      context.read<ScenarioSimManager>().resetScenario();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            spacing: 24.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Progress(),
              SkillsPracticed(),
              HintsUsed(),
              AiAnalytic(),
              AiAnalytic(),
              SessionFeeling(),
              const SizedBox(height: 8),
              Row(
                children: [
                  // This takes 1 part (1/3 of the total width)
                  Expanded(
                    flex: 1,
                    child: SecondaryButton(text: "Retry", onPressed: () {}),
                  ),
                  const SizedBox(width: 12),
                  // This takes 2 parts (2/3 of the total width)
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: "Done",
                      onPressed: onPressedDone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
