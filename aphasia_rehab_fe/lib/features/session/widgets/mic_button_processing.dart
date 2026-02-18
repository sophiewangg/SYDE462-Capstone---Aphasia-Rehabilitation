import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MicButtonProcessing extends StatefulWidget {
  const MicButtonProcessing({super.key});

  @override
  State<MicButtonProcessing> createState() => _MicButtonProcessingState();
}

class _MicButtonProcessingState extends State<MicButtonProcessing> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Implement audio play logic
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        shape: const StadiumBorder(),
        side: const BorderSide(color: Colors.black, width: 1.0),
        fixedSize: const Size(250, 75),
        padding: EdgeInsets.zero,
        elevation: 2,
      ),
      child: SvgPicture.asset(
        'assets/icons/processing_icon.svg',
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        width: 30,
      ),
    );
  }
}
