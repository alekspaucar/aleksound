# Reproductor, Biblioteca y portadas — 0.6.3

Fecha: 9 de octubre de 2026. Ajustes solicitados y aprobados por Erick: barra inmediata, Descargas primero y portada local recuperable sin descargar otra vez el audio.

## Barra que sigue el dedo

Antes, cada movimiento enviaba un salto al motor y la pantalla esperaba su progreso. Ahora el reproductor mantiene una posición visual durante el gesto: barra y tiempo cambian juntos al instante; el audio salta una sola vez al soltar. Mientras ese salto termina, el progreso anterior no mueve el marcador hacia atrás. Después vuelve a mostrar la posición del motor.

Una canción nueva, otro gesto o cerrar el reproductor invalidan el estado pendiente anterior. Esta corrección sirve para el archivo local, la preparación online nativa y el reproductor web; no elimina la espera inicial de preparar un audio sin descargar.

La propiedad del gesto se captura al apoyar el dedo, no al soltarlo. Si la cola avanza mientras se mantiene pulsado, sus movimientos y final se descartan antes de buscar audio en la canción nueva. Esta regresión se reprodujo después de una revisión independiente y pasó tras añadir la protección.

Código: `lib/ui/player_screen.dart`. El controlador y el reempaquetado de audio permanecen intactos.

## Descargas al entrar

Al tocar Biblioteca desde Inicio o Buscar, se selecciona **Descargas** y se limpia el texto de búsqueda anterior para no ocultar canciones. El orden de opciones es Descargas, Álbumes, Guardadas y Favoritos. Elegir Álbumes sigue funcionando; al salir y volver por el botón Biblioteca, reaparecen las descargas. Los accesos explícitos a álbumes/favoritos conservan su destino.

La lectura de la biblioteca local se actualiza sin bloquear la navegación. Esto también permite reintentar portadas pendientes al volver, sin resolver ni transferir el audio.

Una sección Descargas vacía explica cómo descargar y ofrece **Buscar música**; no muestra instrucciones de Favoritos.

Código: `lib/ui/app_shell.dart`.

## Portada descargada y reparación

La búsqueda entregaba enlaces de `img.youtube.com`, mientras el guardado solo admitía `i.ytimg.com`: la portada se omitía aunque el audio quedara completo. Se comprobó este caso en **Jósean Log - Chachachá (Lyric Video)**, ID `sDMxQF18yvA`.

`ArtworkDownloader.swift` normaliza ambos formatos al mismo ID exacto. Usa una miniatura estándar como alternativa si la versión grande falta. Exige HTTPS, ruta/host final coherentes, HTTP 200, hasta 3 MB, dimensiones acotadas y una imagen decodificable; rechaza la miniatura pequeña de video no disponible.

Las nuevas descargas guardan la imagen junto al audio. Si una canción antigua no tiene portada local, la lectura de Biblioteca inicia una recuperación separada: no bloquea el audio offline, no vuelve a resolver el audio y no cambia nombre, bytes ni duración del M4A. La escritura de imagen e índice es atómica; una eliminación o sustitución durante la petición prevalece.

Los refrescos concurrentes comparten el trabajo. Tras fallar, el reintento queda limitado a uno por minuto al consultar Biblioteca, o puede volver a intentarse al abrir de nuevo la app. Requiere internet para obtener la imagen; una portada ausente no invalida el audio ya descargado. No se promete recuperar una imagen que el proveedor no entregue.

## Pruebas ejecutadas

- Antes de corregir: las pruebas de barra, selección de Descargas y portada ausente fallaron por los problemas reportados.
- `test/player_polish_test.dart`: el marcador y tiempo responden antes del salto, no hay saltos durante el arrastre, una actualización antigua no revierte el gesto y volver a Biblioteca selecciona Descargas/actualiza archivos.
- `tools/artwork_regression.swift`: ambos hosts, ID exacto, alternativas sin duplicados, dominio ajeno no utilizado, imagen válida y rechazo de HTML/tamaño excesivo/miniatura ausente.
- `iphone_artwork_test.dart`, iPhone físico: **portada de Chachachá recuperada**, archivo local decodificable; siete registros conservados con los mismos archivos, bytes y duración de audio.
- `iphone_player_polish_test.dart`, iPhone físico: Descargas al entrar/reentrar, portada local y salto a unos **127,919 s** con el motor real. Cero consultas a la fuente de audio remota. No es una medición de latencia acústica ni un toque observado manualmente por el asistente.
- Suite Flutter: **63 pruebas aprobadas**; análisis sin incidencias, incluida la regresión de cambio de canción durante el gesto y el mensaje de Descargas vacías.

El resultado final de compilación/instalación y las pruebas adicionales se registran en [Validación](validacion.md). La confirmación manual previa de bloqueo/modo avión no se convierte en una nueva prueba de llamadas, auriculares o disponibilidad de cualquier video.

## Comprobar en el teléfono

1. Abrir Biblioteca: deben aparecer Descargas primero, incluida Chachachá con su portada.
2. Reproducir una canción, abrir el reproductor y arrastrar la barra: el tiempo sigue el dedo y el salto se aplica al soltar.
3. Elegir Álbumes, salir a Inicio y volver a Biblioteca: vuelve Descargas, sin borrar álbumes.
4. Con la portada recuperada, escuchar desde Descargas sin internet: audio e imagen se leen del teléfono.

Relacionado: [núcleo iPhone](version-0.6-iphone.md), [guía de uso](guia-de-uso.md), [duración real](correccion-duracion-audio.md) y [desarrollo](desarrollo.md).
