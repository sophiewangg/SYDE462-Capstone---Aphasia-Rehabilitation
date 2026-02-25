import '../models/scenario_step.dart';

/// Default restaurant scenario steps for the aphasia rehab exercise.
const List<ScenarioStep> restaurantScenarioSteps = [
  ScenarioStep(
    prompt: "Hello! How are you doing?",
    characterAsset: "assets/characters/intro_hello.png",
    audioAsset: "audio_clips/server_speech_1.mp3",
  ),
  ScenarioStep(
    prompt: "Would you like something to drink?",
    characterAsset: "assets/characters/order_talk.png",
  ),
  ScenarioStep(
    prompt: "What would you like to order?",
    characterAsset: "assets/characters/order_takingorder.png",
  ),
  ScenarioStep(
    prompt: "Here is your food. Enjoy your meal!",
    characterAsset: "assets/characters/server_talk.png",
  ),
  ScenarioStep(
    prompt: "Can I get you anything else?",
    characterAsset: "assets/characters/server_talk.png",
  ),
  ScenarioStep(
    prompt: "Thank you! Have a great day!",
    characterAsset: "assets/characters/intro_hello.png",
  ),
];
