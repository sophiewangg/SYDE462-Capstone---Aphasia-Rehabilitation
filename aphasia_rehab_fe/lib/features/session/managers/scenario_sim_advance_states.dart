part of 'scenario_sim_manager.dart';

/// State pattern: each [ScenarioStep] with advance behavior implements this contract.
abstract class _ScenarioSimAdvanceState {
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  );
}

const String _didNotUnderstandMessage =
    "I'm not sure I understood. Could you try saying that another way?";

Future<void> _fallbackDontUnderstand(
  ScenarioSimManager context,
  ImageConfiguration config,
) async {
  await context._triggerFallback(_didNotUnderstandMessage, config);
}

bool _containsAnyIntent(List<String> intents, List<String> candidates) {
  return candidates.any(intents.contains);
}

final class _NoOpAdvanceState implements _ScenarioSimAdvanceState {
  const _NoOpAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {}
}

final class _ReservationAdvanceState implements _ScenarioSimAdvanceState {
  const _ReservationAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains("reservation_yes")) {
      context._currentStep = ScenarioStep.reservationName;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else if (intents.contains("reservation_no")) {
      context._currentStep = ScenarioStep.numberPeople;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _ReservationNameAdvanceState implements _ScenarioSimAdvanceState {
  const _ReservationNameAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._currentStep = ScenarioStep.numberPeople;
    await context._handleScenarioStepChange(context._currentStep, config);
  }
}

final class _NumberPeopleAdvanceState implements _ScenarioSimAdvanceState {
  const _NumberPeopleAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._currentStep = ScenarioStep.drinksOffer;
    await context._handleScenarioStepChange(context._currentStep, config);
    context._isBobEateryModalOpen = true;
    context.notifyListeners();
  }
}

