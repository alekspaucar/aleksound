import 'dart:async';
import 'package:flutter/material.dart';
import '../catalog_track.dart';
import '../state/music_controller.dart';
import 'artwork.dart';
import 'download_button.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage(
      {super.key,
      required this.music,
      required this.onPlay,
      required this.onImport,
      required this.onSave,
      required this.onAlbum});
  final MusicController music;
  final Future<void> Function(CatalogTrack) onPlay, onSave, onAlbum;
  final Future<void> Function() onImport;
  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final text = TextEditingController();
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    text.dispose();
    super.dispose();
  }

  void search(String query) {
    debounce?.cancel();
    unawaited(widget.music.discovery!.search(query));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.music.discovery!;
    final music = widget.music;
    return ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text('Buscar música',
                  style: Theme.of(context).textTheme.headlineMedium)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: TextField(
                controller: text,
                textInputAction: TextInputAction.search,
                onChanged: (q) {
                  debounce?.cancel();
                  debounce =
                      Timer(const Duration(milliseconds: 650), () => search(q));
                },
                onSubmitted: search,
                decoration: InputDecoration(
                    hintText: 'Canción o artista en YouTube',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                        tooltip: 'Buscar',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => search(text.text)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Wrap(
                  spacing: 8,
                  children: ['Phonk', 'C.R.O', 'Remix', 'Reguetón']
                      .map((q) => ActionChip(
                          label: Text(q),
                          onPressed: () {
                            text.text = q;
                            search(q);
                          }))
                      .toList())),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextButton.icon(
                      onPressed: widget.onImport,
                      icon: const Icon(Icons.add_link),
                      label: const Text('Pegar enlace de YouTube Music')))),
          if (d.loading)
            const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator())),
          if (d.error != null)
            Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.error!),
                      TextButton(
                          onPressed: () => search(text.text),
                          child: const Text('Reintentar'))
                    ])),
          if (!d.loading &&
              d.query.isNotEmpty &&
              d.results.isEmpty &&
              d.error == null)
            const Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                    'No hay resultados. Prueba el título o el nombre del artista.')),
          if (d.query.isEmpty)
            const Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                    'Encuentra canciones, escucha y descarga para llevarlas contigo.')),
          ...d.results.map((original) {
            final t = music.downloads?.track(original) ?? original;
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 22, right: 8),
              leading: CoverArt(
                  variant: t.artwork,
                  imageUrl: t.artworkUrl,
                  size: 48,
                  radius: 6),
              title:
                  Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${t.artist}${t.hasLocalAudio ? ' · Descargada' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              onTap: () async {
                await music.playTrack(t, queue: d.results);
                if (context.mounted) await widget.onPlay(t);
              },
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                DownloadButton(music: music, track: t, compact: true),
                PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    onSelected: (value) async {
                      try {
                        await music.library.addOnlineTrack(original);
                        if (value == 'save') {
                          await widget.onSave(original);
                        } else {
                          await widget.onAlbum(original);
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'No se pudo guardar la canción. Reintenta.')));
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'save',
                              child: Text('Guardar en biblioteca')),
                          PopupMenuItem(
                              value: 'album', child: Text('Añadir a un álbum'))
                        ]),
              ]),
            );
          }),
          if (d.hasMore && !d.loading)
            Center(
                child: TextButton(
                    onPressed: d.loadingMore ? null : d.more,
                    child: Text(
                        d.loadingMore ? 'Buscando más…' : 'Más resultados'))),
          const SizedBox(height: 24),
        ]);
  }
}
