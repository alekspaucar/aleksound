import 'dart:async';
import 'package:aleksound/catalog_track.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/state/music_controller.dart';
import 'package:aleksound/ui/app_shell.dart';
import 'package:aleksound/ui/player_screen.dart';
import 'package:aleksound/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iphone_music_test.dart' show Native, Source, song;

class CountingNative extends Native {
  int refreshes = 0;
  @override
  Future<Map<String, dynamic>> library() {
    refreshes++;
    return super.library();
  }
}

// Only the slow audio-engine boundary is delayed; the real screen and its
// subscription to controller progress remain active during the gesture.
class DelayedSeekMusic extends MusicController {
  DelayedSeekMusic(super.library, {super.downloads});
  final seeks = <double>[];
  final completion = Completer<void>();
  CatalogTrack? selectedTrack;
  @override
  CatalogTrack get current => selectedTrack ?? super.current;
  @override
  Future<void> seek(double milliseconds) async {
    seeks.add(milliseconds);
    await completion.future;
    position = Duration(milliseconds: milliseconds.round());
    notifyListeners();
  }
}

void main() {
  testWidgets('un gesto anterior no adelanta la canción siguiente',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final downloads = DownloadStore(Native(), Source());
    await downloads.initialize();
    final music = DelayedSeekMusic(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads);
    addTearDown(music.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: PlayerScreen(controller: music)));
    music.duration = const Duration(minutes: 2);
    music.position = const Duration(seconds: 10);
    music.notifyListeners();
    await tester.pump();
    await tester.ensureVisible(find.byType(Slider));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Slider)));
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();
    // Simulate an automatic queue advance while the finger remains down.
    music.selectedTrack = song;
    music.position = const Duration(seconds: 1);
    music.notifyListeners();
    await tester.pump();
    await gesture.moveBy(const Offset(15, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(music.seeks, isEmpty,
        reason: 'Ese dedo empezó sobre otra canción: descartar su salto.');
    music.completion.complete();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('arrastrar actualiza barra y tiempo antes de buscar audio',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final downloads = DownloadStore(Native(), Source());
    await downloads.initialize();
    final music = DelayedSeekMusic(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads);
    addTearDown(music.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: PlayerScreen(controller: music)));
    music.duration = const Duration(minutes: 2);
    music.position = const Duration(seconds: 10);
    music.notifyListeners();
    await tester.pump();
    await tester.ensureVisible(find.byType(Slider));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Slider)));
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();
    final selected = tester.widget<Slider>(find.byType(Slider)).value;
    expect(selected, greaterThan(60000));
    expect(music.seeks, isEmpty,
        reason: 'No acumular saltos mientras se mueve el dedo.');
    final seconds = (selected / 1000).floor();
    expect(
        find.text(
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
        findsOneWidget);
    // A stale engine update must not pull the thumb backwards.
    music.position = const Duration(seconds: 11);
    music.notifyListeners();
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, selected);
    await gesture.up();
    await tester.pump();
    expect(music.seeks, hasLength(1));
    expect(tester.widget<Slider>(find.byType(Slider)).value, selected);
    music.completion.complete();
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value,
        closeTo(music.position.inMilliseconds.toDouble(), 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Biblioteca muestra Descargas al entrar y al volver',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final native = CountingNative();
    final downloads = DownloadStore(native, Source());
    await downloads.initialize();
    final music = MusicController(
        LibraryStore(await SharedPreferences.getInstance()),
        downloads: downloads);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: MusicHome(controller: music)));
    final navigation = find.byType(NavigationBar);
    await tester.tap(
        find.descendant(of: navigation, matching: find.text('Biblioteca')));
    await tester.pumpAndSettle();
    ChoiceChip downloadsChip() =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Descargas'));
    expect(downloadsChip().selected, true);
    expect(find.text('Todavía no hay descargas'), findsOneWidget);
    expect(native.refreshes, 2,
        reason: 'Revisar portadas pendientes sin bloquear la navegación.');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Álbumes'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('Inicio')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(of: navigation, matching: find.text('Biblioteca')));
    await tester.pumpAndSettle();
    expect(downloadsChip().selected, true);
    expect(native.refreshes, 3);
    await tester.pumpWidget(const SizedBox());
    music.dispose();
  });
}
