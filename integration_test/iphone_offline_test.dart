import 'package:aleksound/catalog_track.dart';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/state/music_controller.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Deny the remote source after a fresh process starts. This verifies the file
// path and persistence, not the physical Wi-Fi/cellular switch or lock taps.
class UnavailableSource implements MusicSource {
  int requests = 0;
  Never _unavailable() {
    requests++;
    throw StateError('No se permite consultar la red en esta prueba.');
  }

  @override
  Future<ResolvedAudio> resolve(CatalogTrack track) async => _unavailable();
  @override
  Future<SearchBatch> search(String query) async => _unavailable();
  @override
  Future<SearchBatch> nextPage(Object continuation) async => _unavailable();
  @override
  void close() {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('tras reiniciar, reproduce descarga sin consultar la fuente',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body:
                Text('Aleksound · Archivo persistente, fuente sin conexión'))));
    final native = IosMusic();
    final source = UnavailableSource();
    final downloads = DownloadStore(native, source);
    final controller = MusicController(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads,
        source: source);
    try {
      await (await AudioSession.instance)
          .configure(const AudioSessionConfiguration.music());
      await downloads.initialize();
      final initialCount = downloads.tracks.length;
      for (var i = 0; i < onlineCatalog.length; i++) {
        final original = onlineCatalog[i];
        expect(downloads.isDownloaded(original.id), true);
        final local = downloads.track(original);
        expect(local.audioUrl, startsWith('file:'));
        expect(local.artworkUrl, startsWith('file:'));
        expect(local.duration.inSeconds, greaterThan(60));
        await controller.playTrack(original, queue: onlineCatalog);
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(controller.error, isNull);
        expect(controller.current.id, original.id);
        expect(controller.position.inMilliseconds, greaterThan(1000));
        expect(controller.duration.inMilliseconds / 1000,
            closeTo(local.duration.inMilliseconds / 1000, 0.1));
        expect(source.requests, 0);
        await controller.seek(controller.duration.inMilliseconds - 1500);
        await Future<void>.delayed(const Duration(seconds: 4));
        expect(controller.error, isNull);
        expect(controller.current.id,
            onlineCatalog[(i + 1) % onlineCatalog.length].id,
            reason: '${original.title} debe avanzar en su final real.');
        expect(controller.position.inMilliseconds, greaterThan(1000));
      }
      final song = onlineCatalog[3];
      expect(downloads.isDownloaded(song.id), true,
          reason: 'Ejecutar primero la descarga real, sin desinstalar la app.');
      final saved = downloads.track(song);
      expect(saved.audioUrl, startsWith('file:'));
      expect(saved.artworkUrl, startsWith('file:'));
      expect(saved.duration.inSeconds, greaterThan(60));
      expect(saved.duration.inMilliseconds / 1000, closeTo(213, 1),
          reason:
              'Why We Lose no debe incluir una cola vacía ni durar el doble.');

      await controller.playTrack(song, queue: [song]);
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(controller.error, isNull);
      expect(controller.playing, true);
      expect(controller.position.inMilliseconds, greaterThan(1000));
      expect(controller.current.isAvailableOffline, true);
      expect(controller.duration.inMilliseconds / 1000, closeTo(213, 1));
      expect(source.requests, 0);

      const channel = MethodChannel('aleksound/native_music');
      var media = await channel.invokeMapMethod<String, dynamic>('mediaState');
      expect(media?['title'], song.title);
      expect(media?['rate'], 1);
      expect(media?['duration'] as num, closeTo(213, 1));
      expect(media?['commandsEnabled'], true);
      await controller.togglePlay();
      await controller.seek(40000);
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(controller.playing, false);
      expect(controller.position.inSeconds, greaterThanOrEqualTo(39));
      media = await channel.invokeMapMethod<String, dynamic>('mediaState');
      expect(media?['rate'], 0);
      await controller.togglePlay();
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(controller.playing, true);
      expect(source.requests, 0);
      await controller.togglePlay();

      // A correct label isn't sufficient: the real player must complete and
      // advance at the audio's real end, not wait through a silent second half.
      final next = onlineCatalog[4];
      await controller.playTrack(song, queue: [song, next]);
      await controller.seek(210000);
      await Future<void>.delayed(const Duration(seconds: 6));
      expect(controller.error, isNull);
      expect(controller.current.id, next.id,
          reason: 'La cola debe avanzar al terminar los 3:33 reales.');
      expect(controller.playing, true);
      expect(controller.position.inMilliseconds, greaterThan(1000));
      expect(source.requests, 0);
      final repaired = await native.library();
      expect((repaired['records'] as List).length, initialCount,
          reason: 'Conservar también las canciones añadidas por el usuario.');
      for (final record in repaired['records'] as List) {
        expect((record as Map)['timingVersion'], 1);
      }
      await controller.togglePlay();
    } finally {
      await native.nowPlaying({'title': ''});
      controller.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
