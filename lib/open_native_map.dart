import 'package:url_launcher/url_launcher.dart';

Future<void> openNativeMap({
  required double latitude,
  required double longitude,
  String? label,
}) async {
  final encodedLabel = Uri.encodeComponent(label ?? 'Lieu');
  // URI universel : essayer d’abord le scheme "geo:"
  final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');

  if (await canLaunchUrl(geoUri)) {
    await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    return;
  }

  // Fallback : ouvrir Google Maps (web / app)
  final gmaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
  if (await canLaunchUrl(gmaps)) {
    await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    return;
  }

  throw 'Aucune application de cartes disponible.';
}
