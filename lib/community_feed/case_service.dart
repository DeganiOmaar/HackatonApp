import 'package:cloud_firestore/cloud_firestore.dart';
import 'case_model.dart';

class CaseService {
  static final _caseCollection = FirebaseFirestore.instance.collection('cases');

  // Ajouter un nouveau cas dans Firestore
  static Future<void> addCase(CaseModel caseModel) async {
    await _caseCollection.doc(caseModel.id).set(caseModel.toMap());
  }

  // Récupérer tous les cas sans filtrage (affichage global)
  static Stream<List<CaseModel>> getAllCases() {
    return _caseCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CaseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // (Optionnel) Si besoin pour notification : Récupérer UID des utilisateurs ayant le même rôle
  static Future<List<String>> getUserTokensByRole(String role) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    // Ici on suppose que tu stockes un "deviceToken" dans les documents user
    return usersSnapshot.docs
        .map((doc) => doc.data()['deviceToken'] as String?)
        .where((token) => token != null)
        .cast<String>()
        .toList();
  }
}
