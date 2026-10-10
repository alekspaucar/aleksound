# YouTube online — prototipo 0.4

## Música real

La colección inicial contiene las versiones exactas compartidas por Erick:

| Canción | Video |
| --- | --- |
| Drake — Texts Go Green | `kFXHPfI2JoI` |
| After Hours (best part) | `sI3FS119zNI` |
| Drake — Signs (Kylian Remix) | `RSk4BlmtGbE` |
| Cartoon, Jéja — Why We Lose | `zyXmsVwZqX4` |
| Latin Mafia — Julieta (Amarea Remix) | `O02ITEGcUQE` |
| La Santa Grifa — Sabanas Blancas | `lRP7b8bl6l4` |

Los títulos se verificaron con oEmbed de YouTube. Las fichas iniciales usan títulos abreviados y créditos legibles; una importación conserva el título y canal de la respuesta. Las carátulas son remotas, no se incluyen en el paquete. No se inventan artistas ante respuestas incompletas.

## Añadir una canción

1. Toca **+ / Añadir canción** en Inicio o **Añadir canción desde YouTube** en Buscar.
2. Pega un enlace público de YouTube o YouTube Music.
3. Toca **Añadir a mi música**. Se consultan título/canal y se conserva el ID, sin seguimiento.
4. Encuentra la ficha en tu colección y añádela a álbumes o favoritos.

Se admiten enlaces watch, youtu.be, shorts, embed y live con ID válido. Se rechazan otros dominios y listas sin canción. Reimportar un ID no duplica la ficha ni quita una canción guardada. `youtube_tracks` conserva las importaciones; álbumes y favoritos continúan usando IDs.

## Escuchar

El reproductor oficial permanece visible y conserva sus controles. Aleksound añade pausa, avance, anterior, siguiente, repetición y cola. Si no hay inicio automático, toca reproducir en el video. El historial solo registra reproducción activa con el ID confirmado; consultar metadatos o abrir una ficha no cuenta como escuchar.

La app pausa y libera YouTube al cerrar el reproductor online. El mini-reproductor vuelve a abrir esa vista. No implementa audio oculto, pantalla bloqueada ni segundo plano. Un video puede no permitir inserción o estar restringido/retirado: se muestra el error y **Abrir en YouTube**, sin cambiar de versión silenciosamente.

En el adaptador web, lecturas concurrentes de metadatos pueden colisionar por sus claves de respuesta. Aleksound confirma ID y duración con lecturas secuenciales y acotadas. No inventa la duración si no llega información válida.

Cada transición de reproducción invalida la identidad anterior. Las consultas tardías se descartan si cambió la selección o la transición. No se usa el título cacheado para registrar escuchas. Si YouTube abre un video relacionado diferente, la app lo pausa y solicita seleccionar una canción de la cola, sin atribuirlo a la ficha original.

En una cola mixta de demos antiguas y enlaces, si el audio local termina con la pantalla cerrada, la siguiente canción de YouTube queda pendiente. Se muestra **Abre el reproductor para continuar**; no se intenta cargar un video oculto. Al abrir la pantalla se consume esa intención de reproducción. Esto no constituye reproducción online en segundo plano.

## Pendiente

- Búsqueda global: el buscador actual solo filtra tu colección.
- Descarga de audio, MP3 y reproducción offline.
- Validación nativa en iPhone y Android.
- Garantizar que todas las versiones permitan inserción: un título consultable no prueba disponibilidad de reproducción.

Los álbumes y favoritos antiguos mantienen sus demos. No se borraron bibliotecas anteriores.

Referencias: [API de YouTube](https://developers.google.com/youtube/iframe_api_reference), [youtube_player_iframe](https://pub.dev/packages/youtube_player_iframe).
