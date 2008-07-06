// Noise

package org.ffilmation.engine.datatypes {
	
		import org.ffilmation.engine.core.*

		/**
		* This object stores the return value for the fScene.translateStageCoordsToElement method
	  * 
		* @see org.ffilmation.engine.core.fScene#translateStageCoordsToElements()
		*/
		public class fCoordinateOccupant {
		
			/**
			* Element that occupies the coordinate
			*/
			public var element:fRenderableElement
			
			/** Coordinate corresponding to the input Stage coordinate */
			public var coordinate:fPoint3d
			
			/**
			* Constructor for the fCoordinateOccupant class
			*/
			function fCoordinateOccupant(element:fRenderableElement,x:Number,y:Number,z:Number):void {
				 this.element = element
				 this.coordinate = new fPoint3d(x,y,z)
			}
			

			
		}
}

