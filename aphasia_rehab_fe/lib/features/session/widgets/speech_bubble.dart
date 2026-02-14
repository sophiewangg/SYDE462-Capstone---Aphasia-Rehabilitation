import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_audio_button.dart';

class SpeechBubble extends StatefulWidget {
  final String prompt;

  const SpeechBubble({super.key, required this.prompt});

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  @override
  Widget build(BuildContext context) {
    // Wrapping in Align allows the Container to respect its 400 width
    return Align(
      alignment: Alignment.center, // or topCenter, centerRight, etc.
      child: Container(
        width: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.boxBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing:
                12.0, // This adds 12 pixels of space between the button and the text
            children: [
              PlayAudioButton(),
              Text(
                widget.prompt,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
