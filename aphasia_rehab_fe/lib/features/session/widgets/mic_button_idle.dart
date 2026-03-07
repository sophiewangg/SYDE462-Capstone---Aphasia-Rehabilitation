import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MicButtonIdle extends StatefulWidget {
  final bool fillWidth;

  const MicButtonIdle({super.key, this.fillWidth = false});

  @override
  State<MicButtonIdle> createState() => _MicButtonIdleState();
}

class _MicButtonIdleState extends State<MicButtonIdle> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 5.0,
      children: [
        SizedBox(
          width: widget.fillWidth ? double.infinity : null,
          height: 72,
          child: ElevatedButton(
            onPressed: () {
              final config = createLocalImageConfiguration(context);
              scenarioSimManager.handleMicToggle(config);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              shape: const StadiumBorder(),
              minimumSize: widget.fillWidth
                  ? const Size(double.infinity, 72)
                  : const Size(170, 72),
              padding: EdgeInsets.zero,
              elevation: 2,
            ),
            child: SvgPicture.asset(
              'assets/icons/mic_button.svg',
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              width: 30,
            ),
          ),
        ),
        Text("Tap to speak", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
