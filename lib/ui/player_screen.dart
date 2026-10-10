import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../state/music_controller.dart';
import 'artwork.dart';
import 'theme.dart';
import 'download_button.dart';

Future<void> showMusicPlayer(
    BuildContext context, MusicController music) async {
  music.playerVisible = true;
  music.ensureYoutube();
  try {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PlayerScreen(controller: music));
  } finally {
    music.playerVisible = false;
    // Esta integración requiere un reproductor visible, no audio oculto.
    if (music.usesYoutubePlayer) await music.suspendYoutube();
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.controller});
  final MusicController controller;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  MusicController get music => widget.controller;
  double? _scrubMilliseconds;
  String? _scrubTrackId;
  String? _gestureTrackId;
  int _seekRevision = 0;

  void _trackChanged() {
    if (_scrubTrackId != null &&
        (_scrubTrackId != music.current.id || music.loading)) {
      _seekRevision++;
      _scrubTrackId = null;
      _gestureTrackId = null;
      if (mounted) setState(() => _scrubMilliseconds = null);
    }
  }

  void _beginScrub(double value) {
    if (music.loading) return;
    _gestureTrackId = music.current.id;
    _scrub(value);
  }

  void _scrub(double value) {
    // Ownership is captured on finger-down, not on an old gesture's later
    // move/end callback after the queue has advanced to another song.
    if (_gestureTrackId != music.current.id || music.loading) return;
    setState(() {
      _seekRevision++;
      _scrubTrackId = _gestureTrackId;
      _scrubMilliseconds = value;
    });
  }

  Future<void> _finishScrub(double value) async {
    if (_gestureTrackId != music.current.id || music.loading) return;
    _gestureTrackId = null;
    final revision = _seekRevision, trackId = music.current.id;
    try {
      await music.seek(value);
    } finally {
      // A pending engine seek must not overwrite a newer gesture/song.
      if (mounted && revision == _seekRevision && trackId == music.current.id) {
        setState(() => _scrubMilliseconds = null);
      }
    }
  }

  String time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    music.addListener(_trackChanged);
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != music) {
      oldWidget.controller.removeListener(_trackChanged);
      music.addListener(_trackChanged);
      _seekRevision++;
      _scrubTrackId = null;
      _gestureTrackId = null;
      _scrubMilliseconds = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    music.removeListener(_trackChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && music.usesYoutubePlayer) {
      music.youtube?.pauseVideo();
    }
  }

  Future<void> libraryAction(bool save) async {
    try {
      if (save) {
        await music.library.toggleSaved(music.current.id);
      } else {
        await music.library.toggleFavorite(music.current.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el cambio.')));
      }
    }
  }

  Future<void> openSource() async {
    final id = music.current.youtubeVideoId;
    if (id == null) return;
    try {
      final ok = await launchUrl(
          Uri.https('www.youtube.com', '/watch', {'v': id}),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir YouTube.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir YouTube.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: music,
      builder: (context, _) {
        final track = music.current, p = context.colors;
        final shownPosition =
            _scrubTrackId == track.id && _scrubMilliseconds != null
                ? Duration(milliseconds: _scrubMilliseconds!.round())
                : music.position;
        final saved = music.library.saved.contains(track.id),
            favorite = music.library.favorites.contains(track.id);
        return SizedBox(
            height: MediaQuery.sizeOf(context).height,
            child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Material(
                    color: p.background,
                    child: Stack(fit: StackFit.expand, children: [
                      ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                          child: CoverArt(
                              variant: track.artwork,
                              imageUrl: track.artworkUrl,
                              radius: 0)),
                      ColoredBox(
                          color: p.background.withValues(
                              alpha: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? .96
                                  : .92)),
                      SafeArea(
                          child: LayoutBuilder(
                              builder:
                                  (context, bounds) => ListView(
                                          padding: const EdgeInsets.fromLTRB(
                                              22, 12, 22, 24),
                                          children: [
                                            Row(children: [
                                              IconButton(
                                                  tooltip: 'Cerrar reproductor',
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  icon: const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 30)),
                                              Expanded(
                                                  child: Column(children: [
                                                Text('Ahora suena',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: p.muted)),
                                                Text(
                                                    track.hasLocalAudio
                                                        ? 'Descargada · Sin internet'
                                                        : track.isYoutube
                                                            ? 'YouTube · Online'
                                                            : 'Demo local',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ])),
                                              IconButton(
                                                  tooltip: saved
                                                      ? 'Quitar de biblioteca'
                                                      : 'Guardar en biblioteca',
                                                  onPressed: () =>
                                                      libraryAction(true),
                                                  icon: Icon(saved
                                                      ? Icons.bookmark_rounded
                                                      : Icons
                                                          .bookmark_border_rounded)),
                                            ]),
                                            const SizedBox(height: 22),
                                            if (music.usesYoutubePlayer &&
                                                music.youtube != null)
                                              ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: YoutubePlayer(
                                                    key: ObjectKey(
                                                        music.youtube),
                                                    controller: music.youtube!,
                                                    aspectRatio: (bounds
                                                                .maxWidth -
                                                            44) /
                                                        math.max(
                                                            200,
                                                            (bounds.maxWidth -
                                                                    44) *
                                                                9 /
                                                                16),
                                                    backgroundColor:
                                                        Colors.black,
                                                  ))
                                            else
                                              Center(
                                                  child: CoverArt(
                                                      variant: track.artwork,
                                                      imageUrl:
                                                          track.artworkUrl,
                                                      size: math.min(
                                                          bounds.maxWidth - 44,
                                                          365),
                                                      radius: 8)),
                                            const SizedBox(height: 25),
                                            Row(children: [
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(track.title,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headlineMedium),
                                                    const SizedBox(height: 7),
                                                    Text(track.artist,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color: p.muted)),
                                                  ])),
                                              IconButton(
                                                  tooltip: favorite
                                                      ? 'Quitar de favoritos'
                                                      : 'Añadir a favoritos',
                                                  onPressed: () =>
                                                      libraryAction(false),
                                                  icon: Icon(favorite
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_border_rounded)),
                                            ]),
                                            const SizedBox(height: 20),
                                            Slider(
                                                value: shownPosition
                                                    .inMilliseconds
                                                    .toDouble()
                                                    .clamp(
                                                        0,
                                                        math
                                                            .max(
                                                                1,
                                                                music.duration
                                                                    .inMilliseconds)
                                                            .toDouble()),
                                                max: math
                                                    .max(
                                                        1,
                                                        music.duration
                                                            .inMilliseconds)
                                                    .toDouble(),
                                                onChanged:
                                                    music.duration > Duration.zero
                                                        ? _scrub
                                                        : null,
                                                onChangeStart:
                                                    music.duration > Duration.zero
                                                        ? _beginScrub
                                                        : null,
                                                onChangeEnd:
                                                    music.duration > Duration.zero
                                                        ? _finishScrub
                                                        : null,
                                                semanticFormatterCallback:
                                                    (value) => time(Duration(
                                                        milliseconds: value.round()))),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(time(shownPosition),
                                                      style: TextStyle(
                                                          color: p.muted,
                                                          fontSize: 11)),
                                                  Text(
                                                      music.duration ==
                                                              Duration.zero
                                                          ? '—:—'
                                                          : time(
                                                              music.duration),
                                                      style: TextStyle(
                                                          color: p.muted,
                                                          fontSize: 11))
                                                ]),
                                            const SizedBox(height: 22),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  IconButton(
                                                      tooltip:
                                                          'Reproducción aleatoria',
                                                      onPressed:
                                                          music.toggleShuffle,
                                                      icon: Icon(
                                                          Icons.shuffle_rounded,
                                                          color: music.shuffle
                                                              ? p.text
                                                              : p.muted)),
                                                  IconButton(
                                                      tooltip:
                                                          'Canción anterior',
                                                      onPressed: music.previous,
                                                      icon: const Icon(
                                                          Icons
                                                              .skip_previous_rounded,
                                                          size: 35)),
                                                  IconButton.filled(
                                                      style:
                                                          IconButton.styleFrom(
                                                              backgroundColor:
                                                                  p.text,
                                                              foregroundColor:
                                                                  p.background,
                                                              fixedSize:
                                                                  const Size(
                                                                      70, 70)),
                                                      tooltip: music.playing
                                                          ? 'Pausar'
                                                          : 'Reproducir',
                                                      onPressed: music.loading
                                                          ? null
                                                          : music.togglePlay,
                                                      icon: music.loading
                                                          ? CircularProgressIndicator(
                                                              color:
                                                                  p.background)
                                                          : Icon(
                                                              music.playing
                                                                  ? Icons
                                                                      .pause_rounded
                                                                  : Icons
                                                                      .play_arrow_rounded,
                                                              size: 40)),
                                                  IconButton(
                                                      tooltip:
                                                          'Siguiente canción',
                                                      onPressed: music.next,
                                                      icon: const Icon(
                                                          Icons
                                                              .skip_next_rounded,
                                                          size: 35)),
                                                  IconButton(
                                                      tooltip:
                                                          'Repetir canción',
                                                      onPressed:
                                                          music.toggleRepeat,
                                                      icon: Icon(
                                                          music.repeat
                                                              ? Icons
                                                                  .repeat_one_rounded
                                                              : Icons
                                                                  .repeat_rounded,
                                                          color: music.repeat
                                                              ? p.text
                                                              : p.muted)),
                                                ]),
                                            const SizedBox(height: 24),
                                            if (track.isYoutube)
                                              DownloadButton(
                                                  music: music, track: track),
                                            if (music.queueNotice != null)
                                              Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Text(
                                                      music.queueNotice!,
                                                      textAlign:
                                                          TextAlign.center)),
                                            Text(
                                                track.hasLocalAudio
                                                    ? 'Audio guardado en tu iPhone. Puedes cerrar esta pantalla y seguir escuchando.'
                                                    : music.nativeAudio &&
                                                            track.isYoutube
                                                        ? 'Escucha online. Descarga esta canción para reproducirla sin internet.'
                                                        : track.isYoutube
                                                            ? 'Requiere internet. Guardar conserva el enlace, no descarga el audio. Al cerrar este reproductor se pausa.'
                                                            : 'Audio original de demostración · 24 segundos',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    height: 1.5,
                                                    color: p.muted)),
                                            if (music.error != null)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12),
                                                  child: Text(music.error!,
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error))),
                                            if (track.isYoutube)
                                              TextButton.icon(
                                                  onPressed: openSource,
                                                  icon: const Icon(
                                                      Icons.open_in_new_rounded,
                                                      size: 17),
                                                  label: const Text(
                                                      'Abrir en YouTube')),
                                            TextButton.icon(
                                                onPressed: () =>
                                                    showModalBottomSheet<void>(
                                                        context: context,
                                                        useSafeArea: true,
                                                        isScrollControlled:
                                                            true,
                                                        builder:
                                                            (context) =>
                                                                SizedBox(
                                                                    height: math.min(
                                                                        500,
                                                                        MediaQuery.sizeOf(context).height *
                                                                            .75),
                                                                    child: ListView(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                        children: [
                                                                          const Padding(
                                                                              padding: EdgeInsets.all(8),
                                                                              child: Text('Cola de reproducción', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
                                                                          ...music.queue.map((item) => ListTile(
                                                                              leading: CoverArt(variant: item.artwork, imageUrl: item.artworkUrl, size: 42, radius: 6),
                                                                              title: Text(item.title),
                                                                              subtitle: Text(item.artist),
                                                                              onTap: () {
                                                                                music.playTrack(item, queue: music.queue);
                                                                                Navigator.pop(context);
                                                                              })),
                                                                        ]))),
                                                icon: const Icon(
                                                    Icons.queue_music_rounded),
                                                label: const Text(
                                                    'Ver cola de reproducción')),
                                          ]))),
                    ]))));
      });
}
