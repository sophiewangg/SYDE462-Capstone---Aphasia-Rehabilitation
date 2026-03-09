enum ScenarioStep {
  reservation('reservation'),
  reservationName('reservationName'),
  numberPeople('numberPeople'),
  drinksOffer('drinksOffer'),
  waterType('waterType'),
  iceQuestion('iceQuestion'),
  readyToOrder('readyToOrder'),
  appetizers('appetizers'),
  entrees('entrees'),
  steakDoneness('steakDoneness'),
  sideChoice('sideChoice'),
  isThatAll('isThatAll'),
  notReadyToOrder('notReadyToOrder'),
  howIsEverything('howIsEverything'),
  areYouDone('areYouDone'),
  readyForBill('readyForBill'),
  paymentMethod('paymentMethod'),
  receipt('receipt');

  // The internal string ID
  final String id;

  // Constructor
  const ScenarioStep(this.id);

  // Helper to find an enum by its string ID (useful for API responses)
  static ScenarioStep fromId(String id) {
    return ScenarioStep.values.firstWhere(
      (step) => step.id == id,
      orElse: () => ScenarioStep.drinksOffer,
    );
  }

  /// Returns the snake_case string required by the PostgreSQL database.
  String get dbValue {
    switch (this) {
      case ScenarioStep.reservation:
        return 'reservation';
      case ScenarioStep.reservationName:
        return 'reservation_name';
      case ScenarioStep.numberPeople:
        return 'number_people';
      case ScenarioStep.drinksOffer:
        return 'drinks_offer';
      case ScenarioStep.waterType:
        return 'water_type';
      case ScenarioStep.iceQuestion:
        return 'ice_question';
      case ScenarioStep.readyToOrder:
        return 'ready_to_order';
      case ScenarioStep.appetizers:
        return 'appetizers';
      case ScenarioStep.entrees:
        return 'entrees';
      case ScenarioStep.steakDoneness:
        return 'steak_doneness';
      case ScenarioStep.sideChoice:
        return 'side_choice';
      case ScenarioStep.isThatAll:
        return 'is_that_all';
      case ScenarioStep.notReadyToOrder:
        return 'not_ready_to_order';
      case ScenarioStep.howIsEverything:
        return 'how_is_everything';
      case ScenarioStep.areYouDone:
        return 'are_you_done';
      case ScenarioStep.readyForBill:
        return 'ready_for_bill';
      case ScenarioStep.paymentMethod:
        return 'payment_method';
      case ScenarioStep.receipt:
        return 'receipt';
    }
  }
}
