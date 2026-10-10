// ignore_for_file: implementation_imports, avoid_print
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/pages/watch_page.dart';
import 'package:youtube_explode_dart/src/videos/video_controller.dart';
import 'package:http/http.dart' as http;
import 'package:aleksound/data/audio_selection.dart';
import 'package:aleksound/data/player_request.dart';
import 'package:aleksound/data/youtube_client.dart';

// Diagnostic only. A Mac result does not certify the autonomous iPhone flow.
class NormalizedClient extends http.BaseClient {
  final http.Client client = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.Request && request.method == 'POST') {
      request.body = normalizePlayerRequest(
          request.body, request.headers['X-Goog-Visitor-Id']);
    }
    return client.send(request).timeout(const Duration(seconds: 20));
  }

  @override
  void close() {
    client.close();
    super.close();
  }
}

Future<void> main(List<String> args) async {
  final client = YoutubeHttpClient(NormalizedClient());
  final api = args.length > 1 && args[1] == 'visionos'
      ? publicAudioClient
      : YoutubeApiClient.ios;
  try {
    final page = await WatchPage.get(client, args.first)
        .timeout(const Duration(seconds: 20));
    final p = await VideoController(client)
        .getPlayerResponse(VideoId(args.first), api, watchPage: page)
        .timeout(const Duration(seconds: 20));
    final audio = publicAacAudio(p, args.first);
    for (final s in audio.take(1)) {
      final url = Uri.parse(s.url);
      try {
        final request = http.Request(
            'GET',
            url.replace(queryParameters: {
              ...url.queryParameters,
              'range': '0-${s.contentLength! - 1}'
            }));
        request.headers.addAll({
          'User-Agent': api.payload['context']['client']['userAgent'] as String,
          'Accept': '*/*',
        });
        final r =
            await client.send(request).timeout(const Duration(seconds: 20));
        var bytes = 0;
        if (r.statusCode >= 200 && r.statusCode < 300) {
          await for (final chunk
              in r.stream.timeout(const Duration(seconds: 20))) {
            bytes += chunk.length;
            if (bytes > s.contentLength!) {
              throw const FormatException('oversized');
            }
          }
        }
        print(
            'itag=${s.tag}, client=${url.queryParameters['c']}, status=${r.statusCode}, bytes=$bytes/${s.contentLength}, n=${url.queryParameters.containsKey('n')}');
      } catch (e) {
        print('itag=${s.tag}, failure=${e.runtimeType}');
      }
    }
  } catch (e) {
    print('provider failure=${e.runtimeType}');
  } finally {
    client.close();
  }
}
