import 'package:aleksound/data/ios_player_script.dart';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/state/music_controller.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iphone_audio_test.dart' show DiagnosticSource;

// Hide downloads only from this test's view. Never delete the user's library.
class OnlineOnlyMusic extends IosMusic {
  @override
  Future<Map<String, dynamic>> library() async => {'records': [], 'jobs': []};
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('audio online sin descarga conserva duración y final reales',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('Aleksound · Duración online'))));
    final native = OnlineOnlyMusic();
    final source =
        DiagnosticSource(YoutubeAudioSource(playerScript: IosPlayerScript()));
    final downloads = DownloadStore(native, source);
    final controller = MusicController(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads,
        source: source);
    try {
      await downloads.initialize();
      await (await AudioSession.instance)
          .configure(const AudioSessionConfiguration.music());
      final song = onlineCatalog[3], next = onlineCatalog[4];
      await controller.playTrack(song, queue: [song, next]);
      await Future<void>.delayed(const Duration(seconds: 2));
      binding.reportData = {
        'onlineError': controller.error,
        'onlineDuration': controller.duration.inMilliseconds / 1000,
        'onlinePosition': controller.position.inMilliseconds / 1000,
      };
      expect(controller.error, isNull);
      expect(controller.duration.inMilliseconds / 1000, closeTo(213, 1),
          reason: 'Escuchar sin descargar tampoco debe duplicar la duración.');
      expect(controller.position.inMilliseconds, greaterThan(1000));
      expect(controller.current.isDownloaded, false);
      await controller.seek(210000);
      final limit = DateTime.now().add(const Duration(seconds: 40));
      while ((controller.current.id != next.id ||
              controller.loading ||
              controller.position.inMilliseconds < 1000) &&
          DateTime.now().isBefore(limit)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      expect(controller.error, isNull);
      expect(controller.current.id, next.id);
      expect(controller.duration.inMilliseconds / 1000, closeTo(198.5, 1));
      expect(controller.position.inMilliseconds, greaterThan(1000));
      expect(controller.current.isDownloaded, false);
      await controller.togglePlay();
    } finally {
      await native.nowPlaying({'title': ''});
      controller.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
