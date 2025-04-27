class CaseModel {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String role; // Spécialité : Fruit, Blé, etc.
  final String localisation;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final int likes;  // ✅ Nouveau champ ajouté !

  CaseModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.role,
    required this.localisation,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.likes = 0,  // ✅ Valeur par défaut à 0 pour éviter des erreurs
  });

  // Convertir un objet en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'role': role,
      'localisation': localisation,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'likes': likes, // ✅ Ajouté ici
    };
  }

  // Créer un objet CaseModel à partir de Firestore
  factory CaseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CaseModel(
      id: documentId,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      role: map['role'] ?? '',
      localisation: map['localisation'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      likes: (map['likes'] ?? 0) as int, // ✅ Important pour récupérer les likes
    );
  }
}
