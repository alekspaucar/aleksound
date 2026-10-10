# Aleksound 0.6.3 — núcleo autónomo de iPhone

Fecha: 9 de octubre de 2026. **Descarga real/persistencia comprobadas en iPhone; modo avión y bloqueo confirmados manualmente por Erick.** Esta página describe el código actual. Las evidencias históricas se conservan en [Validación](validacion.md).

**Release 0.6.3+9 instalada y abierta**, 23,8 MB: barra/tiempo siguen al dedo, Biblioteca entra en Descargas y las portadas ausentes se reparan sin volver a descargar audio. La imagen de Chachachá se recuperó y se conservan siete registros/audio, más los seis originales de recuperación. [Ajustes y comprobaciones](ajustes-reproductor-biblioteca-portadas.md).

0.6.2 corrigió la duración duplicada/cola vacía mediante reempaquetado AAC sin pérdida, no con una etiqueta dividida. Las seis descargas iniciales se repararon conservando originales; todos sus finales/avance volvieron a pasar en 0.6.3. La ruta online prepara un temporal completo; Why We Lose → Julieta pasó por separado en 0.6.2. Audición manual posterior pendiente. [Causa, datos y límites](correccion-duracion-audio.md).

## Las cinco partes

| Parte | Código actual | Estado de comprobación |
| --- | --- | --- |
| Buscar música | Búsqueda real YouTube, paginación, Phonk/C.R.O/Remix/Reguetón | Resultados reales observados en pruebas nativas |
| Obtener audio | Resolver público AAC/M4A del ID exacto, cliente actualizado e identidad coherente | Seis versiones originales recibidas completas dentro del iPhone |
| Guardar audio y carátula | URLSession, progreso, cancelar, reintentar, AVFoundation, índice atómico | Seis audios y seis carátulas locales verificados en dispositivo físico |
| Escuchar offline | `just_audio` prioriza archivo local; carátula local; cola de descargadas | Las seis reproducen tras proceso nuevo sin resolver remoto; modo avión confirmado por el usuario |
| Controlar desde iOS | Sesión musical, modo audio de fondo y MediaPlayer con comandos | Publicación probada; continuidad con pantalla bloqueada y pausa/reanudación confirmadas por el usuario. Llamadas/auriculares pendientes |

Una compilación, una muestra de audio o una demo incluida **no certifican descarga/offline**. La comprobación usa archivos completos de las versiones originales. La aceptación básica de radios/bloqueo fue confirmada por el usuario; no extrapolarla a llamadas, Bluetooth o cualquier video futuro.

## Uso

1. **Buscar** consulta YouTube por canción o artista; los géneros lanzan consultas reales.
2. Descargar resuelve la misma versión. Durante la transferencia permite cancelar y muestra porcentaje; un fallo permite reintentar con una URL nueva.
3. **Biblioteca** abre **Descargas** por defecto: archivos verificados, espacio ocupado y tareas fallidas. Álbumes sigue disponible; Guardadas/Favoritos conservan metadatos, no audio.
4. Una pista descargada siempre utiliza su archivo local. En un álbum, **Sin internet** usa solo sus canciones descargadas, en su orden.
5. Cerrar el reproductor nativo no lo pausa. La web conserva el reproductor YouTube visible; no tiene transferencias nativas.

Se conservan los seis enlaces originales, IDs, álbumes, favoritos y temas blanco/negro del sistema. No se sustituye una versión musical silenciosamente. Restaurar el respaldo v1 no crea descargas: contiene metadatos, no audio.

## Estructura del núcleo

