import 'package:aphasia_rehab_fe/common/start_button.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/colors.dart';

class ContinueSession extends StatefulWidget {
  const ContinueSession({super.key});

  @override
  State<ContinueSession> createState() => _ContinueSessionState();
}

class _ContinueSessionState extends State<ContinueSession> {
  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              "Continue where you left off",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.boxBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 35, // 35% of the space
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/restaurant_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  flex: 65, // 65% of the space
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.boxBorder)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ordering at a restaurant",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            "3 mins left",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: StartButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }
}
