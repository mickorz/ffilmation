package org.ffilmation.engine.bulletRenderers {

		// Imports
		import flash.display.*
		import flash.events.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.interfaces.*
		
		/**
		* This renderer renders a bullet as a line
		*/
		public class fLineBulletRenderer implements fEngineBulletRenderer {
			
			//Color
			private var color:Number
			
			//Alpha
			private var alpha:Number

			//Size
			private var size:Number

			/**
			* Constructor for the "Line" bullet renderer class
			* @param color Line color
			* @param size Line thickness
			* @param alpha Line alpha
			*/
			public function fLineBulletRenderer(color:Number,size:Number,alpha:Number=1):void {
		  	this.color = color
		  	this.size = size
		  	this.alpha = alpha
			}

		  /** @private */
		  public function init(bullet:fBullet):void {
		  	bullet.customData.oldx = bullet.container.x
		  	bullet.customData.oldy = bullet.container.y
		  	bullet.container.graphics.clear()
		  }

		  /** @private */
			public function update(bullet:fBullet):void {
		  	bullet.container.graphics.clear()
		  	bullet.container.graphics.lineStyle(this.size,this.color,this.alpha)
		  	bullet.container.graphics.lineTo(bullet.customData.oldx - bullet.container.x,bullet.customData.oldy - bullet.container.y)
		  	bullet.customData.oldx = bullet.container.x
		  	bullet.customData.oldy = bullet.container.y
			}

		  /** @private */
			public function clear(bullet:fBullet):void {
		  	bullet.container.graphics.clear()
			}

		}

}