- `lib/data/youtube_audio_source.dart`: búsqueda y resolución. Todo sucede en el teléfono, sin un ayudante en Mac.
- `lib/data/audio_selection.dart`: valida ID exacto, AAC, HTTPS, dominio, tamaño y ausencia de DRM.
- `lib/data/player_request.dart`: normalización del contexto público del reproductor.
- `lib/data/youtube_client.dart`: cliente público VISIONOS y su identidad de transferencia, aislados del resto de la app.
- `lib/data/ios_player_script.dart`: expresiones del reproductor en JavaScriptCore del teléfono; módulos EJS con hash comprobado.
- `lib/state/discovery_store.dart`: consultas y paginación; descarta respuestas antiguas.
- `lib/offline/download_store.dart`: archivos verificados, trabajos, cancelación y reintento.
- `lib/offline/native_music.dart`: contrato Flutter/Swift y eventos del sistema.
- `ios/Runner/NativeMusicPlugin.swift`: almacenamiento, URLSession, AVFoundation, JavaScriptCore y MediaPlayer.
- `ios/Runner/AudioFileFinalizer.swift`: reempaquetado, duración por frames y validación del audio final; reutilizado por descargas y caché online.
- `ios/Runner/ArtworkDownloader.swift`: portadas de los dos hosts, alternativas seguras, imagen validada y recuperación independiente del audio.
- `lib/ui/player_screen.dart`: posición visual inmediata durante gesto/salto, sin acumulación de seeks.
- `lib/state/music_controller.dart`: motor único, progreso, cola, fuente local y controles remotos.
- `lib/ui/discovery_page.dart`, `download_button.dart`: buscar y estados de descarga.
- `lib/ui/local_image*.dart`: imágenes desde archivos locales.
- `integration_test/iphone_audio_test.dart`: flujo remoto completo y prueba separada del motor nativo.
- `integration_test/iphone_offline_test.dart`: nuevo proceso, índice persistente y controlador real con fuente remota deshabilitada.
- `integration_test/iphone_catalog_test.dart`: archivos de las seis versiones originales, con reintento explícito y conservación de identidad.
- `integration_test/iphone_online_timing_test.dart`: escucha real sin registro descargado, duración/final y siguiente pista; nunca borra la biblioteca para aislar la ruta online.
- `integration_test/iphone_artwork_test.dart`, `iphone_player_polish_test.dart`: reparación de imagen sin modificar audio y gesto/navegación con motor real.

## Archivos y seguridad

El audio reside en `Application Support/Aleksound` del contenedor iOS. Se generan nombres UUID; `library.json` guarda rutas relativas y se escribe atómicamente. Álbumes y ajustes siguen en preferencias. Las URLs temporales no entran en el índice, respaldos ni documentación.

Resolver → transferir → verificar → disponible. Solo respuesta HTTP válida, bytes completos y audio reproducible con duración válida habilitan **Descargada**. Los archivos ausentes vuelven a no descargados. Eliminar una descarga conserva álbumes/favoritos y detiene el archivo si suena. No se purga toda la biblioteca al recuperar errores.

Transferir → reempaquetar sin recomprimir → comprobar duración/frames/audio final → indexar. Registros anteriores migran localmente una vez y conservan `originalAudioFile`. La caché online es separada y no modifica el índice. Una escucha sin descargar puede tardar en empezar porque prepara el archivo completo; no se promete streaming progresivo. El contador muestra audio activo, no copias originales de recuperación.

Cada archivo tiene límite de 300 MB; las nuevas transferencias/preparaciones comprueban espacio para temporal y archivo final, con margen de 50 MB. Reintentar vuelve a resolver. URLSession administra descargas de fondo; cerrar a la fuerza puede cancelarlas. La preparación online usa una sesión temporal, no una descarga persistente de fondo. No se promete reanudación de fragmentos entre fuentes diferentes.

No se incorporan cuentas/contraseñas, contenido de pago ni descifrado DRM. El contexto JavaScript no recibe funciones nativas de archivos o red. `youtube_explode_dart` está fijado a 3.1.0 porque el adaptador usa interfaces internas; actualizarlo requiere pruebas.

## Corrección del fallo y límites

La ruta IOS inicial recibió HTTP 403 en simulador/iPhone. Se contrastó con la [tabla vigente del extractor yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py) y su [selección de clientes](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_video.py). Se incorporó el cliente público VISIONOS y se conserva su User-Agent al transferir, en lugar del valor genérico de la página web. VISIONOS describe el protocolo del proveedor; Aleksound sigue siendo una app de iPhone. No añade servidor, cuenta ni DRM. Esta interfaz no es una API oficial estable de YouTube y puede cambiar.

Al recibir el archivo completo apareció un segundo error: AVFoundation rechazaba la extensión temporal `.part` con `AVFoundationErrorDomain/-11828`. Se reprodujo con un archivo propio idéntico bajo dos extensiones: `.m4a` válido, `.part` inválido. El temporal ahora termina en `.part.m4a` y solo se incorpora al índice después de validar bytes, duración y reproducción. La prueba física pasó tras esta corrección.

La prueba posterior con un proceso nuevo recuperó los seis audios/carátulas del índice y los reprodujo sin consultar al resolutor; también verificó pausa, avance y reanudación. El 403 apareció de forma intermitente durante el diagnóstico: no se garantiza disponibilidad de todos los videos ni se sustituye una versión rechazada. No se borró la app ni su biblioteca. Erick confirmó modo avión, continuidad con pantalla bloqueada y pausa/reanudación mediante controles reales. Interrupciones, auriculares y cambios de salida siguen pendientes. Android, letras, ecualizador y CarPlay quedan fuera de este cierre.

