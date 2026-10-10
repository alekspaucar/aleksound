# Aleksound

Tu música, a tu manera. Aplicación personal de música hecha con Flutter, pensada primero para iPhone y preparada para Android.

La interfaz se inspira en YouTube Music: carátulas protagonistas, fondos difuminados, navegación sencilla y reproductor expandido. Aleksound tiene identidad propia y no está afiliada a YouTube.

## Estado actual: 0.6.3 instalada en iPhone

La barra y el tiempo siguen el dedo; el salto se aplica al soltar. Biblioteca abre **Descargas** primero, con Álbumes disponible. Las portadas se guardan localmente y las ausentes se recuperan sin descargar otra vez el audio. La de **Chachachá** ya se reparó; las siete descargas se conservan. [Cambios y pruebas](documentacion/ajustes-reproductor-biblioteca-portadas.md).

Se reprodujo y corrigió la duración duplicada: las seis descargas se repararon localmente sin pérdida, conservando originales, y sus finales/avance de cola pasaron en iPhone. La escucha online prepara un temporal completo y también pasó con Why We Lose → Julieta. Puede añadir espera inicial; no equivale a guardar para offline. Detalle: [duración y cola vacía](documentacion/correccion-duracion-audio.md). La aceptación anterior de pocos segundos no certificaba los finales; audición manual posterior pendiente.

Se implementaron las cinco capas: búsqueda real, resolución de audio público, descargas/archivos, reproducción local y controles nativos. **Las seis versiones originales tienen audio y carátula descargados en el iPhone**, y reproducen tras iniciar un proceso nuevo sin consultar YouTube. Erick confirmó manualmente modo avión, continuidad con pantalla bloqueada y pausa/reanudación desde los controles de iOS.

Consulta [núcleo iPhone 0.6](documentacion/version-0.6-iphone.md) para código, instrucciones, evidencias y límites. El Mac solo desarrolla e instala; no es un servidor de música. Álbumes, favoritos y temas se conservan.

Verificación: **63 pruebas Flutter aprobadas**, análisis sin incidencias y compilaciones web/iOS correctas. Release **0.6.3+9** instalada y abierta por actualización, sin desinstalar ni restablecer datos. Gesto/portada/Biblioteca y los seis finales originales pasaron de nuevo en iPhone físico. Las pruebas automáticas y las confirmaciones del usuario se distinguen en [Validación](documentacion/validacion.md). Llamadas, auriculares y cambios de salida siguen pendientes de prueba.

## Base conservada del prototipo 0.5

Esta versión amplía la biblioteca: búsqueda y orden de colecciones, orden de canciones del álbum, archivo recuperable y copias de seguridad de metadatos.

- Inicio con las seis canciones reales compartidas por Erick y sus carátulas de YouTube.
- Importación de otros enlaces de YouTube o YouTube Music con título y canal reales.
- Reproductor integrado de YouTube, con progreso y errores de disponibilidad.
- Álbumes personales: crear, editar, añadir canciones y reproducir su propia cola.
- Editor con búsqueda de canciones y orden de reproducción configurable.
- Archivados recuperables desde Biblioteca, sin borrar contenido.
- Respaldo copiable y restauración por combinación, sin duplicar colecciones.
- Búsqueda de álbumes, guardadas y favoritos; orden por colección, nombre o artista.
- Historial local de las últimas veinte canciones, sin duplicados.
- Interfaz clásica en blanco y negro, con tema automático del dispositivo y selección manual de claro/oscuro.
- Búsqueda por canción, artista y género dentro de tu colección; no busca todo YouTube.
- Biblioteca de enlaces, favoritos e importaciones que persisten al reiniciar.
- Las demos anteriores se conservan en álbumes y favoritos antiguos; no aparecen en Inicio.
- Mini-reproductor y pantalla expandida con fondo difuminado de la carátula.
- Pausa, anterior, siguiente, avance, repetición, aleatorio y cola.
- Vista de tamaño móvil dentro de Chrome en ventanas amplias.
- Archivos de proyecto para web, iOS y Android.

**Guardar una canción de YouTube conserva su enlace; no descarga audio.** Requiere internet y el reproductor visible. Al cerrar el reproductor online se pausa. YouTube puede bloquear versiones o reproducción integrada; la app muestra el error y permite abrir la fuente. Obtener metadatos no demuestra que un video pueda reproducirse.

Ese era el alcance de 0.5. El código y límites actuales están en [versión 0.6](documentacion/version-0.6-iphone.md). Letras y Android siguen pendientes.

Decisión confirmada el 9 de octubre de 2026: buscar, descargar y escuchar se hará **solo desde el iPhone**. El usuario autorizó construir las cinco partes: [diseño de referencia](documentacion/diseno-iphone-autonomo.md) y [implementación](documentacion/implementacion-iphone-autonomo.md).

## Usar la app instalada en tu iPhone

