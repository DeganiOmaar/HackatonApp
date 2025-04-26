// chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Marquer la conversation comme lue au chargement de la page
    _firestore.collection('chats').doc(widget.chatId).update({
      'readTimestamps.$_currentUid': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final chatDoc = _firestore.collection('chats').doc(widget.chatId);

    // 1) Ajout du message dans la sous-collection
    await chatDoc.collection('messages').add({
      'text': text,
      'from': _currentUid,
      'timestamp': now,
    });

    // 2) Mise à jour des métadonnées du chat
    await chatDoc.update({
      'lastMessage': text,
      'lastTimestamp': now,
      'lastSender': _currentUid,  // <-- On y ajoute lastSender
    });

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.peerAvatar.isNotEmpty
                  ? NetworkImage(widget.peerAvatar)
                  : null,
              child: widget.peerAvatar.isEmpty
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.peerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final m = docs[i].data();
                    final text = m['text'] as String? ?? '';
                    final from = m['from'] as String? ?? '';
                    final ts = (m['timestamp'] as Timestamp?)?.toDate();
                    final rel = ts != null
                        ? timeago.format(ts, locale: 'fr')
                        : '';
                    final isMe = from == _currentUid;

                    return MessageBubble(
                      text: text,
                      isMe: isMe,
                      time: rel,
                    );
                  },
                );
              },
            ),
          ),
          // Champ de saisie et bouton envoyer
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
