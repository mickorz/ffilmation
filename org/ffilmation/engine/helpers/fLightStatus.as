package org.ffilmation.engine.helpers {
	
		// Imports
		import org.ffilmation.engine.core.*

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Keeps track of several variables of one light in one plane
		*/
		public class fLightStatus {

			// Public properties
	    public var element:fRenderableElement
			public var light:fLight
			
			public var created:Boolean
			public var lightZ:Number
			
			public var lUp:Number
			public var lDown:Number
			public var lLeft:Number
			public var lRight:Number

			// Constructor
			function fLightStatus(element:fRenderableElement,light:fLight):void {
			
			   // References
			   this.element = element
			   this.light = light
			
			   // Status
			   this.created = false              // Indicates if all containers have already been created
			   this.lightZ = 0                	 // fLight's last z position
			
			   this.lUp = 0                   	 // fLight range ( used in optimizations )
			   this.lDown = 0
			   this.lLeft = 0
			   this.lRight = 0
			
			}

		}

}
