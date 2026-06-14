// Tests de la lógica musical pura (Node, sin MuseScore).
// Ejecutar: node verificadorCoral/test/logic.test.js
"use strict";
var L = require("../verificadorCoralLogic.js");

var passed = 0, failed = 0;
function eq(actual, expected, msg) {
      var a = JSON.stringify(actual), e = JSON.stringify(expected);
      if (a === e) { passed++; }
      else { failed++; console.error("FAIL: " + msg + "\n   esperado " + e + "\n   obtuvo   " + a); }
}
function ok(cond, msg) { eq(!!cond, true, msg); }

// Helper: nota a partir de pitch + tpc.
function n(pitch, tpc) { return { pitch: pitch, tpc: tpc }; }

// TPC de referencia (Do=14, línea de quintas):
// Do=14 Re=16 Mi=18 Fa=13 Sol=15 La=17 Si=19
// Fa#=20 Do#=21 Sol#=22 Re#=23 La#=24
// Sib=12 Mib=11 Lab=10 Reb=9 Solb=8

// --- tpc2pc ---
eq(L.tpc2pc(14), 0, "Do -> pc 0");
eq(L.tpc2pc(16), 2, "Re -> pc 2");
eq(L.tpc2pc(13), 5, "Fa -> pc 5");
eq(L.tpc2pc(19), 11, "Si -> pc 11");
eq(L.tpc2pc(20), 6, "Fa# -> pc 6");
eq(L.tpc2pc(12), 10, "Sib -> pc 10");

// --- tpc2step (letra) ---
eq(L.tpc2step(14), 0, "Do letra 0");
eq(L.tpc2step(16), 1, "Re letra 1");
eq(L.tpc2step(13), 3, "Fa letra 3");
eq(L.tpc2step(19), 6, "Si letra 6");

// --- 2ª aumentada vs 3ª menor (mismo nº de semitonos = 3) ---
// La menor: Fa (pitch 65, tpc 13) -> Sol# (pitch 68, tpc 22) = 2ª aumentada
ok(L.isAugmentedSecond(n(65, 13), n(68, 22)), "Fa->Sol# es 2ª aumentada");
// La (57, 17) -> Do (60, 14) = 3ª menor, NO aumentada
ok(!L.isAugmentedSecond(n(57, 17), n(60, 14)), "La->Do es 3ª menor, no 2ªaum");

// --- saltos aum/dism ---
ok(L.isAugOrDimLeap(n(65, 13), n(71, 19)), "Fa->Si = 4ª aumentada (tritono)");
ok(L.isAugOrDimLeap(n(71, 19), n(65, 13)), "Si->Fa = 5ª disminuida");
ok(!L.isAugOrDimLeap(n(60, 14), n(67, 15)), "Do->Sol = 5ª justa, no aum/dism");

// --- identificación de acordes ---
// Do mayor en estado fundamental: Do Mi Sol, bajo Do
var cMaj = L.identifyChord([0, 4, 7], 0);
eq(cMaj.rootPc, 0, "CMaj root Do");
eq(cMaj.quality, "maj", "CMaj calidad mayor");
eq(cMaj.inversion, 0, "CMaj estado fundamental");

// Sol7 (dominante de Do): Sol Si Re Fa, bajo Sol
var g7 = L.identifyChord([7, 11, 2, 5], 7);
eq(g7.rootPc, 7, "G7 root Sol");
eq(g7.quality, "dom7", "G7 dominante");
eq(g7.seventhPc, 5, "G7 séptima = Fa");

// Sol7 primera inversión (Si en el bajo)
var g7b = L.identifyChord([7, 11, 2, 5], 11);
eq(g7b.inversion, 1, "G7 1ª inversión (3ª en bajo)");

// disminuido Si Re Fa
var bdim = L.identifyChord([11, 2, 5], 11);
eq(bdim.quality, "dim", "Si dim");

// --- grados ---
eq(L.scaleDegree(0, 0, "major"), "I", "Do en DoM = I");
eq(L.scaleDegree(7, 0, "major"), "V", "Sol en DoM = V");
eq(L.scaleDegree(5, 0, "major"), "IV", "Fa en DoM = IV");
eq(L.scaleDegree(9, 9, "minor"), "i", "La en Lam = i");
eq(L.scaleDegree(4, 9, "minor"), "V", "Mi en Lam = V");

// --- sensible ---
eq(L.leadingTonePc(0), 11, "sensible de DoM = Si");
eq(L.leadingTonePc(9), 8, "sensible de Lam = Sol#");

// --- keySig -> tónica mayor ---
eq(L.keySigToTonicPc(0), 0, "0 alteraciones -> Do");
eq(L.keySigToTonicPc(1), 7, "1 sostenido -> Sol");
eq(L.keySigToTonicPc(-1), 5, "1 bemol -> Fa");
eq(L.keySigToTonicPc(2), 2, "2 sostenidos -> Re");

// --- chordMemberOf ---
eq(L.chordMemberOf(11, g7), "third", "Si es 3ª de G7 (sensible)");
eq(L.chordMemberOf(5, g7), "seventh", "Fa es 7ª de G7");
eq(L.chordMemberOf(7, g7), "root", "Sol es fundamental de G7");

// --- duplicaciones ---
// I de DoM con 3ª duplicada: Do Mi Sol Mi -> third = 2
var dobTercera = L.findDoublings([n(48,14), n(64,18), n(67,15), n(76,18)], cMaj);
eq(dobTercera.third, 2, "3ª duplicada detectada (count=2)");
// sensible duplicada en G7: Si en dos voces
var dobSensible = L.findDoublings([n(43,15), n(59,19), n(65,13), n(71,19)], g7);
eq(dobSensible.third, 2, "sensible (3ª de V) duplicada count=2");

// --- movimiento paralelo ---
// Quintas paralelas: Do/Sol -> Re/La (ambas suben, intervalo 7 constante)
var par5 = L.classifyPerfectMotion(n(67,15), n(69,17), n(60,14), n(62,16));
eq(par5, { tipo: "paralela", intervalo: "5" }, "quintas paralelas");
// Octavas paralelas: Do/Do -> Re/Re
var par8 = L.classifyPerfectMotion(n(72,14), n(74,16), n(60,14), n(62,16));
eq(par8, { tipo: "paralela", intervalo: "8" }, "octavas paralelas");
// Movimiento contrario hacia 5ª: no es paralela pero sí "contraria-igual" si prev también 5ª
var contraria = L.classifyPerfectMotion(n(67,15), n(72,14), n(60,14), n(53,13));
ok(contraria === null || contraria.tipo !== "paralela", "mov contrario no es paralela");
// 5ª oculta (directa) por movimiento directo hacia 5ª desde otro intervalo
var oculta = L.classifyPerfectMotion(n(64,18), n(69,17), n(60,14), n(62,16));
eq(oculta.tipo, "oculta", "5ª oculta por mov directo");

// --- ámbitos ---
ok(L.outOfRange(84, "S"), "Do6 fuera del ámbito de soprano");
ok(!L.outOfRange(72, "S"), "Do5 dentro del ámbito de soprano");
ok(L.outOfRange(36, "B"), "Do2 fuera del ámbito de bajo");

// ---------------------------------------------------------------------------
console.log("\n" + passed + " pasaron, " + failed + " fallaron.");
process.exit(failed === 0 ? 0 : 1);
