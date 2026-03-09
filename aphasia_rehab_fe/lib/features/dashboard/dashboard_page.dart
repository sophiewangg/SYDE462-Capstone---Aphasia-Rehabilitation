import 'package:aphasia_rehab_fe/common/primary_button.dart';
import 'package:aphasia_rehab_fe/common/secondary_button.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/ai_analytic.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/hints_used.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/progress.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/session_feeling.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/skills_practiced.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SessionDashboardService _dashboardService = SessionDashboardService();

  late Future<List<List<String>>> _combinedFuture;

  @override
  void initState() {
    super.initState();
    _combinedFuture = Future.wait([
      _dashboardService.fetchSavedDetections("sound_rep"),
      _dashboardService.fetchSavedDetections("interjection"),
    ]);
  }

  void onPressedDone() {
    context.read<ScenarioSimManager>().resetScenario();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final DashboardManager dashboardManager = context.watch<DashboardManager>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<List<String>>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final soundRepFiles = snapshot.data?[0] ?? [];
            final interjectionFiles = snapshot.data?[1] ?? [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Progress(
                    dashboardManager.numHintsUsed,
                    soundRepFiles.length + interjectionFiles.length,
                    dashboardManager.numUnclearResponses /
                        dashboardManager.numPromptsGiven,
                  ),
                  const SizedBox(height: 24),
                  SkillsPracticed(
                    dashboardManager.skillsPracticed,
                  ),
                  const SizedBox(height: 24),
                  HintsUsed(dashboardManager.hintsGiven),
                  const SizedBox(height: 24),

                  // 4. Pass the specific lists to the correct widgets
                  if (soundRepFiles.isNotEmpty) ...[
                    AiAnalytic(
                      files: soundRepFiles,
                      disfluencyType: "sound_rep",
                    ),
                    const SizedBox(height: 24), // Keeps spacing consistent
                  ],
                  if (interjectionFiles.isNotEmpty) ...[
                    AiAnalytic(
                      files: interjectionFiles,
                      disfluencyType: "interjection",
                    ),
                    const SizedBox(height: 24), // Keeps spacing consistent
                  ],
                  SessionFeeling(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SecondaryButton(text: "Retry", onPressed: () {}),
                      ),
                      const SizedBox(width: 12),
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
            );
          },
        ),
      ),
    );
  }
}
