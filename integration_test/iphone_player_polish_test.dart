import 'dart:io';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/state/music_controller.dart';
import 'package:aleksound/ui/app_shell.dart';
import 'package:aleksound/ui/artwork.dart';
import 'package:aleksound/ui/player_screen.dart';
import 'package:aleksound/ui/theme.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iphone_offline_test.dart' show UnavailableSource;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Biblioteca, portada local y salto con el motor real del iPhone',
      (tester) async {
    final native = IosMusic(), source = UnavailableSource();
    final downloads = DownloadStore(native, source);
    await downloads.initialize();
    final music = MusicController(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads,
        source: source);
    try {
      await (await AudioSession.instance)
          .configure(const AudioSessionConfiguration.music());
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          home: MusicHome(controller: music)));
      final navigation = find.byType(NavigationBar);
      Future<void> navigate(String title) async {
        await tester
            .tap(find.descendant(of: navigation, matching: find.text(title)));
        await tester.pump();
      }

      await navigate('Biblioteca');
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Descargas'))
              .selected,
          true);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Álbumes'));
      await tester.pump();
      await navigate('Inicio');
      await navigate('Biblioteca');
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Descargas'))
              .selected,
          true);

      final song =
          downloads.tracks.firstWhere((t) => t.id == 'youtube:sDMxQF18yvA');
      expect(song.artworkUrl, startsWith('file:'));
      expect(await File.fromUri(Uri.parse(song.artworkUrl)).exists(), true);
      await music.playTrack(song, queue: [song]);
      await Future<void>.delayed(const Duration(seconds: 1));
      await music.togglePlay();
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          home: PlayerScreen(controller: music)));
      await tester.pump();
      expect(
          find.byWidgetPredicate((widget) =>
              widget is CoverArt && widget.imageUrl == song.artworkUrl),
          findsWidgets);
      await tester.ensureVisible(find.byType(Slider));
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(Slider)));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      final selected = tester.widget<Slider>(find.byType(Slider)).value;
      expect(selected, greaterThan(100000));
      expect(music.position.inSeconds, lessThan(5),
          reason: 'El motor salta al soltar, no en cada movimiento.');
      await gesture.up();
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value,
          closeTo(selected, 100));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();
      expect(music.error, isNull);
      expect(music.position.inMilliseconds, closeTo(selected, 150));
      expect(tester.widget<Slider>(find.byType(Slider)).value,
          closeTo(selected, 150));
      expect(source.requests, 0);
      binding.reportData = {
        'downloadsFirst': true,
        'localCover': true,
        'seekMilliseconds': selected.round(),
        'remoteAudioRequests': source.requests
      };
    } finally {
      await tester.pumpWidget(const SizedBox());
      await native.nowPlaying({'title': ''});
      music.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
