import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import MuseScore 3.0
import Muse.UiComponents 1.0

import "verificadorCoralLogic.js" as Logica

// =============================================================================
// Verificador de Reglas de Coral (estilo Bach)
//
// Obra derivada de "Parallel Intervals Checker" de Christian Hofmann
// (https://github.com/christianhofmanncodes/musescore-plugins), a su vez
// inspirado en checkParallels de heuchi. Licencia GPLv3.
//
// Extiende el plugin original (quintas/octavas paralelas) con un conjunto
// configurable de reglas de armonía y conducción de voces del estilo de coral.
// Cada regla puede activarse/desactivarse y lleva su referencia bibliográfica
// (visible como tooltip en el diálogo y en el README).
// =============================================================================

MuseScore {
      version: "1.0"
      title: "Verificador de Reglas de Coral"
      description: "Detecta quintas/octavas paralelas y un conjunto configurable de reglas de armonía y conducción de voces del estilo de coral (duplicaciones, resolución de sensible y séptima, 2ª aumentada, cruces, espaciado, ámbitos, etc.). Cada regla se activa/desactiva y trae su referencia bibliográfica."
      categoryCode: "composing-arranging-tools"
      thumbnailName: "logo.png"
      requiresScore: true
      pluginType: "dialog"

      implicitHeight: 640
      implicitWidth: 460

      id: verificador

      // --- Marcado / ejecución ---
      property bool onlyColor: false
      property bool dryRun: false
      property bool cleanupBeforeRun: true
      readonly property string sentinel: "» "   // prefijo de las marcas de texto

      // --- Tonalidad ---
      property int  scoreKeySig: 0          // alteraciones leídas de la partitura
      property int  tonicOverride: -1       // -1 = auto (desde armadura)
      property string modeOverride: "major" // "major" | "minor"

      // --- Resultados ---
      property var findingCounts: ({})

      // --- Definición de reglas -------------------------------------------------
      // Las reglas melódicas/voice-leading (A,B,C) vienen activas; las que
      // dependen de análisis armónico (D,E,F) vienen desactivadas por defecto.
      readonly property var categorias: ({
            "A": "A · Movimiento paralelo / directo",
            "B": "B · Disposición de voces",
            "C": "C · Línea melódica",
            "D": "D · Duplicaciones (análisis armónico)",
            "E": "E · Resoluciones (análisis armónico)",
            "F": "F · Completitud del acorde (análisis armónico)"
      })

      readonly property var RULES: [
            { id: "quintasParalelas",     cat: "A", on: true,  color: "#FB8C00",
              nombre: "Quintas justas paralelas",
              cita: "Zamacois, Tratado de armonía (movimientos prohibidos); Piston, Armonía (cuerpo de la armonía); Fux, Gradus ad Parnassum." },
            { id: "octavasParalelas",     cat: "A", on: true,  color: "#4285F4",
              nombre: "Octavas paralelas",
              cita: "Zamacois, Tratado de armonía; Piston, Armonía; Fux, Gradus ad Parnassum." },
            { id: "unisonosParalelos",    cat: "A", on: true,  color: "#26A69A",
              nombre: "Unísonos paralelos",
              cita: "Piston, Armonía; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "quintasOctavasOcultas",cat: "A", on: true,  color: "#AB47BC",
              nombre: "Quintas/octavas ocultas (directas) — énfasis voces extremas",
              cita: "Piston, Armonía (hidden/direct fifths & octaves); Zamacois, Tratado de armonía." },
            { id: "quintasMovContrario",  cat: "A", on: true,  color: "#EC407A",
              nombre: "Quintas/octavas por movimiento contrario hacia intervalo perfecto",
              cita: "Aldwell & Schachter, Harmony and Voice Leading; Piston, Armonía." },

            { id: "cruceVoces",           cat: "B", on: true,  color: "#7E57C2",
              nombre: "Cruce de voces",
              cita: "Piston, Armonía; Kostka & Payne, Tonal Harmony (voice leading)." },
            { id: "superposicionVoces",   cat: "B", on: true,  color: "#5C6BC0",
              nombre: "Superposición (overlap) de voces",
              cita: "Aldwell & Schachter, Harmony and Voice Leading; Kostka & Payne, Tonal Harmony." },
            { id: "espaciadoMayorOctava", cat: "B", on: true,  color: "#42A5F5",
              nombre: "Distancia mayor a 8ª entre voces adyacentes superiores (S-A, A-T)",
              cita: "Zamacois, Tratado de armonía (disposición); Kostka & Payne, Tonal Harmony (spacing)." },
            { id: "ambitoVoces",          cat: "B", on: true,  color: "#29B6F6",
              nombre: "Tessitura SATB excedida",
              cita: "Kostka & Payne, Tonal Harmony (vocal ranges); Aldwell & Schachter, Harmony and Voice Leading." },

            { id: "segundaAumentada",     cat: "C", on: true,  color: "#EF5350",
              nombre: "Salto melódico de 2ª aumentada (6-7 en modo menor)",
              cita: "Zamacois, Tratado de armonía (intervalos melódicos); De la Motte, Armonía; Schoenberg, Tratado de armonía." },
            { id: "intervalosAumDism",    cat: "C", on: true,  color: "#FF7043",
              nombre: "Saltos melódicos aumentados/disminuidos (4ª aum., 5ª dism., 7ª)",
              cita: "Fux, Gradus ad Parnassum / Jeppesen, Counterpoint; Piston, Armonía." },
            { id: "saltosGrandes",        cat: "C", on: true,  color: "#FFA726",
              nombre: "Saltos melódicos grandes (> 8ª)",
              cita: "Fux, Gradus ad Parnassum; Piston, Armonía (línea melódica)." },

            { id: "duplicacionTercera",   cat: "D", on: false, color: "#66BB6A",
              nombre: "Duplicación de la 3ª en acordes mayores (I, IV, V)",
              cita: "Zamacois, Tratado de armonía (duplicaciones); Piston, Armonía (doubling)." },
            { id: "duplicacionSensible",  cat: "D", on: false, color: "#9CCC65",
              nombre: "Duplicación de la sensible (prohibido)",
              cita: "Piston, Armonía; Kostka & Payne, Tonal Harmony; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "duplicacionSeptima",   cat: "D", on: false, color: "#D4E157",
              nombre: "Duplicación de la 7ª del acorde",
              cita: "Piston, Armonía (acordes de séptima); Kostka & Payne, Tonal Harmony." },
            { id: "preferenciaFundamental",cat: "D", on: false, color: "#C0CA33",
              nombre: "Estado fundamental sin duplicar la fundamental (informativa)",
              cita: "Zamacois, Tratado de armonía (duplicaciones preferentes)." },

            { id: "resolucionSensible",   cat: "E", on: false, color: "#FFCA28",
              nombre: "Resolución de la sensible (sube a la tónica en V→I; voces extremas)",
              cita: "Piston, Armonía; Kostka & Payne, Tonal Harmony; Aldwell & Schachter, Harmony and Voice Leading." },
            { id: "resolucionSeptima",    cat: "E", on: false, color: "#FFB300",
              nombre: "Resolución de la 7ª (desciende por grado conjunto)",
              cita: "Piston, Armonía (séptima de dominante); Kostka & Payne, Tonal Harmony." },
            { id: "preparacionSeptima",   cat: "E", on: false, color: "#FF8F00",
              nombre: "Preparación de la disonancia (séptimas NO dominantes)",
              cita: "Jeppesen, Counterpoint; Schenker. Nota: la 7ª de dominante NO requiere preparación." },

            { id: "acordeIncompleto",     cat: "F", on: false, color: "#8D6E63",
              nombre: "Acorde incompleto (falta la 3ª)",
              cita: "Piston, Armonía; Kostka & Payne, Tonal Harmony." }
      ]

      // Estado de activación: id -> bool. Inicializado en onCompleted.
      property var ruleEnabled: ({})
      property var ruleColor: ({})

      // =========================================================================
      // UI
      // =========================================================================
      Component.onCompleted: {
            var en = {}, col = {};
            for (var i = 0; i < RULES.length; i++) {
                  en[RULES[i].id] = RULES[i].on;
                  col[RULES[i].id] = RULES[i].color;
            }
            ruleEnabled = en;
            ruleColor = col;
            populateModels();
      }

      // Un ListModel por categoría para construir el diálogo dinámicamente.
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
                        rid: r.id, nombre: r.nombre, cita: r.cita, activa: r.on
                  });
            }
      }

      function syncEnabledFromModels() {
            var en = {};
            var models = [modelA, modelB, modelC, modelD, modelE, modelF];
            for (var m = 0; m < models.length; m++) {
                  for (var i = 0; i < models[m].count; i++) {
                        var it = models[m].get(i);
                        en[it.rid] = it.activa;
                  }
            }
            ruleEnabled = en;
      }

      // Plantilla de GroupBox con sus checkboxes (una por categoría).
      component RuleGroup: GroupBox {
            property var ruleModel
            Layout.fillWidth: true
            ColumnLayout {
                  width: parent.width
                  Repeater {
                        model: ruleModel
                        delegate: CheckBox {
                              text: nombre
                              checked: activa
                              Layout.fillWidth: true
                              onToggled: ruleModel.setProperty(index, "activa", checked)
                              ToolTip.visible: hovered
                              ToolTip.delay: 300
                              ToolTip.text: cita
                        }
                  }
            }
      }

      Dialog {
            id: settingsDialog
            title: "Verificador de Reglas de Coral — Configuración"
            modal: true
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
            visible: false
            width: 440
            height: 600

            ScrollView {
                  anchors.fill: parent
                  clip: true
                  contentWidth: availableWidth

                  ColumnLayout {
                        width: settingsDialog.width - 40
                        spacing: 8

                        Label {
                              text: "Pasá el mouse sobre cada regla para ver su referencia bibliográfica."
                              wrapMode: Text.WordWrap
                              font.italic: true
                              Layout.fillWidth: true
                        }

                        GroupBox {
                              title: "Tonalidad"
                              Layout.fillWidth: true
                              ColumnLayout {
                                    RowLayout {
                                          Label { text: "Tónica:" }
                                          ComboBox {
                                                id: tonicCombo
                                                model: ["Auto (armadura)", "Do", "Do#/Reb", "Re", "Re#/Mib",
                                                        "Mi", "Fa", "Fa#/Solb", "Sol", "Sol#/Lab",
                                                        "La", "La#/Sib", "Si"]
                                                currentIndex: 0
                                                onActivated: tonicOverride = currentIndex === 0 ? -1 : currentIndex - 1
                                          }
                                    }
                                    RowLayout {
                                          Label { text: "Modo:" }
                                          ComboBox {
                                                id: modeCombo
                                                model: ["Mayor", "menor"]
                                                currentIndex: 0
                                                onActivated: modeOverride = currentIndex === 0 ? "major" : "minor"
                                          }
                                    }
                              }
                        }

                        Label { text: categorias["A"]; font.bold: true; Layout.topMargin: 4 }
                        RuleGroup { ruleModel: modelA }
                        Label { text: categorias["B"]; font.bold: true }
                        RuleGroup { ruleModel: modelB }
                        Label { text: categorias["C"]; font.bold: true }
                        RuleGroup { ruleModel: modelC }
                        Label { text: categorias["D"]; font.bold: true }
                        RuleGroup { ruleModel: modelD }
                        Label { text: categorias["E"]; font.bold: true }
                        RuleGroup { ruleModel: modelE }
                        Label { text: categorias["F"]; font.bold: true }
                        RuleGroup { ruleModel: modelF }

                        GroupBox {
                              title: "Marcado"
                              Layout.fillWidth: true
                              ColumnLayout {
                                    CheckBox { text: "Solo colorear notas (sin texto)"; checked: onlyColor; onToggled: onlyColor = checked }
                                    CheckBox { text: "Sin marcas (dry run)"; checked: dryRun; onToggled: dryRun = checked }
                                    CheckBox { text: "Limpiar marcas previas antes de ejecutar"; checked: cleanupBeforeRun; onToggled: cleanupBeforeRun = checked }
                              }
                        }
                  }
            }

            onAccepted: { syncEnabledFromModels(); startCheck(); }
            onRejected: { quit(); }
      }

      MessageDialog {
            id: msgResult
            title: "Resultado"
            text: ""
            onAccepted: { quit(); }
            visible: false
      }

      function openSettings() { settingsDialog.open(); }

      // =========================================================================
      // Tonalidad efectiva
      // =========================================================================
      function effectiveTonicPc() {
            return tonicOverride >= 0 ? tonicOverride : Logica.keySigToTonicPc(scoreKeySig);
      }

      // =========================================================================
      // Marcado (adaptado del plugin original)
      // =========================================================================
      function resetColor(note) { note.color = "#000000"; }

      function colorNotes(wrappers, color) {
            for (var i = 0; i < wrappers.length; i++) {
                  if (wrappers[i] && wrappers[i].ref) wrappers[i].ref.color = color;
            }
      }

      function addStaffText(text, color, track, tick) {
            var myText = newElement(Element.STAFF_TEXT);
            myText.text = sentinel + text;
            myText.offsetY = 1;
            var cursor = curScore.newCursor();
            cursor.rewind(0);
            cursor.track = track;
            while (cursor.tick < tick && cursor.next()) { /* avanzar */ }
            cursor.add(myText);
      }

      // Reporta un hallazgo: cuenta, colorea y (si corresponde) agrega texto.
      function report(ruleId, wrappers, etiqueta) {
            findingCounts[ruleId] = (findingCounts[ruleId] || 0) + 1;
            if (dryRun) return;
            colorNotes(wrappers, ruleColor[ruleId]);
            if (onlyColor) return;
            var anchor = wrappers[0];
            addStaffText(etiqueta, ruleColor[ruleId], anchor.track, anchor.tick);
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
      // Recolección de voces y verticales
      // =========================================================================
      // streams[track] = [ {pitch, tpc, tick, ref, track}, ... ] (nota superior
      // de cada acorde por voz; el coral es monofónico por voz).
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

      // Asigna roles SATB ordenando las voces por altura media (más aguda = S).
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

      // Nota sonando en cada voz en 'tick' (la última con tick <= tick), con su
      // índice dentro del stream (para hallar la nota siguiente / resolución).
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
      // PASADA 1 — Reglas melódicas (por voz)
      // =========================================================================
      function checkMelodic(data) {
            for (var t = 0; t < data.tracks.length; t++) {
                  var s = data.streams[data.tracks[t]];
                  for (var i = 1; i < s.length; i++) {
                        var a = s[i - 1], b = s[i];
                        if (a.pitch === b.pitch) continue;
                        if (ruleEnabled["segundaAumentada"] && Logica.isAugmentedSecond(a, b))
                              report("segundaAumentada", [a, b], "2ª aum.");
                        else if (ruleEnabled["intervalosAumDism"] && Logica.isAugOrDimLeap(a, b))
                              report("intervalosAumDism", [a, b], "salto aum./dism.");
                        if (ruleEnabled["saltosGrandes"] && Logica.semitones(a, b) > 12)
                              report("saltosGrandes", [a, b], "salto > 8ª");
                  }
            }
      }

      // =========================================================================
      // PASADA 2 — Paralelas / ocultas (pares de voces, en cada onset)
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
                              var m = Logica.classifyPerfectMotion(uPrev, uCur, lPrev, lCur);
                              if (!m) continue;
                              if (m.tipo === "paralela") {
                                    if (m.intervalo === "5" && ruleEnabled["quintasParalelas"])
                                          report("quintasParalelas", [uPrev, lPrev, uCur, lCur], "5ª paralela");
                                    else if (m.intervalo === "8" && ruleEnabled["octavasParalelas"])
                                          report("octavasParalelas", [uPrev, lPrev, uCur, lCur], "8ª paralela");
                                    else if (m.intervalo === "1" && ruleEnabled["unisonosParalelos"])
                                          report("unisonosParalelos", [uPrev, lPrev, uCur, lCur], "unísono paralelo");
                              } else if (m.tipo === "oculta" && ruleEnabled["quintasOctavasOcultas"]) {
                                    report("quintasOctavasOcultas", [uPrev, lPrev, uCur, lCur], m.intervalo + "ª oculta");
                              } else if (m.tipo === "contraria-igual" && ruleEnabled["quintasMovContrario"]) {
                                    report("quintasMovContrario", [uPrev, lPrev, uCur, lCur], m.intervalo + "ª mov. contrario");
                              }
                        }
                  }
            }
      }

      // =========================================================================
      // PASADA 3 — Disposición de voces (vertical)
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
                  // ámbito
                  if (ruleEnabled["ambitoVoces"]) {
                        var rr = ["S", "A", "T", "B"];
                        for (var j = 0; j < rr.length; j++) {
                              var w = byRole[rr[j]];
                              if (w && Logica.outOfRange(w.pitch, rr[j]))
                                    report("ambitoVoces", [w], "fuera de ámbito " + rr[j]);
                        }
                  }
                  // espaciado > 8ª entre voces superiores adyacentes
                  if (ruleEnabled["espaciadoMayorOctava"]) {
                        if (byRole["S"] && byRole["A"] && (byRole["S"].pitch - byRole["A"].pitch) > 12)
                              report("espaciadoMayorOctava", [byRole["S"], byRole["A"]], "> 8ª (S-A)");
                        if (byRole["A"] && byRole["T"] && (byRole["A"].pitch - byRole["T"].pitch) > 12)
                              report("espaciadoMayorOctava", [byRole["A"], byRole["T"]], "> 8ª (A-T)");
                  }
                  // cruce de voces (adyacentes)
                  if (ruleEnabled["cruceVoces"]) {
                        var ord = ["S", "A", "T", "B"];
                        for (var c = 0; c < ord.length - 1; c++) {
                              var hi = byRole[ord[c]], lo = byRole[ord[c + 1]];
                              if (hi && lo && hi.pitch < lo.pitch)
                                    report("cruceVoces", [hi, lo], "cruce " + ord[c] + "/" + ord[c + 1]);
                        }
                  }
                  // superposición respecto de la vertical anterior
                  if (ruleEnabled["superposicionVoces"] && prevByRole) {
                        var pares = [["S", "A"], ["A", "T"], ["T", "B"]];
                        for (var pp = 0; pp < pares.length; pp++) {
                              var up = pares[pp][0], dn = pares[pp][1];
                              if (byRole[up] && prevByRole[dn] && byRole[up].pitch < prevByRole[dn].pitch)
                                    report("superposicionVoces", [byRole[up]], "superposición " + up + "/" + dn);
                              else if (byRole[dn] && prevByRole[up] && byRole[dn].pitch > prevByRole[up].pitch)
                                    report("superposicionVoces", [byRole[dn]], "superposición " + up + "/" + dn);
                        }
                  }
                  prevByRole = byRole;
            }
      }

      // =========================================================================
      // PASADA 4 — Armonía: duplicaciones, resoluciones, completitud
      // =========================================================================
      function checkHarmony(data, roleMap) {
            var anyHarmonyRule =
                  ruleEnabled["duplicacionTercera"] || ruleEnabled["duplicacionSensible"] ||
                  ruleEnabled["duplicacionSeptima"] || ruleEnabled["preferenciaFundamental"] ||
                  ruleEnabled["resolucionSensible"] || ruleEnabled["resolucionSeptima"] ||
                  ruleEnabled["preparacionSeptima"] || ruleEnabled["acordeIncompleto"];
            if (!anyHarmonyRule) return;

            var tonicPc = effectiveTonicPc();
            var sensiblePc = Logica.leadingTonePc(tonicPc);
            var ticks = allOnsetTicks(data);

            for (var k = 0; k < ticks.length; k++) {
                  var son = sonorityAt(ticks[k], data);
                  if (son.length < 2) continue;
                  var pcs = [], bassW = son[0].w;
                  for (var i = 0; i < son.length; i++) {
                        pcs.push(Logica.tpc2pc(son[i].w.tpc));
                        if (son[i].w.pitch < bassW.pitch) bassW = son[i].w;
                  }
                  var chord = Logica.identifyChord(pcs, Logica.tpc2pc(bassW.tpc));
                  if (!chord) continue;
                  var grado = Logica.scaleDegree(chord.rootPc, tonicPc, modeOverride);
                  var gradoRaiz = Logica.degreeRoot(grado);

                  // --- Duplicaciones ---
                  var counts = {};        // member -> [wrappers]
                  for (var d = 0; d < son.length; d++) {
                        var pc = Logica.tpc2pc(son[d].w.tpc);
                        var mem = Logica.chordMemberOf(pc, chord);
                        if (!counts[mem]) counts[mem] = [];
                        counts[mem].push(son[d].w);
                  }

                  if (ruleEnabled["duplicacionTercera"] && chord.quality === "maj" &&
                        (gradoRaiz === "I" || gradoRaiz === "IV" || gradoRaiz === "V") &&
                        counts["third"] && counts["third"].length >= 2) {
                        report("duplicacionTercera", counts["third"], "3ª duplicada (" + gradoRaiz + ")");
                  }

                  if (ruleEnabled["duplicacionSensible"]) {
                        var sens = [];
                        for (var e = 0; e < son.length; e++)
                              if (Logica.tpc2pc(son[e].w.tpc) === sensiblePc) sens.push(son[e].w);
                        if (sens.length >= 2) report("duplicacionSensible", sens, "sensible duplicada");
                  }

                  if (ruleEnabled["duplicacionSeptima"] && chord.seventhPc !== null &&
                        counts["seventh"] && counts["seventh"].length >= 2) {
                        report("duplicacionSeptima", counts["seventh"], "7ª duplicada");
                  }

                  if (ruleEnabled["preferenciaFundamental"] && chord.inversion === 0 &&
                        chord.seventhPc === null &&
                        (!counts["root"] || counts["root"].length < 2)) {
                        report("preferenciaFundamental", counts["root"] || [son[0].w],
                               "fundamental sin duplicar");
                  }

                  if (ruleEnabled["acordeIncompleto"] &&
                        (!counts["third"] || counts["third"].length === 0)) {
                        report("acordeIncompleto", [son[0].w], "acorde sin 3ª");
                  }

                  // --- Resoluciones (necesitan la nota siguiente en la voz) ---
                  var esDominante = (chord.quality === "dom7") ||
                                    (gradoRaiz === "V");
                  for (var r = 0; r < son.length; r++) {
                        var item = son[r], wpc = Logica.tpc2pc(item.w.tpc);
                        var stream = data.streams[item.track];
                        var nextNote = (item.idx + 1 < stream.length) ? stream[item.idx + 1] : null;
                        var role = roleMap[item.track];
                        var esExtrema = (role === "S" || role === "B");

                        // Resolución de la sensible (solo voces extremas, en dominante)
                        if (ruleEnabled["resolucionSensible"] && esDominante &&
                              wpc === sensiblePc && esExtrema && nextNote) {
                              var subeATonica = (Logica.tpc2pc(nextNote.tpc) === tonicPc) &&
                                                (nextNote.pitch - item.w.pitch === 1 || nextNote.pitch - item.w.pitch === 2);
                              if (!subeATonica)
                                    report("resolucionSensible", [item.w], "sensible sin resolver");
                        }

                        // Resolución de la 7ª (cualquier voz)
                        if (ruleEnabled["resolucionSeptima"] && chord.seventhPc !== null &&
                              wpc === chord.seventhPc && nextNote) {
                              var bajaGradoConj = (item.w.pitch - nextNote.pitch === 1 ||
                                                   item.w.pitch - nextNote.pitch === 2) &&
                                                  Logica.intervalNumber(item.w, nextNote) === 2;
                              if (!bajaGradoConj)
                                    report("resolucionSeptima", [item.w], "7ª sin resolver");
                        }

                        // Preparación de séptimas NO dominantes
                        if (ruleEnabled["preparacionSeptima"] && chord.seventhPc !== null &&
                              chord.quality !== "dom7" && wpc === chord.seventhPc) {
                              var prevNote = (item.idx - 1 >= 0) ? stream[item.idx - 1] : null;
                              var preparada = prevNote &&
                                    (prevNote.pitch === item.w.pitch ||
                                     Logica.tpc2pc(prevNote.tpc) === chord.seventhPc);
                              if (!preparada)
                                    report("preparacionSeptima", [item.w], "7ª sin preparar");
                        }
                  }
            }
      }

      // =========================================================================
      // Orquestación
      // =========================================================================
      function startCheck() {
            if (!curScore) { quit(); return; }
            findingCounts = {};

            curScore.startCmd();
            if (cleanupBeforeRun) cleanupOldMarkings();

            var data = collect();
            if (data.tracks.length === 0) {
                  curScore.endCmd();
                  msgResult.text = "No se encontraron notas para analizar.";
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
                  if (c > 0) { total += c; lines.push("• " + RULES[i].nombre + ": " + c); }
            }
            if (total === 0) {
                  msgResult.text = "¡No se encontraron infracciones de las reglas activas!";
            } else {
                  msgResult.text = total + " hallazgo(s):\n\n" + lines.join("\n");
            }
            if (dryRun) msgResult.text += "\n\n(Dry run: no se aplicaron marcas.)";
      }

      onRun: { openSettings(); }
}
