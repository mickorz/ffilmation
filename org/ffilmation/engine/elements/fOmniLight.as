package org.ffilmation.engine.elements {

		// Imports
		import flash.geom.*
		import flash.events.*
		import org.ffilmation.engine.core.*
		
		/**
		* <p>Spot light definition. Behaves as an Omni light in 3dMax. A point projecting light in all directions</p>
		*
		* <p>Projects into planes as a circle</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS ELEMENT DIRECTLY.
		* Use scene.createOmniLight() to add new lights to a scene.</p>
		*
		* @see org.ffilmation.engine.core.fScene#createOmniLight()
		*/
		public class fOmniLight extends fLight {
		
			/**
			* Contructor
			*
			* @param defObj And XML defining the light
			* @param scene The scene where the light will be
			*
			* @private
			*/
			function fOmniLight(defObj:XML,scene:fScene) {

			   super(defObj,scene)
			   
			}
			
			/**
			* Sets the light intensity to a value
			*
			* @param percent The new intensity. Range from 0 to 100
			*
			* @private
			*/
			public override function setIntensity(percent:Number):void {
			   this.intensity = percent
 			   var pc:Number = percent/100

  	     this.color = new ColorTransform(this.lightColor.redMultiplier, this.lightColor.greenMultiplier, this.lightColor.blueMultiplier,pc,
  	                     								 this.lightColor.redOffset,this.lightColor.greenOffset,this.lightColor.blueOffset,0)
  	                     
				 dispatchEvent(new Event(fLight.INTENSITYCHANGE))			           
			}
			
		
		}
}
