import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailsScreen({Key? key, required this.caseData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createdAt =
        caseData['date'] != null
            ? (caseData['date'] as Timestamp).toDate()
            : null;
    final formattedDate =
        createdAt != null
            ? DateFormat('dd/MM/yyyy à HH:mm').format(createdAt)
            : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Détails de cas",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caseData['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  caseData['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              caseData['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              caseData['content'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (formattedDate.isNotEmpty)
              Text(
                'Publié le : $formattedDate',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
