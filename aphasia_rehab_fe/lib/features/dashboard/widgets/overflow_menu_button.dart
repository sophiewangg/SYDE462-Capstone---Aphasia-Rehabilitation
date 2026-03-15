import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class OverflowMenuButton extends StatelessWidget {
  final String filename;
  final String disfluencyType;
  final Function(String, String) onDeleteSuccess;

  const OverflowMenuButton({
    super.key,
    required this.filename,
    required this.disfluencyType,
    required this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final DashboardManager dashboardManager = context.watch<DashboardManager>();

    return PopupMenuButton<String>(
      popUpAnimationStyle: AnimationStyle(
        duration: Duration.zero,
        reverseDuration: Duration.zero,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      offset: const Offset(-120, -130),
      onSelected: (String value) async {
        if (value == 'helpful') {
          print("Marked as Helpful");
        } else if (value == 'incorrect') {
          int? res = await dashboardManager.clearDetection(
            filename,
            disfluencyType,
          );

          if (res == 200) {
            onDeleteSuccess(filename, disfluencyType);
          } else {
            print("Failed to delete. Status code: $res");
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'helpful',
          height: 50,
          child: Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                color: Color(0xFF386641),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Helpful',
                style: TextStyle(
                  color: Color(0xFF386641),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'incorrect',
          height: 50,
          child: Row(
            children: [
              const Icon(
                Icons.thumb_down_outlined,
                color: Color(0xFFBC4749),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Incorrect',
                style: TextStyle(
                  color: Color(0xFFBC4749),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      child: SvgPicture.asset(
        'assets/icons/overflow_menu_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 20,
      ),
    );
  }
}
