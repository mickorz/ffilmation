package org.ffilmation.engine.helpers {
	
		// Imports
		import flash.display.*
		import org.ffilmation.engine.core.*
		
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
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

		}
		
} 
