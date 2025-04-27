class RendementModel {
  final String id;
  final String culture;
  final int annee;
  final double quantite; // en kilogrammes

  RendementModel({
    required this.id,
    required this.culture,
    required this.annee,
    required this.quantite,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'culture': culture,
      'annee': annee,
      'quantite': quantite,
    };
  }

  // Créer un RendementModel à partir de Firestore
  factory RendementModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RendementModel(
      id: documentId,
      culture: map['culture'] ?? '',
      annee: map['annee'] ?? 0,
      quantite: (map['quantite'] ?? 0).toDouble(),
    );
  }
}
