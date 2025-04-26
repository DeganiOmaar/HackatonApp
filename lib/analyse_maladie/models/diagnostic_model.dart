class DiagnosticModel {
  final List<PlantSuggestion> suggestions;

  DiagnosticModel({required this.suggestions});

  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? suggestionsJson =
        json['result']?['disease']?['suggestions'];

    if (suggestionsJson == null) {
      return DiagnosticModel(suggestions: []);
    }

    return DiagnosticModel(
      suggestions: suggestionsJson
          .map((data) => PlantSuggestion.fromJson(data))
          .toList(),
    );
  }
}

class PlantSuggestion {
  final String plantName;
  final double probability;
  final String? description;
  final String? wikiUrl;

  PlantSuggestion({
    required this.plantName,
    required this.probability,
    this.description,
    this.wikiUrl,
  });

  factory PlantSuggestion.fromJson(Map<String, dynamic> json) {
    return PlantSuggestion(
      plantName: json['name'] ?? 'Inconnu',
      probability: (json['probability'] as num).toDouble(),
      description: json['description'] ?? 'Pas de description disponible',
      wikiUrl: json['url'],
    );
  }
}
