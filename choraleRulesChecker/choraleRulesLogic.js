// choraleRulesLogic.js
//
// Pure music-theory logic (no QML or MuseScore dependencies) used by the
// "Chorale Rules Checker" plugin. Kept separate so it can be unit-tested with
// Node, outside of MuseScore.
//
// Input conventions:
//   - A "note" is a plain object { pitch, tpc, track, voice, tick }
//       pitch : MIDI pitch (middle C = 60)
//       tpc   : MuseScore tonal pitch class (C = 14, circle of fifths)
//   - A "verticality" is an array of notes sounding simultaneously.
//
// This file works both imported from QML (import "...js" as Logic) and
// require()-d from Node, thanks to the UMD guard at the bottom.

// ---------------------------------------------------------------------------
// 1. Pitch / spelling helpers (based on tpc)
// ---------------------------------------------------------------------------

// Pitch class (0..11, C=0) from a tpc.
function tpc2pc(tpc) {
      return (((tpc - 14) * 7) % 12 + 12) % 12;
}

// Diatonic step / letter (0=C,1=D,2=E,3=F,4=G,5=A,6=B) from a tpc.
function tpc2step(tpc) {
      return (((tpc - 14) * 4) % 7 + 7) % 7;
}

// Absolute diatonic pitch: octave*7 + step. Used to measure the interval
// "number" (2nd, 3rd, ...) while respecting spelling.
function diatonicPitch(note) {
      var pc = tpc2pc(note.tpc);
      var octave = Math.round((note.pitch - pc) / 12);
      return octave * 7 + tpc2step(note.tpc);
}

// Melodic interval number between two notes (unison = 1, 2nd = 2, ...).
function intervalNumber(noteA, noteB) {
      return Math.abs(diatonicPitch(noteB) - diatonicPitch(noteA)) + 1;
}

// Semitones between two notes.
function semitones(noteA, noteB) {
      return Math.abs(noteB.pitch - noteA.pitch);
}

// Is the melodic leap A->B an augmented second? (number 2, 3 semitones)
function isAugmentedSecond(noteA, noteB) {
      return intervalNumber(noteA, noteB) === 2 && semitones(noteA, noteB) === 3;
}

// Augmented/diminished melodic leap relevant to chorale style:
// augmented 4th (tritone, number 4), diminished 5th (tritone, number 5),
// augmented 2nd, and major 7th.
function isAugOrDimLeap(noteA, noteB) {
      var n = intervalNumber(noteA, noteB);
      var s = semitones(noteA, noteB);
      if (s === 6 && (n === 4 || n === 5)) return true;  // aug4 / dim5
      if (n === 2 && s === 3) return true;               // augmented 2nd
      if (n === 7 && s === 11) return true;              // melodic major 7th
      return false;
}

// ---------------------------------------------------------------------------
// 2. Chord identification
// ---------------------------------------------------------------------------

// Chord templates as sets of intervals (in semitones) above the root. The
// check order prioritizes sevenths over triads.
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

// Identify the chord from the pitch classes present and the pitch class of the
// bass (lowest note). Returns null if nothing matches.
//   -> { rootPc, quality, inversion, seventhPc | null, thirdPc, fifthPc }
// inversion: 0 (root position), 1, 2, 3.
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
      if (bassRel === tmpl.intervals[1]) return 1;     // third in bass
      if (bassRel === tmpl.intervals[2]) return 2;     // fifth in bass
      if (tmpl.seventh !== null && bassRel === tmpl.seventh) return 3;
      return 0;
}

// Which chord member is this pitch class?
//   -> "root" | "third" | "fifth" | "seventh" | "none"
function chordMemberOf(pc, chord) {
      if (pc === chord.rootPc) return "root";
      if (pc === chord.thirdPc) return "third";
      if (pc === chord.fifthPc) return "fifth";
      if (chord.seventhPc !== null && pc === chord.seventhPc) return "seventh";
      return "none";
}

// ---------------------------------------------------------------------------
// 3. Key and scale degrees
// ---------------------------------------------------------------------------

// Pitch class of the tonic from the number of accidentals in the key signature.
// keySig: -7..7 (negative = flats). Returns the MAJOR tonic.
function keySigToTonicPc(keySig) {
      // Each sharp goes up a fifth (7 semitones) from C.
      return ((keySig * 7) % 12 + 12) % 12;
}

