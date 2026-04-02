import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/common/tutorial_player.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/scenario_sim.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ScenarioOverview extends StatefulWidget {
  final String title;
  final String timeEstimate;
  final String imagePath;
  final List<String> overviewItems;

  const ScenarioOverview({
    super.key,
    this.title = 'Going to a restaurant',
    this.timeEstimate = '5-7 min',
    this.imagePath = 'assets/images/restaurant_image.png',
    this.overviewItems = const [
      'Small talk',
      'Ordering food & drinks',
      'Receiving food',
      'Paying for food',
    ],
  });

  @override
  State<ScenarioOverview> createState() => _ScenarioOverviewState();
}

class _ScenarioOverviewState extends State<ScenarioOverview> {
  bool _showTutorial = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showTutorial
            ? TutorialPlayer(
                onClose: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
              )
            : _buildOverviewContent(context),
      ),
    );
  }

  Widget _buildOverviewContent(BuildContext context) {
    return Column(
      children: [
        // Back button row
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0),
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
              ),
              label: Text(
                'Back',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Scenario illustration
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.imagePath,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),

                // Time estimate pill + Watch tutorial button
                Row(
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.boxBorder),
                      ),
                      child: Text(
                        widget.timeEstimate,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Watch tutorial button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTutorial = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.boxBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Watch tutorial',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Overview section
                Text(
                  'Overview:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...widget.overviewItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, right: 10.0),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Start button pinned at bottom
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final manager = Provider.of<ScenarioSimManager>(
                  context,
                  listen: false,
                );
                final config = createLocalImageConfiguration(context);
                await manager.init(config);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScenarioSim()),
                  );
                }
              },
              icon: SvgPicture.asset(
                'assets/icons/start_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
                width: 16,
              ),
              label: Text(
                'Start',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowPrimary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}