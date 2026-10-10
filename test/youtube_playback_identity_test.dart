import 'package:aleksound/state/youtube_playback_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'terminar durante la verificación permite avanzar una sola vez al confirmar',
      () {
    final identity = YoutubePlaybackIdentity();
    final revision = identity.beginVerification();
    identity.markEnded();
    expect(identity.takeCompletion(), isFalse);
    identity.confirm(revision, 'selected', 'selected');
    expect(identity.takeCompletion(), isTrue);
    expect(identity.takeCompletion(), isFalse);
  });
  test('un final pendiente no avanza tras seleccionar otra canción', () {
    final identity = YoutubePlaybackIdentity();
    identity.beginVerification();
    identity.markEnded();
    final revision = identity.beginVerification();
    identity.confirm(revision, 'second', 'second');
    expect(identity.takeCompletion(), isFalse);
  });
  test('otra transición invalida la identidad previamente confirmada', () {
    final identity = YoutubePlaybackIdentity();
    final revision = identity.beginVerification();
    expect(identity.confirm(revision, 'selected', 'selected'), isTrue);
    identity.beginVerification();
    expect(identity.confirmedId, isNull);
  });
  test('una consulta antigua no confirma después de cambiar de canción', () {
    final identity = YoutubePlaybackIdentity();
    final oldRevision = identity.beginVerification();
    final newRevision = identity.beginVerification();
    expect(identity.confirm(oldRevision, 'first', 'first'), isFalse);
    expect(identity.confirmedId, isNull);
    expect(identity.confirm(newRevision, 'second', 'second'), isTrue);
    expect(identity.confirmedId, 'second');
  });
  test('un video relacionado no confirma la canción seleccionada', () {
    final identity = YoutubePlaybackIdentity();
    final revision = identity.beginVerification();
    expect(identity.confirm(revision, 'selected', 'related'), isFalse);
    expect(identity.confirmedId, isNull);
  });
}
