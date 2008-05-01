
package org.ffilmation.engine.helpers {

		import org.ffilmation.engine.core.*

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* fVisibilityInfo provides information about an objects visibility from a given point
		*/
		public class fVisibilityInfo {
		
				// Public variables
				public var obj:fRenderableElement
				public var distance:Number
				
				// Constructor
				public function fVisibilityInfo(obj:fRenderableElement,distance:Number):void {
				
						this.obj = obj
						this.distance = distance
				
				}
			 
		}
		
		
}

