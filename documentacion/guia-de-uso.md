# Guía de uso

## iPhone 0.6.3

Al tocar **Biblioteca**, aparecen **Descargas** primero; Álbumes sigue disponible. La barra y el tiempo del reproductor siguen el dedo mientras arrastras, y el audio salta al soltar. La portada se guarda localmente: si alguna descarga anterior quedó sin ella, abrir la app o volver a Biblioteca con internet inicia su recuperación sin descargar otra vez el audio. Tras un fallo se limita el reintento a uno por minuto. [Detalle de los tres ajustes](ajustes-reproductor-biblioteca-portadas.md).

La duración duplicada se corrige automáticamente para los archivos anteriores y las próximas descargas; no hace falta borrar ni volver a descargar las seis canciones. Escuchar sin descargar prepara un temporal completo antes de comenzar, por lo que puede tardar unos segundos. No equivale a guardar la canción para futuros reinicios. [Detalle](correccion-duracion-audio.md).

Buscar consulta YouTube. Biblioteca distingue Descargas de enlaces guardados; los álbumes muestran acciones por canción y una cola de descargadas. Los seis enlaces iniciales ya tienen audio/carátula verificados en el teléfono. El [manual actual](version-0.6-iphone.md#uso) describe estados y límites; el comportamiento web permanece online.

### Descargar y escuchar en el iPhone

1. Con internet, abre **Buscar**, escribe canción/artista y elige la versión que quieres.
2. Toca **Descargar**. Espera a que termine la verificación; porcentaje o carátula visible no significan que ya esté completa.
3. Abre **Biblioteca → Descargas**. Desde allí, reproducir utiliza siempre el archivo local.
4. En un álbum, **Sin internet** crea una cola de sus canciones descargadas, respetando el orden.
5. Si aparece un error, **Reintentar** obtiene una fuente nueva de la misma versión. No borrar la app para resolverlo.

### Confirmación posterior a la corrección

La prueba básica de modo avión/bloqueo fue confirmada por Erick antes de reportar el fallo de duración. Después de actualizar 0.6.2, comprueba Why We Lose (3:33), escucha un tramo del comienzo y del final, y confirma que se oye y termina sin una segunda mitad vacía. Repite con una canción online. No cambiar esa confirmación anterior por una aceptación automática de esta corrección.

## Abrir Aleksound

En el iPhone que ya tiene **0.6.3+9 Release**, toca el icono de Aleksound. Puedes cerrar Xcode y desconectar la Mac. Mantén el modo desarrollador activado: la firma personal lo requiere también en Release. El perfil gratuito tiene vigencia limitada; [cómo renovarlo sin borrar tus canciones](instalacion.md#vigencia-de-la-instalación-personal).

Sigue [Instalación](instalacion.md) para ejecutar en Chrome o preparar dispositivos. La vista previa web permite evaluar el diseño sin instalar Xcode.

## Añadir tu música

1. En Inicio, toca **Añadir canción**.
2. Pega el enlace público de una canción en YouTube o YouTube Music.
3. Toca **Añadir a mi música** y espera la consulta de título y canal.
4. Busca la canción en tu colección.

Añadir el mismo video no crea una segunda ficha. Un enlace inválido o una consulta fallida muestra un error. Añadir una ficha no garantiza que YouTube permita reproducir ese video integrado.

## Escuchar

Toca una canción para abrir el reproductor. En iPhone usa audio nativo y prioriza el archivo descargado; sin archivo requiere internet. En navegador, si no permite inicio automático, toca reproducir en el video. Puedes pausar, adelantar, cambiar de canción y abrir la cola. La duración aparece cuando el reproductor la informa; no se inventa si todavía es desconocida.

La carátula sirve de fondo difuminado. El historial se actualiza tras confirmar reproducción activa de la canción, no simplemente por abrir su ficha.

Cerrar la pantalla del reproductor nativo de iPhone no pausa el audio. En web, cerrar el reproductor online sí lo pausa. Volver al mini-reproductor abre esa pantalla. Si una cola web con demos antiguas llega a una canción online con la vista cerrada, aparece la indicación de abrir el reproductor para continuar.

## Crear un álbum

1. Abre **Biblioteca** y selecciona **Álbumes**.
2. Toca **Crear álbum**.
3. Escribe un nombre y selecciona canciones.
4. Guarda y abre el álbum.
5. Toca **Reproducir álbum** o elige una de sus canciones.

La cola se limita al contenido del álbum. **Editar álbum** permite cambiar el nombre, buscar canciones para añadirlas y ajustar **Orden de reproducción** con Subir, Bajar y Quitar. Guarda y vuelve a reproducir el álbum para usar el nuevo orden. Un álbum personal organiza canciones; no es una descarga ni una publicación musical.

## Biblioteca y favoritos

El marcador guarda el enlace; no audio. El corazón añade o quita un favorito. **Guardadas**, **Favoritos** y **Descargas** son colecciones diferentes. Biblioteca filtra su sección actual; el menú permite ordenar canciones por Colección, Nombre o Artista. La pestaña Buscar consulta YouTube, y también puedes añadir un enlace.

## Archivar y respaldar

En las opciones del álbum, **Archivar álbum** lo aparta sin borrarlo. Se recupera desde **Opciones de biblioteca → Archivados** con sus canciones y orden intactos.

En **Opciones de biblioteca → Copia de seguridad**, copia el respaldo y guárdalo en tus notas. Para restaurarlo, pega el texto, pulsa **Comprobar copia** y después **Combinar con mi biblioteca**. Se combinan las colecciones, sin borrar las actuales. No incluye audio ni guarda un archivo automáticamente. Consulta [Biblioteca y respaldo](biblioteca-y-respaldo.md) para las reglas de combinación.

## Apariencia

En Inicio, abre **Apariencia** y elige el sistema, claro u oscuro. La elección se conserva localmente. El modo automático sigue el tema del dispositivo o navegador.

## Si algo falla

| Situación | Qué hacer |
| --- | --- |
| No empieza el audio | En iPhone revisar Descargas; sin archivo comprobar internet. En web pulsar reproducir en el video |
| YouTube rechaza la descarga | Reintentar con internet; si persiste, elegir explícitamente otra versión. No hay sustitución automática |
| YouTube bloquea la inserción web | Usar **Abrir en YouTube** o añadir otra versión |
| Falta una canción | Buscar en YouTube desde la app o añadir su enlace |
| Falta una portada descargada | Con internet, volver a Biblioteca; si acaba de fallar, esperar un minuto o abrir de nuevo la app. No borrar el audio |
| La biblioteca parece vacía en web | Volver al mismo navegador, perfil, host y puerto |
| El video cambia dentro de YouTube | Elegir una canción de la cola para continuar con su ficha correcta |

## Lo que todavía no hace

No convierte a MP3: utiliza AAC/M4A compatible con iPhone. No hay descargas nativas en web ni Android validado, sincronización, letras o CarPlay. Bloqueo/pausa/reanudación básicos y modo avión fueron confirmados por el usuario; llamadas/auriculares y cambios de salida siguen pendientes. La preparación online completa puede añadir espera. Consultar [Estado del proyecto](estado-del-proyecto.md).
