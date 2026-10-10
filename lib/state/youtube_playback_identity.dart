/// Confirma la identidad activa independientemente de los metadatos cacheados.
class YoutubePlaybackIdentity {
  String? confirmedId;
  int _revision = 0;
  bool _endedPending = false;
  void markEnded() => _endedPending = true;
  bool takeCompletion() {
    if (!_endedPending || confirmedId == null) return false;
    _endedPending = false;
    return true;
  }

  int get revision => _revision;
  int beginVerification() {
    confirmedId = null;
    _endedPending = false;
    return ++_revision;
  }

  bool confirm(int revision, String expectedId, String actualId) {
    if (revision != _revision) return false;
    confirmedId = actualId == expectedId ? actualId : null;
    return confirmedId != null;
  }
}
