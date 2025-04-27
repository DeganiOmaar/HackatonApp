import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rendement_model.dart';

class RendementService {
  static final _userUid = FirebaseAuth.instance.currentUser!.uid;
  static final _rendementCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(_userUid)
      .collection('yields');

  // Ajouter un nouveau rendement
  static Future<void> addRendement(RendementModel rendement) async {
    await _rendementCollection.doc(rendement.id).set(rendement.toMap());
  }

  // Corrigé ici : récupérer tous les rendements sous forme de Future
  static Future<List<RendementModel>> getRendements() async {
    final snapshot = await _rendementCollection.orderBy('annee', descending: true).get();
    return snapshot.docs
        .map((doc) => RendementModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
