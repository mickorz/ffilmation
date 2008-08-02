package org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers {
	
		// Imports
		import flash.display.*
		import org.ffilmation.engine.core.*
		
		/**
		* @private
		* Container object for an object Shadow
	  */
		public class fObjectShadow {

			// Public properties
			public var shadow:Sprite
			
			public var clip:MovieClip

			public var request:fRenderableElement

			// Constructor
			function fObjectShadow(shadow:Sprite,clip:MovieClip,request:fRenderableElement):void {
			   this.shadow = shadow
			   this.clip = clip
			   this.request = request
			}

			public function dispose():void {
				 this.shadow = null
				 this.clip = null
				 this.request = null
			}

		}
		
} 
