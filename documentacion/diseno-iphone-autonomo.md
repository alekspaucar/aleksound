# Diseño propuesto: Aleksound autónomo en iPhone

Fecha: 9 de octubre de 2026. Diseño de referencia; **construcción autorizada por el usuario**. No certifica cada detalle como implementado. El código concreto usa Swift/MediaPlayer y está descrito en [versión 0.6](version-0.6-iphone.md); su validación extremo a extremo sigue pendiente.

## 1. Decisión confirmada

Erick quiere buscar, descargar, organizar y escuchar desde el iPhone. El Mac se usa para desarrollar, compilar y efectuar la instalación personal; no participa en las descargas ni en la reproducción cotidiana. No habrá un servidor propio, dirección del Mac, conversor web externo ni servicio de pago necesario para usar la app.

El cierre solicitado incluye audio real descargado, escucha en modo avión, segundo plano y controles de bloqueo. No basta con entregar el prototipo online. Primero iPhone; Android posteriormente. Se conserva Flutter, la marca Aleksound y la documentación en `documentacion/`.

## 2. Punto de partida y límite de esta propuesta

La versión 0.5 ya tiene enlaces reales, importación, reproducción visible de YouTube, álbumes, favoritos, historial, respaldo de metadatos y temas. No guarda audio remoto. No hay evidencia de compilación o reproducción nativa. Los resultados históricos de pruebas se consultan en [Validación](validacion.md), no se vuelven a atribuir a esta edición.

Esta propuesta define un único flujo móvil de extremo a extremo: **encontrar una versión → obtener audio → guardarlo → reproducirlo localmente con controles del sistema**. Sus componentes se separan para poder probarlos. El acceso al audio es el primer criterio de viabilidad: las demás capas no pueden sustituirlo con demos.

Quedan fuera cuentas, sincronización, suscripciones, publicidad, letras, ecualizador, CarPlay y publicación en tiendas. No son requisitos de este cierre. La web seguirá como vista previa online; no será la prueba del funcionamiento offline de iPhone.

## 3. Arquitectura elegida y alternativas descartadas

Se propone un proveedor ejecutado dentro de la app para búsqueda y resolución de streams públicos. La transferencia y los archivos pertenecen al iPhone; la reproducción utiliza un motor de audio nativo.

- Se descarta el ayudante en Mac: contradice la decisión confirmada.
- Se descarta un servidor remoto propio: añade infraestructura, coste y dependencia no solicitados.
- El iframe actual se conserva como ruta online visible para enlaces no descargados o fallos de resolución; no se convierte en un reproductor oculto ni se usa como supuesto archivo offline.

```text
Buscar / pegar enlace en el iPhone
                ↓
Proveedor de catálogo y resolución de audio
                ↓
Transferencia nativa → Archivo temporal → Validación
                                            ↓
                            Archivo local + metadatos + carátula
                                            ↓
                      Motor de audio → App / bloqueo / Centro de Control
```

## 4. Obtención de audio: propuesta y comprobación obligatoria

