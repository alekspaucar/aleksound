import 'dart:convert';

/// Keep the public player request consistent with its anonymous watch session.
String normalizePlayerRequest(String body, String? visitor) {
  final payload = jsonDecode(body) as Map<String, dynamic>;
  final playback = payload['playbackContext']?['contentPlaybackContext'];
  if (playback is Map && playback['signatureTimestamp'] is String) {
    final timestamp = int.tryParse(playback['signatureTimestamp'] as String);
    if (timestamp != null) playback['signatureTimestamp'] = timestamp;
  }
  final client = payload['context']?['client'];
  if (client is Map && visitor != null && visitor.isNotEmpty) {
    client['visitorData'] = visitor;
  }
  return jsonEncode(payload);
}
