package saui.proj4
{
	import flash.events.MouseEvent;
	import flash.media.*;
	import flash.utils.*;
	
	import mx.core.UIComponent;
	
	/**
	 * The Key class represents a single key on the main keyboard.
	 * 
	 * Keys dispatch events when they're clicked on with the mouse.
	 * 
	 * @author Jenny Schweers
	 */
	public class Key extends UIComponent
	{
		// constants for drawing
		public static const WIDTH_WHITE : int = 44
		public static const WIDTH_BLACK : int = 30;
		public static const HEIGHT_WHITE : int = MainKeyboard.HEIGHT - 2;
		public static const HEIGHT_BLACK : int = Math.floor(MainKeyboard.HEIGHT * 0.55 + 0.5);
		
		public var pitch : Number = 0;
		public var octave : Number = 0;
		public var isDown : Boolean = false;			// used to ignore repeated KEY_DOWN events caused by holding down key
		private var interval : int = 0;
		
		private var _color : uint = 0x00ff00;
		
		/**
		 * Getter for color.
		 */
		public function get color() : uint { return _color; }
		
		/**
		 * Setter for color (requires redraw).
		 */
		public function set color(color : uint) : void {
			_color = color;
			invalidateDisplayList();
		}
				
		/**
		 * Constructor.
		 */
		public function Key(x:int, y:int, pitch:Number, octave:Number) {
			this.pitch = pitch;
			this.octave = octave;
			
			this.x = x;
			this.y = y;
			if (Note.isBlack(this.pitch)) {
				this.width = WIDTH_BLACK;
				this.height = HEIGHT_BLACK;
				this.color = 0x000000;
			}
			else {
				this.width = WIDTH_WHITE;
				this.height = HEIGHT_WHITE;
				this.color = 0xffffff;
			}
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, captureMouseEvent);
			this.addEventListener(MouseEvent.MOUSE_UP, captureMouseEvent);
			this.addEventListener(MouseEvent.MOUSE_OVER, captureMouseEvent);
			this.addEventListener(MouseEvent.MOUSE_OUT, captureMouseEvent);
			this.addEventListener(MouseEvent.ROLL_OUT, captureMouseEvent);
		}
		
		/**
		 * Handle mouse events. On mouse down/up, NOTE_START/NOTE_STOP events are dispatched;
		 * MusicContainer will handle these events.
		 */
		private function captureMouseEvent(evt:MouseEvent) : void {
			if (evt.type == MouseEvent.MOUSE_DOWN) {
				if (!this.isDown) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_START, this.pitch, this.octave);
				}
			}
			else if (evt.type == MouseEvent.MOUSE_UP) {
				if (this.isDown) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_STOP, this.pitch, this.octave);
				}
			}
			else if (evt.type == MouseEvent.MOUSE_OUT) {
				// moving mouse off of key releases it
				if (this.isDown) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_STOP, this.pitch, this.octave);
				}
			}
			else if (evt.type == MouseEvent.MOUSE_OVER) {
				// allow user to hold down mouse button and press keys while dragging over them
				if (evt.buttonDown && !this.isDown) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_START, this.pitch, this.octave);
				}
			}
			
			evt.stopImmediatePropagation();
			evt.preventDefault();
		}
		
		/**
		 * Draw key.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.graphics.clear();
			this.graphics.beginFill(this.color);
			if (Note.isBlack(this.pitch)) {
				this.graphics.drawRect(0, 0, WIDTH_BLACK + 1, HEIGHT_BLACK);
			}
			else {
				this.graphics.drawRect(0, HEIGHT_BLACK, WIDTH_WHITE, HEIGHT_WHITE - HEIGHT_BLACK);
				switch (this.pitch) {
					case Note.C:
					case Note.F:
						this.graphics.drawRect(0, 0, WIDTH_WHITE - WIDTH_BLACK / 2, HEIGHT_BLACK);
						break;
					case Note.D:
					case Note.G:
					case Note.A:
						this.graphics.drawRect(WIDTH_BLACK / 2, 0, WIDTH_WHITE - WIDTH_BLACK, HEIGHT_BLACK);
						break;
					case Note.E:
					case Note.B:
						this.graphics.drawRect(WIDTH_BLACK / 2, 0, WIDTH_WHITE - WIDTH_BLACK / 2, HEIGHT_BLACK);
						break;
				}
			}
			this.graphics.endFill();
		}
		
		/**
		 * Press key.  Changes color from black to white or vice versa.
		 */
		public function press() : void {
			if (!isDown) {
				isDown = true;
				if (Note.isBlack(this.pitch)) {
					this.color = 0x666666;
				}
				else {
					this.color = 0xd0d0d0;
				}
			}
		}
		
		/**
		 * Release key.  This sets interval to fade key's color back to normal.
		 */
		public function release() : void {
			if (isDown) {
				isDown = false;
				clearInterval(interval);
				interval = setInterval(fadeOut, 1);
			}
		}
		
		/**
		 * Fade key color until it returns to normal.
		 */
		private function fadeOut() : void {
			if (Note.isBlack(this.pitch)) {
				this.color = this.color - 0x0a0a0a;
			}
			else {
				this.color = this.color + 0x040404;
			}
			if (this.color < 0x0a0a0a) {
				this.color = 0x000000;
				clearInterval(interval);
			}
			if (this.color > 0xfbfbfb) {
				this.color = 0xffffff;
				clearInterval(interval);
			}
		}
	}
}