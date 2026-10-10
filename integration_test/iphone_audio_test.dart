import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aleksound/data/ios_player_script.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:aleksound/catalog_track.dart';

class DiagnosticSource implements MusicSource {
  DiagnosticSource(this.source);
  final MusicSource source;
  @override
  Future<ResolvedAudio> resolve(CatalogTrack track) async {
    try {
      return await source.resolve(track);
    } catch (e) {
      final details =
          e.toString().replaceAll(RegExp(r'https?://\S+'), '[fuente]');
      // ignore: avoid_print
      print(
          'Resolución iPhone: ${e.runtimeType}: ${details.substring(0, details.length.clamp(0, 500))}');
      rethrow;
    }
  }

  @override
  Future<SearchBatch> search(String q) => source.search(q);
  @override
  Future<SearchBatch> nextPage(Object continuation) =>
      source.nextPage(continuation);
  @override
  void close() => source.close();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('LOCAL_AUDIO_ONLY')) {
    testWidgets('iPhone busca, descarga, valida y reproduce archivo local',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: Center(
                  child: Text('Aleksound · Prueba de audio en iPhone')))));
      const channel = MethodChannel('aleksound/native_music');
      await channel.invokeMethod<void>(
          'initializePlayerScript', 'function jsc(input) { return input; }');
      expect(
          await channel.invokeMethod<String>(
              'evaluatePlayerScript', 'JSON.stringify(jsc({ok: true}))'),
          '{"ok":true}');
      final script = IosPlayerScript();
      expect(await script.executeJavaScript('JSON.stringify({modules: true})'),
          '{"modules":true}');
      final source = DiagnosticSource(YoutubeAudioSource(playerScript: script));
      final native = IosMusic();
      final store = DownloadStore(native, source);
      final player = AudioPlayer();
      try {
        final results = await source.search('C.R.O phonk');
        expect(results.tracks, isNotEmpty);
        await store.initialize();
        final song = onlineCatalog[3];
        await store.download(song);
        final limit = DateTime.now().add(const Duration(minutes: 3));
        while (!store.isDownloaded(song.id) &&
            store.busy(song.id) &&
            DateTime.now().isBefore(limit)) {
          await Future<void>.delayed(const Duration(seconds: 1));
          await store.refresh();
        }
        expect(store.isDownloaded(song.id), true,
            reason: '${store.job(song.id)?['error'] ?? store.error} '
                '${store.job(song.id)?['diagnostic'] ?? ''}');
        final saved = store.track(song);
        expect(saved.audioUrl, startsWith('file:'));
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        final duration = await player
            .setAudioSource(AudioSource.uri(Uri.parse(saved.audioUrl)));
        expect(duration?.inSeconds, greaterThan(60));
        unawaited(player.play());
        await Future<void>.delayed(const Duration(seconds: 3));
        expect(player.position.inMilliseconds, greaterThan(1000));
        await player.pause();
        await native.nowPlaying({
          'title': saved.title,
          'artist': saved.artist,
          'duration': duration!.inSeconds,
          'position': player.position.inSeconds,
          'playing': false,
          'enabled': true,
          'artworkUri': saved.artworkUrl
        });
        await store.refresh();
        expect(store.track(song).isAvailableOffline, true);
      } finally {
        await player.dispose();
        store.dispose();
        native.dispose();
        source.close();
      }
    }, timeout: const Timeout(Duration(minutes: 6)));
  }

  testWidgets('motor iOS y publicación MediaPlayer con audio propio incluido',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Text(
                'Validación del motor iOS; no es una descarga de YouTube'))));
    const channel = MethodChannel('aleksound/native_music');
    final player = AudioPlayer();
    final native = IosMusic();
    try {
      await (await AudioSession.instance)
          .configure(const AudioSessionConfiguration.music());
      final duration = await player
          .setAudioSource(AudioSource.asset('assets/audio/midnight.wav'));
      expect(duration?.inSeconds, greaterThan(0));
      unawaited(player.play());
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(player.position.inMilliseconds, greaterThan(1000));
      await native.nowPlaying({
        'title': 'Aleksound · Validación local',
        'artist': 'Audio propio incluido',
        'duration': duration!.inMilliseconds / 1000,
        'position': player.position.inMilliseconds / 1000,
        'playing': true,
        'enabled': true
      });
      final media =
          await channel.invokeMapMethod<String, dynamic>('mediaState');
      expect(media?['title'], 'Aleksound · Validación local');
      expect(media?['rate'], 1);
      expect(media?['audioCategory'], 'AVAudioSessionCategoryPlayback');
      expect(media?['backgroundAudio'], true);
      expect(media?['commandsEnabled'], true);
      await player.pause();
    } finally {
      await native.nowPlaying({'title': ''});
      native.dispose();
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
