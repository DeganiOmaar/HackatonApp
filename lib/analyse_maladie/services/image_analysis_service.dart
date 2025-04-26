import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diagnostic_model.dart';

class ImageAnalysisService {
  static const String _apiKey = 'ooUzMFoaPMBQS0vI4akDzsV7v9ovO3GsebnKIo4jlUJboP4dxr'; 
  static const String _apiUrl = 'https://plant.id/api/v3/health_assessment';

  static Future<DiagnosticModel> analyzePlantImage(String base64Image) async {
    try {
      String formattedBase64 = 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _apiKey,
        },
        body: jsonEncode({
          "images": [formattedBase64],
          "latitude": 36.8065,
          "longitude": 10.1815,
          "similar_images": true, // ✅ garder similar_images
        }),
      );

if (response.statusCode == 200 || response.statusCode == 201) {
  final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
  return DiagnosticModel.fromJson(jsonResponse);
} else {
  throw Exception('Erreur d\'analyse d\'image : ${response.statusCode} - ${response.body}');
}

    } catch (e) {
      throw Exception('Erreur de communication avec l\'API : $e');
    }
  }
}
