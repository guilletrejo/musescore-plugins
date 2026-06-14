// verificadorCoralLogic.js
//
// Lógica musical pura (sin dependencias de QML ni de MuseScore) usada por el
// plugin "Verificador de Reglas de Coral". Se mantiene aparte para poder
// testearla con Node fuera de MuseScore.
//
// Convenciones de entrada:
//   - Una "nota" es un objeto plano { pitch, tpc, track, voice, tick }
//       pitch : altura MIDI (Do central = 60)
//       tpc   : tonal pitch class de MuseScore (Do = 14, línea de quintas)
//   - Una "vertical" es un array de notas que suenan simultáneamente.
//
// Este archivo funciona tanto importado desde QML (import "...js" as Logica)
// como require()-eado desde Node (gracias al guard UMD del final).

// ---------------------------------------------------------------------------
// 1. Utilidades de altura / grafía (basadas en tpc)
// ---------------------------------------------------------------------------

// Clase de altura (0..11, Do=0) a partir del tpc.
function tpc2pc(tpc) {
      return (((tpc - 14) * 7) % 12 + 12) % 12;
}

// Paso diatético / letra (0=Do,1=Re,2=Mi,3=Fa,4=Sol,5=La,6=Si) a partir del tpc.
function tpc2step(tpc) {
      return (((tpc - 14) * 4) % 7 + 7) % 7;
}

// Altura diatónica absoluta: octava*7 + paso. Sirve para medir el "número" de
// intervalo (2ª, 3ª, ...) respetando la grafía.
function diatonicPitch(note) {
      var pc = tpc2pc(note.tpc);
      var octave = Math.round((note.pitch - pc) / 12);
      return octave * 7 + tpc2step(note.tpc);
}

// Número de intervalo melódico entre dos notas (unísono = 1, 2ª = 2, ...).
function intervalNumber(noteA, noteB) {
      return Math.abs(diatonicPitch(noteB) - diatonicPitch(noteA)) + 1;
}

// Semitonos entre dos notas.
function semitones(noteA, noteB) {
      return Math.abs(noteB.pitch - noteA.pitch);
}

// ¿El salto melódico entre A y B es una 2ª aumentada? (número 2, 3 semitonos)
function isAugmentedSecond(noteA, noteB) {
      return intervalNumber(noteA, noteB) === 2 && semitones(noteA, noteB) === 3;
}

// ¿Salto melódico de intervalo aumentado o disminuido relevante para coral?
// Detecta 4ª aumentada (tritono, número 4) y 5ª disminuida (tritono, número 5).
function isAugOrDimLeap(noteA, noteB) {
      var n = intervalNumber(noteA, noteB);
      var s = semitones(noteA, noteB);
      if (s === 6 && (n === 4 || n === 5)) return true;  // 4ªaum / 5ªdism
      if (n === 2 && s === 3) return true;               // 2ª aumentada
      if (n === 7 && s === 11) return true;              // 7ª mayor melódica
      return false;
}

// ---------------------------------------------------------------------------
// 2. Identificación de acordes
// ---------------------------------------------------------------------------

// Plantillas de acorde como conjuntos de intervalos (en semitonos) sobre la
// fundamental. El orden de chequeo prioriza las séptimas sobre las tríadas.
var CHORD_TEMPLATES = [
      { quality: "dom7",     intervals: [0, 4, 7, 10], seventh: 10 },
      { quality: "maj7",     intervals: [0, 4, 7, 11], seventh: 11 },
      { quality: "min7",     intervals: [0, 3, 7, 10], seventh: 10 },
      { quality: "halfDim7", intervals: [0, 3, 6, 10], seventh: 10 },
      { quality: "dim7",     intervals: [0, 3, 6, 9],  seventh: 9  },
      { quality: "maj",      intervals: [0, 4, 7],     seventh: null },
      { quality: "min",      intervals: [0, 3, 7],     seventh: null },
      { quality: "dim",      intervals: [0, 3, 6],     seventh: null },
      { quality: "aug",      intervals: [0, 4, 8],     seventh: null }
];

function uniqueSorted(arr) {
      var seen = {}, out = [];
      for (var i = 0; i < arr.length; i++) {
            if (!seen[arr[i]]) { seen[arr[i]] = true; out.push(arr[i]); }
      }
      out.sort(function (a, b) { return a - b; });
      return out;
}

