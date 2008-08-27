// Basic renderable element class

package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
		import org.ffilmation.utils.*
	  import flash.display.*
	  import flash.events.*	
		import flash.utils.*
		import flash.geom.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.logicSolvers.projectionSolver.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers.*

		/**
		* This class renders an fBullet. Note that this simply wll create and move an empty Sprite. Bullets use custom renderes that draw
		* into this empy Sprite
		* @private
		*/
		public class fFlash9BulletRenderer extends fFlash9ElementRenderer {
			
			// Private properties
	    private var baseObj:MovieClip
			private var lights:Array
			private var glight:fGlobalLight
			private var allShadows:Array
			private var currentSprite:MovieClip
			private var currentSpriteIndex:Number
			private var occlusionCount:Number = 0
			public var simpleShadows:Boolean = false
			
			// Protected properties
			protected var projectionCache:fObjectProjectionCache
			
			/** @private */
	    public var shadowObj:Class
			
			// Constructor
			/** @private */
			function fFlash9BulletRenderer(rEngine:fFlash9RenderEngine,container:MovieClip,element:fBullet):void {
				
				 // Previous
				 super(rEngine,element,container,container)

			}

			/**
			* Place asset its proper position
			*/
			public override function place():void {

			   // Place in position
			   var coords:Point = this.scene.translateCoords(this.element.x,this.element.y,this.element.z)
			   this.container.x = coords.x
			   this.container.y = coords.y
			   
			}

		}
		
		
}