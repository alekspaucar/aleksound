# Estructura del proyecto

Marca: **Aleksound**. Carpeta y repositorio local: `alesound`. Base: Flutter y Dart.

El mapa siguiente registra la base. Los archivos añadidos para búsqueda, descargas, puente Swift, imágenes locales y pruebas de integración se describen en [estructura 0.6](version-0.6-iphone.md#estructura-del-núcleo).

## Mapa de archivos

```text
alesound/
├── README.md                       Presentación y ejecución rápida
├── .gitignore                      Exclusiones de Git
├── pubspec.yaml                    Dependencias, versión y assets
├── pubspec.lock                    Versiones resueltas
├── analysis_options.yaml           Reglas de análisis
├── lib/
│   ├── main.dart                    Inicio de la app y preferencias
│   ├── catalog_track.dart           Modelo de canción
│   ├── data/
│   │   ├── online_catalog.dart      Los seis enlaces iniciales
│   │   ├── youtube_source.dart      Validación de enlaces y metadatos
│   │   ├── youtube_import_service.dart  Consulta de título y canal
│   │   ├── personal_album.dart      Modelo de álbum personal
│   │   ├── library_backup.dart      Formato y validación del respaldo
│   │   └── demo_catalog.dart        Demos anteriores y búsqueda
│   ├── state/
│   │   ├── library_store.dart       Persistencia de biblioteca y ajustes
│   │   ├── music_controller.dart    Audio, progreso y cola
│   │   └── youtube_playback_identity.dart  Identidad y final pendiente
│   └── ui/
│       ├── app_shell.dart           Inicio, Buscar y Biblioteca
│       ├── player_screen.dart       Reproductor expandido
│       ├── album_screen.dart        Editor y vista de álbum
│       ├── import_song_sheet.dart   Formulario para añadir enlaces
│       ├── library_backup_sheet.dart  Copiar, comprobar y combinar respaldo
│       ├── artwork.dart             Carátulas y estados de imagen
│       └── theme.dart               Paletas clara y oscura
├── assets/audio/                    Audio original de demos antiguas
├── test/                            Pruebas de estado, datos e interfaz
├── tools/                           Generador de audio de demostración
├── web/                             Configuración web
├── ios/                             Proyecto nativo de iOS
├── android/                         Proyecto nativo de Android
└── documentacion/                   Manuales, requisitos y evidencias
```

Las carpetas nativas existen; esto no significa que la instalación o la reproducción móvil estén verificadas. `build/` y `.dart_tool/` se generan y no se versionan.

## Dónde cambiar cada cosa

| Necesidad | Punto de entrada |
| --- | --- |
| Modificar Inicio o navegación | `lib/ui/app_shell.dart` |
| Cambiar colores o tema | `lib/ui/theme.dart` |
| Cambiar presentación del reproductor | `lib/ui/player_screen.dart` |
| Cambiar respuesta de barra/tiempo al arrastrar | `lib/ui/player_screen.dart` y `test/player_polish_test.dart` |
| Cambiar guardado o reparación de portadas iPhone | `ios/Runner/ArtworkDownloader.swift` y `NativeMusicPlugin.swift` |
| Cambiar reproducción o cola | `lib/state/music_controller.dart` |
| Proteger historial frente a cambios de video | `lib/state/youtube_playback_identity.dart` |
| Añadir canciones iniciales | `lib/data/online_catalog.dart` |
| Cambiar validación o importación | `lib/data/youtube_source.dart` y `youtube_import_service.dart` |
| Cambiar almacenamiento local | `lib/state/library_store.dart` |
| Cambiar creación o edición de álbumes | `lib/ui/album_screen.dart` |
| Cambiar búsqueda, orden o archivados de Biblioteca | `lib/ui/app_shell.dart` |
| Cambiar validación del respaldo | `lib/data/library_backup.dart` |
| Cambiar combinación y recuperación ante fallos | `lib/state/library_store.dart` |
| Cambiar formulario de copia/restauración | `lib/ui/library_backup_sheet.dart` |

`test/library_backup_test.dart` cubre validación, combinación repetida, conservación de datos y un fallo de escritura simulado. `library_store_test.dart` cubre archivo recuperable; `album_editor_test.dart`, el orden guardado y referencias ausentes conservadas.

Mantener datos, reproducción y presentación separados. Las futuras descargas necesitan su propio gestor y almacenamiento de archivos; no deben simularse con una preferencia o un enlace guardado.

## Organización de Markdown

`README.md` es la entrada pública. [README de documentación](README.md) es el índice. Los documentos del producto permanecen en `documentacion/`; las capturas van en `documentacion/capturas/`.

Los archivos específicos de asistentes, como `AGENTS.md`, `CLAUDE.md` y `CODEX.md`, se excluyen mediante `.gitignore`. No ignorar todos los `.md`: estos manuales sí deben acompañar al proyecto en GitHub. El README generado de assets iOS pertenece a la configuración nativa y no se mueve.

Para responsabilidades y datos, consultar [Arquitectura](arquitectura.md). Para reglas de cambio, consultar [Desarrollo](desarrollo.md).
