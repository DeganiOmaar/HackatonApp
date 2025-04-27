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
        backgroundColor: Colors.white,
       
        title: const Text(
          'Liste des questions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.question_circle, size: 28),
            onPressed: () => Get.to(() => const AddQuestionPage()),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('question')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur: \${snap.error}'));
          }
          if (!snap.hasData) {
            return Center(
              child: LoadingAnimationWidget.discreteCircle(
                color: Theme.of(context).primaryColor,
                size: 36,
                secondRingColor: Colors.indigo,
                thirdRingColor: Colors.pink.shade400,
              ),
            );
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucune question pour l’instant.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data()! as Map<String, dynamic>;
              final userId = data['userId'] as String;
              final questionText = data['question'] as String? ?? '';
              final imageUrl = data['image'] as String? ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final relative = timestamp != null
                  ? timeago.format(timestamp, locale: 'fr')
                  : '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
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
                  final user = userSnap.data!.data() as Map<String, dynamic>;
                  final displayName = '${user['nom']} ${user['prenom']}';
                  final avatarUrl = user['image'] as String? ?? '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Get.to(() => ResponsePage(
                              questionId: doc.id,
                              questionData: data,
                            ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                      : null,
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
                                  Chip(
                                    label: Text(relative),
                                    backgroundColor: Colors.grey[200],
                                  ),
                              ],
                            ),
                          ),
                          // Image
                          if (imageUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(0),
                                  bottom: Radius.circular(12)),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Question text
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              questionText,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                          // Footer: see responses icon
                        
                          const SizedBox(height: 8),
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
