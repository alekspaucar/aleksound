import '../catalog_track.dart';

class YoutubeSource {
  static final _id = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  static String? videoId(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return null;
    final host = uri.host.toLowerCase();
    String? id;
    if (host == 'youtu.be') {
      if (uri.pathSegments.length == 1) id = uri.pathSegments.first;
    } else if ([
      'youtube.com',
      'www.youtube.com',
      'music.youtube.com',
      'm.youtube.com'
    ].contains(host)) {
      if (uri.path == '/watch') id = uri.queryParameters['v'];
      if (uri.pathSegments.length == 2 &&
          ['shorts', 'embed', 'live'].contains(uri.pathSegments.first)) {
        id = uri.pathSegments.last;
      }
    }
    return id != null && _id.hasMatch(id) ? id : null;
  }

  static CatalogTrack fromOembed(String id, Map<String, dynamic> data) {
    final title = data['title'], author = data['author_name'];
    if (!_id.hasMatch(id) ||
        title is! String ||
        title.trim().isEmpty ||
        author is! String ||
        author.trim().isEmpty) {
      throw const FormatException(
          'No se pudieron obtener el título y el canal de esta canción.');
    }
    return CatalogTrack(
      id: 'youtube:$id',
      title: title.trim(),
      artist: author.trim(),
      artworkUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      audioUrl: '',
      youtubeVideoId: id,
      isDownloadable: false,
      duration: Duration.zero,
      genre: 'YouTube',
      mood: 'Todo',
    );
  }
}
