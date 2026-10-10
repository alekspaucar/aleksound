import 'dart:async';
import 'package:flutter/foundation.dart';
import '../catalog_track.dart';
import '../data/youtube_audio_source.dart';
import 'native_music.dart';

class DownloadStore extends ChangeNotifier {
  DownloadStore(this.native, this.source) {
    _subscription =
        native.events.where((e) => e['kind'] == 'downloads').listen((_) {
      unawaited(refresh().catchError((Object e) {
        error = 'No se pudo actualizar la biblioteca local.';
        _notify();
      }));
    });
  }
  final NativeMusic native;
  final MusicSource source;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  final _records = <String, Map<String, dynamic>>{};
  final _jobs = <String, Map<String, dynamic>>{};
  final _revisions = <String, int>{};
  bool _disposed = false;
  int _refreshRevision = 0;
  String? error;
  bool get supported => native.supported;
  int get bytes => _records.values
      .fold(0, (sum, r) => sum + ((r['bytes'] as num?)?.toInt() ?? 0));
  bool isDownloaded(String id) => _records.containsKey(id);
  Map<String, dynamic>? job(String id) => _jobs[id];
  List<Map<String, dynamic>> get jobs => List.unmodifiable(_jobs.values);
  bool busy(String id) =>
      ['resolving', 'downloading', 'verifying'].contains(_jobs[id]?['status']);
  List<CatalogTrack> get tracks => _records.values
      .map((r) => track(CatalogTrack(
            id: r['id'] as String,
            title: r['title'] as String? ?? 'Canción',
            artist: r['artist'] as String? ?? '',
            artworkUrl: '',
            audioUrl: '',
            youtubeVideoId: r['videoId'] as String?,
            isDownloadable: true,
          )))
      .toList();
  CatalogTrack track(CatalogTrack original) {
    final r = _records[original.id];
    if (r == null) {
      return original.copyWith(
          isDownloaded: false,
          audioUrl: original.hasLocalAudio ? '' : original.audioUrl,
          artworkUrl: original.artworkUrl.startsWith('file:')
              ? ''
              : original.artworkUrl);
    }
    return original.copyWith(
        isDownloaded: true,
        isDownloadable: true,
        audioUrl: r['audioUri'] as String,
        artworkUrl: r['artworkUri'] as String? ?? '',
        duration: Duration(
            milliseconds: (((r['duration'] as num?) ?? 0) * 1000).round()));
  }

  Future<void> initialize() => refresh();
  Future<void> refresh() async {
    final revision = ++_refreshRevision;
    final data = await native.library();
    if (_disposed || revision != _refreshRevision) return;
    _records.clear();
    for (final raw in (data['records'] as List?) ?? []) {
      final r = Map<String, dynamic>.from(raw as Map);
      if (r['id'] is String &&
          r['audioUri'] is String &&
          (r['audioUri'] as String).startsWith('file:') &&
          (r['bytes'] as num? ?? 0) > 1024) {
        _records[r['id'] as String] = r;
      }
    }
    _jobs.removeWhere(
        (id, j) => _records.containsKey(id) || j['origin'] != 'resolution');
    for (final raw in (data['jobs'] as List?) ?? []) {
      final j = Map<String, dynamic>.from(raw as Map);
      if (j['id'] is String) _jobs[j['id'] as String] = j;
    }
    _notify();
  }

  Future<void> download(CatalogTrack track) async {
    if (!supported || busy(track.id) || isDownloaded(track.id)) return;
    final revision = (_revisions[track.id] ?? 0) + 1;
    _revisions[track.id] = revision;
    _jobs[track.id] = {
      'id': track.id,
      'title': track.title,
      'status': 'resolving',
      'origin': 'resolution',
      'progress': 0.0
    };
    error = null;
    _notify();
    try {
      final audio = await source.resolve(track);
      if (_disposed || _revisions[track.id] != revision) return;
      await native.download(track, audio);
      if (_disposed || _revisions[track.id] != revision) {
        await native.cancel(track.id);
        return;
      }
      _jobs[track.id] = {
        'id': track.id,
        'title': track.title,
        'status': 'downloading',
        'progress': 0.0
      };
      await refresh();
    } catch (e) {
      if (_disposed || _revisions[track.id] != revision) return;
      _jobs[track.id] = {
        'id': track.id,
        'title': track.title,
        'status': 'failed',
        'origin': 'resolution',
        'error': musicSourceError(e)
      };
      error = musicSourceError(e);
      _notify();
    }
  }

  Future<void> cancel(String id) async {
    _refreshRevision++;
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    await native.cancel(id);
    _jobs.remove(id);
    _notify();
  }

  Future<void> delete(String id) async {
    await cancel(id);
    await native.delete(id);
    await refresh();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
