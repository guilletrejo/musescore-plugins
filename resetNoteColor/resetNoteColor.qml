import QtQuick 2.15
import MuseScore 3.0
 
MuseScore {
      version:  "2.1"
      title: "Reset note color"
      description: "This plugin clears colors from note heads."
      // pluginType: "dialog"
      categoryCode: "composing-arranging-tools"
      thumbnailName: "logo.png"
      requiresScore: true
 
      property var colorFifth: "#ff6500";
      property var colorOctave: "#ff0050";
      property var colorHidden: "#a03500";
      property var colorNear: "#a06500";

 
      property var colorBlack: "#000000" ;
      // Apply the given function to all notes in selection or, if nothing is selected, in the entire score
      function applyToNotesInSelection(func) {
            if (typeof curScore === 'undefined')
                  return;
       
            var cursor     = curScore.newCursor();
            cursor.rewind(1);
            var startStaff  = cursor.staffIdx;
            cursor.rewind(2);
            var endStaff   = cursor.staffIdx;
            var endTick    = cursor.tick // if no selection, end of score
            var fullScore = false;
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff
                  endStaff = curScore.nstaves; // and end with last
            }
       console.log(startStaff + " - " + endStaff + " - " + endTick)
            for (var staff = startStaff; staff <= endStaff; staff++) {
                  for (var voice = 0; voice < 4; voice++) {          
                        cursor.rewind(1); // sets voice to 0
                        cursor.voice = voice; //voice has to be set after goTo
                        cursor.staffIdx = staff;

                        if (!cursor.segment)
                              cursor.rewind(0) // if no selection, beginning of score

                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type == Element.CHORD) {
                                    var notes = cursor.element.notes;
                                    for (var i = 0; i < notes.length; i++) {
                                          var note = notes[i];
                                          func(note);
                                    }
                              }
                              cursor.next();
                        }
                  }
            }
      }
 
      function colorNote(note) {
            //note.color = colors[note.pitch % 12];
            var curcol = note.color;
            if( curcol ==  colorFifth  || curcol ==  colorOctave  || curcol == colorHidden || curcol == colorNear ) {
           	 note.color = colorBlack;
            }
      }
 
      onRun: {
            console.log("Starting Reset note color...");
 
            if (typeof curScore === 'undefined')
                  // Qt.quit();
                  return;
 
            applyToNotesInSelection(colorNote)
 
            // Qt.quit();
            return;
         }
}
