package saui.proj4
{
	import flash.events.*;
	
	import mx.core.UIComponent;

	/**
	 * The MasterKeyboard class represents a full piano. It is drawn at the bottom of the MusicContainer, 
	 * and the user can click on it to select which part of the piano will be used for the main keyboard.
	 * 
	 * @author Jenny Schweers
	 */
	public class MasterKeyboard extends UIComponent
	{
		// constants for drawing
		public static const WIDTH : int = 729;
		public static const HEIGHT : int = 50;
		public static const WHITE_KEY_WIDTH : int = 13;
		public static const BLACK_KEY_WIDTH : int = 7;
		public static const ACTIVE_WIDTH : int = (WHITE_KEY_WIDTH + 1) * 9;
		
		// the pitch and octave of the start key, the lowest note of the main keyboard
		public var startPitch : Number = -1;
		public var startOctave : Number = -1;
		
		// the index (out of 52 white keys) that will be used as the start key if user clicks
		// on the spot they're currently hovering over
		public var tentativeIndex : int = -1;
		
		/**
		 * Constructor.
		 */
		public function MasterKeyboard(x:int, y:int, startPitch:Number, startOctave:Number)
		{
			super();
			
			this.width = WIDTH;
			this.height = HEIGHT;
			
			this.x = x;
			this.y = y;
			
			this.startPitch = startPitch;
			this.startOctave = startOctave;
			
			this.addEventListener(MouseEvent.MOUSE_OVER, captureMouseEvent);
			this.addEventListener(MouseEvent.MOUSE_OUT, captureMouseEvent);
			this.addEventListener(MouseEvent.MOUSE_MOVE, captureMouseEvent);
			this.addEventListener(MouseEvent.CLICK, captureMouseEvent);
		}
		
		/**
		 * Handle mouse events.  On hover, a set of keys under the cursor is highlighted.
		 * On click, the main keyboard is changed so it represents those highlighted keys.
		 */
		private function captureMouseEvent(evt:MouseEvent) : void {
			if (evt.type == MouseEvent.MOUSE_MOVE) {
				var newTentativeIndex : int = Math.floor(evt.localX / (WHITE_KEY_WIDTH + 1)) - 4;
				newTentativeIndex = Math.max(0, newTentativeIndex);
				newTentativeIndex = Math.min(43, newTentativeIndex);
				if (tentativeIndex != newTentativeIndex) {
					tentativeIndex = newTentativeIndex;
					invalidateDisplayList();
				}
			}
			else if (evt.type == MouseEvent.MOUSE_OUT) {
				tentativeIndex = -1;
				invalidateDisplayList();
			}
			else if (evt.type == MouseEvent.CLICK) {
				// changing the start key just dispatches a NoteEvent
				// MusicContainer will catch that event and call update functions on this and the main keyboard
				this.startPitch = (tentativeIndex + 5) % 7;
				this.startOctave = Math.floor((tentativeIndex + 5) / 7);
				NoteEvent.dispatch(this, NoteEvent.NOTE_SET_MASTER, this.startPitch, this.startOctave);
			}
		}
		
		/**
		 * Redraw this object with given pitch and octave used as lowest key for main keyboard.
		 */
		public function updateStart(startPitch:Number, startOctave:Number) : void {
			this.startPitch = startPitch;
			this.startOctave = startOctave;
			invalidateDisplayList();
		}
		
		/**
		 * Draw the master keyboard.  Keys that are not part of the current main keyboard will be shaded grey.
		 * Keys that user is hovering over will be shaded in blue.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.graphics.beginFill(0x000000, 0.5);
			this.graphics.drawRect(0, 0, this.width, this.height);
			this.graphics.endFill();
			
			// white keys
			this.graphics.beginFill(0xffffff);
			for (var i : int = 0; i < 52; i++) {
				this.graphics.drawRect(i * (WHITE_KEY_WIDTH + 1) + 1, 1, WHITE_KEY_WIDTH, this.height - 2);
			}
			this.graphics.endFill();
			
			// shade keys not in use
			var startX : int = Note.index52(this.startPitch, this.startOctave) * (WHITE_KEY_WIDTH + 1) + 1;
			this.graphics.lineStyle();
			this.graphics.beginFill(0x000000, 0.5);
			this.graphics.drawRect(0, 0, startX, this.height);
			this.graphics.drawRect(startX + ACTIVE_WIDTH, 1, this.width - startX - ACTIVE_WIDTH, this.height - 2);
			this.graphics.endFill();
			
			// lightly shade keys being hovered over
			if (tentativeIndex != -1) {
				startX = Math.floor((WHITE_KEY_WIDTH + 1) * tentativeIndex + 1);
				this.graphics.beginFill(0x0000ff, 0.3);
				this.graphics.drawRect(startX, 1, ACTIVE_WIDTH, this.height - 2);
				this.graphics.endFill();
			}
			
			// black keys
			var hasBlack : Array = [true, false, true, true, false, true, true];
			this.graphics.beginFill(0x000000);
			for (i = 0; i < 51; i++) {
				if (hasBlack[i % hasBlack.length]) {
					this.graphics.drawRect(i * 14 + 15 - BLACK_KEY_WIDTH / 2, 1, BLACK_KEY_WIDTH, this.height * 0.55);
				}
			}
			this.graphics.endFill();
		}
	}
}