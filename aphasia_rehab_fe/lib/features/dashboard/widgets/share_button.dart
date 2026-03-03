import 'package:aphasia_rehab_fe/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShareButton extends StatefulWidget {
  const ShareButton({super.key});

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10.0,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            fixedSize: const Size(64, 64),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.all(12),
            shape: const CircleBorder(),
            side: const BorderSide(color: AppColors.boxBorder, width: 1),
          ),
          child: SvgPicture.asset(
            'assets/icons/share_icon.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
            width: 24,
          ),
        ),
        Text("Share", style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
