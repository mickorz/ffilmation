package org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers {
	
		// Imports
		import flash.geom.Point
		
		/**
		* @private
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
