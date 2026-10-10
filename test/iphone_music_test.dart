import 'dart:async';
import 'package:aleksound/catalog_track.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/state/discovery_store.dart';
import 'package:aleksound/offline/download_store.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:flutter_test/flutter_test.dart';

const song = CatalogTrack(
    id: 'youtube:zyXmsVwZqX4',
    title: 'Song',
    artist: 'Artist',
    artworkUrl: '',
    audioUrl: '',
    youtubeVideoId: 'zyXmsVwZqX4',
    isDownloadable: false);

class Source implements MusicSource {
  final searches = <String, Completer<SearchBatch>>{};
  final pages = <Object, Completer<SearchBatch>>{};
  final resolution = Completer<ResolvedAudio>();
  @override
  Future<SearchBatch> search(String query) =>
      (searches[query] = Completer()).future;
  @override
  Future<SearchBatch> nextPage(Object continuation) =>
      (pages[continuation] = Completer()).future;
  @override
  Future<ResolvedAudio> resolve(CatalogTrack track) => resolution.future;
  @override
  void close() {}
}

class Native implements NativeMusic {
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  int starts = 0;
  Completer<Map<String, dynamic>>? pendingLibrary;
  Map<String, dynamic> snapshot = {'records': [], 'jobs': []};
  @override
  bool get supported => true;
  @override
  Stream<Map<String, dynamic>> get events => controller.stream;
  @override
  Future<Map<String, dynamic>> library() async =>
      pendingLibrary == null ? snapshot : await pendingLibrary!.future;
  @override
  Future<void> download(CatalogTrack track, ResolvedAudio audio) async {
    starts++;
  }

  @override
  Future<Uri> preparePlayback(CatalogTrack track, ResolvedAudio audio) async =>
      Uri.parse('file:///cache/preview.m4a');
  @override
  Future<void> releasePlayback(Uri uri) async {}

  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> nowPlaying(Map<String, dynamic> data) async {}
  @override
  void dispose() {
    controller.close();
  }
}

void main() {
  test('una respuesta antigua no reemplaza la búsqueda nueva', () async {
    final source = Source();
    final discovery = DiscoveryStore(source);
    final old = discovery.search('old');
    final latest = discovery.search('new');
    source.searches['new']!.complete(const SearchBatch([song]));
    await latest;
    source.searches['old']!.complete(const SearchBatch([]));
    await old;
    expect(discovery.results.single.id, song.id);
    expect(discovery.query, 'new');
    discovery.dispose();
  });
  test('paginación conserva orden y elimina canciones repetidas', () async {
    final source = Source();
    final discovery = DiscoveryStore(source);
    final first = discovery.search('phonk');
    source.searches['phonk']!
        .complete(const SearchBatch([song], continuation: 'page2'));
    await first;
    final next = discovery.more();
    source.pages['page2']!.complete(const SearchBatch([
      song,
      CatalogTrack(
          id: 'youtube:kFXHPfI2JoI',
          title: 'Another song',
          artist: 'Artist',
          artworkUrl: '',
          audioUrl: '',
          youtubeVideoId: 'kFXHPfI2JoI',
          isDownloadable: false),
    ], continuation: 'page3'));
    await next;
    expect(discovery.results.map((track) => track.id),
        [song.id, 'youtube:kFXHPfI2JoI']);
    expect(discovery.hasMore, true);
    expect(discovery.loadingMore, false);
    discovery.dispose();
  });
  test('una página vacía termina paginación aunque haya continuación',
      () async {
    final source = Source();
    final discovery = DiscoveryStore(source);
    final first = discovery.search('remix');
    source.searches['remix']!
        .complete(const SearchBatch([song], continuation: 'page2'));
    await first;
    final next = discovery.more();
    source.pages['page2']!
        .complete(const SearchBatch([], continuation: 'page3'));
    await next;
    expect(discovery.results.single.id, song.id);
    expect(discovery.hasMore, false);
    discovery.dispose();
  });
  test('una página tardía no se mezcla con una consulta diferente', () async {
    final source = Source();
    final discovery = DiscoveryStore(source);
    final first = discovery.search('old');
    source.searches['old']!
        .complete(const SearchBatch([song], continuation: 'oldPage'));
    await first;
    final oldPage = discovery.more();
    final latest = discovery.search('new');
    source.searches['new']!.complete(const SearchBatch([]));
    await latest;
    source.pages['oldPage']!
        .complete(const SearchBatch([song], continuation: 'nextOldPage'));
    await oldPage;
    expect(discovery.query, 'new');
    expect(discovery.results, isEmpty);
    expect(discovery.hasMore, false);
    expect(discovery.loadingMore, false);
    discovery.dispose();
  });
  test('cancelar mientras se obtiene el audio impide iniciar descarga',
      () async {
    final source = Source(), native = Native();
    final downloads = DownloadStore(native, source);
    await downloads.initialize();
    final pending = downloads.download(song);
    await downloads.cancel(song.id);
    source.resolution.complete(
        ResolvedAudio(Uri.https('audio.example', '/a.m4a'), bytes: 5000));
    await pending;
    expect(native.starts, 0);
    expect(downloads.isDownloaded(song.id), false);
    downloads.dispose();
  });
  test('archivo nativo verificado se reproduce local conservando ID YouTube',
      () async {
    final native = Native();
    native.snapshot['records'] = [
      {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'videoId': song.youtubeVideoId,
        'audioUri': 'file:///sandbox/song.m4a',
        'artworkUri': 'file:///sandbox/song.jpg',
        'bytes': 5000,
        'duration': 120.0,
      }
    ];
    final downloads = DownloadStore(native, Source());
    await downloads.initialize();
    final local = downloads.track(song);
    expect(local.id, song.id);
    expect(local.isYoutube, true);
    expect(local.isAvailableOffline, true);
    expect(local.audioUrl, 'file:///sandbox/song.m4a');
    expect(local.artworkUrl, 'file:///sandbox/song.jpg');
    native.snapshot['records'] = [];
    await downloads.refresh();
    expect(downloads.track(song).isAvailableOffline, false);
    downloads.dispose();
  });
  test('un fallo de resolución conserva reintentar tras refrescar biblioteca',
      () async {
    final source = Source(), native = Native();
    final downloads = DownloadStore(native, source);
    await downloads.initialize();
    final pending = downloads.download(song);
    source.resolution
        .completeError(const FormatException('Audio no disponible'));
    await pending;
    await downloads.refresh();
    expect(downloads.job(song.id)?['status'], 'failed');
    downloads.dispose();
  });
  test('refresco anterior a cancelar no resucita la descarga', () async {
    final native = Native();
    final store = DownloadStore(native, Source());
    await store.initialize();
    native.pendingLibrary = Completer();
    final pending = store.refresh();
    await store.cancel(song.id);
    native.pendingLibrary!.complete({
      'records': [],
      'jobs': [
        {'id': song.id, 'status': 'downloading'}
      ]
    });
    await pending;
    expect(store.busy(song.id), false);
    store.dispose();
  });
}
