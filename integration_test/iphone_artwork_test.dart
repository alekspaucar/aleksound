import 'dart:io';
import 'package:aleksound/offline/native_music.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('recupera portada de Chachachá sin cambiar audio guardado',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('Aleksound · Portada local'))));
    final native = IosMusic();
    try {
      final before = await native.library();
      final originals = {
        for (final r in before['records'] as List)
          (r as Map)['id']: Map<String, dynamic>.from(r)
      };
      const id = 'youtube:sDMxQF18yvA';
      expect(originals.containsKey(id), true);
      final audio = File.fromUri(Uri.parse(originals[id]!['audioUri']));
      final originalSize = await audio.length();
      Map<String, dynamic>? repaired;
      for (var attempt = 0; attempt < 15; attempt++) {
        final data = await native.library();
        repaired = Map<String, dynamic>.from((data['records'] as List)
            .cast<Map>()
            .firstWhere((r) => r['id'] == id));
        if ((repaired['artworkUri'] as String? ?? '').startsWith('file:')) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      expect(repaired!['artworkUri'], startsWith('file:'),
          reason: 'Una descarga de búsqueda debe conservar su portada.');
      final image = File.fromUri(Uri.parse(repaired['artworkUri']));
      expect(await image.length(), greaterThan(1024));
      final decoded = await decodeImageFromList(await image.readAsBytes());
      expect(decoded.width, greaterThan(100));
      expect(decoded.height, greaterThan(100));
      decoded.dispose();
      final after = await native.library();
      final records = (after['records'] as List).cast<Map>();
      expect(records.length, originals.length);
      for (final r in records) {
        final old = originals[r['id']]!;
        expect(r['audioFile'], old['audioFile']);
        expect(r['bytes'], old['bytes']);
        expect(r['duration'], old['duration']);
      }
      expect(await audio.length(), originalSize);
      binding.reportData = {
        'artworkRepaired': true,
        'audioPreserved': true,
        'records': records.length,
      };
    } finally {
      native.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
