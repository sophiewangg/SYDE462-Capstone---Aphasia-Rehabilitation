import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectHint extends StatefulWidget {
  const SelectHint({super.key});

  @override
  State<SelectHint> createState() => _SelectHintState();
}

class _SelectHintState extends State<SelectHint> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    const double borderRadius = 8.0;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.boxBorder, width: 1.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 35,
              child: InkWell(
                onTap: () => scenarioSimManager.handleHintPressed(
                  isWordFinding: true,
                  context: context,
                ), // Call the provided callback
                // Wrap the image here
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(borderRadius),
                  ),
                  child: Image.asset(
                    'assets/images/help_finding_word_image.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(width: 1, color: AppColors.boxBorder),
            Expanded(
              flex: 35,
              child: InkWell(
                onTap: () => scenarioSimManager.handleHintPressed(
                  isWordFinding: false,
                  context: context,
                ), // Call the provided callback
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: Image.asset(
                    'assets/images/i_dont_understand_image.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
