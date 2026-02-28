import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  child: Stack(
                    children: [
                      // Scrollable menu content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24 + 40,
                          24,
                          120,
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

                              // Starters
                              const Text(
                                "Bruschetta · 12",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Toasted bread topped with fresh tomatoes,\ngarlic, basil, and olive oil.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Soup of the day · 10",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Chef's seasonal soup, served warm with\ntoasted bread. Ask the server for today's soup.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 32),

                              // Entrées box
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
                                  children: const [
                                    Center(
                                      child: Text(
                                        "ENTRÉES",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Ribeye Steak · 34",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Grilled steak cooked to your liking, served\nwith a side of either fries or salad.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      "Seafood Alfredo · 24",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Fettuccine in creamy Alfredo sauce with\nshrimp and mixed seafood.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      "Chicken Katsu · 22",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Crispy breaded chicken cutlet served with\nrice and katsu sauce.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Drinks and Alcohol columns
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  // Drinks
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "DRINKS",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text("Soda · 4"),
                                      Text("Lemonade · 4.50"),
                                      Text("Tea · 4.50"),
                                      Text("Coffee · 4"),
                                    ],
                                  ),
                                  // Alcohol
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ALCOHOL",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text("Beer · 6"),
                                      Text("Wine · 100g · 7"),
                                    ],
                                  ),
                                ],
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
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: scenarioSimManager.toggleBobEateryModal,
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
