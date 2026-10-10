import '../catalog_track.dart';

// Audio y carátulas originales de demostración, incluidos con la app.
const demoCatalog = <CatalogTrack>[
  CatalogTrack(
    id: 'midnight-drive',
    title: 'Midnight Drive',
    artist: 'Aleksound Sessions',
    artworkUrl: '',
    audioUrl: 'assets/audio/midnight.wav',
    isDownloadable: true,
    genre: 'Ambient',
    mood: 'Noche',
    artwork: 0,
    color: 0xFFBCA5E5,
  ),
  CatalogTrack(
    id: 'neon-rain',
    title: 'Neon Rain',
    artist: 'Luna Norte',
    artworkUrl: '',
    audioUrl: 'assets/audio/rain.wav',
    isDownloadable: true,
    genre: 'Electrónica',
    mood: 'Energía',
    artwork: 1,
    color: 0xFF9ECADB,
  ),
  CatalogTrack(
    id: 'afterglow',
    title: 'Afterglow',
    artist: 'Costa Azul',
    artworkUrl: '',
    audioUrl: 'assets/audio/glow.wav',
    isDownloadable: true,
    genre: 'Chill',
    mood: 'Relax',
    artwork: 2,
    color: 0xFFF4B68C,
  ),
  CatalogTrack(
    id: 'orbita',
    title: 'Órbita',
    artist: 'Aleksound Sessions',
    artworkUrl: '',
    audioUrl: 'assets/audio/midnight.wav',
    isDownloadable: true,
    genre: 'Ambient',
    mood: 'Noche',
    artwork: 3,
    color: 0xFFC5B4E9,
  ),
  CatalogTrack(
    id: 'mar-adentro',
    title: 'Mar adentro',
    artist: 'Costa Azul',
    artworkUrl: '',
    audioUrl: 'assets/audio/glow.wav',
    isDownloadable: true,
    genre: 'Chill',
    mood: 'Relax',
    artwork: 4,
    color: 0xFF9ECCC3,
  ),
  CatalogTrack(
    id: 'ciudad-azul',
    title: 'Ciudad azul',
    artist: 'Luna Norte',
    artworkUrl: '',
    audioUrl: 'assets/audio/rain.wav',
    isDownloadable: true,
    genre: 'Electrónica',
    mood: 'Energía',
    artwork: 5,
    color: 0xFFA9B4E5,
  ),
];

String normalizeCatalogText(String value) => value
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

List<CatalogTrack> searchCatalog(List<CatalogTrack> tracks, String query) {
  final needle = normalizeCatalogText(query.trim());
  return tracks
      .where((track) => normalizeCatalogText(
            '${track.title} ${track.artist} ${track.genre} ${track.mood}',
          ).contains(needle))
      .toList();
}
