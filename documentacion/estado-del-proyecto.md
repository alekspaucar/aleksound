# Estado del proyecto

Fecha: **9 de octubre de 2026**. **Release 0.6.3+9 instalada y abierta en iPhone**, conservando biblioteca y firma. Siete descargas con portadas locales; Chachachá recibió su imagen sin modificar audio. La barra responde al dedo y Biblioteca abre Descargas primero. [Ajustes](ajustes-reproductor-biblioteca-portadas.md). Modo avión/bloqueo básico fue confirmado por Erick antes del reporte de duración duplicada; la audición manual posterior está pendiente. Llamadas, auriculares y cambios de salida siguen pendientes. [Matriz](version-0.6-iphone.md), [evidencia](validacion.md). Los registros 0.5/0.4 son históricos.

**Corrección 0.6.2:** duración duplicada y silencio a mitad de barra reportados en ambas rutas. Se repararon las seis descargas sin pérdida ni borrado de originales; todos sus finales/avance real pasaron. La preparación online completa pasó por separado con Why We Lose → Julieta. [Causa y límites](correccion-duracion-audio.md). La aceptación inicial no cubría las canciones completas.

Este documento distingue la meta personal de la implementación actual. No sustituye las evidencias de [Validación](validacion.md).

## Implementado

- Inicio con canciones reales compartidas por el usuario y escuchas recientes; sin banner promocional.
- Importación de enlaces públicos de YouTube y YouTube Music con título y canal consultados mediante oEmbed.
- Reproducción online integrada y visible, sujeta a disponibilidad de YouTube.
- Controles de reproducción, progreso, cola, repetición y aleatorio.
- Barra/tiempo inmediatos durante el gesto; salto único al soltar, sin depender del retraso del motor para mover el marcador.
- Álbumes personales: crear, editar y reproducir sus canciones.
- Orden de canciones editable, búsqueda de selección y archivo recuperable de álbumes.
- Biblioteca con búsqueda, orden por nombre/artista y respaldo manual por copia y combinación.
- Favoritos, enlaces guardados e historial local de hasta veinte canciones sin duplicados.
- Paletas clásicas blanca y negra; tema del sistema por defecto y selección manual.
- Persistencia de metadatos y ajustes. Compatibilidad con álbumes y favoritos de demos anteriores.
- Búsqueda real YouTube por canción, artista o género, con paginación y protección de respuestas antiguas.
- Resolución pública AAC/M4A y evaluador JavaScriptCore en el iPhone, sin proceso externo en Mac. Cliente actualizado; seis archivos completos comprobados sin cambiar de versión musical.
- Gestor nativo de transferencias con progreso, cancelación, reintento, validación de audio e índice de archivos relativos. Una respuesta fallida nunca cuenta como descargada.
- Biblioteca de descargas, espacio ocupado, archivos/carátulas locales y cola offline del álbum. Reproducción local prioritaria en el controlador.
- Descargas como sección inicial al entrar por navegación inferior y recuperación de portadas ausentes sin descargar otra vez audio.
- Sesión de audio musical, modo de fondo y publicación MediaPlayer con eventos remotos. Bloqueo y pausa/reanudación confirmados por el usuario; validación de interrupciones y salidas pendiente.

## Verificación 0.6.3

63 pruebas aprobadas, análisis limpio, compilaciones web/iOS correctas. Pruebas físicas de recuperación de portada, conservación de siete audios y gesto/navegación aprobadas; los seis finales originales volvieron a pasar sin resolutor remoto. Release 0.6.3+9 instalada y abierta por actualización. El índice antes/después de reparar solo añadió la portada de Chachachá; 21 archivos conservados tras actualizar. No se inspeccionó cada álbum en la pantalla ni se volvió a medir la ruta online remota. [Validación](validacion.md).

## Antecedente 0.6.2

