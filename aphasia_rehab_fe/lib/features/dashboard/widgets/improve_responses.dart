import 'package:aphasia_rehab_fe/features/dashboard/widgets/improved_response.dart';
import 'package:aphasia_rehab_fe/models/improved_response_model.dart';
import 'package:flutter/material.dart';

class ImproveResponses extends StatefulWidget {
  final List<ImprovedResponse> improvedResponses;

  const ImproveResponses({super.key, required this.improvedResponses});

  @override
  State<ImproveResponses> createState() => _ImproveResponsesState();
}

class _ImproveResponsesState extends State<ImproveResponses> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tips to improve responses",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          "Tap to learn more advanced phrases",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),

        for (var improvedResponse in widget.improvedResponses)
          ImprovedResponseSuggestion(improvedResponse: improvedResponse),
      ],
    );
  }
}
