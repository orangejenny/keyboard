package saui.proj4
{
	import flash.events.Event;
	
	import mx.core.UIComponent;

	/**
	 * The NoteEvent class is for events custom to this application:
	 * starting/stopping notes and changing which part of the 
	 * master keyboard is being used.
	 * 
	 * @author Jenny Schweers
	 */
	public class NoteEvent extends Event
	{
		// Types of NoteEvent
		public static const NOTE_START : String = "start";
		public static const NOTE_STOP : String = "stop";
		public static const NOTE_SET_MASTER : String = "master";		// set start note on master keyboard to this note
		
		public var pitch : Number = -1;
		public var octave : Number = -1;
		
		/**
		 * Constructor for NoteEvent
		 */
		public function NoteEvent(type:String, bubbles:Boolean, cancelable:Boolean, pitch:Number, octave:Number)
		{
			super(type, bubbles, cancelable);
			this.pitch = pitch;
			this.octave = octave;
		}

		/**
		 * Shortcut function to dispatch events without remembering the right values for bubbles and cancelable
		 */
		public static function dispatch(uic:UIComponent, type:String, pitch:Number, octave:Number) : void {
			uic.dispatchEvent(new NoteEvent(type, true, false, pitch, octave));
		}
	}
}