El candidato es `youtube_explode_dart` 3.1.0, cuya documentación describe búsqueda, metadatos y streams de audio. Algunos clientes requieren desafíos JavaScript. Que un paquete declare soporte iOS no demuestra una descarga en este proyecto. [Documentación del proveedor](https://pub.dev/packages/youtube_explode_dart).

Su interfaz `BaseEJSSolver` admite implementar un evaluador JavaScript distinto. La propuesta es un puente Swift hacia JavaScriptCore del iPhone, sin lanzar Deno, Node, Python o procesos del Mac. El resultado de esa integración sigue siendo una **hipótesis por verificar**, no una capacidad confirmada. [Interfaz del solucionador](https://github.com/Hexer10/youtube_explode_dart/blob/master/lib/src/reverse_engineering/challenges/ejs/base_ejs_solver.dart), [JSContext de Apple](https://developer.apple.com/documentation/javascriptcore/jscontext).

Los módulos auxiliares se fijarán a una versión, con integridad comprobada y licencias conservadas. El evaluador tendrá un contexto aislado sin objetos nativos que permitan acceder a archivos, credenciales o red; solicitudes identificadas y serializadas, límites de entrada y errores visibles. La evaluación se hará fuera del hilo de interfaz. Un timeout de la solicitud no se presentará como garantía de detener un script: la capacidad de recuperación del motor debe comprobarse en la validación técnica.

Antes de extender la interfaz se deberá demostrar en una app iOS: resolver una fuente pública accesible, recibir bytes de audio completos y reproducir el archivo sin red. También se comprobarán las seis versiones compartidas, informando resultados individuales. Una prueba en Dart sobre el Mac no confirma que el puente funcione en iPhone.

Si esa prueba falla, no se cambiará silenciosamente a un servidor, un catálogo de demos o una fuente distinta. Se conservará el prototipo y se informará del fallo concreto para revisar una solución que siga funcionando dentro del teléfono.

No se garantiza cualquier video: una versión privada, eliminada, protegida o que requiera acceso no soportado tendrá un estado explícito. No se incorporan credenciales, acceso a contenidos de pago ni descifrado DRM. Tampoco se cambia por otro remix sin elección del usuario.

## 5. Descubrimiento y catálogo

Buscar tendrá dos ámbitos distinguibles: **En internet** y **Mi biblioteca**. Internet consultará el proveedor por nombre de canción, artista o términos como phonk, C.R.O, remix y reguetón. Los resultados conservarán título, canal/artista declarado por la fuente, miniatura e ID; no se inventarán créditos ni popularidad.

Habrá carga, error con reintento, ausencia de resultados y paginación. Las respuestas de consultas antiguas no reemplazarán la búsqueda más reciente. Los accesos por género serán búsquedas explícitas, no un supuesto algoritmo de recomendaciones de YouTube Music.

Se mantiene pegar enlaces YouTube/YouTube Music y la identidad `youtube:<videoId>`. Encontrar metadatos no marca una canción como descargable o descargada. La disponibilidad de descarga solo se confirma al resolver una fuente compatible.

## 6. Formato y transferencia

Se prioriza audio AAC en contenedor M4A compatible con la reproducción nativa. Se conserva el audio disponible en ese formato, sin convertirlo obligatoriamente a MP3 ni renombrar un archivo incompatible. Si no existe una variante admitida, se informa de ello y permanece disponible la ruta online cuando funcione.

El descriptor resuelto contiene identidad de canción, URL temporal HTTPS, cabeceras necesarias, formato, tamaño esperado cuando la fuente lo facilite y caducidad cuando sea conocida. La URL temporal no es la identidad de la pista ni una copia de seguridad duradera.

La transferencia iOS propuesta utiliza `URLSession` con una sesión de fondo identificable. Se reconecta a tareas existentes al abrir la app. El sistema puede gestionar una transferencia cuando la app está suspendida, pero cerrarla a la fuerza puede cancelarla; no se promete continuidad en ese caso. [Sesiones de fondo de Apple](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:)).

Se procesa una descarga a la vez; el resto espera en una cola persistente. Un segundo toque no crea otra copia. Se ofrecen progreso real, cancelar y reintentar. La resolución de la URL comienza con la app activa; la continuidad de transferencia en segundo plano se valida por separado.

```text
En cola → Resolviendo → Descargando → Verificando → Descargada
               ↓             ↓             ↓
             Error      Cancelada/error   Error
```

Se comprueba espacio antes de empezar cuando el tamaño es conocido, reservando 50 MB adicionales. Con tamaño desconocido se muestra progreso indeterminado y se aplica un límite de 250 MB por archivo. El gestor comprueba también errores reales de escritura; la estimación de espacio no los elimina.

Una URL caducada se resuelve de nuevo para el mismo ID. La reanudación solo reutiliza bytes si el servidor y la identidad del recurso lo permiten; de lo contrario reinicia esa transferencia, sin concatenar fragmentos de versiones distintas. No hay reintentos infinitos: cada tarea admite dos automáticos por fallos transitorios y después requiere acción del usuario.

## 7. Archivos, índice y recuperación

Los archivos completos residen en el almacenamiento de soporte de la app, no exclusivamente en caché eliminable. Se usan nombres derivados de IDs, nunca rutas recibidas de la red. El índice guarda rutas relativas para tolerar cambios en el directorio de la instalación.

El componente nativo será el único escritor del índice de descargas y de sus archivos. Flutter consume instantáneas y eventos mediante un puente. El índice versionado registra ID, estado, identificador de tarea, ruta temporal/final, bytes, formato, duración y errores; se escribe con reemplazo atómico. Las preferencias actuales siguen conservando colecciones y ajustes, sin cargar audio en JSON.

La validación exige respuesta HTTP válida, tamaño no nulo, comprobación del tamaño esperado cuando exista y reconocimiento de una pista de audio con duración válida. Rechaza páginas HTML, archivos vacíos y formatos no admitidos. El archivo solo se mueve a su nombre final después de validar. El estado offline requiere índice coherente y archivo presente.

Al reiniciar se reconcilian índice, tareas y archivos: una tarea interrumpida puede reintentarse, un archivo final válido se recupera y un registro sin archivo vuelve a no descargado. Los temporales solo se limpian por tarea conocida; no se borra toda la biblioteca para corregir una inconsistencia.

La carátula se guarda por separado. Si falla su descarga, el audio válido se conserva, se informa del fallo y se muestra una imagen local de sustitución; se permite reintentar la carátula. Abrir una canción descargada sin internet no exige recuperar una imagen remota.

Eliminar una descarga borra únicamente su audio y los archivos locales que ya no tengan referencias; mantiene el enlace, favoritos y álbumes. Se pide confirmación, se detiene su reproducción si está activa y se informa de que el audio borrado requiere descargarse otra vez. El usuario ve espacio ocupado total y por canción. No hay purga automática de música descargada.

## 8. Reproducción y controles del sistema

Para una canción con archivo verificado, el motor elige el archivo local incluso con internet disponible. Nunca cae a red automáticamente si la selección está en modo «Solo descargadas». Una canción no disponible muestra el motivo; las colas offline filtran las no descargadas e indican cuántas se excluyeron.

Se propone un manejador único de audio con `just_audio`, `audio_service` y `audio_session`. App y sistema compartirán canción activa, cola, posición, pausa, anterior/siguiente, repetición y aleatorio. Título y carátula publicados deben corresponder al audio que realmente suena, no a una carga anterior. `audio_service` documenta integración con segundo plano y controles de bloqueo; esto exige implementación y pruebas propias. [Documentación de audio_service](https://pub.dev/packages/audio_service).

La sesión iOS se configura para música y segundo plano de audio. Se responde a llamadas/interrupciones, desconexión de auriculares y cambio de salida; no se reanuda después de una pausa manual ni se duplica el historial por reabrir la vista. Cerrar la pantalla del reproductor local no detiene la escucha.

El iframe online conserva el comportamiento visible del prototipo: cerrarlo pausa ese video. No publicará controles nativos como si su video fuera audio local. Los dos motores no deben sonar simultáneamente. Para escuchar esa versión con la pantalla bloqueada se necesita primero su archivo local válido.

Después de un cierre forzado se conserva la cola/posición para retomarla, pero no se promete reproducción continua mientras el proceso está cerrado. «Pantalla apagada» no significa teléfono completamente apagado.

## 9. Integración con la app y conservación de datos

Se mantienen Inicio con escuchas recientes, carátulas grandes, fondo difuminado, álbumes personales y temas blanco/negro que siguen el sistema. No se añade un banner promocional. Buscar tendrá resultados reales de internet y Biblioteca distinguirá **Enlaces guardados** de **Descargas**.

El botón de descarga cambia entre resolver, progreso/cancelar, completada y error/reintentar. La pantalla Descargas reúne cola, errores y espacio. Un corazón no inicia una descarga. Guardar un enlace no crea un archivo.

El cierre incluye nombre, icono y pantalla de inicio propios de Aleksound, sin identidad de ejemplo de Flutter; textos en español, áreas táctiles de al menos 44 puntos, etiquetas accesibles y comprobación con texto ampliado en claro y oscuro. Se evita un estado vacío sin explicación: Biblioteca vacía ofrece buscar o pegar un enlace.

No se cambian los IDs de las seis canciones ni se borran álbumes, archivados, favoritos o historial existentes. Las demos antiguas permanecen únicamente por compatibilidad y se identifican como contenido incluido; no cuentan como prueba de transferencia remota. La importación de respaldos v1 mantiene su validación actual y no marca pistas como descargadas si el archivo no existe en este iPhone.

## 10. Componentes propuestos y límites

| Componente | Responsabilidad y dependencia |
| --- | --- |
| Proveedor de catálogo | Buscar y consultar metadatos públicos; no escribe archivos |
| Resolver de audio | Obtener una fuente compatible para un ID; depende del proveedor y, si hace falta, del evaluador iOS |
| Puente JavaScript iOS | Evaluar expresiones del resolver en el teléfono; no expone acceso general al sistema |
| Gestor nativo de descargas | Transferir, validar, conservar índice y recuperar tareas; usa URLSession y almacenamiento iOS |
| Repositorio offline Flutter | Consultar estados/archivos y enviar acciones al gestor; no es un segundo escritor del índice |
| Manejador de audio | Reproducir el archivo local y coordinar controles del sistema; no descarga por su cuenta |
| Biblioteca actual | Mantener enlaces, álbumes, favoritos y tema; no certifica archivos mediante preferencias |
| Presentación | Mostrar búsqueda, biblioteca, estados y controles; observa los módulos, no realiza transferencia directamente |

Las interfaces transmitirán IDs y resultados explícitos, no excepciones nativas sin traducir. La resolución, la transferencia y la reproducción se invalidan mediante identidades/revisiones para que respuestas tardías no se atribuyan a otra canción.

## 11. Errores y privacidad

Mensajes distinguibles: sin conexión, video no disponible, audio incompatible, fallo de resolución, URL caducada, descarga interrumpida, archivo inválido y espacio insuficiente. Se ofrecen reintento, cancelar o abrir la versión original; nunca una sustitución musical silenciosa.

La app no necesita una cuenta propia ni almacena cookies o contraseñas de YouTube. No se registran URLs firmadas completas ni credenciales en documentación, respaldos o Git. Se validan HTTPS, dominios, redirecciones y tamaño de entradas. El contexto JavaScript no recibe secretos ni un puente de ejecución general.

Para una sesión offline, iniciar la app, mostrar biblioteca/carátulas locales y reproducir archivos no depende de consultar el proveedor. Los cambios externos del proveedor pueden afectar búsquedas y nuevas descargas; no deben romper archivos ya guardados.

## 12. Criterios para dar por terminado el cierre iPhone

| Comprobación | Resultado exigido |
| --- | --- |
| Descarga en iOS | Un enlace público real produce audio completo desde la app, sin ningún proceso o servidor en el Mac |
| Versiones del usuario | Se informa por separado del resultado de sus seis enlaces; no se inventa disponibilidad |
| Búsqueda global | Consultas de música elegida producen resultados reales fuera de la colección inicial, con errores y paginación |
| Modo avión | Descargar, cerrar, desactivar red, abrir y reproducir una canción completa y un álbum descargado |
| Biblioteca local | Metadatos y carátula descargada funcionan sin red; imagen local de sustitución ante ausencia de carátula |
| Interrupción de descarga | Cancelar/reintentar, URL caducada y reinicio no dejan un falso estado «Descargada» ni copias duplicadas |
| Transferencia de fondo | Cambiar de app/bloquear durante una transferencia y comprobar su estado al volver; documentar cierre forzado |
| Espacio y eliminación | Error de espacio visible; borrar audio recupera espacio sin perder álbumes/favoritos ni borrar otra canción |
| Audio de fondo | Escuchar archivo local al usar otra app y con pantalla bloqueada, manteniendo la cola correcta |
| Sistema | Bloqueo y Centro de Control muestran canción, imagen, progreso y controles sincronizados |
| Interrupciones | Comprobar llamada, desconexión de auriculares y cambio de salida sin reproducción inesperada |
| Migración | Biblioteca 0.5 y respaldos v1 conservan contenido; no confunden enlace, demo y descarga |
| Regresión | Análisis y pruebas del proyecto pasan; la vista previa web sigue funcionando con sus límites explícitos |
| Acabado móvil | Nombre/icono/inicio de Aleksound, estados vacíos y errores comprensibles; sin desbordamientos con texto ampliado en claro/oscuro |
| Xcode | Compilación de simulador correcta y apertura de la app; firma e instalación física verificadas aparte |
| Evidencia física | Modo avión, bloqueo, Centro de Control e interrupciones se verifican en el iPhone, no solo en Chrome |

El código puede quedar compilable antes de conectar el iPhone, pero no se declarará «probado en tu celular» sin esa prueba. La cuenta/equipo de firma y las confirmaciones de seguridad de Apple se completan con Erick; no se inventan ni se eligen silenciosamente.

## 13. Revisión e implementación posterior

La autonomía del iPhone está confirmada. Falta la revisión de este diseño escrito antes de preparar el plan detallado de implementación. No se han instalado los paquetes candidatos, creado puentes Swift, descargado audio ni comprobado los criterios nativos durante esta redacción.

El plan posterior debe comenzar por la viabilidad de obtención de audio en iOS, después continuar con almacenamiento y recuperación, reproducción/controles, integración de búsqueda y estados, y evidencia física. No se marcará el producto terminado por cerrar únicamente la documentación.

Referencias locales: [Visión](vision.md), [Requisitos](requisitos.md), [Arquitectura actual](arquitectura.md), [Plan de trabajo](plan-de-trabajo.md) y [Estado real](estado-del-proyecto.md).
