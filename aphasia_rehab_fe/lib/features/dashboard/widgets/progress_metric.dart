import 'package:flutter/material.dart';

class ProgressMetric extends StatefulWidget {
  final String title;
  final String value;
  final double width;
  final bool hasTooltip;
  final double? clearPercentage;

  const ProgressMetric({
    super.key,
    required this.title,
    required this.value,
    required this.width,
    required this.hasTooltip,
    this.clearPercentage,
  });

  @override
  State<ProgressMetric> createState() => _ProgressMetricState();
}

class _ProgressMetricState extends State<ProgressMetric> {
  // 1. Add a state variable to track visibility
  bool _isTooltipVisible = false;

  String getOverUnder() {
    if (widget.clearPercentage != null && widget.clearPercentage! < 0.5) {
      return "under";
    }
    return "over";
  }

  int getPercentage() {
    return switch (widget.clearPercentage!) {
      >= 0.95 => 95,
      >= 0.90 => 90,
      >= 0.70 => 70,
      >= 0.5 => 50,
      _ => 50, // The 'default' case
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.width,
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.hasTooltip)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTooltipVisible = !_isTooltipVisible;
                        });
                      },
                      child: Icon(
                        Icons.info_outline,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),

        if (widget.hasTooltip != null && _isTooltipVisible)
          Positioned(
            bottom: 79,
            right: 6,
            child: CustomPaint(
              painter: TooltipTailPainter(),
              child: Container(
                width: widget.width * 1.2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Your answer was understood ',
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text:
                            '${getOverUnder()} ${getPercentage()}% ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: 'of the time',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TooltipTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE2E5E9);
    final path = Path();
    // Triangle tip aligned with the icon
    path.moveTo(size.width - 30, size.height);
    path.lineTo(size.width - 20, size.height + 8);
    path.lineTo(size.width - 10, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
