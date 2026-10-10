import 'dart:convert';
import 'package:aleksound/data/audio_selection.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/player/player_response.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object> format(int bitrate,
        {String? url, String mime = 'audio/mp4; codecs="mp4a.40.2"'}) =>
    {
      'itag': bitrate,
      'bitrate': bitrate,
      'contentLength': '5000',
      'mimeType': mime,
      if (url != null) 'url': url,
    };
PlayerResponse player(List<Map<String, Object>> formats,
        {String id = 'zyXmsVwZqX4', bool drm = false}) =>
    PlayerResponse.parse(jsonEncode({
      'playabilityStatus': {'status': 'OK'},
      'videoDetails': {'videoId': id},
      'streamingData': {
        'adaptiveFormats': formats,
        if (drm) 'drmFamilies': ['WIDEVINE']
      },
    }));

void main() {
  test('escoge AAC de mayor calidad y omite formato SABR sin URL', () {
    final result = publicAacAudio(
        player([
          format(100),
          format(50, url: 'https://a.googlevideo.com/audio'),
          format(120, url: 'https://b.googlevideo.com/audio'),
          format(200,
              url: 'https://c.googlevideo.com/audio',
              mime: 'audio/webm; codecs="opus"'),
        ]),
        'zyXmsVwZqX4');
    expect(result.first.bitrate, 120);
    expect(result.length, 2);
  });
  test('rechaza otro video, contenido protegido y dominio falso', () {
    final good = format(120, url: 'https://a.googlevideo.com/audio');
    expect(
        () => publicAacAudio(player([good], id: 'kFXHPfI2JoI'), 'zyXmsVwZqX4'),
        throwsFormatException);
    expect(() => publicAacAudio(player([good], drm: true), 'zyXmsVwZqX4'),
        throwsFormatException);
    expect(
        () => publicAacAudio(
            player([
              format(120, url: 'https://googlevideo.com.attacker.test/audio')
            ]),
            'zyXmsVwZqX4'),
        throwsFormatException);
  });
}
