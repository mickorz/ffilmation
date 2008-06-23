package org.ffilmation.engine.core {
	
		// Imports
		import flash.events.*
		import flash.display.*

		import org.ffilmation.engine.helpers.*

		/**
		* <p>The fRenderableElement class defines the basic interface for visible elements in your scene.</p>
		*
		* <p>Lights are NOT considered visible elements, therefore don't inherit from fRenderableElement</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT</p>
		*/
		public class fRenderableElement extends fElement {
		
			// Public properties
			
			/**
			* Boolean value indicating if this object receives lighting. You can change this value dynamically.
			* Any element in your XML can be given a receiveLights="false|true" attribute in its XML definition
			*/
			public var receiveLights:Boolean = true

			/**
			* Boolean value indicating if this object receives shadows. You can change this value dynamically
			* Any element in your XML can be given a receiveShadows="false|true" attribute in its XML definition
			*/
			public var receiveShadows:Boolean = true

			/**
			* Boolean value indicating if this object casts shadows. You can change this value dynamically
			* Any element in your XML can be given a castShadows="false|true" attribute in its XML definition
			*/
			public var castShadows:Boolean = true

			/**
			* Boolean value indicating if this object collides with others.
			* Any element in your XML can be given a solid="false|true" attribute in its XML definition. When a character moves to
			* a position that overlaps another element, if will trigger either the fCollide or the fWalkover Events, depending
			* on the solid property for that element.
			*
			* @see org.ffilmation.engine.events.fCollideEvent
			* @see org.ffilmation.engine.events.fWalkoverEvent
			*/
			public var solid:Boolean = true

			/**
			* A reference to the library movieclip that was attached to create the element, so you
			* can acces methods inside, nested clips or whatever
			*/
			public var flashClip:MovieClip

			/** @private */
			public var _depth:Number = 0

			/** @private */
			public var depthOrder:Number

			/** 
			* <p>The container is the base MovieClip that contains everything. If you want to add Mouse Events to your elements, use this
			* property. Camera occlusion will be applied: this means that if this element was occluded to show the camera position,
			* its events are disabled as well so you can click on items behind this element.</p>
			*
			* <p>The container is defined as MovieClip because MovieClips are "dynamic" and properties can be created into them.
			* The container for each element will have two properties:</p>
			* <p>
			* <b>fElementId</b>: The ID for this element<br>
			* <b>fElement</b>: A pointer to the fElement this MovieClip represents<br>
			* </p>
			* <p>These properties will be useful when programming MouseEvents. Using them, you will be able to access the class from an Event
			* listener attached to the MovieClip
			*/
			public var container:MovieClip

			/** @private */
			public var containerToPaint:DisplayObject

			/** @private */
			protected var containerParent:DisplayObjectContainer

			/** @private */
			public var _visible = true
			/** @private */
			public var x0:Number
			/** @private */
			public var y0:Number
			/** @private */
			public var x1:Number
			/** @private */
			public var y1:Number
			/** @private */
			public var top:Number

			// Events
			/** @private */
		  public static const DEPTHCHANGE:String = "renderableElementDepthChange"

			/**
 			* The fRenderableElement.SHOW constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementShow</code> event.
 			* The event is dispatched when the character is shown via the show() method
 			* 
 			* @eventType renderableElementShow
 			*/
		  public static const SHOW:String = "renderableElementShow"

			/**
 			* The fRenderableElement.HIDE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementHide</code> event.
 			* The event is dispatched when the character is hidden via the hide() method
 			* 
 			* @eventType renderableElementHide
 			*/
		  public static const HIDE:String = "renderableElementHide"


			// Constructor
			/** @private */
			function fRenderableElement(defObj:XML,scene:fScene,libraryMovieClip:DisplayObject,spriteToShowHide:MovieClip):void {
				
				 // Previous
				 super(defObj,scene)
				 
				 // Main container
				 this.containerToPaint = libraryMovieClip
				 if(libraryMovieClip is MovieClip) this.flashClip = (libraryMovieClip as MovieClip)
				 this.container = spriteToShowHide
				 this.containerParent = this.container.parent
				 this.container.fElementId = this.id
				 this.container.fElement = this
					
				 // Lights enabled ?
				 var temp:XMLList = defObj.@receiveLights
			   if(temp.length()==1) this.receiveLights = (temp.toString()=="true")

				 // Shadows enabled ?
				 temp = defObj.@receiveShadows
			   if(temp.length()==1) this.receiveShadows = (temp.toString()=="true")

				 // Projects shadow ?
				 temp = defObj.@castShadows
			   if(temp.length()==1) this.castShadows = (temp.toString()=="true")

				 // Solid ?
				 temp = defObj.@solid
			   if(temp.length()==1) this.solid = (temp.toString()=="true")
			   
			   // Add to all elements
				 scene.addToDepthSort(this)

			}

			/**
			* Makes element visible
			*/
			public function show():void {
				 this._visible = true
			   this.containerParent.addChild(this.container)
				 this.scene.addToDepthSort(this)
				 dispatchEvent(new Event(fRenderableElement.SHOW))
			}
			
			/**
			* Makes element invisible
			*/
			public function hide():void {
				 this._visible = false
			   this.containerParent.removeChild(this.container)
				 this.scene.removeFromDepthSort(this)
				 dispatchEvent(new Event(fRenderableElement.HIDE))
			}

			/**
			* Passes the stardard gotoAndPLay command to the base clip of this element
			*
			* @param where A frame number or frame label
			*/
			public function gotoAndPlay(where:*):void {
				 if(this.flashClip)	this.flashClip.gotoAndPlay(where)
			}

			/**
			* Passes the stardard gotoAndStop command to the base clip of this element
			*
			* @param where A frame number or frame label
			*/
			public function gotoAndStop(where:*):void {
					if(this.flashClip) this.flashClip.gotoAndStop(where)
			}

			/**
			* Calls a function of the base clip
			*
			* @param what Name of the function to call
			*
			* @param param An optional extra parameter to pass to the function
			*/
			public function call(what:String,param:*=null):void {
					if(this.flashClip) this.flashClip[what](param)
			}

			// Mouse management
			/** @private */
			public function disableMouseEvents():void {
				this.container.mouseEnabled = false
			}

			/** @private */
			public function enableMouseEvents():void {
				this.container.mouseEnabled = true
			}

			// Depth management
			/** @private */
			public final function setDepth(d:Number):void {
				 
				 this._depth = d
				 
				 // Reorder all objects ( merda )
				 this.dispatchEvent(new Event(fRenderableElement.DEPTHCHANGE))
				
		  }

			// Initial object position
			/** @private */
			public function place():void {
			}

			// Sets global light
			/** @private */
			public function setGlobalLight(light:fGlobalLight):void {
				 light.addEventListener(fLight.INTENSITYCHANGE,this.processGlobalIntensityChange)
				 light.addEventListener(fLight.RENDER,this.processGlobalIntensityChange)
			}
			
			/** @private */
			public function processGlobalIntensityChange(evt:Event):void {
			}

			// fLight reaches element
			/** @private */
			public function lightIn(light:fLight):void {
			
			   // Hide container
			   this.showLight(light)
			   
			}
			
			// fLight leaves element
			/** @private */
		  public function lightOut(light:fLight):void {
			
			   // Hide container
			   this.hideLight(light)
			   
			}

			// Makes light visible
			/** @private */
			public function showLight(light:fLight):void {
			
			}
			
			// Makes light invisible
			/** @private */
			public function hideLight(light:fLight):void {
			
			
			}
			
			// Render start
			/** @private */
			public function renderStart(light:fLight):void {
			
			
			}
			
			// Render ( draw ) light
			/** @private */
			public function renderLight(light:fLight):void {
			
			
			}
			
			// Tests shadows of other elements upon this element
			/** @private */
			public function testShadow(other:fRenderableElement,x:Number,y:Number,z:Number):Number {
					return fCoverage.NOT_SHADOWED
			}


			// Renders shadows of other elements upon this element
			/** @private */
			public function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			
			}

			/** @private */
			public function renderShadowAlone(light:fLight,other:fRenderableElement):void {
			   
			
			}

			/** @private */
			public function unrenderShadowAlone(light:fLight,other:fRenderableElement):void {
			   
			
			}

			// Ends render
			/** @private */
			public function renderFinish(light:fLight):void {
			
			}

			// Confirm Impact from bullet
			/** @private */
			public function confirmImpact(x:Number,y:Number,z:Number,dx:Number,dy:Number,dz:Number):fPlaneBounds {
				if(this.solid) return new fPlaneBounds()
				else return null
			}

			// Test primary fCollision
			/** @private */
			public function testPrimaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {
				return null
			}

			// Test secondary fCollision
			/** @private */
			public function testSecondaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {
				return null
			}

		}

}
