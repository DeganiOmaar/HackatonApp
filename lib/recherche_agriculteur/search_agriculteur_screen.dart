import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:robotic_app/messagesscreens/chatpage.dart';

/// Génère un ID de chat unique pour deux utilisateurs
String generateChatId(String uidA, String uidB) =>
    uidA.compareTo(uidB) < 0 ? "${uidA}_$uidB" : "$uidB\_$uidA";

class SearchAgriculteurScreen extends StatefulWidget {
  const SearchAgriculteurScreen({Key? key}) : super(key: key);

  @override
  State<SearchAgriculteurScreen> createState() => _SearchAgriculteurScreenState();
}

class _SearchAgriculteurScreenState extends State<SearchAgriculteurScreen> {
  final TextEditingController materialController = TextEditingController();
  String? selectedRole;

  final List<String> roles = [
    'Tout',
    'Fruit',
    'Légumineuses',
    'Oliviers',
    'Blé',
    'Pommes de terre',
  ];

  Future<void> _refresh() async {
    setState(() {});
  }

  void _showAgriculteurDialog(DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (context) => _buildPopup(user),
    );
  }

  Widget _buildPopup(DocumentSnapshot user) {
    final peerUid = user.id;
    final peerName = '${user['nom']} ${user['prenom']}';
    final peerAvatar = user['image'] as String? ?? '';
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                  child: peerAvatar.isEmpty
                      ? SvgPicture.asset('assets/img/avtr.svg', width: 32, height: 32)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  peerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.email, user['email'] as String? ?? ''),
                _buildInfoRow(Icons.location_on, user['localisation'] as String? ?? ''),
                _buildInfoRow(Icons.agriculture, user['role'] as String? ?? ''),
                _buildInfoRow(Icons.work_history, user['experience'] as String? ?? 'Non spécifié'),
                _buildInfoRow(Icons.build_circle, user['materiels'] as String? ?? 'Non spécifié'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    final chatId = generateChatId(currentUid, peerUid);
                    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
                    final chatSnap = await chatRef.get();
                    if (!chatSnap.exists) {
                      await chatRef.set({
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
                      await chatRef.update({
                        'readTimestamps.$currentUid': FieldValue.serverTimestamp(),
                      });
                    }
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: chatId,
                          peerId: peerUid,
                          peerName: peerName,
                          peerAvatar: peerAvatar,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Envoyer Message', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Rechercher un agriculteur",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: materialController,
                    decoration: InputDecoration(
                      hintText: 'Matériel',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 30, ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.line_style, color: Colors.white, size: 16,),
                    onPressed: () {
                      _openFilterDialog();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final allUsers = snapshot.data?.docs ?? [];
                    final users = allUsers
                        .where((doc) =>
                            doc.id != currentUid &&
                            (selectedRole == null || selectedRole == 'Tout' || doc['role'] == selectedRole) &&
                            (materialController.text.isEmpty ||
                                (doc['materiels'] != null &&
                                    (doc['materiels'] as String)
                                        .toLowerCase()
                                        .contains(materialController.text.toLowerCase()))))
                        .toList();
                    if (users.isEmpty) {
                      return const Center(child: Text('Aucun agriculteur trouvé.'));
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return InkWell(
                          onTap: () => _showAgriculteurDialog(user),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(user['image'] as String? ?? ''),
                                  ),
                                  const SizedBox(height: 10),
                                  Text('${user['nom']} ${user['prenom']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Spécialité: ${user['role']}',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user['localisation'] as String? ?? '',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrer par expertise'),
          content: DropdownButton<String>(
            isExpanded: true,
            value: selectedRole,
            hint: const Text('Choisir un rôle'),
            items: roles.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedRole = value;
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
