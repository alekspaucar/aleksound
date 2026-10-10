import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../catalog_track.dart';
import '../data/demo_catalog.dart';
import '../data/online_catalog.dart';
import 'library_store.dart';
import 'youtube_playback_identity.dart';
import '../data/youtube_audio_source.dart';
import '../offline/download_store.dart';
import 'discovery_store.dart';

class MusicController extends ChangeNotifier {
  MusicController(this.library, {this.downloads, this.source, this.discovery}) {
    library.addListener(notifyListeners);
    downloads?.addListener(_downloadsChanged);
    discovery?.addListener(notifyListeners);
    if (downloads != null) {
      _subscriptions.add(downloads!.native.events
          .where((e) => e['kind'] == 'remote')
          .listen((e) {
        unawaited(_remote(e));
      }));
    }
    _subscriptions.addAll([
      _player.playerStateStream.listen((_) {
        if (usesYoutubePlayer) return;
        _publishNative();
        _recordCurrentListen();
        if (_loaded &&
            _player.processingState == ProcessingState.completed &&
            !_advancing) {
          _advancing = true;
          unawaited(next().whenComplete(() => _advancing = false));
        }
        notifyListeners();
      }),
      _player.positionStream.listen((value) {
        if (usesYoutubePlayer) return;
        position = value;
        if (value.inSeconds != _lastPublishedSecond) _publishNative();
        notifyListeners();
      }),
      _player.durationStream.listen((value) {
        if (usesYoutubePlayer) return;
        duration = value ?? current.duration;
        _publishNative();
        notifyListeners();
      }),
      _player.errorStream.listen((_) => _reportError()),
    ]);
  }
  final LibraryStore library;
  final DownloadStore? downloads;
  final MusicSource? source;
  final DiscoveryStore? discovery;
  bool get nativeAudio => downloads?.supported == true;
  bool get usesYoutubePlayer =>
      !nativeAudio && current.isYoutube && !current.hasLocalAudio;
  int _lastPublishedSecond = -1;
  String? queueNotice;
  String? _activeAudioUri;
  Uri? _previewUri;
  Future<void> _releasePreview(Uri? uri) async {
    if (uri == null) return;
    try {
      await downloads?.native.releasePlayback(uri);
    } catch (_) {
      // Temporary cache cleanup must never turn valid playback into an error.
    }
  }

  void _downloadsChanged() {
    notifyListeners();
    unawaited(_switchToDownloadedAudio());
  }

  Future<void> _switchToDownloadedAudio() async {
    if (_disposed ||
        loading ||
        !_loaded ||
        !current.hasLocalAudio ||
        _activeAudioUri == current.audioUrl) {
      return;
    }
    final resume = playing, from = position, selected = current;
    loading = true;
    try {
      await _player.pause();
      await _player.setAudioSource(
          AudioSource.uri(Uri.parse(selected.audioUrl)),
          initialPosition: from);
      _activeAudioUri = selected.audioUrl;
      final oldPreview = _previewUri;
      _previewUri = null;
      await _releasePreview(oldPreview);
      if (resume) {
        unawaited(_player.play().catchError((Object _) => _reportError()));
      }
    } catch (_) {
      error =
          'La canción está descargada. Pulsa reproducir para abrir el archivo local.';
      _loaded = false;
    } finally {
      loading = false;
      if (!_disposed) {
        _publishNative();
        notifyListeners();
      }
    }
  }

  Future<void> _remote(Map<String, dynamic> event) async {
    try {
      switch (event['action']) {
        case 'play':
          if (!playing) await togglePlay();
        case 'pause':
        case 'stop':
          await _player.pause();
        case 'next':
          await next();
        case 'previous':
          await previous();
        case 'seek':
          await seek(((event['position'] as num?) ?? 0).toDouble() * 1000);
      }
    } catch (_) {
      _reportError();
    }
  }

  void _publishNative() {
    if (!nativeAudio || _disposed) return;
    _lastPublishedSecond = position.inSeconds;
    unawaited(downloads!.native.nowPlaying({
      'title': _loaded ? current.title : '',
      'artist': current.artist,
      'duration': duration.inMilliseconds / 1000,
      'position': position.inMilliseconds / 1000,
      'playing': playing,
      'enabled': _loaded,
      'artworkUri': current.artworkUrl,
    }).catchError((Object _) {}));
  }

  Future<void> downloadTrack(CatalogTrack track) async {
    if (track.isYoutube) await library.addOnlineTrack(track);
    await downloads?.download(track);
  }

