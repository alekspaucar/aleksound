// Adapter pinned to youtube_explode_dart 3.1.0.
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/player/player_response.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/models/stream_info_provider.dart';

List<StreamInfoProvider> publicAacAudio(
    PlayerResponse response, String videoId) {
  final streaming = response.root['streamingData'];
  if (!response.isVideoPlayable ||
      response.previewVideoId?.isNotEmpty == true ||
      response.isLive ||
      response.root['videoDetails']?['videoId'] != videoId ||
      streaming is! Map ||
      streaming['drmFamilies'] != null ||
      response.root['licenseInfos'] != null) {
    throw const FormatException(
        'YouTube no ofrece audio público para esta versión.');
  }
  final audio = response.streams.where((s) {
    final url = Uri.tryParse(s.url);
    return s.audioCodec != null &&
        s.videoCodec == null &&
        s.container == 'mp4' &&
        (s.contentLength ?? 0) > 1024 &&
        (s.contentLength ?? 0) <= 300 * 1024 * 1024 &&
        url != null &&
        url.scheme == 'https' &&
        url.host.endsWith('.googlevideo.com');
  }).toList()
    ..sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));
  if (audio.isEmpty) {
    throw const FormatException(
        'Esta versión no ofrece un archivo de audio compatible. Prueba otra versión.');
  }
  return audio;
}
