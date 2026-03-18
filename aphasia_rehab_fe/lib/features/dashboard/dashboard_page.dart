import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/common/primary_button.dart';
import 'package:aphasia_rehab_fe/common/secondary_button.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/ai_analytic.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/hints_used.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/improve_responses.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/progress.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/session_feeling.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/skills_practiced.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/models/improved_response_model.dart';
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

  // Local state for the disfluencies list
  List<Map<String, String>> _localDisfluencies = [];
  List<ImprovedResponse> _improvedResults = [];

  late Future<List<dynamic>> _combinedFuture;

  @override
  void initState() {
    super.initState();
    _initializeDashboardData();
  }

  Future<void> _initializeDashboardData() async {
    final dashboardManager = context.read<DashboardManager>();

    setState(() {
      _combinedFuture = Future.wait([
        _dashboardService.fetchSavedDetections("sound_rep"),
        _dashboardService.fetchSavedDetections("interjection"),
        _fetchAllSkillNames(dashboardManager),
      ]);
    });

    final results = await _combinedFuture;

    // Process and store list in state once data arrives
    final soundReps = (results[0] as List? ?? []).map(
      (f) => {'filename': f.toString(), 'disfluencyType': 'sound_rep'},
    );
    final interjections = (results[1] as List? ?? []).map(
      (f) => {'filename': f.toString(), 'disfluencyType': 'interjection'},
    );

    if (mounted) {
      setState(() {
        _localDisfluencies = [...soundReps, ...interjections];
      });
      dashboardManager.fetchImprovedResults().then((results) {
        setState(() {
          _improvedResults = results;
        });
      });
    }
  }

  void removeDisfluencyLocally(String filename, String disfluencyType) {
    setState(() {
      _localDisfluencies.removeWhere(
        (item) =>
            item['filename'] == filename &&
            item['disfluencyType'] == disfluencyType,
      );
    });
  }

  void onPressedDone() {
    context.read<ScenarioSimManager>().resetScenario();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<Map<String, int>> _fetchAllSkillNames(DashboardManager manager) async {
    final Map<String, int> skillMap = {};
    for (var entry in manager.skillsPracticed.entries) {
      String skillName = await manager.getSkillName(entry.key);
      skillMap[skillName] = entry.value;
    }
    return skillMap;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardManager = context.watch<DashboardManager>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.yellowSecondary,
                  ),
                  strokeWidth: 3,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final skillNameMap = snapshot.data?[2] ?? {};

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Progress(
                    dashboardManager.numHintsUsed,
                    (dashboardManager.numWordsUsed /
                        dashboardManager.numPromptsGiven),
                    1 -
                        (dashboardManager.numUnclearResponses /
                            dashboardManager.numPromptsGiven),
                  ),
                  const SizedBox(height: 24),
                  SkillsPracticed(skillNameMap),
                  const SizedBox(height: 24),
                  if (dashboardManager.hintsGiven.isNotEmpty) ...[
                    HintsUsed(dashboardManager.hintsGiven),
                    const SizedBox(height: 24),
                  ],
                  if (_localDisfluencies.isNotEmpty) ...[
                    AiAnalytic(
                      files: _localDisfluencies,
                      onDeleteSuccess: removeDisfluencyLocally,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_improvedResults.isNotEmpty) ...[
                    ImproveResponses(improvedResponses: _improvedResults),
                    const SizedBox(height: 24),
                  ],
                  const SessionFeeling(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(text: "Retry", onPressed: () {}),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: PrimaryButton(text: "Done", onPressed: onPressedDone),
        ),
      ],
    );
  }
}
