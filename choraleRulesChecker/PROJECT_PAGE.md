# musescore.org project page — ready-to-paste text

When you add the project at https://musescore.org/en/project/add (project type:
**Plugin**), you can paste the text below. Remember to set **API compatibility**
to **4.x**, otherwise the plugin stays hidden for most users.

---

**Title:** Chorale Rules Checker

**Short summary / teaser:**
Checks Bach-chorale harmony and voice-leading rules — parallel fifths/octaves,
doublings, leading-tone and seventh resolution, augmented seconds, voice
crossing, spacing, ranges and more. Each rule is individually toggleable and
carries a bibliographic reference. Bilingual UI (English / Spanish).

**Body:**

Chorale Rules Checker extends the classic parallel-intervals check into a full
set of harmony and voice-leading rules from the chorale style taught in
conservatories.

It does not just compare voice pairs melodically: it collects all four voices,
identifies the chord (root, third, fifth, seventh, inversion) and the scale
degree (I, IV, V…) relative to the key, so it can check genuine harmonic rules.

**20 rules in 6 categories**, each with its own on/off toggle and a bibliographic
reference shown as a tooltip:

- **Parallel / direct motion** — parallel fifths, octaves and unisons, hidden
  (direct) fifths/octaves, perfect intervals reached by contrary motion.
- **Voice spacing & layout** — voice crossing, voice overlap, spacing over an
  octave between adjacent upper voices, SATB range checks.
- **Melodic line** — augmented seconds (e.g. 6–7 in minor), augmented/diminished
  leaps (aug4, dim5, 7th), large leaps.
- **Doublings** — doubled third in major chords (I, IV, V), doubled leading tone
  (forbidden), doubled seventh, root-position chord without a doubled root.
- **Resolutions** — leading-tone resolution (up to the tonic), seventh
  resolution (down by step), preparation of non-dominant sevenths.
- **Chord completeness** — incomplete chord (missing third).

Melodic and voice-leading rules are on by default. The rules that depend on
harmonic analysis are off by default (chord/key recognition is heuristic and can
produce false positives — enable them with judgment). The key is auto-detected
from the key signature and can be overridden manually (tonic + major/minor).

Violations are highlighted by coloring the notes and adding a short staff text.
Modes: only-color, dry-run, and clean previous markings before running.

References include Zamacois (*Tratado de armonía*), De la Motte, Piston, Aldwell &
Schachter, Kostka & Payne, Schoenberg, and Fux / Jeppesen.

**Compatibility:** MuseScore Studio 4.x

**License:** GPLv3. This is a modified and extended version of the *Parallel
Intervals Checker* by Christian Hofmann, itself inspired by *checkParallels* by
heuchi. The original license is preserved.

**Source code / download:** https://github.com/guilletrejo/musescore-plugins
(folder `choraleRulesChecker/`)
