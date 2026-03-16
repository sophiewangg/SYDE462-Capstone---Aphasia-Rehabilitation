import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<Widget> _sectionItems(Map<String, MenuItemEntry> menu, String section) {
  final entries = menu.entries.where((e) => e.value.section == section).toList();
  final children = <Widget>[];
  for (var i = 0; i < entries.length; i++) {
    if (i > 0) children.add(const SizedBox(height: 24));
    final item = entries[i].value;
    children.addAll([
      Text(
        '${item.name} · ${item.price.toStringAsFixed(item.price == item.price.roundToDouble() ? 0 : 1)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      if (item.description != null)
        Text(
          item.description!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
    ]);
  }
  return children;
}

Widget _drinksColumn(String section, String heading) {
  final items = bobsEateryMenu.entries
      .where((e) => e.value.section == section)
      .map((e) => Text('${e.value.name} · ${e.value.price.toStringAsFixed(e.value.price == e.value.price.roundToDouble() ? 0 : 1)}'))
      .toList();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        heading,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      ...items,
    ],
  );
}

class Menu extends StatefulWidget {
  final double modalHeight;

  const Menu({super.key, required this.modalHeight});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: scenarioSimManager.isBobEateryModalOpen ? 0 : -widget.modalHeight,
            child: IgnorePointer(
              ignoring: !scenarioSimManager.isBobEateryModalOpen,
              child: Container(
                height:widget.modalHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Stack(
                    children: [
                      // Scrollable menu content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24 + 40,
                          24,
                          0,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: Text(
                                  "Bob's Eatery",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: 'Lily Script One',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Starters (from dict)
                              ..._sectionItems(bobsEateryMenu, 'starters'),

                              const SizedBox(height: 32),

                              // Entrées box (from dict)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Center(
                                      child: Text(
                                        "ENTRÉES",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._sectionItems(bobsEateryMenu, 'entrees'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Drinks and Alcohol columns (from dict)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 170),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _drinksColumn('drinks', 'DRINKS'),
                                    _drinksColumn('alcohol', 'ALCOHOL'),
                                  ],
                                ),
                              ),
                    
                            ],
                          ),
                        ),
                      ),

                      // Fixed circular close button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            color: Colors.black87,
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(),
                            onPressed: scenarioSimManager.toggleBobEateryModal,
                          ),
                        ),
                      ),
                      
                      Positioned( // bottom rectangle for the hint, mic, and menu buttons
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4D4F75),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),  
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
