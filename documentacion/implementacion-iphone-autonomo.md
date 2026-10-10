# Implementación de Aleksound en iPhone

Fecha: 2026-10-09. Ejecución solicitada por Erick: construir las cinco partes en esta sesión.

Objetivo: buscar música online, descargar audio completo dentro del iPhone, conservar archivos/carátulas, reproducir offline y controlar audio desde iOS. Diseño de referencia: [iPhone autónomo](diseno-iphone-autonomo.md).

## Decisiones de ejecución

- Conservar IDs, álbumes, preferencias, firma y cambios existentes. Sin commits ni publicación automática.
- Implementar aquí en el checkout conectado al usuario: el proyecto inicial sigue sin commits y Xcode usa este directorio.
- Usar `youtube_explode_dart` para búsqueda y resolución de audio público. Probar primero su ruta sin runtime externo. No añadir Deno ni un servidor en Mac.
- Integrar transferencias y controles con Swift, URLSession y MediaPlayer mediante un canal Flutter. Aprovechar `just_audio` ya integrado y evitar cambiar el gestor de dependencias nativas funcionando en Xcode.
- Descargar AAC/M4A compatible con iPhone; no convertir ni renombrar audio WebM a MP3.
- Validar tamaño, archivo y duración antes de declarar una descarga disponible. Guardar rutas relativas para sobrevivir a cambios de contenedor iOS.
- Mantener la vista web; las transferencias locales nativas corresponden al iPhone.

## Tareas y comprobaciones

- [x] Búsqueda remota paginada, respuestas tardías descartadas y errores recuperables. Archivos `lib/data/youtube_audio_source.dart`, `lib/state/discovery_store.dart`; pruebas de concurrencia, paginación y selección AAC.
- [x] Código de almacenamiento y transferencias: contratos Dart en `lib/offline/`, puente Swift en `ios/Runner/`. Pruebas Dart de cancelación durante resolución, error/archivo ausente y estado basado en registro nativo. **Transferencia remota completa de las seis versiones validada en iPhone.**
- [x] Código de reproducción: `MusicController` prioriza archivo local; MediaPlayer, sesión musical y modo background integrados. Motor propio/publicación comprobados en iPhone; no se certifican controles físicos ni streaming YouTube.
- [x] Interfaz: búsqueda YouTube, descargar/cancelar/reintentar/borrar, Biblioteca > Descargas con espacio ocupado, carátulas locales y etiquetas de estado en reproductor/álbumes. Álbum con botón de cola de descargadas.
- [x] Suite Flutter (56 pruebas), análisis y compilación web; Release 0.6.1 instalada sin borrar la app.
- [x] Corregir cliente/identidad de transferencia y extensión temporal; obtener archivos YouTube completos dentro del iPhone.
- [x] Recuperar audio/carátula y reproducir las seis versiones con proceso nuevo y fuente remota deshabilitada.
- [x] Registrar confirmación manual de modo avión y bloqueo/pausa/reanudación, anterior al reporte de duración duplicada.
- [x] Reproducir regresión de duración; reempaquetar las seis descargas sin pérdida, conservar originales y probar todos sus finales/avance real.
- [x] Corregir/validar duración y final online (Why We Lose → Julieta); 60 pruebas, análisis y compilaciones correctas; Release 0.6.2 instalada/abierta por actualización.
- [ ] Confirmar audición manual posterior a la reparación, sin reutilizar la aceptación anterior.
- [ ] Control físico específico del Centro de Control, interrupciones, auriculares y cambios de salida.

## Riesgos que se prueban

1. URL de audio caducada o rechazo de YouTube: reintento vuelve a resolver, no reutiliza una URL antigua.
2. Canción/consulta cambiada mientras llega una respuesta: invalidar por revisión/ID.
3. Cancelación, cierre y archivo incompleto: nunca marcar descargada antes de validación.
4. Cambio del directorio iOS y eliminación: resolver rutas relativas y conservar álbumes/favoritos.
5. Red ausente: iniciar biblioteca/reproducción local sin consultar YouTube; cola offline omite canciones sin archivo e informa.

## Registro

- 2026-10-09: dependencias Dart instaladas. Las capturas aportadas muestran instalación y UI en iPhone; todavía no demuestran descargas/offline ni controles nativos de Aleksound.
- 2026-10-09: núcleo 0.6 implementado y Release actualizada/abierta en el iPhone. Búsqueda y JavaScriptCore funcionan; transferencia completa devuelve HTTP 403. La prueba separada de audio propio/MediaPlayer pasa. Registro: [Validación](validacion.md). No marcar el objetivo completo.
- 2026-10-09, corrección 0.6.1: cliente público VISIONOS con identidad coherente y temporal `.part.m4a`; descarga nativa/audio/carátula aprobados para los seis enlaces exactos. Why We Lose reproduce después de iniciar otro proceso con cero peticiones al resolutor. Modo avión real y controles físicos aún no se dieron por probados.
- 2026-10-09, 0.6.2: tras confirmar radios/bloqueo básico, Erick reportó duración duplicada en ambas rutas. Reempaquetado AAC sin pérdida y migración local con originales conservados. Seis finales offline y transición online real aprobados; 60 pruebas Flutter y compilaciones web/Release correctas. Release 0.6.2+8 instalada y abierta sin desinstalar; índice/19 archivos conservados. [Evidencia](validacion.md), [causa y límites](correccion-duracion-audio.md). Audición manual posterior pendiente.
