class CaseModel {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String role; // Spécialité: Fruit, Blé, etc.
  final String localisation;
  final DateTime createdAt;

  CaseModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.role,
    required this.localisation,
    required this.createdAt,
  });

  // Convertir un objet en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'role': role,
      'localisation': localisation,
      'createdAt': createdAt.toIso8601String(),
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
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
