package org.ffilmation.engine.bulletRenderers {

		// Imports
		import flash.display.*
		import flash.events.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.interfaces.*
		
		/**
		* This renderer renders a bullet as a single color pixel
		*/
		public class fPixelBulletRenderer implements fEngineBulletRenderer {
			
			// All bullets can share this
			private var pixelBitmapData:BitmapData
			
			//Size
			private var size:Number
			
			//Alpha
			private var alpha:Number

			/**
			* Constructor for the "Pixel" bullet renderer class
			* @param color Color of the pixel to be drawn as bullet
			* @param size Size of the pixel
			* @param alpha Alpha value
			*/
			public function fPixelBulletRenderer(color:Number,size:Number,alpha:Number=1):void {
		  	this.pixelBitmapData = new BitmapData(size,size,false,color)
		  	this.size = size
		  	this.alpha = alpha
			}

		  /** @private */
		  public function init(bullet:fBullet):void {
		  	bullet.customData.pixelBitmap = new	Bitmap(this.pixelBitmapData)
		  	bullet.container.addChild(bullet.customData.pixelBitmap)
		  	bullet.customData.pixelBitmap.alpha = this.alpha
		  	bullet.customData.pixelBitmap.x = bullet.customData.pixelBitmap.y = -Math.round(this.size/2)
		  }

		  /** @private */
			public function update(bullet:fBullet):void {
			}

		  /** @private */
			public function clear(bullet:fBullet):void {
		  	bullet.container.removeChild(bullet.customData.pixelBitmap)
		  	bullet.customData.pixelBitmap = null
			}

		}

}
