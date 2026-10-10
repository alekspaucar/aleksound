import 'dart:convert';
import '../catalog_track.dart';
import 'personal_album.dart';
import 'youtube_source.dart';

class LibraryBackup {
  const LibraryBackup(
      {required this.tracks,
      required this.albums,
      required this.favorites,
      required this.saved,
      required this.recent,
      required this.appearance});
  final List<CatalogTrack> tracks;
  final List<PersonalAlbum> albums;
  final Set<String> favorites, saved;
  final List<String> recent;
  final String appearance;

  String encode() => const JsonEncoder.withIndent('  ').convert({
        'format': 'aleksound-library',
        'version': 1,
        'tracks': tracks
            .map((t) => {
                  'videoId': t.youtubeVideoId,
                  'title': t.title,
                  'author_name': t.artist,
                })
            .toList(),
        'albums': albums.map((a) => a.toJson()).toList(),
        'favorites': favorites.toList(),
        'saved': saved.toList(),
        'recent': recent,
        'appearance': appearance,
      });

  factory LibraryBackup.decode(String text) {
    if (text.length > 2000000) {
      throw const FormatException('La copia es demasiado grande.');
    }
    final Object? value;
    try {
      value = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Pega una copia completa de Aleksound.');
    }
    if (value is! Map<String, dynamic> ||
        value['format'] != 'aleksound-library' ||
        value['version'] != 1) {
      throw const FormatException('Esta copia no es compatible con Aleksound.');
    }
    final data = value;
    List<Object?> list(String field) {
      final items = data[field];
      if (items is! List || items.length > 5000) {
        throw FormatException('La copia contiene datos inválidos en $field.');
      }
      return items;
    }

    List<String> ids(Object? items) {
      if (items is! List ||
          items.length > 5000 ||
          items.any((id) =>
              id is! String ||
              id.trim().isEmpty ||
              id.length > 200 ||
              (id.startsWith('youtube:') &&
                  !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id.substring(8))))) {
        throw const FormatException(
            'La copia contiene identificadores inválidos.');
      }
      return List<String>.from(items).toSet().toList();
    }

    final tracks = <String, CatalogTrack>{};
    for (final item in list('tracks')) {
      if (item is! Map<String, dynamic> ||
          item['videoId'] is! String ||
          item['title'] is! String ||
          (item['title'] as String).length > 1000 ||
          item['author_name'] is! String ||
          (item['author_name'] as String).length > 1000) {
        throw const FormatException('La copia contiene canciones inválidas.');
      }
      final track = YoutubeSource.fromOembed(item['videoId'] as String, item);
      tracks[track.id] = track;
    }
    final albums = <PersonalAlbum>[];
    final albumIds = <String>{};
    final names = <String>{};
    for (final item in list('albums')) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          (item['id'] as String).trim().isEmpty ||
          (item['id'] as String).length > 200 ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty ||
          (item['name'] as String).trim().length > 60 ||
          (item.containsKey('archived') && item['archived'] is! bool)) {
        throw const FormatException('La copia contiene álbumes inválidos.');
      }
      final id = item['id'] as String, name = (item['name'] as String).trim();
      if (!albumIds.add(id) || !names.add(name.toLowerCase())) {
        throw const FormatException('La copia contiene álbumes duplicados.');
      }
      albums.add(PersonalAlbum(
          id: id,
          name: name,
          trackIds: ids(item['trackIds']),
          archived: item['archived'] == true));
    }
    final appearance = value['appearance'];
    if (!['system', 'light', 'dark'].contains(appearance)) {
      throw const FormatException('La copia contiene una apariencia inválida.');
    }
    return LibraryBackup(
        tracks: tracks.values.toList(),
        albums: albums,
        favorites: ids(list('favorites')).toSet(),
        saved: ids(list('saved')).toSet(),
        recent: ids(list('recent')).take(20).toList(),
        appearance: appearance as String);
  }
}
