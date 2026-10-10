# Duración duplicada y cola sin sonido

Fecha: 2026-10-09. Regresión informada por Erick después de la primera aceptación de modo avión/bloqueo. Afecta descargas y escucha sin descargar.

## Causa comprobada

Una copia de la descarga original de Why We Lose contiene 9.394.112 frames AAC a 44.100 Hz: **213,018 s de audio**. AVFoundation interpreta su contenedor MP4 fragmentado como **426,085 s**. La transferencia llegó completa (3.449.148 bytes); no se trata de dividir por dos una etiqueta de interfaz ni de descargar la mitad del archivo.

Las pruebas anteriores reproducían pocos segundos y exigían solo duración positiva: no detectaban la cola vacía. La regresión nueva falló en el iPhone con 426,085 frente a los 213 s esperados.

## Reparación

`ios/Runner/AudioFileFinalizer.swift` obtiene la duración real desde frames y frecuencia de muestreo. Exporta con `AVAssetExportPresetPassthrough` a un M4A nuevo, limitado al intervalo real: reempaqueta AAC sin volver a comprimirlo. Comprueba bytes, frames conservados, duración coherente con AVPlayer y lectura del audio final.

Las descargas nuevas validan el tamaño original recibido **antes** de reempaquetar. El índice guarda el tamaño y duración del archivo preparado, no los del transporte.

Las descargas anteriores se reparan localmente al cargar la biblioteca, sin consultar YouTube. Cada registro conserva ID, título, artista y carátula; el índice cambia atómicamente al archivo nuevo, marcado `timingVersion: 1`. `originalAudioFile` conserva el original como copia recuperable. Los refrescos simultáneos comparten una sola migración; un fallo conserva el registro anterior. No desinstalar ni borrar datos para reparar.

Las copias originales ocupan espacio adicional. El contador de Descargas corresponde a los archivos activos; no incluye esas copias de recuperación. No hay purga automática de originales en esta corrección.

### Escucha sin descargar

La ruta online del iPhone también utiliza el finalizador. URLSession recibe el archivo completo en `Caches/AleksoundPreview`; conserva las cabeceras de la misma fuente y valida bytes. Después se reempaqueta antes de entregarlo a `just_audio`.

Es **preparación completa**, no streaming progresivo: puede añadir espera al comenzar, según tamaño y red. No crea un registro de Descargas. El temporal anterior se libera después de cargar la siguiente fuente y al liberar el reproductor; los UUID de esta caché se limpian al iniciar otro proceso. El borrado nunca apunta a Application Support. Para conservar una canción al reiniciar/sin internet sigue siendo necesario **Descargar**.

Rechazos del proveedor no se presentan como silencio ni como descarga válida: se muestra el motivo y permite obtener otra fuente al pulsar reproducir. La ruta pública puede fallar de forma intermitente.

## Evidencia ejecutada

- `tools/audio_finalizer_regression.swift`, compilado junto al código de producción: duración 213,018 s, SHA-256 idéntico de **todos los samples decodificados** antes/después, original intacto y rechazo de sobrescritura del destino.
- Prueba física offline: reparación de las seis descargas; duraciones del archivo y del reproductor coherentes; reproducción y avance a la siguiente pista en el final real de cada canción. El resolutor está deshabilitado en la prueba.
- Lectura del índice del teléfono confirma seis registros con `timingVersion: 1`, carátulas originales y referencias de recuperación conservadas.
- `iphone_online_timing_test.dart` aprobada en iPhone físico: el test oculta la vista de descargas sin borrarlas; resuelve y prepara audio real, reproduce Why We Lose (213,018 s), salta al final real y reproduce Julieta (198,506 s), ambas sin marcar como descargadas. La primera ejecución sin red y otras ejecuciones online fallidas no se cuentan como éxito; la ejecución posterior aprobada está registrada por separado.

| Canción | Segundos correctos en el índice |
| --- | ---: |
| Texts Go Green | 308,986 |
| After Hours (best part) | 167,786 |
| Signs (Kylian Remix) | 390,837 |
| Why We Lose | 213,018 |
| Julieta (Amarea Remix) | 198,506 |
| Sabanas Blancas | 253,952 |

Offline y online tienen pruebas físicas separadas. La audición manual posterior a la actualización debe confirmarse con Erick; avance de posición y decodificación no equivalen a escuchar personalmente el altavoz del teléfono.

## Repetir comprobaciones

```bash
xcrun swiftc -parse-as-library ios/Runner/AudioFileFinalizer.swift tools/audio_finalizer_regression.swift -o /tmp/aleksound-audio-regression
/tmp/aleksound-audio-regression COPIA_LOCAL.m4a NUEVO_DESTINO.m4a
flutter drive --no-pub --driver=test_driver/iphone_audio_driver.dart --target=integration_test/iphone_offline_test.dart -d ID_IPHONE --publish-port --keep-app-running
```

El fixture es una copia local de diagnóstico, no una descarga Mac necesaria para el uso de la app. Conservar los archivos del usuario. Tras las pruebas, reinstalar por actualización una compilación **Release de `lib/main.dart`**, no dejar el objetivo de diagnóstico.

Referencias primarias: [AVAudioFile.length](https://developer.apple.com/documentation/avfaudio/avaudiofile/length) y [AVAssetExportSession](https://developer.apple.com/documentation/avfoundation/avassetexportsession). Evidencia completa: [Validación](validacion.md).
