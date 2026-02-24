class SimplifiedPrompt {
  final String simplifiedPrompt;

  SimplifiedPrompt({required this.simplifiedPrompt});

  // A factory to turn your Backend JSON into this Object
  factory SimplifiedPrompt.fromJson(Map<String, dynamic> json) {
    return SimplifiedPrompt(simplifiedPrompt: json['simplified_prompt'] ?? '');
  }
}
