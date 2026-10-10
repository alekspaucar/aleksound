import 'dart:convert';
import 'package:http/http.dart' as http;
import '../catalog_track.dart';
import 'youtube_source.dart';

class YoutubeImportService {
  Future<CatalogTrack> fetch(String input) async {
    final id = YoutubeSource.videoId(input);
    if (id == null) {
      throw const FormatException(
          'Pega un enlace válido de una canción de YouTube o YouTube Music.');
    }
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': 'https://www.youtube.com/watch?v=$id',
      'format': 'json',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException(
          'YouTube no permite consultar este video. Comprueba que sea público y esté disponible.');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de YouTube no válida.');
    }
    return YoutubeSource.fromOembed(id, data);
  }
}
