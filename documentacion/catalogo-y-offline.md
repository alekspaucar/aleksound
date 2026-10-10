# Catálogo y offline

## Actualización iPhone 0.6.1

Existe búsqueda remota y gestor de archivos reales. Solo el índice nativo y un archivo completo verificado habilitan offline; guardar un enlace sigue sin descargar. Se descargaron y reprodujeron las seis versiones originales en iPhone, con carátulas locales. Modo avión real y controles físicos siguen pendientes. [Detalle actual](version-0.6-iphone.md). Las secciones siguientes registran la base del prototipo y sus criterios.

## Antecedente del prototipo web

El prototipo 0.4 usa seis enlaces reales de YouTube como colección principal e importa otros enlaces con oEmbed. Reproducción online con el reproductor visible, no descarga. El buscador filtra la colección; no busca todo YouTube. Consulta [YouTube online](youtube-online.md).

### Demos anteriores

Seis fichas de demostración y tres audios sintéticos originales de 24 segundos; nombres de artistas ficticios y carátulas propias. Guardar una demo conserva un ID. El archivo viene incluido; no se descarga de internet. Quitar la ficha no elimina el asset del paquete.

La instalación móvil incluye los assets. La web los sirve desde la aplicación; puede necesitar red para cargar o recargar. No hay caché persistente de audio ni garantía offline tras cerrar Chrome.

## Contrato de proveedor

Cada resultado debe ofrecer ID, título, artista, duración, imagen, fuente y condiciones. Para descargar debe ofrecer un recurso de audio válido y metadatos de tipo/tamaño. Una URL a una página de video no es una URL de audio.

Fuentes autorizadas o URLs directas pueden alimentar el catálogo. En web, el servidor también debe permitir CORS. Una pista no disponible offline puede guardarse como favorito o enlace; no se promete que todas las canciones comerciales estén disponibles.

## Descarga real

```text
Disponible → En cola → Descargando → Verificando → Disponible offline
                            ↓               ↓
                      Error / reintento   Error / limpieza
```

Archivo temporal, cancelación, reintento, control de espacio y validación. Solo un archivo completo habilita offline. Eliminar una descarga conserva favoritos y metadatos salvo petición explícita.

## Prueba de aceptación manual

Descargar, cerrar, activar modo avión, abrir y reproducir. Confirmar audio, carátula, cola y recuperación de transferencias interrumpidas. Esta garantía aún no corresponde al prototipo web.
