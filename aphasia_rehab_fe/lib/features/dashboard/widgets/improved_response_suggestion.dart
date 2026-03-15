import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/dashboard/widgets/hint_audio_button.dart';
import 'package:aphasia_rehab_fe/models/improved_response_model.dart';
import 'package:flutter/material.dart';

class ImprovedResponseSuggestion extends StatefulWidget {
  ImprovedResponse improvedResponse;
  ImprovedResponseSuggestion({super.key, required this.improvedResponse});

  @override
  State<ImprovedResponseSuggestion> createState() =>
      _ImprovedResponseSuggestionState();
}

class _ImprovedResponseSuggestionState
    extends State<ImprovedResponseSuggestion> {
  // Logic to track if the section is open or closed
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2E9), // The light beige background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 1. HEADER SECTION
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    HintAudioButton(
                      widget.improvedResponse.prompt,
                      '${widget.improvedResponse.taskId}/prompt',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.improvedResponse.prompt,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),

            // 2. EXPANDABLE CONTENT
            if (_isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You said",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResponseBox(
                      text: widget.improvedResponse.response,
                      id: '${widget.improvedResponse.taskId}/response',
                      backgroundColor:
                          AppColors.cueModalInProgress, // Light orange
                      iconColor: Colors.black,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Icon(Icons.south, color: Colors.grey, size: 20),
                      ),
                    ),
                    const Text(
                      "Try these next time",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResponseBox(
                      text: widget.improvedResponse.improvedResponse1,
                      id: '${widget.improvedResponse.improvedResponse1}/improvedResponse1',
                      backgroundColor:
                          AppColors.cueModalComplete, // Light green
                      iconColor: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    _buildResponseBox(
                      text: widget.improvedResponse.improvedResponse2,
                      id: '${widget.improvedResponse.improvedResponse1}/improvedResponse2',
                      backgroundColor:
                          AppColors.cueModalComplete, // Light green
                      iconColor: Colors.black,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build the individual response rows
  Widget _buildResponseBox({
    required String text,
    required String id,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          HintAudioButton(text, id),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