  Future<void> deleteDownload(String id) async {
    if (current.id == id && current.hasLocalAudio) {
      await _player.stop();
      _loaded = false;
      _publishNative();
    }
    await downloads?.delete(id);
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<CatalogTrack> get tracks {
    final imported = library.importedTracks;
    final collection = [
      ...onlineCatalog,
      ...imported.where((t) => !onlineCatalog.any((i) => i.id == t.id)),
    ];
    final byId = {for (final t in collection) t.id: t};
    for (final t in downloads?.tracks ?? <CatalogTrack>[]) {
      byId.putIfAbsent(t.id, () => t);
    }
    return byId.values.map((t) => downloads?.track(t) ?? t).toList();
  }

  // Conserva el contenido de los álbumes antiguos, sin mostrar demos en Inicio.
  List<CatalogTrack> get allTracks => [...tracks, ...demoCatalog];
  List<CatalogTrack> _queue = onlineCatalog;
  List<CatalogTrack> get queue =>
      List.unmodifiable(_queue.map((t) => downloads?.track(t) ?? t));
  int index = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  YoutubePlayerController? youtube;
  final List<StreamSubscription<dynamic>> _youtubeSubscriptions = [];
  bool _youtubePlaying = false;
  bool playerVisible = false;
  bool _pendingYoutubePlay = false;
  bool get waitingForPlayer =>
      usesYoutubePlayer && _pendingYoutubePlay && !playerVisible;
  final _youtubeIdentity = YoutubePlaybackIdentity();
  PlayerState _lastYoutubeState = PlayerState.unknown;
  bool _metadataPending = false;
  bool _advancing = false;
  bool _loaded = false,
      loading = false,
      shuffle = false,
      repeat = false,
      _disposed = false;
  String? error;
  CatalogTrack get current => downloads?.track(_queue[index]) ?? _queue[index];
  bool get playing => usesYoutubePlayer
      ? _youtubePlaying
      : _player.playing && _player.processingState != ProcessingState.completed;

  void ensureYoutube({bool autoPlay = false}) {
    if (!usesYoutubePlayer || youtube != null) return;
    _pendingYoutubePlay = _pendingYoutubePlay || autoPlay;
    if (!playerVisible) {
      if (_pendingYoutubePlay) {
        error =
            'Abre el reproductor para continuar con esta canción de YouTube.';
      }
      notifyListeners();
      return;
    }
    autoPlay = _pendingYoutubePlay;
    _pendingYoutubePlay = false;
    error = null;
    final controller = YoutubePlayerController.fromVideoId(
      videoId: current.youtubeVideoId!,
      autoPlay: autoPlay,
      startSeconds: position.inMilliseconds / 1000,
      params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          interfaceLanguage: 'es',
          playsInline: true,
          privacyEnhancedMode: true),
    );
    youtube = controller;
    _youtubeSubscriptions.add(controller.stream.listen((value) {
      if (_disposed || youtube != controller || !current.isYoutube) return;
      if (value.playerState != _lastYoutubeState) {
        _lastYoutubeState = value.playerState;
        if (value.playerState == PlayerState.playing ||
            value.playerState == PlayerState.buffering ||
            value.playerState == PlayerState.unStarted ||
            value.playerState == PlayerState.cued) {
          _youtubeIdentity.beginVerification();
        }
      }
      _youtubePlaying = value.playerState == PlayerState.playing &&
          _youtubeIdentity.confirmedId == current.youtubeVideoId;
      if (value.playerState == PlayerState.playing) {
        if (_youtubeIdentity.confirmedId != current.youtubeVideoId) {
          _syncYoutubeMetadata(controller);
        }
      }
      if (value.hasError) {
        error =
            'YouTube no puede reproducir este video aquí (código ${value.error.code}). Puedes abrirlo en YouTube o probar otra versión.';
        _youtubePlaying = false;
      }
      if (value.playerState == PlayerState.ended) {
        _youtubeIdentity.markEnded();
        _advanceYoutubeIfReady();
      }
      notifyListeners();
    }));
    _youtubeSubscriptions.add(controller.videoStateStream.listen((value) {
      if (_disposed || youtube != controller || !current.isYoutube) return;
      if (_youtubeIdentity.confirmedId != current.youtubeVideoId ||
          duration == Duration.zero) {
        _syncYoutubeMetadata(controller);
      }
      if (_youtubeIdentity.confirmedId == current.youtubeVideoId) {
        position = value.position;
      }
      notifyListeners();
    }));
  }

  void _advanceYoutubeIfReady() {
    if (_disposed ||
        !current.isYoutube ||
        _advancing ||
        loading ||
        _youtubeIdentity.confirmedId != current.youtubeVideoId ||
        !_youtubeIdentity.takeCompletion()) {
      return;
    }
    _advancing = true;
    final action = repeat ? playTrack(current, queue: _queue) : next();
    unawaited(action.whenComplete(() => _advancing = false));
  }

