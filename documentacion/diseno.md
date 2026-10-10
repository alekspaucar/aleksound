# Diseño de interfaz

## Dirección

Experiencia musical clásica, con interfaz blanca o negra según el dispositivo. La música escuchada recientemente ocupa el primer bloque; no hay mensajes ni banners de promoción. Las ilustraciones conservan el protagonismo visual en las carátulas.

## Sistema visual

| Elemento | Claro | Oscuro |
| --- | --- | --- |
| Fondo | `#FAFAFA` | `#101010` |
| Superficie | `#F0F0F0` | `#202020` |
| Texto y controles | `#171717` | `#F5F5F5` |
| Texto secundario | `#626262` | `#AAAAAA` |
| Divisiones | `#DDDDDD` | `#383838` |

Sans serif disponible en la plataforma, títulos de 21–30 px y texto de 12–15 px. Texto a la izquierda y carátula centrada en el reproductor. Controles táctiles de al menos 44 px, ayudas y estados vacíos legibles.

## Pantallas

```text
Inicio                  Buscar                   Biblioteca
Marca / apariencia      Título                   Título / Crear álbum / Opciones
Escuchadas recientes    Campo de búsqueda        Álbumes / Guardadas / Favoritos
Filtros                 Géneros                  Búsqueda / Orden / Lista
Carrusel                Resultados
Accesos / lista
------------------------------------------------------------
Mini-reproductor: carátula, título, pausa y siguiente
Inicio                  Buscar                   Biblioteca
```

El reproductor expandido usa la carátula real como fondo difuminado y muestra el reproductor oficial de YouTube visible. Incluye cerrar, guardar enlace con marcador (no descarga), título/artista, corazón, progreso, tiempos, aleatorio, anterior, reproducción, siguiente, repetir y cola. Errores de YouTube y alternativa de abrir la fuente visibles. La ventana del video mide al menos 200 px de altura.

Los álbumes personales tienen portada compuesta por sus canciones, nombre, listado y acción de reproducción. El editor separa **Orden de reproducción** (seleccionadas con Subir, Bajar y Quitar) de **Añadir canciones** (búsqueda y selección). La cola del reproductor refleja únicamente el álbum que está sonando.

Biblioteca conserva los filtros Álbumes, Guardadas y Favoritos. Su búsqueda y orden tienen controles discretos en la misma paleta. El menú de opciones abre Archivados y Copia de seguridad. Archivar es recuperable; no usar lenguaje de eliminación permanente. El respaldo muestra cantidades y exige comprobación previa antes de combinar, con resultado o error visibles. Formularios y listas se desplazan sin ocultar las acciones principales en tamaño móvil.

## Adaptación

Contenidos desplazables cuando falta altura. Ventanas amplias muestran un marco de 430 px. Es una vista de diseño, no un simulador de iOS ni prueba de controles nativos.

Las transiciones responden al usuario. Inicio usa carátulas remotas y el acceso **Añadir canción**. **Buscar en mi música** deja claro el alcance de búsqueda. Las demos antiguas conservan sus ilustraciones. «Guardar enlace online» no certifica offline; «Descargar» se reserva para transferencia real.
