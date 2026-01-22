import 'package:aphasia_rehab_fe/features/session/session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartButton extends StatefulWidget {
  const StartButton({super.key});

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          double.infinity, // This forces the button to fill all available width
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SessionPage(title: "My Session"),
            ),
          );
        },
        icon: SvgPicture.asset(
          'assets/icons/start_icon.svg',
          colorFilter: const ColorFilter.mode(
            Colors.textPrimary,
            BlendMode.srcIn,
          ),
          width: 16,
        ),

        label: Text('Start', style: Theme.of(context).textTheme.titleMedium),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowPrimary,
          foregroundColor: Colors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
