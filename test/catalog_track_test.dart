import 'package:flutter_test/flutter_test.dart';
import 'package:aleksound/catalog_track.dart';

void main() {
  test('una pista descargable todavía no está offline antes de guardarla', () {
    const track = CatalogTrack(
      id: 'demo-1',
      title: 'Midnight Drive',
      artist: 'Aleksound Sessions',
      artworkUrl: 'https://example.com/midnight-drive.jpg',
      audioUrl: 'https://example.com/midnight-drive.mp3',
      isDownloadable: true,
    );

    expect(track.isAvailableOffline, isFalse);
  });

  test('una pista sin permiso de descarga no se marca como offline', () {
    const track = CatalogTrack(
      id: 'demo-2',
      title: 'Neon Rain',
      artist: 'Aleksound Sessions',
      artworkUrl: 'https://example.com/neon-rain.jpg',
      audioUrl: 'https://example.com/neon-rain.mp3',
      isDownloadable: false,
    );

    expect(track.isAvailableOffline, isFalse);
  });

  test('una pista descargable puede marcarse como guardada offline', () {
    const track = CatalogTrack(
      id: 'demo-3',
      title: 'Afterglow',
      artist: 'Aleksound Sessions',
      artworkUrl: 'https://example.com/afterglow.jpg',
      audioUrl: 'https://example.com/afterglow.mp3',
      isDownloadable: true,
    );

    expect(track.copyWith(isDownloaded: true).isAvailableOffline, isTrue);
  });
}
