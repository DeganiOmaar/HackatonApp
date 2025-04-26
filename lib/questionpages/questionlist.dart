import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:robotic_app/questionpages/addquestion.dart';
import 'package:robotic_app/questionpages/reponsepage.dart';
import 'package:timeago/timeago.dart' as timeago;

class QuestionsListPage extends StatelessWidget {
  const QuestionsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              Get.to(() => AddQuestionPage());
            },
            icon: Icon(LineAwesomeIcons.question_circle),
          ),
        ],
        backgroundColor: Colors.white,
        title: const Text(
          "Liste des questions",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('question')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return Center(
              child: LoadingAnimationWidget.discreteCircle(
                size: 32,
                color: const Color.fromARGB(255, 16, 16, 16),
                secondRingColor: Colors.indigo,
                thirdRingColor: Colors.pink.shade400,
              ),
            );
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune question pour l’instant.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final q = doc.data()! as Map<String, dynamic>;
              final userId = q['userId'] as String;
              final questionText = q['question'] as String? ?? '';
              final questionImageUrl = q['image'] as String? ?? '';
              final timestamp = (q['timestamp'] as Timestamp?)?.toDate();
              final relative =
                  timestamp != null
                      ? timeago.format(timestamp, locale: 'fr')
                      : '';

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: Text('Utilisateur introuvable')),
                    );
                  }
                  final user = userSnap.data!.data()!;
                  final displayName = '${user['nom']} ${user['prenom']}';
                  final avatarUrl = user['image'] as String? ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ResponsePage(
                                questionId: doc.id,
                                questionData: q,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête : avatar, nom, relatif
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : const AssetImage(
                                              'assets/img/avtr.svg',
                                            )
                                            as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (relative.isNotEmpty)
                                Text(
                                  relative,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Image de la question
                          if (questionImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                questionImageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),

                          if (questionImageUrl.isNotEmpty)
                            const SizedBox(height: 12),

                          // Texte de la question
                          Text(
                            questionText,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
