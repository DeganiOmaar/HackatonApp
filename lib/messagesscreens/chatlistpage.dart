import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:robotic_app/messagesscreens/chatpage.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatsListPage extends StatelessWidget {
  const ChatsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Conversations",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsRef
            .where('participants', arrayContains: currentUid)
            .orderBy('lastTimestamp', descending: true)
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
            return const Center(child: Text('Aucune conversation.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final chatDoc = docs[i];
              final chatData = chatDoc.data();
              final participants = List<String>.from(chatData['participants']);
              final peerId =
                  participants.firstWhere((uid) => uid != currentUid);
              final lastMsg = chatData['lastMessage'] as String? ?? '';
              final lastTs = (chatData['lastTimestamp'] as Timestamp?)
                  ?.toDate();
              final relative = lastTs != null
                  ? timeago.format(lastTs, locale: 'fr')
                  : '';

              // Récupération des infos du pair
              return FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(peerId)
                    .get(),
                builder: (ctx, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Chargement...'),
                    );
                  }
                  final user = userSnap.data!.data()!;
                  final name = '${user['nom']} ${user['prenom']}';
                  final avatarUrl = user['image'] as String? ?? '';

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatDoc.id,
                            peerId: peerId,
                            peerName: name,
                            peerAvatar: avatarUrl,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
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
                    title: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      relative,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
