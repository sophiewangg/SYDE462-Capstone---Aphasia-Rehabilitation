import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TutorialPlayer extends StatefulWidget {
  final VoidCallback onClose;

  const TutorialPlayer({
    super.key,
    required this.onClose,
  });

  @override
  State<TutorialPlayer> createState() => _TutorialPlayerState();
}

class _TutorialPlayerState extends State<TutorialPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/tutorial.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      });

    // When video ends, show the play button again
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          _controller.value.duration > Duration.zero) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isPlaying => _controller.value.isPlaying;

  bool get _isFinished =>
      _isInitialized &&
      _controller.value.position >= _controller.value.duration &&
      _controller.value.duration > Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Close button row
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0),
            child: IconButton(
              onPressed: () {
                _controller.pause();
                widget.onClose();
              },
              icon: const Icon(
                Icons.close,
                size: 28,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Video area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isInitialized
                ? _buildVideoPlayer()
                : const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.yellowPrimary,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Label text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Text(
                'Tutorial guide',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'A walkthrough of how your practice works',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),

            // Play button overlay — shown when paused or finished
            if (!_isPlaying || _isFinished)
              GestureDetector(
                onTap: () {
                  if (_isFinished) {
                    _controller.seekTo(Duration.zero);
                  }
                  _controller.play();
                  setState(() {});
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 44,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

            // Tap to pause when playing
            if (_isPlaying && !_isFinished)
              GestureDetector(
                onTap: () {
                  _controller.pause();
                  setState(() {});
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

            // Progress bar at bottom
            if (_isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.yellowPrimary,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}