import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';

class PlayAudioButton extends StatefulWidget {
  const PlayAudioButton({super.key});

  @override
  State<PlayAudioButton> createState() => _PlayAudioButtonState();
}

class _PlayAudioButtonState extends State<PlayAudioButton> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose(); // Always clean up your players
    super.dispose();
  }

  void _playSound() async {
    // Play the audio from assets
    await _player.play(AssetSource('audio_clips/server_speech_1.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _playSound();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.grey100,
        foregroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(
          10,
        ),
        elevation: 2,
      ),
      child: SvgPicture.asset(
        'assets/icons/audio_icon.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
        width: 20,
      ),
    );
  }
}
