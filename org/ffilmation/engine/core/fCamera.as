// CAMERA

package org.ffilmation.engine.core {
	
		// Imports
		import flash.display.BlendMode
		
		/**
		* <p>The fCamera defines which part of the scene is shown.
		* Use the scene's setCamera method to asign any camera to the scene, and then move the camera</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS ELEMENT DIRECTLY.<br>
		* Use scene.createCamera() to add new cameras to the scene</p>
		*
		* @see org.ffilmation.engine.core.fScene#createCamera()
		* @see org.ffilmation.engine.core.fScene#setCamera()
		*
		*/
		public class fCamera extends fElement {
		
			// Constants
			private static var count:Number = 0
			
			/**
			* This value goes from 0 to 100 and indicates the alpha value to which elements that cover the camera are set.
			* "Cover" means literally, onscreen. This allows you to see what you are doing behind a wall. The default "100" value disables this effect
			*/
			public var occlusion:Number = 100
			
			/**
			* Occluded Planes will be assigned this blendMode. Different scenes may require a different mode to achieve a niver effect.
			* BlenMode.OVERLAY works well usually.
			*/
			public var planeOcclusionMode:String = BlendMode.OVERLAY

			/**
			* Occluded Objects will be assigned this blendMode. Different scenes may require a different mode to achieve a niver effect.
			* BlenMode.NORMAL works well usually.
			*/
			public var objectOcclusionMode:String = BlendMode.NORMAL


			/**
			* Constructor for the fCamera class
			*
			* @param scene The scene associated to this camera
		  *
			* @private
			*/
			function fCamera(scene:fScene) {
			
				 var myId:String = "fCamera_"+(fCamera.count++)
				 
				 // Previous
				 super(<camera id={myId}/>,scene)			 
				 
			}
			
			
		}
}

