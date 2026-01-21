class Cue {
  final String likelyWord;
  final String semantic;
  final String rhyming;
  final String firstSound;

  Cue({
    required this.likelyWord,
    required this.semantic,
    required this.rhyming,
    required this.firstSound,
  });

  // A factory to turn your Backend JSON into this Object
  factory Cue.fromJson(Map<String, dynamic> json) {
    return Cue(
      likelyWord: json['likely_word'] ?? '',
      semantic: json['semantic'] ?? '',
      rhyming: json['rhyming'] ?? '',
      firstSound: json['first_sound'] ?? '',
    );
  }
}