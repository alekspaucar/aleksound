# Instrucciones de desarrollo

## Núcleo iPhone 0.6.3

Leer [barra, Biblioteca y portadas](ajustes-reproductor-biblioteca-portadas.md). Conservar la posición visual durante el arrastre y el salto pendiente; no enviar un seek por cada movimiento. Al entrar por navegación inferior, Descargas es el destino inicial. Portadas de búsqueda y oEmbed deben usar el mismo guardado seguro; no convertir una reparación de imagen en una descarga de audio.

Regresiones nuevas: `test/player_polish_test.dart`, `tools/artwork_regression.swift`, `integration_test/iphone_artwork_test.dart` y `integration_test/iphone_player_polish_test.dart`. La prueba de portada usa la descarga existente de Chachachá y compara los audios antes/después; no la borra ni la descarga otra vez. La prueba offline conserva el conteo inicial, incluidas canciones añadidas por el usuario, en vez de imponer seis registros.

Leer la [regresión de duración](correccion-duracion-audio.md). Audio positivo durante dos segundos no valida el final. Las pruebas deben comprobar frames/duración, lectura del audio final y avance de la cola. `AudioFileFinalizer` reempaqueta sin recomprimir; la biblioteca migra conservando originales. Nunca corregir este fallo dividiendo solo el texto de duración por dos.

Leer [estado actual](version-0.6-iphone.md) antes de continuar. Conservar firma y datos. Ejecutar pruebas de integración separadas para fuente remota y motor local; un fallo HTTP 403 no se convierte en éxito porque compile. En `flutter drive`, usar `--keep-app-running` para impedir su desinstalación automática. No imponer el transporte IPv4 investigado: falló por reinicio de conexión.

Cliente público aislado en `lib/data/youtube_client.dart`; la transferencia conserva su User-Agent. Al actualizarlo, probar resolución/ID/tamaño y transferencia completa en el teléfono. AVFoundation necesita extensión de audio en el temporal (`.part.m4a`); solo el índice final lo declara descargado. Fuente, temporal y validación tienen regresiones reproducidas. Nunca registrar URLs temporales ni credenciales.

Pruebas físicas: `iphone_audio_test.dart` para búsqueda/primera descarga/motor; `iphone_catalog_test.dart` para seis versiones y reintento explícito; `iphone_offline_test.dart` para otro proceso con fuente remota deshabilitada. Esta última no prueba el interruptor físico de modo avión. Tras pruebas, compilar con `--release --target lib/main.dart` e instalar por actualización, para no dejar el programa de diagnóstico en el teléfono.

## Flujo

Lee visión, requisitos y plan. Revisa el código actual y sus pruebas antes de modificar. Separa catálogo, audio, biblioteca y presentación. Actualiza documentación junto a cambios sustanciales y diferencia siempre funciones reales de demos.

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome --web-port 7358
flutter build web
```

Las pruebas cubren modelo offline, búsqueda y persistencia. Audio y diseño requieren además inspección de la app. No afirmes integración nativa basándote solo en la compilación web.

Desde 0.4 se prueban enlaces Music/watch/cortos, rechazo de dominios imitadores, metadatos incompletos e importaciones sin duplicados. Para integración real, comprobar oEmbed desde el navegador, reproducción/progreso, error de inserción, importación persistida y álbumes con pistas online. Consultar título no confirma reproducción. No registrar escuchas hasta confirmar ID activo.

Desde 0.5 se comprueban orden del álbum, referencias ausentes conservadas, archivado recuperable, respaldo completo y combinación repetida sin duplicados. Las pruebas de fallos de preferencias verifican recuperación de valores previos y continuación de la reversión si una preferencia falla; no simulan un cierre inesperado del proceso. Al modificar respaldo, validar la copia y el resultado combinado antes de escribir, probar errores de versión/IDs/límites y conservar las escuchas que coincidan con la restauración.

Para validación manual: buscar un álbum por nombre sin acentos, cambiar su orden, guardar, archivar y recuperar; copiar el respaldo, rechazar texto inválido y combinar una copia válida. Recargar en el mismo origen y comprobar que las colecciones siguen presentes. Ver [Biblioteca y respaldo](biblioteca-y-respaldo.md).

## Reglas

- Audio real con assets válidos, sin URLs ficticias.
- Estado descargado únicamente tras validar archivo local.
- Preferencias para IDs y ajustes; almacenamiento de archivos para audio.
- Errores de carga/almacenamiento visibles y accionables.
- Liberar reproductor y suscripciones; impedir cargas simultáneas.
- Colores y estilos compartidos en `ui/theme.dart`.
- Comprobar controles y desbordamientos en pantallas pequeñas.
- Versionar documentación y `pubspec.lock`; excluir instrucciones privadas, secretos y certificados.
- Conservar cambios existentes del usuario.

## Contenido de demostración

Seis fichas comparten tres audios originales. Modifica `data/demo_catalog.dart` para añadir fichas, declara assets en `pubspec.yaml` y usa contenido con condiciones claras.

```bash
python3 tools/generate_demo_audio.py
```

El generador reproducible usa biblioteca estándar y crea PCM WAV mono de 24 segundos sin descargar muestras. `CustomPainter` dibuja las carátulas localmente.

## Evidencia

Indica comandos y resultados reales. Una compilación web no prueba firma, instalación móvil, bloqueo ni segundo plano. Completa criterios de aceptación antes de marcar una etapa como terminada.
