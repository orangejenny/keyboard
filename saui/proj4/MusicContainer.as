package saui.proj4
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.media.*;
	import flash.text.*;
	import flash.utils.*;
	
	import mx.containers.HBox;
	import mx.controls.*;
	import mx.core.*;
	import mx.events.SliderEvent;
	
	/**
	 * The MusicContainer is the container for the rest of the application's classes and controls.
	 *
	 * @author Jenny Schweers 
	 */
	public class MusicContainer extends UIComponent
	{
		public static const WIDTH : int = 1100;
		public static const HEIGHT : int = 600;
		
		public static const MODE_RECORD : String = "record";
		public static const MODE_PLAYBACK : String = "playback";
		public static const MODE_EDIT : String = "edit";
		
		private var keyboard : MainKeyboard = null;
		private var masterKeyboard : MasterKeyboard = null;
		private var player : MusicPlayer = null;
		private var song : Composition = null;
		
		private var startPitch : Number = Note.C;					// lowest key on the main keyboard
		private var startOctave : Number = 4;

		private var controlButtons : Array = null;
		private var statusMessage : TextField = null;
		private var statusBar : Shape = null;
		private var statusInterval : int = 0;
		private var helpBox : HBox = null;
		
		public var mode : String = MODE_EDIT;
		private var _currentBeat : Number = -1;						// composition cursor position
		public var maxBeat : Number = -1;							// maximum possible cursor position, depending on how long a song has been recorded
		
		private var recordInterval : int = 0;
		private var playInterval : int = 0;
		private var playingNotes : Array = new Array();
		private var recordDate : Date = null;
		
		private var shade : HBox = null;							// used to cover up metronome when not in edit mode
		
		/**
		 * Getter for currentBeat.
		 */
		public function get currentBeat() : Number {return _currentBeat;}
		
		/**
		 * Setter for currentBeat (needs to set composition's cursor position).
		 */
		public function set currentBeat(newBeat : Number) : void {
			_currentBeat = newBeat;
			song.setCursor(newBeat);
		}

		/**
		 * Constructor.
		 */
		public function MusicContainer(x:int, y:int) {
			super();
			
			this.x = x;
			this.y = y;
			this.width = WIDTH;
			this.height = HEIGHT;
			
			keyboard = new MainKeyboard(WIDTH / 2 - MainKeyboard.WIDTH / 2, 370, startPitch, startOctave);
			this.addChild(keyboard);
			
			masterKeyboard = new MasterKeyboard(WIDTH / 2 - MasterKeyboard.WIDTH / 2, 545, startPitch, startOctave);
			this.addChild(masterKeyboard);
			
			player = new MusicPlayer();
			
			var startBPM : int = 80;
			song = new Composition(10, 10, startBPM);
			this.addChild(song);
			
			this.currentBeat = 0;
			this.maxBeat = 0;
			
			drawSettings(startBPM);
			
			drawControls();
			
			drawStatus();
			
			drawHelp();
			
			// draw shadow to cover metronome when it's disabled
			shade = new HBox();
			shade.x = 920;
			shade.y = 365;
			shade.width = 130;
			shade.height = 80;
			shade.graphics.clear();
			shade.graphics.beginFill(0x000000, 0.5);
			shade.graphics.drawRect(0, 0, shade.width, shade.height);
			shade.graphics.endFill();
			setShadeVisibility(false);
			this.addChild(shade);
			
			this.addEventListener(NoteEvent.NOTE_START, startNote);
			this.addEventListener(NoteEvent.NOTE_STOP, stopNote);
			this.addEventListener(NoteEvent.NOTE_SET_MASTER, updateStart);
			
			this.doubleClickEnabled = true;
			this.addEventListener(MouseEvent.CLICK, captureMouseEvent);
			this.addEventListener(MouseEvent.DOUBLE_CLICK, captureMouseEvent);
			
			Application.application.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.captureKeyboardEvent, false);
			Application.application.stage.addEventListener(KeyboardEvent.KEY_UP, this.captureKeyboardEvent, false);
			Application.application.stage.focus = this;
			
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * Show or hide metronome shadow.
		 */
		private function setShadeVisibility(vis:Boolean) : void {
			this.shade.visible = vis;
		}
		
		/**
		 * Handle error: play sound and display message briefly.
		 */
		private function notify(msg:String) : void {
			statusMessage.text = msg;
			statusMessage.visible = true;
			statusBar.x = WIDTH / 2 - (statusMessage.textWidth + 20) / 2 - 5;
			statusBar.graphics.clear();
			statusBar.graphics.beginFill(0xdd0000, 0.5);
			statusBar.graphics.drawRoundRect(0, 0, statusMessage.textWidth + 20, 18, 20);
			statusBar.graphics.endFill();
			statusBar.visible = true;
			clearInterval(statusInterval);
			statusInterval = setInterval(statusStartFade, 3000);
			
			ResourceFactory.getSound(ResourceFactory.ERROR).play(0, 0, new SoundTransform(0.3));
		}
		
		/**
		 * Start fading out status message.
		 */
		private function statusStartFade() : void {
			clearInterval(statusInterval);
			statusInterval = setInterval(statusFadeOut, 50);
		}
		
		/**
		 * Fade status bar, and clear text when status bar is fully faded.
		 */
		private function statusFadeOut() : void {
			statusBar.alpha -= 0.1;
			if (statusBar.alpha <= 0) {
				statusBar.visible = false;
				statusMessage.visible = false;
				statusBar.alpha = 1;
				clearInterval(statusInterval);
			}
		}
		
		/**
		 * Remove all notes and reset cursor to beginning.
		 */
		private function clear(evt:MouseEvent=null) : void {
			this.currentBeat = 0;
			this.maxBeat = 0;
			song.clear();
		}
		
		/**
		 * Interpret click of record/play/pause button.
		 */
		private function captureButtonClick(evt:MouseEvent) : void {
			var target : Button = Button(evt.target);
			mode = target.id;
			if (target.toggle && !target.selected) {
				mode = MODE_EDIT;
			}
			setMode(mode);
		}
		
		/**
		 * Change application mode (recording, playback, or editing)
		 */	
		private function setMode(mode:String) : void {
			this.mode = mode;
			
			// stop everything currently going on
			player.stopAll();
			song.stopAll();
			clearInterval(recordInterval);
			clearInterval(playInterval);
			song.deselectAll();
			playingNotes = new Array();
			
			if (mode == MODE_RECORD) {
				recordDate = new Date();
				song.setMetronome(this.currentBeat % 4);						// sync metronome
				setShadeVisibility(true);										// disable metronome control
				recordDate = new Date();
				recordInterval = setInterval(record, song.msPerBeat() / 2);		// start recording
				controlButtons[1].selected = false;								// make sure "play" button is off
			}
			else if (mode == MODE_PLAYBACK) {
				if (this.currentBeat == this.maxBeat) {
					this.currentBeat = 0;
				}
				song.setMetronome(this.currentBeat % 4);						// sync metronome
				this.currentBeat -= 0.5;
				setShadeVisibility(true);										// disable metronome control
				play();															// play first note
				playInterval = setInterval(play, song.msPerBeat() / 2);			// set interval to play subsequent notes
				controlButtons[0].selected = false;								// make sure "record" button is off
			}
			else if (mode == MODE_EDIT) {
				setShadeVisibility(false);										// enable metronome control
				controlButtons[0].selected = false;								// make sure "record" button is off
				controlButtons[1].selected = false;								// make sure "play" button is off
			}
		}
		
		/**
		 * Record: Increment current beat, clean up notation (fill in rests, etc.), and wrap lines
		 */
		private function record() : void {
			
			// clean up notation
			song.clean(currentBeat, 0.5);
			
			// increment beat
			this.currentBeat += 0.5;
			this.maxBeat = Math.max(this.maxBeat, this.currentBeat);

			// wrap if necessary
			if (this.currentBeat >= Composition.BEATS_PER_LINE * 2) {
				this.currentBeat -= Composition.BEATS_PER_LINE;
				this.maxBeat -= Composition.BEATS_PER_LINE;
				song.wrapLine();
			}
		}
		
		/**
		 * Play whatever is active during the current beat
		 */
		private function play() : void {
			// stop when we hit the end
			if (this.currentBeat >= maxBeat) {
				setMode(MODE_EDIT);
				return;
			}
			
			this.currentBeat += 0.5;
			var newPlayingNotes : Array = song.activeNotes(_currentBeat);
			var n : Note = null;
			var i : int = 0;
			
			for (i = 0; i < newPlayingNotes.length; i++) {
				// start notes that are in newPlayingNotes but not the old playingNotes
				n = Note(newPlayingNotes[i]);
				if (playingNotes.indexOf(n) == -1) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_START, n.pitch, n.octave);
				}
			}
			for (i = 0; i < playingNotes.length; i++) {
				// stop notes that are in playingNotes but not in newPlayingNotes
				n = Note(playingNotes[i]);
				if (newPlayingNotes.indexOf(n) == -1) {
					NoteEvent.dispatch(this, NoteEvent.NOTE_STOP, n.pitch, n.octave);
				}
			}
			
			playingNotes = newPlayingNotes;
		}
		
		/**
		 * Change beats per minute and update metronome slider.
		 */
		private function updateBPM(evt:SliderEvent) : void {
			song.bpm = evt.target.value;
			TextField(evt.target.getChildAt(1)).text = "= " + evt.target.value;
		}
		
		/**
		 * Start note: Play sound. If recording, add to composition. If not in playback mode, highlight key on main keyboard.
		 */
		private function startNote(evt:NoteEvent) : void {
			if (mode != MODE_RECORD || evt.target != this) {
				player.play(evt.pitch, evt.octave);
			}
			
			if (mode != MODE_PLAYBACK) {
				keyboard.press(evt.pitch, evt.octave);
			}
			if (mode == MODE_RECORD) {
				song.addNote(evt.pitch, evt.octave, _currentBeat);
			}
		}
		
		/**
		 * Stop note: end note sound, note on composition, and main keyboard highlight.
		 */
		private function stopNote(evt:NoteEvent) : void {
			player.stop(evt.pitch, evt.octave);
			if (mode != MODE_PLAYBACK) {
				keyboard.release(evt.pitch, evt.octave);
			}
			if (mode == MODE_RECORD && evt.target != this) {
				song.endNote(evt.pitch, evt.octave);
			}
		}
		
		/**
		 * Update start key used for main keyboard.
		 */
		public function updateStart(evt:NoteEvent) : void {
			// stop everything going on
			player.stopAll();
			song.stopAll();
			
			startPitch = evt.pitch;
			startOctave = evt.octave;
			startOctave += Math.floor(startPitch / 12);
			startPitch = (startPitch + 12) % 12;
			if (startOctave < 0 || startOctave == 0 && startPitch < Note.A) {
				startPitch = Note.A;
				startOctave = 0;
			}
			if (startOctave > 6) {
				startPitch = Note.B; 
				startOctave = 6;
			}

			this.startPitch = startPitch;
			this.startOctave = startOctave;
			keyboard.updateStart(startPitch, startOctave);
			masterKeyboard.updateStart(startPitch, startOctave);
			invalidateDisplayList();
		} 
		
		/**
		 * Set handedness.
		 */
		private function changeHandedness(evt:MouseEvent) : void {
			this.keyboard.handedness = evt.target.id;
			Application.application.stage.focus = this;
		}

		/** 
		 * Handle keyboard event by passing it on to children.
		 */
		private function captureKeyboardEvent(evt:KeyboardEvent) : void {
			try {
				keyboard.captureKeyboardEvent(evt);
				song.captureKeyboardEvent(evt);
			}
			catch (err:NoteError) {
				notify(err.message);
			}
			evt.stopImmediatePropagation();
			evt.preventDefault();
		}
		
		private function captureMouseEvent(evt:MouseEvent) : void {
			try {
				if (evt.stageY < song.y + song.height) {
					song.captureMouseEvent(evt);
				}
			}
			catch (err:NoteError) {
				notify(err.message);
			}
			evt.stopImmediatePropagation();
			evt.preventDefault();			
		}
		
		/** 
		 * Draw controls.
		 */
		private function drawSettings(bpm:int) : void {
			// Right vs Left hand control
			var group : RadioButtonGroup = new RadioButtonGroup();
			var radioRight : RadioButton = new RadioButton();
			radioRight.label = "Right-handed";
			radioRight.id = MainKeyboard.RIGHT_HANDED.toString();
			radioRight.visible = true;
			radioRight.width = 100;
			radioRight.height = 18;
			radioRight.x = 930;
			radioRight.y = 470;
			radioRight.group = group;
			radioRight.addEventListener(MouseEvent.CLICK, changeHandedness);
			radioRight.selected = true;
			this.addChild(radioRight);
			
			var radioLeft : RadioButton = new RadioButton();
			radioLeft.label = "Left-handed";
			radioLeft.id = MainKeyboard.LEFT_HANDED.toString();
			radioLeft.width = 100;
			radioLeft.height = 18;
			radioLeft.x = 930;
			radioLeft.y = 490;
			radioLeft.group = group;
			radioLeft.addEventListener(MouseEvent.CLICK, changeHandedness);
			this.addChild(radioLeft);
			
			// Metronome
			var metronomeBox : CheckBox = new CheckBox();
			metronomeBox.mouseFocusEnabled = false;
			metronomeBox.label = "Metronome";
			metronomeBox.width = 100;
			metronomeBox.height = 18;
			metronomeBox.x = 930;
			metronomeBox.y = 370;
			metronomeBox.addEventListener(MouseEvent.CLICK, song.toggleMetronome);
			this.addChild(metronomeBox);
			var metronomeSlider : HSlider = new HSlider();
			metronomeSlider.mouseFocusEnabled = false;
			metronomeSlider.x = 930;
			metronomeSlider.y = 420;
			metronomeSlider.height = 20;
			metronomeSlider.width = 120;
			metronomeSlider.minimum = 60;
			metronomeSlider.maximum = 120;
			metronomeSlider.snapInterval = 2;
			metronomeSlider.value = bpm;
			metronomeSlider.addEventListener(SliderEvent.CHANGE, updateBPM);
			this.addChild(metronomeSlider);
			var m : Matrix = new Matrix();
			m.scale(0.25, 0.25);
			metronomeSlider.graphics.beginBitmapFill(ResourceFactory.getImage(ResourceFactory.QUARTER_NOTE), m);
			metronomeSlider.graphics.drawRect(Note.WIDTH, -Note.HEIGHT, Note.IMAGE_WIDTH, Note.HEIGHT);
			metronomeSlider.graphics.endFill();
			var metronomeText : TextField = new TextField();
			metronomeText.text = "= " + bpm.toString();
			metronomeText.x = 40;
			metronomeText.y = -Note.HEIGHT / 2;
			metronomeText.width = 50;
			metronomeText.height = 20;
			metronomeSlider.addChild(metronomeText);
			
		}
		
		/**
		 * Show or hide help.
		 */
		private function toggleHelp(evt:MouseEvent) : void {
			if (evt.target.label == "Show Help") {
				helpBox.visible = true;
				evt.target.label = "Hide Help";
			}
			else {
				helpBox.visible = false;
				evt.target.label = "Show Help";
			}
		}
		
		/**
		 * Draw help box.
		 */
		private function drawHelp() : void {
			helpBox = new HBox();
			helpBox.width = 180;
			helpBox.height = 185;
			helpBox.x = controlButtons[4].x + controlButtons[4].width + 2;
			helpBox.y = controlButtons[0].y + 30;
			helpBox.visible = false;
			helpBox.drawRoundRect(0, 0, 180, 185, 5, 0xbbbbbb, 0.9);	
			this.addChild(helpBox);
			
			var helpText : Text = new Text();
			helpText.text = "Playing\n\tUse computer keyboard or\n\tclick on keyboard image.\n";
			helpText.text += "Moving cursor\n\tDouble-click on song to begin\n\tplaying/recording from that\n\tpoint.\n";
			helpText.text += "Editing\n\tClick or shift-click to select\n\tnotes.  ";
			helpText.text += "Move notes with the\n\tarrow keys, page up, and\n\tpage down. ";
			helpText.text += "Remove notes\n\twith the delete key.\n";
			helpText.width = 180;
			helpText.height = 185;
			helpText.visible = true;
			helpBox.addChild(helpText);
		}
		
		/**
		 * Position status bar and draw (blank) status message.
		 */
		private function drawStatus() : void {
			statusBar = new Shape();
			statusBar.x = 295;
			statusBar.y = 330;
			statusBar.visible = false;
			this.addChild(statusBar);
						
			var textFormat : TextFormat = new TextFormat();
			textFormat.align = TextFormatAlign.CENTER;
			textFormat.font = "Arial";
			textFormat.size = 12;
			textFormat.color = 0xdddddd;
			statusMessage = new TextField();
			statusMessage.defaultTextFormat = textFormat;
			statusMessage.x = 295;
			statusMessage.y = 330;
			statusMessage.width = 500;
			statusMessage.height = 18;
			statusMessage.text = "";
			statusMessage.visible = false;
			this.addChild(statusMessage);
		}
		
		/**
		 * Draw main control buttons.
		 */
		private function drawControls() : void {
			controlButtons = new Array(5);
			for (var i : int = 0; i < controlButtons.length; i++) {
				controlButtons[i] = new Button();
				controlButtons[i].width = 150;
				controlButtons[i].height = 40;
				controlButtons[i].x = 10;
				controlButtons[i].y = 320 + i * 44;
				controlButtons[i].label = "b" + i;
				controlButtons[i].setStyle("overSkin", MusicButtonSkin);
				controlButtons[i].setStyle("upSkin", MusicButtonSkin);
				controlButtons[i].setStyle("downSkin", MusicButtonSkin);
				controlButtons[i].setStyle("selectedOverSkin", MusicButtonSkin);
				controlButtons[i].setStyle("selectedUpSkin", MusicButtonSkin);
				controlButtons[i].setStyle("selectedDownSkin", MusicButtonSkin);
				this.addChild(controlButtons[i]);
			}
			controlButtons[0].label = "Record";
			controlButtons[0].id = MODE_RECORD;
			controlButtons[0].addEventListener(MouseEvent.CLICK, captureButtonClick);
			controlButtons[0].toggle = true;
			controlButtons[1].label = "Play";
			controlButtons[1].id = MODE_PLAYBACK;
			controlButtons[1].toggle = true;
			controlButtons[1].addEventListener(MouseEvent.CLICK, captureButtonClick);
			controlButtons[2].label = "Pause";
			controlButtons[2].id = MODE_EDIT;
			controlButtons[2].addEventListener(MouseEvent.CLICK, captureButtonClick);
			controlButtons[3].label = "Clear";
			controlButtons[3].addEventListener(MouseEvent.CLICK, clear);
			controlButtons[4].label = "Show Help";
			controlButtons[4].addEventListener(MouseEvent.CLICK, toggleHelp);
			controlButtons[4].toggle = true;
		}

		/**
		 * Draw lines between main keyboard and master keyboard.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.graphics.clear();
			this.graphics.lineStyle(1, 0x333333);
			var startX : int = Note.index52(this.startPitch, this.startOctave) * (MasterKeyboard.WHITE_KEY_WIDTH + 1) + 1;
			this.graphics.moveTo(keyboard.x + 1, keyboard.y + keyboard.height - 1);
			this.graphics.lineTo(masterKeyboard.x + startX, masterKeyboard.y + 1);
			this.graphics.moveTo(keyboard.x + keyboard.width - 1, keyboard.y + keyboard.height - 1);
			this.graphics.lineTo(masterKeyboard.x + startX + MasterKeyboard.ACTIVE_WIDTH, masterKeyboard.y + 1);
		}
	}
}