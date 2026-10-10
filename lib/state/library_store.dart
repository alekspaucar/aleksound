import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/personal_album.dart';
import '../catalog_track.dart';
import '../data/youtube_source.dart';
import '../data/library_backup.dart';

class LibraryStore extends ChangeNotifier {
  LibraryStore(this.preferences);
  final SharedPreferences preferences;
  Future<void> _mutationTail = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    // Un fallo se entrega al solicitante, sin bloquear operaciones posteriores.
    _mutationTail =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Set<String> get favorites =>
      preferences.getStringList('favorites')?.toSet() ?? {};
  Set<String> get saved =>
      preferences.getStringList('saved_demos')?.toSet() ?? {};
  List<String> get recent => preferences.getStringList('recent_tracks') ?? [];
  String get appearance => preferences.getString('appearance') ?? 'system';
  List<CatalogTrack> get importedTracks {
    final result = <CatalogTrack>[];
    try {
      final items = jsonDecode(preferences.getString('youtube_tracks') ?? '[]');
      if (items is! List) return result;
      for (final item in items) {
        if (item is! Map<String, dynamic> || item['videoId'] is! String) {
          continue;
        }
        try {
          result.add(YoutubeSource.fromOembed(item['videoId'] as String, item));
        } on FormatException {
          continue;
        }
      }
    } on FormatException {
      return result;
    }
    return result;
  }

  Future<void> addOnlineTrack(CatalogTrack track) =>
      _enqueue(() => _addOnlineTrack(track));

  Future<void> _addOnlineTrack(CatalogTrack track) async {
    if (!track.isYoutube) {
      throw ArgumentError('Solo se pueden importar enlaces de YouTube.');
    }
    final tracks = [...importedTracks.where((t) => t.id != track.id), track];
    final data = tracks
        .map((t) => {
              'videoId': t.youtubeVideoId,
              'title': t.title,
              'author_name': t.artist,
            })
        .toList();
    if (!await preferences.setString('youtube_tracks', jsonEncode(data))) {
      throw StateError('No se pudo guardar la canción.');
    }
    notifyListeners();
  }

