import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectHint extends StatefulWidget {
  const SelectHint({super.key});

  @override
  State<SelectHint> createState() => _SelectHintState();
}

class _SelectHintState extends State<SelectHint> {
  @override
  Widget build(BuildContext context) {
    final hintManager = context.watch<HintManager>();

    const double borderRadius = 8.0;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHintOption(
            imagePath: 'assets/images/help_finding_word_image.png',
            label: "I can't think of a word",
            onTap: () => hintManager.startHintFlow(
              isWordFinding: true,
              context: context,
            ),
          ),
          Container(height: 1, color: AppColors.boxBorder),
          _buildHintOption(
            imagePath: 'assets/images/i_dont_understand_image.png',
            label: "I don't understand",
            onTap: () => hintManager.startHintFlow(
              isWordFinding: false,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintOption({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.grey100,
        highlightColor: AppColors.grey100.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
