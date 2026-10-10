import 'dart:async';
import 'package:aleksound/data/ios_player_script.dart';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final song in onlineCatalog) {
    testWidgets('archivo local de ${song.title}, mismo ID y versión',
        (tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Text('Aleksound · ${song.title}'))));
      final native = IosMusic();
      final source = YoutubeAudioSource(playerScript: IosPlayerScript());
      final store = DownloadStore(native, source);
      final player = AudioPlayer();
      try {
        await store.initialize();
        // Exercise the existing explicit retry with a fresh URL. A retry never
        // replaces the selected ID, trusts a partial file or deletes records.
        for (var attempt = 1;
            attempt <= 3 && !store.isDownloaded(song.id);
            attempt++) {
          await store.download(song);
          final limit = DateTime.now().add(const Duration(minutes: 3));
          while (store.busy(song.id) && DateTime.now().isBefore(limit)) {
            await Future<void>.delayed(const Duration(seconds: 1));
            await store.refresh();
          }
          // ignore: avoid_print
          print('${song.title}: intento $attempt, '
              '${store.isDownloaded(song.id) ? 'archivo verificado' : store.job(song.id)?['error']}');
        }
        expect(store.isDownloaded(song.id), true,
            reason: store.job(song.id)?['error'] as String? ?? store.error);
        final saved = store.track(song);
        expect(saved.id, song.id);
        expect(saved.youtubeVideoId, song.youtubeVideoId);
        expect(saved.audioUrl, startsWith('file:'));
        expect(saved.artworkUrl, startsWith('file:'));
        await (await AudioSession.instance)
            .configure(const AudioSessionConfiguration.music());
        final duration = await player
            .setAudioSource(AudioSource.uri(Uri.parse(saved.audioUrl)));
        expect(duration?.inSeconds, greaterThan(60));
        // play() completes when playback ends, not when it starts.
        unawaited(player.play());
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(player.position.inMilliseconds, greaterThan(1000));
        await player.pause();
      } finally {
        await player.dispose();
        store.dispose();
        native.dispose();
        source.close();
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
