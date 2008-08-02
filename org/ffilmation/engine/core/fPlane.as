package org.ffilmation.engine.core {
	
		// Imports
		import org.ffilmation.engine.elements.*
	  
		/**
		* <p>fPlanes are the 2d surfaces that provide the main structure for any scene. Once created, planes can't be altered
		* as the render engine relies heavily on precalculations that depend on the structure of the scene.</p>
		*
		* <p>Planes cannot be instantiated directly. Instead, fWall and fFloor are used.</p>
		*
		* <p>fPlane contains all the lighting, occlusions and shadowcasting code. They also support bump mapping</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT</p>
		*/
		public class fPlane extends fRenderableElement {
		
			// Public properties
			
			/** 
			* Array of holes in this plane. 
			* You can't create holes dynamically, they must be in the plane's material, but you can open and close them as you wish
			*
		  * @see org.ffilmation.engine.core.fHole
			*/
			public var holes:Array									// Array of holes in this plane
			
			/** 
			* Material applied to this plane
			*/
			public var material:fMaterial
			
			// Private properties
			/** @private */
			public var zIndex:Number

			// Constructor
			/** @private */
			function fPlane(defObj:XML,scene:fScene,width:Number,height:Number):void {
				
				 // Prepare material
				 this.scene = scene
				 this.material = new fMaterial(defObj.@src,width,height,this)
				 
				 // Previous
				 super(defObj,scene)

			   // Holes
			   this.holes = this.material.getHoles()

			}

			// Planes don't move
			/** @private */
			public override function moveTo(x:Number,y:Number,z:Number):void {
			  throw new Error("Filmation Engine Exception: You can't move a fPlane. ("+this.id+")"); 
		  }

			/** @private */
			// Is this plane in front of other plane ?
			public function inFrontOf(p:fPlane):Boolean {
				return false
			}

			/** @private */
			public function setZ(zIndex:Number):void {
			   this.zIndex = zIndex
			   this.setDepth(zIndex)
			}

			/** @private */
			public function disposePlane():void {

				this.material.dispose()
				this.material = null
				for(var i:Number=0;i<this.holes.length;i++) delete this.holes[i]
				this.holes = null
				this.disposeRenderable()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposePlane()
			}

		}

}