  Future<void> _syncYoutubeMetadata(YoutubePlayerController controller) async {
    if (_metadataPending) return;
    _metadataPending = true;
    final revision = _youtubeIdentity.revision;
    final selectedId = current.youtubeVideoId;
    try {
      // El adaptador web usa claves por milisegundo: consultas concurrentes
      // pueden colisionar. Leer ID y duración secuencialmente evita esa carrera.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (_disposed || youtube != controller) return;
      final data =
          await controller.videoData.timeout(const Duration(seconds: 3));
      if (_disposed ||
          youtube != controller ||
          revision != _youtubeIdentity.revision ||
          selectedId != current.youtubeVideoId ||
          data.videoId.isEmpty) {
        return;
      }
      if (!_youtubeIdentity.confirm(revision, selectedId!, data.videoId)) {
        _youtubePlaying = false;
        position = Duration.zero;
        duration = Duration.zero;
        error =
            'El video cambió dentro de YouTube. Selecciona una canción de la cola para continuar.';
        await controller.pauseVideo();
        notifyListeners();
        return;
      }
      if (controller.value.playerState == PlayerState.ended) {
        _advanceYoutubeIfReady();
        return;
      }
      final seconds =
          await controller.duration.timeout(const Duration(seconds: 3));
      if (_disposed ||
          youtube != controller ||
          revision != _youtubeIdentity.revision ||
          data.videoId != current.youtubeVideoId) {
        return;
      }
      if (seconds.isFinite && seconds > 0) {
        duration = Duration(milliseconds: (seconds * 1000).round());
      }
      _youtubePlaying = controller.value.playerState == PlayerState.playing;
      if (_youtubePlaying) {
        error = null;
        await library.recordListen(current.id);
      }
      _advanceYoutubeIfReady();
      notifyListeners();
    } catch (_) {
      // El video puede seguir sonando; no fabricar duración ni escuchas.
    } finally {
      _metadataPending = false;
    }
  }

  Future<void> suspendYoutube() async {
    final old = youtube;
    youtube = null;
    _youtubePlaying = false;
    _pendingYoutubePlay = false;
    _youtubeIdentity.beginVerification();
    _lastYoutubeState = PlayerState.unknown;
    for (final subscription in _youtubeSubscriptions) {
      await subscription.cancel();
    }
    _youtubeSubscriptions.clear();
    if (old != null) await old.close();
    notifyListeners();
  }

  void _recordCurrentListen() {
    if (_disposed ||
        usesYoutubePlayer ||
        !_loaded ||
        !_player.playing ||
        _player.processingState != ProcessingState.ready) {
      return;
    }
    unawaited(library.recordListen(current.id).catchError((Object _) {
      if (!_disposed) {
        error = 'La música está sonando, pero no se pudo guardar el historial.';
        notifyListeners();
      }
    }));
  }

  Future<void> playTrack(CatalogTrack track,
      {List<CatalogTrack>? queue}) async {
    if (loading) return;
    track = downloads?.track(track) ?? track;
    var desired = List<CatalogTrack>.of(
        queue ?? (track.isYoutube ? tracks : demoCatalog));
    queueNotice = null;
    if (track.hasLocalAudio && nativeAudio) {
      final offline = desired
          .where((t) => downloads!.isDownloaded(t.id) || !t.isYoutube)
          .toList();
      if (offline.length != desired.length) {
        queueNotice =
            'La cola reproduce las canciones descargadas de esta selección.';
      }
      desired = offline;
    }
    if (!desired.any((t) => t.id == track.id)) desired = [track, ...desired];
    final next = desired.indexWhere((item) => item.id == track.id);
    if (next < 0) return;
    loading = true;
    error = null;
    notifyListeners();
    Uri? preparedPreview;
    try {
      if (track.isYoutube && !nativeAudio && !track.hasLocalAudio) {
        await _player.pause();
        _queue = desired;
        index = next;
        position = Duration.zero;
        duration = Duration.zero;
        _youtubePlaying = false;
        _youtubeIdentity.beginVerification();
        if (youtube == null) {
          ensureYoutube(autoPlay: true);
        } else {
          unawaited(youtube!
              .loadVideoById(videoId: track.youtubeVideoId!)
              .catchError((Object _) => _reportError()));
        }
        return;
      }
      await suspendYoutube();
      await _player.pause();
      _loaded = false;
      _queue = desired;
      index = next;
      position = Duration.zero;
      duration = track.duration;
      _publishNative();
      if (track.hasLocalAudio) {
        await _player
            .setAudioSource(AudioSource.uri(Uri.parse(track.audioUrl)));
        _activeAudioUri = track.audioUrl;
      } else if (track.isYoutube && source != null) {
        await library.addOnlineTrack(track);
        final audio = await source!.resolve(track);
        if (_disposed) return;
        if (nativeAudio) {
          preparedPreview =
              await downloads!.native.preparePlayback(track, audio);
          if (_disposed) {
            await _releasePreview(preparedPreview);
            return;
          }
          await _player.setAudioSource(AudioSource.uri(preparedPreview));
          _activeAudioUri = preparedPreview.toString();
        } else {
          await _player.setAudioSource(
              AudioSource.uri(audio.uri, headers: audio.headers));
          _activeAudioUri = audio.uri.toString();
        }
      } else {
        await _player.setAudioSource(AudioSource.asset(track.audioUrl));
        _activeAudioUri = track.audioUrl;
      }
      final oldPreview = _previewUri;
      _previewUri = preparedPreview;
      await _releasePreview(oldPreview);
      await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
      _loaded = true;
      _publishNative();
      unawaited(_player.play().catchError((Object _) => _reportError()));
    } catch (e) {
      await _releasePreview(preparedPreview);
      _loaded = false;
      error = track.hasLocalAudio
          ? 'No se pudo abrir el archivo local. Comprueba la descarga en Biblioteca.'
          : musicSourceError(e);
      _publishNative();
    } finally {
      loading = false;
      if (!_disposed) {
        notifyListeners();
        unawaited(_switchToDownloadedAudio());
      }
    }
  }

