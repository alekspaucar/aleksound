import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../catalog_track.dart';
import '../data/personal_album.dart';
import '../data/demo_catalog.dart';
import '../state/library_store.dart';
import '../state/music_controller.dart';
import 'artwork.dart';
import 'player_screen.dart';
import 'theme.dart';
import 'download_button.dart';

Future<PersonalAlbum?> showAlbumEditor(
  BuildContext context, {
  required LibraryStore library,
  required List<CatalogTrack> tracks,
  PersonalAlbum? album,
}) =>
    showModalBottomSheet<PersonalAlbum>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          AlbumEditor(library: library, tracks: tracks, album: album),
    );

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, required this.tracks, this.size = 56});
  final List<CatalogTrack> tracks;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: tracks.isEmpty
              ? ColoredBox(
                  color: context.colors.surface,
                  child: Icon(Icons.album_outlined,
                      size: size * .45, color: context.colors.muted))
              : tracks.length == 1
                  ? CoverArt(
                      variant: tracks.first.artwork,
                      imageUrl: tracks.first.artworkUrl,
                      size: size,
                      radius: 0)
                  : Wrap(
                      children: List.generate(
                          4,
                          (i) => CoverArt(
                              variant: tracks[i % tracks.length].artwork,
                              imageUrl: tracks[i % tracks.length].artworkUrl,
                              size: size / 2,
                              radius: 0))),
        ),
      );
}

class AlbumEditor extends StatefulWidget {
  const AlbumEditor(
      {super.key, required this.library, required this.tracks, this.album});
  final LibraryStore library;
  final List<CatalogTrack> tracks;
  final PersonalAlbum? album;
  @override
  State<AlbumEditor> createState() => _AlbumEditorState();
}

