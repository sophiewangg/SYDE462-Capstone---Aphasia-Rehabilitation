import 'package:flutter/material.dart';

class ProgressMetric extends StatefulWidget {
  final String title;
  final String value;
  final double width;
  const ProgressMetric({
    super.key,
    required this.title,
    required this.value,
    required this.width,
  });

  @override
  State<ProgressMetric> createState() => _ProgressMetricState();
}

class _ProgressMetricState extends State<ProgressMetric> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(widget.value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
