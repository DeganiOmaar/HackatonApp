import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:quickalert/quickalert.dart';

class ResponsePage extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;

  const ResponsePage({
    Key? key,
    required this.questionId,
    required this.questionData,
  }) : super(key: key);

  @override
  State<ResponsePage> createState() => _ResponsePageState();
}

class _ResponsePageState extends State<ResponsePage> {
  final TextEditingController _responseController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitResponse() async {
    final text = _responseController.text.trim();
    if (text.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Veuillez saisir une réponse.',
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('question')
          .doc(widget.questionId)
          .collection('responses')
          .add({
        'response': text,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'rating': 0,
      });
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Réponse postée avec succès !',
      );
      _responseController.clear();
    } catch (_) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Impossible d’envoyer la réponse.',
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _setRating(String responseId, int starCount) async {
    await FirebaseFirestore.instance
        .collection('question')
        .doc(widget.questionId)
        .collection('responses')
        .doc(responseId)
        .update({'rating': starCount});
  }

  void _showRatingDialog(String responseId, int currentRating) {
  int selected = currentRating;
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Noter cette réponse'),
        content: StatefulBuilder(
          builder: (ctx, setState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final idx = i + 1;
                return IconButton(
                  icon: Icon(
                    idx <= selected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => selected = idx),
                );
              }),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _setRating(responseId, selected);
              Navigator.of(dialogContext).pop();  // <— ferme bien le dialog
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                text: 'Merci pour votre avis !',
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      );
    },
  );
}

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final qImageUrl = q['image'] as String? ?? '';
    final qText = q['question'] as String? ?? '';
    final qTimestamp = (q['timestamp'] as Timestamp?)?.toDate();
    final qRelative =
        qTimestamp != null ? timeago.format(qTimestamp, locale: 'fr') : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Réponses",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Question
          Card(
            color: Colors.white,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(q['userId'] as String)
                    .get(),
                builder: (ctx, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final userData = userSnap.data!.data()!;
                  final avatarUrl = userData['image'] as String? ?? '';
                  final displayName =
                      '${userData['nom']} ${userData['prenom']}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? SvgPicture.asset(
                                    'assets/img/avtr.svg',
                                    width: 32,
                                    height: 32,
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
                          if (qRelative.isNotEmpty)
                            Text(
                              qRelative,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                        ],
                      ),
                      if (qImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            qImageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        qText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Responses
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('question')
                  .doc(widget.questionId)
                  .collection('responses')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Erreur : ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Pas encore de réponses.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final docResp = docs[i];
                    final r = docResp.data()! as Map<String, dynamic>;
                    final respText = r['response'] as String? ?? '';
                    final respTs = (r['timestamp'] as Timestamp?)?.toDate();
                    final respRel = respTs != null
                        ? timeago.format(respTs, locale: 'fr')
                        : '';
                    final respUserId = r['userId'] as String;
                    final rating = r['rating'] as int? ?? 0;

                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(respUserId)
                          .get(),
                      builder: (ctx2, usnap) {
                        if (usnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final u = usnap.data!.data()!;
                        final avatar = u['image'] as String? ?? '';
                        final name = '${u['nom']} ${u['prenom']}';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white,
                                        backgroundImage: avatar.isNotEmpty
                                            ? NetworkImage(avatar)
                                            : null,
                                        child: avatar.isEmpty
                                            ? SvgPicture.asset(
                                                'assets/img/avtr.svg',
                                                width: 28,
                                                height: 28,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Text(
                                                  respRel,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.black87),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              respText,
                                              style: const TextStyle(
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Réagir button & current rating
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      if (rating > 0) ...[
                                        // display rating stars under time
                                        Row(
                                          children: List.generate(5, (idx) {
                                            return Icon(
                                              idx < rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      TextButton(
                                        onPressed: () => _showRatingDialog(
                                            docResp.id, rating),
                                        child: const Text('Réagir'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Input & send
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _responseController,
                  decoration: InputDecoration(
                    hintText: 'Écrire une réponse...',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(color: Colors.white))
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _submitResponse,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
