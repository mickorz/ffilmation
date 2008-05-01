package org.ffilmation.engine.helpers {

		// Imports
		import org.ffilmation.engine.core.*

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* fShadowedVisibilityInfo provides information about an objects visibility from a given point and shadows affecting it
		*/
		public class fShadowedVisibilityInfo extends fVisibilityInfo {
		
				// Public variables
				public var shadows:Array
				public var withinRange:Number
				
				// Constructor
				public function fShadowedVisibilityInfo(obj:fRenderableElement,distance:Number):void {
				
						super(obj,distance)
						this.shadows = new Array
				
				}
				
				public function addShadow(shadow:fVisibilityInfo):void {
					
						this.shadows[this.shadows.length] = shadow
					
				}
			 
		}
		
		
}

