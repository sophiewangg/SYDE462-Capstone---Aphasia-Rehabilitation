enum ScenarioStep {
  drinksOffer,
  waterType,
  iceQuestion,
  readyToOrder,
  appetizers,
  entrees,
  steakDoneness,
  sideChoice,
  isThatAll,
  allergies,
  notReadyToOrder;

  /// Returns the snake_case string required by the PostgreSQL database.
  String get dbValue {
    switch (this) {
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
      case ScenarioStep.allergies:
        return 'allergies';
      case ScenarioStep.notReadyToOrder:
        return 'not_ready_to_order';
    }
  }
}
