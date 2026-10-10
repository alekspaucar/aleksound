# Requisitos y aceptación

## Cierre de iPhone 0.6

### Ajustes aprobados 0.6.3

- Barra y tiempo acompañan al dedo sin esperar al motor; un salto al soltar. Los eventos antiguos no revierten el gesto ni una canción nueva.
- Cada entrada por el botón Biblioteca desde otra pestaña muestra Descargas, sin ocultar ni borrar Álbumes. Limpiar la búsqueda anterior evita esconder canciones por un filtro viejo.
- Guardar una portada local decodificable. Reparar las descargas que quedaron sin ella con internet, sin descargar de nuevo el audio ni modificar su duración/archivo. Un fallo de imagen no bloquea escuchar un archivo válido.

[Implementación y pruebas](ajustes-reproductor-biblioteca-portadas.md). Estas pruebas automáticas no certifican latencia acústica cero ni disponibilidad de todas las portadas.

### Antecedente 0.6.2

Buscar, obtener audio, descargar archivos/carátulas, escuchar offline y controlar desde iOS son las cinco partes solicitadas. Las seis versiones tienen archivos completos y recuperación en proceso nuevo comprobadas. Erick confirmó modo avión/bloqueo básico, pero después reportó duración duplicada en ambas rutas. La aceptación exige **duración real, audio conservado hasta el final y avance sin tramo vacío**. Los seis finales offline y dos versiones/transición online pasaron; Release 0.6.2 instalada/abierta. Audición manual posterior, interrupciones y auriculares pendientes. [Matriz](version-0.6-iphone.md), [regresión](correccion-duracion-audio.md). No contar demos, muestras parciales ni enlaces como aceptación offline. El prototipo siguiente es el antecedente.

## Prototipo 0.5

| Función | Criterio |
| --- | --- |
| Inicio | Historial real de escuchas, carátulas, filtros y accesos a biblioteca; sin bloque promocional |
| Álbumes | Nombre y selección de canciones persistentes; edición y reproducción solo de sus pistas |
| Orden de álbum | Orden elegido al editar persiste; una reproducción nueva lo utiliza |
| Archivo | Archivar oculta el álbum sin borrarlo; recuperarlo conserva sus canciones y orden |
| Respaldo | Validación previa y combinación sin perder biblioteca existente; no incluye audio |
| Biblioteca | Búsqueda de álbumes/canciones, orden por colección/nombre/artista y estados vacíos claros |
| Apariencia | Paletas blanca/negra, tema del dispositivo por defecto y elección manual persistente |
| Búsqueda | Título, artista, género o ambiente; ignora acentos y espacios exteriores |
| Enlaces guardados | Guardar/quitar enlaces modifica la lista y persiste; no implica descarga |
| Favoritos | Corazón y menú modifican el mismo conjunto persistente |
| Audio | Reproductor online visible con progreso real y errores de disponibilidad |
| Importar | Enlace validado, título/canal reales, ID único y persistencia |
| Reproductor | Mini-reproductor abre carátula grande con fondo difuminado |
| Cola | Elegir una pista comienza esa pista |
| Errores | Fallas de audio o almacenamiento generan un mensaje |
| Vista previa | Marco móvil en ventanas amplias, ancho adaptable en móvil |

## Aplicación móvil objetivo

- El iPhone realiza búsqueda, descarga, almacenamiento y reproducción; no depende de un Mac, servidor propio o conversor externo para su uso cotidiano.
- El Mac solo participa en desarrollo, compilación e instalación personal. Offline y controles nativos forman parte del cierre solicitado, no de una entrega online previa.
- Catálogo remoto con disponibilidad de descarga clara.
- Descargas con progreso, cancelación, reintento y validación.
- Reproducción en modo avión después de reiniciar la app.
- Biblioteca, carátulas y metadatos locales.
- Audio en segundo plano, bloqueo y controles del sistema.
- Interrupciones, llamadas y auriculares gestionados correctamente.
- Gestión avanzada de colecciones y administración del espacio ocupado. Los álbumes personales básicos ya existen.

El [Diseño de iPhone autónomo](diseno-iphone-autonomo.md) es la referencia aprobada para implementar; su aceptación real se registra por separado en [Validación](validacion.md).

## Fuera del prototipo 0.5 (histórico)

Búsqueda global, descargas reales, extracción de YouTube, cuentas, sincronización, letras, ecualizador, CarPlay y controles de bloqueo. El catálogo actual contiene seis enlaces reales y canciones importadas. No presentar las funciones pendientes como implementadas.

La instalación personal iOS requiere firma y herramientas de Apple. Validación web no equivale a validación móvil. Un teléfono completamente apagado no reproduce audio.
