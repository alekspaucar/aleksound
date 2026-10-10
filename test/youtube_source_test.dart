import 'package:aleksound/data/youtube_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza enlaces Music, watch y cortos sin conservar seguimiento', () {
    for (final url in [
      'https://music.youtube.com/watch?v=kFXHPfI2JoI&si=tracking',
      'https://www.youtube.com/watch?v=kFXHPfI2JoI',
      'https://youtu.be/kFXHPfI2JoI?t=10',
      'https://www.youtube.com/shorts/kFXHPfI2JoI',
    ]) {
      expect(YoutubeSource.videoId(url), 'kFXHPfI2JoI');
    }
  });
  test('rechaza dominios imitadores, listas y códigos inválidos', () {
    for (final url in [
      'https://youtube.com.evil.test/watch?v=kFXHPfI2JoI',
      'https://evil.test/?v=kFXHPfI2JoI',
      'https://www.youtube.com/playlist?list=abc',
      'https://youtube.com/watch?v=short',
      'javascript:alert(1)',
    ]) {
      expect(YoutubeSource.videoId(url), isNull);
    }
  });
  test('importa metadatos reales sin afirmar que el enlace está descargado',
      () {
    final track = YoutubeSource.fromOembed('kFXHPfI2JoI', {
      'title': 'Drake - Texts Go Green (Official Audio)',
      'author_name': 'DrakeVEVO',
      'thumbnail_url': 'https://i.ytimg.com/vi/kFXHPfI2JoI/hqdefault.jpg',
    });
    expect(track.title, 'Drake - Texts Go Green (Official Audio)');
    expect(track.artist, 'DrakeVEVO');
    expect(track.id, 'youtube:kFXHPfI2JoI');
    expect(track.isDownloadable, isFalse);
    expect(track.isAvailableOffline, isFalse);
    expect(track.duration, Duration.zero);
  });
  test('no fabrica canciones ante metadatos incompletos', () {
    expect(() => YoutubeSource.fromOembed('kFXHPfI2JoI', {}),
        throwsFormatException);
  });
}
