package org.ffilmation.engine.helpers {
	
		// Imports
		import flash.geom.Point
		import org.ffilmation.engine.elements.fFloor
		
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Contains projection information for a given floor
	  */
		public class fFloorProjectionCache {

			// Public properties
			
			public var x:Number
			public var y:Number
			public var z:Number
			public var fl:fFloor
			public var points:fFloorProjection
			public var holes:Array


			// Constructor
			function fFloorProjectionCache():void {
			
			}

		}
		
} 
