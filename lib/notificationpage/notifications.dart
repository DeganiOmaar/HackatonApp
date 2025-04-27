import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:robotic_app/community_feed/CaseDetailsScreen.dart';
import '../shared/colors.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  late String currentUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUid = user.uid;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .get();
      userData = doc.data()!;
    } catch (e) {
      print('Erreur chargement userData: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: LoadingAnimationWidget.discreteCircle(
            size: 32,
            color: const Color.fromARGB(255, 16, 16, 16),
          ),
        ),
      );
    }

    final userRole = userData['role'] as String?;
    if (userRole == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
          ),
        ),
        body: const Center(child: Text('Impossible de récupérer votre rôle.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('notifications')
                  .where('role', isEqualTo: userRole)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Une erreur est survenue.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  size: 32,
                  color: const Color.fromARGB(255, 16, 16, 16),
                  secondRingColor: Colors.indigo,
                  thirdRingColor: Colors.pink,
                ),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune notification pour votre rôle.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                final nom = data['nom'] ?? '';
                final prenom = data['prenom'] ?? '';
                final title = data['title'] ?? '';
                final timestamp = (data['date'] as Timestamp?)?.toDate();
                final dateText =
                    timestamp != null
                        ? DateFormat('yMMMd').format(timestamp)
                        : '';
                final caseId = data['caseId'];

                return InkWell(
                  onTap: () {
                    if (caseId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaseDetailsScreen(caseData: data),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$nom $prenom',
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          SvgPicture.asset('assets/img/point.svg', height: 14),
                          const SizedBox(width: 10),
                          Text(
                            dateText,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
