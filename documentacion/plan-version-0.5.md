# Plan de la versión 0.5

Fecha: 8 de octubre de 2026. Ampliación solicitada mientras se prepara Xcode.

## Alcance

1. Buscar álbumes, canciones guardadas y favoritos en Biblioteca; ordenar por nombre o por orden de colección.
2. Editar el orden de canciones del álbum sin perder selecciones anteriores. La cola de una reproducción nueva debe seguir ese orden.
3. Archivar y recuperar álbumes de manera persistente. No borrar sus canciones ni alterar la cola que ya está sonando.
4. Copiar una copia de seguridad de metadatos y restaurarla combinando con la biblioteca actual, sin borrar colecciones.
5. Actualizar documentación, verificar en web y registrar el avance en JARVIS.

## Diseño

Mantener las paletas existentes: fondo claro `#FAFAFA`, superficie `#F0F0F0`, texto `#171717`; fondo oscuro `#101010`, superficie `#202020`, texto `#F5F5F5`. Tipografía actual con títulos y listas alineados a la izquierda. Las carátulas aportan el color.

Biblioteca tendrá búsqueda bajo sus filtros y un menú de orden. En el editor, separar canciones seleccionadas (con controles de orden) de canciones disponibles. Archivados y respaldo se abrirán desde un menú de Biblioteca. Mostrar operaciones con verbos claros y mensajes de resultado.

```text
Biblioteca / Crear álbum / Opciones
Álbumes · Guardadas · Favoritos
Buscar en Biblioteca          Orden
Colección filtrada

Editar álbum
Nombre
Orden de reproducción: seleccionadas / subir / bajar / quitar
Añadir canciones: búsqueda / selección
Guardar cambios
```

## Validación

Pruebas de persistencia para orden y archivo; pruebas de respaldo para versión, datos inválidos, combinación repetida y conservación de datos actuales. Prueba de interfaz para guardar el orden elegido. Análisis, suite completa, compilación web e inspección de flujos en pantalla móvil.

## Límites

El respaldo incluye enlaces, metadatos, álbumes, favoritos, historial y apariencia; no audio. Descargas, búsqueda global e integración nativa siguen según el plan general. No introducir una nueva fuente musical ni sustituir canciones sin elegir su enlace.

## Resultado

Funciones implementadas. Verificación final: análisis sin incidencias, 42 pruebas aprobadas y compilación web correcta. Revisión de protección de datos incorporada: límites del resultado combinado, reversión que continúa tras un error y escuchas serializadas con restauración. Los flujos web observados y sus límites se registran en [Validación](validacion.md); el manual está en [Biblioteca y respaldo](biblioteca-y-respaldo.md).
