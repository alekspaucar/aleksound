import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:http/http.dart' as http;
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/js_challenge.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/pages/watch_page.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/videos/video_controller.dart';
import '../catalog_track.dart';
import 'player_request.dart';
import 'audio_selection.dart';
import 'youtube_client.dart';

class SearchBatch {
  const SearchBatch(this.tracks, {this.continuation});
  final List<CatalogTrack> tracks;
  final Object? continuation;
}

class ResolvedAudio {
  const ResolvedAudio(this.uri, {required this.bytes, this.headers = const {}});
  final Uri uri;
  final int bytes;
  final Map<String, String> headers;
}

abstract interface class MusicSource {
  Future<SearchBatch> search(String query);
  Future<SearchBatch> nextPage(Object continuation);
  Future<ResolvedAudio> resolve(CatalogTrack track);
  void close();
}

class YoutubeAudioSource implements MusicSource {
  YoutubeAudioSource({this.playerScript, this.httpClientFactory});
  final BaseJSChallengeSolver? playerScript;
  final http.Client Function()? httpClientFactory;
  final yt.YoutubeExplode _youtube = yt.YoutubeExplode();
  SearchBatch _batch(yt.VideoSearchList? page) => SearchBatch(
      page
              ?.where((v) => !v.isLive)
              .map((v) => CatalogTrack(
                    id: 'youtube:${v.id.value}',
                    title: v.title,
                    artist: v.author,
                    artworkUrl: v.thumbnails.highResUrl,
                    audioUrl: '',
                    youtubeVideoId: v.id.value,
                    duration: v.duration ?? Duration.zero,
                    genre: 'YouTube',
                    mood: 'Todo',
                    isDownloadable: false,
                  ))
              .toList() ??
          [],
      continuation: page);
  @override
  Future<SearchBatch> search(String query) async {
    return _batch(await _youtube.search
        .search(query.trim())
        .timeout(const Duration(seconds: 25)));
  }

  @override
  Future<SearchBatch> nextPage(Object continuation) async {
    return _batch(await (continuation as yt.VideoSearchList)
        .nextPage()
        .timeout(const Duration(seconds: 25)));
  }

  @override
  Future<ResolvedAudio> resolve(CatalogTrack track) async {
    if (track.youtubeVideoId == null) {
      throw const FormatException('Esta canción no tiene una fuente de audio.');
    }
    final client =
        yt.YoutubeHttpClient(_TimedClient(httpClientFactory?.call()));
    try {
      final page = await WatchPage.get(client, track.youtubeVideoId!)
          .timeout(const Duration(seconds: 25));
      final response = await VideoController(client)
          .getPlayerResponse(
              yt.VideoId(track.youtubeVideoId!), publicAudioClient,
              watchPage: page)
          .timeout(const Duration(seconds: 25));
      // getManifest performs a HEAD on the first format. Some finite public
      // formats reject HEAD but accept GET; others (SABR) have no URL at all.
      // Select real AAC URLs without HEAD. The native transfer validates the
      // actual GET status, exact byte count and decoded audio before committing.
      final streams = publicAacAudio(response, track.youtubeVideoId!);
      final audio = streams.first;
      var url = Uri.parse(audio.url);
      if (url.scheme != 'https' || !url.host.endsWith('.googlevideo.com')) {
        throw const FormatException('La fuente de audio no es válida.');
      }
      final requests = <JSChallengeType, List<String>>{
        if (url.queryParameters['n'] != null)
          JSChallengeType.n: [url.queryParameters['n']!],
        if (audio.signatureParameter != null && audio.signature != null)
          JSChallengeType.sig: [audio.signature!],
      };
      if (requests.isNotEmpty) {
        if (playerScript == null || page.sourceUrl == null) {
          throw const FormatException(
              'No se pudo preparar el audio de esta versión.');
        }
        final solved = await playerScript!
            .solveBulk(page.sourceUrl!, requests)
            .timeout(const Duration(seconds: 30));
        final parameters = Map<String, String>.of(url.queryParameters);
        for (final item in requests.entries) {
          final value = solved[item.value.single];
          if (value == null || value.isEmpty) {
            throw const FormatException(
                'No se pudo preparar el audio de esta versión.');
          }
          parameters[item.key == JSChallengeType.n
              ? 'n'
              : audio.signatureParameter!] = value;
        }
        url = url.replace(queryParameters: parameters);
      }
      final size = audio.contentLength!;
      return ResolvedAudio(
          url.replace(queryParameters: {
            ...url.queryParameters,
            'range': '0-${size - 1}',
          }),
          bytes: size,
          headers: {
            'User-Agent': publicAudioClient.payload['context']['client']
                ['userAgent'] as String,
            'Accept': '*/*',
          });
    } finally {
      client.close();
    }
  }

  @override
  void close() => _youtube.close();
}

class _TimedClient extends http.BaseClient {
  _TimedClient([http.Client? client]) : client = client ?? http.Client();
  final http.Client client;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request &&
        request.method == 'POST' &&
        request.url.host == 'www.youtube.com' &&
        request.url.path == '/youtubei/v1/player') {
      request.body = normalizePlayerRequest(
          request.body, request.headers['X-Goog-Visitor-Id']);
    }
    final response =
        await client.send(request).timeout(const Duration(seconds: 12));
    return http.StreamedResponse(
        response.stream.timeout(const Duration(seconds: 12)),
        response.statusCode,
        headers: response.headers,
        request: request,
        contentLength: response.contentLength,
        isRedirect: response.isRedirect,
        reasonPhrase: response.reasonPhrase);
  }

  @override
  void close() {
    client.close();
    super.close();
  }
}

String musicSourceError(Object error) {
  if (error is FormatException) return error.message.toString();
  return 'No se pudo obtener esta canción. Comprueba tu conexión y reintenta; YouTube puede limitar la disponibilidad de esta versión.';
}
