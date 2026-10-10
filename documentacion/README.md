# Documentación de Aleksound

Estos documentos describen lo que se quiere construir, lo que existe y cómo continuar. Se incluyen en GitHub; las instrucciones privadas de asistentes permanecen ignoradas.

## Empieza aquí

- Estado técnico actual: [iPhone 0.6.3](version-0.6-iphone.md), [barra/Descargas/portadas](ajustes-reproductor-biblioteca-portadas.md) y [corrección de duración](correccion-duracion-audio.md). Release instalada/abierta, siete descargas conservadas y portada de Chachachá recuperada. Gesto/imagen/Biblioteca y seis finales originales probados de nuevo; audición manual posterior pendiente. Las páginas 0.5 conservan el historial, no sustituyen este estado.

- Para saber qué funciona y qué falta: [Estado del proyecto](estado-del-proyecto.md).
- Para usar la app: [Guía de uso](guia-de-uso.md) e [Instalación](instalacion.md).
- Para cerrar Xcode y usar el iPhone: [Uso diario y firma personal](instalacion.md#usar-aleksound-sin-xcode). Release funciona sin la Mac; conservar modo desarrollador y renovar el perfil gratuito cuando venza, sin borrar la app.
- Para ubicar el código: [Estructura del proyecto](estructura-del-proyecto.md) y [Arquitectura](arquitectura.md).
- Para continuar el desarrollo: [Requisitos](requisitos.md), [Desarrollo](desarrollo.md) y [Plan de trabajo](plan-de-trabajo.md).
- Para revisar el cierre solicitado en iPhone: [Diseño autónomo de referencia](diseno-iphone-autonomo.md), meta aprobada; [plan de implementación](implementacion-iphone-autonomo.md) y [núcleo actual](version-0.6-iphone.md) distinguen código y aceptación.

## Estructura de documentación

```text
documentacion/
├── README.md                       Índice
├── estado-del-proyecto.md           Implementado, comprobado y pendiente
├── guia-de-uso.md                   Manual de uso
├── estructura-del-proyecto.md       Mapa del código y documentos
├── vision.md                       Propósito y decisiones
├── requisitos.md                   Funciones y aceptación
├── diseno.md                       Pantallas e identidad visual
├── arquitectura.md                 Componentes y datos
├── diseno-iphone-autonomo.md        Diseño aprobado de iPhone autónomo
├── implementacion-iphone-autonomo.md Tareas ejecutadas y aceptación pendiente
├── version-0.6-iphone.md            Núcleo actual, descargas probadas y límites
├── correccion-duracion-audio.md    Duración real, reparación y pruebas del final
├── ajustes-reproductor-biblioteca-portadas.md Barra inmediata y portada recuperable
├── instalacion.md                  Uso sin Xcode, firma y preparación de dispositivos
├── desarrollo.md                   Reglas y comprobaciones
├── youtube-online.md               Importación y reproducción online
├── catalogo-y-offline.md            Catálogo, descarga y antecedentes
├── albumes-historial-temas.md       Colecciones y apariencia
├── biblioteca-y-respaldo.md         Orden, archivados y copias de seguridad
├── plan-version-0.5.md              Alcance de esta ampliación
├── plan-de-trabajo.md               Etapas siguientes
├── github.md                       Versionado y publicación
├── validacion.md                   Evidencias y limitaciones
└── capturas/                       Imágenes de las versiones probadas
```

## Orden de lectura

1. [Visión](vision.md): objetivo y decisiones.
2. [Requisitos](requisitos.md): alcance y criterios de aceptación.
3. [Diseño](diseno.md): pantallas e interacción.
4. [Arquitectura](arquitectura.md): módulos y datos.
5. [Instalación](instalacion.md): cómo ejecutar la app.
6. [Desarrollo](desarrollo.md): instrucciones de trabajo y comprobación.
7. [Catálogo y offline](catalogo-y-offline.md): demos y descargas futuras.
8. [Plan de trabajo](plan-de-trabajo.md): evolución del producto.
9. [GitHub](github.md): repositorio y exclusiones.
10. [Validación](validacion.md): evidencias y limitaciones comprobadas.
11. [Álbumes, historial y temas](albumes-historial-temas.md): creación, reproducción e interfaz automática.
12. [YouTube online](youtube-online.md): catálogo real e importación de enlaces.
13. [Biblioteca y respaldo](biblioteca-y-respaldo.md): orden, archivo recuperable y restauración.
14. [Plan de la versión 0.5](plan-version-0.5.md): alcance de la ampliación.
15. [Diseño de iPhone autónomo](diseno-iphone-autonomo.md): referencia del cierre offline y nativo.
16. [Implementación iPhone](implementacion-iphone-autonomo.md): tareas y comprobaciones.
17. [Núcleo iPhone 0.6.3](version-0.6-iphone.md): funcionamiento actual, pruebas físicas y límites.
18. [Corrección de duración](correccion-duracion-audio.md): reempaquetado, migración segura y finales reales.
19. [Ajustes 0.6.3](ajustes-reproductor-biblioteca-portadas.md): barra/tiempo inmediatos, Descargas primero y portadas locales.

Actualizado el 9 de octubre de 2026. Release 0.6.3 instalada: [ajustes](ajustes-reproductor-biblioteca-portadas.md) y [núcleo actual](version-0.6-iphone.md). Una compilación no confirma descarga, sonido audible, offline o bloqueo: consultar las pruebas específicas y sus límites.

## Mantener estos documentos

Al cambiar una función, actualizar su documento específico y los requisitos afectados. Si cambia el alcance, actualizar estado y plan. Registrar en validación solo comprobaciones ejecutadas, con fecha y límites; no convertir una compilación web en evidencia de instalación móvil.

Usar enlaces relativos entre documentos, títulos claros y ejemplos sin secretos. No mover aquí instrucciones específicas de asistentes ni ignorar toda la documentación Markdown. Evitar repetir detalles técnicos: estructura ubica archivos; arquitectura explica responsabilidades; validación conserva evidencia.
