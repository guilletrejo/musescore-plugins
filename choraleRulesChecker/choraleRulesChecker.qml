import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import MuseScore 3.0
import Muse.UiComponents 1.0

import "choraleRulesLogic.js" as Logic

// =============================================================================
// Chorale Rules Checker (Bach style)
//
// Derivative of "Parallel Intervals Checker" by Christian Hofmann
// (https://github.com/christianhofmanncodes/musescore-plugins), itself inspired
// by checkParallels by heuchi. License: GPLv3.
//
// Extends the original plugin (parallel fifths/octaves) with a configurable set
// of chorale-style harmony and voice-leading rules. Each rule can be toggled on
// and off and carries a bibliographic reference (shown as a tooltip in the
// dialog and listed in the README). Bilingual UI: English / Spanish.
// =============================================================================

MuseScore {
      version: "1.1"
      title: "Chorale Rules Checker"
      description: "Checks parallel fifths/octaves plus a configurable set of Bach-chorale harmony and voice-leading rules (doublings, leading-tone and seventh resolution, augmented 2nd, voice crossing, spacing, ranges, etc.). Each rule can be toggled and carries a bibliographic reference. Bilingual UI (EN/ES)."
      categoryCode: "composing-arranging-tools"
      thumbnailName: "logo.png"
      requiresScore: true
      pluginType: "dialog"

      implicitHeight: 660
      implicitWidth: 480

      id: checker

      // --- Language: "en" (default) or "es" ---
      property string lang: "en"

      // --- Marking / execution ---
      property bool onlyColor: false
      property bool dryRun: false
      property bool cleanupBeforeRun: true
      readonly property string sentinel: "» "   // prefix for text markings

      // --- Key ---
      property int  scoreKeySig: 0          // accidentals read from the score
      property int  tonicOverride: -1       // -1 = auto (from key signature)
      property string modeOverride: "major" // "major" | "minor"

      // --- Results ---
      property var findingCounts: ({})
      property var ruleById: ({})
      property var ruleColor: ({})

      // Returns the value for the current language.
      function tr(en, es) { return lang === "en" ? en : es; }

      // --- UI strings ---
      readonly property var STR: ({
            "en": {
                  dialogTitle: "Chorale Rules Checker — Settings",
                  hint: "Hover each rule to see its bibliographic reference.",
                  language: "Language:",
                  key: "Key", tonic: "Tonic:", mode: "Mode:",
                  auto: "Auto (key signature)", major: "Major", minor: "minor",
                  marking: "Marking",
                  onlyColor: "Only color notes (no text)",
                  dryRun: "No markings (dry run)",
                  cleanup: "Clean previous markings before running",
                  noNotes: "No notes found to analyze.",
                  noFindings: "No violations of the active rules were found!",
                  findings: "finding(s):",
                  dryNote: "(Dry run: no markings were applied.)"
            },
            "es": {
                  dialogTitle: "Verificador de Reglas de Coral — Configuración",
                  hint: "Pasá el mouse sobre cada regla para ver su referencia bibliográfica.",
                  language: "Idioma:",
                  key: "Tonalidad", tonic: "Tónica:", mode: "Modo:",
                  auto: "Auto (armadura)", major: "Mayor", minor: "menor",
                  marking: "Marcado",
                  onlyColor: "Solo colorear notas (sin texto)",
                  dryRun: "Sin marcas (dry run)",
                  cleanup: "Limpiar marcas previas antes de ejecutar",
                  noNotes: "No se encontraron notas para analizar.",
                  noFindings: "¡No se encontraron infracciones de las reglas activas!",
                  findings: "hallazgo(s):",
                  dryNote: "(Dry run: no se aplicaron marcas.)"
            }
      })
      function S(k) { return STR[lang][k]; }

      // --- Category titles ---
      readonly property var CATEGORIES: ({
            "A": { en: "A · Parallel / direct motion",            es: "A · Movimiento paralelo / directo" },
            "B": { en: "B · Voice spacing & layout",              es: "B · Disposición de voces" },
            "C": { en: "C · Melodic line",                        es: "C · Línea melódica" },
            "D": { en: "D · Doublings (harmonic analysis)",       es: "D · Duplicaciones (análisis armónico)" },
            "E": { en: "E · Resolutions (harmonic analysis)",     es: "E · Resoluciones (análisis armónico)" },
            "F": { en: "F · Chord completeness (harmonic analysis)", es: "F · Completitud del acorde (análisis armónico)" }
      })
      function catTitle(cat) { return tr(CATEGORIES[cat].en, CATEGORIES[cat].es); }

      // --- Rule definitions -----------------------------------------------------
      // Melodic / voice-leading rules (A,B,C) are on by default; rules that rely
      // on harmonic analysis (D,E,F) are off by default (heuristic).
      readonly property var RULES: [
            { id: "parallelFifths",  cat: "A", on: true,  color: "#FB8C00",
              en: "Parallel perfect fifths", es: "Quintas justas paralelas",
              cite: "Zamacois, Tratado de armonía (forbidden motions); Piston, Harmony; Fux, Gradus ad Parnassum." },
            { id: "parallelOctaves", cat: "A", on: true,  color: "#4285F4",
              en: "Parallel octaves", es: "Octavas paralelas",
              cite: "Zamacois, Tratado de armonía; Piston, Harmony; Fux, Gradus ad Parnassum." },
            { id: "parallelUnisons", cat: "A", on: true,  color: "#26A69A",
              en: "Parallel unisons", es: "Unísonos paralelos",
              cite: "Piston, Harmony; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "hiddenFifthsOctaves", cat: "A", on: true, color: "#AB47BC",
              en: "Hidden (direct) fifths/octaves — emphasis on outer voices",
              es: "Quintas/octavas ocultas (directas) — énfasis voces extremas",
              cite: "Piston, Harmony (hidden/direct fifths & octaves); Zamacois, Tratado de armonía." },
            { id: "fifthsContraryMotion", cat: "A", on: true, color: "#EC407A",
              en: "Fifths/octaves reached by contrary motion onto a perfect interval",
              es: "Quintas/octavas por movimiento contrario hacia intervalo perfecto",
              cite: "Aldwell & Schachter, Harmony and Voice Leading; Piston, Harmony." },

            { id: "voiceCrossing", cat: "B", on: true, color: "#7E57C2",
              en: "Voice crossing", es: "Cruce de voces",
              cite: "Piston, Harmony; Kostka & Payne, Tonal Harmony (voice leading)." },
            { id: "voiceOverlap", cat: "B", on: true, color: "#5C6BC0",
              en: "Voice overlap", es: "Superposición (overlap) de voces",
              cite: "Aldwell & Schachter, Harmony and Voice Leading; Kostka & Payne, Tonal Harmony." },
            { id: "spacingOverOctave", cat: "B", on: true, color: "#42A5F5",
              en: "Spacing over an octave between adjacent upper voices (S-A, A-T)",
              es: "Distancia mayor a 8ª entre voces adyacentes superiores (S-A, A-T)",
              cite: "Zamacois, Tratado de armonía (spacing); Kostka & Payne, Tonal Harmony (spacing)." },
            { id: "voiceRange", cat: "B", on: true, color: "#29B6F6",
              en: "SATB range exceeded", es: "Tessitura SATB excedida",
              cite: "Kostka & Payne, Tonal Harmony (vocal ranges); Aldwell & Schachter, Harmony and Voice Leading." },

            { id: "augmentedSecond", cat: "C", on: true, color: "#EF5350",
              en: "Melodic augmented 2nd (6-7 in minor)",
              es: "Salto melódico de 2ª aumentada (6-7 en modo menor)",
              cite: "Zamacois, Tratado de armonía (melodic intervals); De la Motte, Harmony; Schoenberg, Theory of Harmony." },
            { id: "augDimLeaps", cat: "C", on: true, color: "#FF7043",
              en: "Augmented/diminished melodic leaps (aug4, dim5, 7th)",
              es: "Saltos melódicos aumentados/disminuidos (4ªaum., 5ªdism., 7ª)",
              cite: "Fux, Gradus ad Parnassum / Jeppesen, Counterpoint; Piston, Harmony." },
            { id: "largeLeaps", cat: "C", on: true, color: "#FFA726",
              en: "Large melodic leaps (> octave)", es: "Saltos melódicos grandes (> 8ª)",
              cite: "Fux, Gradus ad Parnassum; Piston, Harmony (melodic line)." },

            { id: "doubledThird", cat: "D", on: false, color: "#66BB6A",
              en: "Doubled 3rd in major chords (I, IV, V)",
              es: "Duplicación de la 3ª en acordes mayores (I, IV, V)",
              cite: "Zamacois, Tratado de armonía (doublings); Piston, Harmony (doubling)." },
            { id: "doubledLeadingTone", cat: "D", on: false, color: "#9CCC65",
              en: "Doubled leading tone (forbidden)",
              es: "Duplicación de la sensible (prohibido)",
              cite: "Piston, Harmony; Kostka & Payne, Tonal Harmony; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "doubledSeventh", cat: "D", on: false, color: "#D4E157",
              en: "Doubled chordal 7th", es: "Duplicación de la 7ª del acorde",
              cite: "Piston, Harmony (seventh chords); Kostka & Payne, Tonal Harmony." },
            { id: "rootNotDoubled", cat: "D", on: false, color: "#C0CA33",
              en: "Root-position chord without a doubled root (informational)",
              es: "Estado fundamental sin duplicar la fundamental (informativa)",
              cite: "Zamacois, Tratado de armonía (preferred doublings)." },

            { id: "leadingToneResolution", cat: "E", on: false, color: "#FFCA28",
              en: "Leading-tone resolution (up to tonic in V→I; outer voices)",
              es: "Resolución de la sensible (sube a la tónica en V→I; voces extremas)",
              cite: "Piston, Harmony; Kostka & Payne, Tonal Harmony; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "seventhResolution", cat: "E", on: false, color: "#FFB300",
              en: "Seventh resolution (steps down by a 2nd)",
              es: "Resolución de la 7ª (desciende por grado conjunto)",
              cite: "Piston, Harmony (dominant seventh); Kostka & Payne, Tonal Harmony." },
            { id: "seventhPreparation", cat: "E", on: false, color: "#FF8F00",
              en: "Dissonance preparation (NON-dominant sevenths)",
              es: "Preparación de la disonancia (séptimas NO dominantes)",
              cite: "Jeppesen, Counterpoint; Schenker. Note: the dominant seventh does NOT require preparation." },

            { id: "incompleteChord", cat: "F", on: false, color: "#8D6E63",
              en: "Incomplete chord (missing 3rd)", es: "Acorde incompleto (falta la 3ª)",
              cite: "Piston, Harmony; Kostka & Payne, Tonal Harmony." }
      ]

      // =========================================================================
      // Setup
      // =========================================================================
      Component.onCompleted: {
            var byId = {}, col = {};
            for (var i = 0; i < RULES.length; i++) {
                  byId[RULES[i].id] = RULES[i];
                  col[RULES[i].id] = RULES[i].color;
            }
            ruleById = byId;
            ruleColor = col;
            populateModels();
      }

      // One ListModel per category to build the dialog dynamically.
      ListModel { id: modelA }
      ListModel { id: modelB }
      ListModel { id: modelC }
      ListModel { id: modelD }
      ListModel { id: modelE }
      ListModel { id: modelF }

      function modelFor(cat) {
            return cat === "A" ? modelA : cat === "B" ? modelB : cat === "C" ? modelC
                 : cat === "D" ? modelD : cat === "E" ? modelE : modelF;
      }

      function populateModels() {
            for (var i = 0; i < RULES.length; i++) {
                  var r = RULES[i];
                  modelFor(r.cat).append({
                        rid: r.id, nameEn: r.en, nameEs: r.es, cite: r.cite, enabled: r.on
                  });
            }
      }

      function isEnabled(ruleId) {
            var models = [modelA, modelB, modelC, modelD, modelE, modelF];
            for (var m = 0; m < models.length; m++) {
                  for (var i = 0; i < models[m].count; i++) {
                        var it = models[m].get(i);
                        if (it.rid === ruleId) return it.enabled;
                  }
            }
            return false;
      }

      // Inline component: a GroupBox with one checkbox per rule.
      component RuleGroup: GroupBox {
            property var ruleModel
            Layout.fillWidth: true
            ColumnLayout {
                  width: parent.width
                  Repeater {
                        model: ruleModel
                        delegate: CheckBox {
                              text: checker.lang === "en" ? nameEn : nameEs
                              checked: enabled
                              Layout.fillWidth: true
                              onToggled: ruleModel.setProperty(index, "enabled", checked)
                              ToolTip.visible: hovered
                              ToolTip.delay: 300
                              ToolTip.text: cite
                        }
                  }
            }
      }

      Dialog {
            id: settingsDialog
            title: checker.S("dialogTitle")
            modal: true
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
            visible: false
            width: 460
            height: 620

            ScrollView {
                  anchors.fill: parent
                  clip: true
                  contentWidth: availableWidth

                  ColumnLayout {
                        width: settingsDialog.width - 40
                        spacing: 8

                        RowLayout {
                              Label { text: checker.S("language") }
                              ComboBox {
                                    id: langCombo
                                    model: ["English", "Español"]
                                    currentIndex: 0
                                    onActivated: checker.lang = currentIndex === 0 ? "en" : "es"
                              }
                        }

                        Label {
                              text: checker.S("hint")
                              wrapMode: Text.WordWrap
                              font.italic: true
                              Layout.fillWidth: true
                        }

                        GroupBox {
                              title: checker.S("key")
                              Layout.fillWidth: true
                              ColumnLayout {
                                    RowLayout {
                                          Label { text: checker.S("tonic") }
                                          ComboBox {
                                                id: tonicCombo
                                                model: [checker.S("auto"), "C", "C#/Db", "D", "D#/Eb",
                                                        "E", "F", "F#/Gb", "G", "G#/Ab",
                                                        "A", "A#/Bb", "B"]
                                                currentIndex: 0
                                                onActivated: checker.tonicOverride = currentIndex === 0 ? -1 : currentIndex - 1
                                          }
                                    }
                                    RowLayout {
                                          Label { text: checker.S("mode") }
                                          ComboBox {
                                                id: modeCombo
                                                model: [checker.S("major"), checker.S("minor")]
                                                currentIndex: 0
                                                onActivated: checker.modeOverride = currentIndex === 0 ? "major" : "minor"
                                          }
                                    }
                              }
                        }

                        Label { text: checker.catTitle("A"); font.bold: true; Layout.topMargin: 4 }
                        RuleGroup { ruleModel: modelA }
                        Label { text: checker.catTitle("B"); font.bold: true }
                        RuleGroup { ruleModel: modelB }
                        Label { text: checker.catTitle("C"); font.bold: true }
                        RuleGroup { ruleModel: modelC }
                        Label { text: checker.catTitle("D"); font.bold: true }
                        RuleGroup { ruleModel: modelD }
                        Label { text: checker.catTitle("E"); font.bold: true }
                        RuleGroup { ruleModel: modelE }
                        Label { text: checker.catTitle("F"); font.bold: true }
                        RuleGroup { ruleModel: modelF }

                        GroupBox {
                              title: checker.S("marking")
                              Layout.fillWidth: true
                              ColumnLayout {
                                    CheckBox { text: checker.S("onlyColor"); checked: onlyColor; onToggled: onlyColor = checked }
                                    CheckBox { text: checker.S("dryRun"); checked: dryRun; onToggled: dryRun = checked }
                                    CheckBox { text: checker.S("cleanup"); checked: cleanupBeforeRun; onToggled: cleanupBeforeRun = checked }
                              }
                        }
                  }
            }

            onAccepted: { startCheck(); }
            onRejected: { quit(); }
      }

      MessageDialog {
            id: msgResult
            title: "Chorale Rules Checker"
            text: ""
            onAccepted: { quit(); }
            visible: false
      }

      function openSettings() { settingsDialog.open(); }

      // =========================================================================
      // Effective key
      // =========================================================================
      function effectiveTonicPc() {
            return tonicOverride >= 0 ? tonicOverride : Logic.keySigToTonicPc(scoreKeySig);
      }

      // =========================================================================
      // Marking (adapted from the original plugin)
      // =========================================================================
      function resetColor(note) { note.color = "#000000"; }

      function colorNotes(wrappers, color) {
            for (var i = 0; i < wrappers.length; i++) {
                  if (wrappers[i] && wrappers[i].ref) wrappers[i].ref.color = color;
            }
      }

      function addStaffText(text, track, tick) {
            var myText = newElement(Element.STAFF_TEXT);
            myText.text = sentinel + text;
            myText.offsetY = 1;
            var cursor = curScore.newCursor();
            cursor.rewind(0);
            cursor.track = track;
            while (cursor.tick < tick && cursor.next()) { /* advance */ }
            cursor.add(myText);
      }

      // Report a finding: count it, color it and (if applicable) add text.
      function report(ruleId, wrappers, label) {
            findingCounts[ruleId] = (findingCounts[ruleId] || 0) + 1;
            if (dryRun) return;
            colorNotes(wrappers, ruleColor[ruleId]);
            if (onlyColor) return;
            var anchor = wrappers[0];
            addStaffText(label, anchor.track, anchor.tick);
      }

      function cleanupOldMarkings() {
            var cursor = curScore.newCursor();
            cursor.rewind(0);
            while (cursor.segment) {
                  var segment = cursor.segment;
                  if (segment.annotations) {
                        for (var i = segment.annotations.length - 1; i >= 0; i--) {
                              var a = segment.annotations[i];
                              if (a && a.type === Element.STAFF_TEXT &&
                                    typeof a.text === "string" && a.text.indexOf(sentinel) === 0) {
                                    removeElement(a);
                              }
                        }
                  }
                  for (var track = 0; track < curScore.ntracks; track++) {
                        var el = segment.elementAt(track);
                        if (el && el.type === Element.CHORD) {
                              for (var j = 0; j < el.notes.length; j++) resetColor(el.notes[j]);
                        }
                  }
                  cursor.next();
            }
      }

      // =========================================================================
      // Voice and verticality collection
      // =========================================================================
      // streams[track] = [ {pitch, tpc, tick, ref, track}, ... ] (top note of each
      // chord per voice; chorales are monophonic per voice).
      function collect() {
            var streams = {};
            var tracks = [];
            var nstaves = curScore.nstaves;
            scoreKeySig = 0;
            for (var staff = 0; staff < nstaves; staff++) {
                  for (var v = 0; v < 4; v++) {
                        var track = staff * 4 + v;
                        var cursor = curScore.newCursor();
                        cursor.rewind(0);
                        cursor.track = track;
                        if (cursor.segment) scoreKeySig = cursor.keySignature;
                        var arr = [];
                        while (cursor.segment) {
                              var el = cursor.element;
                              if (el && el.type === Element.CHORD && el.notes.length > 0) {
                                    var top = el.notes[el.notes.length - 1];
                                    arr.push({ pitch: top.pitch, tpc: top.tpc,
                                               tick: cursor.tick, ref: top, track: track });
                              }
                              cursor.next();
                        }
                        if (arr.length) { streams[track] = arr; tracks.push(track); }
                  }
            }
            return { streams: streams, tracks: tracks };
      }

      // Assign SATB roles by ordering voices by mean pitch (highest = S).
      function assignRoles(data) {
            var stats = [];
            for (var t = 0; t < data.tracks.length; t++) {
                  var track = data.tracks[t];
                  var s = data.streams[track], sum = 0;
                  for (var i = 0; i < s.length; i++) sum += s[i].pitch;
                  stats.push({ track: track, mean: sum / s.length });
            }
            stats.sort(function (a, b) { return b.mean - a.mean; });
            var roles = ["S", "A", "T", "B"];
            var map = {};
            for (var k = 0; k < stats.length && k < 4; k++) map[stats[k].track] = roles[k];
            return map;
      }

      function allOnsetTicks(data) {
            var seen = {}, ticks = [];
            for (var t = 0; t < data.tracks.length; t++) {
                  var s = data.streams[data.tracks[t]];
                  for (var i = 0; i < s.length; i++) {
                        if (!seen[s[i].tick]) { seen[s[i].tick] = true; ticks.push(s[i].tick); }
                  }
            }
            ticks.sort(function (a, b) { return a - b; });
            return ticks;
      }

      // Note sounding in each voice at 'tick' (the last one with tick <= tick),
      // with its index in the stream (to find the next note / resolution).
      function sonorityAt(tick, data) {
            var out = [];   // [{w, idx, track}]
            for (var t = 0; t < data.tracks.length; t++) {
                  var track = data.tracks[t];
                  var s = data.streams[track], chosen = -1;
                  for (var i = 0; i < s.length; i++) {
                        if (s[i].tick <= tick) chosen = i; else break;
                  }
                  if (chosen >= 0) out.push({ w: s[chosen], idx: chosen, track: track });
            }
            return out;
      }

      // =========================================================================
      // PASS 1 — Melodic rules (per voice)
      // =========================================================================
      function checkMelodic(data) {
            for (var t = 0; t < data.tracks.length; t++) {
                  var s = data.streams[data.tracks[t]];
                  for (var i = 1; i < s.length; i++) {
                        var a = s[i - 1], b = s[i];
                        if (a.pitch === b.pitch) continue;
                        if (isEnabled("augmentedSecond") && Logic.isAugmentedSecond(a, b))
                              report("augmentedSecond", [a, b], tr("aug 2nd", "2ª aum."));
                        else if (isEnabled("augDimLeaps") && Logic.isAugOrDimLeap(a, b))
                              report("augDimLeaps", [a, b], tr("aug/dim leap", "salto aum./dism."));
                        if (isEnabled("largeLeaps") && Logic.semitones(a, b) > 12)
                              report("largeLeaps", [a, b], tr("leap > 8ve", "salto > 8ª"));
                  }
            }
      }

      // =========================================================================
      // PASS 2 — Parallels / hidden (voice pairs, at each onset)
      // =========================================================================
      function checkParallels(data) {
            var ticks = allOnsetTicks(data);
            for (var k = 1; k < ticks.length; k++) {
                  var prev = sonorityAt(ticks[k - 1], data);
                  var cur = sonorityAt(ticks[k], data);
                  var prevByTrack = {}, curByTrack = {};
                  for (var p = 0; p < prev.length; p++) prevByTrack[prev[p].track] = prev[p].w;
                  for (var c = 0; c < cur.length; c++) curByTrack[cur[c].track] = cur[c].w;

                  for (var a = 0; a < data.tracks.length; a++) {
                        for (var b = a + 1; b < data.tracks.length; b++) {
                              var ta = data.tracks[a], tb = data.tracks[b];
                              var uPrev = prevByTrack[ta], uCur = curByTrack[ta];
                              var lPrev = prevByTrack[tb], lCur = curByTrack[tb];
                              if (!uPrev || !uCur || !lPrev || !lCur) continue;
                              if (uPrev.tick === uCur.tick && lPrev.tick === lCur.tick) continue;
                              var m = Logic.classifyPerfectMotion(uPrev, uCur, lPrev, lCur);
                              if (!m) continue;
                              if (m.type === "parallel") {
                                    if (m.interval === "5" && isEnabled("parallelFifths"))
                                          report("parallelFifths", [uPrev, lPrev, uCur, lCur], tr("parallel 5th", "5ª paralela"));
                                    else if (m.interval === "8" && isEnabled("parallelOctaves"))
                                          report("parallelOctaves", [uPrev, lPrev, uCur, lCur], tr("parallel 8ve", "8ª paralela"));
                                    else if (m.interval === "1" && isEnabled("parallelUnisons"))
                                          report("parallelUnisons", [uPrev, lPrev, uCur, lCur], tr("parallel unison", "unísono paralelo"));
                              } else if (m.type === "hidden" && isEnabled("hiddenFifthsOctaves")) {
                                    report("hiddenFifthsOctaves", [uPrev, lPrev, uCur, lCur],
                                           tr("hidden " + m.interval, "oculta " + m.interval));
                              } else if (m.type === "contrary-equal" && isEnabled("fifthsContraryMotion")) {
                                    report("fifthsContraryMotion", [uPrev, lPrev, uCur, lCur],
                                           tr("contrary " + m.interval, "mov. contrario " + m.interval));
                              }
                        }
                  }
            }
      }

      // =========================================================================
      // PASS 3 — Voice spacing & layout (vertical)
      // =========================================================================
      function checkSpacing(data, roleMap) {
            var ticks = allOnsetTicks(data);
            var prevByRole = null;
            for (var k = 0; k < ticks.length; k++) {
                  var son = sonorityAt(ticks[k], data);
                  var byRole = {};
                  for (var i = 0; i < son.length; i++) {
                        var role = roleMap[son[i].track];
                        if (role) byRole[role] = son[i].w;
                  }
                  // range
                  if (isEnabled("voiceRange")) {
                        var rr = ["S", "A", "T", "B"];
                        for (var j = 0; j < rr.length; j++) {
                              var w = byRole[rr[j]];
                              if (w && Logic.outOfRange(w.pitch, rr[j]))
                                    report("voiceRange", [w], tr("range " + rr[j], "ámbito " + rr[j]));
                        }
                  }
                  // spacing > octave between adjacent upper voices
                  if (isEnabled("spacingOverOctave")) {
                        if (byRole["S"] && byRole["A"] && (byRole["S"].pitch - byRole["A"].pitch) > 12)
                              report("spacingOverOctave", [byRole["S"], byRole["A"]], tr("> 8ve (S-A)", "> 8ª (S-A)"));
                        if (byRole["A"] && byRole["T"] && (byRole["A"].pitch - byRole["T"].pitch) > 12)
                              report("spacingOverOctave", [byRole["A"], byRole["T"]], tr("> 8ve (A-T)", "> 8ª (A-T)"));
                  }
                  // voice crossing (adjacent)
                  if (isEnabled("voiceCrossing")) {
                        var ord = ["S", "A", "T", "B"];
                        for (var c = 0; c < ord.length - 1; c++) {
                              var hi = byRole[ord[c]], lo = byRole[ord[c + 1]];
                              if (hi && lo && hi.pitch < lo.pitch)
                                    report("voiceCrossing", [hi, lo], tr("crossing ", "cruce ") + ord[c] + "/" + ord[c + 1]);
                        }
                  }
                  // overlap vs the previous verticality
                  if (isEnabled("voiceOverlap") && prevByRole) {
                        var pairs = [["S", "A"], ["A", "T"], ["T", "B"]];
                        for (var pp = 0; pp < pairs.length; pp++) {
                              var up = pairs[pp][0], dn = pairs[pp][1];
                              if (byRole[up] && prevByRole[dn] && byRole[up].pitch < prevByRole[dn].pitch)
                                    report("voiceOverlap", [byRole[up]], tr("overlap ", "superposición ") + up + "/" + dn);
                              else if (byRole[dn] && prevByRole[up] && byRole[dn].pitch > prevByRole[up].pitch)
                                    report("voiceOverlap", [byRole[dn]], tr("overlap ", "superposición ") + up + "/" + dn);
                        }
                  }
                  prevByRole = byRole;
            }
      }

      // =========================================================================
      // PASS 4 — Harmony: doublings, resolutions, completeness
      // =========================================================================
      function checkHarmony(data, roleMap) {
            var anyHarmonyRule =
                  isEnabled("doubledThird") || isEnabled("doubledLeadingTone") ||
                  isEnabled("doubledSeventh") || isEnabled("rootNotDoubled") ||
                  isEnabled("leadingToneResolution") || isEnabled("seventhResolution") ||
                  isEnabled("seventhPreparation") || isEnabled("incompleteChord");
            if (!anyHarmonyRule) return;

            var tonicPc = effectiveTonicPc();
            var leadingPc = Logic.leadingTonePc(tonicPc);
            var ticks = allOnsetTicks(data);

            for (var k = 0; k < ticks.length; k++) {
                  var son = sonorityAt(ticks[k], data);
                  if (son.length < 2) continue;
                  var pcs = [], bassW = son[0].w;
                  for (var i = 0; i < son.length; i++) {
                        pcs.push(Logic.tpc2pc(son[i].w.tpc));
                        if (son[i].w.pitch < bassW.pitch) bassW = son[i].w;
                  }
                  var chord = Logic.identifyChord(pcs, Logic.tpc2pc(bassW.tpc));
                  if (!chord) continue;
                  var degree = Logic.scaleDegree(chord.rootPc, tonicPc, modeOverride);
                  var degreeRoot = Logic.degreeRoot(degree);

                  // --- Doublings ---
                  var counts = {};        // member -> [wrappers]
                  for (var d = 0; d < son.length; d++) {
                        var pc = Logic.tpc2pc(son[d].w.tpc);
                        var mem = Logic.chordMemberOf(pc, chord);
                        if (!counts[mem]) counts[mem] = [];
                        counts[mem].push(son[d].w);
                  }

                  if (isEnabled("doubledThird") && chord.quality === "maj" &&
                        (degreeRoot === "I" || degreeRoot === "IV" || degreeRoot === "V") &&
                        counts["third"] && counts["third"].length >= 2) {
                        report("doubledThird", counts["third"],
                               tr("doubled 3rd (", "3ª duplicada (") + degreeRoot + ")");
                  }

                  if (isEnabled("doubledLeadingTone")) {
                        var lead = [];
                        for (var e = 0; e < son.length; e++)
                              if (Logic.tpc2pc(son[e].w.tpc) === leadingPc) lead.push(son[e].w);
                        if (lead.length >= 2) report("doubledLeadingTone", lead,
                               tr("doubled leading tone", "sensible duplicada"));
                  }

                  if (isEnabled("doubledSeventh") && chord.seventhPc !== null &&
                        counts["seventh"] && counts["seventh"].length >= 2) {
                        report("doubledSeventh", counts["seventh"], tr("doubled 7th", "7ª duplicada"));
                  }

                  if (isEnabled("rootNotDoubled") && chord.inversion === 0 &&
                        chord.seventhPc === null &&
                        (!counts["root"] || counts["root"].length < 2)) {
                        report("rootNotDoubled", counts["root"] || [son[0].w],
                               tr("root not doubled", "fundamental sin duplicar"));
                  }

                  if (isEnabled("incompleteChord") &&
                        (!counts["third"] || counts["third"].length === 0)) {
                        report("incompleteChord", [son[0].w], tr("missing 3rd", "acorde sin 3ª"));
                  }

                  // --- Resolutions (need the next note in the voice) ---
                  var isDominant = (chord.quality === "dom7") || (degreeRoot === "V");
                  for (var r = 0; r < son.length; r++) {
                        var item = son[r], wpc = Logic.tpc2pc(item.w.tpc);
                        var stream = data.streams[item.track];
                        var nextNote = (item.idx + 1 < stream.length) ? stream[item.idx + 1] : null;
                        var role = roleMap[item.track];
                        var isOuter = (role === "S" || role === "B");

                        // Leading-tone resolution (outer voices only, on a dominant)
                        if (isEnabled("leadingToneResolution") && isDominant &&
                              wpc === leadingPc && isOuter && nextNote) {
                              var risesToTonic = (Logic.tpc2pc(nextNote.tpc) === tonicPc) &&
                                    (nextNote.pitch - item.w.pitch === 1 || nextNote.pitch - item.w.pitch === 2);
                              if (!risesToTonic)
                                    report("leadingToneResolution", [item.w],
                                           tr("leading tone unresolved", "sensible sin resolver"));
                        }

                        // Seventh resolution (any voice)
                        if (isEnabled("seventhResolution") && chord.seventhPc !== null &&
                              wpc === chord.seventhPc && nextNote) {
                              var stepsDown = (item.w.pitch - nextNote.pitch === 1 ||
                                               item.w.pitch - nextNote.pitch === 2) &&
                                              Logic.intervalNumber(item.w, nextNote) === 2;
                              if (!stepsDown)
                                    report("seventhResolution", [item.w],
                                           tr("7th unresolved", "7ª sin resolver"));
                        }

                        // Preparation of NON-dominant sevenths
                        if (isEnabled("seventhPreparation") && chord.seventhPc !== null &&
                              chord.quality !== "dom7" && wpc === chord.seventhPc) {
                              var prevNote = (item.idx - 1 >= 0) ? stream[item.idx - 1] : null;
                              var prepared = prevNote &&
                                    (prevNote.pitch === item.w.pitch ||
                                     Logic.tpc2pc(prevNote.tpc) === chord.seventhPc);
                              if (!prepared)
                                    report("seventhPreparation", [item.w],
                                           tr("7th unprepared", "7ª sin preparar"));
                        }
                  }
            }
      }

      // =========================================================================
      // Orchestration
      // =========================================================================
      function startCheck() {
            if (!curScore) { quit(); return; }
            findingCounts = {};

            curScore.startCmd();
            if (cleanupBeforeRun) cleanupOldMarkings();

            var data = collect();
            if (data.tracks.length === 0) {
                  curScore.endCmd();
                  msgResult.text = S("noNotes");
                  msgResult.visible = true;
                  return;
            }
            var roleMap = assignRoles(data);

            checkMelodic(data);
            checkParallels(data);
            checkSpacing(data, roleMap);
            checkHarmony(data, roleMap);

            curScore.endCmd();
            showResults();
            msgResult.visible = true;
      }

      function showResults() {
            var total = 0, lines = [];
            for (var i = 0; i < RULES.length; i++) {
                  var id = RULES[i].id;
                  var c = findingCounts[id] || 0;
                  if (c > 0) { total += c; lines.push("• " + tr(RULES[i].en, RULES[i].es) + ": " + c); }
            }
            if (total === 0) {
                  msgResult.text = S("noFindings");
            } else {
                  msgResult.text = total + " " + S("findings") + "\n\n" + lines.join("\n");
            }
            if (dryRun) msgResult.text += "\n\n" + S("dryNote");
      }

      onRun: { openSettings(); }
}
