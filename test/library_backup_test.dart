import 'dart:async';
import 'dart:convert';
import 'package:aleksound/data/library_backup.dart';
import 'package:aleksound/data/youtube_source.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailingPreferences extends InMemorySharedPreferencesStore {
  FailingPreferences() : super.empty();
  bool failNextFavorites = false;
  bool throwOnRecoveryRemoval = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failNextFavorites && key == 'flutter.favorites') {
      failNextFavorites = false;
      return false;
    }
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (throwOnRecoveryRemoval && key == 'flutter.youtube_tracks') {
      throwOnRecoveryRemoval = false;
      throw StateError('Fallo simulado de recuperación.');
    }
    return super.remove(key);
  }
}

class DelayedPreferences extends InMemorySharedPreferencesStore {
  DelayedPreferences() : super.empty();
  final entered = Completer<void>(), release = Completer<void>();
  bool delayNextYoutubeWrite = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (delayNextYoutubeWrite && key == 'flutter.youtube_tracks') {
      delayNextYoutubeWrite = false;
      entered.complete();
      await release.future;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'escuchas durante una restauración se conservan en orden después de ella',
      () async {
    final platform = DelayedPreferences();
    SharedPreferencesStorePlatform.instance = platform;
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    await store.recordListen('old');
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    data['recent'] = ['backup'];
    platform.delayNextYoutubeWrite = true;
    final restoring = store.restoreBackup(jsonEncode(data));
    await platform.entered.future;
    final listening = store.recordListen('during');
    final latest = store.recordListen('latest');
    platform.release.complete();
    await Future.wait([restoring, listening, latest]);
    await prefs.reload();
    expect(store.recent, ['latest', 'during', 'old', 'backup']);
  });
  test('rechaza una combinación que supera los límites sin truncar datos',
      () async {
    SharedPreferences.setMockInitialValues(
        {'favorites': List.generate(5000, (i) => 'track-$i')});
    final store = LibraryStore(await SharedPreferences.getInstance());
    final before = store.exportBackup();
    final data = jsonDecode(before) as Map<String, dynamic>;
    data['favorites'] = ['extra'];
    await expectLater(
        store.restoreBackup(jsonEncode(data)),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('biblioteca combinada'))));
    expect(store.exportBackup(), before);
    await store.recordListen('new-listen');
    expect(store.recent, ['new-listen']);
  });
  test('un error en una reversión no impide recuperar las otras preferencias',
      () async {
    final platform = FailingPreferences();
    SharedPreferencesStorePlatform.instance = platform;
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    await store.saveAlbum(name: 'Actual', trackIds: ['orbita']);
    await store.toggleFavorite('orbita');
    await store.toggleSaved('orbita');
    await store.setAppearance('light');
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    data['tracks'] = [
      {'videoId': 'RSk4BlmtGbE', 'title': 'Signs', 'author_name': 'Kylian'}
    ];
    (data['albums'] as List).add({
      'id': 'extra',
      'name': 'Extra',
      'trackIds': ['neon-rain']
    });
    data['favorites'] = ['neon-rain'];
    platform.failNextFavorites = true;
    platform.throwOnRecoveryRemoval = true;
    await expectLater(
        store.restoreBackup(jsonEncode(data)),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('restauración quedó incompleta'))));
    await prefs.reload();
    expect(store.albums.map((a) => a.name), ['Actual']);
    expect(store.favorites, {'orbita'});
    expect(store.saved, {'orbita'});
    expect(store.appearance, 'light');
  });
  test('un fallo de escritura revierte también las partes ya restauradas',
      () async {
    final platform = FailingPreferences();
    SharedPreferencesStorePlatform.instance = platform;
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    await store.saveAlbum(name: 'Actual', trackIds: ['orbita']);
    final before = store.exportBackup();
    final data = jsonDecode(before) as Map<String, dynamic>;
    data['albums'] = [
      {
        'id': 'other',
        'name': 'Extra',
        'trackIds': ['neon-rain']
      }
    ];
    data['favorites'] = ['neon-rain'];
    platform.failNextFavorites = true;
    await expectLater(store.restoreBackup(jsonEncode(data)), throwsStateError);
    expect(store.exportBackup(), before);
    await prefs.reload();
    expect(store.exportBackup(), before);
  });
  test('el respaldo restaura metadatos, orden, archivo, favoritos y tema',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    final track = YoutubeSource.fromOembed(
        'RSk4BlmtGbE', {'title': 'Signs', 'author_name': 'Kylian'});
    await store.addOnlineTrack(track);
    await store.toggleFavorite(track.id);
    await store.toggleSaved(track.id);
    await store.recordListen(track.id);
    await store.setAppearance('dark');
    final album =
        await store.saveAlbum(name: 'Remix', trackIds: [track.id, 'neon-rain']);
    await store.setAlbumArchived(album.id, true);
    final text = store.exportBackup();
    SharedPreferences.setMockInitialValues({});
    final restored = LibraryStore(await SharedPreferences.getInstance());
    await restored.restoreBackup(text);
    expect(restored.importedTracks.single.title, 'Signs');
    expect(restored.importedTracks.single.isAvailableOffline, isFalse);
    expect(restored.archivedAlbums.single.trackIds,
        ['youtube:RSk4BlmtGbE', 'neon-rain']);
    expect(restored.favorites, {'youtube:RSk4BlmtGbE'});
    expect(restored.saved, {'youtube:RSk4BlmtGbE'});
    expect(restored.recent, ['youtube:RSk4BlmtGbE']);
    expect(restored.appearance, 'dark');
  });
  test(
      'restaurar repetidamente combina sin duplicar ni reemplazar datos locales',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    final album = await store.saveAlbum(name: 'Viaje', trackIds: ['neon-rain']);
    final text = store.exportBackup();
    await store.saveAlbum(
        id: album.id, name: 'Mi viaje', trackIds: ['midnight-drive']);
    await store.toggleFavorite('orbita');
    await store.setAppearance('light');
    await store.restoreBackup(text);
    await store.restoreBackup(text);
    expect(store.albums.length, 1);
    expect(store.albums.single.name, 'Mi viaje');
    expect(store.albums.single.trackIds, ['midnight-drive', 'neon-rain']);
    expect(store.favorites, {'orbita'});
    expect(store.appearance, 'light');
  });
  test('álbumes distintos con el mismo nombre se conservan con nombre único',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    await store.saveAlbum(name: 'Noche', trackIds: ['neon-rain']);
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    (data['albums'] as List).first['id'] = 'different-album';
    final text = jsonEncode(data);
    await store.restoreBackup(text);
    await store.restoreBackup(text);
    expect(store.albums.map((a) => a.name), ['Noche', 'Noche (2)']);
  });
  test('metadatos locales prevalecen al combinar el mismo video', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    await store.addOnlineTrack(YoutubeSource.fromOembed(
        'RSk4BlmtGbE', {'title': 'Local', 'author_name': 'Kylian'}));
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    (data['tracks'] as List).first['title'] = 'Backup';
    await store.restoreBackup(jsonEncode(data));
    expect(store.importedTracks.single.title, 'Local');
  });
  test('una copia inválida se rechaza completa sin modificar la biblioteca',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    await store.saveAlbum(name: 'Actual', trackIds: ['orbita']);
    final before = store.exportBackup();
    final data = jsonDecode(before) as Map<String, dynamic>;
    data['favorites'] = ['youtube:RSk4BlmtGbE&evil=1'];
    await expectLater(
        store.restoreBackup(jsonEncode(data)), throwsFormatException);
    expect(store.exportBackup(), before);
  });
  test('versiones ajenas, JSON incompleto y álbumes mal formados se rechazan',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    expect(() => LibraryBackup.decode('{'), throwsFormatException);
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    data['version'] = 999;
    expect(() => LibraryBackup.decode(jsonEncode(data)), throwsFormatException);
    data['version'] = 1;
    data['albums'] = [
      {
        'id': 'one',
        'name': 'Album',
        'trackIds': [7]
      }
    ];
    expect(() => LibraryBackup.decode(jsonEncode(data)), throwsFormatException);
  });
  test('la copia limita historial a veinte y descarta duplicados', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    final data = jsonDecode(store.exportBackup()) as Map<String, dynamic>;
    data['recent'] = ['track-0', ...List.generate(25, (i) => 'track-$i')];
    final backup = LibraryBackup.decode(jsonEncode(data));
    expect(backup.recent.length, 20);
    expect(backup.recent.first, 'track-0');
    expect(backup.recent.last, 'track-19');
  });
}
