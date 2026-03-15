class Prompt {
  final String id;
  final String scenarioStepId;
  final String audioUrl;
  final String imageSpeakingUrl;
  final String imageListeningUrl;
  final String imageConfusedUrl;
  final String skillPracticedId;
  final String promptText;

  Prompt({
    required this.id,
    required this.scenarioStepId,
    required this.audioUrl,
    required this.imageSpeakingUrl,
    required this.imageListeningUrl,
    required this.imageConfusedUrl,
    required this.skillPracticedId,
    required this.promptText,
  });

  // This converts the JSON Map from Python into a Dart Object
  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'],
      scenarioStepId: json['scenario_step_id'],
      audioUrl: json['audio_url'],
      imageSpeakingUrl: json['image_speaking_url'],
      imageListeningUrl: json['image_listening_url'],
      imageConfusedUrl: json['image_confused_url'],
      skillPracticedId: json['skill_practiced_id'],
      promptText: json['prompt_text'], // Note: JSON uses snake_case from Python
    );
  }
}