class _AlbumEditorState extends State<AlbumEditor> {
  late final name = TextEditingController(text: widget.album?.name ?? '');
  late final selected = widget.album?.trackIds.toSet() ?? <String>{};
  final search = TextEditingController();
  String query = '';
  String? error;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final album = await widget.library
          .saveAlbum(id: widget.album?.id, name: name.text, trackIds: selected);
      if (mounted) Navigator.pop(context, album);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is ArgumentError
              ? e.message.toString()
              : 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  void move(String id, int offset) {
    final ids = selected.toList();
    final index = ids.indexOf(id), next = ids.indexOf(id) + offset;
    if (index < 0 || next < 0 || next >= ids.length) return;
    ids.insert(next, ids.removeAt(index));
    setState(() {
      selected.clear();
      selected.addAll(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: math.min(650, MediaQuery.sizeOf(context).height - inset - 40),
        child: Material(
          color: context.colors.background,
          child: SafeArea(
              top: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 12, 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              widget.album == null
                                  ? 'Crear álbum'
                                  : 'Editar álbum',
                              style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                          tooltip: 'Cancelar',
                          onPressed:
                              saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ])),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: TextField(
                      controller: name,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          labelText: 'Nombre del álbum',
                          hintText: 'Por ejemplo, Para el viaje',
                          border: const OutlineInputBorder(),
                          errorText: error),
                      onChanged: (_) {
                        if (error != null) setState(() => error = null);
                      },
                    )),
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Elige canciones · ${selected.length} seleccionadas',
                            style: TextStyle(color: context.colors.muted)))),
                Expanded(
                    child: ListView(children: [
                  if (selected.isNotEmpty) ...[
                    const Padding(
                        padding: EdgeInsets.fromLTRB(22, 6, 22, 4),
                        child: Text('Orden de reproducción',
                            style: TextStyle(fontWeight: FontWeight.w600))),
                    ...selected.toList().asMap().entries.map((entry) {
                      final matches =
                          widget.tracks.where((t) => t.id == entry.value);
                      final track = matches.isEmpty ? null : matches.first;
                      final title = track?.title ?? 'Canción no disponible';
                      return ListTile(
                          key: ValueKey('selected-${entry.value}'),
                          contentPadding:
                              const EdgeInsets.only(left: 22, right: 6),
                          title: Text('${entry.key + 1}. $title',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: track == null
                              ? null
                              : Text(track.artist,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                tooltip: 'Subir $title',
                                onPressed: saving || entry.key == 0
                                    ? null
                                    : () => move(entry.value, -1),
                                icon: const Icon(Icons.arrow_upward_rounded,
                                    size: 20)),
                            IconButton(
                                tooltip: 'Bajar $title',
                                onPressed:
                                    saving || entry.key == selected.length - 1
                                        ? null
                                        : () => move(entry.value, 1),
                                icon: const Icon(Icons.arrow_downward_rounded,
                                    size: 20)),
                            IconButton(
                                tooltip: 'Quitar $title del álbum',
                                onPressed: saving
                                    ? null
                                    : () => setState(
                                        () => selected.remove(entry.value)),
                                icon:
                                    const Icon(Icons.close_rounded, size: 20)),
                          ]));
                    }),
                    const Divider(indent: 22, endIndent: 22),
                  ],
                  Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                      child: TextField(
                          controller: search,
                          enabled: !saving,
                          onChanged: (value) => setState(() => query = value),
                          decoration: const InputDecoration(
                              labelText: 'Añadir canciones',
                              hintText: 'Buscar en tu música',
                              prefixIcon: Icon(Icons.search_rounded)))),
                  ...searchCatalog(widget.tracks, query)
                      .where((t) => !selected.contains(t.id))
                      .map((track) => CheckboxListTile(
                            value: selected.contains(track.id),
                            controlAffinity: ListTileControlAffinity.trailing,
                            secondary: CoverArt(
                                variant: track.artwork,
                                imageUrl: track.artworkUrl,
                                size: 44,
                                radius: 6),
                            title: Text(track.title),
                            subtitle: Text(track.artist,
                                style: Theme.of(context).textTheme.bodySmall),
                            onChanged: saving
                                ? null
                                : (value) => setState(() {
                                      value == true
                                          ? selected.add(track.id)
                                          : selected.remove(track.id);
                                    }),
                          )),
                ])),
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: saving ? null : save,
                            child: Text(saving
                                ? 'Guardando…'
                                : widget.album == null
                                    ? 'Crear álbum'
                                    : 'Guardar cambios')))),
              ])),
        ),
      ),
    );
  }
}

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.id, required this.controller});
  final String id;
  final MusicController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final matches =
            controller.library.albums.where((album) => album.id == id);
        if (matches.isEmpty) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Álbum no disponible')));
        }
        final album = matches.first;
        final tracks = album.trackIds
            .map((id) => controller.allTracks.where((t) => t.id == id))
            .expand((t) => t)
            .toList();
        final offline = tracks.where((t) => t.hasLocalAudio).toList();
        return Scaffold(
          appBar: AppBar(
              backgroundColor: context.colors.background,
              title: const Text('Tu álbum'),
              actions: [
                IconButton(
                    tooltip: 'Editar álbum',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showAlbumEditor(context,
                        library: controller.library,
                        tracks: controller.allTracks,
                        album: album)),
                IconButton(
                    tooltip: 'Archivar álbum',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () async {
                      try {
                        await controller.library
                            .setAlbumArchived(album.id, true);
                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          messenger.showSnackBar(const SnackBar(
                              content: Text(
                                  'Álbum archivado. Puedes recuperarlo en Biblioteca.')));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No se pudo archivar el álbum.')));
                        }
                      }
                    }),
              ]),
          body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Center(child: AlbumCover(tracks: tracks, size: 190)),
                const SizedBox(height: 22),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(album.name,
                        style: Theme.of(context).textTheme.headlineLarge)),
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                    child: Text(
                        '${tracks.length} ${tracks.length == 1 ? 'canción' : 'canciones'} · Álbum personal',
                        style: TextStyle(color: context.colors.muted))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: FilledButton.icon(
                        onPressed: tracks.isEmpty
                            ? null
                            : () async {
                                await controller.playTrack(tracks.first,
                                    queue: tracks);
                                if (context.mounted) {
                                  await showMusicPlayer(context, controller);
                                }
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Reproducir álbum'))),
                if (controller.nativeAudio && offline.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                      child: OutlinedButton.icon(
                          onPressed: () async {
                            await controller.playTrack(offline.first,
                                queue: offline);
                            if (context.mounted) {
                              await showMusicPlayer(context, controller);
                            }
                          },
                          icon: const Icon(Icons.offline_pin_outlined),
                          label: Text(
                              'Sin internet · ${offline.length} descargadas'))),
                const SizedBox(height: 22),
                if (tracks.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                          'Este álbum está vacío. Toca el lápiz para añadir canciones.',
                          style: TextStyle(color: context.colors.muted))),
                ...tracks.map((track) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 4),
                      leading: CoverArt(
                          variant: track.artwork,
                          imageUrl: track.artworkUrl,
                          size: 48,
                          radius: 6),
                      title: Text(track.title),
                      subtitle: Text(
                          '${track.artist}${track.hasLocalAudio ? ' · Descargada' : ''}',
                          style: Theme.of(context).textTheme.bodySmall),
                      trailing: track.isYoutube && controller.nativeAudio
                          ? DownloadButton(
                              music: controller, track: track, compact: true)
                          : Icon(controller.current.id == track.id &&
                                  controller.playing
                              ? Icons.graphic_eq
                              : Icons.play_arrow_rounded),
                      onTap: () async {
                        await controller.playTrack(track, queue: tracks);
                        if (context.mounted) {
                          await showMusicPlayer(context, controller);
                        }
                      },
                    )),
              ]),
          bottomNavigationBar: SafeArea(
              top: false,
              child: ListTile(
                onTap: () => showMusicPlayer(context, controller),
                tileColor: context.colors.surface,
                title: Text(controller.current.title),
                subtitle: Text(controller.waitingForPlayer
                    ? 'Abre el reproductor para continuar'
                    : controller.current.artist),
                trailing: IconButton(
                    tooltip: controller.playing ? 'Pausar' : 'Reproducir',
                    onPressed: () {
                      if (controller.usesYoutubePlayer) {
                        showMusicPlayer(context, controller);
                      } else {
                        controller.togglePlay();
                      }
                    },
                    icon: Icon(controller.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded)),
              )),
        );
      });
}
