# Biblioteca y respaldo — versión 0.5

## Buscar y ordenar

Biblioteca conserva las secciones Álbumes, Guardadas y Favoritos. El campo de búsqueda filtra la sección actual y permite limpiar la consulta. El menú de orden ofrece Colección y Nombre; las canciones también ofrecen Artista. Estos filtros se conservan mientras la app está abierta, no como un ajuste persistente.

La búsqueda ignora mayúsculas y acentos, igual que el buscador general. Solo consulta contenido de la biblioteca actual.

## Elegir el orden del álbum

Abre **Editar álbum**. Las canciones seleccionadas aparecen en **Orden de reproducción** con acciones Subir, Bajar y Quitar. Debajo puedes buscar y añadir otras canciones; se añaden al final. Guarda para conservar el orden.

Una reproducción nueva del álbum usa ese orden. La cola que ya está sonando conserva su selección anterior hasta iniciar de nuevo el álbum. Referencias de canciones temporalmente no disponibles se conservan al editar, y pueden retirarse expresamente.

## Archivar y recuperar

El menú de cada álbum y su pantalla ofrecen **Archivar álbum**. Sale de la colección activa, pero conserva identidad, nombre y canciones. En **Opciones de biblioteca → Archivados** puedes recuperarlo. No hay eliminación permanente en esta versión.

Los álbumes archivados también reservan su nombre para evitar duplicados al recuperarlos. Se incluyen en la copia de seguridad. Las preferencias antiguas sin el campo `archived` se interpretan como álbumes activos.

## Crear una copia

1. Abre **Biblioteca → Opciones de biblioteca → Copia de seguridad**.
2. En **Crear copia**, pulsa **Copiar respaldo**.
3. Guarda el texto completo en tus notas o en un archivo.

La copia contiene metadatos de importaciones, IDs de favoritos y enlaces guardados, álbumes (con orden y estado de archivo), historial y apariencia. Las seis fichas iniciales siguen formando parte del catálogo de la app. No incluye audio ni descarga canciones. Copiar no guarda un archivo automáticamente.

## Restaurar

1. Abre **Restaurar** y pega el texto completo de una copia.
2. Pulsa **Comprobar copia** para validar formato y ver las cantidades.
3. Pulsa **Combinar con mi biblioteca**.

La restauración combina con el contenido actual. No borra colecciones ni favoritos. Mismo video: conserva sus metadatos locales. Mismo ID de álbum: conserva nombre y estado local, y añade canciones faltantes al final. Distinto ID y mismo nombre: añade un sufijo numérico. Historial local primero, sin duplicados, hasta veinte IDs. Conserva el tema elegido localmente; si aún no existe esa preferencia, usa el de la copia.

Se admite el formato `aleksound-library`, versión 1. Se validan tanto la copia entrante como la biblioteca combinada antes de escribir. Se limita a dos millones de caracteres y cinco mil elementos por lista: si la combinación supera estos límites, se rechaza sin truncar tus colecciones. Las escuchas que llegan durante la restauración se registran después, en orden, para no sobrescribir el historial.

Ante un fallo de escritura se intenta restaurar los valores anteriores; un error al recuperar una preferencia no impide intentar las demás. Si no se consigue, se informa de una restauración incompleta. La escritura de varias preferencias no es una transacción del sistema ni garantiza recuperación si el proceso se cierra en medio de la operación.

No hay sincronización automática: para llevar tus colecciones a otro navegador u origen debes copiar y restaurar. Para escuchar sus enlaces sigue siendo necesaria conexión y disponibilidad del reproductor.
