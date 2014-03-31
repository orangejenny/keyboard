package saui.proj4
{
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.*;
	
	/**
	 * The MusicPlayer class controls sound for the piano.
	 * 
	 * It does not control the metronome or error sounds.
	 * 
	 * When sounds stop, they slowly fade out.
	 * 
	 * @author Jenny Schweers
	 */ 
	public class MusicPlayer
	{
		private var sounds : Array = null;				// Sound objects
		private var channels : Array = null;			// SoundChannel objects
		private var intervals : Array = null;			// interval ids for fading sound
		
		/**
		 * Constructor.
		 */
		public function MusicPlayer()
		{
			sounds = new Array(88);
			channels = new Array(88);
			intervals = new Array(88);
			intervals = new Array(88);
			
			var i : int = 0;
			var name : String = "";
			while (i < 88) {
				sounds[i] = ResourceFactory.getSound(i);			// load sounds
				channels[i] = new SoundChannel();					// initialize so calling stop() won't throw error
				intervals[i] = 0; 
				i++;
			}
		}
		
		/**
		 * Start playing a key.
		 */
		public function play(pitch:Number, octave:Number) : void {
			var index : int = Note.index88(pitch, octave);
			clearInterval(intervals[index]);
			channels[index] = sounds[index].play();
		}
		
		/**
		 * Stop playing a key (start fading: drop volume every tenth of a second).
		 */
		public function stop(pitch:Number, octave:Number) : void {
			var index : int = Note.index88(pitch, octave);
			clearInterval(intervals[index]);
			intervals[index] = setInterval(fadeOut, 10, pitch, octave);
		}
		
		/**
		 * Stop all currently playing sounds.
		 */
		public function stopAll() : void {
			for (var i : int = 0; i < intervals.length; i++) {
				channels[i].stop();
			}
		}

		/**
		 * Fade given sound, and stop it altogether once volume is zero.
		 */
		private function fadeOut(pitch:Number, octave:Number) : void {
			var index : int = Note.index88(pitch, octave);
			var volume:Number = channels[index].soundTransform.volume;
			if (volume <= 0) {
				channels[index].stop();
				clearInterval(intervals[index]);
			}
			else {
				channels[index].soundTransform = new SoundTransform(volume - 0.1, 0);
			}
		}
	}
}