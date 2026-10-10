import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/data/youtube_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('importar canciones simultáneas conserva las dos', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    final first = YoutubeSource.fromOembed(
        'kFXHPfI2JoI', {'title': 'Primera', 'author_name': 'Artista'});
    final second = YoutubeSource.fromOembed(
        'zyXmsVwZqX4', {'title': 'Segunda', 'author_name': 'Artista'});
    await Future.wait(
        [store.addOnlineTrack(first), store.addOnlineTrack(second)]);
    expect(
        store.importedTracks.map((t) => t.id).toSet(), {first.id, second.id});
  });
  test(
      'archivar y recuperar conserva canciones y orden tras recrear biblioteca',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    final album = await store
        .saveAlbum(name: 'Orden', trackIds: ['neon-rain', 'midnight-drive']);
    await store.setAlbumArchived(album.id, true);
    final reopened = LibraryStore(prefs);
    expect(reopened.albums, isEmpty);
    expect(reopened.archivedAlbums.single.trackIds,
        ['neon-rain', 'midnight-drive']);
    await reopened.setAlbumArchived(album.id, false);
    expect(LibraryStore(prefs).albums.single.trackIds,
        ['neon-rain', 'midnight-drive']);
  });
  test(
      'un álbum archivado no pierde identidad al editar ni admite nombre duplicado',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    final album = await store.saveAlbum(name: 'Noche', trackIds: ['orbita']);
    await store.setAlbumArchived(album.id, true);
    await store.saveAlbum(
        id: album.id, name: 'Noche', trackIds: ['neon-rain', 'orbita']);
    expect(store.archivedAlbums.single.id, album.id);
    await expectLater(
        store.saveAlbum(name: 'noche', trackIds: []), throwsArgumentError);
    await expectLater(
        store.setAlbumArchived('absent', true), throwsArgumentError);
  });
  test(
      'importar dos veces conserva una canción, metadatos y álbum al reiniciar',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    final track = YoutubeSource.fromOembed('kFXHPfI2JoI', {
      'title': 'Texts Go Green',
      'author_name': 'DrakeVEVO',
    });
    await store.addOnlineTrack(track);
    await store.addOnlineTrack(track);
    await store.saveAlbum(name: 'Real', trackIds: [track.id]);
    final restored = LibraryStore(prefs);
    expect(restored.importedTracks.length, 1);
    expect(restored.importedTracks.single.title, 'Texts Go Green');
    expect(restored.importedTracks.single.isAvailableOffline, isFalse);
    expect(restored.albums.single.trackIds, ['youtube:kFXHPfI2JoI']);
  });
  test('los favoritos sobreviven al recrear la biblioteca', () async {
    final preferences = await SharedPreferences.getInstance();
    await LibraryStore(preferences).toggleFavorite('midnight-drive');
    expect(LibraryStore(preferences).favorites, contains('midnight-drive'));
  });
  test('guardar y quitar una demo actualiza la biblioteca persistida',
      () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    await store.toggleSaved('neon-rain');
    expect(store.saved, contains('neon-rain'));
    await store.toggleSaved('neon-rain');
    expect(store.saved, isEmpty);
  });

  test('historial conserva orden reciente y no repite canciones', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    await store.recordListen('midnight-drive');
    await store.recordListen('neon-rain');
    await store.recordListen('midnight-drive');
    expect(LibraryStore(prefs).recent, ['midnight-drive', 'neon-rain']);
  });

  test('el historial limita las canciones a las veinte últimas', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    for (var i = 0; i < 25; i++) {
      await store.recordListen('track-$i');
    }
    expect(store.recent.length, 20);
    expect(store.recent.first, 'track-24');
    expect(store.recent.last, 'track-5');
  });

  test('crear un álbum persiste nombre y canciones sin duplicados', () async {
    final prefs = await SharedPreferences.getInstance();
    await LibraryStore(prefs).saveAlbum(
        name: ' Mi álbum ', trackIds: ['neon-rain', 'neon-rain', 'afterglow']);
    final album = LibraryStore(prefs).albums.single;
    expect(album.name, 'Mi álbum');
    expect(album.trackIds, ['neon-rain', 'afterglow']);
  });

  test('editar un álbum conserva identidad y reemplaza su contenido', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    final album = await store.saveAlbum(name: 'Noche', trackIds: ['orbita']);
    await store.saveAlbum(id: album.id, name: 'Viaje', trackIds: ['afterglow']);
    expect(store.albums.single.id, album.id);
    expect(store.albums.single.name, 'Viaje');
    expect(store.albums.single.trackIds, ['afterglow']);
  });

  test('nombres vacíos y duplicados no modifican los álbumes', () async {
    final store = LibraryStore(await SharedPreferences.getInstance());
    await store.saveAlbum(name: 'Noche', trackIds: []);
    await expectLater(
        store.saveAlbum(name: '  ', trackIds: []), throwsArgumentError);
    await expectLater(
        store.saveAlbum(name: ' noche ', trackIds: []), throwsArgumentError);
    expect(store.albums.length, 1);
  });

  test('el tema sigue al sistema por defecto y conserva la elección', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    expect(store.appearance, 'system');
    await store.setAppearance('light');
    expect(LibraryStore(prefs).appearance, 'light');
  });
}
