package saui.proj4
{
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import mx.core.UIComponent;
	
	/**
	 * A Note object is a single note or rest, part of the composition a user records. 
	 * 
	 * The Note class also contains static methods to determine things like which clef 
	 * a note is in, which key it goes with, etc.
	 * 
	 * @author Jenny Schweers
	 */
	public class Note extends UIComponent
	{
		// constants for drawing notes
        public static const WIDTH : int = 25;				// includes flat/sharp, note image, and spacing
        public static const HEIGHT : int = 25;
        public static const IMAGE_OFFSET : int = 7; 
        public static const IMAGE_WIDTH : int = 15;
        
        // constants for all the pitches in one octave, plus rests
        public static const BASS_REST : Number = -2;
        public static const TREBLE_REST : Number = -1;
		public static const C : Number = 0;
		public static const C_SHARP : Number = 0.45;
		public static const D : Number = 1;
		public static const E_FLAT : Number = 1.55;
		public static const E : Number = 2;
		public static const F : Number = 3;
		public static const F_SHARP : Number = 3.45;
		public static const G : Number = 4;
		public static const G_SHARP : Number = 4.45;
		public static const A : Number = 5;
		public static const B_FLAT : Number = 5.55;
		public static const B : Number = 6;
		public static const ALL_PITCHES : Array = [Note.C, Note.C_SHARP, Note.D, Note.E_FLAT, Note.E, Note.F, Note.F_SHARP, Note.G, Note.G_SHARP, Note.A, Note.B_FLAT, Note.B];
		private static const ALL_NAMES : Array = ["C", "C_SHARP", "D", "E_FLAT", "E", "F", "F_SHARP", "G", "G_SHARP", "A", "B_FLAT", "B"];
		
		// major parts of a Note
		private var _pitch : Number = -1;
		private var _octave : Number = -1;
		private var _numBeats : Number = -1;					// length of this note, multiple of 0.5
		private var _tieAfter : Number = 0;						// if zero, no tie. if not zero, note is tied where first part has tieAfter # of beats
		
		private var _selected : Boolean = false;				// true if user has selected this note for editing
		private var recordInterval : int = 0;					// 0 unless note is currently being recorded
		
		/**
		 * Getter for pitch.
		 */
		public function get pitch() : Number { return _pitch; }
		
		/**
		 * Setter for pitch (requires redraw).
		 */
		public function set pitch(p : Number) : void {
			if (p != _pitch) {
				_pitch = p;
				invalidateDisplayList();
			}
		}

		/**
		 * Getter for octave.
		 */
		public function get octave() : Number { return _octave; }
		
		/**
		 * Setter for octave (requires redraw).
		 */
		public function set octave(o : Number) : void {
			if (o != _octave) {
				_octave = o;
				invalidateDisplayList();
			}
		}
		
		/**
		 * Getter for numBeats.
		 */
		public function get numBeats() : Number { return _numBeats; }
		
		/**
		 * Setter for numBeats (requires redraw).
		 */
		public function set numBeats(nb : Number) : void {
			if (nb != _numBeats) {
				_numBeats = nb;
				invalidateDisplayList();
			}
			
			// 2.5 beats and 3.5 beats are tied even if they don't cross two measures
			if (_numBeats == 2.5) {
				_tieAfter = 2;
			}
			else if (_numBeats == 3.5) {
				_tieAfter = 3;
			}
		}
		
		/**
		 * Getter for tieAfter.
		 */
		public function get tieAfter() : Number { return _tieAfter; }
		
		/**
		 * Setter for tieAfter (requires redraw).
		 */
		public function set tieAfter(ta : Number) : void {
			if (ta != _tieAfter) {
				_tieAfter = ta;
				invalidateDisplayList();
			}
		}
		
		/**
		 * Getter for selected.
		 */
		public function get selected() : Boolean { return _selected; }
		
		/**
		 * Setter for selected (requires redraw).
		 */
		public function set selected(s : Boolean) : void {
			if (s != _selected) {
				_selected = s;
				invalidateDisplayList();
			}
		}
		
		/**
		 * Fake getter for this note's position on piano, out of 88 keys.
		 */
		public function get index88() : int { 
			return Note.index88(this.pitch, this.octave); 
		}
		
		/**
		 * Sets the pitch and octave of this note based on an index (out of 88 piano keys).
		 */
		public function set index88(i : int) : void {
			i = Math.min(i, 87);
			i = Math.max(i, 0);
			this.pitch = getPitchFromIndex88(i);
			this.octave = getOctaveFromIndex88(i);
		}
		
		/**
		 * Get pitch based on given piano key.
		 */
		private function getPitchFromIndex88(i : int) : Number {
			return ALL_PITCHES[(i + 9) % 12];
		}
		
		/**
		 * Get octave based on given piano key.
		 */
		private function getOctaveFromIndex88(octave:Number) : Number {
			return Math.floor((octave + 9) / 12);
		}
		
		/**
		 * Constructor.
		 * 
		 * If numBeats is not provided, this note will start as 0.5 beats and will set an interval to increment itself 
		 * 0.5 beats at a time, based on gievn beats per minute value, until it is stopped or it reaches a maximum of four beats.
		 */
		public function Note(pitch:Number, octave:Number, numBeats:Number=0, bpm:int=0) {
			this.pitch = pitch;
			this.octave = octave;
			if (numBeats) {
				this.numBeats = numBeats;
			}
			else {
				this.numBeats = 0.5;
				recordInterval = setInterval(addBeats, Composition.msPerBeat(bpm) / 2, 0.5);	// increment every eighth note
			}
			
			this.width = WIDTH;
			this.height = HEIGHT;
		}
		
		/**
		 * Increment numBeats, stopping at 4 beats.
		 * 
		 * @param beatsDelta Amount to increment by.
		 */
		private function addBeats(beatsDelta:Number) : void {
			numBeats += beatsDelta;
			if (numBeats >= 4) {
				stop();
			}
		}
		
		/**
		 * Calculate x and y position of this Note: x position will be zero, and y position will be based on pitch.
		 */
		private function setPosition() : void {
			var noteIndex : int = index52(pitch, octave);
			if (is8va(pitch, octave)) {
				noteIndex -= 7;
			}
			else if (is8vb(pitch, octave)) {
				noteIndex += 7;
			}
			
			var noteX : int = 0;
			var noteY : int = 0;
			if (!isRest(pitch) && hasStemDown(pitch, octave)) {
				noteY += HEIGHT - Composition.SPACE_HEIGHT;
			}
			if (isTreble(pitch, octave)) {
				noteY += Composition.TREBLE_STAFF_Y_OFFSET + (Composition.SPACE_HEIGHT * 1.5);
				if (isRest(pitch)) {
					noteY -= Composition.SPACE_HEIGHT * 1.5;
				}
				else {
					noteY -= Composition.SPACE_HEIGHT * (noteIndex - 23) / 2;
				}
			}
			else {
				noteY += Composition.BASS_STAFF_Y_OFFSET - Composition.SPACE_HEIGHT - Composition.SPACE_HEIGHT * 3;
				if (isRest(pitch)) {
					noteY += Composition.SPACE_HEIGHT * 4;
				}
				else {
					noteY += Composition.SPACE_HEIGHT * (22 - noteIndex) / 2;
				}
			}
			
			this.x = noteX;
			this.y = noteY;
		}
		
		/**
		 * Stop Note from automatically incrementing itself.
		 */
		public function stop() : void {
			clearInterval(recordInterval);
			recordInterval = 0;
		}
		
		/**
		 * Determine which piano key the given pitch and octave go with.
		 */
		public static function index88(pitch:Number, octave:Number) : int {
			var rv : int = 0;
			rv = (octave * 12) + ALL_PITCHES.indexOf(pitch) - 9;
			return rv;
		}
		
		/**
		 * Determine which white piano key the given pitch and octave go with.
		 * Black keys are rounded to the nearest white key: B_FLAT becomes B, etc.
		 */
		public static function index52(pitch:Number, octave:Number) : int {
			return (octave * 7 - 5 + Math.round(pitch));
		}
		
		/**
		 * Determine if given pitch is a rest.
		 */
		public static function isRest(pitch:Number) : Boolean {
			return (pitch == Note.TREBLE_REST || pitch == Note.BASS_REST);
		}
		
		/**
		 * Determine if note should be drawn upside-down.
		 */
		public static function hasStemDown(pitch:Number, octave:Number) : Boolean {
			var index : int = Note.index52(pitch, octave);
			return (index > 28 || (index > 16 && index < 23));
		}
		
		/**
		 * Determine which clef given note is in.
		 * Middle C and above are drawn as treble, everything below middle C drawn as bass.
		 */
		public static function isTreble(pitch:Number, octave:Number) : Boolean {
			return (octave >= 4 || pitch == Note.TREBLE_REST);
		}
		
		/**
		 * Determine if given note corresponds to black or white key.
		 */
		public static function isBlack(pitch:Number) : Boolean {
			return (pitch != Math.floor(pitch));
		}
		
		/**
		 * Determine if given note is a flat.
		 * Only B_FLAT and E_FLAT will return true, system does not understand things like G_SHARP==A_FLAT
		 */
		public static function isFlat(pitch:Number) : Boolean {
			return (isBlack(pitch) && Math.round(pitch) == Math.ceil(pitch));
		}
		
		/**
		 * Determine if given note is a sharp.
		 * Only C_SHARP, F_SHARP, and G_SHARP will return true, system does not understand things like G_SHARP==A_FLAT
		 */
		public static function isSharp(pitch:Number) : Boolean {
			return (isBlack(pitch) && Math.round(pitch) == Math.floor(pitch));
		}
		
		/**
		 * Determine if given note is drawn in a space on the staff, as opposed to on a line.
		 */
		public static function isSpace(pitch:Number, octave:Number) : Boolean {
			if (Note.is8va(pitch, octave)) {
				octave--;
			}
			else if (Note.is8vb(pitch, octave)) {
				octave++;
			}
			if (octave % 2 == 0) {
				return (Math.round(pitch) % 2 == 1);
			}
			else {
				return (Math.round(pitch) % 2 == 0);
			}
		}
		
		/**
		 * Determine if given note should be drawn 8va.
		 * Top octave of piano is drawn one octave lower than it should be and marked as 8va.
		 */
		public static function is8va(pitch:Number, octave:Number) : Boolean {
			var index : int = Note.index52(pitch, octave);
			return (index > 44 && !Note.isRest(pitch));
		}
		
		/**
		 * Determine if given note should be drawn 8vb.
		 * Bottom octave of piano is drawn one octave higher than it should be and marked as 8vb.
		 */
		public static function is8vb(pitch:Number, octave:Number) : Boolean {
			var index : int = Note.index52(pitch, octave);
			return (index < 7 && !Note.isRest(pitch));
		}
		
		/**
		 * Sets position and draws note.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			setPosition();
			
			this.graphics.clear();
			
			// highlight if selected
			if (selected) {
				this.graphics.beginFill(0x00aaff, 0.2);
				this.graphics.drawRoundRect(2, 0, WIDTH - 4, HEIGHT, 10);
				this.graphics.endFill();
			}
			
			// remove any lingering 8va or 8vb
			while (this.numChildren) {
				this.removeChildAt(0);
			}
			
			if (tieAfter) {
				// draw two notes and tie them together
				drawNote(tieAfter, 0);
				drawNote(this.numBeats - tieAfter, tieAfter);
				if (!Note.isRest(this.pitch)) {
					// draw curve between notes
					var curveX : int = 0;
					var anchorY : int = 0;			// actual point drawn
					var controlY : int = 0;			// point controlling shape of curve
					var curveWidth : int = tieAfter * WIDTH * 2;
					if (Note.hasStemDown(pitch, octave)) {
						curveX = 18;
						anchorY = -3;
						controlY = -8 - Math.floor(numBeats) * 2;
					}
					else {
						curveX = 10;
						anchorY = HEIGHT + 3;
						controlY = HEIGHT + 8 + Math.floor(numBeats) * 2;
					}
					this.graphics.lineStyle(1, 0x000000);
					this.graphics.moveTo(curveX, anchorY);
					this.graphics.curveTo(curveX + curveWidth / 2, controlY, curveX + curveWidth, anchorY);
					this.graphics.lineStyle();			
				}	
			}
			else {
				// draw single note
				drawNote(this.numBeats, 0);
			}
			
			// add sharp/flat
			if (!Note.isRest(this.pitch) && Note.isBlack(pitch)) {
				this.graphics.lineStyle();
				var image : BitmapData = null;
				var accidentalX : int = 0;
				var accidentalY : int = 0;
				if (Note.isSharp(pitch)) {
					image = ResourceFactory.getImage(ResourceFactory.SHARP);
				}
				else if (Note.isFlat(pitch)) {
					image = ResourceFactory.getImage(ResourceFactory.FLAT);
				}
				if (Note.hasStemDown(pitch, octave)) {
					accidentalX = 6;
					accidentalY = -3;
				}
				else {
					accidentalX = 0;
					accidentalY = 16;
				}
				var accidentalMatrix : Matrix = new Matrix();
				accidentalMatrix.translate(accidentalX, accidentalY);
				this.graphics.beginBitmapFill(image, accidentalMatrix);
				this.graphics.drawRect(accidentalX, accidentalY, 5, 9);
				this.graphics.endFill();
			}
		}	
		
		/**
		 * Draw single note: note image, extra ledger lines, 8va/8vb marking.
		 */
		private function drawNote(numBeats:Number, beatsOffset:Number=0) : void {
			this.graphics.lineStyle();
			
			var noteMatrix : Matrix = new Matrix();
			noteMatrix.scale(0.25, 0.25);
			if (!Note.isRest(this.pitch) && hasStemDown(this.pitch, this.octave)) {
				// invert so stem points down
				noteMatrix.scale(-1, -1);
				noteMatrix.translate(-IMAGE_WIDTH, 0);
			}
			
			var imageID : int = -1;
			if (Note.isRest(this.pitch)) {
				if (numBeats < 1) {
					imageID = ResourceFactory.EIGHTH_REST;
				}
				else if (numBeats < 2) {
					imageID = ResourceFactory.QUARTER_REST;
				}
				else if (numBeats < 4) {
					imageID = ResourceFactory.HALF_REST;
				}
				else {
					imageID = ResourceFactory.WHOLE_REST;
				}
			}
			else {
				if (numBeats < 1) {
					imageID = ResourceFactory.EIGHTH_NOTE;
				}
				else if (numBeats < 2) {
					imageID = ResourceFactory.QUARTER_NOTE;
				}
				else if (numBeats < 4) {
					imageID = ResourceFactory.HALF_NOTE;
				}
				else {
					imageID = ResourceFactory.WHOLE_NOTE;
				}
			}
			
			// draw note
			var xOffset : int = beatsOffset * Note.WIDTH * 2;
			var yOffset : int = 0;									// todo: account for note and tie being on different lines of composition
			noteMatrix.translate(IMAGE_OFFSET + xOffset, yOffset);
			this.graphics.beginBitmapFill(ResourceFactory.getImage(imageID), noteMatrix);
			this.graphics.drawRect(IMAGE_OFFSET + xOffset, yOffset, IMAGE_WIDTH, HEIGHT);
			this.graphics.endFill();
			
			// add dot for dotted quarter, dotted half
			if (numBeats == 1.5 || Math.floor(numBeats) == 3) {
				this.graphics.beginFill(0x000000);
				if (Note.isRest(this.pitch)) {
					this.graphics.drawEllipse(xOffset + WIDTH - 3, HEIGHT / 2 - 3, 3, 3);
				}
				else if (hasStemDown(this.pitch, this.octave)) {
					this.graphics.drawEllipse(xOffset + WIDTH - 3, 1, 3, 3);
				}
				else {
					this.graphics.drawEllipse(xOffset + WIDTH - 7, 20, 3, 3);
				}
				this.graphics.endFill();
			}
			
			// ledger lines
			if (!Note.isRest(this.pitch)) {
				var noteIndex : int = Note.index52(pitch, octave);
				if (Note.is8va(this.pitch, this.octave)) {
					noteIndex -= 7;
				}
				else if (Note.is8vb(this.pitch, this.octave)) {
					noteIndex += 7;
				}
				
				// figure out where to put lines
				var ledgerDelta : int = 0;
				var ledgerLines : int = 0;
				var ledgerX : int = 0;
				var ledgerY : int = 0;
				if (Note.isTreble(pitch, octave)) {
					if (noteIndex == 23) {
						ledgerLines = 1;
						ledgerX = 5;
						ledgerY = Note.HEIGHT - 4;
					}
					else if (noteIndex > 34) {
						ledgerLines = (noteIndex - 35) / 2 + 1;
						ledgerX = 11;
						if (Note.isSpace(pitch, octave)) {
							ledgerY = Composition.SPACE_HEIGHT;
						}
						else {
							ledgerY = 2;
						}
					}
					ledgerDelta = Composition.SPACE_HEIGHT;
				}
				else {
					if (noteIndex < 12) {
						ledgerLines = Math.floor((13 - noteIndex) / 2);
						ledgerX = 5;
						if (Note.isSpace(pitch, octave)) {
							ledgerY = Note.HEIGHT - Composition.SPACE_HEIGHT;
						}
						else {
							ledgerY = Note.HEIGHT - 4;
						}
					}
					ledgerDelta = -Composition.SPACE_HEIGHT;
				}
			
				// draw lines
				this.graphics.lineStyle(1, 0x000000);
				while (ledgerLines > 0) {
					this.graphics.moveTo(xOffset + ledgerX, ledgerY);
					this.graphics.lineTo(xOffset + ledgerX + 13, ledgerY);
					ledgerY += ledgerDelta;
					ledgerLines--;
				}
			}
			
			// 8va/b marking
			var textFormat : TextFormat = new TextFormat();
			textFormat.size = 9;
			textFormat.bold = false;
			var tf : TextField = new TextField();
			if (Note.is8va(pitch, octave)) {
				tf.defaultTextFormat = textFormat;
				tf.text = "8va";
				tf.width = 20;
				tf.height = 20;
				tf.x = xOffset + 8;
				tf.y = -11;
				this.addChild(tf);
			}
			else if (Note.is8vb(pitch, octave)) {
				tf.defaultTextFormat = textFormat;
				tf.text = "8vb";
				tf.width = 20;
				tf.height = 20;
				tf.x = xOffset + 4;
				tf.y = this.height - 2;
				this.addChild(tf);
			}
			
			return;
		}
	}	
}