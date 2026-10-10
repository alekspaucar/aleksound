import 'package:aleksound/state/music_controller.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/offline/download_store.dart';
import 'iphone_music_test.dart' show Native, Source;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('una descarga conserva el género y artista del catálogo original',
      () async {
    SharedPreferences.setMockInitialValues({});
    final song = onlineCatalog.first;
    final native = Native();
    native.snapshot['records'] = [
      {
        'id': song.id,
        'videoId': song.youtubeVideoId,
        'title': song.title,
        'artist': 'Canal',
        'audioUri': 'file:///sandbox/song.m4a',
        'bytes': 5000,
        'duration': 120.0,
      }
    ];
    final store = DownloadStore(native, Source());
    await store.initialize();
    final library = LibraryStore(await SharedPreferences.getInstance());
    await library.addOnlineTrack(song);
    final music = MusicController(library, downloads: store);
    final restored = music.tracks.firstWhere((t) => t.id == song.id);
    expect(restored.genre, song.genre);
    expect(restored.artist, song.artist);
    expect(restored.isAvailableOffline, true);
    music.dispose();
  });
  test('sin pantalla visible no crea un reproductor YouTube oculto', () async {
    SharedPreferences.setMockInitialValues({});
    final music =
        MusicController(LibraryStore(await SharedPreferences.getInstance()));
    expect(() => music.ensureYoutube(autoPlay: true), returnsNormally);
    expect(music.youtube, isNull);
    expect(music.playing, isFalse);
    expect(music.waitingForPlayer, isTrue);
    expect(music.error, isNotNull);
    music.dispose();
  });
}