Abre Aleksound desde su icono. Puedes cerrar Xcode y desconectar o apagar la Mac: **0.6.3+9 está instalada en Release**. Mantén activo el modo desarrollador y la confianza en tu certificado; Release no cambia la firma personal. Con Personal Team gratuito, el perfil vence a los siete días de su emisión y debe renovarse sin borrar la app. [Uso diario, firma y actualización segura](documentacion/instalacion.md#usar-aleksound-sin-xcode).

## Vista previa web en la Mac

En la terminal de VS Code o de tu Mac:

```bash
cd /Users/erickvzh/Documents/alesound
export PATH="/Users/erickvzh/develop/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome --web-port 7358
```

Chrome abre la app. Amplía la ventana para ver el marco móvil. Toca una carátula para escuchar y el mini-reproductor para abrir la pantalla completa. En la terminal, `r` actualiza y `q` termina la sesión.

En este Mac también puedes abrir `lib/main.dart`, seleccionar **Aleksound en Chrome** en Ejecutar y depurar y pulsar F5. La configuración de VS Code es local y está ignorada en Git. La vista previa estática del asistente usa 7357; el modo de desarrollo usa 7358 para evitar conflictos.

Esta ruta del SDK corresponde al Mac donde comenzó el proyecto; en otra máquina usa tu instalación de Flutter. Para ver la app en Chrome no necesitas Xcode. Si Flutter no está en el PATH:

```bash
/Users/erickvzh/develop/flutter/bin/flutter run -d chrome --web-port 7358
```

## Documentación

Capturas de la ampliación 0.5: [Biblioteca](documentacion/capturas/biblioteca-0.5.png) y [editor con orden de canciones](documentacion/capturas/editor-album-0.5.png).

Capturas de la integración real: [reproductor final](documentacion/capturas/youtube-final.png), [reproductor de YouTube](documentacion/capturas/youtube-reproductor.jpg) y [álbum online](documentacion/capturas/youtube-album.jpg).

Capturas del diseño anterior 0.3: [Inicio claro](documentacion/capturas/inicio-claro.jpg), [Inicio oscuro](documentacion/capturas/inicio-oscuro.jpg), [álbum personal](documentacion/capturas/album.jpg) y [reproductor de demo](documentacion/capturas/reproductor.jpg).

| Documento | Contenido |
| --- | --- |
| [iPhone 0.6](documentacion/version-0.6-iphone.md) | Código actual, pruebas, límites e instalación Release |
| [Ajustes 0.6.3](documentacion/ajustes-reproductor-biblioteca-portadas.md) | Barra inmediata, Descargas primero y recuperación de portadas |
| [Índice](documentacion/README.md) | Mapa de documentación |
| [Estado del proyecto](documentacion/estado-del-proyecto.md) | Implementado, comprobado y pendiente |
| [Guía de uso](documentacion/guia-de-uso.md) | Añadir canciones, escuchar y crear álbumes |
| [Estructura del proyecto](documentacion/estructura-del-proyecto.md) | Mapa de archivos y dónde modificar cada función |
| [Visión](documentacion/vision.md) | Objetivo y decisiones |
| [Requisitos](documentacion/requisitos.md) | Funciones y aceptación |
| [Diseño](documentacion/diseno.md) | Pantallas e identidad visual |
| [Arquitectura](documentacion/arquitectura.md) | Código y responsabilidades |
| [iPhone autónomo: diseño de referencia](documentacion/diseno-iphone-autonomo.md) | Meta aprobada de descargas y audio nativo sin servidor en Mac |
| [Implementación iPhone](documentacion/implementacion-iphone-autonomo.md) | Tareas implementadas y aceptación pendiente |
| [Instalación](documentacion/instalacion.md) | Uso sin Xcode, modo desarrollador, renovación de firma y preparación de dispositivos |
| [Desarrollo](documentacion/desarrollo.md) | Instrucciones y comprobaciones |
| [Catálogo y offline](documentacion/catalogo-y-offline.md) | Demos y futuras fuentes |
| [Plan de trabajo](documentacion/plan-de-trabajo.md) | Etapas de la app |
| [GitHub](documentacion/github.md) | Versionado y publicación |
| [Validación](documentacion/validacion.md) | Comprobaciones realizadas y límites |
| [Álbumes, historial y temas](documentacion/albumes-historial-temas.md) | Cómo usar las nuevas funciones |
| [YouTube online](documentacion/youtube-online.md) | Canciones reales, importación y límites |
| [Biblioteca y respaldo](documentacion/biblioteca-y-respaldo.md) | Orden, archivados y copias de seguridad |

## Estructura

```text
lib/
  main.dart                 Entrada
  catalog_track.dart        Modelo de canción
  data/                     Búsqueda YouTube, resolución, importación y demos
  offline/                  Gestor de descargas y contrato nativo iPhone
  state/                    Reproducción y biblioteca
  ui/                       Pantallas, carátulas y tema
assets/audio/               Audio original
test/                       Pruebas
integration_test/           Prueba remota completa y motor nativo separado
test_driver/                Ejecución física sin desinstalar
tools/                      Demos y diagnóstico acotado de audio remoto
documentacion/              Documentación funcional y técnica
web/  ios/  android/        Configuración de plataformas
```

## Verificación

```bash
flutter analyze
flutter test test
flutter build web
flutter build ios --release
```

Se versiona `pubspec.lock` para usar las mismas dependencias. Instrucciones de asistentes, secretos, configuración local y compilaciones están excluidos en `.gitignore`.

## Contenido

La meta sigue siendo descubrir y guardar música cuando haya internet. iOS descarga AAC/M4A sin conversión obligatoria a MP3 y prioriza el archivo local verificado. La ruta pública del proveedor puede cambiar o rechazar una versión: se informa del fallo y se permite reintentar, sin reemplazar la canción. La vista web continúa online.

Las carátulas online se consultan desde YouTube. Las demos antiguas usan ilustraciones locales y audio propio de `tools/generate_demo_audio.py`; se conservan para compatibilidad.

Referencias: [Flutter web](https://docs.flutter.dev/platform-integration/web/building), [just_audio](https://pub.dev/packages/just_audio), [shared_preferences](https://pub.dev/packages/shared_preferences).
