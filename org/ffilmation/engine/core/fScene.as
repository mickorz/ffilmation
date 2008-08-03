// SCENE

package org.ffilmation.engine.core {

		// Imports
		import flash.xml.*
		import flash.net.*
		import flash.utils.*
		import flash.events.*
		import flash.system.*
		import flash.display.*
		import flash.geom.Point
		import flash.geom.Rectangle	

		import org.ffilmation.utils.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.logicSolvers.coverageSolver.*
		import org.ffilmation.engine.logicSolvers.visibilitySolver.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.*
		
		/**
		* <p>The fScene class provides control over a scene in your application. The API for this object is used to add and remove 
		* elements from the scene after it has been loaded, and managing cameras.</p>
		*
		* <p>Moreover, you can get information on topology, visibility from one point to another, search for paths and other useful
		* methods that will help, for example, in programming AIs that move inside the scene.</p>
		*
		* <p>The data structures contained within this object are populated during initialization by the fSceneInitializer class (which you don't need to understand).</p>
		*
		*/
		public class fScene extends EventDispatcher {
		
			// This counter is used to generate unique scene Ids
			private static var count:Number = 0

		  // Private properties
		  /** @private */
		  internal var engine:fEngine
		 	/** @private */
			internal var _orig_container:Sprite  		  					// Backup reference
		  /** @private */
			internal var top:int
		  /** @private */
			internal var depthSortArr:Array									  	// Array of elements for depth sorting
			/** @private */
			internal var gridWidth:Number												// Grid size in pixels
			/** @private */
			internal var gridDepth:Number
			/** @private */
			internal var gridHeight:Number
			/** @private */
			internal var sortAreas:Array												// zSorting generates this. This array points to contiguous spaces sharing the same zIndex
																													// It is used to find the proper zIndex for a cell
																													
			private var currentCamera:fCamera										// The camera currently in use
			private var currentOccluding:Array = []							// Array of elements currently occluding the camera
			private var _controller:fEngineSceneController = null
			
			/** @private */
			public var IAmBeingRendered:Boolean = false				// If this scene is actually being rendered

		  // Public properties
		  
		  /** 
		  * Every Scene is automatically assigned and ID
		  */
		  public var id:String																

		  /** 
		  * Were this scene is drawn
		  */
		  public var container:Sprite		          						
		  
		  /**
		  * An string indicating the scene's current status
		  */
		  public var stat:String         				 							

		  /**
		  * Indicates if the scene is loaded and ready
		  */
		  public var ready:Boolean
		  
		  /**
		  * Scene width in pixels.
		  */														
			public var width:Number
			
			/**
			* Scene depth in pixels
			*/				
			public var depth:Number
		  
			/**
			* Scene height in pixels
			*/				
			public var height:Number

		  /**
		  * An array of all floors for fast loop access. For "id" access use the .all array
		  */
		  public var floors:Array                 						

		  /**
		  * An array of all walls for fast loop access. For "id" access use the .all array
		  */
		  public var walls:Array                  						

		  /**
		  * An array of all objects for fast loop access. For "id" access use the .all array
		  */
		  public var objects:Array                						

		  /**
		  * An array of all characters for fast loop access. For "id" access use the .all array
		  */
		  public var characters:Array                					

		  /**
		  * An array of all lights for fast loop access. For "id" access use the .all array
		  */
		  public var lights:Array                 						

		  /**
		  * An array of all elements for fast loop access. For "id" access use the .all array
		  */
		  public var everything:Array                 						

		  /**
		  * The global light for this scene. Use this property to change light properties such as intensity and color
		  */
		  public var environmentLight:fGlobalLight  					

		  /**
		  * An array of all elements in this scene, use it with ID Strings
		  */
		  public var all:Array                    						
		  
		  /**
		  * The AI-related method are grouped inside this object, for easier access
		  */
		  public var AI:fAiContainer

			/** @private */
		  public var gridSize:Number           								// Grid size ( in pixels )
			/** @private */
		  public var levelSize:Number          								// Vertical grid size ( along Z axis, in pixels )
			/** @private */
		  public var grid:Array                 						  // The grid
			/** @private */
		  public var viewWidth:Number													// Viewport size
			/** @private */
		  public var viewHeight:Number												// Viewport size
			/** @private */
			public var objectDefinitions:Object								  // The list of object definitions loaded for this scene
			/** @private */
			public var materialDefinitions:Object								// The list of material definitions loaded for this scene
			/** @private */
			public var noiseDefinitions:Object									// The list of noise definitions loaded for this scene
			
			private var renderEngine:fEngineRenderEngine				// The render engine
			

		  // Events

			/**
			* An string describing the process of loading and processing and scene XML definition file.
			* Events dispatched by the scene while loading containg this String as a description of what is happening
			*/
			public static const LOADINGDESCRIPTION:String = "Creating scene"

			/**
 			* The fScene.LOADPROGRESS constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>scenecloadprogress</code> event.
 			* The event is dispatched when the status of the scene changes during scene loading and processing.
 			* A listener to this event can then check the scene's status property to update a progress dialog
 			*
 			*/
		  public static const LOADPROGRESS:String = "scenecloadprogress"

			/**
 			* The fScene.LOADCOMPLETE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>sceneloadcomplete</code> event.
 			* The event is dispatched when the scene finishes loading and processing and is ready to be used
 			*
 			*/
		  public static const LOADCOMPLETE:String = "sceneloadcomplete"
		
			/**
			* Constructor. Don't call directly, use fEngine.createScene() instead
			* 
			*/
			function fScene(engine:fEngine,container:Sprite,retriever:fEngineSceneRetriever,width:Number,height:Number,renderer:fEngineRenderEngine) {
			
			   // Properties
			   this.id = "fScene_"+(fScene.count++)
			   this.engine = engine
			   this._orig_container = container           
			   this.container = container                 
			   this.environmentLight = null     
			   this.gridSize = 64
			   this.levelSize = 64
			   this.top = 0
			   this.stat = "Loading XML"  
 			   this.ready = false
 			   this.viewWidth = width
 			   this.viewHeight = height
			
			   // Internal arrays
			   this.depthSortArr = new Array          
			   this.floors = new Array          
			   this.walls = new Array           
			   this.objects = new Array         
			   this.characters = new Array         
			   this.lights = new Array         
			   this.everything = new Array          
			   this.all = new Array 
			   
			   // AI
			   this.AI = new fAiContainer(this)
			
			   // Render engine
			   this.renderEngine = renderer || (new fFlash9RenderEngine(this,container))
			   this.renderEngine.setViewportSize(width,height)
			   
			   // Start xml retrieve process
			   var initializer:fSceneInitializer = new fSceneInitializer(this,retriever)
			   initializer.start()

			}
			
			// Public methods
			
			/**
			* This Method is called to enable the scene. It will enable all controllers associated to the scene and its
			* elements. The engine no longer calls this method when the scene is shown. Do it manually when needed.
			*
			* A typical use of manual enabling/disabling of scenes is pausing the game or showing a dialog box of any type.
			*
			* @see org.ffilmation.engine.core.fEngine#showScene
			*/
			public function enable():void {
				
				// Enable scene controller
				if(this.controller) this.controller.enable()
				
				// Enable controllers for all elements in the scene
				for(var i:Number=0;i<this.everything.length;i++) if(this.everything[i].controller!=null) this.everything[i].controller.enable()
				
			}
			
			/**
			* This Method is called to disable the scene. It will disable all controllers associated to the scene and its
			* elements. The engine no longer calls this method when the scene is hidden. Do it manually when needed.
			*
			* A typical use of manual enabling/disabling of scenes is pausing the game or showing a dialog box of any type.
			*
			* @see org.ffilmation.engine.core.fEngine#hideScene
			*/
			public function disable():void {
				
				// Disable scene controller
				if(this.controller) this.controller.disable()
				
				// Disable  controllers for all elements in the scene
				for(var i:Number=0;i<this.everything.length;i++) if(this.everything[i].controller!=null) this.everything[i].controller.disable()
				
			}

			/**
			* Assigns a controller to this scene
			* @param controller: any controller class that implements the fEngineSceneController interface
			*/
			public function set controller(controller:fEngineSceneController):void {
				
				if(this._controller!=null) this._controller.disable()
				this._controller = controller
				this._controller.assignScene(this)
				
			}
			
			/**
			* Retrieves controller from this scene
			* @return controller: the class that is currently controlling the fScene
			*/
			public function get controller():fEngineSceneController {
				return this._controller
			}

			/** 
			* This method sets the active camera for this scene. The camera position determines the viewable area of the scene
			*
			* @param camera The camera you want to be active
			*
			*/
			public function setCamera(camera:fCamera):void {
				
					// Stop following old camera
					if(this.currentCamera) {
						this.currentCamera.removeEventListener(fElement.MOVE,this.cameraMoveListener)
						this.currentCamera.removeEventListener(fElement.NEWCELL,this.cameraNewCellListener)
					}
					
					// Follow new camera
					this.currentCamera = camera
					this.currentCamera.addEventListener(fElement.MOVE,this.cameraMoveListener)
					this.currentCamera.addEventListener(fElement.NEWCELL,this.cameraNewCellListener)
					this.followCamera(this.currentCamera)
			}
			
			/**
			* Creates a new camera associated to the scene
			*
			* @return an fCamera object ready to move or make active using the setCamera() method
			*
			*/
			public function createCamera():fCamera {
				
					//Return
					return new fCamera(this)
			}

			/**
			* Creates a new light and adds it to the scene. You won't see the light until you call its
			* render() or moveTo() methods
			*
			* @param idlight: The unique id that will identify the light
			*
			* @param x: Initial x coordinate for the light
			*
			* @param y: Initial x coordinate for the light
			*
			* @param z: Initial x coordinate for the light
			*
			* @param size: Radius of the sphere that identifies the light
			*
			* @param color: An string specifying the color of the light in HTML format, example: #ffeedd
			*
			* @param intensity: Intensity of the light goes from 0 to 100
			*
			* @param decay: From 0 to 100 marks the distance along the lights's radius from where intensity starrts to fade fades. A 0 decay defines a solid light
			*
			* @param bumpMapped: Determines if this light will be rendered with bumpmapping. Please note that for the bumpMapping to work in a given surface,
			* the surface will need a bumpMap definition and bumpMapping must be enabled in the engine's global parameters
			*
			*/
			public function createOmniLight(idlight:String,x:Number,y:Number,z:Number,size:Number,color:String,intensity:Number,decay:Number,bumpMapped:Boolean):fOmniLight {
				
					//Create
					this.addLight(<light id={idlight} type="omni" size={size} x={x} y={y} z={z} color={color} intensity={intensity} decay={decay} bump={bumpMapped}/>)
					
					//Return
					return this.all[idlight]
			}

			/**
			* Removes an omni light from the scene. This is not the same as hiding the light, this removes the element completely from the scene
			*
			* @param light The light to be removed
			*/
			public function removeOmniLight(light:fOmniLight):void {
				
					// Remove from array
					this.lights.splice(this.lights.indexOf(light),1)
					
					// Hide light from elements
			    var cell:fCell = light.cell
		      var nEl:Number = light.nElements
		      for(var i2:Number=0;i2<nEl;i2++) this.renderEngine.lightOut(light.elementsV[i2].obj,light)
		      light.scene = null
		      
		      nEl = this.characters.length
		      for(i2=0;i2<nEl;i2++) this.renderEngine.lightOut(this.characters[i2],light)
		      this.all[light.id] = null
		      
		      // This light may be in some character cache
		      light.removed = true
				
			}

			/** 
			*	Creates a new character an adds it to the scene
			*
			* @param idchar: The unique id that will identify the character
			*
			* @param def: Definition id. Must match a definition in some of the definition XMLs included in the scene
			*
			* @param x: Initial x coordinate for the character
			*
			* @param y: Initial x coordinate for the character
			*
			* @param z: Initial x coordinate for the character
			*
			**/
			public function createCharacter(idchar:String,def:String,x:Number,y:Number,z:Number):fCharacter {
				
					//Create
					this.addCharacter(<character id={idchar} definition={def} x={x} y={y} z={z} />)
					var character:fCharacter = this.all[idchar]
					if(IAmBeingRendered) this.addElementToRenderEngine(character)
					character.updateDepth()

					//Return
					return character
			}

			/**
			* Removes a character from the scene. This is not the same as hiding the character, this removes the element completely from the scene
			*
			* @param char The character to be removed
			*/
			public function removeCharacter(char:fCharacter):void {

					// Remove from arraya
					this.characters.splice(this.lights.indexOf(char),1)
		      this.all[char.id] = null
		      
		      // Hide
		      char.hide()
		      
		      // Remove from render engine
		      this.removeElementFromRenderEngine(char)
		      char.dispose()

			}

			/**
			* This method translates scene 3D coordinates to 2D coordinates relative to the Sprite containing the scene
			* 
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* @param z z-axis coordinate
			*
			* @return A Point in this scene's container Sprite
			*/
			public function translate3DCoordsTo2DCoords(x:Number,y:Number,z:Number):Point {
				 return this.translateCoords(x,y,z)
			}

			/**
			* This method translates scene 3D coordinates to 2D coordinates relative to the Stage
			* 
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* @param z z-axis coordinate
			*
			* @return A Coordinate in the Stage
			*/
			public function translate3DCoordsToStageCoords(x:Number,y:Number,z:Number):Point {
				
				 //Get offset of camera
         var rect:Rectangle = this.container.scrollRect
         
         // Get point
				 var r:Point = this.translateCoords(x,y,z)
				 
				 // Translate
				 r.x-=rect.x
				 r.y-=rect.y
				 
				 return r
			}

			/**
			* This method translates Stage coordinates to scene coordinates. Useful to map mouse events into game events
			*
		  * @example You can call it like
		  *
		  * <listing version="3.0">
      *  function mouseClick(evt:MouseEvent) {
      *    var coords:Point = this.scene.translateStageCoordsTo3DCoords(evt.stageX, evt.stageY)
      *    this.hero.character.teleportTo(coords.x,coords.y, this.hero.character.z)
      *   }
			* </listing>
			*
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* 
			* @return A Point in the scene's coordinate system. Please note that a Z value is not returned as It can't be calculated from a 2D input.
			* The returned x and y correspond to z=0 in the game's coordinate system.
			*/
			public function translateStageCoordsTo3DCoords(x:Number,y:Number):Point {
         
         //get offset of camera
         var rect:Rectangle = this.container.scrollRect
         var xx:Number = x+rect.x
         var yy:Number = y+rect.y
         
         //rotate the coordinates
         var yCart:Number = (xx/Math.cos(0.46365)+(yy)/Math.sin(0.46365))/2
         var xCart:Number = (-1*(yy)/Math.sin(0.46365)+xx/Math.cos(0.46365))/2         
         
         //scale the coordinates
         xCart = xCart/fEngine.DEFORMATION
         yCart = yCart/fEngine.DEFORMATION
         
         return new Point(xCart,yCart)
      }         

			/**
			* This method returns the element under a Stage coordinate, and a 3D translation of the 2D coordinates passed as input.
			* To achieve this it finds which visible elements are under the input pixel, ignoring the engine's internal coordinates.
			* Now you can find out what did you click and which point of that element did you click.
			*
			* @param x Stage horizontal coordinate
			* @param y Stage vertical coordinate
			* 
			* @return An array of objects storing both the element under that point and a 3d coordinate corresponding to the 2d Point. This method returns null
			* if the coordinate is not occupied by any element.
			* Why an Array an not a single element ? Because you may want to search the Array for the element that better suits your intentions: for
			* example if you use it to walk around the scene, you will want to ignore trees to reach the floor behind. If you are shooting
			* people, you will want to ignore floors and look for objects and characters to target at.
			*
			* @see org.ffilmation.engine.datatypes.fCoordinateOccupant
			*/
			public function translateStageCoordsToElements(x:Number,y:Number):Array {
				
				// This must be passed to the renderer because we have no idea how things are drawn
				if(IAmBeingRendered) return this.renderEngine.translateStageCoordsToElements(x,y)
				else return null
		
			}

			/**
			* Use this method to completely rerender the scene. However, under normal circunstances there shouldn't be a need to call this manually
			*/
			public function render():void {

			   // Render global light
			   this.environmentLight.render()

			   // Render dynamic lights
			   for(var i:Number=0;i<this.lights.length;i++) this.lights[i].render()

			}
			
			/**
			* <p>Normally you don't need to call this method manually. When an scene is shown, this method is called to initialize the render engine
			* for this scene ( this involves creating all the Sprites ). This may take a couple of seconds.</p>
			* <p>Under special circunstances, however, you may want to call this method manually at some point before showing the scene. This is useful is you want
			* the graphic assets to exist before the scene is shown ( to attach Mouse Events for example ).</p>
			*/
			public function startRendering() {
				
				 if(IAmBeingRendered) return
		   	 
			   // Init render engine
			   this.renderEngine.initialize()
			   
			   // Init render for all elements
			   for(var j:Number=0;j<this.floors.length;j++) addElementToRenderEngine(this.floors[j])
			   for(j=0;j<this.walls.length;j++) addElementToRenderEngine(this.walls[j])
			   for(j=0;j<this.objects.length;j++) addElementToRenderEngine(this.objects[j])
			   for(j=0;j<this.characters.length;j++) addElementToRenderEngine(this.characters[j])
		   	 
			   // Set flag
			   IAmBeingRendered = true

		   	 // Now sprites can be sorted
			   this.depthSort()

		   	 // Render scene
		   	 this.render()
			   
			}

			// PRIVATE AND INTERNAL METHODS FOLLOW

			/**
			* This method adds an element to the renderEngine poll
			*/
			private function addElementToRenderEngine(element:fRenderableElement) {
			
				 // Init
				 element.container = this.renderEngine.initRenderFor(element)
				 
				 // This happens only if the render Engine returns a container for every element. 
				 if(element.container) {
				 	element.container.fElementId = element.id
				 	element.container.fElement = element
				 }
				 
				 // This can be null, depending on the render engine
				 element.flashClip = this.renderEngine.getAssetFor(element)
				 
				 // Listen to show and hide events
				 element.addEventListener(fRenderableElement.SHOW,this.showListener,false,0,true)
				 element.addEventListener(fRenderableElement.HIDE,this.hideListener,false,0,true)
				 element.addEventListener(fRenderableElement.ENABLE,this.enableListener,false,0,true)
				 element.addEventListener(fRenderableElement.DISABLE,this.disableListener,false,0,true)
				 
				 // Elements default to Mouse-disabled
				 element.disableMouseEvents()
				 
			}

			/**
			* This method removes an element from the renderEngine poll
			*/
			private function removeElementFromRenderEngine(element:fRenderableElement) {
			
				 this.renderEngine.stopRenderFor(element)
				 
				 // Stop listening to show and hide events
				 element.removeEventListener(fRenderableElement.SHOW,this.showListener)
				 element.removeEventListener(fRenderableElement.HIDE,this.hideListener)
				 element.removeEventListener(fRenderableElement.ENABLE,this.enableListener)
				 element.removeEventListener(fRenderableElement.DISABLE,this.disableListener)
				 
			}


			// Listens to elements made visible
			private function showListener(evt:Event):void {
			   if(IAmBeingRendered) this.renderEngine.showElement(evt.target as fRenderableElement)
			}
			
			// Listens to elements made invisible
			private function hideListener(evt:Event):void {
			   if(IAmBeingRendered) this.renderEngine.hideElement(evt.target as fRenderableElement)
			}

			// Listens to elements made visible
			private function enableListener(evt:Event):void {
			   this.renderEngine.enableElement(evt.target as fRenderableElement)
			}
			
			// Listens to elements made invisible
			private function disableListener(evt:Event):void {
			   this.renderEngine.disableElement(evt.target as fRenderableElement)
			}

			/*
			* @private
			* This method is called when the scene is no longer displayed.
			*/
			public function stopRendering() {
		   	 
			   // Stop render engine
			   this.renderEngine.dispose()
			   
			   // Set flag
			   IAmBeingRendered = false
			   
			}

			/**
			* @private
			* This method frees all resources allocated by this scene. Always clean unused scene objects:
			* scenes generate lots of internal Arrays and BitmapDatas that will eat your RAM fast if they are not properly deleted
			*/
			public function dispose():void {
				
		  	// Free properties
		  	this.engine = null
				for(var i:Number=0;i<this.depthSortArr.length;i++) delete this.depthSortArr[i]
				this.depthSortArr = null
				for(i=0;i<this.sortAreas.length;i++) delete this.sortAreas[i]
				this.sortAreas = null
				for(i=0;i<this.currentOccluding.length;i++) delete this.currentOccluding[i]
				this.currentOccluding = null
				for(i=0;i<this.objectDefinitions.length;i++) delete this.objectDefinitions[i]
				this.objectDefinitions = null
				for(i=0;i<this.materialDefinitions.length;i++) delete this.materialDefinitions[i]
				this.materialDefinitions = null
				for(i=0;i<this.noiseDefinitions.length;i++) delete this.noiseDefinitions[i]
				this.noiseDefinitions = null
				this.currentCamera.dispose()
				this.currentCamera = null
				this._controller = null
				
				this.renderEngine.dispose()
				
				if(this._orig_container.parent) this._orig_container.parent.removeChild(this._orig_container)
				this._orig_container = null
				this.container = null

				// Free elements
		  	for(i=0;i<this.floors.length;i++) {
		  		this.floors[i].dispose()
		  		delete this.floors[i]
		  	}
		  	for(i=0;i<this.walls.length;i++) {
		  		this.walls[i].dispose()
		  		delete this.walls[i]
		  	}
		  	for(i=0;i<this.objects.length;i++) {
		  		this.objects[i].dispose()
		  		delete this.objects[i]
		  	}
		  	for(i=0;i<this.characters.length;i++) {
		  		this.characters[i].dispose()
		  		delete this.characters[i]
		  	}
		  	for(i=0;i<this.lights.length;i++) {
		  		this.lights[i].dispose()
		  		delete this.lights[i]
		  	}
				for(var n in this.all) delete this.all[n]
				
				// Free grid
				for(i=0;i<this.gridWidth;i++) {  
					for(var j:int=0;j<this.gridDepth;j++) {  
		      	 for(var k:int=0;k<this.gridHeight;k++) {  
			         try {
			         		this.grid[i][j][k].dispose()
			         		delete this.grid[i][j][k]
			         } catch (e:Error) {
			         	
			         }
			       }
			    } 
			  }
				this.grid = null
				
			}
			
			// This method is called when the shadowQuality option changes
			/** @private */
		  public function resetShadows():void {
		  	this.renderEngine.resetShadows()
		  	for(var i:Number=0;i<this.lights.length;i++) this.processNewCellOmniLight(this.lights[i])
		  }
			
			// Listens cameras moving
			private function cameraMoveListener(evt:fMoveEvent):void {
					this.followCamera(evt.target as fCamera)
			}

			// Listens cameras changing cells. Applies camera occlusion
			private function cameraNewCellListener(evt:Event):void {
				
					var camera:fCamera = evt.target as fCamera
					if(camera.occlusion>=100 && camera.cell) return
					
					// Change alphas
					var newAlpha:Number = camera.occlusion/100
					var oldOccluding:Array = this.currentOccluding
					var newOccluding:Array = camera.cell.elementsInFront
					
					for(var i:Number=0;i<oldOccluding.length;i++) {
						oldOccluding[i].container.blendMode = BlendMode.NORMAL
						oldOccluding[i].container.alpha = 1
						
						// Restore Mouse Events
						oldOccluding[i].enableMouseEvents()
					}
					for(i=0;i<newOccluding.length;i++) {
						if(newOccluding[i] is fPlane) newOccluding[i].container.blendMode = camera.planeOcclusionMode
						else newOccluding[i].container.blendMode = camera.objectOcclusionMode
						newOccluding[i].container.alpha = newAlpha
						
						// This will allow you to click elements behind the occluded element
						newOccluding[i].disableMouseEvents()
					}
					
					this.currentOccluding = newOccluding
				
			}

			// Adjusts visualization to camera position
			private function followCamera(camera:fCamera):void {				
					this.renderEngine.setCameraPosition(camera)
			}

			// Depth sorting
			/** @private */
			public function addToDepthSort(item:fRenderableElement):void {				

				if(this.depthSortArr.indexOf(item)<0) {
				 	this.depthSortArr.push(item)
			   	item.addEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener,false,0,true)
			  }
			
			}

			/** @private */
			public function removeFromDepthSort(item:fRenderableElement):void {				

				 this.depthSortArr.splice(this.depthSortArr.indexOf(item),1)
			   item.removeEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener)
			
			}

			// Listens to renderableitems changing its depth
			/** @private */
			public function depthChangeListener(evt:Event):void {
				
				//Element
				if(!this.IAmBeingRendered) return
				
				var el:fRenderableElement = evt.target as fRenderableElement
				var oldD:Number = el.depthOrder
				this.depthSortArr.sortOn("_depth", Array.NUMERIC);
				var newD:Number = this.depthSortArr.indexOf(el)
				if(newD!=oldD) {
					el.depthOrder = newD
					this.container.setChildIndex(el.container, newD)
				}
				
			}
			
		  // Initial depth sorting
			private function depthSort():void {
				
				var ar:Array = this.depthSortArr
				ar.sortOn("_depth", Array.NUMERIC);
    		var i:Number = ar.length;
    		var p:Sprite = this.container
    		
    		while(i--) {
        	p.setChildIndex(ar[i].container, i)
        	ar[i].depthOrder = i
        }
				
			}

			// Reset cell. This is called if the engine's quality options change to a better quality
			// as all cell info will have to be recalculated
			/** @private */
			public function resetGrid():void {

				for(var i:int=0;i<this.gridWidth;i++) {  

					for(var j:int=0;j<=this.gridDepth;j++) {  

		      	 for(var k:int=0;k<=this.gridHeight;k++) {  
			
			         try {
			         		this.grid[i][j][k].characterShadowCache = new Array
			         		delete this.grid[i][j][k].visibleObjs
			         } catch (e:Error) {
			         	
			         }
			   
			       }
		
			    } 
			  }
				
			}

			// Element enters new cell
			/** @private */
			public function processNewCell(evt:Event):void {

				if(evt.target is fOmniLight) this.processNewCellOmniLight(evt.target as fOmniLight)
				if(evt.target is fCharacter) this.processNewCellCharacter(evt.target as fCharacter)
				
			}

			// Process New cell for Omni lights
			private function processNewCellOmniLight(light:fOmniLight):void {
			
			   // Init
			   var cell:fCell = light.cell
			   var x:Number, y:Number,z:Number
		     var nEl:Number = light.nElements
				 var tempElements:Array

				 try {
			    x = cell.x
			    y = cell.y
			    z = cell.z
			   } catch (e:Error) {
			    x = light.x
			    y = light.y
			    z = light.z
			   }

		     // Hide light from elements no longer within range
		     for(var i2:Number=0;i2<nEl;i2++) this.renderEngine.lightOut(light.elementsV[i2].obj,light)

			   if(cell==null) {
			      // fLight outside grid
			      light.elementsV = fVisibilitySolver.calcVisiblesCoords(this,light.x,light.y,light.z)
			      tempElements = light.elementsV
			      
			   } 
			   else {
			      // fLight enters new cell
			      if(!light.cell.visibleObjs || light.cell.visibleRange<light.size) this.calcVisibles(light.cell,light.size)
			      light.elementsV = light.cell.visibleObjs
			      tempElements = light.elementsV
			   }
			   
			   // Count elements close enough
			   var nElements:Number
	   	   var ele:fShadowedVisibilityInfo
			   var shadowArray:Array
			   var shLength:Number

			   nEl = tempElements.length
			   for(nElements=0;nElements<nEl && tempElements[nElements].distance<light.size;nElements++);
			   light.nElements = nElements

			   for(i2=0;i2<nElements;i2++) {
			   	  
			   	  ele = tempElements[i2]
			      if(ele.distance<light.size) this.renderEngine.lightIn(ele.obj,light)
			      
			      // Calculate how many shadow containers are within range
			      
			      shadowArray = ele.shadows
			      shLength = shadowArray.length
			      
			      for(var var2:Number=0;var2<shLength && shadowArray[var2].distance<light.size;var2++);
			      tempElements[i2].withinRange = var2
			   }

				 // Characters			   
			   var chLength:Number = this.characters.length
			   var character:fCharacter
				 var cache:fCharacterShadowCache
				 var el:fRenderableElement
				 
			   for(i2=0;i2<chLength;i2++) {
			   	
			   		character = this.characters[i2]
			   		
				   	// Shadow info already exists ?
				   	try {
				   		 cache = character.cell.characterShadowCache[light.counter]||new fCharacterShadowCache(light)
				   	} catch(e:Error) {
				   		 cache = new fCharacterShadowCache(light)
				   	}

			   		// Is character within range ?
			   		if(character.distanceTo(x,y,z)<light.size) {
			   			
			   			 cache.withinRange = true
			   			 
				   		 if(cache.character==character && cache.cell==light.cell) {
				   		 	
				   		 	  // Cache is still valid, no need to update
				   		 	
				   		 } else {
				   		 	
				   		 	  // Cache is outdated. Update it
				   		 	  cache.clear()
				   		 	  cache.cell = light.cell
				   		 	  cache.character = character
				   		 	  
				   		 	  if(fEngine.characterShadows) { 
				   		 	    
				   		 	  	for(var i:Number=0;i<nElements;i++) {
				   		 	  			el = tempElements[i].obj
               	  	
				   	   	  			// Shadows of this character upon other elements
				   		 	  		  if(fCoverageSolver.calculateCoverage(character,el,x,y,z) == fCoverage.SHADOWED) {
				   		 	  		  	cache.addElement(el)
				   		 	  		  }
               	  	
				   	   	  		  // Shadows of other elements upon this character
					   	 	  		  //if(fCoverageSolver.calculateCoverage(el,character,x,y,z) == fCoverage.SHADOWED) character.renderShadow(light,el)
				   		 	  	}
               	  
			   			 	  } 

			   		  }

			   		} else {
			   			
			   			cache.withinRange = false
			   			cache.clear()
			   			
			   		  // Remove light
			   		  this.renderEngine.lightOut(character,light)
			   		  
			   		}

			   	  // Update cache
			   	  character.vLights[light.counter] = light.vCharacters[character.counter] = cache
			   	  if(character.cell) character.cell.characterShadowCache[light.counter] = cache

			   }

			}

			// Process New cell for Characters
			private function processNewCellCharacter(character:fCharacter):void {
			
				 // Init
				 var light:fOmniLight, elements:Array, nEl:Number, distL:Number, range:Number,x:Number, y:Number, z:Number
				 var cache:fCharacterShadowCache, oldCache:fCharacterShadowCache, elementsV:Array, el:fPlane
				 var s:Number, len:Number,i:Number,i2:Number

		 		 // Change depth of object
		 		 if(character.cell!=null) character.setDepth(character.cell.zIndex)
		 		 
			   // Count lights close enough
			   for(i2=0;i2<this.lights.length;i2++) {
			   	
			   		light = this.lights[i2]
			   		
				   	// Shadow info already already exists ?
				   	try {
				   		 cache = character.cell.characterShadowCache[light.counter]||new fCharacterShadowCache(light)
				   	} catch(e:Error) {
				   		 cache = new fCharacterShadowCache(light)
				   	}
				   	
			   		// Range
			   		distL = light.distanceTo(character.x,character.y,character.z)
			   		range = character.shadowRange
			   		
			   		// Is character within range ?
			   		if(distL<light.size) {
			   			
			   			cache.withinRange = true
			   			
			   			if(light.cell) {
			   				x = light.cell.x
			        	y = light.cell.y
			        	z = light.cell.z
			        } else {
			   				x = light.x
			        	y = light.y
			        	z = light.z
			        }
			   			
							if(cache.character==character && cache.cell==light.cell) {
				   		 	
				   		 	  // Cache is still valid, no need to update
				   		 	
				   		} else {
				   			
				   			 
				   			  // Cache is outdated. Update it
				   		 	  cache.clear()
				   		 	  cache.cell = light.cell
				   		 	  cache.character = character

				   		    if(fEngine.characterShadows) {
                  
							    	// Add visibles from foot
							    	if(!character.cell.visibleObjs || character.cell.visibleRange<range) {
							    		this.calcVisibles(character.cell,range)
							    	}
			            	elementsV = character.cell.visibleObjs
				   		    	nEl = elementsV.length
				   		    	for(i=0;i<nEl && elementsV[i].distance<range;i++) {
                  	
				   		    			try {
				   		    				el = elementsV[i].obj
				   	      				// Shadows of this character upon other elements
				   	      			 	if(fCoverageSolver.calculateCoverage(character,el,x,y,z) == fCoverage.SHADOWED) cache.addElement(el)
				   	      			} catch(e:Error) {
				   	      			}
                  	
				   		    	}
				   		    	
							    	// Add visibles from top
							    	try {
							    		var topCell:fCell = this.translateToCell(character.x,character.y,character.top)
							    		if(!topCell.visibleObjs  || topCell.visibleRange<range) {
							    			this.calcVisibles(topCell,range)
							    		}
			            		elementsV = topCell.visibleObjs
				   		    		nEl = elementsV.length
				   		    		for(i=0;i<nEl && elementsV[i].distance<range;i++) {
                  		
				   		    				try {
				   		    					el = elementsV[i].obj
				   	      					// Shadows of this character upon other elements
				   	      				 	if(fCoverageSolver.calculateCoverage(el,character,x,y,z) == fCoverage.SHADOWED) cache.addElement(el)
				   	      				} catch(e:Error) {
				   	      				}
                  		
				   		    		}
				   		      } catch(e:Error) {
				   		      	
				   		      }
                  
						      }
						      
						  }
			   			
			   		} else {
			   		
			   			cache.withinRange = false
			   			cache.clear()
			   		  
 			   		  // And remove light
			   		  this.renderEngine.lightOut(character,light)
			   		  
			   		}

	  				// Delete shadows from this character that are no longer visible
			   		oldCache = character.vLights[light.counter]
			   		if(oldCache!=null) {
						 	elements = oldCache.elements
						 	nEl = elements.length
		   	 		 	for(var i3:Number=0;i3<nEl;i3++) {
			   					if(cache.elements.indexOf(elements[i3])<0) {
			   						this.renderEngine.removeShadow(elements[i3],light,character)
			   					}
		   	 			}
		   	 		}
			   	  
			   	  // Update cache
			   	  character.vLights[light.counter] = light.vCharacters[character.counter] = character.cell.characterShadowCache[light.counter] = cache

			   }
			   
			   
			   
			   
			}

			// Light render method
			/** @private */
			public function renderElement(evt:Event):void {
				
			   // If the scene is not being displayed, we don't update the render engine
			   // However, the element's properties are modified. When the scene is shown the result is consistent
			   // to what has changed while the render was not being updated
			   if(IAmBeingRendered) {
			   	if(evt.target is fOmniLight) this.renderOmniLight(evt.target as fOmniLight)
				 	if(evt.target is fCharacter) this.renderCharacter(evt.target as fCharacter)
				 }
				
			}

			// Main render method for omni lights
			private function renderOmniLight(light:fOmniLight):void {
			
			   // Step 1: Init
			   var x:Number = light.x, y:Number = light.y, z:Number = light.z, nElements:Number = light.nElements, tempElements:Array = light.elementsV, el:fRenderableElement,others:Array,withinRange:Number
			   
			   // Step 2: render Start
				 for(var i2:Number=0;i2<nElements;i2++) this.renderEngine.renderStart(tempElements[i2].obj,light)
		
			   // Step 3: render light and shadows 
				 for(i2=0;i2<nElements;i2++) {
				    el = tempElements[i2].obj
				    others = tempElements[i2].shadows
				    withinRange = tempElements[i2].withinRange
				    this.renderEngine.renderLight(el,light)
			    
				    // Shadow from statics
				    for(var i3:Number=0;i3<withinRange;i3++) {
				    	try {
				    		if(others[i3].obj._visible) this.renderEngine.renderShadow(el,light,others[i3].obj)
				    	} catch(e:Error) {
				    		trace(e)
				    	}
				    }
				    
				    
				 }

			   // Step 4: Render characters
			   var character:fCharacter, elements:Array, idChar:Number,len:Number, cache:fCharacterShadowCache           
         
         len = light.vCharacters.length
			   for(idChar=0;idChar<len;idChar++) {
			   	  cache = light.vCharacters[idChar]
			   	  if(cache.withinRange) {
			   	  	character = cache.character
			   	  	elements = cache.elements
			   			this.renderEngine.renderStart(character,light)
			   			this.renderEngine.renderLight(character,light)
			   			this.renderEngine.renderFinish(character,light)
			   		
			   			for(i2=0;i2<elements.length;i2++) {
					    	try {
			   					if(character._visible) this.renderEngine.renderShadow(elements[i2],light,character)
			   				} catch(e:Error) {
			   					
			   		  	}
			   			}
			   		}
			   		
			   }

			   // Step 5: End render
			   for(i2=0;i2<nElements;i2++) this.renderEngine.renderFinish(tempElements[i2].obj,light)

			}

			// Main render method for characters
			private function renderCharacter(character:fCharacter):void {
			
			   var light:fOmniLight, elements:Array, nEl:Number, len:Number, cache:fCharacterShadowCache 
			   
			   // Render all lights and shadows
			   
			   len = character.vLights.length
			   for(var i:Number=0;i<len;i++) {
			   
					 	cache =  character.vLights[i]
					 	if(!cache.light.removed && cache.withinRange) {
					 	
					 		// Start
					 		light = cache.light as fOmniLight
			   		  this.renderEngine.renderStart(character,light)
			   		  this.renderEngine.renderLight(character,light)
			    		
			    		// Update shadows for this character
			    		elements = cache.elements
			    		nEl = elements.length
		   	 		  if(fEngine.characterShadows) for(var i2:Number=0;i2<nEl;i2++) {
		   	 		  	try {
			    				this.renderEngine.updateShadow(elements[i2],light,character)
			    			} catch(e:Error) {
			    			
			    			}
			    			
			    		}

							// End
			   		  this.renderEngine.renderFinish(character,light)
			   		  
			   	  }
			   
			   }

			}

			/** @private */
			internal function addLight(definitionObject:XML):void {
			
			   // Create
			   var nfLight:fOmniLight = new fOmniLight(definitionObject,this)
			   var temp:Array
			   
			   // Events
				 nfLight.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 nfLight.addEventListener(fElement.MOVE,this.renderElement)			   
				 nfLight.addEventListener(fLight.RENDER,this.processNewCell)			   
				 nfLight.addEventListener(fLight.RENDER,this.renderElement)			   
			
			   // Add to lists
			   nfLight.counter = this.lights.length
			   this.lights.push(nfLight)
			   this.everything.push(nfLight)
			   this.all[nfLight.id] = nfLight
			     
			}

			/** @private */
			internal function addCharacter(definitionObject:XML):void {
			
				 // Create
			   var nCharacter:fCharacter = new fCharacter(definitionObject,this)
			   
			   // Events
				 nCharacter.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 nCharacter.addEventListener(fElement.MOVE,this.renderElement)			   

			   // Add to lists
 			   nCharacter.counter = this.characters.length
			   this.characters.push(nCharacter)
			   this.everything.push(nCharacter)
			   this.all[nCharacter.id] = nCharacter
			
			}

			// Returns the cell containing the given coordinates
			/** @private */
			public function translateToCell(x:Number,y:Number,z:Number):fCell {
				 return this.getCellAt(Math.floor(x/this.gridSize),Math.floor(y/this.gridSize),Math.floor(z/this.levelSize))
			}
			
			// Returns the cell at specific grid coordinates. If cell does not exist, it is created.
			/** @private */
			public function getCellAt(i:Number,j:Number,k:Number) {
				
				if(i<0 || j<0 || k<0) return null
				if(i>=this.gridWidth || j>=this.gridDepth || k>=this.gridHeight) return null
				
				// Create new if necessary
				if(!this.grid[i]) this.grid[i] = new Array
				if(!this.grid[i][j]) this.grid[i][j] = new Array
				if(!this.grid[i][j][k]) {
					
					var cell:fCell = new fCell()

			    // Z-Index
			    cell.zIndex = this.computeZIndex(i,j,k)
			    var s:Array = this.sortAreas[i]
			    var l:Number = s.length
			    
			    var found:Boolean = false
			    for(var n:Number=0;!found && n<l;n++) {
			    	if(s[n].isPointInside(i,j,k)) {
			    		found = true
			    		cell.zIndex+=s[n].zValue
			    	}
			  	}
			         
			    // Internal
			    cell.i = i
			    cell.j = j
			    cell.k = k
			    cell.x = (this.gridSize/2)+(this.gridSize*i)
			    cell.y = (this.gridSize/2)+(this.gridSize*j)
			    cell.z = (this.levelSize/2)+(this.levelSize*k)
					this.grid[i][j][k] = cell

				}
				
				// Return cell
				return this.grid[i][j][k]
				
			}

			// Returns a normalized zSort value for a cell in the grid. Bigger values display in front of lower values
			/** @private */
			public function computeZIndex(i:Number,j:Number,k:Number):Number {
				 var ow = this.gridWidth
				 var od = this.gridDepth
				 var oh = this.gridHeight
			   return ((((((ow-i+1)+(j*ow+2)))*oh)+k))/(ow*od*oh)
			}

			/** @private */
			public function translateCoords(x:Number,y:Number,z:Number):Point {
			
				 var xx:Number = x*fEngine.DEFORMATION
				 var yy:Number = y*fEngine.DEFORMATION
				 var zz:Number = z*fEngine.DEFORMATION
				 var xCart:Number = (xx+yy)*Math.cos(0.46365)
				 var yCart:Number = zz+(xx-yy)*Math.sin(0.46365)

				 return new Point(xCart,-yCart)

			}
			
			// Get visible elements from given cell, sorted by distance
			/** @private */
			public function calcVisibles(cell:fCell,range:Number=Infinity):void {
			   var r:Array = fVisibilitySolver.calcVisiblesCoords(this,cell.x,cell.y,cell.z,range)
			   cell.visibleObjs = r
			   cell.visibleRange = range
			}
			

		
		}


}

