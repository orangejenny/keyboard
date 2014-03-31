package saui.proj4
{
	import flash.display.BitmapData;
	
	import mx.core.BitmapAsset;
	import mx.core.SoundAsset;
	
	/**
	 * The ResourceFactory class provides static methods to access to all embedded sounds and images.
	 * 
	 * @author Jenny Schweers
	 */
	
	public class ResourceFactory
	{
		// Images: notes and rests
		public static const WHOLE_NOTE : int = 0;
		public static const HALF_NOTE : int = 1;
		public static const QUARTER_NOTE : int = 2;
		public static const EIGHTH_NOTE : int = 3;
		public static const WHOLE_REST : int = 4;
		public static const HALF_REST : int = 5;
		public static const QUARTER_REST : int = 6;
		public static const EIGHTH_REST : int = 7;
		
		// Images: other
		public static const SHARP : int = 8;
		public static const FLAT : int = 9;
		public static const TREBLE_CLEF : int = 10;
		public static const BASS_CLEF : int = 11;
		public static const BRACE : int = 12;
		public static const QUESTION_MARK : int = 13;
		
        [Embed(source="resources/whole.gif")]
		private static const wholeNote:Class;
        [Embed(source="resources/half.gif")]
		private static const halfNote:Class;
        [Embed(source="resources/quarter.gif")]
		private static const quarterNote:Class;
        [Embed(source="resources/eighth.gif")]
		private static const eighthNote:Class;
        [Embed(source="resources/whole_rest.gif")]
		private static const wholeRest:Class;
        [Embed(source="resources/half_rest.gif")]
		private static const halfRest:Class;
        [Embed(source="resources/quarter_rest.gif")]
		private static const quarterRest:Class;
        [Embed(source="resources/eighth_rest.gif")]
		private static const eighthRest:Class;
        [Embed(source="resources/sharp.gif")]
		private static const sharp:Class;
        [Embed(source="resources/flat.gif")]
		private static const flat:Class;
        [Embed(source="resources/treble.gif")]
		private static const trebleClef:Class;
        [Embed(source="resources/bass.gif")]
		private static const bassClef:Class;
        [Embed(source="resources/brace.gif")]
		private static const brace:Class;
		[Embed(source="resources/qmark.gif")]
		private static const qmark:Class;
		
		private static var images : Array = [];
		images.push(wholeNote);
		images.push(halfNote);
		images.push(quarterNote);
		images.push(eighthNote);
		images.push(wholeRest);
		images.push(halfRest);
		images.push(quarterRest);
		images.push(eighthRest);
		images.push(sharp);
		images.push(flat);
		images.push(trebleClef);
		images.push(bassClef);
		images.push(brace);
		images.push(qmark);
		
		// Sounds: Other
		public static const METRONOME : int = 88;
        [Embed(source="sounds/Pop.mp3")]
		private static const metronomeSound:Class;
		
		public static const ERROR : int = 89;
        [Embed(source="sounds/Glass.mp3")]
		private static const errorSound:Class;
		
		// Sounds: one for each pitch on piano
		[Embed(source="sounds/0.mp3")]
		private static const sound0:Class;
		[Embed(source="sounds/1.mp3")]
		private static const sound1:Class;
		[Embed(source="sounds/2.mp3")]
		private static const sound2:Class;
		[Embed(source="sounds/3.mp3")]
		private static const sound3:Class;
		[Embed(source="sounds/4.mp3")]
		private static const sound4:Class;
		[Embed(source="sounds/5.mp3")]
		private static const sound5:Class;
		[Embed(source="sounds/6.mp3")]
		private static const sound6:Class;
		[Embed(source="sounds/7.mp3")]
		private static const sound7:Class;
		[Embed(source="sounds/8.mp3")]
		private static const sound8:Class;
		[Embed(source="sounds/9.mp3")]
		private static const sound9:Class;
		[Embed(source="sounds/10.mp3")]
		private static const sound10:Class;
		[Embed(source="sounds/11.mp3")]
		private static const sound11:Class;
		[Embed(source="sounds/12.mp3")]
		private static const sound12:Class;
		[Embed(source="sounds/13.mp3")]
		private static const sound13:Class;
		[Embed(source="sounds/14.mp3")]
		private static const sound14:Class;
		[Embed(source="sounds/15.mp3")]
		private static const sound15:Class;
		[Embed(source="sounds/16.mp3")]
		private static const sound16:Class;
		[Embed(source="sounds/17.mp3")]
		private static const sound17:Class;
		[Embed(source="sounds/18.mp3")]
		private static const sound18:Class;
		[Embed(source="sounds/19.mp3")]
		private static const sound19:Class;
		[Embed(source="sounds/20.mp3")]
		private static const sound20:Class;
		[Embed(source="sounds/21.mp3")]
		private static const sound21:Class;
		[Embed(source="sounds/22.mp3")]
		private static const sound22:Class;
		[Embed(source="sounds/23.mp3")]
		private static const sound23:Class;
		[Embed(source="sounds/24.mp3")]
		private static const sound24:Class;
		[Embed(source="sounds/25.mp3")]
		private static const sound25:Class;
		[Embed(source="sounds/26.mp3")]
		private static const sound26:Class;
		[Embed(source="sounds/27.mp3")]
		private static const sound27:Class;
		[Embed(source="sounds/28.mp3")]
		private static const sound28:Class;
		[Embed(source="sounds/29.mp3")]
		private static const sound29:Class;
		[Embed(source="sounds/30.mp3")]
		private static const sound30:Class;
		[Embed(source="sounds/31.mp3")]
		private static const sound31:Class;
		[Embed(source="sounds/32.mp3")]
		private static const sound32:Class;
		[Embed(source="sounds/33.mp3")]
		private static const sound33:Class;
		[Embed(source="sounds/34.mp3")]
		private static const sound34:Class;
		[Embed(source="sounds/35.mp3")]
		private static const sound35:Class;
		[Embed(source="sounds/36.mp3")]
		private static const sound36:Class;
		[Embed(source="sounds/37.mp3")]
		private static const sound37:Class;
		[Embed(source="sounds/38.mp3")]
		private static const sound38:Class;
		[Embed(source="sounds/39.mp3")]
		private static const sound39:Class;
		[Embed(source="sounds/40.mp3")]
		private static const sound40:Class;
		[Embed(source="sounds/41.mp3")]
		private static const sound41:Class;
		[Embed(source="sounds/42.mp3")]
		private static const sound42:Class;
		[Embed(source="sounds/43.mp3")]
		private static const sound43:Class;
		[Embed(source="sounds/44.mp3")]
		private static const sound44:Class;
		[Embed(source="sounds/45.mp3")]
		private static const sound45:Class;
		[Embed(source="sounds/46.mp3")]
		private static const sound46:Class;
		[Embed(source="sounds/47.mp3")]
		private static const sound47:Class;
		[Embed(source="sounds/48.mp3")]
		private static const sound48:Class;
		[Embed(source="sounds/49.mp3")]
		private static const sound49:Class;
		[Embed(source="sounds/50.mp3")]
		private static const sound50:Class;
		[Embed(source="sounds/51.mp3")]
		private static const sound51:Class;
		[Embed(source="sounds/52.mp3")]
		private static const sound52:Class;
		[Embed(source="sounds/53.mp3")]
		private static const sound53:Class;
		[Embed(source="sounds/54.mp3")]
		private static const sound54:Class;
		[Embed(source="sounds/55.mp3")]
		private static const sound55:Class;
		[Embed(source="sounds/56.mp3")]
		private static const sound56:Class;
		[Embed(source="sounds/57.mp3")]
		private static const sound57:Class;
		[Embed(source="sounds/58.mp3")]
		private static const sound58:Class;
		[Embed(source="sounds/59.mp3")]
		private static const sound59:Class;
		[Embed(source="sounds/60.mp3")]
		private static const sound60:Class;
		[Embed(source="sounds/61.mp3")]
		private static const sound61:Class;
		[Embed(source="sounds/62.mp3")]
		private static const sound62:Class;
		[Embed(source="sounds/63.mp3")]
		private static const sound63:Class;
		[Embed(source="sounds/64.mp3")]
		private static const sound64:Class;
		[Embed(source="sounds/65.mp3")]
		private static const sound65:Class;
		[Embed(source="sounds/66.mp3")]
		private static const sound66:Class;
		[Embed(source="sounds/67.mp3")]
		private static const sound67:Class;
		[Embed(source="sounds/68.mp3")]
		private static const sound68:Class;
		[Embed(source="sounds/69.mp3")]
		private static const sound69:Class;
		[Embed(source="sounds/70.mp3")]
		private static const sound70:Class;
		[Embed(source="sounds/71.mp3")]
		private static const sound71:Class;
		[Embed(source="sounds/72.mp3")]
		private static const sound72:Class;
		[Embed(source="sounds/73.mp3")]
		private static const sound73:Class;
		[Embed(source="sounds/74.mp3")]
		private static const sound74:Class;
		[Embed(source="sounds/75.mp3")]
		private static const sound75:Class;
		[Embed(source="sounds/76.mp3")]
		private static const sound76:Class;
		[Embed(source="sounds/77.mp3")]
		private static const sound77:Class;
		[Embed(source="sounds/78.mp3")]
		private static const sound78:Class;
		[Embed(source="sounds/79.mp3")]
		private static const sound79:Class;
		[Embed(source="sounds/80.mp3")]
		private static const sound80:Class;
		[Embed(source="sounds/81.mp3")]
		private static const sound81:Class;
		[Embed(source="sounds/82.mp3")]
		private static const sound82:Class;
		[Embed(source="sounds/83.mp3")]
		private static const sound83:Class;
		[Embed(source="sounds/84.mp3")]
		private static const sound84:Class;
		[Embed(source="sounds/85.mp3")]
		private static const sound85:Class;
		[Embed(source="sounds/86.mp3")]
		private static const sound86:Class;
		[Embed(source="sounds/87.mp3")]
		private static const sound87:Class;
		
		private static var sounds : Array = [];
		sounds.push(sound0);
		sounds.push(sound1);
		sounds.push(sound2);
		sounds.push(sound3);
		sounds.push(sound4);
		sounds.push(sound5);
		sounds.push(sound6);
		sounds.push(sound7);
		sounds.push(sound8);
		sounds.push(sound9);
		sounds.push(sound10);
		sounds.push(sound11);
		sounds.push(sound12);
		sounds.push(sound13);
		sounds.push(sound14);
		sounds.push(sound15);
		sounds.push(sound16);
		sounds.push(sound17);
		sounds.push(sound18);
		sounds.push(sound19);
		sounds.push(sound20);
		sounds.push(sound21);
		sounds.push(sound22);
		sounds.push(sound23);
		sounds.push(sound24);
		sounds.push(sound25);
		sounds.push(sound26);
		sounds.push(sound27);
		sounds.push(sound28);
		sounds.push(sound29);
		sounds.push(sound30);
		sounds.push(sound31);
		sounds.push(sound32);
		sounds.push(sound33);
		sounds.push(sound34);
		sounds.push(sound35);
		sounds.push(sound36);
		sounds.push(sound37);
		sounds.push(sound38);
		sounds.push(sound39);
		sounds.push(sound40);
		sounds.push(sound41);
		sounds.push(sound42);
		sounds.push(sound43);
		sounds.push(sound44);
		sounds.push(sound45);
		sounds.push(sound46);
		sounds.push(sound47);
		sounds.push(sound48);
		sounds.push(sound49);
		sounds.push(sound50);
		sounds.push(sound51);
		sounds.push(sound52);
		sounds.push(sound53);
		sounds.push(sound54);
		sounds.push(sound55);
		sounds.push(sound56);
		sounds.push(sound57);
		sounds.push(sound58);
		sounds.push(sound59);
		sounds.push(sound60);
		sounds.push(sound61);
		sounds.push(sound62);
		sounds.push(sound63);
		sounds.push(sound64);
		sounds.push(sound65);
		sounds.push(sound66);
		sounds.push(sound67);
		sounds.push(sound68);
		sounds.push(sound69);
		sounds.push(sound70);
		sounds.push(sound71);
		sounds.push(sound72);
		sounds.push(sound73);
		sounds.push(sound74);
		sounds.push(sound75);
		sounds.push(sound76);
		sounds.push(sound77);
		sounds.push(sound78);
		sounds.push(sound79);
		sounds.push(sound80);
		sounds.push(sound81);
		sounds.push(sound82);
		sounds.push(sound83);
		sounds.push(sound84);
		sounds.push(sound85);
		sounds.push(sound86);
		sounds.push(sound87);
		sounds.push(metronomeSound);
		sounds.push(errorSound);
		
		/**
		 * Constructor, should not be called.
		 * 
		 */		
		public function ResourceFactory() {
			throw new TypeError("ResourceFactory is not a constructor");
		}

		/**
		 * Gets the BitmapData for an image.
		 * 
		 * @param id The image to get, should be one of ResourceFactory's constants.
		 * 
		 * @return BitmapData The image
		 */
		public static function getImage(id:int) : BitmapData {
			var image : BitmapAsset = BitmapAsset(new images[id]);
			return image.bitmapData;
		}
		
		/**
		 * Gets a sound.
		 * 
		 * @param id The sound to get, should be one of ResourceFactory's constants.
		 * 
		 * @return SoundAsset The sound requested.
		 */
		public static function getSound(id:int) : SoundAsset {
			var sound : SoundAsset = SoundAsset(new sounds[id]);
			return sound;
		}
	}
}