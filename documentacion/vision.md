# Visión de Aleksound

## Propósito

Proyecto personal de Erick: tener un reproductor propio en el iPhone, con la comodidad de YouTube Music y la autonomía de un iPod. El usuario empieza sin archivos locales y quiere encontrar música online para guardarla cuando tenga conexión.

Primero iPhone; Android después, compartiendo interfaz y lógica Flutter. No se busca publicar comercialmente ni crear una red social.

## Experiencia deseada

Buscar, escuchar, guardar cuando la fuente permita descarga y encontrar la canción después sin internet. Carátula grande, imagen difuminada detrás, controles claros y cola accesible.

La aplicación final debe seguir sonando al bloquear la pantalla. Un teléfono completamente apagado no puede reproducir audio; el requisito se refiere a pantalla apagada con el equipo encendido.

## Decisiones

- Marca Aleksound; carpeta existente `alesound`.
- Flutter y Dart, con uso personal.
- README en raíz; documentación funcional y técnica en `documentacion/`.
- Archivos de asistentes ignorados en Git.
- Confirmado el 9 de octubre de 2026: el iPhone realiza búsqueda, descarga y reproducción. El Mac solo desarrolla e instala; no actúa como ayudante de descarga ni servidor. El cierre solicitado incluye offline y controles nativos, no solo el prototipo online instalable.
- Las demos sirvieron para el diseño. El usuario aprobó avanzar con sus seis canciones reales de YouTube e importación de enlaces online; offline continúa pendiente.
- Inicio basado en escuchas recientes, álbumes personales editables e interfaz clásica con tema automático claro/oscuro.
- Futuras fuentes descargables autorizadas; no hay extractor de YouTube.

## Éxito del prototipo

Abrir en Chrome, navegar Inicio/Buscar/Biblioteca, importar un enlace real y escuchar cuando YouTube permita inserción. Biblioteca y álbumes sobreviven al reiniciar en el mismo origen. Disponibilidad y errores deben ser visibles. El diseño puede evaluarse sin Xcode.

## Decisiones futuras

Verificar proveedor y obtención de audio dentro de iOS, revisar el [diseño autónomo propuesto](diseno-iphone-autonomo.md) y completar firma/instalación personal. Un servidor no forma parte de la arquitectura elegida. La propuesta técnica aún no está implementada.
