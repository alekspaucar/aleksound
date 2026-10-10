import 'package:flutter/material.dart';
import '../catalog_track.dart';
import '../data/youtube_import_service.dart';
import '../state/library_store.dart';
import 'theme.dart';

Future<CatalogTrack?> showImportSong(
        BuildContext context, LibraryStore library) =>
    showModalBottomSheet<CatalogTrack>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ImportSongSheet(library: library));

class ImportSongSheet extends StatefulWidget {
  const ImportSongSheet({super.key, required this.library});
  final LibraryStore library;
  @override
  State<ImportSongSheet> createState() => _ImportSongSheetState();
}

class _ImportSongSheetState extends State<ImportSongSheet> {
  final link = TextEditingController();
  bool loading = false;
  String? error;
  @override
  void dispose() {
    link.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final track = await YoutubeImportService().fetch(link.text);
      await widget.library.addOnlineTrack(track);
      if (!widget.library.saved.contains(track.id)) {
        await widget.library.toggleSaved(track.id);
      }
      if (mounted) Navigator.pop(context, track);
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e is FormatException
              ? e.message
              : 'No se pudo consultar YouTube. Comprueba internet e intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          22, 22, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
          top: false,
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text('Añadir canción',
                          style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(
                      tooltip: 'Cancelar',
                      onPressed: loading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded))
                ]),
                const SizedBox(height: 12),
                Text(
                    'Pega un enlace de YouTube o YouTube Music. Obtendremos el título y la carátula reales.',
                    style: TextStyle(color: context.colors.muted, height: 1.5)),
                const SizedBox(height: 20),
                TextField(
                    controller: link,
                    autofocus: true,
                    enabled: !loading,
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => add(),
                    decoration: InputDecoration(
                        labelText: 'Enlace de la canción',
                        hintText: 'https://music.youtube.com/watch?v=…',
                        border: const OutlineInputBorder(),
                        errorText: error,
                        errorMaxLines: 4)),
                const SizedBox(height: 16),
                const Text(
                    'Se guarda como canción online. No es una descarga offline.',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: loading ? null : add,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_rounded),
                        label: Text(loading
                            ? 'Consultando YouTube…'
                            : 'Añadir a mi música'))),
              ]))));
}
