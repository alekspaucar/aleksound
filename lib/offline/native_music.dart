import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../catalog_track.dart';
import '../data/youtube_audio_source.dart';

abstract interface class NativeMusic {
  bool get supported;
  Stream<Map<String, dynamic>> get events;
  Future<Map<String, dynamic>> library();
  Future<void> download(CatalogTrack track, ResolvedAudio audio);
  Future<Uri> preparePlayback(CatalogTrack track, ResolvedAudio audio);
  Future<void> releasePlayback(Uri uri);
  Future<void> cancel(String id);
  Future<void> delete(String id);
  Future<void> nowPlaying(Map<String, dynamic> data);
  void dispose();
}

class IosMusic implements NativeMusic {
  IosMusic() {
    if (supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'event' && call.arguments is Map) {
          _events.add(Map<String, dynamic>.from(call.arguments as Map));
        }
      });
    }
  }
  static const _channel = MethodChannel('aleksound/native_music');
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  @override
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  @override
  Stream<Map<String, dynamic>> get events => _events.stream;
  @override
  Future<Map<String, dynamic>> library() async => supported
      ? Map<String, dynamic>.from(
          (await _channel.invokeMapMethod<String, dynamic>('library')) ?? {})
      : {'records': [], 'jobs': []};
  @override
  Future<void> download(CatalogTrack t, ResolvedAudio audio) async {
    if (!supported) {
      throw StateError(
          'Las descargas están disponibles en la app para iPhone.');
    }
    await _channel.invokeMethod<void>('download', {
      'id': t.id,
      'title': t.title,
      'artist': t.artist,
      'videoId': t.youtubeVideoId,
      'artworkUrl': t.artworkUrl,
      'url': audio.uri.toString(),
      'bytes': audio.bytes,
      'headers': audio.headers,
    });
  }

  @override
  Future<Uri> preparePlayback(CatalogTrack t, ResolvedAudio audio) async {
    Map<String, dynamic>? result;
    try {
      result =
          await _channel.invokeMapMethod<String, dynamic>('preparePlayback', {
        'id': t.id,
        'videoId': t.youtubeVideoId,
        'url': audio.uri.toString(),
        'bytes': audio.bytes,
        'headers': audio.headers,
      });
    } on PlatformException catch (e) {
      throw FormatException(e.message ?? 'No se pudo preparar el audio.');
    }
    final uri = Uri.tryParse(result?['audioUri'] as String? ?? '');
    if (uri == null || uri.scheme != 'file') {
      throw const FormatException('No se pudo preparar el audio para iPhone.');
    }
    return uri;
  }

  @override
  Future<void> releasePlayback(Uri uri) async {
    if (supported && uri.scheme == 'file') {
      await _channel.invokeMethod<void>('releasePlayback', uri.toString());
    }
  }

  @override
  Future<void> cancel(String id) => _channel.invokeMethod<void>('cancel', id);
  @override
  Future<void> delete(String id) => _channel.invokeMethod<void>('delete', id);
  @override
  Future<void> nowPlaying(Map<String, dynamic> data) async {
    if (supported) await _channel.invokeMethod<void>('nowPlaying', data);
  }

  @override
  void dispose() {
    if (supported) _channel.setMethodCallHandler(null);
    unawaited(_events.close());
  }
}
