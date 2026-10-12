# Datos

## Archivo

`raw/superstore.csv`

| Campo | Valor |
|---|---|
| Dataset | Sample - Superstore |
| Descripción | Muestra ficticia que Tableau distribuye junto a Tableau Desktop |
| Copia utilizada | https://raw.githubusercontent.com/QuamiRay/Superstore-Exploratory-Analysis-Using-Power-BI/main/Sample%20-%20Superstore.csv |
| Fecha de descarga | 2026-10-12 |
| Tamaño | 2.287.806 bytes |
| SHA-256 | `58FB59C63089E564D835E4AABE19D371757DE1137A5BF1888243AE386C4B7A97` |
| Codificación | Windows-1252 (confirmado: el archivo **no** es UTF-8 válido) |
| Filas | 9.994, más el encabezado |
| Columnas | 21 |

## Verificación de integridad

El archivo se contrastó contra los valores conocidos del dataset canónico. Si en algún
momento estos números no se reproducen, el archivo fue alterado y el análisis no es válido.

| Control | Valor verificado |
|---|---|
| Ventas totales | 2.297.200,86 |
| Utilidad total | 286.397,02 |
| Pedidos únicos | 5.009 |
| Clientes únicos | 793 |
| Productos únicos | 1.862 |
| Rango de fechas | 2014-01-03 a 2017-12-30 |
| Categorías | Furniture, Office Supplies, Technology |
| Subcategorías | 17 |
| Regiones | Central, East, South, West |

## Cómo se descargó y cómo se verifica

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/QuamiRay/Superstore-Exploratory-Analysis-Using-Power-BI/main/Sample%20-%20Superstore.csv' -OutFile 'data/raw/superstore.csv'
Get-FileHash 'data/raw/superstore.csv' -Algorithm SHA256
```

El hash debe coincidir con el de la tabla de arriba. No basta con que el archivo exista.

## Reglas de esta carpeta

- El archivo de `raw/` **no se edita nunca**. Toda transformación vive en `sql/`.
- El CSV está declarado como `-text` en `.gitattributes`, así que git no toca sus fines de
  línea. Sin esa regla, git convierte CRLF a LF al versionar, el archivo guardado en el
  repositorio deja de ser idéntico al descargado y el hash de la tabla de arriba pasa a ser
  falso. Comprobación: `git cat-file -s HEAD:data/raw/superstore.csv` debe devolver 2287806.
- Se versiona en el repositorio a propósito, para que cualquiera pueda reproducir el
  análisis sin depender de una descarga externa ni de una cuenta en un portal.
- Si se reemplaza el archivo, hay que actualizar el hash y volver a correr los controles.

## Licencia y salvedad

Los datos son ficticios. Tableau los distribuye como material de ejemplo con su producto y
sus términos de uso no autorizan explícitamente la redistribución; las copias públicas en
Kaggle no declaran licencia. Se incluye aquí por tratarse de material de práctica
ampliamente difundido, con la fuente declarada y sin fines comerciales. Si este repositorio
se reutilizara con fines comerciales, habría que reemplazar la fuente o pedir autorización.
Esta salvedad se documenta en vez de omitirse: declarar la procedencia y los límites de un
dato externo es parte del trabajo.
