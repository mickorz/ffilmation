package org.ffilmation.engine.core {
	
		// Imports
		import org.ffilmation.utils.*
		import org.ffilmation.engine.elements.*

		import flash.geom.*
		import flash.events.*
		import flash.display.*

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

			/** 
			* <p><b>WARNING!!!: </b> This property only exists when the scene is being rendered and the graphic elements have been created. This
			* happens when you call fEngine.showScene(). Trying to access this property before the scene is shown ( to attach a Mouse Event for example )
			* will throw an error.</p>
			*
			* <p>The container is the base DisplayObject that contains everything. If you want to add Mouse Events to your elements, use this
			* property. Camera occlusion will be applied: this means that if this element was occluded to show the camera position,
			* its events are disabled as well so you can click on items behind this element.</p>
			*
			* <p>The container for each element will have two properties:</p>
			* <p>
			* <b>fElementId</b>: The ID for this element<br>
			* <b>fElement</b>: A pointer to the fElement this MovieClip represents<br>
			* </p>
			* <p>These properties will be useful when programming MouseEvents. Using them, you will be able to access the class from an Event
			* listener attached to the container
			*/
			public var container:fElementContainer

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
						
			// These properties are used by the renderManager
			/////////////////////////////////////////////////
			
			/** @private */
			public var _depth:Number = 0

			/** @private */
			public var depthOrder:int
			
			/** @private */
			public var isVisibleNow:Boolean = false

			/** @private */
			public var willBeVisible:Boolean = false
			
			/** @private */
			public var bounds2d:Rectangle = new Rectangle()
			

			// Events
			/** @private */
		  public static const DEPTHCHANGE:String = "renderableElementDepthChange"

			/**
 			* The fRenderableElement.SHOW constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementShow</code> event.
 			* The event is dispatched when the elements is shown via the show() method
 			* 
 			* @eventType renderableElementShow
 			*/
		  public static const SHOW:String = "renderableElementShow"

			/**
 			* The fRenderableElement.HIDE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementHide</code> event.
 			* The event is dispatched when the elements is hidden via the hide() method
 			* 
 			* @eventType renderableElementHide
 			*/
		  public static const HIDE:String = "renderableElementHide"

			/**
			* @private
 			* The fRenderableElement.ENABLE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementEnable</code> event.
 			* The event is dispatched when the elements's Mouse events are enabled
 			* 
 			* @eventType renderableElementEnable
 			*/
		  public static const ENABLE:String = "renderableElementEnable"

			/**
			* @private
 			* The fRenderableElement.DISABLE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>renderableElementDisable</code> event.
 			* The event is dispatched when the elements's Mouse events are disabled
 			* 
 			* @eventType renderableElementDisable
 			*/
		  public static const DISABLE:String = "renderableElementDisable"

			// Constructor
			/** @private */
			function fRenderableElement(defObj:XML,scene:fScene,noDepthSort:Boolean=false):void {
				
				 // Previous
				 super(defObj,scene)
				 
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
			   
			}

			/**
			* Mouse management
			*/
			public function disableMouseEvents():void {
				dispatchEvent(new Event(fRenderableElement.DISABLE))
			}

			/**
			* Mouse management
			*/
			public function enableMouseEvents():void {
				dispatchEvent(new Event(fRenderableElement.ENABLE))
			}

			/**
			* Makes element visible
			*/
			public function show():void {
				 if(!this._visible) {
				 		this._visible = true
				 		dispatchEvent(new Event(fRenderableElement.SHOW))
				 }
			}
			
			/**
			* Makes element invisible
			*/
			public function hide():void {
				 if(this._visible) {
				 		this._visible = false
				 		dispatchEvent(new Event(fRenderableElement.HIDE))
				 }
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


			// Depth management
			/** @private */
			public final function setDepth(d:Number):void {
				 
				 this._depth = d
				 
				 // Reorder all objects
				 this.dispatchEvent(new Event(fRenderableElement.DEPTHCHANGE))
				
		  }
			
			/**
			* Return the 2D distance from this element to any world coordinate
			*/
			public function distance2d(x:Number,y:Number,z:Number):Number {
				var p2d:Point = fScene.translateCoords(x,y,z)
				return this.distance2dScreen(p2d.x,p2d.y)
			}

			/**
			* Return the 2D distance from this element to any screen coordinate
			*/
			public function distance2dScreen(x:Number,y:Number):Number {

				var bounds:Rectangle = this.bounds2d
				var pos2D:Point = new Point(x,y)
				var dist:Number = Infinity
				if(this is fWall) {
					var w:fWall = this as fWall
					var origin:Point = fScene.translateCoords(w.x0,w.y0,w.z)
				} else {
					origin = fScene.translateCoords(this.x,this.y,this.z)
				}
				
				if(bounds.contains(pos2D.x-origin.x,pos2D.y-origin.y)) return 0
				
				var corner1:Point = new Point(origin.x+bounds.x,origin.y+bounds.y)
				var corner2:Point = new Point(origin.x+bounds.x,origin.y+bounds.y+bounds.height)
				var corner3:Point = new Point(origin.x+bounds.x+bounds.width,origin.y+bounds.y+bounds.height)
				var corner4:Point = new Point(origin.x+bounds.x+bounds.width,origin.y+bounds.y)
				
				var d:Number = mathUtils.distancePointToSegment(corner1,corner2,pos2D)
				if(d<dist) dist = d
				d = mathUtils.distancePointToSegment(corner2,corner3,pos2D)
				if(d<dist) dist = d
				d = mathUtils.distancePointToSegment(corner3,corner4,pos2D)
				if(d<dist) dist = d
				d = mathUtils.distancePointToSegment(corner4,corner1,pos2D)
				if(d<dist) dist = d
				
				return dist

			}

			/** @private */
			public function disposeRenderable():void {

				this.flashClip = null
				this.container = null
				this.disposeElement()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposeRenderable()
			}



		}

}
