// Tests for the pure music-theory logic (Node, no MuseScore).
// Run: node choraleRulesChecker/test/logic.test.js
"use strict";
var L = require("../choraleRulesLogic.js");

var passed = 0, failed = 0;
function eq(actual, expected, msg) {
      var a = JSON.stringify(actual), e = JSON.stringify(expected);
      if (a === e) { passed++; }
      else { failed++; console.error("FAIL: " + msg + "\n   expected " + e + "\n   got      " + a); }
}
function ok(cond, msg) { eq(!!cond, true, msg); }

// Helper: note from pitch + tpc.
function n(pitch, tpc) { return { pitch: pitch, tpc: tpc }; }

// Reference TPC (C=14, circle of fifths):
// C=14 D=16 E=18 F=13 G=15 A=17 B=19
// F#=20 C#=21 G#=22 D#=23 A#=24
// Bb=12 Eb=11 Ab=10 Db=9 Gb=8

// --- tpc2pc ---
eq(L.tpc2pc(14), 0, "C -> pc 0");
eq(L.tpc2pc(16), 2, "D -> pc 2");
eq(L.tpc2pc(13), 5, "F -> pc 5");
eq(L.tpc2pc(19), 11, "B -> pc 11");
eq(L.tpc2pc(20), 6, "F# -> pc 6");
eq(L.tpc2pc(12), 10, "Bb -> pc 10");

// --- tpc2step (letter) ---
eq(L.tpc2step(14), 0, "C letter 0");
eq(L.tpc2step(16), 1, "D letter 1");
eq(L.tpc2step(13), 3, "F letter 3");
eq(L.tpc2step(19), 6, "B letter 6");

// --- augmented 2nd vs minor 3rd (both span 3 semitones) ---
// A minor: F (pitch 65, tpc 13) -> G# (pitch 68, tpc 22) = augmented 2nd
ok(L.isAugmentedSecond(n(65, 13), n(68, 22)), "F->G# is an augmented 2nd");
// A (57, 17) -> C (60, 14) = minor 3rd, NOT augmented
ok(!L.isAugmentedSecond(n(57, 17), n(60, 14)), "A->C is a minor 3rd, not aug2");

// --- aug/dim leaps ---
ok(L.isAugOrDimLeap(n(65, 13), n(71, 19)), "F->B = augmented 4th (tritone)");
ok(L.isAugOrDimLeap(n(71, 19), n(65, 13)), "B->F = diminished 5th");
ok(!L.isAugOrDimLeap(n(60, 14), n(67, 15)), "C->G = perfect 5th, not aug/dim");

// --- chord identification ---
// C major root position: C E G, bass C
var cMaj = L.identifyChord([0, 4, 7], 0);
eq(cMaj.rootPc, 0, "CMaj root C");
eq(cMaj.quality, "maj", "CMaj quality major");
eq(cMaj.inversion, 0, "CMaj root position");

// G7 (dominant of C): G B D F, bass G
var g7 = L.identifyChord([7, 11, 2, 5], 7);
eq(g7.rootPc, 7, "G7 root G");
eq(g7.quality, "dom7", "G7 dominant");
eq(g7.seventhPc, 5, "G7 seventh = F");

// G7 first inversion (B in the bass)
var g7b = L.identifyChord([7, 11, 2, 5], 11);
eq(g7b.inversion, 1, "G7 1st inversion (third in bass)");

// diminished B D F
var bdim = L.identifyChord([11, 2, 5], 11);
eq(bdim.quality, "dim", "B diminished");

// --- scale degrees ---
eq(L.scaleDegree(0, 0, "major"), "I", "C in CMaj = I");
eq(L.scaleDegree(7, 0, "major"), "V", "G in CMaj = V");
eq(L.scaleDegree(5, 0, "major"), "IV", "F in CMaj = IV");
eq(L.scaleDegree(9, 9, "minor"), "i", "A in Am = i");
eq(L.scaleDegree(4, 9, "minor"), "V", "E in Am = V");

// --- leading tone ---
eq(L.leadingTonePc(0), 11, "leading tone of CMaj = B");
eq(L.leadingTonePc(9), 8, "leading tone of Am = G#");

// --- keySig -> major tonic ---
eq(L.keySigToTonicPc(0), 0, "0 accidentals -> C");
eq(L.keySigToTonicPc(1), 7, "1 sharp -> G");
eq(L.keySigToTonicPc(-1), 5, "1 flat -> F");
eq(L.keySigToTonicPc(2), 2, "2 sharps -> D");

// --- chordMemberOf ---
eq(L.chordMemberOf(11, g7), "third", "B is the 3rd of G7 (leading tone)");
eq(L.chordMemberOf(5, g7), "seventh", "F is the 7th of G7");
eq(L.chordMemberOf(7, g7), "root", "G is the root of G7");

// --- doublings ---
// I of CMaj with doubled 3rd: C E G E -> third = 2
var dblThird = L.findDoublings([n(48,14), n(64,18), n(67,15), n(76,18)], cMaj);
eq(dblThird.third, 2, "doubled 3rd detected (count=2)");
// doubled leading tone in G7: B in two voices
var dblLeading = L.findDoublings([n(43,15), n(59,19), n(65,13), n(71,19)], g7);
eq(dblLeading.third, 2, "leading tone (3rd of V) doubled count=2");

// --- parallel motion ---
// Parallel fifths: C/G -> D/A (both ascend, interval 7 constant)
var par5 = L.classifyPerfectMotion(n(67,15), n(69,17), n(60,14), n(62,16));
eq(par5, { type: "parallel", interval: "5" }, "parallel fifths");
// Parallel octaves: C/C -> D/D
var par8 = L.classifyPerfectMotion(n(72,14), n(74,16), n(60,14), n(62,16));
eq(par8, { type: "parallel", interval: "8" }, "parallel octaves");
// Contrary motion onto a fifth: not parallel
var contrary = L.classifyPerfectMotion(n(67,15), n(72,14), n(60,14), n(53,13));
ok(contrary === null || contrary.type !== "parallel", "contrary motion is not parallel");
// Hidden (direct) fifth by similar motion onto a fifth from another interval
var hidden = L.classifyPerfectMotion(n(64,18), n(69,17), n(60,14), n(62,16));
eq(hidden.type, "hidden", "hidden 5th by direct motion");

// --- ranges ---
ok(L.outOfRange(84, "S"), "C6 out of soprano range");
ok(!L.outOfRange(72, "S"), "C5 within soprano range");
ok(L.outOfRange(36, "B"), "C2 out of bass range");

// ---------------------------------------------------------------------------
console.log("\n" + passed + " passed, " + failed + " failed.");
process.exit(failed === 0 ? 0 : 1);
