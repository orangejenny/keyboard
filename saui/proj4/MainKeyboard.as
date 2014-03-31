package saui.proj4
{
	import flash.events.*;
	import flash.media.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import mx.core.UIComponent;
	
	/**
	 * The MainKeyboard class is where the user plays notes.  The user can click on keys or
	 * use the computer keyboard.  The keyboard represents a section of the whole master
	 * keyboard.  Keys are mapped to computer keyboard letters.  The mappings use the home row
	 * and bottom row for white keys and the top row for black keys.  These letter-key mappings
	 * are slightly different depending on whether the user wants to play right-handed or left-handed.
	 * 
	 * @author Jenny Schweers
	 */
	public class MainKeyboard extends UIComponent
	{
		// constands for drawing
		public static const WIDTH : int = 406;
		public static const HEIGHT : int = 150;
		
		// pitch and octave of lowest key
		public var startPitch : Number = -1;
		public var startOctave : Number = -1;
		
		public static const RIGHT_HANDED : int = 0;
		public static const LEFT_HANDED : int = 1;
		private var _handedness : int = RIGHT_HANDED;
		
		// map letters on computer keyboard to main keyboard keys
		private var keyMap : Array = null;
		
		/**
		 * Getter for handedness
		 */
		public function get handedness() : int {return _handedness;}
		
		/**
		 * Setter for handedness (requires re-mapping keys).
		 */
		public function set handedness(h : int) : void {
			if (h != RIGHT_HANDED && h != LEFT_HANDED) {
				throw new Error("Illegal value (" + h + ") passed to set handedness");
			}
			_handedness = h;
			setupKeyMap();
		}
		
		/**
		 * Constructor.
		 */
		public function MainKeyboard(x:int, y:int, startPitch:Number, startOctave:Number)
		{
			this.startPitch = startPitch;
			this.startOctave = startOctave;
			setupKeyMap();
			
			this.x = x;
			this.y = y;
			this.width = WIDTH;
			this.height = HEIGHT;
			
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * Press key - just passes command down to correct key.
		 */
		public function press(pitch:Number, octave:Number) : void {
			var k : Key = getKey(pitch, octave);
			if (k) {
				k.press();
			}
		}
		
		/**
		 * Release key - just passes command down to correect key.
		 */ 
		public function release(pitch:Number, octave:Number) : void {
			var k : Key = getKey(pitch, octave);
			if (k) {
				k.release();
			}			
		}
		
		/**
		 * Get Key object based on given pitch and octave.
		 * 
		 * @return Key Selected key, null if key is not found.
		 */
		private function getKey(pitch:Number, octave:Number) : Key {
			var rv : Key = null;
			var child : Key = null;
			var i : int = 0;
			while (i < this.numChildren && !rv) {
				child = Key(this.getChildAt(i));
				if (child.pitch == pitch && child.octave == octave) {
					rv = child;
				}
				i++;
			}
			return rv;
		}
		
		/**
		 * Determine which letters correspond to which keys, based on handedness and which section of master 
		 * keyboard is selected.  Adds Key objects as children.  Draws letters on screen to assist user.
		 */
		public function setupKeyMap() : void {
			// set up computer keyboard / music keyboard mappings
			var letters : Array = null;
			if (this.handedness == RIGHT_HANDED) {
				letters = ["AZ", "W", "SX", "E", "DC", "R", "FV", "T", "GB", "Y", "HN", "U", "JM", "I", "K,", "O", "L."];
			}
			else {
				letters = ["SZ", "E", "DX", "R", "FC", "T", "GV", "Y", "HB", "U", "JN", "I", "KM", "O", "L,", "P", ";."];
			}
			var code : String = "";
			var numKeys : int = 0;
			var xCursor : int = 1;
			var pitch : Number = -1;
			var octave : Number = -1;
			while (this.numChildren > 0) {
				this.removeChildAt(0);
			}
			
			var k : Key = null;
			var startIndex : int = Note.ALL_PITCHES.indexOf(startPitch);
			keyMap = new Array();
			while (letters.length > 0) {
				code = letters.shift();
				pitch = Note.ALL_PITCHES[(startIndex + numKeys) % 12];
				octave = startOctave + Math.floor((startIndex + numKeys) / 12);
				if (code.length == 2) {
					keyMap[code.charAt(0)] = numKeys;
					keyMap[code.charAt(1)] = numKeys;
					k = new Key(xCursor, 1, pitch, octave);
										
					var x1 : int = 0;
					var x2 : int = 0;
					if (this.handedness == MainKeyboard.RIGHT_HANDED) {
						x1 = 4;
						x2 = 20;
					}
					else {
						x1 = 20;
						x2 = 4;
					}
					k.addChild(getHelpTextField(x1, 100, code.charAt(0), 0x000000));
					k.addChild(getHelpTextField(x2, 120, code.charAt(1), 0x000000));
					this.addChild(k);
					xCursor += Key.WIDTH_WHITE + 1;
					numKeys++;
				}
				else if (Note.isBlack(pitch)) {
					keyMap[code] = numKeys;
					k = new Key(xCursor - Key.WIDTH_BLACK / 2 - 1, 1, pitch, octave);
					k.addChild(getHelpTextField(6, 60, code, 0xffffff));
					this.addChild(k);
					numKeys++;
				}
			}
			invalidateDisplayList();
		}
		
		/**
		 * Change which key (from master keyboard) is used as lowest note for main keyboard.
		 */
		public function updateStart(startPitch:Number, startOctave:Number) : void {
			this.startPitch = startPitch;
			this.startOctave = startOctave;
			setupKeyMap();
			invalidateDisplayList();
		}
		
		/**
		 * Generate text field to be used as help text on keyboard.
		 */
		private function getHelpTextField(x:int, y: int, str:String, color:uint) : TextField {
			var textFormat : TextFormat = new TextFormat();
			textFormat.size = 18;
			textFormat.font = "Arial";
			textFormat.color = color;
			
			var rv : TextField = new TextField();
			rv.defaultTextFormat = textFormat;
			rv.x = x;
			rv.y = y;
			rv.width = 22;
			rv.height = 22;
			rv.text = str;
			rv.mouseEnabled = false;
			
			return rv;
		}
		
		/**
		 * Draw keyboard. This just draws a black background; the keys will draw themselves.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.graphics.clear();
			this.graphics.beginFill(0x000000);
			this.graphics.drawRect(0, 0, this.width, this.height);
			this.graphics.endFill();
		}
		
		/**
		 * Handle keyboard event.  If key pressed matches a keyboard key, dispatch a NoteEvent 
		 * for MusicContainer to handle.  Otherwise, do nothing.
		 */
		public function captureKeyboardEvent(evt:KeyboardEvent) : void {
			var char : String = "";
			if (evt.keyCode == 0xBC) {
				char = ",";
			}
			else if (evt.keyCode == 0xBE) {
				char = ".";
			}
			else if (evt.keyCode == 0xBA) {
				char = ";";
			}
			else if (evt.keyCode >= 0x41 && evt.keyCode <= 0x5a) {			// letter, comma, period, semicolon
				char = String.fromCharCode(evt.keyCode).toUpperCase(); 
			}
			
			if (keyMap.hasOwnProperty(char)) {
				var k : Key = Key(this.getChildAt(keyMap[char]));
				if (evt.type == KeyboardEvent.KEY_UP) {
					if (k.isDown) {
						NoteEvent.dispatch(this, NoteEvent.NOTE_STOP, k.pitch, k.octave);
					}
				}
				else if (evt.type == KeyboardEvent.KEY_DOWN) {
					if (!k.isDown) {										// ignore repeated KEY_DOWN events from holding down key
						NoteEvent.dispatch(this, NoteEvent.NOTE_START, k.pitch, k.octave);
					}
				}
			}
			
			evt.stopImmediatePropagation();
			evt.preventDefault();
		}
	}
}