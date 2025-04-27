import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'add_case_screen.dart';
import 'case_model.dart';
import 'case_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  final String userRole;
  final String userLocalisation;
  const CommunityFeedScreen({
    Key? key,
    required this.userRole,
    required this.userLocalisation,
  }) : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String? detectedCity;

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  /// Détecte la ville de l'utilisateur (reste affichée mais non utilisée pour filtrer)
  Future<void> _detectCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      var marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        setState(() {
          detectedCity = marks.first.locality ?? marks.first.subAdministrativeArea;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Community Feed",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CaseModel>>(
        stream: CaseService.getAllCases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun cas trouvé'));
          }

          // Affiche tous les cas récupérés
          final allCases = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allCases.length,
            itemBuilder: (context, index) {
              final cas = allCases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Image.network(
                        cas.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cas.description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.place, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                cas.localisation,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Spacer(),
                              IconButton(onPressed: (){
                                
                              }, icon: Icon(Icons.location_on_sharp))
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.label, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                cas.role,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publié le : ${cas.createdAt.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddCaseScreen(
                userRole: widget.userRole,
                userLocalisation: detectedCity ?? '',
              ),
            ),
          );
          if (result == true) setState(() {});
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