  Future<void> togglePlay() async {
    try {
      if (usesYoutubePlayer) {
        ensureYoutube();
        if (playing) {
          await youtube!.pauseVideo();
        } else {
          error = null;
          await youtube!.playVideo();
        }
        return;
      }
      if (playing) {
        await _player.pause();
      } else if (!_loaded ||
          _player.processingState == ProcessingState.completed) {
        await playTrack(current, queue: _queue);
      } else {
        unawaited(_player.play().catchError((Object _) => _reportError()));
      }
    } catch (_) {
      _reportError();
    }
  }

  Future<void> next() async {
    if (loading) return;
    try {
      final nextIndex = shuffle && _queue.length > 1
          ? (index + 1 + DateTime.now().microsecond % (_queue.length - 1)) %
              _queue.length
          : (index + 1) % _queue.length;
      await playTrack(_queue[nextIndex], queue: _queue);
    } catch (_) {
      _reportError();
    }
  }

  Future<void> previous() async {
    if (loading) return;
    try {
      if (usesYoutubePlayer) {
        if (position.inSeconds > 3) {
          await seek(0);
        } else {
          await playTrack(_queue[(index - 1 + _queue.length) % _queue.length],
              queue: _queue);
        }
        return;
      }
      if (_loaded && position.inSeconds > 3) {
        await _player.seek(Duration.zero);
      } else {
        await playTrack(_queue[(index - 1 + _queue.length) % _queue.length],
            queue: _queue);
      }
    } catch (_) {
      _reportError();
    }
  }

  Future<void> seek(double milliseconds) async {
    try {
      if (usesYoutubePlayer) {
        await youtube?.seekTo(
            seconds: milliseconds / 1000, allowSeekAhead: true);
        position = Duration(milliseconds: milliseconds.round());
        notifyListeners();
        return;
      }
      if (_loaded) {
        await _player.seek(Duration(milliseconds: milliseconds.round()));
      }
    } catch (_) {
      _reportError();
    }
  }

  Future<void> toggleShuffle() async {
    try {
      if (usesYoutubePlayer) {
        shuffle = !shuffle;
        notifyListeners();
        return;
      }
      await _player.setShuffleModeEnabled(!shuffle);
      shuffle = !shuffle;
      notifyListeners();
    } catch (_) {
      _reportError();
    }
  }

  Future<void> toggleRepeat() async {
    try {
      if (usesYoutubePlayer) {
        repeat = !repeat;
        notifyListeners();
        return;
      }
      await _player.setLoopMode(repeat ? LoopMode.off : LoopMode.one);
      repeat = !repeat;
      notifyListeners();
    } catch (_) {
      _reportError();
    }
  }

  void _reportError() {
    if (_disposed) return;
    error =
        'No se pudo reproducir. Comprueba la conexión y pulsa reproducir otra vez.';
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    library.removeListener(notifyListeners);
    downloads?.removeListener(_downloadsChanged);
    discovery?.removeListener(notifyListeners);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    for (final subscription in _youtubeSubscriptions) {
      unawaited(subscription.cancel());
    }
    if (youtube != null) unawaited(youtube!.close());
    final preview = _previewUri;
    _previewUri = null;
    unawaited(_player.dispose().whenComplete(() => _releasePreview(preview)));
    library.dispose();
    downloads?.dispose();
    discovery?.dispose();
    downloads?.native.dispose();
    source?.close();
    super.dispose();
  }
}
