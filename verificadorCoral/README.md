# Verificador de Reglas de Coral (estilo Bach) — para MuseScore Studio 4

**Verificador de Reglas de Coral** es un plugin de MuseScore que detecta no solo
**quintas y octavas paralelas**, sino un conjunto configurable de reglas de
**armonía y conducción de voces** del estilo de coral que se estudia en los
conservatorios.

Cada regla puede **activarse o desactivarse individualmente** y lleva su
**referencia bibliográfica** (visible como *tooltip* al pasar el mouse en el
diálogo, y listada en la tabla de abajo).

> Obra derivada de [Parallel Intervals Checker](https://github.com/christianhofmanncodes/musescore-plugins)
> de **Christian Hofmann** (a su vez inspirado en
> [checkParallels](https://github.com/heuchi/checkParallels) de *heuchi*).
> Licencia **GPLv3**.

---

## Características

- **20 reglas** agrupadas en 6 categorías (ver tabla).
- Cada regla con su **toggle** y su **cita bibliográfica** en tooltip.
- **Análisis melódico, vertical y armónico**: a diferencia del plugin original
  (que solo compara pares de voces melódicamente y usa la nota superior de cada
  acorde), este identifica el **acorde**, su **fundamental/3ª/5ª/7ª**, la
  **inversión** y el **grado** (I, IV, V…) respecto de la tonalidad.
- **Tonalidad**: se detecta automáticamente desde la armadura (asume Mayor); se
  puede **corregir manualmente** la tónica y el modo (Mayor/menor) en el diálogo.
- **Marcado**: colorea las notas implicadas y agrega un texto de pauta con el
  nombre abreviado de la regla. Modos **solo color**, **dry run** (sin marcas) y
  **limpieza previa** de marcas anteriores.

---

## Instalación

1. Cloná o descargá este repositorio.
2. Copiá la carpeta `verificadorCoral/` **completa** a tu carpeta de plugins de
   MuseScore (`Configuración > Carpetas > Plugins`, p. ej.
   `~/Documents/MuseScore4/Plugins/`).
3. Abrí MuseScore Studio 4 y activá el plugin en `Inicio > Plugins`.
4. Aparecerá en el menú `Plugins > Composition and Arranging Tools`.

---

## Uso

1. Abrí un coral **SATB** (4 voces, en 4 pentagramas o en 2 con 2 voces cada uno).
2. Ejecutá el plugin. Se abre el diálogo de configuración:
   - **Tonalidad**: dejá *Auto* o corregí tónica/modo.
   - Activá/desactivá las reglas que quieras (pasá el mouse para ver la referencia).
   - Elegí opciones de marcado (solo color / dry run / limpieza previa).
3. Aceptá. El plugin colorea y marca las infracciones y muestra un resumen.

---

## Reglas y referencias bibliográficas

Las categorías **A–C** (melódico / conducción de voces) vienen **activadas** por
defecto. Las categorías **D–F** dependen del análisis armónico (más sensible a
falsos positivos) y vienen **desactivadas** por defecto.

| Regla | Cat. | Default | Referencia |
|-------|------|---------|------------|
| Quintas justas paralelas | A · Movimiento | ON | Zamacois, *Tratado de armonía* (movimientos prohibidos); Piston, *Armonía*; Fux, *Gradus ad Parnassum* |
| Octavas paralelas | A | ON | Zamacois, *Tratado de armonía*; Piston, *Armonía*; Fux, *Gradus ad Parnassum* |
| Unísonos paralelos | A | ON | Piston, *Armonía*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Quintas/octavas ocultas (directas) | A | ON | Piston, *Armonía* (hidden/direct 5ths & 8ths); Zamacois, *Tratado de armonía* |
| Quintas/octavas por movimiento contrario | A | ON | Aldwell & Schachter, *Harmony and Voice Leading*; Piston, *Armonía* |
| Cruce de voces | B · Disposición | ON | Piston, *Armonía*; Kostka & Payne, *Tonal Harmony* |
| Superposición (overlap) de voces | B | ON | Aldwell & Schachter, *Harmony and Voice Leading*; Kostka & Payne, *Tonal Harmony* |
| Distancia > 8ª entre voces adyacentes superiores (S-A, A-T) | B | ON | Zamacois, *Tratado de armonía* (disposición); Kostka & Payne, *Tonal Harmony* (spacing) |
| Tessitura SATB excedida | B | ON | Kostka & Payne, *Tonal Harmony* (vocal ranges); Aldwell & Schachter, *Harmony and Voice Leading* |
| Salto melódico de 2ª aumentada (6-7 en menor) | C · Melódica | ON | Zamacois, *Tratado de armonía* (intervalos melódicos); De la Motte, *Armonía*; Schoenberg, *Tratado de armonía* |
| Saltos melódicos aumentados/disminuidos (4ªaum., 5ªdism., 7ª) | C | ON | Fux, *Gradus ad Parnassum* / Jeppesen, *Counterpoint*; Piston, *Armonía* |
| Saltos melódicos grandes (> 8ª) | C | ON | Fux, *Gradus ad Parnassum*; Piston, *Armonía* (línea melódica) |
| Duplicación de la 3ª en acordes mayores (I, IV, V) | D · Duplicaciones | OFF | Zamacois, *Tratado de armonía* (duplicaciones); Piston, *Armonía* (doubling) |
| Duplicación de la sensible (prohibido) | D | OFF | Piston, *Armonía*; Kostka & Payne, *Tonal Harmony*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Duplicación de la 7ª del acorde | D | OFF | Piston, *Armonía* (acordes de séptima); Kostka & Payne, *Tonal Harmony* |
| Estado fundamental sin duplicar la fundamental (informativa) | D | OFF | Zamacois, *Tratado de armonía* (duplicaciones preferentes) |
| Resolución de la sensible (sube a la tónica en V→I; voces extremas) | E · Resoluciones | OFF | Piston, *Armonía*; Kostka & Payne, *Tonal Harmony*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Resolución de la 7ª (desciende por grado conjunto) | E | OFF | Piston, *Armonía* (séptima de dominante); Kostka & Payne, *Tonal Harmony* |
| Preparación de la disonancia (séptimas **no** dominantes) | E | OFF | Jeppesen, *Counterpoint*; Schenker. *(La 7ª de dominante NO requiere preparación.)* |
| Acorde incompleto (falta la 3ª) | F · Completitud | OFF | Piston, *Armonía*; Kostka & Payne, *Tonal Harmony* |

> **Nota sobre las citas:** se indican a nivel de autor/obra/tema. El número exacto
> de página o parágrafo varía según la edición; conviene verificarlo en tu
> ejemplar. Ediciones de referencia habituales en conservatorios hispanohablantes:
> Joaquín **Zamacois**, *Tratado de armonía* (Labor / Idea Música); Diether **de la
> Motte**, *Armonía* (Idea Books / Labor); Walter **Piston**, *Armonía* (SpanPress /
> Labor); **Aldwell & Schachter**, *Harmony and Voice Leading* (Cengage); **Kostka &
> Payne**, *Tonal Harmony* (McGraw-Hill); Arnold **Schoenberg**, *Tratado de armonía*
> (Real Musical); J. J. **Fux**, *Gradus ad Parnassum* / Knud **Jeppesen**,
> *Counterpoint*.

---

## Limitaciones (importante)

- La **identificación de acorde y tonalidad es heurística**. Notas de paso,
  retardos/suspensiones, apoyaturas o texturas no estrictamente corales pueden
  generar **falsos positivos**. Por eso las reglas armónicas (D–F) vienen
  desactivadas por defecto: actívalas con criterio.
- La detección automática de tonalidad desde la armadura **asume modo Mayor**
  (la armadura no distingue Mayor de su relativa menor). Para ejercicios en
  **menor**, fijá el modo manualmente en el diálogo.
- Se analiza la **nota superior de cada voz/acorde** (el coral es monofónico por
  voz). Divisi dentro de una misma voz no se analizan completamente.
- La resolución de la **sensible** se chequea solo en **voces extremas** (soprano
  y bajo), donde la regla es estricta; en voces internas suele relajarse.

---

## Tests de la lógica

La lógica musical pura (intervalos, grafía con TPC, identificación de acordes,
grados, duplicaciones, movimiento paralelo) está en `verificadorCoralLogic.js` y
se testea con Node, sin necesidad de MuseScore:

```bash
node verificadorCoral/test/logic.test.js
```

---

## Licencia y créditos

GPLv3. Versión **modificada y extendida** del *Parallel Intervals Checker* de
**Christian Hofmann**, inspirado en *checkParallels* de **heuchi**. Se conservan
los términos de la licencia original.
