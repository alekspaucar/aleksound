import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:aleksound/offline/native_music.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('aleksound/native_music');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final audio = ResolvedAudio(Uri.https('r.googlevideo.com', '/videoplayback'),
      bytes: 5000, headers: const {'User-Agent': 'same-client'});
  late IosMusic native;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    native = IosMusic();
  });
  tearDown(() {
    native.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
  test('prepara caché sin solicitar una descarga persistente', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return {'audioUri': 'file:///cache/preview.m4a', 'duration': 213.0};
    });
    final uri = await native.preparePlayback(onlineCatalog[3], audio);
    expect(uri.toString(), 'file:///cache/preview.m4a');
    expect(calls.map((call) => call.method), ['preparePlayback']);
    final data = calls.single.arguments as Map;
    expect(data['id'], onlineCatalog[3].id);
    expect(data['bytes'], 5000);
    expect(data['headers'], audio.headers);
  });
  test('rechaza una respuesta remota en lugar del archivo preparado', () async {
    messenger.setMockMethodCallHandler(channel,
        (_) async => {'audioUri': 'https://example.com/unprepared.m4a'});
    await expectLater(
        native.preparePlayback(onlineCatalog[3], audio), throwsFormatException);
  });
  test('libera archivos temporales, nunca solicita borrar la canción',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    await native.releasePlayback(Uri.parse('file:///cache/preview.m4a'));
    await native.releasePlayback(Uri.https('example.com', '/audio'));
    expect(calls.map((call) => call.method), ['releasePlayback']);
  });
  test('conserva el motivo nativo para un reintento comprensible', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
          code: 'audio_preview', message: 'Audio incompleto');
    });
    await expectLater(
        native.preparePlayback(onlineCatalog[3], audio),
        throwsA(isA<FormatException>()
            .having((error) => error.message, 'motivo', 'Audio incompleto')));
  });
}
