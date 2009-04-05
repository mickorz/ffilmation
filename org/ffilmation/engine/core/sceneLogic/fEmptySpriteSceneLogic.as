// EMPTY SPRITE LOGIC
package org.ffilmation.engine.core.sceneLogic {


		// Imports
		import flash.events.*
		import flash.display.*
		import flash.utils.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.logicSolvers.visibilitySolver.*
		import org.ffilmation.engine.logicSolvers.coverageSolver.*
		

		/**
		* This class stores static methods related to emptySprites in the scene
		* @private
		*/
		public class fEmptySpriteSceneLogic {	

			
			// Process New cell for EmptySprites
			public static function processNewCellEmptySprite(scene:fScene,spr:fEmptySprite,forceReset:Boolean = false):void {
			
			}

			// Main render method for EmptySprites
			public static function renderEmptySprite(scene:fScene,spr:fEmptySprite):void {
			   
				 // Move EmptySprites to its new position
				 scene.renderEngine.updateEmptySpritePosition(spr)
				 
			}


		}

}
