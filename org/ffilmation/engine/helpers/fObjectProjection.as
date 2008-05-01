package org.ffilmation.engine.helpers {
	
		// Imports
		import flash.geom.Point
		
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Contains projection information for a given object
	  */
		public class fObjectProjection {

			// Public properties
			
			/**
			* The four Points that enclose the objects projection 
			*/
	    public var polygon:Array
	    
	    /** 
	    * The length of the object's projection
	    */
			public var size:Number
			
			/**
			* Origin point for projection
			*/
			public var origin:Point
			
			/**
			* End point for projection
			*/
			public var end:Point
			
			// Constructor
			function fObjectProjection():void {
			
			   this.size = 0
			}

		}
		
} 
