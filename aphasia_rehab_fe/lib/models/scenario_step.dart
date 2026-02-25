/// A single step in a scenario — prompt text, character sprite, and optional audio.
class ScenarioStep {
  final String prompt;
  final String characterAsset;
  final String? audioAsset;

  const ScenarioStep({
    required this.prompt,
    required this.characterAsset,
    this.audioAsset,
  });
}