function setsEqual(a, b) {
      if (a.length !== b.length) return false;
      for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
      return true;
}

// Identifica el acorde a partir de las clases de altura presentes y la clase
// de altura del bajo (nota más grave). Devuelve null si no matchea.
//   -> { rootPc, quality, inversion, seventhPc | null, third, fifth, seventh }
// inversion: 0 (fundamental), 1, 2, 3.
function identifyChord(pcs, bassPc) {
      var present = uniqueSorted(pcs.slice());
      for (var t = 0; t < CHORD_TEMPLATES.length; t++) {
            var tmpl = CHORD_TEMPLATES[t];
            for (var r = 0; r < present.length; r++) {
                  var rootPc = present[r];
                  var rel = [];
                  for (var i = 0; i < present.length; i++) {
                        rel.push((present[i] - rootPc + 12) % 12);
                  }
                  rel = uniqueSorted(rel);
                  if (setsEqual(rel, tmpl.intervals)) {
                        var bassRel = ((bassPc - rootPc) % 12 + 12) % 12;
                        var inversion = bassRelToInversion(bassRel, tmpl);
                        return {
                              rootPc: rootPc,
                              quality: tmpl.quality,
                              inversion: inversion,
                              thirdPc: (rootPc + tmpl.intervals[1]) % 12,
                              fifthPc: (rootPc + tmpl.intervals[2]) % 12,
                              seventhPc: tmpl.seventh !== null
                                    ? (rootPc + tmpl.seventh) % 12 : null
                        };
                  }
            }
      }
      return null;
}

function bassRelToInversion(bassRel, tmpl) {
      if (bassRel === 0) return 0;
      if (bassRel === tmpl.intervals[1]) return 1;     // 3ª en el bajo
      if (bassRel === tmpl.intervals[2]) return 2;     // 5ª en el bajo
      if (tmpl.seventh !== null && bassRel === tmpl.seventh) return 3;
      return 0;
}

// ¿Qué miembro del acorde es esta clase de altura?
//   -> "root" | "third" | "fifth" | "seventh" | "none"
function chordMemberOf(pc, chord) {
      if (pc === chord.rootPc) return "root";
      if (pc === chord.thirdPc) return "third";
      if (pc === chord.fifthPc) return "fifth";
      if (chord.seventhPc !== null && pc === chord.seventhPc) return "seventh";
      return "none";
}

// ---------------------------------------------------------------------------
// 3. Tonalidad y grados
// ---------------------------------------------------------------------------

// Clase de altura de la tónica a partir del nº de alteraciones de la armadura.
// keySig: -7..7 (negativos = bemoles). Devuelve la tónica MAYOR.
function keySigToTonicPc(keySig) {
      // Cada sostenido sube una quinta (7 semitonos) desde Do.
      return ((keySig * 7) % 12 + 12) % 12;
}

// pc de la sensible (7º grado ascendente) tanto en mayor como en menor armónica.
function leadingTonePc(tonicPc) {
      return (tonicPc + 11) % 12;
}

var MAJOR_DEGREE_SEMI = { 0: "I", 2: "II", 4: "III", 5: "IV", 7: "V", 9: "VI", 11: "VII" };
// menor armónica: III con 5ª aumentada y VII (sensible) sobre tonicPc+11.
var MINOR_DEGREE_SEMI = { 0: "i", 2: "ii", 3: "III", 5: "iv", 7: "V", 8: "VI", 11: "vii" };

// Grado (cifrado romano) de una fundamental respecto de la tónica/modo.
// mode: "major" | "minor". Devuelve null si la fundamental es cromática.
function scaleDegree(rootPc, tonicPc, mode) {
      var rel = ((rootPc - tonicPc) % 12 + 12) % 12;
      var table = mode === "minor" ? MINOR_DEGREE_SEMI : MAJOR_DEGREE_SEMI;
      return table.hasOwnProperty(rel) ? table[rel] : null;
}

// Normaliza un grado a número romano "mayúsculo" sin calidad (I, II, ... VII).
function degreeRoot(degree) {
      return degree ? degree.toUpperCase() : null;
}

