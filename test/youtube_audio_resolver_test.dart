import 'dart:convert';
import 'package:aleksound/data/online_catalog.dart';
import 'package:aleksound/data/youtube_audio_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('resuelve AAC público con el cliente vigente y conserva su identidad',
      () async {
    final song = onlineCatalog[3];
    Map<String, dynamic>? payload;
    String? requestAgent;
    final transport = MockClient((request) async {
      if (request.url.path == '/watch') {
        expect(request.url.queryParameters['v'], song.youtubeVideoId);
        return http.Response(
            '''
<html><head><meta property="og:url" content="https://www.youtube.com/watch?v=${song.youtubeVideoId}"></head>
<body><div id="player"></div><script>ytcfg.set({"STS":123,"INNERTUBE_CONTEXT":{"client":{"visitorData":"guest"}}});</script></body></html>
''',
            200,
            headers: {'set-cookie': 'VISITOR_INFO1_LIVE=guest; Path=/;'});
      }
      if (request.url.path == '/sw.js_data') {
        final visitor = List<Object?>.filled(14, null)..[13] = 'guest';
        return http.Response(
            jsonEncode([
              [
                null,
                null,
                [
                  [visitor]
                ]
              ]
            ]),
            200);
      }
      expect(request.method, 'POST');
      expect(request.url.path, '/youtubei/v1/player');
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      requestAgent = request.headers['user-agent'];
      // Fixture for the public finite-AAC route checked on 2026-10-09.
      // The old IOS route is not accepted by this provider response.
      if (payload!['context']['client']['clientName'] != 'VISIONOS') {
        return http.Response(
            jsonEncode({
              'playabilityStatus': {'status': 'ERROR'},
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'playabilityStatus': {'status': 'OK'},
            'videoDetails': {'videoId': song.youtubeVideoId},
            'streamingData': {
              'adaptiveFormats': [
                {
                  'itag': 140,
                  'bitrate': 128000,
                  'contentLength': '5000',
                  'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
                  'url': 'https://a.googlevideo.com/videoplayback?c=VISIONOS',
                }
              ]
            },
          }),
          200);
    });
    final source = YoutubeAudioSource(httpClientFactory: () => transport);
    addTearDown(source.close);

    final result = await source.resolve(song);

    expect(payload!['videoId'], song.youtubeVideoId);
    expect(payload!['context']['client']['visitorData'], 'guest');
    expect(
        payload!['playbackContext']['contentPlaybackContext']
            ['signatureTimestamp'],
        123);
    expect(result.bytes, 5000);
    expect(result.uri.queryParameters['range'], '0-4999');
    expect(result.uri.queryParameters['c'], 'VISIONOS');
    expect(result.headers['User-Agent'], requestAgent);
    expect(result.headers['User-Agent'],
        payload!['context']['client']['userAgent']);
    expect(result.headers.keys, unorderedEquals(['User-Agent', 'Accept']));
  });
}
