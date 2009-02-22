package org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers {
	
		// Imports
		import flash.geom.Point
		import org.ffilmation.engine.elements.fFloor

		import org.ffilmation.utils.polygons.*
		
		/**
		* @private
		* Contains projection information for a given floor
	  */
		public class fFloorProjectionCache {

			// Public properties
			
			public var x:Number
			public var y:Number
			public var z:Number
			public var fl:fFloor
			public var points:fPolygon
			public var holes:Array


			// Constructor
			function fFloorProjectionCache():void {
			
			}

		}
		
} 
