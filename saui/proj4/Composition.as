package saui.proj4
{
	import flash.display.*;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.media.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;

	/**
	 * The Composition class contains the song that the user records and edits. During recording, 
	 * it draws the staff, positions notes, and cleans up notation.  During editing, it allows user 
	 * to click on notes to select them and then use keyboard to move pitch up/down or note position 
	 * left/right.  The composition includes a cursor that shows where recording/playback will begin;
	 * user can double-click to move cursor around.  The Composition also contains a metronome.
	 * 
	 * @author Jenny Schweers
	 */
	public class Composition extends UIComponent
	{
		public static const WIDTH : int = MusicContainer.WIDTH - 20;
		public static const HEIGHT : int = 300;
		
		public static const BEATS_PER_LINE : int = 20;														// 20 beats (5 measures) per line
		public static const BEATS_PER_MEASURE : int = 4;													// everything is in 4/4 time signature
		public static const NUM_LINES : int = 2;															// two lines in composition
		
		// constants for drawing
		public static const SPACE_HEIGHT : int = 6;		
		public static const X_OFFSET : int = 5;																// x offset of entire staff
		public static const BRACE_WIDTH : int = 5;
		public static const BRACE_HEIGHT : int = 72;
		public static const STAFF_X_OFFSET : int = BRACE_WIDTH + 2;											// x offset of staff lines
		public static const TREBLE_STAFF_Y_OFFSET : int = 45;												// y offset of top treble staff line
		public static const BASS_STAFF_Y_OFFSET : int = TREBLE_STAFF_Y_OFFSET + 50;							// y offset of top bass staff line
		public static const CLEF_OFFSET : int = 5;
		public static const TREBLE_CLEF_WIDTH : int = 15;
		public static const TREBLE_CLEF_HEIGHT : int = 43;
		public static const TREBLE_CLEF_Y_OFFSET : int = TREBLE_STAFF_Y_OFFSET - 8;
		public static const BASS_CLEF_WIDTH : int = 17;
		public static const BASS_CLEF_HEIGHT : int = 20;
		public static const BASS_CLEF_Y_OFFSET : int = TREBLE_CLEF_Y_OFFSET + 59;
		public static const MUSIC_X_OFFSET : int = STAFF_X_OFFSET + CLEF_OFFSET + BASS_CLEF_WIDTH + 20;		// x offset where notes can start being drawn
		public static const STAFF_WIDTH : int = MUSIC_X_OFFSET + Note.WIDTH * BEATS_PER_LINE * 2 - 11;		// staff line width
		public static const TREBLE_BASS_LINE : int = HEIGHT / 4 + SPACE_HEIGHT * 2;							// y offset of invisible dividing line between treble and bass
		
		private var notes : Array = null;						// array of Canvas objects, one per half-beat of time.
																// Note at beat x is stored at notes[x * 2]
																// Note objects get added as children to canvases.
		
		private var _bpm : int = 0;								// beats per minute
		private var metronome : int = 0;						// metronome beat, 0 to 3
		private var metronomeInterval : int = 0;
		private var metronomeSound : Sound = null;
		private var cursor : Shape = null;						// rounded rectangle showing where we're currently playing/recording
		
		private var selectStartBeat : Number = -1;				// first beat selected
		private var selectNumBeats : Number = 0;				// length, in beats, of selection
		private var selectIsTreble : Boolean = false;			// does selection include treble clef?
		private var selectBothClefs : Boolean = false;			// does selection include both clefs?
		private var highlight : Shape = null;
		
		/**
		 * Constructor.
		 */
		public function Composition(x:int, y:int, bpm:int)
		{
			super();
			
			notes = new Array(BEATS_PER_LINE * 2 * 2);
			for (var i : int = 0; i < notes.length; i++) {
				notes[i] = new Canvas();
				notes[i].x = MUSIC_X_OFFSET + (i % (BEATS_PER_LINE * 2)) * Note.WIDTH;
				if (i < BEATS_PER_LINE * 2) {
					notes[i].y = 0;
				}
				else {
					notes[i].y = HEIGHT / 2;
				}
				notes[i].width = Note.WIDTH;
				notes[i].height = HEIGHT / 2;
				this.addChild(notes[i]);
			}
			
			this.x = x;
			this.y = y;
			
			this.bpm = bpm;
			this.metronomeSound = ResourceFactory.getSound(ResourceFactory.METRONOME);
			cursor = new Shape();
			cursor.graphics.lineStyle(3, 0x000000, 0.1);
			cursor.graphics.drawRoundRect(0, -Note.HEIGHT / 2, Note.WIDTH, Composition.BASS_STAFF_Y_OFFSET - Composition.TREBLE_STAFF_Y_OFFSET + Composition.SPACE_HEIGHT * 4 + Note.HEIGHT, Note.HEIGHT);
			cursor.graphics.endFill();
			this.addChild(cursor);
			
			highlight = new Shape();
			highlight.x = MUSIC_X_OFFSET;
			highlight.y = 0;
			this.addChild(highlight);
			
			this.height = HEIGHT;
			this.width = WIDTH;
			
			this.clear();
		}
		
		/**
		 * Getter for beats per minute.
		 */
		public function get bpm() : int {return _bpm;}
		
		/**
		 * Setter for beats per minute (requires resetting metronome).
		 */
		public function set bpm(bpm : int) : void {
			_bpm = bpm;
			setMetronome(0);
		}
		
		/**
		 * Move cursor to highlight given slice of time.
		 */
		public function setCursor(beat:Number) : void {
			cursor.x = MUSIC_X_OFFSET + (beat % BEATS_PER_LINE) * Note.WIDTH * 2;
			cursor.y = TREBLE_STAFF_Y_OFFSET;
			if (beat >= Composition.BEATS_PER_LINE) {
				cursor.y += Composition.HEIGHT / 2;
			}
		}
		
		/**
		 * Set metronome to given beat (0 to 3).  Resets metronome interval.
		 */
		public function setMetronome(beat:int) : void {
			metronome = beat;
			if (metronomeInterval) {
				clearInterval(metronomeInterval);
				tick();
				metronomeInterval = setInterval(tick, msPerBeat());
			}
		}
		
		/**
		 * Turn metronome on/off.
		 */
		public function toggleMetronome(evt:MouseEvent) : void {
			if (metronomeInterval == 0) {
				tick();
				metronomeInterval = setInterval(tick, msPerBeat());
			}
			else {
				clearInterval(metronomeInterval);
				metronomeInterval = 0;
			}
		}
		
		/**
		 * Play metronome sound - loud for first beat of measure, softer for others.
		 */
		 
		private function tick() : void {
			if (metronome == 0) {
				//metronomeSound.play(0, 0, new SoundTransform(0.8));
				metronomeSound.play(0, 0, new SoundTransform(1));
			}
			else {
				//metronomeSound.play(0, 0, new SoundTransform(0.2));
				metronomeSound.play(0, 0, new SoundTransform(0.5));
			}
			metronome = (metronome + 1) % 4;
		}
		
		/**
		 * Returns number of milliseconds per beat, beased on this.bpm.
		 */
		public function msPerBeat() : Number {
			return (1 / (this.bpm / 60) * 1000);
		}
		
		/**
		 * Returns number of milliseconds per beat, beased on given bpm.
		 */
		public static function msPerBeat(bpm:Number) : Number {
			return (1 / (bpm / 60) * 1000);
		}
		
		/**
		 * Draw composition.  Draws white background and staffs.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.graphics.clear();
			this.graphics.beginFill(0xffffff);
			this.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			this.graphics.endFill();
			drawStaff(X_OFFSET, 0);
			drawStaff(X_OFFSET, HEIGHT / 2);
		}
		
		/**
		 * Draw single staff (treble + bass).
		 */
		private function drawStaff(x:int, y:int) : void {
			this.graphics.lineStyle();

			// brace image
			var m : Matrix = new Matrix();
			m.translate(x, y + TREBLE_STAFF_Y_OFFSET);
			this.graphics.beginBitmapFill(ResourceFactory.getImage(ResourceFactory.BRACE), m);
			this.graphics.drawRect(x, y + TREBLE_STAFF_Y_OFFSET, BRACE_WIDTH, BRACE_HEIGHT);
			this.graphics.endFill();
			
			// clef images
			m.identity();
			m.translate(x + BRACE_WIDTH + CLEF_OFFSET, y + TREBLE_CLEF_Y_OFFSET);
			this.graphics.beginBitmapFill(ResourceFactory.getImage(ResourceFactory.TREBLE_CLEF), m);
			this.graphics.drawRect(x + BRACE_WIDTH + CLEF_OFFSET, y + TREBLE_CLEF_Y_OFFSET, TREBLE_CLEF_WIDTH, TREBLE_CLEF_HEIGHT);
			this.graphics.endFill();
			
			m.identity();
			m.translate(x + BRACE_WIDTH + CLEF_OFFSET, y + BASS_CLEF_Y_OFFSET);
			this.graphics.beginBitmapFill(ResourceFactory.getImage(ResourceFactory.BASS_CLEF), m);
			this.graphics.drawRect(x + BRACE_WIDTH + CLEF_OFFSET, y + BASS_CLEF_Y_OFFSET, BASS_CLEF_WIDTH, BASS_CLEF_HEIGHT);
			this.graphics.endFill();

			// time signature
			var fours : Array = new Array(4);
			var textFormat : TextFormat = new TextFormat();
			textFormat.size = 16;
			textFormat.bold = true;
			for (var i : int = 0; i < fours.length; i++) {
				fours[i] = new TextField();
				fours[i].defaultTextFormat = textFormat;
				fours[i].text = "4";
				fours[i].x = 32;
				fours[i].width = 20;
				fours[i].height = 20;
				this.addChild(fours[i]);
			}
			fours[0].y = y + TREBLE_STAFF_Y_OFFSET - 2;
			fours[1].y = y + TREBLE_STAFF_Y_OFFSET + 10;
			fours[2].y = y + BASS_STAFF_Y_OFFSET - 2;
			fours[3].y = y + BASS_STAFF_Y_OFFSET + 10;

			// staff lines
			this.graphics.lineStyle(1, 0x000000);
			for (i = 0; i < 5; i++) {
				this.graphics.moveTo(x + STAFF_X_OFFSET, y + TREBLE_STAFF_Y_OFFSET + i * SPACE_HEIGHT);
				this.graphics.lineTo(x + STAFF_WIDTH + STAFF_X_OFFSET, y + TREBLE_STAFF_Y_OFFSET + i * SPACE_HEIGHT);
			}
			for (i = 0; i < 5; i++) {
				this.graphics.moveTo(x + STAFF_X_OFFSET, y + BASS_STAFF_Y_OFFSET + i * SPACE_HEIGHT);
				this.graphics.lineTo(x + STAFF_WIDTH + STAFF_X_OFFSET, y + BASS_STAFF_Y_OFFSET + i * SPACE_HEIGHT);
			}
			this.graphics.moveTo(x + STAFF_X_OFFSET, y + TREBLE_STAFF_Y_OFFSET);
			this.graphics.lineTo(x + STAFF_X_OFFSET, y + BASS_STAFF_Y_OFFSET + SPACE_HEIGHT * 4);
			
			// measure lines
			var xOffset : int = MUSIC_X_OFFSET;
			var yOffset : int = 0;
			i = 1;
			while (i <= BEATS_PER_LINE * NUM_LINES / 4) {
				if (i > BEATS_PER_LINE / 4) {
					yOffset = HEIGHT / NUM_LINES;
				}
				this.graphics.moveTo(xOffset + ((i % (BEATS_PER_LINE / 4)) + 1) * 4 * Note.WIDTH * 2, yOffset + TREBLE_STAFF_Y_OFFSET);
				this.graphics.lineTo(xOffset + ((i % (BEATS_PER_LINE / 4)) + 1) * 4 * Note.WIDTH * 2, yOffset + BASS_STAFF_Y_OFFSET + SPACE_HEIGHT * 4);
				i++;
			}
		}
		
		/**
		 * Execute given function on all notes in composition.
		 * 
		 * @param callback Function that takes one parameter, a Note object.
		 */
		private function notesMapAll(callback:Function) : void {
			notes.forEach(function(element:Canvas, index:int, a:Array) : void {
				for (var i : int = 0; i < element.numChildren; i++) {
					callback(Note(element.getChildAt(i)));
				}
			});
		}
		
		/**
		 * Execute given function on a range of notes in composition.
		 * 
		 * @param startBeat The time to start at, measured in beats.
		 * @param numBeats The time range to cover, measured in beats.
		 * @param callback The function to call, which takes two parameters: a Note object 
		 * and an index that will be passed the index in this.notes where that Note is stored. 
		 */
		private function notesMapRange(startBeat:Number, numBeats:Number, callback:Function) : void {
			notes.slice(startBeat * 2, (startBeat + numBeats) * 2).forEach(function(element:Canvas, index:int, a:Array) : void {
				for (var i : int = element.numChildren - 1; i >= 0; i--) {
					callback(Note(element.getChildAt(i)), index + startBeat * 2);
				}
			});
		}
		
		/**
		 * Standardize notation for a given time range.  
		 * 
		 * This will fill blank spaces in with rests, combine sequential rests into bigger rests, 
		 * and redraw any notes that cross measure lines as tied notes. 
		 * 
		 * Function will round down given start beat to the beginning of its
		 * measure and then subtract another measure.  The ending beat will be rounded up to the end of its measure and then
		 * have another measure added.
		 */
		public function clean(startBeat:Number, numBeats:Number) : void {
			// round up/down so we're always starting at the start of a measure and doing an extra measure on either side
			numBeats += BEATS_PER_MEASURE * 2;
			startBeat -= BEATS_PER_MEASURE;
			if (startBeat < 0) {
				numBeats += startBeat;
				startBeat = 0;
			}
			startBeat -= startBeat % BEATS_PER_MEASURE;
			numBeats += startBeat % BEATS_PER_MEASURE;
			numBeats = Math.ceil(numBeats / 4) * 4;
			//trace("---cleaning " + numBeats + " beats, starting at " + startBeat);
			
			// Fill in rests
			var absMax : int = MusicContainer(this.parent).maxBeat * 2;
			if (MusicContainer(this.parent).mode == MusicContainer.MODE_EDIT) {
				absMax--;
			}
			var i : Number = Math.min(absMax, (startBeat + numBeats) * 2 - 1);
			var trebleRestBeats : Number = 0;
			var bassRestBeats : Number = 0;
			var active : Array = null;
			var n : Note = null; 
			while (i >= 0) {
				// look for which clefs have notes
				active = activeNotes(i / 2);
				if (active.some(function(item:Note, index:int, a:Array) : Boolean {
						return Note.isTreble(item.pitch, item.octave);
					})) {
					if (trebleRestBeats) {
						//trace("treble note is active here (" + (i / 2) + ") and trebleRestBeats="+trebleRestBeats+", so put a rest at the beat after this one");
						setRest(Note.TREBLE_REST, trebleRestBeats, i / 2 + 0.5);
						trebleRestBeats = 0;
					}
					// remove any treble rest that starts here
					for (var j : int = notes[i].numChildren - 1; j >= 0; j--) {
						if (notes[i].getChildAt(j).pitch == Note.TREBLE_REST) {
							notes[i].removeChildAt(j);
						}
					}
				}
				else {
					//trace("no treble note here, so increment restBeats");
					trebleRestBeats += 0.5;
				}
				
				if (active.some(function(item:Note, index:int, a:Array) : Boolean {
						return !Note.isTreble(item.pitch, item.octave);
					})) {
					if (bassRestBeats) {
						setRest(Note.BASS_REST, bassRestBeats, i / 2 + 0.5);
						bassRestBeats = 0;
					}
					// remove any bass rest that starts here
					for (j = notes[i].numChildren - 1; j >= 0; j--) {
						if (notes[i].getChildAt(j).pitch == Note.BASS_REST) {
							notes[i].removeChildAt(j);
						}
					}
				}
				else {
					bassRestBeats += 0.5;
				}
				
				if ((i / 2) % BEATS_PER_MEASURE == 0 && trebleRestBeats) {
					//trace("hit the start of the meaure, put a rest here");
					setRest(Note.TREBLE_REST, trebleRestBeats, i / 2);
					trebleRestBeats = 0;
				}
				if ((i / 2) % BEATS_PER_MEASURE == 0 && bassRestBeats) {
					setRest(Note.BASS_REST, bassRestBeats, i / 2);
					bassRestBeats = 0;
				}
				
				i--;
			}

			// Tied notes
			notesMapRange(startBeat, numBeats, function(n:Note, index:Number) : void {
				var newTieAfter : Number = BEATS_PER_MEASURE - ((index / 2) % BEATS_PER_MEASURE);
				if (newTieAfter >= n.numBeats) {
					if (n.numBeats == 2.5) {
						newTieAfter = 2;	
					}
					else if (n.numBeats == 3.5) {
						newTieAfter = 3;
					}
					else {
						newTieAfter = 0;
					}
				}
				if (n.tieAfter != newTieAfter) {
					n.tieAfter = newTieAfter;
				}
			});
		}
		
		/**
		 * Make sure the given rest exists at given beat: if it doesn't, then add it, and if any other rests
		 * exist at that beat, remove them.
		 * 
		 * @param pitch Either Note.TREBLE_REST or Note.BASS_REST
		 * @param numBeats The length of the rest.
		 * @param beat Where to place the rest.
		 */
		private function setRest(pitch:Number, numBeats:Number, beat:Number) : void {
			var myRest : Note = null;
			var n : Note = null;
			for (var i : int = notes[beat * 2].numChildren - 1; i >= 0; i--) {
				n = Note(notes[beat * 2].getChildAt(i));
				if (n.pitch == pitch) {
					myRest = n;
				}
			}
			if (myRest) {
				if (myRest.numBeats != numBeats) {
					myRest.numBeats = numBeats;
				}
			}
			else {
				addNote(pitch, pitch, beat, numBeats);
			}
			
			// remove any rests this covers
			notesMapRange(beat + 0.5, numBeats - 0.5, function(n:Note, index:Number) : void {
				if (n.pitch == pitch) {
					n.parent.removeChild(n);
				}
			});
		}
		
		/**
		 * Remove all notes and reset cursor to beginning.
		 */
		public function clear(evt:MouseEvent=null) : void {
			notes.forEach(function(element:Canvas, index:int, a:Array) : void {
				element.removeAllChildren();
			});
		}
		
		/**
		 * Stop any currently recording notes.
		 */
		public function stopAll() : void {
			notesMapAll(function(n:Note) : void {
				n.stop();
			});
		}
		
		/**
		 * Add a note (or a rest) to the composition.  If numBeats is provided, the new note's length will be numBeats.  
		 * If not provided, the note will start at 0.5 beats long and will increment itself until stopped.
		 */ 
		public function addNote(pitch:Number, octave:Number, startBeat:Number, numBeats:Number=0) : void {
			var n : Note = null;
			if (!Note.isRest(pitch)) {
				// remove any rests
				for (var i : int = notes[startBeat * 2].numChildren - 1; i >= 0; i--) {
					n = Note(notes[startBeat * 2].getChildAt(i));
					if (Note.isRest(n.pitch) && Note.isTreble(pitch, octave) == Note.isTreble(n.pitch, n.octave)) {
						notes[startBeat * 2].removeChildAt(i);
					}
				}
			}
			
			// if there's already a note with same octave+pitch playing here, cut it off
			for (var b : Number = 0.5; b < 4; b += 0.5) {
				notesMapRange(startBeat - b, 0.5, function(n:Note, index:Number) : void {
					if (n.pitch == pitch && n.octave == octave) {
						if (n.numBeats > b) {
							n.numBeats = b;
						}
					}
				});
			}
			
			// remove any notes already starting here at this pitch+octave
			notesMapRange(startBeat, 0.5, function(n:Note, index:Number) : void {
				if (n.pitch == pitch && n.octave == octave) {
					n.parent.removeChild(n);
				}
			});

			notes[startBeat * 2].addChild(new Note(pitch, octave, numBeats, this.bpm));
		}
		
		/**
		 * Stop the given note from being recorded.
		 */
		public function endNote(pitch:Number, octave:Number) : void {
			notesMapAll(function(n:Note) : void {
				if (n.pitch == pitch && n.octave == octave) {
					n.stop();
				}
			});
		}
		
		/**
		 * Remove the first line's worth of notes and move the second line up to the first.
		 */
		public function wrapLine() : void {
			for (var i : int = 0; i < BEATS_PER_LINE * 2; i++) {
				notes[i].removeAllChildren();
				for (var j : int = notes[i + BEATS_PER_LINE * 2].numChildren - 1; j >= 0; j--) {
					notes[i].addChild(notes[i + BEATS_PER_LINE * 2].removeChildAt(j));
				}
			}
			clean(0, BEATS_PER_MEASURE);
		}
		
		/**
		 * Get all of the notes (does not return rests) that are playing at the given time.
		 * 
		 * @beat The time to get notes for.
		 * @return Array of Note objects.
		 */
		public function activeNotes(beat:Number) : Array {
			var rv : Array = new Array();
			
			var startBeat : Number = Math.max(0, beat - 3.5);
			var numBeats : Number = Math.min(4, beat + 0.5);
			notesMapRange(startBeat, numBeats, function(n:Note, index:int) : void {
				if (!Note.isRest(n.pitch)) {
					if (index <= beat * 2 && index + n.numBeats * 2 > beat * 2) {
						rv.push(n);
					}
				}
			});

			return rv;
		}
		
		/**
		 * Handle mouse events.  Single-click selects a note.
		 * If a note is already selected, shift-click will select a series of notes from the currently
		 * selected one to the one the user clicked on.  On double-click, composition cursor is moved
		 * to mouse cursor's position.
		 * 
		 * If user attempts to select notes while composition is being recorded/played back, or if user
		 * double-clicks in an area outside of the composition, error message is briefly displayed.
		 */
		public function captureMouseEvent(evt : MouseEvent) : void {
			// using actual localX and localY is causing problems
			evt.localX = evt.stageX - this.x;
			evt.localY = evt.stageY - this.y;
			
			// check that we're not currently playing/recording
			if ((evt.type == MouseEvent.CLICK || evt.type == MouseEvent.DOUBLE_CLICK) 
				&& MusicContainer(this.parent).mode != MusicContainer.MODE_EDIT) {
				throw new NoteError("Cannot edit song while playing / recording");
			}
			
			// check that click was within bounds of composition
			var inBounds : Boolean = evt.localX > MUSIC_X_OFFSET && evt.localX < X_OFFSET + STAFF_X_OFFSET + STAFF_WIDTH;
		
			if (evt.type == MouseEvent.CLICK) {
				var isTreble : Boolean = false;
				var beat : Number = 0;
				if (inBounds) {
					// figure out which beat user clicked on
					evt.localX -= MUSIC_X_OFFSET;
					beat += evt.localX / (Note.WIDTH * 2);
					if (evt.localY > HEIGHT / 2) {
						beat += BEATS_PER_LINE;
						evt.localY -= HEIGHT / 2;
					}
					beat = Math.floor(beat * 2) / 2;				// round beat to nearest 0.5
					if (evt.localY < TREBLE_BASS_LINE) {
						isTreble = true;
					}
					
					if (!evt.shiftKey || !selectNumBeats) {
						// select single note - this one
						selectStartBeat = beat;
						selectIsTreble = isTreble;
						selectNumBeats = 0.5;
						selectBothClefs = false;
					}
					else {
						// select range from current start to this one
						selectNumBeats = Math.abs(beat - selectStartBeat) + 0.5;
						selectStartBeat = Math.min(selectStartBeat, beat);
						selectBothClefs = (selectIsTreble != isTreble);
					}
				}
				else {
					// out of bounds click, so undo any selection
					deselectAll();
				}
				
				drawHighlight();
			}
			else if (evt.type == MouseEvent.DOUBLE_CLICK) {
				var newBeat : Number = Math.floor((evt.localX - MUSIC_X_OFFSET) / Note.WIDTH) / 2;
				if (evt.localY > HEIGHT / 2) {
					newBeat += BEATS_PER_LINE;
				}
				
				if (newBeat <= MusicContainer(this.parent).maxBeat) {
					MusicContainer(this.parent).currentBeat = newBeat;
					deselectAll();
				}
				else {
					throw new NoteError("Please double click inside the song to move the cursor");
				}
			}
		}
		
		public function deselectAll() : void {
			selectStartBeat = -1;
			selectNumBeats = 0;
			selectIsTreble = false;
			selectBothClefs = false;
			drawHighlight();
		}
		
		/**
		 * Draw highlight - mark all notes as selected or not.
		 */
		private function drawHighlight() : void {
			// before selection: deselect everything
			notesMapRange(0, selectStartBeat, function(n:Note, index:Number) : void {
				n.selected = false;
			});
			// in selection: select or deselect (things within selection time range may not be in the right clef to be selected)
			notesMapRange(selectStartBeat, selectNumBeats, function(n:Note, index:Number) : void {
				if (selectBothClefs || Note.isTreble(n.pitch, n.octave) == selectIsTreble) {
					n.selected = true;
				}
				if (!selectBothClefs && Note.isTreble(n.pitch, n.octave) != selectIsTreble) {
					n.selected = false;
				}
			});
			// after selection: deselect everything
			notesMapRange(selectStartBeat + selectNumBeats, BEATS_PER_LINE * 2, function(n:Note, index:Number) : void {
				n.selected = false;
			});
			
			// unhighlight below to do big swathes of highlighting instead of each individual note
			/*highlight.graphics.clear();
			if (selectNumBeats) {
				var highlightY : int = 4;
				var highlightHeight : int = 0;
				if (selectBothClefs) {
					highlightHeight = HEIGHT / 2 - 8;
				}
				else if (selectIsTreble) {
					highlightHeight = TREBLE_BASS_LINE - 2;
				}
				else {
					highlightY = TREBLE_BASS_LINE;
					highlightHeight = HEIGHT / 2 - TREBLE_BASS_LINE - 2;
				}
				var highlightWidth : int = 0;
				var highlightX : int = 0;
				
				highlight.graphics.beginFill(0x00aaff, 0.2);
				// first line
				if (selectStartBeat < BEATS_PER_LINE) {
					highlightX = Note.WIDTH * (selectStartBeat % BEATS_PER_LINE) * 2;
					highlightWidth = Note.WIDTH * Math.min(selectNumBeats, BEATS_PER_LINE - selectStartBeat) * 2;
					highlight.graphics.drawRoundRect(highlightX, highlightY, highlightWidth, highlightHeight, 20);
				}
				// second line
				if (selectStartBeat >= BEATS_PER_LINE || selectStartBeat + selectNumBeats >= BEATS_PER_LINE) {
					var tempStartBeat : Number = Math.max(selectStartBeat, BEATS_PER_LINE) % BEATS_PER_LINE;
					highlightX = tempStartBeat * Note.WIDTH * 2;
					highlightY += HEIGHT / 2;
					highlightWidth = Note.WIDTH * Math.min(selectNumBeats, selectStartBeat + selectNumBeats - BEATS_PER_LINE) * 2;
					highlight.graphics.drawRoundRect(highlightX, highlightY, highlightWidth, highlightHeight, 20);
				}
				highlight.graphics.endFill();
			}*/
		}
		
		/**
		 * Handle keyboard event.  All keybaord events act on whatever notes are currently selected. Commands:
		 * Up arrow / down arrow: Move pitch up/down by one key
		 * Page up / page down: Move pitch up/down by one octave
		 * Left arrow / right arrow: Move notes left/right by half a beat
		 * Delete: Delete notes
		 * All other keyboard events are ignored.
		 */
		public function captureKeyboardEvent(evt:KeyboardEvent) : void {
			if (evt.type == KeyboardEvent.KEY_DOWN) {
				var takeAction : Boolean = true;
				var pitchDelta : int = 0;
				var startBeatDelta : Number = 0;
				var cmdDelete : Boolean = false;
				
				switch(evt.keyCode) {
					case 0x26:					// up arrow
						pitchDelta = 1;
						break;
					case 0x28:					// down arrow
						pitchDelta = -1;
						break;
					case 0x21:
						pitchDelta = 12;		// page up
						break;
					case 0x22:
						pitchDelta = -12;		// page down
						break;
					case 0x2E:					// delete
					case 0x8:					// backspace
						cmdDelete = true;
						break;
					case 0x25:					// left arrow
						startBeatDelta = -0.5;
						break;
					case 0x27:					// right arrow
						startBeatDelta = 0.5;
						break;
					default:
						//trace("caught a 0x" + evt.keyCode.toString(16));
						takeAction = false;
						break;
				}
				
				if (takeAction && selectNumBeats) {
					var actualRangeTreble : Number = 0;
					var actualRangeBass : Number = 0;
					if (pitchDelta) {
						// vars to record if we jumped from one clef to the other
						var newSelectIsTreble : Boolean = false;
						var newSelectIsBass : Boolean = false;
						
						// adjust all notes in range
						notesMapRange(selectStartBeat, selectNumBeats, function(n:Note, index:Number) : void {
							if (selectBothClefs || selectIsTreble == Note.isTreble(n.pitch, n.octave)) {
								if (!Note.isRest(n.pitch)) {			// rests don't change
									n.index88 += pitchDelta;
									if (Note.isTreble(n.pitch, n.octave)) {
										newSelectIsTreble = true;
									}
									else {
										newSelectIsBass = true;
									}
								}
							}
						});
						
						// clean up
						clean(selectStartBeat, selectNumBeats);
						
						// adjust for highlighting
						selectIsTreble = newSelectIsTreble;
						selectBothClefs = newSelectIsTreble && newSelectIsBass;
					}
					else if (startBeatDelta) {
						// array for the notes that are selected
						var notesToMove : Array = new Array(selectNumBeats * 2);
						for (var j : int = 0; j < notesToMove.length; j++) {
							notesToMove[j] = new Canvas();
						}
						
						// determine actual range, which may be longer than given numBeats, if, say,
						// last selected note is longer than half a beat
						actualRangeTreble = 0;
						actualRangeBass = 0;
						notesMapRange(selectStartBeat, selectNumBeats, function(n:Note, index:Number) : void {
							if (selectBothClefs || selectIsTreble == Note.isTreble(n.pitch, n.octave)) {
								if (Note.isTreble(n.pitch, n.octave)) {
									actualRangeTreble = Math.max(actualRangeTreble, index / 2 + n.numBeats);
								}
								else {
									actualRangeBass = Math.max(actualRangeBass, index / 2 + n.numBeats);
								}
							}
						});
						
						if (Math.max(actualRangeTreble, actualRangeBass) + startBeatDelta > MusicContainer(this.parent).maxBeat
							|| selectStartBeat + startBeatDelta < 0) {	
							// don't go out of bounds
							throw new NoteError("Cannot move notes any further");
						}
						// move displaced notes
						notesMapRange(selectStartBeat, selectNumBeats, function(n:Note, index:Number) : void {
							if (selectBothClefs || Note.isTreble(n.pitch, n.octave) == selectIsTreble) {
								n.parent.removeChild(n);
								notesToMove[index - selectStartBeat * 2].addChild(n);
							}
						});
						if (startBeatDelta > 0) {
							notesMapRange(selectStartBeat + selectNumBeats, startBeatDelta, function(n:Note, index:Number) : void {
								if (selectBothClefs || Note.isTreble(n.pitch, n.octave) == selectIsTreble) {
									notes[index].removeChild(n);
									notes[index - selectNumBeats * 2].addChild(n);
								}
							});
						}
						else {
							notesMapRange(selectStartBeat + startBeatDelta, Math.abs(startBeatDelta), function(n:Note, index:Number) : void {
								if (selectBothClefs || Note.isTreble(n.pitch, n.octave) == selectIsTreble) {
									notes[index].removeChild(n);
									notes[index + selectNumBeats * 2].addChild(n);
								}
							});
						}
						
						// put selected notes in their new positions
						for (j = 0; j < notesToMove.length; j++) {
							for (var k : int = notesToMove[j].numChildren - 1; k >= 0; k--) {
								notes[j + (selectStartBeat + startBeatDelta) * 2].addChild(notesToMove[j].getChildAt(k));
							}
						}
						
						// clean up
						clean(Math.min(selectStartBeat, selectStartBeat + startBeatDelta), Math.max(actualRangeTreble, actualRangeBass) + Math.abs(startBeatDelta));
						
						// adjust for highlighting
						selectStartBeat += startBeatDelta;
					} 
					else if (cmdDelete) {
						// remove notes and determine actual range, which may be longer than given numBeats, if, say,
						// last selected note is longer than half a beat
						actualRangeTreble = 0;
						actualRangeBass = 0;
						notesMapRange(selectStartBeat, selectNumBeats, function(n:Note, index:Number) : void {
							if (selectBothClefs || selectIsTreble == Note.isTreble(n.pitch, n.octave)) {
								n.parent.removeChild(n);
								if (Note.isTreble(n.pitch, n.octave)) {
									actualRangeTreble = Math.max(actualRangeTreble, index / 2 + n.numBeats);
								}
								else {
									actualRangeBass = Math.max(actualRangeBass, index / 2 + n.numBeats);
								}
							}
						});
						actualRangeTreble -= selectStartBeat;
						actualRangeBass -= selectStartBeat;
						
						// move any later notes over to take up vacuum left by deleted notes
						notesMapRange(selectStartBeat + selectNumBeats, BEATS_PER_LINE * 2 - selectStartBeat - selectNumBeats, function(n:Note, index:Number) : void {
							if (selectBothClefs || selectIsTreble == Note.isTreble(n.pitch, n.octave)) {
								n.parent.removeChild(n);
								if (Note.isTreble(n.pitch, n.octave)) {
									notes[index - actualRangeTreble * 2].addChild(n);
								}
								else {
									notes[index - actualRangeBass * 2].addChild(n);
								}
							}
						});
						
						// clean up
						clean(Math.min(selectStartBeat, selectStartBeat + startBeatDelta), Math.max(actualRangeTreble, actualRangeBass) * 2);
						
						// adjust for highlighting
						deselectAll();
					}
					drawHighlight();
				}
			}
			
			evt.stopImmediatePropagation();
			evt.preventDefault();
		}
	}
}