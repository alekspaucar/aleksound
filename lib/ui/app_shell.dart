import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../catalog_track.dart';
import '../data/demo_catalog.dart';
import '../data/personal_album.dart';
import '../state/music_controller.dart';
import 'album_screen.dart';
import 'artwork.dart';
import 'player_screen.dart';
import 'theme.dart';
import 'import_song_sheet.dart';
import 'library_backup_sheet.dart';
import 'discovery_page.dart';
import 'download_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final MusicController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final navigation = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final p = context.colors;
        final app = LayoutBuilder(
            builder: (context, inner) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: inner.biggest),
                  child: Navigator(
                      key: navigation,
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                            builder: (_) =>
                                MusicHome(controller: widget.controller),
                          )),
                ));
        if (bounds.maxWidth < 700) return app;
        return Scaffold(
            backgroundColor: p.surface,
            body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Aleksound / Vista móvil',
                        style: TextStyle(fontSize: 12, color: p.muted)),
                    const SizedBox(height: 16),
                    Container(
                        width: 430,
                        height:
                            math.max(100, math.min(880, bounds.maxHeight - 76)),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: p.line, width: 2)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: app)),
                  ])),
            ));
      });
}

class MusicHome extends StatefulWidget {
  const MusicHome({super.key, required this.controller});
  final MusicController controller;
  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> {
  int tab = 0;
  String mood = 'Todo', libraryFilter = 'Descargas', query = '';
  final search = TextEditingController();
  final librarySearch = TextEditingController();
  String libraryQuery = '', libraryOrder = 'Colección';
  MusicController get music => widget.controller;

  void selectTab(int value) {
    final enteringDownloads = value == 2 && tab != 2;
    setState(() {
      if (enteringDownloads) {
        libraryFilter = 'Descargas';
        libraryQuery = '';
        librarySearch.clear();
      }
      tab = value;
    });
    if (enteringDownloads) unawaited(refreshDownloads());
  }

  Future<void> refreshDownloads() async {
    try {
      await music.downloads?.refresh();
    } catch (_) {
      if (mounted) message('No se pudo actualizar la biblioteca local.');
    }
  }

  @override
  void dispose() {
    search.dispose();
    librarySearch.dispose();
    super.dispose();
  }

  void openPlayer() => showMusicPlayer(context, music);
  Future<void> play(CatalogTrack track) async {
    await music.playTrack(track);
    if (mounted) openPlayer();
  }

  Future<void> importSong() async {
    final track = await showImportSong(context, music.library);
    if (mounted && track != null) {
      setState(() {
        tab = 1;
        query = '';
        search.clear();
      });
      message('Canción añadida a tu música · Online');
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
    }
  }

  Future<void> save(CatalogTrack track) async {
    final wasSaved = music.library.saved.contains(track.id);
    try {
      await music.library.toggleSaved(track.id);
      message(wasSaved
          ? 'Canción quitada de tu biblioteca'
          : 'Enlace guardado · No es una descarga offline');
    } catch (_) {
      message('No se pudo guardar. Intenta de nuevo.');
    }
  }

  Future<void> favorite(CatalogTrack track) async {
    try {
      await music.library.toggleFavorite(track.id);
    } catch (_) {
      message('No se pudo guardar el favorito.');
    }
  }

  Future<void> createAlbum() async {
    final album = await showAlbumEditor(context,
        library: music.library, tracks: music.tracks);
    if (mounted && album != null) {
      setState(() {
        tab = 2;
        libraryFilter = 'Álbumes';
      });
      openAlbum(album);
    }
  }

  void openAlbum(PersonalAlbum album) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AlbumScreen(id: album.id, controller: music),
      ));

  Future<void> addToAlbum(CatalogTrack track) async {
    if (music.library.albums.isEmpty) {
      message('Crea un álbum en Biblioteca y elige sus canciones.');
      setState(() {
        tab = 2;
        libraryFilter = 'Álbumes';
      });
      return;
    }
    final album = await showModalBottomSheet<PersonalAlbum>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
          child: ListView(shrinkWrap: true, children: [
        const Padding(
            padding: EdgeInsets.all(22),
            child: Text('Añadir a un álbum',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600))),
        ...music.library.albums.map((album) => ListTile(
            title: Text(album.name),
            subtitle: Text('${album.trackIds.length} canciones'),
            leading: const Icon(Icons.album_outlined),
            onTap: () => Navigator.pop(context, album))),
      ])),
    );
    if (album == null) return;
    try {
      await music.library.saveAlbum(
          id: album.id,
          name: album.name,
          trackIds: [...album.trackIds, track.id]);
      message('Añadida a ${album.name}');
    } catch (_) {
      message('No se pudo actualizar el álbum.');
    }
  }

  void appearance() => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => AnimatedBuilder(
            animation: music.library,
            builder: (context, _) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(22),
                  child: Text('Apariencia',
                      style: TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w600))),
              ...{
                'system': 'Según el dispositivo',
                'light': 'Claro',
                'dark': 'Oscuro'
              }.entries.map((entry) => ListTile(
                    title: Text(entry.value),
                    subtitle: entry.key == 'system'
                        ? const Text('Cambia automáticamente con tu teléfono')
                        : null,
                    leading: Icon(entry.key == 'system'
                        ? Icons.brightness_auto_outlined
                        : entry.key == 'light'
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined),
                    trailing: music.library.appearance == entry.key
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () async {
                      try {
                        await music.library.setAppearance(entry.key);
                      } catch (_) {
                        message('No se pudo guardar el tema.');
                      }
                    },
                  )),
              const SizedBox(height: 18),
            ])),
          ));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: music,
      builder: (context, _) => Scaffold(
            body: SafeArea(
                bottom: false,
                child: Column(children: [
                  Expanded(
                      child: IndexedStack(
                          index: tab,
                          children: [home(), searchPage(), libraryPage()])),
                  if (music.error != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 4),
                        child: Text(music.error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12))),
                  miniPlayer(),
                ])),
            bottomNavigationBar: NavigationBar(
              height: 70,
              selectedIndex: tab,
              onDestinationSelected: selectTab,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Inicio'),
                NavigationDestination(
                    icon: Icon(Icons.search_rounded), label: 'Buscar'),
                NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: 'Biblioteca'),
              ],
            ),
          ));

  Widget home() {
    final tracks = mood == 'Todo'
        ? music.tracks
        : music.tracks.where((t) => t.genre == mood).toList();
    final recent = music.library.recent
        .map((id) => music.tracks.where((t) => t.id == id))
        .expand((t) => t)
        .toList();
    return ListView(
        primary: false,
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                const Icon(Icons.graphic_eq_rounded, size: 26),
                const SizedBox(width: 8),
                const Text('aleksound',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.9)),
                const Spacer(),
                IconButton(
                    tooltip: 'Añadir canción',
                    onPressed: importSong,
                    icon: const Icon(Icons.add_rounded)),
                IconButton(
                    tooltip: 'Buscar música',
                    onPressed: () => setState(() => tab = 1),
                    icon: const Icon(Icons.search_rounded)),
                IconButton(
                    tooltip: 'Apariencia',
                    onPressed: appearance,
                    icon: const Icon(Icons.brightness_6_outlined)),
              ])),
          const SizedBox(height: 26),
          sectionTitle('Escuchadas recientemente'),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.history_rounded, color: context.colors.muted),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text('Reproduce una canción y aparecerá aquí.',
                            style: TextStyle(
                                color: context.colors.muted, height: 1.5))),
                  ]),
                ))
          else
            shelf(recent),
          const SizedBox(height: 16),
          sectionTitle('Tu música'),
          const SizedBox(height: 15),
          SizedBox(
              height: 40,
              child: ListView(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                scrollDirection: Axis.horizontal,
                children: ['Todo', 'Remix', 'Urbano', 'Electrónica']
                    .map((value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: mood == value,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                                color: mood == value
                                    ? context.colors.background
                                    : context.colors.text),
                            onSelected: (_) => setState(() => mood = value),
                          ),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 16),
          shelf(tracks),
          const SizedBox(height: 20),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                Expanded(
                    child: shortcut(
                        Icons.favorite_border_rounded,
                        'Favoritos',
                        '${music.library.favorites.length} canciones',
                        'Favoritos')),
                const SizedBox(width: 12),
                Expanded(
                    child: shortcut(Icons.album_outlined, 'Mis álbumes',
                        '${music.library.albums.length} álbumes', 'Álbumes')),
              ])),
          const SizedBox(height: 26),
          sectionTitle('Todas las canciones'),
          const SizedBox(height: 8),
          ...tracks.map(trackRow),
          Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text('Catálogo de prueba · Audio original incluido',
                  style: Theme.of(context).textTheme.bodySmall)),
        ]);
  }

  Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge));
  Widget shelf(List<CatalogTrack> tracks) => SizedBox(
      height: 209,
      child: ListView.separated(
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemBuilder: (_, index) => trackCard(tracks[index]),
      ));
  Widget trackCard(CatalogTrack track) => SizedBox(
      width: 148,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => play(track),
                child: RepaintBoundary(
                    child: CoverArt(
                        variant: track.artwork,
                        imageUrl: track.artworkUrl,
                        size: 148,
                        radius: 6)))),
        const SizedBox(height: 9),
        Text(track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall),
      ]));
  Widget shortcut(IconData icon, String title, String caption, String filter) =>
      Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            tab = 2;
            libraryFilter = filter;
          }),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(height: 12),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(caption, style: Theme.of(context).textTheme.bodySmall),
                  ])),
        ),
      );
  Widget trackRow(CatalogTrack track) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 3),
        leading: CoverArt(
            variant: track.artwork,
            imageUrl: track.artworkUrl,
            size: 48,
            radius: 6),
        title: Text(track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('${track.artist} · ${track.genre}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall),
        onTap: () => play(track),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones de ${track.title}',
          icon: Icon(Icons.more_vert_rounded,
              color: context.colors.muted, size: 21),
          onSelected: (value) async {
            try {
              if (value == 'save') {
                save(track);
              } else if (value == 'album') {
                addToAlbum(track);
              } else if (value == 'download') {
                await music.downloadTrack(track);
              } else if (value == 'delete') {
                await music.deleteDownload(track.id);
              } else {
                favorite(track);
              }
            } catch (_) {
              message('No se pudo completar la operación. Reintenta.');
            }
          },
          itemBuilder: (_) => [
            if (track.isYoutube && music.downloads?.supported == true)
              PopupMenuItem(
                  value: music.downloads!.isDownloaded(track.id)
                      ? 'delete'
                      : 'download',
                  child: Text(music.downloads!.isDownloaded(track.id)
                      ? 'Borrar audio descargado'
                      : 'Descargar audio')),
            const PopupMenuItem(
                value: 'album', child: Text('Añadir a un álbum')),
            PopupMenuItem(
                value: 'save',
                child: Text(music.library.saved.contains(track.id)
                    ? 'Quitar de biblioteca'
                    : 'Guardar enlace online')),
            PopupMenuItem(
                value: 'favorite',
                child: Text(music.library.favorites.contains(track.id)
                    ? 'Quitar de favoritos'
                    : 'Añadir a favoritos')),
          ],
        ),
      );
  Widget searchPage() {
    if (music.discovery != null) {
      return DiscoveryPage(
          music: music,
          onPlay: (track) async {
            if (mounted) openPlayer();
          },
          onImport: importSong,
          onSave: save,
          onAlbum: addToAlbum);
    }
    final results = searchCatalog(music.tracks, query);
    return ListView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text('Buscar en mi música',
                  style: Theme.of(context).textTheme.headlineMedium)),
          const SizedBox(height: 19),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextButton.icon(
                  onPressed: importSong,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Añadir canción desde YouTube'))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                controller: search,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                    hintText: 'Canciones, artistas o géneros',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () => setState(() {
                                  search.clear();
                                  query = '';
                                }),
                            icon: const Icon(Icons.close_rounded)),
                    filled: true,
                    fillColor: context.colors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none)),
              )),
          const SizedBox(height: 24),
          if (query.isEmpty) ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Wrap(
                    spacing: 8,
                    children: ['Phonk', 'C.R.O', 'Remix', 'Reguetón']
                        .map((genre) => ActionChip(
                            label: Text(genre),
                            onPressed: () => setState(() {
                                  query = genre;
                                  search.text = genre;
                                })))
                        .toList())),
            const SizedBox(height: 24),
          ],
          sectionTitle(query.isEmpty
              ? 'Todas las canciones'
              : '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'}'),
          const SizedBox(height: 12),
          if (results.isEmpty)
            emptyState(Icons.search_off_rounded, 'No encontramos esa canción',
                'Esta búsqueda filtra tu colección. Añade la canción con un enlace de YouTube.'),
          ...results.map(trackRow),
        ]);
  }

  Widget libraryPage() {
    final ids = libraryFilter == 'Favoritos'
        ? music.library.favorites
        : libraryFilter == 'Descargas'
            ? music.downloads?.tracks.map((t) => t.id).toSet() ?? <String>{}
            : music.library.saved;
    final collection =
        music.allTracks.where((t) => ids.contains(t.id)).toList();
    final tracks = searchCatalog(collection, libraryQuery);
    if (libraryOrder == 'Nombre') {
      tracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (libraryOrder == 'Artista') {
      tracks.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    } else {
      final order = ids.toList();
      tracks.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }
    final albums = music.library.albums.where((album) {
      if (libraryQuery.trim().isEmpty) return true;
      return normalizeCatalogText(album.name)
          .contains(normalizeCatalogText(libraryQuery.trim()));
    }).toList();
    if (libraryOrder != 'Colección') {
      albums
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final count = libraryFilter == 'Álbumes' ? albums.length : tracks.length;
    final noun = libraryFilter == 'Álbumes'
        ? (count == 1 ? 'álbum' : 'álbumes')
        : (count == 1 ? 'canción' : 'canciones');
    return ListView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                Expanded(
                    child: Text('Biblioteca',
                        style: Theme.of(context).textTheme.headlineLarge)),
                IconButton(
                    tooltip: 'Crear álbum',
                    onPressed: createAlbum,
                    icon: const Icon(Icons.add_rounded)),
                PopupMenuButton<String>(
                    tooltip: 'Opciones de biblioteca',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) => value == 'backup'
                        ? showLibraryBackup(context, music.library)
                        : showArchivedAlbums(),
                    itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'archived',
                              child: Text(
                                  'Archivados (${music.library.archivedAlbums.length})')),
                          const PopupMenuItem(
                              value: 'backup',
                              child: Text('Copia de seguridad')),
                        ]),
              ])),
          const SizedBox(height: 22),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Wrap(
                  spacing: 8,
                  children: ['Descargas', 'Álbumes', 'Guardadas', 'Favoritos']
                      .map((value) => ChoiceChip(
                            label: Text(value),
                            selected: libraryFilter == value,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                                color: libraryFilter == value
                                    ? context.colors.background
                                    : context.colors.text),
                            onSelected: (_) => setState(() {
                              libraryFilter = value;
                              if (value == 'Álbumes' &&
                                  libraryOrder == 'Artista') {
                                libraryOrder = 'Nombre';
                              }
                            }),
                          ))
                      .toList())),
          const SizedBox(height: 18),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: librarySearch,
                        onChanged: (value) =>
                            setState(() => libraryQuery = value),
                        decoration: InputDecoration(
                            hintText: libraryFilter == 'Álbumes'
                                ? 'Buscar álbumes'
                                : 'Buscar canciones',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: libraryQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar búsqueda de biblioteca',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setState(() {
                                          librarySearch.clear();
                                          libraryQuery = '';
                                        })),
                            filled: true,
                            fillColor: context.colors.surface,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none)))),
                PopupMenuButton<String>(
                    tooltip: 'Ordenar biblioteca',
                    icon: const Icon(Icons.sort_rounded),
                    initialValue: libraryOrder,
                    onSelected: (value) => setState(() => libraryOrder = value),
                    itemBuilder: (_) => [
                          'Colección',
                          'Nombre',
                          if (libraryFilter != 'Álbumes') 'Artista'
                        ]
                            .map((value) => CheckedPopupMenuItem(
                                value: value,
                                checked: libraryOrder == value,
                                child: Text(value)))
                            .toList()),
              ])),
          const SizedBox(height: 12),
          if (libraryFilter == 'Descargas') ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                    '${((music.downloads?.bytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB en tu iPhone · ${tracks.length} canciones')),
            if (music.downloads?.error != null)
              Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(music.downloads!.error!)),
            ...?music.downloads?.jobs.map((job) {
              final matches = music.allTracks.where((t) => t.id == job['id']);
              return ListTile(
                  title: Text(job['title'] as String? ?? 'Descarga'),
                  subtitle: Text(job['status'] == 'failed'
                      ? (job['error'] as String? ?? 'Descarga interrumpida')
                      : job['status'] == 'resolving'
                          ? 'Obteniendo audio…'
                          : job['status'] == 'verifying'
                              ? 'Verificando archivo…'
                              : 'Descargando ${(((job['progress'] as num?) ?? 0) * 100).round()} %'),
                  trailing: matches.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              music.downloads?.cancel(job['id'] as String))
                      : DownloadButton(
                          music: music, track: matches.first, compact: true));
            }),
          ],
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text('$count $noun · $libraryOrder',
                  style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 12),
          if (libraryFilter == 'Álbumes') ...[
            if (albums.isEmpty && libraryQuery.trim().isNotEmpty)
              emptyState(
                  Icons.search_off_rounded,
                  'No hay álbumes con ese nombre',
                  'Prueba otra búsqueda o crea un álbum.'),
            if (albums.isEmpty && libraryQuery.trim().isEmpty)
              emptyState(Icons.album_outlined, 'Tus propios álbumes',
                  'Ponles un nombre y reúne las canciones que quieras escuchar juntas.',
                  action: createAlbum, actionText: 'Crear álbum'),
            ...albums.map((album) {
              final contents = album.trackIds
                  .map((id) => music.allTracks.where((t) => t.id == id))
                  .expand((t) => t)
                  .toList();
              return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
                  leading: AlbumCover(tracks: contents),
                  title: Text(album.name),
                  subtitle: Text(
                      '${contents.length} ${contents.length == 1 ? 'canción' : 'canciones'}',
                      style: Theme.of(context).textTheme.bodySmall),
                  trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones de ${album.name}',
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showAlbumEditor(context,
                              library: music.library,
                              tracks: music.allTracks,
                              album: album);
                        } else {
                          try {
                            await music.library
                                .setAlbumArchived(album.id, true);
                            message(
                                'Álbum archivado. Puedes recuperarlo en Opciones de biblioteca.');
                          } catch (_) {
                            message('No se pudo archivar el álbum.');
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'edit', child: Text('Editar álbum')),
                            PopupMenuItem(
                                value: 'archive',
                                child: Text('Archivar álbum')),
                          ]),
                  onTap: () => openAlbum(album));
            }),
          ] else ...[
            if (tracks.isEmpty && libraryQuery.trim().isNotEmpty)
              emptyState(Icons.search_off_rounded, 'No hay coincidencias',
                  'Prueba otra canción o artista.'),
            if (tracks.isEmpty && libraryQuery.trim().isEmpty)
              emptyState(
                  libraryFilter == 'Guardadas'
                      ? Icons.library_music_outlined
                      : libraryFilter == 'Descargas'
                          ? Icons.download_rounded
                          : Icons.favorite_border_rounded,
                  libraryFilter == 'Guardadas'
                      ? 'Todavía no hay canciones guardadas'
                      : libraryFilter == 'Descargas'
                          ? 'Todavía no hay descargas'
                          : 'Todavía no hay favoritos',
                  libraryFilter == 'Guardadas'
                      ? 'Guarda enlaces de tus canciones. Las de YouTube requieren internet.'
                      : libraryFilter == 'Descargas'
                          ? 'Busca una canción y toca Descargar para escucharla sin internet.'
                          : 'Toca el corazón del reproductor para añadir favoritos.',
                  action: () => selectTab(libraryFilter == 'Descargas' ? 1 : 0),
                  actionText: libraryFilter == 'Descargas'
                      ? 'Buscar música'
                      : 'Explorar música'),
            ...tracks.map(trackRow),
          ],
        ]);
  }

  Future<void> showArchivedAlbums() => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => AnimatedBuilder(
          animation: music.library,
          builder: (context, _) => SizedBox(
                height: math.min(600, MediaQuery.sizeOf(context).height * .8),
                child: SafeArea(
                    child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 12, 8),
                      child: Row(children: [
                        Expanded(
                            child: Text('Álbumes archivados',
                                style: Theme.of(context).textTheme.titleLarge)),
                        IconButton(
                            tooltip: 'Cerrar archivados',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context)),
                      ])),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                          'Tus canciones y el orden del álbum se conservan.')),
                  Expanded(
                      child: ListView(children: [
                    if (music.library.archivedAlbums.isEmpty)
                      emptyState(
                          Icons.inventory_2_outlined,
                          'No hay álbumes archivados',
                          'Los álbumes que archives aparecerán aquí.'),
                    ...music.library.archivedAlbums.map((album) => ListTile(
                        title: Text(album.name),
                        subtitle: Text('${album.trackIds.length} canciones'),
                        leading: const Icon(Icons.album_outlined),
                        trailing: IconButton(
                            tooltip: 'Recuperar ${album.name}',
                            icon: const Icon(Icons.unarchive_outlined),
                            onPressed: () async {
                              try {
                                await music.library
                                    .setAlbumArchived(album.id, false);
                                message('Álbum recuperado');
                              } catch (_) {
                                message('No se pudo recuperar el álbum.');
                              }
                            }))),
                  ])),
                ])),
              )));

  Widget emptyState(IconData icon, String title, String caption,
          {VoidCallback? action, String actionText = 'Explorar música'}) =>
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 38),
          child: Column(children: [
            Icon(icon, size: 42, color: context.colors.muted),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(caption,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.muted, height: 1.6)),
            if (action != null)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child:
                      FilledButton(onPressed: action, child: Text(actionText))),
          ]));
  Widget miniPlayer() => Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            onTap: openPlayer,
            borderRadius: BorderRadius.circular(8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 3, 7),
                  child: Row(children: [
                    CoverArt(
                        variant: music.current.artwork,
                        imageUrl: music.current.artworkUrl,
                        size: 43,
                        radius: 5),
                    const SizedBox(width: 11),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(music.current.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(music.current.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ])),
                    IconButton(
                        tooltip: music.playing ? 'Pausar' : 'Reproducir',
                        onPressed: music.loading
                            ? null
                            : () {
                                if (music.usesYoutubePlayer) {
                                  openPlayer();
                                } else {
                                  music.togglePlay();
                                }
                              },
                        icon: music.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(
                                music.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 29)),
                    IconButton(
                        tooltip: 'Siguiente canción',
                        onPressed: () async {
                          await music.next();
                          if (mounted) openPlayer();
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 26)),
                  ])),
              ExcludeSemantics(
                  child: LinearProgressIndicator(
                      minHeight: 2,
                      value: (music.position.inMilliseconds /
                              math.max(1, music.duration.inMilliseconds))
                          .clamp(0, 1),
                      backgroundColor: context.colors.line,
                      color: context.colors.text)),
            ])),
      ));
}
