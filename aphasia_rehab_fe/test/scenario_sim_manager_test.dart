import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aphasia_rehab_fe/api_service.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/models/prompt_model.dart';
import 'package:aphasia_rehab_fe/models/scenario_step.dart';
import 'package:aphasia_rehab_fe/services/eleven_labs_service.dart';
import 'package:aphasia_rehab_fe/services/prompt_service.dart';
import 'package:aphasia_rehab_fe/services/transcription_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:path/path.dart' as p;

// --- Mocks ---
class MockScenarioApiService extends Mock implements ScenarioApiService {}

class MockPromptService extends Mock implements PromptService {}

class MockTranscriptionService extends Mock implements TranscriptionService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockElevenLabsService extends Mock implements ElevenLabsService {}

class MockDashboardManager extends Mock implements DashboardManager {}

class MockRandom extends Mock implements Random {}

class MockOrderCorrectionResult extends Mock implements OrderCorrectionResult {}

// Required fallback for mocktail to use any() with AudioSource
class FakeAudioSource extends Fake implements AudioSource {}

Prompt _emptyPrompt(ScenarioStep step) {
  return Prompt(
    id: 'p_${step.id}',
    scenarioStepId: step.id,
    audioUrl: 'https://test.com/audio.mp3',
    imageSpeakingUrl: 'https://test.com/speak.png',
    imageListeningUrl: 'https://test.com/listen.png',
    imageConfusedUrl: 'https://test.com/confused.png',
    skillPracticedId: 'skill',
    promptText: 'prompt',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  // Shared variables
  late MockScenarioApiService api;
  late MockPromptService prompt;
  late MockTranscriptionService tx;
  late MockAudioPlayer audio;
  late MockAudioPlayer overrideAudio;
  late MockElevenLabsService eleven;
  late MockDashboardManager dashboard;
  late MockRandom mockRandom;
  late ScenarioSimManager mgr;
  late StreamController<TranscriptionResult> controller;

  setUpAll(() {
    registerFallbackValue(ScenarioStep.reservation);
    registerFallbackValue(Uri.parse('https://test.com'));
    registerFallbackValue(FakeAudioSource());

    dotenv.testLoad(mergeWith: {'ELEVEN_LABS_API_KEY': 'dummy_test_key'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          final tempRoot = Directory.systemTemp.path;
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
              final docsDir = Directory(
                p.join(tempRoot, 'scenario_sim_manager_test_docs'),
              );
              // Physically create the fake directory if it doesn't exist
              if (!docsDir.existsSync()) {
                docsDir.createSync(recursive: true);
              }
              return docsDir.path;
            case 'getTemporaryDirectory':
              final tmpDir = Directory(
                p.join(tempRoot, 'scenario_sim_manager_test_tmp'),
              );
              // Physically create the fake directory if it doesn't exist
              if (!tmpDir.existsSync()) {
                tmpDir.createSync(recursive: true);
              }
              return tmpDir.path;
            default:
              return tempRoot;
          }
        });
  });

  setUp(() {
    api = MockScenarioApiService();
    prompt = MockPromptService();
    tx = MockTranscriptionService();
    audio = MockAudioPlayer();
    overrideAudio = MockAudioPlayer();
    eleven = MockElevenLabsService();
    dashboard = MockDashboardManager();
    mockRandom = MockRandom();
    controller = StreamController<TranscriptionResult>.broadcast();

    when(() => mockRandom.nextInt(any())).thenReturn(0);

    when(
      () => api.verifyOrderCorrection(any(), any(), any()),
    ).thenAnswer((_) async => null);

    when(() => dashboard.addSkillPracticed(any())).thenAnswer((_) {});
    when(() => dashboard.incrementNumPromptsGiven()).thenAnswer((_) {});
    when(() => dashboard.incrementNumWordsUsed(any())).thenAnswer((_) {});
    when(
      () => dashboard.improveResponse(any(), any()),
    ).thenAnswer((_) async {});
    when(() => dashboard.incrementNumUnclearResponses()).thenAnswer((_) {});
    when(() => dashboard.incrementNumRepeats()).thenAnswer((_) {});
    when(() => dashboard.resetDashboard()).thenAnswer((_) {});

    when(() => tx.transcriptionStream).thenAnswer((_) => controller.stream);
    when(() => tx.startStreaming()).thenAnswer((_) async {});
    when(() => tx.stopStreaming()).thenAnswer((_) async {});

    when(() => prompt.fetchPrompt(any())).thenAnswer(
      (inv) async => _emptyPrompt(inv.positionalArguments[0] as ScenarioStep),
    );
    when(
      () => prompt.getSignedUrl(any(), any()),
    ).thenAnswer((_) async => 'https://test.com/food.png');

    void stubAudioPlayer(MockAudioPlayer player) {
      when(
        () => player.setAudioSource(any(), preload: any(named: 'preload')),
      ).thenAnswer((_) async => Duration.zero);
      when(
        () => player.setFilePath(any()),
      ).thenAnswer((_) async => Duration.zero);

      when(() => player.play()).thenAnswer((_) async {});
      when(() => player.pause()).thenAnswer((_) async {});
      when(() => player.seek(any())).thenAnswer((_) async {});
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
    }

    when(
      () => eleven.fetchAudio(any()),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

    stubAudioPlayer(audio);
    stubAudioPlayer(overrideAudio);

    mgr = ScenarioSimManager(
      scenarioApiService: api,
      promptService: prompt,
      transcriptionService: tx,
      audioPlayer: audio,
      overridePlayer: overrideAudio,
      elevenLabsService: eleven,
      dashboardManager: dashboard,
      random: mockRandom,
      delay: (_) async {},
    );
  });

  tearDown(() {
    controller.close();
    mgr.dispose();
  });

  Future<void> runScenarioSequence(
    WidgetTester tester,
    List<List<String>> intentSequence,
  ) async {
    var callCount = 0;
    when(
      () => api.classifyUtterance(
        any(),
        any(),
        globalSearch: any(named: 'globalSearch'),
      ),
    ).thenAnswer((_) async {
      if (callCount < intentSequence.length) {
        return UtteranceClassification(
          match: true,
          intents: intentSequence[callCount++],
        );
      }
      return UtteranceClassification(match: true, intents: []);
    });

    await mockNetworkImagesFor(() async {
      // FIX: Use runAsync to prevent fake-clock deadlocks on ImageStreams
      await tester.runAsync(() async {
        await mgr.init(ImageConfiguration.empty);
      });

      for (int i = 0; i < intentSequence.length; i++) {
        controller.add(TranscriptionResult(text: 'mock user speech'));
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });

        // FIX: Ensure unawaited async state changes inside the manager resolve
        await tester.pumpAndSettle();
      }
    });
  }

  group('multiple intents in single turn', () {
    testWidgets('appetizers step: no apps, orders steak and orders fries', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['no_appetizer', 'order_steak', 'side_fries'],
      ]);
      expect(mgr.currentStep, ScenarioStep.steakDoneness);
      expect(mgr.orderItems, containsAll(['order_steak', 'side_fries']));
    });

    testWidgets('drinks step: orders water and chicken', (tester) async {
      //expect entrees step to be skipped
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_water', 'water_still', 'order_chicken'],
      ]);
      expect(mgr.currentStep, ScenarioStep.iceQuestion);
      expect(mgr.orderItems, contains('order_chicken'));

      await runScenarioSequence(tester, [
        ['yes_ice'],
      ]);

      expect(mgr.currentStep, ScenarioStep.appetizers);

      await runScenarioSequence(tester, [
        ['no_appetizer'],
      ]);

      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });
  });

  group('wrong order curveball', () {
    testWidgets('notices wrong order immediately and corrects it', (
      tester,
    ) async {
      when(() => mockRandom.nextInt(any())).thenReturn(1);

      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['no_appetizer'],
        ['order_chicken'],
        ['is_that_all_yes'],
      ]);

      expect(mgr.currentStep, ScenarioStep.hereSteak);

      final mockResult = MockOrderCorrectionResult();
      when(() => mockResult.isCorrected).thenReturn(true);
      when(
        () => api.verifyOrderCorrection(any(), any(), any()),
      ).thenAnswer((_) async => mockResult);

      await mockNetworkImagesFor(() async {
        controller.add(
          TranscriptionResult(text: "I didn't order steak, I ordered chicken."),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });
        await tester.pumpAndSettle();
      });

      verify(
        () => api.verifyOrderCorrection(
          "I didn't order steak, I ordered chicken.",
          any(),
          any(),
        ),
      ).called(1);

      expect(mgr.currentCurveball, ScenarioCurveball.none);

      expect(mgr.currentStep, ScenarioStep.howIsEverything);
    });

    testWidgets('accepts wrong order, but is nudged and then fixes it', (
      tester,
    ) async {
      when(() => mockRandom.nextInt(any())).thenReturn(1);

      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['no_appetizer'],
        ['order_chicken'],
        ['is_that_all_yes'],
      ]);

      final mockResult = MockOrderCorrectionResult();
      when(() => mockResult.isCorrected).thenReturn(false);
      when(
        () => api.verifyOrderCorrection(any(), any(), any()),
      ).thenAnswer((_) async => mockResult);

      await mockNetworkImagesFor(() async {
        controller.add(TranscriptionResult(text: "Uh, thanks."));
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });
        await tester.pumpAndSettle();
      });

      expect(mgr.currentStep, ScenarioStep.wrongOrderNudge);

      when(
        () => api.classifyUtterance(
          any(),
          any(),
          globalSearch: any(named: 'globalSearch'),
        ),
      ).thenAnswer(
        (_) async =>
            UtteranceClassification(match: true, intents: ['nudge_no']),
      );

      await mockNetworkImagesFor(() async {
        controller.add(TranscriptionResult(text: "No, I didn't."));
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });
        await tester.pumpAndSettle();
      });

      expect(mgr.currentStep, ScenarioStep.howIsEverything);
    });

    testWidgets('accepts wrong order', (tester) async {
      when(() => mockRandom.nextInt(any())).thenReturn(1);

      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['no_appetizer'],
        ['order_chicken'],
        ['is_that_all_yes'],
      ]);

      final mockResult = MockOrderCorrectionResult();
      when(() => mockResult.isCorrected).thenReturn(false);
      when(
        () => api.verifyOrderCorrection(any(), any(), any()),
      ).thenAnswer((_) async => mockResult);

      await mockNetworkImagesFor(() async {
        controller.add(TranscriptionResult(text: "Uh, thanks."));
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });
        await tester.pumpAndSettle();
      });

      expect(mgr.currentStep, ScenarioStep.wrongOrderNudge);

      when(
        () => api.classifyUtterance(
          any(),
          any(),
          globalSearch: any(named: 'globalSearch'),
        ),
      ).thenAnswer(
        (_) async =>
            UtteranceClassification(match: true, intents: ['nudge_no']),
      );

      await mockNetworkImagesFor(() async {
        controller.add(TranscriptionResult(text: "yes i did"));
        await tester.pump();

        await tester.runAsync(() async {
          await mgr.handleEndOfTurn(ImageConfiguration.empty);
        });
        await tester.pumpAndSettle();
      });

      expect(mgr.currentStep, ScenarioStep.howIsEverything);
    });
  });

  group('reservation and seating steps', () {
    testWidgets('yes reservation -> name on reso', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_yes'],
      ]);
      expect(mgr.currentStep, ScenarioStep.reservationName);
    });

    testWidgets('yes reservation -> name on reso -> num people', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_yes'],
        [],
      ]);
      expect(mgr.currentStep, ScenarioStep.numberPeople);
    });

    testWidgets('no reservation -> num people', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
      ]);
      expect(mgr.currentStep, ScenarioStep.numberPeople);
    });

    testWidgets('num people -> drinks offer', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        ['two_people'],
      ]);
      expect(mgr.currentStep, ScenarioStep.drinksOffer);
    });
  });

  group('drinks step', () {
    testWidgets('order water -> water type', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_water'],
      ]);
      expect(mgr.currentStep, ScenarioStep.waterType);
    });

    testWidgets('order still water -> ice question', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_water', 'water_still'],
      ]);
      expect(mgr.currentStep, ScenarioStep.iceQuestion);
    });

    //TODO: nice to have?
    // testWidgets('order sparkling iced water -> ready to order', (tester) async {
    //   await runScenarioSequence(tester, [
    //     ['reservation_no'],
    //     [],
    //     ['beverage_water', 'water_still', 'no_ice'],
    //   ]);
    //   expect(mgr.currentStep, ScenarioStep.readyToOrder);
    // });

    // testWidgets('order iced beverage -> ready to order', (tester) async {
    //   await runScenarioSequence(tester, [
    //     ['reservation_no'],
    //     [],
    //     ['beverage_other', 'no_ice'],
    //   ]);
    //   expect(mgr.currentStep, ScenarioStep.readyToOrder);
    // });

    testWidgets('order non-water -> ice question', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
      ]);
      expect(mgr.currentStep, ScenarioStep.iceQuestion);
    });

    testWidgets('order non-water -> ice question -> appetizers', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        ['no_ice'],
      ]);
      expect(mgr.currentStep, ScenarioStep.readyToOrder);
    });

    testWidgets('no drink -> ready to order', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
      ]);
      expect(mgr.currentStep, ScenarioStep.readyToOrder);
    });
  });

  group('ordering readiness step', () {
    testWidgets('not ready -> triggers override prompt', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_no'],
      ]);
      expect(mgr.currentStep, ScenarioStep.readyToOrder);
      expect(
        mgr.promptOverride,
        "No problem, just say 'I'm ready to order' when you've decided.",
      );
    });

    testWidgets('not ready (triggers override prompt) -> yes ready', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_no'],
      ]);
      expect(mgr.currentStep, ScenarioStep.readyToOrder);
      expect(
        mgr.promptOverride,
        "No problem, just say 'I'm ready to order' when you've decided.",
      );

      await runScenarioSequence(tester, [
        ['ready_yes'],
      ]);

      expect(mgr.currentStep, ScenarioStep.appetizers);
    });

    testWidgets('ready -> appetizers', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
      ]);

      expect(mgr.currentStep, ScenarioStep.appetizers);
    });
  });

  group('ordering appetizers step', () {
    testWidgets('soup of the day -> triggers override prompt', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['ask_soup'],
      ]);

      expect(mgr.orderItems, []);
      expect(mgr.currentStep, ScenarioStep.appetizers);
      expect(mgr.promptOverride, "Today's soup is creamy roasted garlic.");
    });

    testWidgets('recommendation -> triggers override prompt', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['ask_recommendations'],
      ]);

      expect(mgr.orderItems, []);
      expect(mgr.currentStep, ScenarioStep.appetizers);
      expect(mgr.promptOverride, "My personal favourite is the ribeye steak.");
    });

    testWidgets('order appetizer -> order entree', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_soup'],
      ]);

      expect(mgr.orderItems, ['order_soup']);
      expect(mgr.currentStep, ScenarioStep.entrees);
    });

    testWidgets('order appetizer and order entree -> is that all', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_soup', 'order_chicken'],
      ]);

      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('no appetizer -> order entree', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['no_appetizer'],
      ]);

      expect(mgr.orderItems, []);
      expect(mgr.currentStep, ScenarioStep.entrees);
    });

    testWidgets('order entree on appetizer step -> is that all', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_chicken'],
      ]);

      expect(mgr.orderItems, ['order_chicken']);
      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('no entree on appetizer step -> appetizers', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['no_entree'],
      ]);

      expect(mgr.orderItems, []);
      expect(mgr.currentStep, ScenarioStep.appetizers);
    });

    testWidgets('mutliple appetizers works', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_bruschetta', 'order_soup'],
      ]);

      expect(mgr.orderItems, ['order_bruschetta', 'order_soup']);
      expect(mgr.currentStep, ScenarioStep.entrees);
    });

    //TODO: this would be nice
    // testWidgets('no appetizer + no entree -> is that all', (tester) async {
    //   await runScenarioSequence(tester, [
    //     ['reservation_no'],
    //     [],
    //     ['beverage_other'],
    //     [],
    //     ['ready_yes'],
    //     ['no_appetizer', 'no_entree'],
    //   ]);
    //   expect(mgr.currentStep, ScenarioStep.isThatAll);
    // });
  });

  group('ordering entrees step', () {
    testWidgets('order steak -> steak doneness -> sides -> is that all', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['no_appetizer'],
        ['order_steak'],
      ]);

      expect(mgr.orderItems, ['order_steak']);
      expect(mgr.currentStep, ScenarioStep.steakDoneness);

      await runScenarioSequence(tester, [
        ['steak_doneness'],
      ]);

      expect(mgr.currentStep, ScenarioStep.sideChoice);

      await runScenarioSequence(tester, [
        ['side_fries'],
      ]);

      expect(mgr.orderItems, ['order_steak', 'side_fries']);
      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('order non-steak entree -> is that all', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['no_appetizer'],
        ['order_chicken'],
      ]);

      expect(mgr.orderItems, ['order_chicken']);
      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('no entree -> is that all', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_bruschetta'],
        ['no_entrees'],
      ]);

      expect(mgr.orderItems, ['order_bruschetta']);
      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('prev no appetizer -> no entree -> is that all', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['no_appetizer'],
        ['no_entrees'],
      ]);

      expect(mgr.orderItems, []);
      expect(mgr.currentStep, ScenarioStep.isThatAll);
    });

    testWidgets('mutliple entrees works', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['beverage_other'],
        [],
        ['ready_yes'],
        ['order_bruschetta'],
        ['order_chicken', 'order_steak'],
      ]);

      expect(mgr.orderItems, [
        'order_bruschetta',
        'order_chicken',
        'order_steak',
      ]);
      expect(mgr.currentStep, ScenarioStep.steakDoneness);
    });
  });

  group('payment step', () {
    testWidgets('not done eating -> trigger prompt override', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['order_chicken'],
        ['no_appetizer'],
        ['is_that_all_yes'],
        [],
        [],
        ['done_eating_no'],
      ]);

      expect(mgr.currentStep, ScenarioStep.areYouDone);
      expect(
        mgr.promptOverride,
        "No problem, call me over when you're ready by saying 'I'm done'",
      );
    });

    testWidgets('not done eating (trigger prompt override) -> done eating', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['order_chicken'],
        ['no_appetizer'],
        ['is_that_all_yes'],
        [],
        [],
        ['done_eating_no'],
      ]);

      expect(mgr.currentStep, ScenarioStep.areYouDone);
      expect(
        mgr.promptOverride,
        "No problem, call me over when you're ready by saying 'I'm done'",
      );

      await runScenarioSequence(tester, [
        ['done_eating_yes'],
      ]);

      expect(mgr.currentStep, ScenarioStep.readyForBill);
    });

    testWidgets('not ready for bill -> trigger prompt override', (
      tester,
    ) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['order_chicken'],
        ['no_appetizer'],
        ['is_that_all_yes'],
        [],
        [],
        ['done_eating_yes'],
        ['ready_for_bill_no'],
      ]);

      expect(mgr.currentStep, ScenarioStep.readyForBill);
      expect(
        mgr.promptOverride,
        "No problem, call me over when you're ready by saying 'I'm ready for the bill'",
      );
    });

    testWidgets(
      'not ready for bill -> trigger prompt override -> ready for bill',
      (tester) async {
        await runScenarioSequence(tester, [
          ['reservation_no'],
          [],
          ['no_drink'],
          ['order_chicken'],
          ['no_appetizer'],
          ['is_that_all_yes'],
          [],
          [],
          ['done_eating_yes'],
          ['ready_for_bill_no'],
        ]);

        expect(mgr.currentStep, ScenarioStep.readyForBill);
        expect(
          mgr.promptOverride,
          "No problem, call me over when you're ready by saying 'I'm ready for the bill'",
        );

        await runScenarioSequence(tester, [
          ['ready_for_bill_yes'],
        ]);

        expect(mgr.currentStep, ScenarioStep.checkReceipt);
      },
    );

    testWidgets('ready for bill -> payment method', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['order_chicken'],
        ['no_appetizer'],
        ['is_that_all_yes'],
        [],
        [],
        ['done_eating_yes'],
        ['ready_for_bill_yes'],
        [], //how would you like to pay
      ]);

      expect(mgr.currentStep, ScenarioStep.paymentMethod);
    });

    testWidgets('ready for bill -> payment method', (tester) async {
      await runScenarioSequence(tester, [
        ['reservation_no'],
        [],
        ['no_drink'],
        ['order_chicken'],
        ['no_appetizer'],
        ['is_that_all_yes'],
        [],
        [],
        ['done_eating_yes'],
        ['ready_for_bill_yes'],
        [], //how would you like to pay
        [], //would you like your receipt
      ]);

      expect(mgr.currentStep, ScenarioStep.receipt);
      expect(mgr.isScenarioComplete, isTrue);
    });
  });
}
