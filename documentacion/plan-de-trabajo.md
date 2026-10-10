# Plan de trabajo

Decisión del 9 de octubre de 2026: el cierre incluye las cinco partes en iPhone, sin ayudante en Mac ni servidor. Las seis descargas/persistencia están probadas y el usuario confirmó modo avión/bloqueo básico. Después reportó duración duplicada en ambas rutas. **0.6.2: finales reales y audio íntegro**; reparación de las seis descargas y transición online aprobadas, Release instalada/abierta. Confirmación manual posterior pendiente. [Corrección](correccion-duracion-audio.md), [implementación](implementacion-iphone-autonomo.md), [estado](version-0.6-iphone.md). Las etapas siguientes conservan el alcance histórico y futuro.

## 1. Prototipo

Ampliación acotada 0.6.3: tres correcciones aprobadas por Erick — barra inmediata, Biblioteca en Descargas y portada local con reparación independiente del audio. Pruebas de regresión y comprobaciones físicas del gesto/imagen completadas; [detalle](ajustes-reproductor-biblioteca-portadas.md). Conservar biblioteca, firma y comprobaciones de duración de 0.6.2.

Inicio con historial de escuchas, búsqueda, biblioteca de demos, favoritos y álbumes personales persistentes, audio real incluido, reproductor, progreso, cola, repetición y aleatorio. Tema claro/oscuro según el sistema y selección manual. Configuración generada para web, iOS y Android.

Comprobar análisis, pruebas, compilación web e interfaz ejecutada. La entrega debe identificar qué verificaciones se completaron.

## 2. Catálogo y descargas

Búsqueda global paginada, seis enlaces originales e importación oEmbed implementados. El gestor nativo muestra progreso, cancelación, errores y validación; la corrección de cliente y extensión temporal permitió descargar audio/carátula y reproducir las seis versiones originales. Verificar modo avión real tras reiniciar y ampliar muestras de búsqueda. No reemplazar canciones ni usar demos como evidencia.

## 3. iPhone instalado

Xcode, firma, actualización Release y lanzamiento ya comprobados en el iPhone. Sesión de audio y MediaPlayer integrados; motor/publicación pasan una prueba separada con audio propio. Pendiente bloqueo físico, Centro de Control, llamadas, auriculares y cambios de salida con archivo descargado real.

## 4. Biblioteca completa

Álbumes editables, historial, orden, búsqueda de biblioteca, archivo recuperable y respaldo manual de metadatos implementados en 0.5. La 0.6 añade sección de descargas con espacio ocupado y cola de descargadas del álbum. Pendientes: exportación a archivo directa y sincronización opcional. Letras y ecualizador después de resolver audio y descargas. Detalle histórico en [Plan 0.5](plan-version-0.5.md).

## 5. Android

SDK y validación de audio, archivos y controles nativos. Compartir Flutter y adaptar lo necesario por plataforma.

El siguiente trabajo debe recoger audición manual posterior a 0.6.2 y ampliar llamadas/auriculares, cambios de salida y fiabilidad con más búsquedas. La persistencia/ruta local se comprueba con un proceso nuevo y fuente remota deshabilitada. No sustituir audición o una prueba física de radios/toques por una comprobación simulada.
