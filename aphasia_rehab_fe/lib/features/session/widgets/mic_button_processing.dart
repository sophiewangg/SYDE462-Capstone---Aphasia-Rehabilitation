import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';

class MicButtonProcessing extends StatefulWidget {
  final bool fillWidth;
  final Color textColor;

  const MicButtonProcessing({super.key, this.fillWidth = false, this.textColor = Colors.white});

  @override
  State<MicButtonProcessing> createState() => _MicButtonProcessingState();
}

class _MicButtonProcessingState extends State<MicButtonProcessing>
    with TickerProviderStateMixin {
  static const Color _dotColor = Color(0xFF4A4E7A);
  static const double _dotSize = 10.0;
  static const int _dotCount = 3;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_dotCount, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((ctrl) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger each dot by 200ms
    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 5.0,
      children: [
        SizedBox(
          width: widget.fillWidth ? double.infinity : null,
          height: 72,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6D9E8),
              foregroundColor: AppColors.textPrimary,
              shape: const StadiumBorder(),
              minimumSize: widget.fillWidth
                  ? const Size(double.infinity, 72)
                  : const Size(170, 72),
              padding: EdgeInsets.zero,
              elevation: 2,
            ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_dotCount, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i < _dotCount - 1 ? 10.0 : 0),
                child: AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, _) {
                    // Fade + scale up/down
                    final value = _animations[i].value;
                    return Opacity(
                      opacity: 0.3 + (value * 0.7),
                      child: Transform.scale(
                        scale: 0.6 + (value * 0.4),
                        child: Container(
                          width: _dotSize,
                          height: _dotSize,
                          decoration: const BoxDecoration(
                            color: _dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          ),
        ),
        Text("Processing...", style: TextStyle(color: widget.textColor)),
      ],
    );
  }
}