final class _DrinksOfferAdvanceState implements _ScenarioSimAdvanceState {
  const _DrinksOfferAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('water_still') ||
        intents.contains('water_sparkling') ||
        intents.contains('beverage_other')) {
      context._currentStep = ScenarioStep.iceQuestion;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else if (intents.contains('beverage_water')) {
      context._currentStep = ScenarioStep.waterType;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else if (intents.contains('no_drink')) {
      context._currentStep = ScenarioStep.readyToOrder;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _WaterTypeAdvanceState implements _ScenarioSimAdvanceState {
  const _WaterTypeAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (_containsAnyIntent(intents, ['water_still', 'water_sparkling'])) {
      context._currentStep = ScenarioStep.iceQuestion;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _IceQuestionAdvanceState implements _ScenarioSimAdvanceState {
  const _IceQuestionAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (context._orderItems.isNotEmpty ||
        context._wantsNoAppetizers ||
        context._wantsNoEntrees) {
      context._currentStep = context._determineNextLogicalStep();
    } else {
      context._currentStep = ScenarioStep.readyToOrder;
    }

    await context._handleScenarioStepChange(context._currentStep, config);
  }
}

final class _ReadyToOrderAdvanceState implements _ScenarioSimAdvanceState {
  const _ReadyToOrderAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('ready_no')) {
      context._promptOverride =
          "No problem, just say 'I'm ready to order' when you've decided.";
      context.notifyListeners();
      await context._handlePromptOverride(config, false);
    } else if (intents.contains('ready_yes') ||
        orderedNewItems ||
        context._wantsNoAppetizers ||
        context._wantsNoEntrees) {
      context._currentStep = context._determineNextLogicalStep();
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _AppetizersAdvanceState implements _ScenarioSimAdvanceState {
  const _AppetizersAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('ask_specials') || intents.contains('ask_soup')) {
      context._promptOverride = "Today's soup is creamy roasted garlic.";
      context.notifyListeners();
      await context._handlePromptOverride(config, false);
    } else if (intents.contains('ask_recommendations')) {
      context._promptOverride = "My personal favourite is the ribeye steak.";
      context.notifyListeners();
      await context._handlePromptOverride(config, false);
    } else if (orderedNewItems ||
        context._wantsNoAppetizers ||
        context._wantsNoEntrees) {
      context._currentStep = context._determineNextLogicalStep();
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _EntreesAdvanceState implements _ScenarioSimAdvanceState {
  const _EntreesAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (orderedNewItems || context._wantsNoEntrees) {
      context._currentStep = context._determineNextLogicalStep();
      await context._handleScenarioStepChange(context._currentStep, config);
    }
  }
}

final class _SteakDonenessAdvanceState implements _ScenarioSimAdvanceState {
  const _SteakDonenessAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('steak_doneness')) {
      context._currentStep = context._determineNextLogicalStep();
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _SideChoiceAdvanceState implements _ScenarioSimAdvanceState {
  const _SideChoiceAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (orderedNewItems) {
      context._currentStep = context._determineNextLogicalStep();
      await context._handleScenarioStepChange(context._currentStep, config);
    }
  }
}

final class _IsThatAllAdvanceState implements _ScenarioSimAdvanceState {
  const _IsThatAllAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('is_that_all_yes')) {
      context._servedItems.clear();
      context._servedItems.addAll(context._orderItems);

      if (context._currentCurveball == ScenarioCurveball.wrongOrder) {
        const allEntrees = ['order_pasta', 'order_chicken', 'order_steak'];
        const allApps = ['order_bruschetta', 'order_soup'];

        final orderedEntree = context._servedItems.cast<String?>().firstWhere(
          (item) => allEntrees.contains(item),
          orElse: () => null,
        );
        context._orderedEntree = orderedEntree;

        if (orderedEntree != null) {
          final wrongEntrees = allEntrees
              .where((item) => item != orderedEntree)
              .toList();
          final wrongEntree =
              wrongEntrees[context._random.nextInt(wrongEntrees.length)];
          context._servedItems.remove(orderedEntree);
          context._servedItems.add(wrongEntree);
          context._wrongEntree = wrongEntree;
          print("⚾ CURVEBALL APPLIED: Swapped $orderedEntree for $wrongEntree");
        } else {
          final orderedApp = context._servedItems.cast<String?>().firstWhere(
            (item) => allApps.contains(item),
            orElse: () => null,
          );

          if (orderedApp != null) {
            final wrongApps = allApps
                .where((item) => item != orderedApp)
                .toList();
            final wrongApp =
                wrongApps[context._random.nextInt(wrongApps.length)];
            context._servedItems.remove(orderedApp);
            context._servedItems.add(wrongApp);
            print("⚾ CURVEBALL APPLIED: Swapped $orderedApp for $wrongApp");
          } else {
            context._servedItems.add(
              allEntrees[context._random.nextInt(allEntrees.length)],
            );
          }
        }
      }

      if (context._currentCurveball == ScenarioCurveball.longWait) {
        context._currentStep = ScenarioStep.beBackShortly;
      } else if (context._servedItems.contains('order_bruschetta')) {
        context._currentStep = ScenarioStep.hereBruschetta;
      } else if (context._servedItems.contains('order_soup')) {
        context._currentStep = ScenarioStep.hereSoup;
      } else if (context._servedItems.contains('order_pasta')) {
        context._currentStep = ScenarioStep.herePasta;
      } else if (context._servedItems.contains('order_chicken')) {
        context._currentStep = ScenarioStep.hereChicken;
      } else if (context._servedItems.contains('order_steak')) {
        context._currentStep = ScenarioStep.hereSteak;
      } else {
        context._currentStep = ScenarioStep.howIsEverything;
      }
      await context.updateFoodVisuals(context._servedItems, config);
      await context._handleScenarioStepChange(context._currentStep, config);
    } else if (intents.contains('is_that_all_no')) {
      context._currentStep = ScenarioStep.appetizers;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _BeBackShortlyAdvanceState implements _ScenarioSimAdvanceState {
  const _BeBackShortlyAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._showWaitTimer = true;
    context._simulatedWaitMinutes = 0;
    context.notifyListeners();

    for (int i = 1; i <= 45; i++) {
      await context._delay(const Duration(milliseconds: 100));
      context._simulatedWaitMinutes = i;
      context.notifyListeners();
    }

    context._showWaitTimer = false;
    context._showSystemMessage = true;
    context._showRaiseHandButton = true;
    context.notifyListeners();
  }
}

final class _HowHelpAdvanceState implements _ScenarioSimAdvanceState {
  const _HowHelpAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._showRaiseHandButton = false;
    context._currentStep = ScenarioStep.checkOrder;
    await context._handleScenarioStepChange(context._currentStep, config);
    context.notifyListeners();
  }
}

final class _CheckOrderAdvanceState implements _ScenarioSimAdvanceState {
  const _CheckOrderAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._currentCurveball = ScenarioCurveball.none;

    if (context._servedItems.contains('order_bruschetta')) {
      context._currentStep = ScenarioStep.hereBruschetta;
    } else if (context._servedItems.contains('order_soup')) {
      context._currentStep = ScenarioStep.hereSoup;
    } else if (context._servedItems.contains('order_pasta')) {
      context._currentStep = ScenarioStep.herePasta;
    } else if (context._servedItems.contains('order_chicken')) {
      context._currentStep = ScenarioStep.hereChicken;
    } else if (context._servedItems.contains('order_steak')) {
      context._currentStep = ScenarioStep.hereSteak;
    } else {
      context._currentStep = ScenarioStep.howIsEverything;
    }

    await context._handleScenarioStepChange(context._currentStep, config);
    context.notifyListeners();
  }
}

final class _WrongOrderNudgeAdvanceState implements _ScenarioSimAdvanceState {
  const _WrongOrderNudgeAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    final saidNo = intents.any((i) => ['nudge_no'].contains(i));

    if (saidNo) {
      print("✅ Curveball successfully navigated (Via Nudge)!");
      await context._executeCorrectionSequence(config);
    } else {
      if (_containsAnyIntent(intents, ['nudge_yes'])) {
        print("❌ Curveball Failed: User accepted wrong food after nudge.");
        context._currentCurveball = ScenarioCurveball.none;
        context._currentStep = ScenarioStep.howIsEverything;
        await context._handleScenarioStepChange(context._currentStep, config);
      } else {
        await _fallbackDontUnderstand(context, config);
      }
    }
  }
}

final class _HereAppetizerAdvanceState implements _ScenarioSimAdvanceState {
  const _HereAppetizerAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (context._servedItems.contains('order_pasta')) {
      context._currentStep = ScenarioStep.herePasta;
    } else if (context._servedItems.contains('order_chicken')) {
      context._currentStep = ScenarioStep.hereChicken;
    } else if (context._servedItems.contains('order_steak')) {
      context._currentStep = ScenarioStep.hereSteak;
    } else {
      context._currentStep = ScenarioStep.howIsEverything;
    }
    await context.precacheFood(context._appetizerUrl!, config);
    await context._handleScenarioStepChange(context._currentStep, config);
  }
}

final class _HereEntreeAdvanceState implements _ScenarioSimAdvanceState {
  const _HereEntreeAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    await context.precacheFood(context.entreeUrl!, config);
    context._currentStep = ScenarioStep.howIsEverything;
    await context._handleScenarioStepChange(context._currentStep, config);
  }
}

