import QtQuick 2.15
import FileIO 3.0
import MuseScore 3.0

MuseScore {
      version: "0.3"
      title: "Check for Parallel 5ths/8ves [DEV]"
      description: "Check for parallel fifths and octaves. Marks consecutive fifths and octaves and also ascending hidden parallels."
      categoryCode: "composing-arranging-tools"
      thumbnailName: "logo.png"
      requiresScore: true

      property var colorFifth: "#ff6500"
      property var colorOctave: "#ff0050"
      property var colorHidden: "#a03500"

      property bool processAll: false
      property bool errorChords: false
      property bool cleanupBeforeRun: true

      id: checkParallels

      Component.onCompleted: {
            if (mscoreMajorVersion >= 4 && mscoreMinorVersion <= 3) {
                  title = "Check for Parallel 5ths/8ves"
                  thumbnailName = "some_thumbnail.png"
                  categoryCode = "composing-arranging-tools"
            }
      }

      MessageDialog {
            id: msgResult
            title: "Result"
            text: "Not yet set"

            onAccepted: {
                  quit()
            }

            visible: false
      }

      // Set color to black
      function resetColor(note) {
            note.color = "#000000"
      }

      // Cleanup function: remove previous text and reset colors
      function cleanupOldMarkings() {
            var markingsToRemove = ["parallel 5th", "hidden 5th", "parallel 8th", "hidden 8th"];

            var cursor = curScore.newCursor();
            cursor.rewind(0);

            while (cursor.segment) {
                  var segment = cursor.segment;

                  // FIRST: check annotations (e.g., StaffText)
                  if (segment.annotations) {
                        for (var i = 0; i < segment.annotations.length; i++) {
                              var annotation = segment.annotations[i];
                              console.log("Annotation type:", annotation.type, "Text:", annotation.text);
                              if (annotation && annotation.type === Element.STAFF_TEXT) {
                                    if (markingsToRemove.indexOf(annotation.text) !== -1) {
                                          // annotation.remove()
                                          // curScore.removeElement(annotation);
                                          console.log("This annotation will be removed now...");
                                    }
                              }
                        }
                  }

                  // SECOND: check notes (chords)
                  for (var track = 0; track < curScore.ntracks; track++) {
                        var element = segment.elementAt(track);
                        if (!element)
                              continue;

                        if (element.type === Element.CHORD) {
                              for (var i = 0; i < element.notes.length; i++) {
                              var note = element.notes[i];
                              resetColor(note);
                              }
                        }
                  }

                  cursor.next();
                  }
      }

      // Utility function to return the sign of a number
      function sgn(x) {
            return x > 0 ? 1 : x < 0 ? -1 : 0
      }

      // Function to set the color of two notes
      function markColor(note1, note2, color) {
            note1.color = color
            note2.color = color
      }

      // Function to add text to notes
      function markText(note1, note2, msg, color, trackIndex, tick) {
            markColor(note1, note2, color)
            var myText = newElement(Element.STAFF_TEXT)
            myText.text = msg
            myText.offsetY = 1
            
            var cursor = curScore.newCursor()
            cursor.rewind(0)
            cursor.track = trackIndex
            while (cursor.tick < tick) {
                  cursor.next()
            }
            cursor.add(myText)
      }

      // Main run function
      onRun: {
            console.log("start")
            if (!curScore) {
                  console.error("No score found")
                  quit()
            }
            curScore.startCmd()

            if (cleanupBeforeRun) {
                  console.log("Cleaning up old markings...")
                  cleanupOldMarkings()
            }

            // Define the start and end of the area to be checked
            var startStaff, endStaff, endTick
            var cursor = curScore.newCursor()
            cursor.rewind(1)

            if (!cursor.segment) {
                  // No selection, process entire score
                  console.log("No selection: processing whole score")
                  processAll = true
                  startStaff = 0
                  endStaff = curScore.nstaves
            } else {
                  // There is a selection
                  startStaff = cursor.staffIdx
                  cursor.rewind(2)
                  endStaff = cursor.staffIdx + 1
                  endTick = cursor.tick || curScore.lastSegment.tick + 1
                  cursor.rewind(1)
                  console.log(`Selection is: Staves(${startStaff}-${endStaff}) Ticks(${cursor.tick}-${endTick})`)
            }

            // Initialize data structure for checking parallels
            var parallelCheckData = initializeParallelCheckData(startStaff, endStaff)

            // Traverse through the staves/voices
            if (processAll) {
                  cursor.track = 0
                  cursor.rewind(0)
            } else {
                  cursor.rewind(1)
            }

            var segment = cursor.segment

            while (segment && (processAll || segment.tick < endTick)) {
                  handleSegment(segment, startStaff, endStaff, parallelCheckData)
                  segment = segment.next
            }

            // Show results
            showResults(parallelCheckData.foundParallels, parallelCheckData.errorChords)
            curScore.endCmd()
            console.log("finished")
            msgResult.visible = true
      }

      // Initialize data for checking parallels
      function initializeParallelCheckData(startStaff, endStaff) {
            var data = {
                  changed: [],
                  curNote: [],
                  prevNote: [],
                  curRest: [],
                  prevRest: [],
                  curTick: [],
                  prevTick: [],
                  foundParallels: 0,
                  errorChords: false,
            }

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

      // Process each segment
      function handleSegment(segment, startStaff, endStaff, data) {
            var startTrack = startStaff * 4
            var endTrack = endStaff * 4

            // Read notes
            for (var track = startTrack; track < endTrack; track++) {
                  var element = segment.elementAt(track)
                  if (element) {
                        if (element.type == Element.CHORD) {
                              // Handle chords (ignore grace notes)
                              handleChord(element, track, segment, data)
                        } else if (element.type == Element.REST) {
                              // Handle rests
                              handleRest(track, data)
                        } else {
                              data.changed[track] = false
                        }
                  } else {
                        data.changed[track] = false
                  }
            }

            // Find parallels
            findParallels(startTrack, endTrack, data, segment)
      }

      // Handle chord elements
      function handleChord(chord, track, segment, data) {
            var notes = chord.notes

            if (notes.length > 1) {
                  console.warn("Found chord with more than one note!")
                  data.errorChords = true
            }

            var note = notes[notes.length - 1]
            data.prevTick[track] = data.curTick[track]
            data.prevRest[track] = data.curRest[track]
            data.prevNote[track] = data.curNote[track]
            data.curRest[track] = false
            data.curNote[track] = note
            data.curTick[track] = segment.tick
            data.changed[track] = true
      }

      // Handle rest elements
      function handleRest(track, data) {
            if (!data.curRest[track]) {
                  // Was a note
                  data.prevRest[track] = data.curRest[track]
                  data.prevNote[track] = data.curNote[track]
                  data.curRest[track] = true
                  data.changed[track] = false // No need to check against a rest
            }
      }

      // Check for parallel fifths and octaves
      function findParallels(startTrack, endTrack, data, segment) {
            for (var track = startTrack; track < endTrack; track++) {
                  // Compare to other tracks
                  if (data.changed[track] && !data.prevRest[track]) {
                        var dir1 = sgn(data.curNote[track].pitch - data.prevNote[track].pitch)
                        if (dir1 === 0) continue // Voice didn't move
                        for (var i = track + 1; i < endTrack; i++) {
                              if (data.changed[i] && !data.prevRest[i]) {
                                    var dir2 = sgn(data.curNote[i].pitch - data.prevNote[i].pitch)
                                    if (dir1 === dir2) {
                                          checkInterval(track, i, dir1, data, segment)
                                    }
                              }
                        }
                  }
            }
      }

      // Check intervals for fifths and octaves
      function checkInterval(track1, track2, dir, data, segment) {
            var curInterval = data.curNote[track1].pitch - data.curNote[track2].pitch
            var prevInterval = data.prevNote[track1].pitch - data.prevNote[track2].pitch

            if (Math.abs(curInterval % 12) === 7) { // Check fifths
                  checkFifths(curInterval, prevInterval, dir, track1, track2, data)
            }

            if (Math.abs(curInterval % 12) === 0) { // Check octaves
                  checkOctaves(curInterval, prevInterval, dir, track1, track2, data, segment)
            }
      }

      // Check for parallel fifths
      function checkFifths(curInterval, prevInterval, dir, track1, track2, data) {
            if (curInterval === prevInterval) {
                  data.foundParallels++
                  console.log(`P5: ${curInterval}, ${prevInterval}`)
                  markText(data.prevNote[track1], data.prevNote[track2], "parallel 5th", colorFifth, track1, data.prevTick[track1])
                  markColor(data.curNote[track1], data.curNote[track2], colorFifth)
            } else if (dir === 1 && Math.abs(prevInterval) < Math.abs(curInterval)) {
                  // Hidden parallel
                  data.foundParallels++
                  console.log(`H5: ${curInterval}, ${prevInterval}`)
                  markText(data.prevNote[track1], data.prevNote[track2], "hidden 5th", colorHidden, track1, data.prevTick[track1])
                  markColor(data.curNote[track1], data.curNote[track2], colorHidden)
            }
      }

      // Check for parallel octaves
      function checkOctaves(curInterval, prevInterval, dir, track1, track2, data) {
            if (curInterval === prevInterval) {
                  data.foundParallels++
                  console.log(`P8: ${curInterval}, ${prevInterval}`)
                  markText(data.prevNote[track1], data.prevNote[track2], "parallel 8th", colorOctave, track1, data.prevTick[track1])
                  markColor(data.curNote[track1], data.curNote[track2], colorOctave)
            } else if (dir === 1 && Math.abs(prevInterval) < Math.abs(curInterval)) {
                  // Hidden parallel
                  data.foundParallels++
                  console.log(`H8: ${curInterval}, ${prevInterval}`)
                  markText(data.prevNote[track1], data.prevNote[track2], "hidden 8th", colorHidden, track1, data.prevTick[track1])
                  markColor(data.curNote[track1], data.curNote[track2], colorHidden)
            }
      }

      // Display results
      function showResults(parallels, chordErrors) {
            if (parallels === 0) {
                  msgResult.text = "No parallels found!\n"
            } else if (parallels === 1) {
                  msgResult.text = "One parallel found!\n"
            } else {
                  msgResult.text = `${parallels} parallels found!\n`
            }

            if (chordErrors) {
                  msgResult.text += "\nError: Found Chords!\nOnly the top note of each voice is used in this plugin!\n"
            }
      }
}
