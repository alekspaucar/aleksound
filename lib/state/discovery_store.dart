import 'package:flutter/foundation.dart';
import '../catalog_track.dart';
import '../data/youtube_audio_source.dart';

class DiscoveryStore extends ChangeNotifier {
  DiscoveryStore(this.source);
  final MusicSource source;
  String query = '';
  List<CatalogTrack> results = [];
  String? error;
  bool loading = false, loadingMore = false, _disposed = false;
  Object? _continuation;
  int _revision = 0;
  bool get hasMore => _continuation != null;
  Future<void> search(String value) async {
    final revision = ++_revision;
    query = value.trim();
    results = [];
    error = null;
    _continuation = null;
    loadingMore = false;
    loading = query.isNotEmpty;
    notifyListeners();
    if (!loading) return;
    try {
      final page = await source.search(query);
      if (_disposed || revision != _revision) return;
      results = page.tracks;
      _continuation = page.continuation;
    } catch (e) {
      if (_disposed || revision != _revision) return;
      error = musicSourceError(e);
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> more() async {
    if (loading || loadingMore || _continuation == null) return;
    final revision = _revision;
    loadingMore = true;
    error = null;
    notifyListeners();
    try {
      final page = await source.nextPage(_continuation!);
      if (_disposed || revision != _revision) return;
      results = {
        for (final t in [...results, ...page.tracks]) t.id: t
      }.values.toList();
      _continuation = page.continuation;
      if (page.tracks.isEmpty) _continuation = null;
    } catch (e) {
      if (!_disposed && revision == _revision) error = musicSourceError(e);
    } finally {
      if (!_disposed && revision == _revision) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
