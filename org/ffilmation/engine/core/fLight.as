// LIGHT

package org.ffilmation.engine.core {
	
		// Imports
		import flash.geom.*
		import flash.events.*

		/**
		* <p>The fLight is an abstract definition of a light that contains generic information such as
		* intensity, size, decay and color. To create a new type of light you must extend this class</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT</p>
		*/
		public class fLight extends fElement {
		
			// Constants
			/** @private */
			public static const NOLIGHT:Object = { ra:0, ga:0, ba:0, aa:1, rb: 0,gb: 0, bb: 0, ab:0 }
			
			// Private properties

			// Public properties
			
			/** 
			* Numeric counter assigned by scene
			* @private
			*/
			public var counter:int

			/** An string specifying the color of the light in HTML format, example: #ffeedd */
			public var hexcolor:Number

			/** Radius of the sphere that identifies the light */
			public var size:Number

			/** Intensity of the light goes from 0 to 100 */
			public var intensity:Number

			/** From 0 to 100 marks the distance along the lights's radius from where intensity stars to fade. A 0 decay defines a solid light */
			public var decay:Number

			/** Determines if this light will be rendered with bumpmapping.
			* Please note that for the bumpMapping to work in a given surface,
			* the surface will need a bumpMap definition and bumpMapping must be enabled in the engine's global parameters
			*/
			public var bump:Boolean

			/** @private */
			public var elementsV:Array
			/** @private */
			public var nElements:int
			/** @private */
			public var vCharacters:Array
			
			/** @private */
			public var lightColor:ColorTransform
			/** @private */
			public var color:ColorTransform
			
			/**
 			* The fLight.RENDER constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>lightrender</code> event.
 			* The event is dispatched when the light is rendered
 			*/
 			public static const RENDER:String = "lightrender"
 			
			/**
 			* The fLight.INTENSITYCHANGE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>lightintensitychange</code> event.
 			* The event is dispatched when the light changes its intensity
 			*/
			public static const INTENSITYCHANGE:String = "lightintensitychange"
			
			// Constructor
			/** @private */
			function fLight(defObj:XML,scene:fScene) {
			
				 // Previous
				 super(defObj,scene)			 
				 
				 // Current color
			   this.color = null                        

				 // BumpMapped light ?
			   this.bump = (defObj.@bump[0]=="true")

			   // Size
			   var temp:XMLList = defObj.@["size"]
			   if(temp.length()>0) this.size = new Number(temp[0])   
			   else this.size = Infinity
			
			   // fLight color
			   temp = defObj.@color
			   if(temp.length()>0) {

			      // Color transform object (100% light)
			      var col:String = temp.toString()
			  	 	this.hexcolor = parseInt(col.substring(1),16)

			      var r:Number=parseInt(col.substring(1,3),16)
			      var g:Number=parseInt(col.substring(3,5),16)
			      var b:Number=parseInt(col.substring(5,7),16)
			      this.lightColor = new ColorTransform(0.5,0.5,0.5,1,r/2,g/2,b/2,0)
			                                            
			   } else {
						// Defaults to white light			   
			   		this.lightColor = new ColorTransform(1,1,1,1,0,0,0,0)
			  	 	this.hexcolor = 0xffffff
			   }                   

				 // Intensity ( percentage from black to this.lightColor ) 
			   temp = defObj.@intensity
			   if(temp.length()>0) this.intensity = new Number(temp)
			   else this.intensity = 0

				 // Decay ( where does start to fade ) 
			   temp = defObj.@decay
			   if(temp.length()>0) this.decay = new Number(temp)
			   else this.decay = 0
					
			   // fLight status
			   this.elementsV = null                     // Current array of visible elements
			   this.nElements = 0                     	 // Current number of visible elements
				 this.vCharacters = new Array							 // Current array of afected characters
			
			   // Init
			   this.setIntensity(this.intensity)
			   
			}
			
			/** 
			* This method changes the light's intensity
			*
			* @param percent New intensity from 0 to 100
			*/
			public function setIntensity(percent:Number):void {
			   this.intensity = percent
			   this.dispatchEvent(new Event(fLight.INTENSITYCHANGE))
			}
			
			/**
			* Renders the light
			*/
			public function render():void {
				this.cell = this.scene.translateToCell(this.x,this.y,this.z)
				this.dispatchEvent(new Event(fLight.RENDER))
			}
			
		}
}

