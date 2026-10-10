import 'package:aleksound/data/demo_catalog.dart';
import 'package:aleksound/state/library_store.dart';
import 'package:aleksound/ui/album_screen.dart';
import 'package:aleksound/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('el formulario crea un álbum con las canciones seleccionadas',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LibraryStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
            body: Builder(
          builder: (context) => FilledButton(
              onPressed: () =>
                  showAlbumEditor(context, library: store, tracks: demoCatalog),
              child: const Text('Abrir')),
        ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Nombre del álbum'),
        'Para el viaje');
    await tester.tap(find.text('Neon Rain'));
    await tester.tap(find.widgetWithText(FilledButton, 'Crear álbum'));
    await tester.pumpAndSettle();
    expect(store.albums.single.name, 'Para el viaje');
    expect(store.albums.single.trackIds, ['neon-rain']);
  });

  testWidgets('editar conserva el orden anterior y guarda el cambio elegido',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore(prefs);
    final album = await store
        .saveAlbum(name: 'Orden', trackIds: ['neon-rain', 'midnight-drive']);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
            body: AlbumEditor(
                library: store, tracks: demoCatalog, album: album))));
    expect(find.text('1. Neon Rain'), findsOneWidget);
    await tester.tap(find.byTooltip('Subir Midnight Drive'));
    await tester.pump();
    expect(find.text('1. Midnight Drive'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();
    expect(LibraryStore(prefs).albums.single.trackIds,
        ['midnight-drive', 'neon-rain']);
  });

  testWidgets('guardar un álbum conserva una referencia todavía no disponible',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LibraryStore(await SharedPreferences.getInstance());
    final album = await store
        .saveAlbum(name: 'Conservar', trackIds: ['missing-id', 'neon-rain']);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
            body: AlbumEditor(
                library: store, tracks: demoCatalog, album: album))));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();
    expect(store.albums.single.trackIds, ['missing-id', 'neon-rain']);
  });

  testWidgets('la paleta cambia con el tema claro u oscuro del sistema',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    Widget app() => MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: Builder(
            builder: (context) => ColoredBox(
                key: const Key('background'),
                color: context.colors.background)));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(app());
    expect(tester.widget<ColoredBox>(find.byKey(const Key('background'))).color,
        AppPalette.light.background);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(tester.widget<ColoredBox>(find.byKey(const Key('background'))).color,
        AppPalette.dark.background);
  });
}
