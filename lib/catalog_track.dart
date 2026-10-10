class CatalogTrack {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String audioUrl;
  final bool isDownloadable;
  final bool isDownloaded;
  final String genre;
  final String mood;
  final Duration duration;
  final int artwork;
  final int color;
  final String? youtubeVideoId;

  const CatalogTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.audioUrl,
    required this.isDownloadable,
    this.isDownloaded = false,
    this.genre = 'Ambient',
    this.mood = 'Noche',
    this.duration = const Duration(seconds: 24),
    this.artwork = 0,
    this.color = 0xFFAE94E8,
    this.youtubeVideoId,
  });

  bool get isYoutube => youtubeVideoId != null;
  bool get hasLocalAudio => audioUrl.startsWith('file:');
  bool get isAvailableOffline =>
      isDownloaded && (hasLocalAudio || (!isYoutube && isDownloadable));

  CatalogTrack copyWith(
          {bool? isDownloaded,
          String? audioUrl,
          String? artworkUrl,
          Duration? duration,
          bool? isDownloadable}) =>
      CatalogTrack(
        id: id,
        title: title,
        artist: artist,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        isDownloadable: isDownloadable ?? this.isDownloadable,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        genre: genre,
        mood: mood,
        duration: duration ?? this.duration,
        artwork: artwork,
        color: color,
        youtubeVideoId: youtubeVideoId,
      );
}
