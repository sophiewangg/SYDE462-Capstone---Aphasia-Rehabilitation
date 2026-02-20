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
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 350,
        child: Stack(
          clipBehavior: Clip.none, // Required to let the tip sit on the border
          children: [
            // 1. The main Speech Bubble
            Container(
              // The margin creates space ABOVE the bubble for the tip to exist
              margin: const EdgeInsets.only(top: 20),
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
                child: Row(
                  spacing: 12.0,
                  children: [
                    PlayAudioButton(),
                    Expanded(
                      child: Text(
                        widget.prompt,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. The Tip (Positioned on the top border)
            Positioned(
              top:
                  -80, // Adjust this to move speech bubble tip higher
              left: 30,
              child: Image.asset(
                'assets/images/speech_bubble_tip_image.png',
                width: 150,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