  List<PersonalAlbum> get albums =>
      allAlbums.where((a) => !a.archived).toList();
  List<PersonalAlbum> get archivedAlbums =>
      allAlbums.where((a) => a.archived).toList();
  List<PersonalAlbum> get allAlbums {
    try {
      final decoded =
          jsonDecode(preferences.getString('personal_albums') ?? '[]');
      if (decoded is! List) return [];
      return decoded
          .map(PersonalAlbum.fromJson)
          .whereType<PersonalAlbum>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> recordListen(String id) => _enqueue(() => _recordListen(id));

  Future<void> _recordListen(String id) async {
    if (recent.isNotEmpty && recent.first == id) return;
    final ids = [id, ...recent.where((item) => item != id)].take(20).toList();
    if (!await preferences.setStringList('recent_tracks', ids)) {
      throw StateError('No se pudo guardar el historial.');
    }
    notifyListeners();
  }

  Future<void> setAppearance(String value) async {
    if (!['system', 'light', 'dark'].contains(value)) {
      throw ArgumentError('Tema desconocido');
    }
    if (!await preferences.setString('appearance', value)) {
      throw StateError('No se pudo guardar el tema.');
    }
    notifyListeners();
  }

  Future<PersonalAlbum> saveAlbum(
      {String? id,
      required String name,
      required Iterable<String> trackIds}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Escribe un nombre para tu álbum.');
    }
    if (cleanName.length > 60) {
      throw ArgumentError('Usa un nombre de hasta 60 caracteres.');
    }
    final collection = allAlbums;
    if (collection.any((album) =>
        album.id != id &&
        album.name.toLowerCase() == cleanName.toLowerCase())) {
      throw ArgumentError('Ya tienes un álbum con ese nombre.');
    }
    if (id != null && !collection.any((album) => album.id == id)) {
      throw ArgumentError('Este álbum ya no existe.');
    }
    final album = PersonalAlbum(
        id: id ?? 'album-${DateTime.now().microsecondsSinceEpoch}',
        name: cleanName,
        trackIds: List.unmodifiable(trackIds.toSet()),
        archived:
            id != null && collection.firstWhere((a) => a.id == id).archived);
    final updated = id == null
        ? [...collection, album]
        : collection.map((item) => item.id == id ? album : item).toList();
    if (!await preferences.setString('personal_albums',
        jsonEncode(updated.map((item) => item.toJson()).toList()))) {
      throw StateError('No se pudo guardar el álbum.');
    }
    notifyListeners();
    return album;
  }

  Future<void> setAlbumArchived(String id, bool archived) async {
    final collection = allAlbums;
    if (!collection.any((a) => a.id == id)) {
      throw ArgumentError('Este álbum ya no existe.');
    }
    final updated = collection
        .map((a) => a.id == id
            ? PersonalAlbum(
                id: a.id,
                name: a.name,
                trackIds: a.trackIds,
                archived: archived)
            : a)
        .toList();
    if (!await preferences.setString('personal_albums',
        jsonEncode(updated.map((a) => a.toJson()).toList()))) {
      throw StateError('No se pudo actualizar el álbum.');
    }
    notifyListeners();
  }

  String exportBackup() => LibraryBackup(
          tracks: importedTracks,
          albums: allAlbums,
          favorites: favorites,
          saved: saved,
          recent: recent,
          appearance: appearance)
      .encode();

  Future<void> restoreBackup(String text) =>
      _enqueue(() => _restoreBackup(text));

  Future<void> _restoreBackup(String text) async {
    // Validar toda la copia antes de modificar una preferencia.
    final backup = LibraryBackup.decode(text);
    final tracks = {
      for (final t in backup.tracks) t.id: t,
      for (final t in importedTracks) t.id: t
    };
    final collection = allAlbums.toList();
    for (final incoming in backup.albums) {
      final index = collection.indexWhere((a) => a.id == incoming.id);
      if (index >= 0) {
        final local = collection[index];
        collection[index] = PersonalAlbum(
            id: local.id,
            name: local.name,
            archived: local.archived,
            trackIds: {...local.trackIds, ...incoming.trackIds}.toList());
      } else {
        var name = incoming.name, suffix = 2;
        while (
            collection.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
          final ending = ' ($suffix)';
          name =
              '${incoming.name.substring(0, incoming.name.length.clamp(0, 60 - ending.length))}$ending';
          suffix++;
        }
        collection.add(PersonalAlbum(
            id: incoming.id,
            name: name,
            trackIds: incoming.trackIds,
            archived: incoming.archived));
      }
    }
    final merged = LibraryBackup(
        tracks: tracks.values.toList(),
        albums: collection,
        favorites: {...favorites, ...backup.favorites},
        saved: {...saved, ...backup.saved},
        recent: {...recent, ...backup.recent}.take(20).toList(),
        appearance: preferences.containsKey('appearance')
            ? appearance
            : backup.appearance);
    try {
      LibraryBackup.decode(merged.encode());
    } on FormatException {
      throw const FormatException(
          'La biblioteca combinada supera los límites del respaldo. No se modificó tu biblioteca.');
    }
    final values = <String, Object>{
      'youtube_tracks': jsonEncode(tracks.values
          .map((t) => {
                'videoId': t.youtubeVideoId,
                'title': t.title,
                'author_name': t.artist,
              })
          .toList()),
      'personal_albums': jsonEncode(collection.map((a) => a.toJson()).toList()),
      'favorites': merged.favorites.toList(),
      'saved_demos': merged.saved.toList(),
      'recent_tracks': merged.recent,
      'appearance': merged.appearance,
    };
    final previous = {for (final key in values.keys) key: preferences.get(key)};
    Future<bool> write(String key, Object value) => value is List<String>
        ? preferences.setStringList(key, value)
        : preferences.setString(key, value as String);
    try {
      for (final entry in values.entries) {
        if (!await write(entry.key, entry.value)) {
          throw StateError('No se pudo guardar la copia.');
        }
      }
    } catch (_) {
      var recovered = true;
      for (final entry in previous.entries) {
        try {
          final ok = entry.value == null
              ? await preferences.remove(entry.key)
              : await write(entry.key, entry.value!);
          recovered = recovered && ok;
        } catch (_) {
          // Una preferencia fallida no debe impedir recuperar las demás.
          recovered = false;
        }
      }
      notifyListeners();
      throw StateError(recovered
          ? 'No se pudo restaurar. Tu biblioteca se conservó.'
          : 'La restauración quedó incompleta. Conserva la copia y vuelve a intentar.');
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final ids = favorites;
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    if (!await preferences.setStringList('favorites', ids.toList())) {
      throw StateError('No se pudieron guardar los favoritos.');
    }
    notifyListeners();
  }

  Future<void> toggleSaved(String id) async {
    final ids = saved;
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    if (!await preferences.setStringList('saved_demos', ids.toList())) {
      throw StateError('No se pudo guardar la biblioteca.');
    }
    notifyListeners();
  }
}
