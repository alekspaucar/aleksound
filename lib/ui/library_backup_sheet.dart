import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/library_backup.dart';
import '../state/library_store.dart';
import 'theme.dart';

Future<void> showLibraryBackup(BuildContext context, LibraryStore library) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => LibraryBackupSheet(library: library));

class LibraryBackupSheet extends StatefulWidget {
  const LibraryBackupSheet({super.key, required this.library});
  final LibraryStore library;
  @override
  State<LibraryBackupSheet> createState() => _LibraryBackupSheetState();
}

class _LibraryBackupSheetState extends State<LibraryBackupSheet> {
  late final exported =
      TextEditingController(text: widget.library.exportBackup());
  final input = TextEditingController();
  bool restore = false, busy = false;
  LibraryBackup? preview;
  String? error, status;
  @override
  void dispose() {
    exported.dispose();
    input.dispose();
    super.dispose();
  }

  Future<void> copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: exported.text));
      if (mounted) {
        setState(() =>
            status = 'Copia copiada. Guárdala en un archivo o en tus notas.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'No se pudo copiar. Selecciona el texto y cópialo manualmente.');
      }
    }
  }

  void check() {
    try {
      final checked = LibraryBackup.decode(input.text);
      setState(() {
        preview = checked;
        error = null;
        status = null;
      });
    } on FormatException catch (e) {
      setState(() {
        preview = null;
        error = e.message;
      });
    }
  }

  Future<void> merge() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.library.restoreBackup(input.text);
      if (mounted) {
        setState(() {
          exported.text = widget.library.exportBackup();
          status =
              'Copia combinada. Tus canciones y álbumes anteriores se conservaron.';
          preview = null;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e is FormatException
              ? e.message
              : e is StateError
                  ? e.message.toString()
                  : 'No se pudo restaurar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
        canPop: !busy,
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height:
                math.min(700, MediaQuery.sizeOf(context).height - inset - 30),
            child: Material(
              color: context.colors.background,
              child: SafeArea(
                  top: false,
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 12, 8),
                        child: Row(children: [
                          Expanded(
                              child: Text('Copia de seguridad',
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          IconButton(
                              tooltip: 'Cerrar copia de seguridad',
                              onPressed:
                                  busy ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded)),
                        ])),
                    Expanded(
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                            children: [
                          const Text(
                              'Conserva tus enlaces, álbumes, favoritos y ajustes. El audio no se incluye.'),
                          const SizedBox(height: 18),
                          Wrap(
                              spacing: 8,
                              children: [false, true]
                                  .map((value) => ChoiceChip(
                                        label: Text(value
                                            ? 'Restaurar'
                                            : 'Crear copia'),
                                        selected: restore == value,
                                        labelStyle: TextStyle(
                                            color: restore == value
                                                ? context.colors.background
                                                : context.colors.text),
                                        onSelected: busy
                                            ? null
                                            : (_) => setState(() {
                                                  restore = value;
                                                  error = null;
                                                  status = null;
                                                }),
                                      ))
                                  .toList()),
                          const SizedBox(height: 20),
                          if (!restore) ...[
                            Text(
                                'Importadas: ${widget.library.importedTracks.length} · Álbumes: ${widget.library.allAlbums.length} · Favoritos: ${widget.library.favorites.length}',
                                style: TextStyle(color: context.colors.muted)),
                            const SizedBox(height: 16),
                            TextField(
                                controller: exported,
                                readOnly: true,
                                minLines: 5,
                                maxLines: 7,
                                decoration: const InputDecoration(
                                    labelText: 'Contenido de tu copia',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                onPressed: copy,
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copiar respaldo')),
                          ] else ...[
                            TextField(
                                controller: input,
                                enabled: !busy,
                                minLines: 5,
                                maxLines: 7,
                                onChanged: (_) => setState(() {
                                      preview = null;
                                      status = null;
                                      error = null;
                                    }),
                                decoration: const InputDecoration(
                                    labelText: 'Pega tu copia de Aleksound',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 16),
                            OutlinedButton(
                                onPressed: busy ? null : check,
                                child: const Text('Comprobar copia')),
                            if (preview != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                  'Importadas: ${preview!.tracks.length} · Álbumes: ${preview!.albums.length}. Se combinarán con tu biblioteca; las coincidencias no se duplican.'),
                              const SizedBox(height: 16),
                              FilledButton(
                                  onPressed: busy ? null : merge,
                                  child: Text(busy
                                      ? 'Restaurando…'
                                      : 'Combinar con mi biblioteca')),
                            ],
                          ],
                          if (error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                          if (status != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(status!)),
                        ])),
                  ])),
            ),
          ),
        ));
  }
}
