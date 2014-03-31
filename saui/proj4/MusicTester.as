package saui.proj4
{
	import mx.controls.Alert;
	import mx.core.Application;
	
	/**
	 * MusicTester is the main class for running the application.
	 * 
	 * @author Jenny Schweers
	 */
	public class MusicTester 
	{
		public static const MAX_WIDTH:int = MusicContainer.WIDTH;
		public static const MAX_HEIGHT:int = MusicContainer.HEIGHT;

		// main application
		protected static var frame : Application = null;

		/**
		 * Constructor.
		 */
		public function MusicTester() {
			frame = Application(Application.application);
			frame.width = MAX_WIDTH;
			frame.height = MAX_HEIGHT;
			
			// create a MusicContainer
			var musicContainer : MusicContainer = new MusicContainer(0, 0);
			frame.addChild(musicContainer);
			
			Alert.show("Welcome to your Flex piano");
		}

		public static function main() : void {
			var musicTester : MusicTester = new MusicTester();
		}
	}
}