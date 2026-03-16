/// Single menu entry for Bob's Eatery. Used by Menu and Receipt.
class MenuItemEntry {
  final String name;
  final double price;
  final String? description;
  final String section; // 'starters' | 'entrees' | 'sides' | 'drinks' | 'alcohol'

  const MenuItemEntry({
    required this.name,
    required this.price,
    this.description,
    required this.section,
  });
}

/// Bob's Eatery menu: intent ID → display name, price, description.
/// Keys match ScenarioSimManager orderItems (e.g. order_bruschetta, side_fries).
const Map<String, MenuItemEntry> bobsEateryMenu = {
  // Starters
  'order_bruschetta': MenuItemEntry(
    name: 'Bruschetta',
    price: 12,
    description: 'Toasted bread topped with fresh tomatoes,\ngarlic, basil, and olive oil.',
    section: 'starters',
  ),
  'order_soup': MenuItemEntry(
    name: 'Soup of the day',
    price: 10,
    description: "Chef's seasonal soup, served warm with\ntoasted bread. Ask the server for today's soup.",
    section: 'starters',
  ),
  // Entrées
  'order_steak': MenuItemEntry(
    name: 'Ribeye Steak',
    price: 34,
    description: 'Grilled steak cooked to your liking, served\nwith a side of either fries or salad.',
    section: 'entrees',
  ),
  'order_pasta': MenuItemEntry(
    name: 'Seafood Alfredo',
    price: 24,
    description: 'Fettuccine in creamy Alfredo sauce with\nshrimp and mixed seafood.',
    section: 'entrees',
  ),
  'order_chicken': MenuItemEntry(
    name: 'Chicken Katsu',
    price: 22,
    description: 'Crispy breaded chicken cutlet served with\nrice and katsu sauce.',
    section: 'entrees',
  ),
  // Sides (included with Ribeye Steak — not charged separately)
  'side_salad': MenuItemEntry(
    name: 'Side Salad',
    price: 0,
    section: 'sides',
  ),
  'side_fries': MenuItemEntry(
    name: 'Side Fries',
    price: 0,
    section: 'sides',
  ),
  // Drinks (if ever added to order intents)
  'order_soda': MenuItemEntry(name: 'Soda', price: 4, section: 'drinks'),
  'order_lemonade': MenuItemEntry(name: 'Lemonade', price: 4.50, section: 'drinks'),
  'order_tea': MenuItemEntry(name: 'Tea', price: 4.50, section: 'drinks'),
  'order_coffee': MenuItemEntry(name: 'Coffee', price: 4, section: 'drinks'),
  'order_beer': MenuItemEntry(name: 'Beer', price: 6, section: 'alcohol'),
  'order_wine': MenuItemEntry(name: 'Wine', price: 7, section: 'alcohol'),
};
