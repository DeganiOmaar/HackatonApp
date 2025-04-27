import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:robotic_app/community_feed/add_case_screen.dart';
import 'package:robotic_app/community_feed/case_model.dart';
import 'package:robotic_app/community_feed/case_service.dart';
import 'package:robotic_app/community_feed/statisticpage.dart';
import 'package:robotic_app/open_native_map.dart';   // <-- nouvelle page

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
          detectedCity =
              marks.first.locality ?? marks.first.subAdministrativeArea;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(onPressed: (){
            Get.to(()=>StatisticsPage());
          }, icon: Icon(Icons.analytics_outlined))
        ],
        backgroundColor: Colors.white,
        title: const Text(
          'Community Feed',
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

          final cases = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final cas = cases[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Image.network(
                        cas.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    // Infos
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cas.title,
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
                              Expanded(
                                child: Text(
                                  cas.localisation,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              IconButton(
  icon: const Icon(Icons.location_on),
  onPressed: () async {
    if (cas.latitude != null && cas.longitude != null) {
      try {
        await openNativeMap(
          latitude: cas.latitude!,
          longitude: cas.longitude!,
          label: cas.localisation,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnées GPS indisponibles.')),
      );
    }
  },
)
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
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
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
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white,),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddCaseScreen(
                userRole: widget.userRole,
                userLocalisation: detectedCity ?? '',
              ),
            ),
          );
          if (added == true) setState(() {});
        },
      ),
    );
  }
}
