import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'case_model.dart';

class CaseService {
  static final _caseCollection = FirebaseFirestore.instance.collection('cases');

  // 🔥 1. Récupérer tous les cas avec écoute temps réel
  static Stream<List<CaseModel>> getAllCases() {
    return _caseCollection
        .orderBy('likes', descending: true) // 🔥 Trier par likes décroissant
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CaseModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // 🔥 2. Ajouter ou retirer un like
  static Future<void> toggleLike(String caseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Sécurité si pas connecté
    final userId = user.uid;
    final likeDocRef = _caseCollection.doc(caseId).collection('likes').doc(userId);

    final likeDoc = await likeDocRef.get();

    if (likeDoc.exists) {
      // ❌ Déjà liké → retirer
      await likeDocRef.delete();
      await _caseCollection.doc(caseId).update({
        'likes': FieldValue.increment(-1),
      });
    } else {
      // ✅ Pas encore liké → ajouter
      await likeDocRef.set({
        'userId': userId,
        'likedAt': FieldValue.serverTimestamp(),
      });
      await _caseCollection.doc(caseId).update({
        'likes': FieldValue.increment(1),
      });
    }
  }

  // 🔥 3. Vérifier si l'utilisateur actuel a liké ce cas
  static Future<bool> hasLiked(String caseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false; // Sécurité si pas connecté
    final userId = user.uid;
    final likeDoc = await _caseCollection.doc(caseId).collection('likes').doc(userId).get();
    return likeDoc.exists;
  }
}
