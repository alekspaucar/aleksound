import 'dart:convert';
import 'package:aleksound/data/player_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el contexto transmite timestamp numérico y la misma sesión anónima',
      () {
    final result = jsonDecode(normalizePlayerRequest(
        jsonEncode({
          'videoId': 'zyXmsVwZqX4',
          'context': {
            'client': {'clientName': 'TVHTML5'}
          },
          'playbackContext': {
            'contentPlaybackContext': {'signatureTimestamp': '20732'}
          }
        }),
        'anonymous-session'));
    expect(
        result['playbackContext']['contentPlaybackContext']
            ['signatureTimestamp'],
        20732);
    expect(result['context']['client']['visitorData'], 'anonymous-session');
    expect(result['videoId'], 'zyXmsVwZqX4');
  });
}