## Evidencia actual 0.6.3

63 pruebas Flutter aprobadas, análisis limpio, compilaciones web/iOS correctas. La portada de Chachachá se recuperó en el teléfono y decodifica desde un archivo; comparación del índice confirma que solo cambió `artworkFile`, con los siete audios intactos. Prueba física de Descargas al reentrar y salto a 127,919 s aprobada sin consultar la fuente de audio. Seis finales originales y MediaPlayer volvieron a pasar con el resolutor deshabilitado. Release 0.6.3+9 instalada/abierta por actualización; índice conservado. No se repitió la prueba remota online de 0.6.2 en este ajuste. [Registro](validacion.md).

## Antecedente 0.6.2

60 pruebas Flutter aprobadas, análisis limpio, compilaciones web/iOS correctas. Pruebas físicas separadas de finales offline (seis) y online (dos versiones/transición) aprobadas. Release 0.6.2+8 instalada/abierta sin desinstalar. La reparación conserva los originales; el audio decodificado completo de la muestra coincide antes/después. [Registro detallado](validacion.md).

## Antecedentes 0.6.1 del 9 de octubre

- Suite Flutter: **56 pruebas aprobadas**; regresión del cliente e identidad de User-Agent reproducida antes de corregirla, además de los casos de biblioteca y descargas anteriores.
- Análisis sin incidencias; compilaciones web y Release iOS correctas. **0.6.1+7**, app 23,7 MB, instalada mediante actualización con la firma existente; seis M4A, seis JPG e índice conservados después de instalar.
- Todas las ejecuciones físicas preservan la app y sus datos. La conservación individual de cada álbum no se inspeccionó nuevamente desde la pantalla del teléfono.
- Prueba física separada aprobada: audio propio incluido reproduce y avanza; sesión `Playback`, modo de fondo declarado, metadatos MediaPlayer y comandos habilitados. No demuestra una descarga YouTube ni que un toque real en la pantalla bloqueada controle la reproducción.
- Prueba remota completa y catálogo **aprobados**: búsqueda real y seis versiones con M4A/carátula, duración mayor de un minuto y posición real avanzando. Las cinco nuevas transferencias pasaron en el primer intento de esa suite; Why We Lose reutilizó su archivo previamente validado.
- Prueba tras reinicio del proceso **aprobada** para las seis: archivos/carátulas persistentes, controlador real sin peticiones a la fuente, pausa, avance, reanudación y metadatos MediaPlayer coherentes. Esta prueba automática no apagó físicamente Wi-Fi/datos.
- **Confirmación manual de Erick:** respondió «Sí, todo funciona» a la prueba de abrir Descargas, modo avión/Wi-Fi apagado, reproducir, bloquear y pausar/reanudar desde la pantalla bloqueada. Es evidencia reportada por el usuario, no observación directa del asistente.

Registro completo y distinción de resultados: [Validación](validacion.md).

## Instalar una versión independiente de la Mac

Abrir `ios/Runner.xcworkspace` en Xcode. Mantener equipo personal, firma automática y Bundle Identifier al actualizar. **No desinstalar**: la actualización debe conservar los datos.

```bash
cd /Users/erickvzh/Documents/alesound
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
/Users/erickvzh/develop/flutter/bin/flutter pub get
/Users/erickvzh/develop/flutter/bin/flutter build ios --release --target lib/main.dart
```

Para usarla desde su icono sin depurador, instalar **Release**, no Debug/JIT. Mantener Developer Mode y confianza del certificado. Release permite cerrar Xcode, pero no elimina los requisitos de firma de desarrollo. El perfil gratuito de Personal Team vence siete días después de su emisión. Consultar [uso diario y renovación sin desinstalar](instalacion.md#usar-aleksound-sin-xcode), con referencias oficiales de Apple.

## Verificar

```bash
flutter analyze
flutter test test
flutter build web
flutter build ios --release
flutter test integration_test/iphone_audio_test.dart -d ID_SIMULADOR --no-uninstall
```

En el iPhone conectado por red, `flutter drive` requiere `--publish-port`. Añadir **siempre `--keep-app-running`**: la limpieza predeterminada del driver desinstala la app y podría borrar datos. La prueba `LOCAL_AUDIO_ONLY=true` usa audio propio incluido para aislar el motor; no es prueba de descarga YouTube.

Referencias: [proveedor Dart](https://pub.dev/packages/youtube_explode_dart), [URLSession de fondo](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:)), [MediaPlayer](https://developer.apple.com/documentation/mediaplayer), [audio_session](https://pub.dev/packages/audio_session), [just_audio](https://pub.dev/packages/just_audio).