final class _HowIsEverythingAdvanceState implements _ScenarioSimAdvanceState {
  const _HowIsEverythingAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._currentStep = ScenarioStep.areYouDone;
    await context._handleScenarioStepChange(context._currentStep, config);
  }
}

final class _AreYouDoneAdvanceState implements _ScenarioSimAdvanceState {
  const _AreYouDoneAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('done_eating_yes')) {
      context._currentStep = ScenarioStep.readyForBill;
      await context._handleScenarioStepChange(context._currentStep, config);
    } else if (intents.contains('done_eating_no')) {
      context._promptOverride =
          "No problem, call me over when you're ready by saying 'I'm done'";
      context.notifyListeners();
      await context._handlePromptOverride(config, false);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _ReadyForBillAdvanceState implements _ScenarioSimAdvanceState {
  const _ReadyForBillAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (intents.contains('ready_for_bill_yes')) {
      context._currentStep = ScenarioStep.checkReceipt;

      if (context._currentCurveball == ScenarioCurveball.wrongReceipt) {
        context._showStaticReceiptSheet = true;
      } else {
        context._showReceiptSheet = true;
      }

      await context._handleScenarioStepChange(context._currentStep, config);
      context.notifyListeners();
    } else if (intents.contains('ready_for_bill_no')) {
      context._promptOverride =
          "No problem, call me over when you're ready by saying 'I'm ready for the bill'";
      context.notifyListeners();
      await context._handlePromptOverride(config, false);
    } else {
      await _fallbackDontUnderstand(context, config);
    }
  }
}

final class _CheckReceiptAdvanceState implements _ScenarioSimAdvanceState {
  const _CheckReceiptAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    if (context._currentCurveball == ScenarioCurveball.wrongReceipt &&
        intents.contains('wrong_receipt')) {
      context._currentStep = ScenarioStep.resolveReceipt;
      context._showReceiptSheet = true;
    } else {
      context._showReceiptSheet = false;
      context._currentStep = ScenarioStep.paymentMethod;
    }

