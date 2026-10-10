import 'package:flutter/material.dart';
import '../catalog_track.dart';
import '../state/music_controller.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton(
      {super.key,
      required this.music,
      required this.track,
      this.compact = false});
  final MusicController music;
  final CatalogTrack track;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final downloads = music.downloads;
    final job = downloads?.job(track.id);
    final busy = downloads?.busy(track.id) == true;
    final done = downloads?.isDownloaded(track.id) == true;
    final progress = (job?['progress'] as num?)?.toDouble() ?? 0;
    final label = done
        ? 'Descargada · Sin internet'
        : busy
            ? (job?['status'] == 'resolving'
                ? 'Obteniendo audio…'
                : job?['status'] == 'verifying'
                    ? 'Verificando archivo…'
                    : 'Descargando ${(progress * 100).round()} %')
            : job?['status'] == 'failed'
                ? 'Reintentar descarga'
                : 'Descargar';
    final icon = done
        ? Icons.offline_pin_rounded
        : busy
            ? Icons.close_rounded
            : Icons.download_rounded;
    Future<void> action() async {
      try {
        if (done) return;
        if (busy) {
          await downloads!.cancel(track.id);
          return;
        }
        if (downloads?.supported != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Descarga desde Aleksound en tu iPhone.')));
          }
          return;
        }
        await music.downloadTrack(track);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo iniciar la descarga. Reintenta.')));
        }
      }
    }

    if (compact) {
      return IconButton(
          tooltip: busy ? '$label · Cancelar' : label,
          onPressed: done ? null : action,
          icon: Icon(icon));
    }
    return Column(children: [
      FilledButton.icon(
          onPressed: done ? null : action,
          icon: Icon(icon),
          label: Text(busy ? '$label · Cancelar' : label)),
      if (busy)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
                value: job?['status'] == 'downloading' ? progress : null)),
      if (job?['status'] == 'failed')
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                job?['error'] as String? ?? 'La descarga se interrumpió.',
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ]);
  }
}
