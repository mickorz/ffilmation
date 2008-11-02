package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
		import flash.events.*
		import flash.display.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*

		/**
		* This is the basic flash 9 element renderer. All renderes inherit from this
		* @private
		*/
		public class fFlash9ElementRenderer {
		
			/** The element this class renders */
			public var element:fRenderableElement			

			/** The engine for this renderer */
			public var rEngine:fFlash9RenderEngine

			/** The scene where the rendering occurs */
			public var scene:fScene			

			/** The container for the element */
			public var container:MovieClip

			/** The graphic asset for this element */
			public var flashClip:MovieClip

			/** The graphic asset that is displayed for this element */
			public var containerToPaint:DisplayObject

			/** Storing this allows us to show/hide the element */
			private var containerParent:DisplayObjectContainer

			// Constructor
			/** @private */
			function fFlash9ElementRenderer(rEngine:fFlash9RenderEngine,element:fRenderableElement,libraryMovieClip:DisplayObject,spriteToShowHide:MovieClip):void {
				
				 // Pointer to element
				 this.element = element
				 this.scene = element.scene
				 this.rEngine = rEngine
				 
				 // Main container
				 this.containerToPaint = libraryMovieClip
				 if(libraryMovieClip is MovieClip) this.flashClip = (libraryMovieClip as MovieClip)
				 this.container = spriteToShowHide
				 this.containerParent = this.container.parent
				 
				 // Move asset to appropiate position
				 this.place()
				 
				 // Is it hidden at origin ?
				 if(!this.element._visible) this.hide()
				 
			}

			/**
			* Place asset its proper position
			*/
			public function place():void {
			}

			/**
			* Mouse management
			*/
			public function disableMouseEvents():void {
				this.container.mouseEnabled = false
			}

			/**
			* Mouse management
			*/
			public function enableMouseEvents():void {
				this.container.mouseEnabled = true
			}

			/**
			* Renders element visible
			*/
			public function show():void {
			   this.containerParent.addChild(this.container)
			}
			
			/**
			* Renders element invisible
			*/
			public function hide():void {
			   this.containerParent.removeChild(this.container)
			}
			
			/** 
			* Sets global light
			*/
			public function renderGlobalLight(light:fGlobalLight):void {
			}

			/** 
			*	Light reaches element
			*/
			public function lightIn(light:fLight):void {
			}
			
			/**
			* Light leaves element
			*/
		  public function lightOut(light:fLight):void {
			}
			
			/**
			* Render start
			*/
			public function renderStart(light:fLight):void {
			
			
			}
			
			/**
			* Render ( draw ) light
			*/
			public function renderLight(light:fLight):void {
			
			
			}
			
			/**
			* Renders shadows of other elements upon this element
			*/
			public function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			
			}

			/**
			* Updates shadow of a moving element into this element
			*/
			public function updateShadow(light:fLight,other:fRenderableElement):void {
			   
			
			}

			/**
			* Removes shadow from another element
			*/
			public function removeShadow(light:fLight,other:fRenderableElement):void {
			
			}

			/**
			* Ends render
			*/
			public function renderFinish(light:fLight):void {
			
			}

			/**
			* Starts acclusion related to one character
			*/
			public function startOcclusion(character:fCharacter):void {
			}

			/**
			* Updates acclusion related to one character
			*/
			public function updateOcclusion(character:fCharacter):void {
			}

			/**
			* Stops acclusion related to one character
			*/
			public function stopOcclusion(character:fCharacter):void {
			}

			/** 
			* Resets shadows. This is called when the fEngine.shadowQuality value is changed
			*/
			public function resetShadows():void {
			}

			/**
			* Frees resources
			*/
			public function disposeRenderer():void {

				// Remove dependencies
				delete this.container.fElementId
				delete this.container.fElement
				this.containerToPaint = null
				this.containerParent = null
				this.container = null
				
			}

			public function dispose():void {
				this.disposeRenderer()
			}



		}

}
