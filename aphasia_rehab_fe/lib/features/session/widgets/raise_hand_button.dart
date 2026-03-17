import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';

/// A circular "raise hand" button that appears during specific dialogue stages.
/// - Pulses/blinks when first shown to draw attention
/// - On press: stops pulsing, shows pushed color, moves upward slightly
/// - Designed for the dialogue layer in the restaurant scenario
class RaiseHandButton extends StatefulWidget {
  final VoidCallback onPressed;

  const RaiseHandButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<RaiseHandButton> createState() => _RaiseHandButtonState();
}

class _RaiseHandButtonState extends State<RaiseHandButton>
    with SingleTickerProviderStateMixin {
  bool _hasBeenPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_hasBeenPressed) return;
    setState(() => _hasBeenPressed = true);
    _pulseController.stop();
    // Brief delay so pushed state is visible before scenario transitions
    Future.delayed(const Duration(milliseconds: 250), widget.onPressed);
  }

  @override
  Widget build(BuildContext context) {
    final isPushed = _hasBeenPressed;

    // Pushed: solid darker color, moved up
    final backgroundColor = isPushed
        ? AppColors.yellowSecondary
        : AppColors.yellowPrimary;
    final iconColor = isPushed
        ? AppColors.yellowTertiary
        : AppColors.yellowSecondary;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          isPushed ? -8 : 0,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // Only show pulse ring when not pushed
                if (isPushed) return child!;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing outer ring
                    Container(
                      width: 72 * _pulseAnimation.value,
                      height: 72 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.yellowPrimary.withOpacity(0.35),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.front_hand,
                  size: 36,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to raise hand',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
