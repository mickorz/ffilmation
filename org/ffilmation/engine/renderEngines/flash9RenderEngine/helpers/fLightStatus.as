package org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers {
	
		// Imports
		import flash.geom.Point

		import org.ffilmation.utils.polygons.*
		import org.ffilmation.engine.core.*

		/**
		* @private
		* Keeps track of several variables of one light in one plane
		*/
		public class fLightStatus {

			// Public properties
	    public var element:fPlane
			public var light:fLight
			
			public var created:Boolean
			public var lightZ:Number
			public var localPos:Point = new Point()
			public var localScale:Number
			
			// Constructor
			function fLightStatus(element:fPlane,light:fLight):void {
			
			   // References
			   this.element = element
			   this.light = light
			
			   // Status
			   this.created = false              // Indicates if all containers have already been created
			   this.lightZ = 0                	 // Light's last z position
			
			}

		}

}
