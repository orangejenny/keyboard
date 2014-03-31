package saui.proj4
{
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.text.*;
	
	import mx.controls.Button;
	import mx.skins.halo.ButtonSkin;

	/**
	 * MusicButtonSkin is used to skin the main controls.
	 * 
	 * Augments the standard ButtonSkin with an image next to each button's label.
	 * For toggle buttons, highlights the button label when the button is selected.
	 * 
	 * @author Jenny Schweers
	 */
	public class MusicButtonSkin extends ButtonSkin
	{	
		/**
		 * Constructor.
		 */
		public function MusicButtonSkin() {
			super();
		}
		
		/**
		 * Draw the button. Call super's updateDisplayList, then add image and possibly highlight.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			this.graphics.clear();
			
			// draw standard ButtonSkin
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var shapeX : int = 15;
			var shapeY : int = 12;
			var shapeDim : int = 16;			
			
			// if this is a toggle button and it's pressed, highlight the label
			if (name == "selectedUpSkin" || name == "selectedOverSkin" || name == "selectedDownSkin") {
				this.graphics.beginFill(0xffff66, 0.3);
				this.graphics.drawRoundRect(shapeX, shapeY + shapeDim / 8, 100, shapeDim * 0.75, 10);
				this.graphics.endFill();
			}
			
			if (Button(this.parent).label.toLowerCase().indexOf("help") != -1) {
				// help: question mark image
				var m : Matrix = new Matrix();
				m.translate(12, 5);
				this.graphics.beginBitmapFill(ResourceFactory.getImage(ResourceFactory.QUESTION_MARK), m);
				this.graphics.drawRect(12, 5, 21, 31);
				this.graphics.endFill();
			}
			else {
				var mode : String = Button(this.parent).id;
				if (mode == MusicContainer.MODE_RECORD) {
					// record: draw red circle
					this.graphics.lineStyle(8, 0xff3333);
					this.graphics.beginFill(0xff3333);
					this.graphics.drawCircle(shapeX + shapeDim / 2, shapeY + shapeDim / 2, shapeDim / 2);
				}
				else if (mode == MusicContainer.MODE_PLAYBACK) {
					// playback: draw green triangle
					this.graphics.lineStyle(8, 0x11aa11);
					this.graphics.beginFill(0x11aa11);
					this.graphics.moveTo(shapeX, shapeY);
					this.graphics.lineTo(shapeX + shapeDim, shapeY + shapeDim / 2);
					this.graphics.lineTo(shapeX, shapeY + shapeDim);
					this.graphics.lineTo(shapeX, shapeY);
				}
				else if (mode == MusicContainer.MODE_EDIT) {
					// pause: draw yellow pause sign
					this.graphics.lineStyle(8, 0xdddd11);
					this.graphics.beginFill(0xdddd00);
					this.graphics.moveTo(shapeX + 2, shapeY);
					this.graphics.lineTo(shapeX + 2, shapeY + shapeDim);
					this.graphics.moveTo(shapeX + shapeDim - 2, shapeY);
					this.graphics.lineTo(shapeX + shapeDim - 2, shapeY + shapeDim);
				}
				else {	
					// clear: draw purple X
					this.graphics.lineStyle(8, 0xaa11aa);
					this.graphics.beginFill(0xaa11aa);
					this.graphics.moveTo(shapeX, shapeY);
					this.graphics.lineTo(shapeX + shapeDim, shapeY + shapeDim);
					this.graphics.moveTo(shapeX + shapeDim, shapeY);
					this.graphics.lineTo(shapeX, shapeY + shapeDim);				
				}
				this.graphics.endFill();
			}
		}
	}
}
