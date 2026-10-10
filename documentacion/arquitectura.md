# Arquitectura

## Núcleo 0.6

El iPhone usa `YoutubeAudioSource`/`DiscoveryStore`, `DownloadStore`, puente Swift propietario de archivos y `MusicController` con `just_audio`. MediaPlayer publica estado y devuelve comandos por un canal. `AudioFileFinalizer` reempaqueta AAC según frames reales, para descargas y caché online. La biblioteca anterior migra sin borrar originales; la escucha online no crea registros descargados. La web conserva iframe visible. [Archivos actuales](version-0.6-iphone.md#estructura-del-núcleo), [duración/final](correccion-duracion-audio.md). El resto del documento registra la base histórica 0.5.

## Implementación

Flutter renderiza la interfaz. `AnimatedBuilder` observa `MusicController`, que coordina `youtube_player_iframe` para enlaces online y `just_audio` para demos antiguas. `LibraryStore` conserva IDs y metadatos en `shared_preferences`.

```text
main.dart
  ├── SharedPreferences → LibraryStore
  └── MusicController → YouTube online / just_audio local
        └── AppShell
              └── MusicHome: Inicio / Buscar / Biblioteca
                    └── PlayerScreen: reproductor / cola
```

## Responsabilidades

| Archivo | Responsabilidad |
| --- | --- |
| catalog_track.dart | Modelo de pista y disponibilidad |
| data/demo_catalog.dart | Catálogo y búsqueda insensible a acentos |
| data/online_catalog.dart | Seis versiones reales elegidas por el usuario |
| data/youtube_source.dart | Validación de enlaces y metadatos |
| data/youtube_import_service.dart | Consulta oEmbed con timeout y errores |
| data/personal_album.dart | Modelo serializable de álbum personal |
| data/library_backup.dart | Formato de respaldo versionado y validación completa |
| state/library_store.dart | Guardadas, favoritos, álbumes, historial y apariencia persistentes |
| state/music_controller.dart | Audio, cola, progreso y errores |
| state/youtube_playback_identity.dart | Identidad verificada por revisión y final pendiente consumido una vez |
| ui/app_shell.dart | Marco móvil y navegación |
| ui/player_screen.dart | Reproductor y cola |
| ui/album_screen.dart | Creación, edición y reproducción de álbumes |
| ui/import_song_sheet.dart | Importación de canciones online |
| ui/library_backup_sheet.dart | Copia, comprobación y combinación de respaldo |
| ui/artwork.dart | Carátulas remotas y locales con estados de carga/error |
| ui/theme.dart | Colores, tipografía y tamaños |

## Datos

Las fichas online usan `youtubeVideoId`, carátula remota, duración inicialmente desconocida e `isDownloadable: false`. El reproductor oficial determina duración y disponibilidad. Las demos antiguas usan tres WAV y permanecen para bibliotecas anteriores.

Preferencias: `favorites`, `saved_demos` y `recent_tracks` guardan IDs. `personal_albums` guarda JSON con identidad, nombre y canciones; `appearance` guarda `system`, `light` o `dark`. No almacenan archivos de audio. Guardar una demo organiza contenido ya incluido; no certifica una descarga.

`youtube_tracks` guarda ID, título y canal de importaciones. `tracks` contiene solo enlaces reales; `allTracks` agrega demos para resolver álbumes anteriores. `saved_demos` conserva su nombre histórico y ahora también puede contener IDs online. No se borran preferencias existentes.

`isDownloadable` e `isDownloaded` describen disponibilidad de un archivo. En el futuro, el estado offline debe calcularse desde archivos verificados, no desde un botón.

En 0.5, `personal_albums` añade `archived` (por defecto falso para datos antiguos). `allAlbums` conserva todo, `albums` filtra activos y `archivedAlbums` expone recuperables. El editor guarda IDs en el orden elegido y no descarta referencias que falten en el catálogo actual.

El respaldo `aleksound-library` versión 1 valida la entrada y el resultado combinado antes de modificar preferencias, incluidos límites de elementos y tamaño. Combina IDs y metadatos, conserva datos locales en coincidencias y renombra nombres iguales con ID distinto. Restauración y registro de escuchas comparten una cola de operaciones, con valores calculados al ejecutar cada operación; una restauración fallida no bloquea escuchas posteriores. Captura valores previos para intentar revertir fallos de escritura, continuando con las demás preferencias si una recuperación falla. No es una transacción resistente a la terminación del proceso. Ver [Biblioteca y respaldo](biblioteca-y-respaldo.md).

## Audio

La cola de Aleksound administra cada fuente por separado: un video de YouTube o un asset local. Las suscripciones actualizan estado y progreso. Lecturas secuenciales de ID/duración evitan colisiones de respuestas del adaptador web. Seleccionar una pista reinicia su posición. Anterior reinicia después de tres segundos; antes cambia de pista. Errores visibles; suscripciones liberadas al cerrar.

YouTube solo se inicializa con `playerVisible`; si una cola mixta alcanza un enlace con la pantalla cerrada, conserva la intención pendiente y pide abrirla. La identidad se invalida en transiciones y rechaza respuestas de revisiones anteriores. Un final recibido durante la confirmación se consume después de comprobar el ID, sin duplicar el avance ni arrastrarlo a otra selección.

El historial se registra cuando el reproductor está activo y listo, también al avanzar automáticamente. No se registra por abrir el reproductor o elegir una canción pausada. Conserva hasta veinte IDs, con la última escucha primero y sin duplicados.

La cola de un álbum contiene únicamente sus canciones. Las selecciones del catálogo usan la cola general. El tema utiliza `ThemeMode.system` por defecto; el controlador de biblioteca notifica cambios de apariencia para alternar entre paletas monocromas.

## Próxima arquitectura

```text
Proveedor online → Metadatos y permiso de descarga
                          ↓
Gestor de descargas → Temporal → Validación → Archivo local
                          ↓
Repositorio de biblioteca → Reproducción local
```

Fuente, descarga, biblioteca y controles nativos deben ser módulos independientes. Audio grande requiere archivos móviles; en web necesitaría almacenamiento como IndexedDB y una política de cuotas.

## Dependencias

`youtube_player_iframe` para YouTube, `http` para oEmbed, `url_launcher` para abrir la fuente, `just_audio` para demos, `shared_preferences` para metadatos e IDs y `flutter_lints` para análisis. Se versiona `pubspec.lock`. Importación e inserción no necesitan claves API; búsqueda global no implementada.

Referencias: [just_audio](https://pub.dev/packages/just_audio) y [shared_preferences](https://pub.dev/packages/shared_preferences).
