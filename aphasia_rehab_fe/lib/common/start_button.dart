import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/common/scenario_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScenarioOverview()),
          );
        },
        icon: SvgPicture.asset(
          'assets/icons/start_icon.svg',
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 16,
        ),
        label: Text('Start', style: Theme.of(context).textTheme.titleSmall),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellowPrimary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}