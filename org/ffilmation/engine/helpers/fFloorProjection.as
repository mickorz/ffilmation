package org.ffilmation.engine.helpers {
	
		// Imports
		import flash.geom.Point
		
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Contains projection information for a given floor
	  */
		public class fFloorProjection {

			// Public properties
			
			public var pUp:Number
			
			public var pDown:Number

			public var pLeft:Number

			public var pRight:Number

			// Constructor
			function fFloorProjection(up:Number,down:Number,left:Number,right:Number):void {
			
			   this.pUp = up
			   this.pDown = down
			   this.pLeft = left
			   this.pRight = right
			}

		}
		
} 