    context._showStaticReceiptSheet = false;
    await context._handleScenarioStepChange(context._currentStep, config);
    context.notifyListeners();
  }
}

final class _ResolveReceiptAdvanceState implements _ScenarioSimAdvanceState {
  const _ResolveReceiptAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._showReceiptSheet = false;
    context._showStaticReceiptSheet = false;

    context._currentStep = ScenarioStep.paymentMethod;
    await context._handleScenarioStepChange(context._currentStep, config);
    context.notifyListeners();
  }
}

final class _PaymentMethodAdvanceState implements _ScenarioSimAdvanceState {
  const _PaymentMethodAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._currentStep = ScenarioStep.receipt;
    await context._handleScenarioStepChange(context._currentStep, config);
    context.notifyListeners();
  }
}

final class _ReceiptAdvanceState implements _ScenarioSimAdvanceState {
  const _ReceiptAdvanceState();

  @override
  Future<void> advance(
    ScenarioSimManager context,
    List<String> intents,
    bool orderedNewItems,
    ImageConfiguration config,
  ) async {
    context._isScenarioComplete = true;
    context._promptOverride =
        "Thank you for dining with us! Have a wonderful day.";
    context._currentCharacter = context._currentPrompt!.imageSpeakingUrl;
    context.notifyListeners();
    await context._handlePromptOverride(config, false);
    context.navigateToDashboardPage();
  }
}

/// Maps each [ScenarioStep] to its advance state (State pattern).
_ScenarioSimAdvanceState _scenarioSimAdvanceStateFor(ScenarioStep step) {
  switch (step) {
    case ScenarioStep.reservation:
      return const _ReservationAdvanceState();
    case ScenarioStep.reservationName:
      return const _ReservationNameAdvanceState();
    case ScenarioStep.numberPeople:
      return const _NumberPeopleAdvanceState();
    case ScenarioStep.drinksOffer:
      return const _DrinksOfferAdvanceState();
    case ScenarioStep.waterType:
      return const _WaterTypeAdvanceState();
    case ScenarioStep.iceQuestion:
      return const _IceQuestionAdvanceState();
    case ScenarioStep.readyToOrder:
      return const _ReadyToOrderAdvanceState();
    case ScenarioStep.appetizers:
      return const _AppetizersAdvanceState();
    case ScenarioStep.entrees:
      return const _EntreesAdvanceState();
    case ScenarioStep.steakDoneness:
      return const _SteakDonenessAdvanceState();
    case ScenarioStep.sideChoice:
      return const _SideChoiceAdvanceState();
    case ScenarioStep.isThatAll:
      return const _IsThatAllAdvanceState();
    case ScenarioStep.beBackShortly:
      return const _BeBackShortlyAdvanceState();
    case ScenarioStep.howHelp:
      return const _HowHelpAdvanceState();
    case ScenarioStep.checkOrder:
      return const _CheckOrderAdvanceState();
    case ScenarioStep.wrongOrderApology:
    case ScenarioStep.wrongOrderResolvedPasta:
    case ScenarioStep.wrongOrderResolvedChicken:
    case ScenarioStep.wrongOrderResolvedSteak:
    case ScenarioStep.notReadyToOrder:
      return const _NoOpAdvanceState();
    case ScenarioStep.wrongOrderNudge:
      return const _WrongOrderNudgeAdvanceState();
    case ScenarioStep.hereBruschetta:
    case ScenarioStep.hereSoup:
      return const _HereAppetizerAdvanceState();
    case ScenarioStep.herePasta:
    case ScenarioStep.hereChicken:
    case ScenarioStep.hereSteak:
      return const _HereEntreeAdvanceState();
    case ScenarioStep.howIsEverything:
      return const _HowIsEverythingAdvanceState();
    case ScenarioStep.areYouDone:
      return const _AreYouDoneAdvanceState();
    case ScenarioStep.readyForBill:
      return const _ReadyForBillAdvanceState();
    case ScenarioStep.checkReceipt:
      return const _CheckReceiptAdvanceState();
    case ScenarioStep.resolveReceipt:
      return const _ResolveReceiptAdvanceState();
    case ScenarioStep.paymentMethod:
      return const _PaymentMethodAdvanceState();
    case ScenarioStep.receipt:
      return const _ReceiptAdvanceState();
  }
}
