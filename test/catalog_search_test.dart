import 'package:aleksound/data/demo_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('busca por título sin depender de acentos', () {
    expect(searchCatalog(demoCatalog, ' orbita ').single.id, 'orbita');
  });
  test('busca por artista y género', () {
    expect(searchCatalog(demoCatalog, 'costa azul').length, 2);
    expect(searchCatalog(demoCatalog, 'electronica').length, 2);
  });
  test('una consulta sin coincidencias devuelve una lista vacía', () {
    expect(searchCatalog(demoCatalog, 'inexistente'), isEmpty);
  });
}
