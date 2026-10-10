import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Public finite-AAC route, checked 2026-10-09 against yt-dlp's client table:
// https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py
// Provider compatibility only: does not change the app's iOS target and does
// not authorize protected, private, paid or DRM content.
const publicAudioClient = YoutubeApiClient(
    {
      'context': {
        'client': {
          'clientName': 'VISIONOS',
          'clientVersion': '1.02',
          'deviceMake': 'Apple',
          'deviceModel': 'RealityDevice17,1',
          'userAgent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
          'osName': 'visionOS',
          'osVersion': '26.5.23O471',
          'hl': 'en',
        }
      }
    },
    'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
    headers: {'X-Youtube-Client-Name': '101'});
