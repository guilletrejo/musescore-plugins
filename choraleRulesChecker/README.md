# Chorale Rules Checker (Bach style) — for MuseScore Studio 4

*(Versión en español: [README.es.md](README.es.md))*

**Chorale Rules Checker** is a MuseScore plugin that detects not only **parallel
fifths and octaves**, but a configurable set of **harmony and voice-leading
rules** from the chorale style taught in conservatories.

Each rule can be **toggled on/off individually** and carries a **bibliographic
reference** (shown as a *tooltip* in the dialog, and listed in the table below).
The UI is **bilingual (English / Spanish)**.

> Derivative of [Parallel Intervals Checker](https://github.com/christianhofmanncodes/musescore-plugins)
> by **Christian Hofmann** (itself inspired by
> [checkParallels](https://github.com/heuchi/checkParallels) by *heuchi*).
> License: **GPLv3**.

---

## Features

- **20 rules** grouped into 6 categories (see table).
- Every rule has its own **toggle** and its **bibliographic citation** in a tooltip.
- **Melodic, vertical and harmonic analysis**: unlike the original plugin (which
  only compares voice pairs melodically using the top note of each chord), this
  one identifies the **chord**, its **root/3rd/5th/7th**, the **inversion** and
  the **scale degree** (I, IV, V…) relative to the key.
- **Key**: auto-detected from the key signature (assumes major); the **tonic and
  mode** (major/minor) can be overridden manually in the dialog.
- **Marking**: colors the notes involved and adds a staff text with the rule's
  short name. **Only color**, **dry run** (no markings) and **clean previous
  markings** modes available.
- **Bilingual UI** (English / Spanish), switchable in the dialog.

---

## Installation

1. Clone or download this repository.
2. Copy the **whole** `choraleRulesChecker/` folder into your MuseScore plugins
   folder (`Preferences > Folders > Plugins`, e.g. `~/Documents/MuseScore4/Plugins/`).
3. Open MuseScore Studio 4 and enable the plugin under `Home > Plugins`.
4. It will appear in `Plugins > Composition and Arranging Tools`.

---

## Usage

1. Open an **SATB** chorale (4 voices, on 4 staves or on 2 staves with 2 voices each).
2. Run the plugin. The settings dialog opens:
   - **Language**: English / Spanish.
   - **Key**: leave on *Auto* or correct the tonic/mode.
   - Toggle the rules you want (hover to read the reference).
   - Choose marking options (only color / dry run / clean previous).
3. Confirm. The plugin colors and labels the violations and shows a summary.

---

## Rules and bibliographic references

Categories **A–C** (melodic / voice-leading) are **on** by default. Categories
**D–F** rely on harmonic analysis (more prone to false positives) and are **off**
by default.

| Rule | Cat. | Default | Reference |
|------|------|---------|-----------|
| Parallel perfect fifths | A · Motion | ON | Zamacois, *Tratado de armonía* (forbidden motions); Piston, *Harmony*; Fux, *Gradus ad Parnassum* |
| Parallel octaves | A | ON | Zamacois, *Tratado de armonía*; Piston, *Harmony*; Fux, *Gradus ad Parnassum* |
| Parallel unisons | A | ON | Piston, *Harmony*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Hidden (direct) fifths/octaves | A | ON | Piston, *Harmony* (hidden/direct 5ths & 8ths); Zamacois, *Tratado de armonía* |
| Fifths/octaves by contrary motion | A | ON | Aldwell & Schachter, *Harmony and Voice Leading*; Piston, *Harmony* |
| Voice crossing | B · Spacing | ON | Piston, *Harmony*; Kostka & Payne, *Tonal Harmony* |
| Voice overlap | B | ON | Aldwell & Schachter, *Harmony and Voice Leading*; Kostka & Payne, *Tonal Harmony* |
| Spacing > octave between adjacent upper voices (S-A, A-T) | B | ON | Zamacois, *Tratado de armonía* (spacing); Kostka & Payne, *Tonal Harmony* |
| SATB range exceeded | B | ON | Kostka & Payne, *Tonal Harmony* (vocal ranges); Aldwell & Schachter, *Harmony and Voice Leading* |
| Melodic augmented 2nd (6-7 in minor) | C · Melodic | ON | Zamacois, *Tratado de armonía* (melodic intervals); De la Motte, *Harmony*; Schoenberg, *Theory of Harmony* |
| Augmented/diminished melodic leaps (aug4, dim5, 7th) | C | ON | Fux, *Gradus ad Parnassum* / Jeppesen, *Counterpoint*; Piston, *Harmony* |
| Large melodic leaps (> octave) | C | ON | Fux, *Gradus ad Parnassum*; Piston, *Harmony* (melodic line) |
| Doubled 3rd in major chords (I, IV, V) | D · Doublings | OFF | Zamacois, *Tratado de armonía* (doublings); Piston, *Harmony* (doubling) |
| Doubled leading tone (forbidden) | D | OFF | Piston, *Harmony*; Kostka & Payne, *Tonal Harmony*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Doubled chordal 7th | D | OFF | Piston, *Harmony* (seventh chords); Kostka & Payne, *Tonal Harmony* |
| Root-position chord without a doubled root (informational) | D | OFF | Zamacois, *Tratado de armonía* (preferred doublings) |
| Leading-tone resolution (up to tonic in V→I; outer voices) | E · Resolutions | OFF | Piston, *Harmony*; Kostka & Payne, *Tonal Harmony*; Aldwell & Schachter, *Harmony and Voice Leading* |
| Seventh resolution (steps down by a 2nd) | E | OFF | Piston, *Harmony* (dominant seventh); Kostka & Payne, *Tonal Harmony* |
| Dissonance preparation (**non**-dominant sevenths) | E | OFF | Jeppesen, *Counterpoint*; Schenker. *(The dominant seventh does NOT require preparation.)* |
| Incomplete chord (missing 3rd) | F · Completeness | OFF | Piston, *Harmony*; Kostka & Payne, *Tonal Harmony* |

> **Note on citations:** these are given at the author/work/topic level. The exact
> page or paragraph number varies by edition; verify it in your own copy. Common
> reference editions: Joaquín **Zamacois**, *Tratado de armonía*; Diether **de la
> Motte**, *Harmony* / *Armonía*; Walter **Piston**, *Harmony*; **Aldwell &
> Schachter**, *Harmony and Voice Leading*; **Kostka & Payne**, *Tonal Harmony*;
> Arnold **Schoenberg**, *Theory of Harmony*; J. J. **Fux**, *Gradus ad Parnassum*
> / Knud **Jeppesen**, *Counterpoint*.

---

## Limitations (important)

- **Chord and key identification is heuristic.** Passing tones, suspensions,
  appoggiaturas or non-strict-chorale textures can produce **false positives**.
  That is why the harmonic rules (D–F) are off by default — enable them with
  judgment.
- Automatic key detection from the signature **assumes major mode** (the key
  signature does not distinguish a major key from its relative minor). For
  exercises in **minor**, set the mode manually in the dialog.
- The **top note of each voice/chord** is analyzed (chorales are monophonic per
  voice). Divisi within a single voice are not fully analyzed.
- **Leading-tone** resolution is checked only in **outer voices** (soprano and
  bass), where the rule is strict; in inner voices it is usually relaxed.

---

## Tests

The pure music-theory logic (intervals, TPC-based spelling, chord identification,
scale degrees, doublings, parallel motion) lives in `choraleRulesLogic.js` and is
tested with Node, without MuseScore:

```bash
node choraleRulesChecker/test/logic.test.js
```

---

## License and credits

GPLv3. A **modified and extended** version of the *Parallel Intervals Checker* by
**Christian Hofmann**, inspired by *checkParallels* by **heuchi**. The terms of
the original license are preserved.
