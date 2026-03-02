import 'dart:math';
import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MicButtonSpeaking extends StatefulWidget {
  const MicButtonSpeaking({super.key});

  @override
  State<MicButtonSpeaking> createState() => _MicButtonSpeakingState();
}

class _MicButtonSpeakingState extends State<MicButtonSpeaking>
    with TickerProviderStateMixin {
  static const int _barCount = 6;
  static const double _maxBarHeight = 36.0;
  static const double _minBarHeight = 6.0;
  static const Color _barColor = Color(0xFF4A4E7A); // dark purple to match pause icon

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Give each bar a slightly different speed for organic feel
    _controllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(300)),
      );
    });

    _animations = _controllers.map((ctrl) {
      // Each bar animates between a random min and max within our bounds
      final low = _minBarHeight + _random.nextDouble() * 8;
      final high = _maxBarHeight - _random.nextDouble() * 8;
      return Tween<double>(begin: low, end: high).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger start times so bars don't all move in sync
    for (int i = 0; i < _barCount; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
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
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Column(
      spacing: 5.0,
      children: [
        ElevatedButton(
          onPressed: () {
            scenarioSimManager.handleMicToggle();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6D9E8), // light purple-grey from screenshot
            foregroundColor: AppColors.textPrimary,
            shape: const StadiumBorder(),
            fixedSize: const Size(170, 72),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            elevation: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Audio wave bars on the LEFT
              SizedBox(
                height: _maxBarHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_barCount, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < _barCount - 1 ? 4.0 : 0),
                      child: AnimatedBuilder(
                        animation: _animations[i],
                        builder: (context, _) {
                          return Container(
                            width: 3,
                            height: _animations[i].value,
                            decoration: BoxDecoration(
                              color: _barColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(width: 30),

              // Pause icon on the RIGHT
              SvgPicture.asset(
                'assets/icons/pause_icon.svg',
                colorFilter: const ColorFilter.mode(_barColor, BlendMode.srcIn),
                width: 22,
              ),
            ],
          ),
        ),
        Text("Listening...", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}