// ---------------------------------------------------------------------------
// 4. Ámbitos vocales (tessituras) SATB en altura MIDI
//    Rangos prácticos habituales para ejercicios de coral.
// ---------------------------------------------------------------------------
var VOICE_RANGES = {
      S: { min: 60, max: 81, nombre: "Soprano" },  // Do4 - La5
      A: { min: 55, max: 74, nombre: "Alto" },     // Sol3 - Re5
      T: { min: 48, max: 69, nombre: "Tenor" },    // Do3 - La4
      B: { min: 40, max: 62, nombre: "Bajo" }      // Mi2 - Re4
};

function outOfRange(pitch, voiceKey) {
      var r = VOICE_RANGES[voiceKey];
      if (!r) return false;
      return pitch < r.min || pitch > r.max;
}

// ---------------------------------------------------------------------------
// 5. Detección de duplicaciones en una vertical
//    notes: array de { pitch, tpc } (todas las voces sonando)
//    chord: salida de identifyChord; tonicPc/mode para la sensible.
//    -> array de hallazgos { member, pcs:[...], esSensible:bool }
// ---------------------------------------------------------------------------
function findDoublings(notes, chord) {
      var counts = {};   // member -> count
      for (var i = 0; i < notes.length; i++) {
            var pc = tpc2pc(notes[i].tpc);
            var m = chordMemberOf(pc, chord);
            counts[m] = (counts[m] || 0) + 1;
      }
      return counts;
}

// ---------------------------------------------------------------------------
// 6. Movimiento entre dos pares de voces (paralelas / ocultas / contrarias)
//    Cada voz se da como { prev: nota, cur: nota }.
// ---------------------------------------------------------------------------
function sign(x) { return x > 0 ? 1 : (x < 0 ? -1 : 0); }

// Clasifica el movimiento de un intervalo perfecto (5ª justa = 7, 8ª = 0).
//   -> { tipo: "paralela"|"oculta"|"contraria-igual"|null, intervalo: "5"|"8" }
function classifyPerfectMotion(vUpperPrev, vUpperCur, vLowerPrev, vLowerCur) {
      var curInt = Math.abs(vUpperCur.pitch - vLowerCur.pitch);
      var prevInt = Math.abs(vUpperPrev.pitch - vLowerPrev.pitch);
      var curMod = curInt % 12;
      var isFifth = curMod === 7;
      var isOctave = curMod === 0 && curInt !== 0;   // 0 con dif 0 = unísono
      var isUnison = curInt === 0;
      if (!isFifth && !isOctave && !isUnison) return null;

      var label = isFifth ? "5" : (isUnison ? "1" : "8");
      var dirUpper = sign(vUpperCur.pitch - vUpperPrev.pitch);
      var dirLower = sign(vLowerCur.pitch - vLowerPrev.pitch);

      // Paralelas reales: mismo intervalo perfecto antes y después, mismo sentido.
      if (curInt === prevInt && dirUpper === dirLower && dirUpper !== 0) {
            return { tipo: "paralela", intervalo: label };
      }
      // Quintas/octavas por movimiento contrario hacia el mismo intervalo perfecto.
      if ((prevInt % 12 === curMod) && dirUpper !== 0 && dirLower !== 0 &&
            dirUpper !== dirLower) {
            return { tipo: "contraria-igual", intervalo: label };
      }
      // Ocultas/directas: llegada a 5ª/8ª por movimiento directo (mismo sentido).
      if (dirUpper === dirLower && dirUpper !== 0 && curInt !== prevInt) {
            return { tipo: "oculta", intervalo: label };
      }
      return null;
}

// ---------------------------------------------------------------------------
// UMD: exportar para Node; en QML 'module' no existe y el bloque se omite.
// ---------------------------------------------------------------------------
if (typeof module !== "undefined" && module.exports) {
      module.exports = {
            tpc2pc: tpc2pc,
            tpc2step: tpc2step,
            diatonicPitch: diatonicPitch,
            intervalNumber: intervalNumber,
            semitones: semitones,
            isAugmentedSecond: isAugmentedSecond,
            isAugOrDimLeap: isAugOrDimLeap,
            identifyChord: identifyChord,
            chordMemberOf: chordMemberOf,
            keySigToTonicPc: keySigToTonicPc,
            leadingTonePc: leadingTonePc,
            scaleDegree: scaleDegree,
            degreeRoot: degreeRoot,
            VOICE_RANGES: VOICE_RANGES,
            outOfRange: outOfRange,
            findDoublings: findDoublings,
            classifyPerfectMotion: classifyPerfectMotion,
            sign: sign
      };
}