60 pruebas aprobadas, análisis sin incidencias y compilaciones web/Release correctas. Seis finales offline y coherencia de duración pasaron en proceso nuevo con fuente remota deshabilitada; dos versiones y transición online pasaron con fuente real. Release 0.6.2+8 instalada/abierta. Los seis originales se conservan como recuperación junto a los archivos reparados, carátulas e índice. Modo avión/bloqueo básico confirmado antes de la regresión; audición posterior pendiente. [Validación](validacion.md).

## Verificación de la ampliación 0.5

Análisis sin incidencias, 42 pruebas aprobadas y compilación web correcta. Incluye conservación de orden y referencias no disponibles, archivo recuperable, copias inválidas, combinación repetida, límites del resultado combinado, escuchas durante restauración y recuperación de valores ante fallos de escritura. Ver las comprobaciones visuales en [Validación](validacion.md).

## Comprobado en la etapa anterior (0.4)

Análisis sin incidencias, 27 pruebas aprobadas y compilación web correcta. En navegador se observó reproducción de `Why We Lose` y `Julieta (Amarea Remix)`, importación de `Signs (Kylian Remix)`, persistencia y creación de álbumes. Consultar [Validación](validacion.md) para resultados, capturas y límites; estos resultados corresponden a la revisión de código anterior, no a una nueva ejecución en cada edición de documentación.

`Texts Go Green` devolvió error de inserción 150 en el navegador probado. Las seis fichas iniciales no equivalen a seis reproducciones garantizadas.

## Pendiente

| Objetivo | Qué falta |
| --- | --- |
| Descarga real | Ampliar pruebas de búsqueda/descargas fuera de las seis versiones; los seis archivos iniciales están comprobados |
| Escucha offline | Aceptación básica confirmada por Erick; ampliar pruebas de descarga interrumpida y uso prolongado |
| iPhone personal | Mantener Developer Mode/certificado y renovar firma del Personal Team; actualización Release ya instalada |
| Controles iOS | Bloqueo y pausa/reanudación confirmados; pendientes Centro de Control específico, llamadas, auriculares y cambios de salida |
| Android | Configurar entorno y verificar en emulador y dispositivo |
| GitHub | Elegir repositorio y visibilidad; publicar cuando el usuario lo indique |

## Límites actuales

Guardar conserva un enlace; **Descargar** solicita un archivo AAC/M4A. Solo un archivo verificado habilita offline: los seis originales ya pasaron esa validación en el teléfono. En iPhone el motor es nativo y cerrar la pantalla no lo pausa; la vista web usa un reproductor online visible y lo pausa al cerrar. Buscar consulta YouTube; la búsqueda interna de Biblioteca filtra las colecciones.

Las preferencias web dependen de navegador, perfil, host y puerto. El respaldo permite trasladar metadatos manualmente; no hay sincronización automática ni respaldo de audio. No se verificaron llamadas, auriculares ni todas las versiones futuras. El bloqueo básico fue confirmado por el usuario. La vista web con marco móvil no es un simulador de iPhone.

## Próximo trabajo

El usuario confirmó que todo el uso debe realizarse desde el iPhone: buscar, descargar, organizar y escuchar. El Mac solo desarrolla e instala. Se solicita completar offline y controles nativos antes del cierre, no limitar la entrega al prototipo online.

La fuente pública actual ya entregó los seis audios dentro del teléfono. Los rechazos intermitentes siguen siendo posibles y se muestran como fallos recuperables, no como descargas válidas. No hay servidor Mac, sustitución de canción ni demos como evidencia. El [diseño aprobado](diseno-iphone-autonomo.md) marca la meta; la [implementación](implementacion-iphone-autonomo.md) identifica lo hecho y lo pendiente.

Seguir [Plan de trabajo](plan-de-trabajo.md), ampliando pruebas de interrupciones/salidas y fiabilidad del proveedor. Cada avance debe actualizar este estado, sus requisitos y la evidencia correspondiente.
