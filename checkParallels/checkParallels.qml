import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FileIO 3.0

import MuseScore 3.0
import Muse.UiComponents 1.0

MuseScore {
      version: "0.9"
      title: "Check for Parallels"
      description: "Check for parallel fifths and octaves. Marks consecutive fifths and octaves and also ascending hidden parallels."
      categoryCode: "composing-arranging-tools"
      thumbnailName: "logo.png"
      requiresScore: true
      pluginType: "dialog"

      implicitHeight: 590
      implicitWidth: 230

      property var colorFifth: "#ff6500"
      property var colorOctave: "#ff0050"
      property var colorHidden: "#a03500"

      property bool onlyColor: false
      property bool dryRun: false
      property bool processAll: false
      property bool errorChords: false
      property bool cleanupBeforeRun: true

      property bool detectFifths: true
      property bool detectOctaves: true
      property bool detectHiddenFifths: true
      property bool detectHiddenOctaves: true

      property var detectedFifths: 0
      property var detectedOctaves: 0
      property var detectedHiddenFifths: 0
      property var detectedHiddenOctaves: 0

      id: checkParallels
      ColorPickerModel { id: colorPickerModel }

      Component.onCompleted: {
            if (mscoreMajorVersion >= 4 && mscoreMinorVersion <= 3) {
                  title = "Check for Parallel 5ths/8ves"
                  thumbnailName = "logo.png"
                  categoryCode = "composing-arranging-tools"
            }
      }

      Dialog {
            id: settingsDialog
            title: "Check for Parallels - Settings"
            modal: true
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
            visible: false

            ScrollView {
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        GroupBox {
                              title: "Detection Options"
                              Layout.fillWidth: true

                              ColumnLayout {
                                    CheckBox { id: fifthsCheckbox; text: "Parallel Fifths"; checked: detectFifths; onClicked: {detectFifths = !detectFifths} }
                                    CheckBox { id: octavesCheckbox; text: "Parallel Octaves"; checked: detectOctaves; onClicked: {detectOctaves = !detectOctaves} }
                                    CheckBox { id: hiddenFifthsCheckbox; text: "Hidden Fifths"; checked: detectHiddenFifths; onClicked: {detectHiddenFifths = !detectHiddenFifths} }
                                    CheckBox { id: hiddenOctavesCheckbox; text: "Hidden Octaves"; checked: detectHiddenOctaves; onClicked: {detectHiddenOctaves = !detectHiddenOctaves} }
                              }
                        }

                        GroupBox {
                              title: "Marking Options"
                              Layout.fillWidth: true

                              ColumnLayout {
                                    CheckBox { id: onlyColorCheckbox; text: "Only color notes (no StaffText)"; checked: onlyColor; onClicked: {onlyColor = !onlyColor} }
                                    CheckBox {
                                          id: testRunCheckbox
                                          text: "No markings (Dry run)"
                                          checked: dryRun
                                          onClicked: {dryRun = !dryRun}
                                    }
                              }
                        }

                        GroupBox {
                              title: "Colors"
                              Layout.fillWidth: true

                              ColumnLayout {
                                    spacing: 15

                                    ColumnLayout {
                                          spacing: 5
                                          Label {
                                                id: fifthColorLabel
                                                text: "Fifths"
                                                Layout.fillWidth: true
                                                font.bold: true
                                          }
                                          RowLayout {
                                                spacing: 10
                                                Rectangle {
                                                      width: 20
                                                      height: 20
                                                      color: colorFifth
                                                      radius: 5

                                                      MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: {
                                                                  var newColor = colorPickerModel.selectColor(colorFifth)
                                                                  if (newColor) colorFifth = newColor
                                                            }
                                                      }
                                                }
                                                Label {
                                                      id: fifthColorValueLabel
                                                      text: colorFifth
                                                }
                                          }
                                    }

                                    ColumnLayout {
                                          spacing: 5
                                          Label {
                                                id: octaveColorLabel
                                                text: "Octaves"
                                                Layout.fillWidth: true
                                                font.bold: true
                                          }
                                          RowLayout {
                                                spacing: 10
                                                Rectangle {
                                                      width: 20
                                                      height: 20
                                                      color: colorOctave
                                                      radius: 5

                                                      MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: {
                                                                  var newColor = colorPickerModel.selectColor(colorOctave)
                                                                  if (newColor) colorOctave = newColor
                                                            }
                                                      }
                                                }
                                                Label {
                                                      id: octaveColorValueLabel
                                                      text: colorOctave
                                                }
                                          }
                                    }

                                    ColumnLayout {
                                          spacing: 5
                                          Label {
                                                id: hiddenColorLabel
                                                text: "Hidden Parallels"
                                                Layout.fillWidth: true
                                                font.bold: true
                                          }
                                          RowLayout {
                                                spacing: 10
                                                Rectangle {
                                                      width: 20
                                                      height: 20
                                                      color: colorHidden
                                                      radius: 5

                                                      MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: {
                                                                  var newColor = colorPickerModel.selectColor(colorHidden)
                                                                  if (newColor) colorHidden = newColor
                                                            }
                                                      }
                                                }
                                                Label {
                                                      id: hiddenColorValueLabel
                                                      text: colorHidden
                                                }
                                          }
                                    }
                                    Button {
                                          text: "Reset Colors to Default"
                                          onClicked: {
                                                colorFifth = "#ff6500"
                                                colorOctave = "#ff0050"
                                                colorHidden = "#a03500"
                                          }
                                    }
                              }
                        }
                  }
            }

            onAccepted: {
                  console.log("Settings saved. Running plugin...")
                  startCheck() // <- Now run plugin
            }

            onRejected: {
                  console.log("Settings canceled.")
                  quit()
            }
      }

      MessageDialog {
            id: msgResult
            title: "Result"
            text: "Not yet set"
            onAccepted: { quit() }
            visible: false
      }

      function openSettings() {
            settingsDialog.open()
      }

      // Helper to reset color
      function resetColor(note) { note.color = "#000000" }

      // Cleanup function
      function cleanupOldMarkings() {
            var markingsToRemove = ["parallel 5th", "hidden 5th", "parallel 8th", "hidden 8th"]
            var cursor = curScore.newCursor()
            cursor.rewind(0)

            while (cursor.segment) {
                  var segment = cursor.segment
                  if (segment.annotations) {
                        for (var i = 0; i < segment.annotations.length; i++) {
                              var annotation = segment.annotations[i]
                              if (annotation && annotation.type === Element.STAFF_TEXT && markingsToRemove.indexOf(annotation.text) !== -1) {
                                    removeElement(annotation)
                              }
                        }
                  }

                  for (var track = 0; track < curScore.ntracks; track++) {
                        var element = segment.elementAt(track)
                        if (!element) continue
                        if (element.type === Element.CHORD) {
                              for (var i = 0; i < element.notes.length; i++) {
                                    resetColor(element.notes[i])
                              }
                        }
                  }

                  cursor.next()
            }
      }

      function signOfDifference(x) { return x > 0 ? 1 : x < 0 ? -1 : 0 }

      function markColor(note1, note2, color) {
            note1.color = color
            note2.color = color
      }

      function markText(note1, note2, msg, color, trackIndex, tick) {
            markColor(note1, note2, color)
            if (onlyColor) return

            var myText = newElement(Element.STAFF_TEXT)
            myText.text = msg
            myText.offsetY = 1

            var cursor = curScore.newCursor()
            cursor.rewind(0)
            cursor.track = trackIndex
            while (cursor.tick < tick) { cursor.next() }
            cursor.add(myText)
      }

      // --- MAIN CHECKING STARTS HERE ---

      function startCheck() {
            if (!curScore) {
                  console.error("No score found")
                  quit()
                  return
            }

            curScore.startCmd()

            if (cleanupBeforeRun) {
                  console.log("Cleaning up old markings...")
                  cleanupOldMarkings()
            }

            var startStaff, endStaff, endTick
            var cursor = curScore.newCursor()
            cursor.rewind(1)

            if (!cursor.segment) {
                  processAll = true
                  startStaff = 0
                  endStaff = curScore.nstaves
            } else {
                  startStaff = cursor.staffIdx
                  cursor.rewind(2)
                  endStaff = cursor.staffIdx + 1
                  endTick = cursor.tick || curScore.lastSegment.tick + 1
                  cursor.rewind(1)
            }

            var data = initializeParallelCheckData(startStaff, endStaff)

            if (processAll) {
                  cursor.track = 0
                  cursor.rewind(0)
            } else {
                  cursor.rewind(1)
            }

            var segment = cursor.segment
            while (segment && (processAll || segment.tick < endTick)) {
                  handleSegment(segment, startStaff, endStaff, data)
                  segment = segment.next
            }

            showResults(data.foundParallels, data.errorChords)
            curScore.endCmd()
            msgResult.visible = true
      }

      function initializeParallelCheckData(startStaff, endStaff) {
            var data = { changed: [], curNote: [], prevNote: [], curRest: [], prevRest: [], curTick: [], prevTick: [], foundParallels: 0, errorChords: false }
            var startTrack = startStaff * 4
            var endTrack = endStaff * 4

            for (var track = startTrack; track < endTrack; track++) {
                  data.curRest[track] = true
                  data.prevRest[track] = true
                  data.changed[track] = false
                  data.curNote[track] = 0
                  data.prevNote[track] = 0
                  data.curTick[track] = 0
                  data.prevTick[track] = 0
            }

            return data
      }

      function handleSegment(segment, startStaff, endStaff, data) {
            var startTrack = startStaff * 4
            var endTrack = endStaff * 4

            for (var track = startTrack; track < endTrack; track++) {
                  var element = segment.elementAt(track)
                  if (element) {
                        if (element.type == Element.CHORD) handleChord(element, track, segment, data)
                        else if (element.type == Element.REST) handleRest(track, data)
                        else data.changed[track] = false
                  } else {
                        data.changed[track] = false
                  }
            }

            findParallels(startTrack, endTrack, data, segment)
      }

      function handleChord(chord, track, segment, data) {
            var notes = chord.notes
            if (notes.length > 1) data.errorChords = true

            var note = notes[notes.length - 1]
            data.prevTick[track] = data.curTick[track]
            data.prevRest[track] = data.curRest[track]
            data.prevNote[track] = data.curNote[track]
            data.curRest[track] = false
            data.curNote[track] = note
            data.curTick[track] = segment.tick
            data.changed[track] = true
      }

      function handleRest(track, data) {
            if (!data.curRest[track]) { // only detect when transitioning from note to rest (not for multiple rests)
                  data.prevRest[track] = data.curRest[track]
                  data.prevNote[track] = data.curNote[track]
                  data.curRest[track] = true
                  data.changed[track] = false
            }
      }

      function findParallels(startTrack, endTrack, data, segment) {
            for (var track = startTrack; track < endTrack; track++) {
                  if (data.changed[track] && !data.prevRest[track]) {
                        var dir1 = signOfDifference(data.curNote[track].pitch - data.prevNote[track].pitch)
                        if (dir1 === 0) continue
                        for (var i = track + 1; i < endTrack; i++) {
                              if (data.changed[i] && !data.prevRest[i]) {
                                    var dir2 = signOfDifference(data.curNote[i].pitch - data.prevNote[i].pitch)
                                    if (dir1 === dir2) {
                                          checkInterval(track, i, dir1, data, segment)
                                    }
                              }
                        }
                  }
            }
      }

      function checkInterval(track1, track2, dir, data, segment) {
            var curInterval = data.curNote[track1].pitch - data.curNote[track2].pitch
            var prevInterval = data.prevNote[track1].pitch - data.prevNote[track2].pitch

            if (Math.abs(curInterval % 12) === 7) checkFifths(curInterval, prevInterval, dir, track1, track2, data)
            if (Math.abs(curInterval % 12) === 0) checkOctaves(curInterval, prevInterval, dir, track1, track2, data)
      }

      function checkFifths(curInterval, prevInterval, dir, track1, track2, data) {
            if (!detectFifths && !detectHiddenFifths) return

            if (curInterval === prevInterval && detectFifths) {
                  detectedFifths++
                  data.foundParallels++
                  if (!dryRun) {
                        markText(data.prevNote[track1], data.prevNote[track2], "parallel 5th", colorFifth, track1, data.prevTick[track1])
                        markColor(data.curNote[track1], data.curNote[track2], colorFifth)
                  }
            } else if (dir === 1 && Math.abs(prevInterval) < Math.abs(curInterval) && detectHiddenFifths) {
                  detectedHiddenFifths++
                  data.foundParallels++
                  if (!dryRun) {
                        markText(data.prevNote[track1], data.prevNote[track2], "hidden 5th", colorHidden, track1, data.prevTick[track1])
                        markColor(data.curNote[track1], data.curNote[track2], colorHidden)
                  }
            }
      }

      function checkOctaves(curInterval, prevInterval, dir, track1, track2, data) {
            if (!detectOctaves && !detectHiddenOctaves) return

            if (curInterval === prevInterval && detectOctaves) {
                  detectedOctaves++
                  data.foundParallels++
                  if (!dryRun) {
                        markText(data.prevNote[track1], data.prevNote[track2], "parallel 8th", colorOctave, track1, data.prevTick[track1])
                        markColor(data.curNote[track1], data.curNote[track2], colorOctave)
                  }
            } else if (dir === 1 && Math.abs(prevInterval) < Math.abs(curInterval) && detectHiddenOctaves) {
                  detectedHiddenOctaves++
                  data.foundParallels++
                  if (!dryRun) {
                        markText(data.prevNote[track1], data.prevNote[track2], "hidden 8th", colorHidden, track1, data.prevTick[track1])
                        markColor(data.curNote[track1], data.curNote[track2], colorHidden)
                  }
            }
      }

      function showResults(parallels, chordErrors) {
            if (parallels === 0) {
                  msgResult.text = "No parallels found!"
            } else if (parallels === 1) {
                  msgResult.text = "One parallel found:"
            } else {
                  msgResult.text = `${parallels} parallels found:`
            }

            if (parallels > 0) {
                  msgResult.text += `\n\nOctaves: ${detectedOctaves}`
                  msgResult.text += `\nFifths: ${detectedFifths}`
                  msgResult.text += `\nHidden Octaves: ${detectedHiddenOctaves}`
                  msgResult.text += `\nHidden Fifths: ${detectedHiddenFifths}`
            }

            if (chordErrors) {
                  msgResult.text += "\n\nWarning: Found chords (multiple notes per voice). Only top note used!"
            }
      }

      onRun: {
            openSettings()
      }
}
