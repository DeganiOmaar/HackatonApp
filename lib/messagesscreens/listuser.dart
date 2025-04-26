// users_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:robotic_app/messagesscreens/chatpage.dart';

String generateChatId(String uidA, String uidB) =>
    uidA.compareTo(uidB) < 0 ? '${uidA}_$uidB' : '${uidB}_$uidA';

class UsersListPage extends StatelessWidget {
  const UsersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection('users');
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Agriculteurs",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        centerTitle: true,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final peers =
              snap.data!.docs.where((d) => d.id != currentUid).toList();
          if (peers.isEmpty) {
            return const Center(child: Text('Aucun autre utilisateur.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: peers.length,
            itemBuilder: (ctx, i) {
              final peerDoc = peers[i];
              final peerUid = peerDoc.id;
              final data = peerDoc.data();
              final name = "${data['nom']} ${data['prenom']}";
              final avatarUrl = data['image'] as String? ?? '';

              final chatId = generateChatId(currentUid, peerUid);
              final chatDocRef = chatsRef.doc(chatId);

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: chatDocRef.snapshots(),
                builder: (ctx2, chatSnap) {
                  bool unread = false;
                  if (chatSnap.hasData && chatSnap.data!.exists) {
                    final chatData = chatSnap.data!.data()!;
                    // Timestamp du dernier message
                    final lastTs = (chatData['lastTimestamp'] as Timestamp?)
                        ?.toDate();
                    // Qui a envoyé ce dernier message ?
                    final lastSender = chatData['lastSender'] as String? ?? '';
                    // Ta dernière lecture
                    final readMap = chatData['readTimestamps']
                        as Map<String, dynamic>? ?? {};
                    final readTs = (readMap[currentUid] as Timestamp?)
                        ?.toDate();

                    // Si c’est l’AUTRE qui a envoyé le dernier message
                    // et que ce message est plus récent que ta dernière lecture
                    if (lastTs != null &&
                        lastSender != currentUid &&
                        (readTs == null || lastTs.isAfter(readTs))) {
                      unread = true;
                    }
                  }

                  return ListTile(
                    onTap: () async {
                      final snapshot = await chatDocRef.get();
                      if (!snapshot.exists) {
                        await chatDocRef.set({
                          'participants': [currentUid, peerUid],
                          'lastMessage': '',
                          'lastTimestamp': FieldValue.serverTimestamp(),
                          'lastSender': '',
                          'readTimestamps': {
                            currentUid: FieldValue.serverTimestamp(),
                            peerUid: FieldValue.serverTimestamp(),
                          },
                        });
                      } else {
                        // marque comme lu
                        await chatDocRef.update({
                          'readTimestamps.$currentUid':
                              FieldValue.serverTimestamp(),
                        });
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            peerId: peerUid,
                            peerName: name,
                            peerAvatar: avatarUrl,
                          ),
                        ),
                      );
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? SvgPicture.asset('assets/img/avtr.svg',
                              width: 32, height: 32)
                          : null,
                    ),
                    title: Row(
                      children: [
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
