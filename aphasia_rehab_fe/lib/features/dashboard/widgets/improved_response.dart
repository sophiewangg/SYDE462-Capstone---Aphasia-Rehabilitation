import 'package:aphasia_rehab_fe/colors.dart';
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
                    _buildSpeakerIcon(AppColors.textPrimary),
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
                      backgroundColor:
                          AppColors.cueModalComplete, // Light green
                      iconColor: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    _buildResponseBox(
                      text: widget.improvedResponse.improvedResponse2,
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

  // Helper to build the speaker icon inside a circle
  Widget _buildSpeakerIcon(Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(Icons.volume_up_outlined, color: iconColor, size: 24),
    );
  }

  // Helper to build the individual response rows
  Widget _buildResponseBox({
    required String text,
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
          _buildSpeakerIcon(iconColor),
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
