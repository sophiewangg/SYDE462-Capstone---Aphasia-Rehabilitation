import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Receipt extends StatelessWidget {
  final double receiptHeight;

  const Receipt({super.key, required this.receiptHeight});

  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    final isVisible = scenarioSimManager.showReceiptSheet;
    final orderItems = scenarioSimManager.orderItems;

    // Aggregate order: itemId -> count, then build lines from bobsEateryMenu
    final Map<String, int> counts = {};
    for (final id in orderItems) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    double subtotal = 0;
    final lineWidgets = <Widget>[];
    for (final e in counts.entries) {
      final entry = bobsEateryMenu[e.key];
      if (entry == null) continue;
      final qty = e.value;
      final lineTotal = entry.price * qty;
      subtotal += lineTotal;
      final label = qty > 1 ? '$qty ${entry.name}' : entry.name;
      lineWidgets.add(_receiptRow(context, label, _formatPrice(lineTotal)));
    }

    const taxRate = 0.08;
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: isVisible ? 0 : -receiptHeight,
      height: receiptHeight,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16 + 150),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Bob's Eatery",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '123 CULINARY AVE',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'DOWNTOWN DISTRICT',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'PHONE: (555) 123-4567',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...lineWidgets,
                        if (lineWidgets.isEmpty)
                          Text(
                            'No items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        _receiptRow(context, 'SUBTOTAL', _formatPrice(subtotal), bold: true),
                        _receiptRow(context, 'TAX', _formatPrice(tax), bold: true),
                        _receiptRow(context, 'TOTAL', _formatPrice(total), bold: true),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Positioned(
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

  static String _formatPrice(double value) =>
      '\$${value.toStringAsFixed(2)}';

  Widget _receiptRow(BuildContext context, String left, String right,
      {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 14 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(left, style: style, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(right, style: style),
        ],
      ),
    );
  }
}