// Pitch class of the leading tone (raised 7th) in both major and harmonic minor.
function leadingTonePc(tonicPc) {
      return (tonicPc + 11) % 12;
}

var MAJOR_DEGREE_SEMI = { 0: "I", 2: "II", 4: "III", 5: "IV", 7: "V", 9: "VI", 11: "VII" };
// Harmonic minor: III with augmented 5th and VII (leading tone) on tonicPc+11.
var MINOR_DEGREE_SEMI = { 0: "i", 2: "ii", 3: "III", 5: "iv", 7: "V", 8: "VI", 11: "vii" };

// Roman-numeral degree of a root relative to the tonic/mode.
// mode: "major" | "minor". Returns null if the root is chromatic.
function scaleDegree(rootPc, tonicPc, mode) {
      var rel = ((rootPc - tonicPc) % 12 + 12) % 12;
      var table = mode === "minor" ? MINOR_DEGREE_SEMI : MAJOR_DEGREE_SEMI;
      return table.hasOwnProperty(rel) ? table[rel] : null;
}

// Normalize a degree to an uppercase roman numeral without quality (I..VII).
function degreeRoot(degree) {
      return degree ? degree.toUpperCase() : null;
}

// ---------------------------------------------------------------------------
// 4. Vocal ranges (SATB) in MIDI pitch.
//    Practical ranges commonly used for chorale exercises.
// ---------------------------------------------------------------------------
var VOICE_RANGES = {
      S: { min: 60, max: 81, name: "Soprano" },  // C4 - A5
      A: { min: 55, max: 74, name: "Alto" },     // G3 - D5
      T: { min: 48, max: 69, name: "Tenor" },    // C3 - A4
      B: { min: 40, max: 62, name: "Bass" }      // E2 - D4
};

function outOfRange(pitch, voiceKey) {
      var r = VOICE_RANGES[voiceKey];
      if (!r) return false;
      return pitch < r.min || pitch > r.max;
}

// ---------------------------------------------------------------------------
// 5. Doubling detection within a verticality
//    notes: array of { pitch, tpc } (all sounding voices)
//    chord: output of identifyChord.
//    -> map member -> count
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
// 6. Motion between two voice pairs (parallel / hidden / contrary)
//    Each voice is given as { prev: note, cur: note }.
// ---------------------------------------------------------------------------
function sign(x) { return x > 0 ? 1 : (x < 0 ? -1 : 0); }

// Classify the motion of a perfect interval (P5 = 7, P8 = 0).
//   -> { type: "parallel"|"hidden"|"contrary-equal"|null, interval: "5"|"8"|"1" }
function classifyPerfectMotion(vUpperPrev, vUpperCur, vLowerPrev, vLowerCur) {
      var curInt = Math.abs(vUpperCur.pitch - vLowerCur.pitch);
      var prevInt = Math.abs(vUpperPrev.pitch - vLowerPrev.pitch);
      var curMod = curInt % 12;
      var isFifth = curMod === 7;
      var isOctave = curMod === 0 && curInt !== 0;   // 0 with diff 0 = unison
      var isUnison = curInt === 0;
      if (!isFifth && !isOctave && !isUnison) return null;

      var label = isFifth ? "5" : (isUnison ? "1" : "8");
      var dirUpper = sign(vUpperCur.pitch - vUpperPrev.pitch);
      var dirLower = sign(vLowerCur.pitch - vLowerPrev.pitch);

      // Real parallels: same perfect interval before and after, same direction.
      if (curInt === prevInt && dirUpper === dirLower && dirUpper !== 0) {
            return { type: "parallel", interval: label };
      }
      // Fifths/octaves reached by contrary motion onto the same perfect interval.
      if ((prevInt % 12 === curMod) && dirUpper !== 0 && dirLower !== 0 &&
            dirUpper !== dirLower) {
            return { type: "contrary-equal", interval: label };
      }
      // Hidden/direct: arrival at a P5/P8 by similar (direct) motion.
      if (dirUpper === dirLower && dirUpper !== 0 && curInt !== prevInt) {
            return { type: "hidden", interval: label };
      }
      return null;
}

// ---------------------------------------------------------------------------
// UMD: export for Node; in QML 'module' is undefined and the block is skipped.
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
