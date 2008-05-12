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
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.generators.*
		
		/**
		* <p>The fScene class provides control over a scene in your application. The API for this object is used to add and remove 
		* elements from the scene after it has been loaded, and managing cameras.</p>
		*
		* <p>Moreover, you can get information on topology, visibility from one point to another, search for paths and other useful
		* methods that will help, for example, in programming AIs that move inside the scene.</p>
		*/
		public class fScene extends EventDispatcher {
		
			// This counter is used to generate unique scene Ids
			/** @private */
			private static var count:Number = 0

		  // Private properties
		  private var engine:fEngine
		  private var _orig_container:Sprite  		  					// Backup reference
		  private var elements:Sprite													// All elements in scene are added here
		  private var top:int
		  private var depthSortArr:Array									  	// Array of elements for depth sorting
		  public var id:String																// Internal id
		
		  private var levels:Array         	     							// List of all levels
		  private var baseLevel:fLevel
		
			private var gridWidth:Number												// Grid size in pixels
			private var gridHeight:Number
			private var gridThickness:Number

			private var currentCamera:fCamera										// The camera currently in use
			private var currentOccluding:Array = []							// Array of elements currently occluding the camera
			
			// Controller
			private var _controller:fEngineSceneController = null
			
			
			// Temp variables used during the load and init process
			private var mediaSrcs:Array
			private var xmlObj:XML
			private var generators:XMLList
			private var srcs:Array
			private var queuePointer:Number
			private var levelData:Array
			private var maxfLevels:Number
			private var limitHeight:Number
			private var retriever:fEngineSceneRetriever
			private var generator:fEngineGenerator
			/** @private */
			public var currentGenerator:Number

		  // Public properties
		  
		  /** 
		  * Were scene is drawn
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
		  public var maxElementsPerfCell:Number = 3					  // Maximum number of elements per cell ( used to reserve zIndexes )
			/** @private */
			public var objectDefinitions:Object								  // The list of object definitions loaded for this scene
			/** @private */
			public var materialDefinitions:Object								// The list of material definitions loaded for this scene
			/** @private */
			public var noiseDefinitions:Object									// The list of noise definitions loaded for this scene

		  // Events

			/**
			* An string describing the process of loading and processing and scene XML definition file.
			* Events dispatched by the scene while loading containg this String as a description of what is happening
			*/
			private static const LOADINGDESCRIPTION:String = "Creating scene"

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
			function fScene(engine:fEngine,container:Sprite,retriever:fEngineSceneRetriever,width:Number,height:Number) {
			
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
 			   this.container.scrollRect = new Rectangle(0,0,width,height)
 			   this.retriever = retriever
			
			   // Internal arrays
			   this.depthSortArr = new Array          
			   this.levels = new Array          
			   this.floors = new Array          
			   this.walls = new Array           
			   this.objects = new Array         
			   this.characters = new Array         
			   this.lights = new Array         
			   this.everything = new Array          
			   this.all = new Array 
			   
			   // Force generator classes to be included in the compiled SWF. I know there must be a nicer way to achieve this...
			   var sc:fScatterGenerator
			   
			   // AI
			   this.AI = new fAiContainer(this)
			
			   // Start xml retrieve process
				 this.retriever.start().addEventListener(Event.COMPLETE, this.loadListener)
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.stat))

			}
			
			// Public methods
			
			/**
			* This Method is called to enable the scene. It will enable all controllers associated to the scene and its
			* elements. The engine calls this method when the scene is shown, but you can call it manually too.
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
			* elements. The engine calls this method when the scene is hidden, but you can call it manually too.
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
		      for(var i2:Number=0;i2<nEl;i2++) light.elementsV[i2].obj.lightOut(light)
		      light.scene = null
		      
		      nEl = this.characters.length
		      for(i2=0;i2<nEl;i2++) this.characters[i2].lightOut(light)
		      this.all[idlight] = null
				
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
					this.environmentLight.render()

					//Return
					return this.all[idchar]
			}

			/**
			* Removes a character from the scene. This is not the same as hiding the character, this removes the element completely from the scene
			*
			* @param char The character to be removed
			*/
			public function removeCharacter(char:fCharacter):void {
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




			// LOAD: Scene xml load event
			private function loadListener(evt:Event):void {
        this.xmlObj = this.retriever.getXML()
        this.processXml_Init()
			}

		  // Process HEAD of scene's XML
			private function processXml_Init():void {
				
			   // Step 1: Retrieve media files
				 this.mediaSrcs = new Array
			   var srcs:XMLList = this.xmlObj.head.child("media")

			   for(var i:Number=0;i<srcs.length();i++) this.mediaSrcs.push(srcs[i].@src)
			   
				 // Step 2: Retrieve definition files and start loading them
				 this.objectDefinitions = new Object()
				 this.materialDefinitions = new Object()
				 this.noiseDefinitions = new Object()
				 this.srcs = new Array()
			   
			   srcs = this.xmlObj.head.child("definitions")
			   for(i=0;i<srcs.length();i++) this.srcs.push(srcs[i].@src)
			   
			   this.queuePointer = -1
			   this.stat = "Loading definition files"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.stat))
			   this.XMLloadComplete(new Event("Dummy"))

		  }
		  
			// Process loaded definition xml
			private function XMLloadComplete(evt:Event):void {
			
				 // Process loaded file
				 if(this.queuePointer>=0) {
				 	
				 		var xmlObj2:XML = new XML(evt.target.data)
				 		
				 		// Retrieve nested definitions
						for(var i:Number=0;i<xmlObj2.child("definitions").length();i++) if(this.srcs.indexOf(xmlObj2.child("definitions")[i].@src)<0) this.srcs.push(xmlObj2.child("definitions")[i].@src)
				 		
				 		// Retrieve media files
						for(i=0;i<xmlObj2.child("media").length();i++) this.mediaSrcs.push(xmlObj2.child("media")[i].@src)				 	
						
						// Retrieve Object definitions
						var defs:XMLList = xmlObj2.child("objectDefinition")
						for(i=0;i<defs.length();i++) {
							this.objectDefinitions[defs[i].@name] = defs[i].copy()
						}
						
						// Retrieve Material definitions
						defs = xmlObj2.child("materialDefinition")
						for(i=0;i<defs.length();i++) {
							this.materialDefinitions[defs[i].@name] = defs[i].copy()
						}
						
						// Retrieve Noise definitions
						defs = xmlObj2.child("noiseDefinition")
						for(i=0;i<defs.length();i++) {
							this.noiseDefinitions[defs[i].@name] = new fNoise(defs[i])
						}

				 }
				 
				 // Proceed to next file
				 this.queuePointer++
				 if(this.queuePointer<this.srcs.length) {
				 	
				 	  // Load
				 		var url:URLRequest = new URLRequest(this.srcs[this.queuePointer])
				 		var loadUrl:URLLoader = new URLLoader(url)
				 		loadUrl.load(url)
				 		loadUrl.addEventListener(Event.COMPLETE, this.XMLloadComplete)
			   		this.stat = "Loading definition file: "+this.srcs[this.queuePointer]
			   		this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.stat))
						
				 } else {

				 		// All loaded
	          this.processXml_Part1()
				 }

			}
		  
			// Start loading media files
			private function processXml_Part1():void {

			   // Read media files
			   this.queuePointer = -1
			   this.stat = "Loading media files"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.stat))

				 // Listen to media load events
				 this.engine.addEventListener(fEngine.MEDIALOADCOMPLETE,this.loadComplete)
				 this.engine.addEventListener(fEngine.MEDIALOADPROGRESS,this.loadProgress)
			   this.loadComplete(new Event("Dummy"))

			}
			
			// Process loaded media file and load next one
			private function loadComplete(event:Event):void {
			
				 this.queuePointer++
				 if(this.queuePointer<this.mediaSrcs.length) {
				 	
				 	  // Load
				 		var src:String = this.mediaSrcs[this.queuePointer]
			  	  this.stat = "Loading media files ( current: "+src+"  ) "
			      var current:Number = 100*(this.queuePointer)/this.srcs.length
			   		this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,current/2,fScene.LOADINGDESCRIPTION,current,this.stat))

						this.engine.loadMedia(src)
						
				 } else {
				 		// All loaded
			  	  this.stat = "Load complete. Processing scene data."
			   	  this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,33,this.stat))
			   		var myTimer:Timer = new Timer(200, 1)
            myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_DecompileT)
            myTimer.start()
				 }

			}
			
	    // Update status of current media file
			private function loadProgress(event:ProgressEvent):void {

			   var percent:Number = (event.bytesLoaded/event.bytesTotal)
			   this.stat = "Loading media files ( current: "+this.mediaSrcs[this.queuePointer]+"  ) "
			   var current:Number = 100*(this.queuePointer+percent)/this.mediaSrcs.length
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,current/2,fScene.LOADINGDESCRIPTION,current,this.stat))
			   
			}
			
			private function processXml_DecompileT(event:TimerEvent):void {
				 this.processXml_Decompile()
		  }

			// Decompile BOX and GENERATOR Tags
			private function processXml_Decompile():void {
				
				 // Remove listeners. Otherwise we would react to other scene's load calls
				 this.engine.removeEventListener(fEngine.MEDIALOADCOMPLETE,this.loadComplete)
				 this.engine.removeEventListener(fEngine.MEDIALOADPROGRESS,this.loadProgress)
				 
				 // Create elements
				 this.elements = new Sprite()
				 this.elements.mouseEnabled = false
				 this.container.addChild(this.elements)
			
			   // Setup environment
			   if(this.xmlObj.@gridsize.length()>0) this.gridSize = new Number(this.xmlObj.@gridsize)
			   if(this.xmlObj.@levelsize.length()>0) this.levelSize = new Number(this.xmlObj.@levelsize)
			   if(this.xmlObj.@maxelementspercell.length()>0) this.maxElementsPerfCell = new Number(this.xmlObj.@maxelementspercell)
			
			   // Setup environment light, if any
			   this.environmentLight = new fGlobalLight(this.xmlObj.head.child("light")[0],this)
			   
				 // Search for BOX tags and decompile into walls and floors
				 var tempObj:XMLList = this.xmlObj.body.child("box")
			   for(var i:Number=0;i<tempObj.length();i++) {
			   	 var box:XML = tempObj[i]
			   	 if(box.@src1.length()>0) this.xmlObj.body.appendChild('<wall id="'+(box.@id+"_side1")+'" src="'+(box.@src1)+'" size="'+(box.@sizex)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="horizontal"/>')
			   	 if(box.@src2.length()>0) this.xmlObj.body.appendChild('<wall id="'+(box.@id+"_side2")+'" src="'+(box.@src2)+'" size="'+(box.@sizey)+'" height="'+(box.@sizez)+'" x="'+(parseInt(box.@x)+parseInt(box.@sizex))+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="vertical"/>')
			   	 if(box.@src3.length()>0) this.xmlObj.body.appendChild('<wall id="'+(box.@id+"_side3")+'" src="'+(box.@src3)+'" size="'+(box.@sizex)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(parseInt(box.@y)+parseInt(box.@sizey))+'" z="'+(box.@z)+'" direction="horizontal"/>')
			   	 if(box.@src4.length()>0) this.xmlObj.body.appendChild('<wall id="'+(box.@id+"_side4")+'" src="'+(box.@src4)+'" size="'+(box.@sizey)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="vertical"/>')
			   	 if(box.@src5.length()>0) this.xmlObj.body.appendChild('<floor id="'+(box.@id+"_side5")+'" src="'+(box.@src5)+'" width="'+(box.@sizex)+'" height="'+(box.@sizey)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(parseInt(box.@z)+parseInt(box.@sizez))+'"/>')
			   	 if(box.@src6.length()>0) this.xmlObj.body.appendChild('<floor id="'+(box.@id+"_side6")+'" src="'+(box.@src6)+'" width="'+(box.@sizex)+'" height="'+(box.@sizey)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(parseInt(box.@z))+'"/>')
				 }
				 
				 // Search for GENERATOR Tags and process
				 this.generators = this.xmlObj.body.child("generator")
				 this.currentGenerator = 0
				 
				 if(this.generators.length()>0) {
				 		processGenerator()
         } else {
         		processGeometry()
         }
			}
			
			
			// Process Generator start
			private function processGenerator():void {
				
				try {
	   			var cls:String = this.generators[this.currentGenerator].classname
	   			var data:XMLList = this.generators[this.currentGenerator].data
	   			var r:Class = getDefinitionByName(cls) as Class
			   	this.generator = new r()

			   	var ret:EventDispatcher = this.generator.generate(this.currentGenerator,this,data)
			   	ret.addEventListener(ProgressEvent.PROGRESS, this.onGeneratorProgress)
			   	ret.addEventListener(Event.COMPLETE, this.onGeneratorComplete)

					this.stat = "Processing generator "+(this.currentGenerator+1)+" of "+this.generators.length()
			   	this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,0,this.stat))

	   		} catch (e:Error) {
	   			throw new Error("Filmation Engine Exception: Scene contains an invalid generator definition: "+cls+" "+e)
	   		}
				 
			}
			
			// Process Generator progress
			private function onGeneratorProgress(evt:Event):void {

					this.stat = "Processing generator "+(this.currentGenerator+1)+" of "+this.generators.length()
			   	this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,this.generator.getPercent(),this.stat))
				
			}
			
			// Process Generator complete
			private function onGeneratorComplete(evt:Event):void {
				
	   			// Insert XML
   				this.xmlObj.body.appendChild(this.generator.getXML())
					
					// Next or finish
					this.currentGenerator++
					if(this.currentGenerator<this.generators.length()) processGenerator()
					else processGeometry()

			}

			// Start processing elements
			private function processGeometry():void {
				 
		 		 // Next step
		  	 this.stat = "Processing geometry and materials."
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,66,this.stat))
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part2T)
         myTimer.start()
				 
			}

			private function processXml_Part2T(event:TimerEvent):void {
				 this.processXml_Part2()
		  }

			// Process and setup base level
			private function processXml_Part2():void {

			   // Retrieve all floors and group them by their Z-coordinate
			   this.levelData = new Array

			   var tempObj:XMLList = tempObj = this.xmlObj.body.child("floor")
			   for(var i:Number=0;i<tempObj.length();i++) {
			   	
			   		// Z for this floor
			   		var tz:Number = 0
			      if(tempObj[i].@z.length()>0) tz = parseInt(tempObj[i].@z)
			      
			      if(tz>0) {
			      	this.levelData[this.levelData.length] = new fTempLevelData(tz)
			      	this.levelData[this.levelData.length-1].floors.push(tempObj[i])
			      } else {
			      	if(this.levelData.length==0) this.levelData[0] = new fTempLevelData(tz)
		      		this.levelData[0].floors.push(tempObj[i])
		      	}
			      
			   }
			   
			   // Sort
				 this.levelData.sortOn("z", Array.NUMERIC)
				 
			   // Retrieve all walls and group with closest floor
			   tempObj = this.xmlObj.body.child("wall")
			   for(i=0;i<tempObj.length();i++) {
			   	
			   		// Z for this element
			   		tz = 0
			      if(tempObj[i].@z.length()>0) tz = parseInt(tempObj[i].@z)
			      
			      for(var j:Number=0;j<this.levelData.length && this.levelData[j].z<=tz;j++);
		      	this.levelData[j-1].walls.push(tempObj[i])
			      
			   }
			   
			   // Retrieve all objects and group with closest floor
			   tempObj = this.xmlObj.body.child("object")
			   for(i=0;i<tempObj.length();i++) {
			   	
			   		// Z for this element
			   		tz = 0
			      if(tempObj[i].@z.length()>0) tz = parseInt(tempObj[i].@z)
			      
			      for(j=0;j<this.levelData.length && this.levelData[j].z<=tz;j++);
		      	this.levelData[j-1].objects.push(tempObj[i])
			      
			   }

			   // Retrieve all characters and group with closest floor
			   tempObj = this.xmlObj.body.child("character")
			   for(i=0;i<tempObj.length();i++) {
			   	
			   		// Z for this element
			   		tz = 0
			      if(tempObj[i].@z.length()>0) tz = parseInt(tempObj[i].@z)
			      
			      for(j=0;j<this.levelData.length && this.levelData[j].z<=tz;j++);
		      	this.levelData[j-1].characters.push(tempObj[i])
			      
			   }

			   this.maxfLevels = this.levelData.length
			
			   // Base level
			   this.stat = "Building levels"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,100,this.stat))
			   this.baseLevel = this.levels[0] = new fLevel(this.elements,this.levelData[0],this,0,0,0)
			
			   // Setup main control grid
			   this.gridWidth = this.baseLevel.gridWidth
			   this.gridHeight = this.baseLevel.gridHeight
			   this.width = this.gridWidth*this.gridSize
			   this.depth = this.gridHeight*this.gridSize
			
			   // Next step
			   if(this.levelData.length>1) {
			   		var myTimer:Timer = new Timer(200, this.levelData.length-1)
         	  myTimer.addEventListener(TimerEvent.TIMER, this.buildfLevels)
            myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part3T)
            myTimer.start()
         } else {
         		this.processXml_Part3()
         }
			
			}
			
			// Process other levels above base
			private function buildfLevels(event:TimerEvent):void {
			
			   // Other levels ( height above base level )
			   // For other levels grid is forced to be the same size as the base level
			   // Size of base level is calculated from floor size
	       this.stat = "Building levels"
	       var current:Number = 100*((event.target.currentCount)/this.levelData.length)
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50+current/10,fScene.LOADINGDESCRIPTION,current,this.stat))

			   this.levels[event.target.currentCount] = new fLevel(this.elements,this.levelData[event.target.currentCount],this,event.target.currentCount,this.gridWidth,this.gridHeight)
			}
			
			private function processXml_Part3T(event:TimerEvent):void {
				 this.processXml_Part3()
		  }

			// Start zSorting algorythm. I'm not even remotely try to explain how it works.
			private function processXml_Part3():void {
			
			   // Sort levels from bottom to top
			   this.levels.sortOn("z", Array.NUMERIC)
			
			   // Copy references from all levels to scene's arrays
			   for(var i:Number=0;i<this.levels.length;i++) {
			      for(var j:Number=0;j<this.levels[i].floors.length;j++) {
			      	this.floors.push(this.levels[i].floors[j])
			      	this.everything.push(this.levels[i].floors[j])
			      }
			      for(j=0;j<this.levels[i].walls.length;j++) {
			      	this.walls.push(this.levels[i].walls[j])
			      	this.everything.push(this.levels[i].walls[j])
			      }
			      for(j=0;j<this.levels[i].objects.length;j++) {
			      	this.objects.push(this.levels[i].objects[j])
			      	this.everything.push(this.levels[i].objects[j])
			      }
			      for(j=0;j<this.levels[i].characters.length;j++) {
			      	this.levels[i].characters[j].counter = this.characters.length
			      	this.characters.push(this.levels[i].characters[j])
			      	this.everything.push(this.levels[i].characters[j])
			      }
			      for(var k:String in this.levels[i].all) this.all[k] = this.levels[i].all[k]
			   }
			
			   // Place walls and floors
			   for(j=0;j<this.floors.length;j++) this.floors[j].place()
			   for(j=0;j<this.walls.length;j++) this.walls[j].place()
			   for(j=0;j<this.objects.length;j++) this.objects[j].place()
			   for(j=0;j<this.characters.length;j++) this.characters[j].place()
			   
			   // zSort walls and cells
			   this.baseLevel.setZ(0)
			   var maxz:Number = this.baseLevel.getMaxZIndex()
			   this.baseLevel.zSort()
			   maxz = this.baseLevel.getMaxZIndex()
			   //trace("Max z "+maxz)
			   //trace("Base Max z "+maxz)
			   //trace(this.gridWidth*this.gridHeight)

  	     this.stat = "Z sorting levels"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60,fScene.LOADINGDESCRIPTION,100,this.stat))

			   // Next step
			   if(this.levels.length>1) {
			   		var myTimer:Timer = new Timer(200, this.levels.length-1)
         		myTimer.addEventListener(TimerEvent.TIMER, this.sortfLevels)
         		myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part4T)
         		myTimer.start()
         } else {
            this.processXml_Part4()
         }
			
			}
			
			// Assign zIndexes to levels above base level containers
			private function sortfLevels(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount

  	     // zSort
  	     var ci:Number = this.levels[i_loop].i
  	     var cij:Number = this.levels[i_loop].i+this.levels[i_loop].gWidth-1
  	     var cj:Number = this.levels[i_loop].j+this.levels[i_loop].gDepth-1
  	     var cji:Number = this.levels[i_loop].j
  	     
  	     var newZ:Number = 0
  	     for(var j:Number=0;j<this.levels.length && this.levels[j].z<=this.levels[i_loop].z;j++) if(j!=i_loop && this.levels[j].grid[ci][cj].zIndex>newZ) newZ = this.levels[j].grid[ci][cj].zIndex
  	     
  	     this.levels[i_loop].setZ(newZ)
  	     this.levels[i_loop].zSort()
  	     
  	     // Propagate max zIndex to levels below so objects in front still display in front 
  	
  	     var maxz:Number = this.levels[i_loop].getMaxZIndex()
  	     //trace(this.levels[i_loop].id+" Max z "+maxz)
  	     for(j=0;j<this.levels.length && this.levels[j].z<=this.levels[i_loop].z;j++) if(j!=i_loop) {
  	        //trace("\n -- > Propago "+this.levels[i_loop].id+" a "+this.levels[j].id+"\n")
  	        this.levels[j].propagateZ(ci,cij,cji,cj,maxz)
  	     }
  	
	       var current:Number = 100*((i_loop+1)/this.levels.length)
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60+current/10,fScene.LOADINGDESCRIPTION,current,this.stat))
			   
			}
			
			// End zSorting algorythm
			private function processXml_Part4T(event:TimerEvent):void {
				
	   		 this.stat = "Finishing Z Sort"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70,fScene.LOADINGDESCRIPTION,100,this.stat))
				 this.processXml_Part4()
		  }

			// Generate grid
			private function processXml_Part4():void {
				
			
			   // Calculate top
			   for(var i:Number=0;i<this.levels.length;i++) if(this.levels[i].top>this.top) this.top = this.levels[i].top
			   
			   // Security margin
			   this.top+=this.levelSize*10
			
			   // Generate grid
			   this.gridThickness = Math.ceil(this.top/this.levelSize)
			
	   		 this.stat = "Generating grid"
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70,fScene.LOADINGDESCRIPTION,100,this.stat))

			   // Create grid
			   this.grid = new Array

			   // Next step
			   var myTimer:Timer = new Timer(20, this.gridWidth+1)
         myTimer.addEventListener(TimerEvent.TIMER, this.gridBuildLoop)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.gridBuildComplete)
         myTimer.start()
			
			}
			
			// Loop creation interval, to spare processor cycles
			private function gridBuildLoop(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount-1
			   var i:Number = i_loop
			   var levelCounter = 0

	       this.grid[i] = new Array()
	       for(var j:Number=0;j<=this.gridHeight;j++) this.grid[i][j] = new Array()
	       
	       for(var k:Number=0;k<=this.gridThickness;k++) {  
			
	         while(levelCounter<this.levels.length && this.levels[levelCounter].k<=k) levelCounter++
			         
			   	 for(j=0;j<=this.gridHeight;j++) {  

			      	 // Calculate max zIndex
			      	 var tz:Number = 0
							 var lev:fLevel
			      	 for(var n:Number=levelCounter-1;n>=0;n--) {
									lev = this.levels[n]
									if(i>=lev.i && i<=(lev.i+lev.gWidth) && j>=lev.j && j<=(lev.j+lev.gDepth) && lev.grid[i][j].zIndex>tz) tz=lev.grid[i][j].zIndex
			      	 }

			         // Setup cell parameters
			         this.grid[i][j][k] = new fCell()

			         // Initial Z-Index
			         this.grid[i][j][k].zIndex = tz
			         
			         // Internal
			         this.grid[i][j][k].i = i
			         this.grid[i][j][k].j = j
			         this.grid[i][j][k].k = k
			         this.grid[i][j][k].x = (this.gridSize/2)+(this.gridSize*i)
			         this.grid[i][j][k].y = (this.gridSize/2)+(this.gridSize*j)
			         this.grid[i][j][k].z = (this.levelSize/2)+(this.levelSize*k)
			     }
		
			   } 
			   
	       var current:Number = 100*((i_loop)/this.gridWidth)
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70+current*0.15,fScene.LOADINGDESCRIPTION,current,this.stat))

			}   
			   
			// Complete grid creation and setup initial raytracing
			private function gridBuildComplete(event:TimerEvent):void {

	      // Free some memory
	      for(var i:Number=1;i<this.levels.length;i++) {
	      	delete this.levels[i].grid
	      	delete this.levels[i]
	      }
	      
	      // Correct floor depths
			  for(i=0;i<this.floors.length;i++) {
			    var f:fFloor = this.floors[i]
			    	if(f.z!=0) {
			   	  	var nz1:Number = this.grid[f.i+f.gWidth-1][f.j][f.k].zIndex
			   	  	if((f.j+f.gDepth)<this.gridHeight) var nz2:Number = this.grid[f.i+f.gWidth-1][f.j+f.gDepth][f.k-1].zIndex
			   	  	else nz2 = Infinity
			   	  	if(f.i>0) var nz3:Number = this.grid[f.i-1][f.j][f.k-1].zIndex
			   	  	else nz3 = Infinity
	   	 				this.floors[i].setZ(Math.min(Math.min(nz1,nz2),nz3)-1)
	   	 			}
			  }
	      
	      // Set depth of objects and characters
				for(var j=0;j<this.objects.length;j++) this.objects[j].updateDepth()
				for(j=0;j<this.characters.length;j++) this.characters[j].updateDepth()

		    // Finish zSort
			  this.depthSort()
	
	      // Next step
	      try {
	      	if(this.xmlObj.@prerender=="true") this.limitHeight = this.gridThickness-1
	      	else if(this.xmlObj.@prerender=="false") this.limitHeight = -1
	      	else this.limitHeight = Math.ceil(parseInt(this.xmlObj.@prerender)/this.levelSize)
	      } catch (e:Error) {
	      	this.limitHeight = 0
	      }
	      
	      this.limitHeight++
	      if(this.limitHeight>0) {
			   
			    var myTimer:Timer = new Timer(20, this.limitHeight*this.gridWidth)
          myTimer.addEventListener(TimerEvent.TIMER, this.rayTraceLoop)
          myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.rayTraceComplete)
          myTimer.start()
      

        } else this.processXml_Part5()
			
			}
			
			// RayTrace Loops
			private function rayTraceLoop(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount-1
   
				 var i:Number = i_loop%this.gridWidth
				 var k:Number = Math.floor(i_loop/this.gridWidth) 
				 for(var j:Number=0;j<=this.gridHeight;j++) {
				 	this.calcVisibles(this.grid[i][j][k])
				 }

 	   		 this.stat = "Raytracing..."
	       var current:Number = 100*(i_loop/(this.limitHeight*this.gridWidth))
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,85+current*0.13,fScene.LOADINGDESCRIPTION,current,this.stat))
			   
			}
			
			// RayTrace Ends
			private function rayTraceComplete(event:TimerEvent):void {
			   this.processXml_Part5()
			}

			// Add collision info
			private function processXml_Part5():void {
			
			   this.stat = "Collision..."
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,98,fScene.LOADINGDESCRIPTION,100,this.stat))

		  	 // Update grid with object collision information
			   for(var j:Number=0;j<this.objects.length;j++) {
			   		var ob:fObject = this.objects[j]
			   		var rz:int = ob.z/this.levelSize
			   		var obi:int = ob.x/this.gridSize
			   		var obj:int = ob.y/this.gridSize
			   		var height:int = ob.height/this.levelSize
			   		var rad:int = Math.ceil(ob.radius/this.gridSize)
			   		
			   		for(var n:int=obj-rad;n<=obj+rad;n++) {
			   			for(var i:int=obi-rad;i<(obi+rad);i++) {
			   				for(var k:int=rz;k<=(rz+height);k++) {
			   					try {
			   						this.grid[i][n][k].walls.objects.push(ob)
			   					} catch(e:Error) {
			   						trace("Warning: "+ob.id+" extends out of bounds.")
			   					}
			   			  }
			   			}
			   	  }

			   }

				 // Update grid with floor fCollision information
			   for(j=0;j<this.floors.length;j++) {
			   		var fl:fFloor = this.floors[j]
			   		rz = fl.z/this.levelSize
			   		for(i=fl.i;i<(fl.i+fl.gWidth);i++) {
			   			for(k=fl.j;k<(fl.j+fl.gDepth);k++) {
			   				this.grid[i][k][rz].walls.bottom = fl
			   				if(rz>0) this.grid[i][k][rz-1].walls.top = fl
			   		  }
			   		}
			   }
			   
				 // Update grid with wall fCollision information
			   for(j=0;j<this.walls.length;j++) {
			   		var wl:fWall = this.walls[j]
			   		height = wl.height/this.levelSize
			   		rz = wl.z/this.levelSize
			   		if(wl.vertical) {
			   			for(i=wl.j;i<(wl.j+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					
			   					try {
			   						this.grid[wl.i][i][k].walls.left = wl
			   					} catch(e:Error) {
			   				  }
			   					if(wl.i>0) {
			   						this.grid[wl.i-1][i][k].walls.right = wl
			   					}
			   				}
			   			}
			   		} else {
			   			for(i=wl.i;i<(wl.i+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					try {
			   						this.grid[i][wl.j][k].walls.up = wl
			   					} catch(e:Error) {
			   				  }

			   					if(wl.j>0) {
			   						this.grid[i][wl.j-1][k].walls.down = wl
			   					}
			   				}
			   			}
			   		}
				 }

		     // Next step
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part6)
         myTimer.start()
			
			}
			
			// Add occlusion info
			private function processXml_Part6(event:TimerEvent):void {

			   this.stat = "Occlusion..."
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,99,fScene.LOADINGDESCRIPTION,100,this.stat))

		  	 // HitTestPoint with shape flag enabled only works if the DisplayObject is attached to the Stage
		  	 this.engine.container.addChild(this.container)
		  	 this.container.visible = false
		  	 
		  	 // Update grid with object occlusion information
			   for(var n:Number=0;n<this.objects.length;n++) {
			   		var ob:fObject = this.objects[n]
			   		var obz:int = ob.z/this.levelSize
			   		var obi:int = ob.x/this.gridSize
			   		var obj:int = ob.y/this.gridSize
			   		var height:int = ob.height/this.levelSize
			   		var rad:int = Math.ceil(ob.radius/this.gridSize)
			   		var bounds:Rectangle = ob.container.getRect(this.container) 
			   		
			   		var cnt:Number = 0
			   		do {
			   		
			   			var some:Boolean = false
			   			for(var i:int=-rad;i<=rad;i++) {
			   				
			   				  var row:Number = obi+i
			   				  var col:Number = obj+i
			   				  var z:Number = obz
									var inside:Boolean = true
									
									do {

										try {
											var cell:fCell = this.grid[row][col][z]
										} catch(e:Error) {
											cell = null
										}

										if(cell) {
											var candidate:Point = this.translateCoords(cell.x,cell.y,cell.z)
											if(bounds.contains(candidate.x,candidate.y)) {
			   								cell.elementsInFront.push(ob)
			   								some = true
											} else inside = false
										}
										z++
										
									} while(cell && inside)			   			  
			   				  
			   			}
			   			cnt++
			   			if(cnt%2==0) obi++
			   			else obj--
			   		
			   		} while(some)

			   }

				 // Wall occlusion
			   for(n=0;n<this.walls.length;n++) {
			   		var wa:fWall = this.walls[n]
			   		obz = wa.z/this.levelSize
			   		obi = ((wa.vertical)?(wa.x):(wa.x0))/this.gridSize
			   		obj = ((wa.vertical)?(wa.y0):(wa.y))/this.gridSize
			   		height = wa.height/this.levelSize

			   		do {
			   		
			   			some = false
			   			for(i=0;i<=wa.size;i++) {
			   				
			   				  if(wa.vertical) {
			   				  	row = obi
			   				  	col = obj+i-1
			   				  } else {
			   				  	row = obi+i
			   				  	col = obj-1
			   				  }
			   				  z = obz
									
									// Test lower cells
									try {
										cell = this.grid[row][col][z]
										candidate = this.translateCoords(cell.x,cell.y,cell.z)
										candidate = this.container.localToGlobal(candidate)
										if(wa.container.hitTestPoint(candidate.x,candidate.y,true))	some = true
									} catch(e:Error) {}

									do {

										try {
											cell = this.grid[row][col][z]
		   								cell.elementsInFront.push(wa)
										} catch(e:Error) {}
										z++
										
									} while(z<(obz+height))			   			  
			   				  
			   			}
		   				obj--
		   				obi++
			   		
			   		} while(some)

			   }


				 // Floor
			   for(n=0;n<this.floors.length;n++) {
			   		var flo:fFloor = this.floors[n]
			   		obz = flo.z/this.levelSize
			   		obi = flo.i
			   		obj = flo.j+flo.gDepth-1
			   		var width:Number = flo.gWidth
			   		var depth:Number = flo.gDepth

			   		do {
			   		
			   			some = false
			   			for(i=0;i<width;i++) {
			   				
		   				  	row = obi+i
		   				  	col = obj
			   				  z = obz-1

									do {

										try {
											cell = this.grid[row][col][z]
											candidate = this.translateCoords(cell.x,cell.y,cell.z)
											candidate = this.container.localToGlobal(candidate)
											if(((row<(flo.i+flo.gWidth)) && col>=flo.j) || flo.container.hitTestPoint(candidate.x,candidate.y,true))	{
												some = true
		   									cell.elementsInFront.push(flo)
		   								}
										} catch(e:Error) {}
										z--
										
									} while(z>=0)			   			  
			   				  
			   			}
			   			for(i=0;i<depth;i++) {
			   				
		   				  	row = obi
		   				  	col = obj-i
			   				  z = obz-1

									do {

										try {
											cell = this.grid[row][col][z]
											candidate = this.translateCoords(cell.x,cell.y,cell.z)
											candidate = this.container.localToGlobal(candidate)
											if(((row<(flo.i+flo.gWidth)) && col>=flo.j) || flo.container.hitTestPoint(candidate.x,candidate.y,true))	{
												some = true
		   									cell.elementsInFront.push(flo)
		   								}
										} catch(e:Error) {}
										z--
										
									} while(z>=0)			   			  
			   				  
			   			}

		   				obj--
		   				obi++
			   		
			   		} while(some)

			   }


		  	 // HitTestPoint with shape flag enabled only works if the DisplayObject is attached to the Stage
		  	 this.engine.container.removeChild(this.container)
		  	 this.container.visible = true

		     // Next step
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part7)
         myTimer.start()

		  }

			// Setup initial lights, render everything
			private function processXml_Part7(event:TimerEvent):void {
			
				 // Render
			   this.stat = "Rendering..."
			   this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,100,fScene.LOADINGDESCRIPTION,100,this.stat))

				 // Retrieve events
				 var tempObj:XMLList = this.xmlObj.body.child("event")
			    for(var i:Number=0;i<tempObj.length();i++) {
			   	  var evt:XML = tempObj[i]
			   	  
						var rz:int = Math.floor((new Number(evt.@z[0]))/this.levelSize)
			   		var obi:int = Math.floor((new Number(evt.@x[0]))/this.gridSize)
			   		var obj:int = Math.floor((new Number(evt.@y[0]))/this.gridSize)
			   		
			   		var height:int = Math.floor((new Number(evt.@height[0]))/this.levelSize)
			   		var width:int = Math.floor((new Number(evt.@width[0]))/(2*this.gridSize))
			   		var depth:int = Math.floor((new Number(evt.@depth[0]))/(2*this.gridSize))

			   		
			   		for(var n:Number=obj-depth;n<=(obj+depth);n++) {
			   			for(var l:Number=obi-width;l<=(obi+width);l++) {
			   				for(var k:Number=rz;k<=(rz+height);k++) {
			   					try {
			   						this.grid[l][n][k].events.push(new fCellEventInfo(evt))   	  
			   					} catch(e:Error){}
			   	  		}
			   	  	}
			   	  }
			   }

		     // Prepare global light
			   for(var j:Number=0;j<this.floors.length;j++) this.floors[j].setGlobalLight(this.environmentLight)
			   for(j=0;j<this.walls.length;j++) this.walls[j].setGlobalLight(this.environmentLight)
			   for(j=0;j<this.objects.length;j++) this.objects[j].setGlobalLight(this.environmentLight)
			   for(j=0;j<this.characters.length;j++) this.characters[j].setGlobalLight(this.environmentLight)
			
			   // Add dynamic lights
			   var objfLight:XMLList = this.xmlObj.body.child("light")
			   for(i=0;i<objfLight.length();i++) {
			   	  this.addLight(objfLight[i])
			   }

			   // Prepare characters
			   for(j=0;j<this.characters.length;j++) {
			   	  this.characters[j].cell = this.translateToCell(this.characters[j].x,this.characters[j].y,this.characters[j].z)
				 		this.characters[j].addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 		this.characters[j].addEventListener(fElement.MOVE,this.renderElement)			   
				 }

		   	 
		   	 // Create controller for this scene, if any was specified in the XML
		   	 if(this.xmlObj.@controller.length()==1) {
				 	try {
	   				var cls:String = this.xmlObj.@controller
	   				var r:Class = getDefinitionByName(cls) as Class
			   		this.controller = new r()		
			   		this.controller.enable()   	 
		   	 	} catch(e:Error) {
						throw new Error("Filmation Engine Exception: Scene contains an invalid controller definition: "+cls)		   	 		
		   	 	}
		   	 }
		   	 
		   	 // Initial render pass
		   	 this.render()
		   	 
		   	 var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Complete)
         myTimer.start()
			}
			
			// Complete process, mark scene as ready
			private function processXml_Complete(event:TimerEvent):void {

				 // Update status
			   this.stat = "Ready"
			   this.ready = true

			   this.dispatchEvent(new fProcessEvent(fScene.LOADCOMPLETE,false,false,100,fScene.LOADINGDESCRIPTION,100,this.stat))

			}

			// Render scene
			/** @private */
			public function render():void {

			   // Render global light
			   this.environmentLight.render()
			
			   // Render dynamic lights
			   for(var i:Number=0;i<this.lights.length;i++) this.lights[i].render()

			}

			// Listens cameras moving
			/** @private */
			public function cameraMoveListener(evt:fMoveEvent):void {
				
					this.followCamera(evt.target as fCamera)
				
			}

			// Listens cameras changing cells. Applies camera occlusion
			/** @private */
			public function cameraNewCellListener(evt:Event):void {
				
					var camera:fCamera = evt.target as fCamera
					if(camera.occlusion>=100) return
					
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
			/** @private */
			internal function followCamera(camera:fCamera):void {				
				
					var p:Point = this.translateCoords(camera.x,camera.y,camera.z)
					
					var rect:Rectangle = this.container.scrollRect
					rect.x = -this.viewWidth/2+p.x
					rect.y = -this.viewHeight/2+p.y
					this.container.scrollRect = rect
					
			}

			// Depth sorting
			/** @private */
			public function addToDepthSort(item:fRenderableElement):void {				

				if(this.depthSortArr.indexOf(item)<0) {
				 	this.depthSortArr.push(item)
			   	item.addEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener)
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
				
				// Call internal sort method
				if(this.ready) this.depthSort()
				
			}
			
		  // Internal depth sorting method
			/** @private */
			private function depthSort():void {
				
				var ar:Array = this.depthSortArr
				ar.sortOn("_depth", Array.NUMERIC);
    		var i:Number = ar.length;
    		var p:Sprite = this.elements
    		
    		while(i--) {
        	if (p.getChildAt(i) != ar[i].container) {
        		p.setChildIndex(ar[i].container, i)
        	}
        }
				
			}

			// Reset cell. This is called if the engine's quality options change to a better quality
			// as all cell info will have to be recalculated
			/** @private */
			public function resetGrid():void {

				for(var i:int=0;i<this.gridWidth;i++) {  

					for(var j:int=0;j<=this.gridHeight;j++) {  

		      	 for(var k:int=0;k<=this.gridThickness;k++) {  
			
			         this.grid[i][j][k].characterShadowCache = new Array
			         delete this.grid[i][j][k].visibleObjs
			   
			       }
		
			    } 
			  }
				
			}

			// Element enters new cell
			/** @private */
			public function processNewCell(evt:Event):void {

				var e:Number = getTimer()
				if(evt.target is fOmniLight) this.processNewCellOmniLight(evt.target as fOmniLight)
				if(evt.target is fCharacter) this.processNewCellCharacter(evt.target as fCharacter)
			  //trace("New cell:"+(getTimer()-e))

				
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
		     for(var i2:Number=0;i2<nEl;i2++) light.elementsV[i2].obj.lightOut(light)

			   if(cell==null) {
			      // fLight outside grid
			      light.elementsV = this.calcVisiblesCoords(light.x,light.y,light.z)
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
			      if(ele.distance<light.size) ele.obj.lightIn(light)
			      
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
				   		 	  		  if(el.testShadow(character,x,y,z) == fCoverage.SHADOWED) {
				   		 	  		  	cache.addElement(el)
				   		 	  		  }
               	  	
				   	   	  		  // Shadows of other elements upon this character
					   	 	  		  //if(character.testShadow(el,x,y,z) == fCoverage.SHADOWED) character.renderShadow(light,el)
				   		 	  	}
               	  
			   			 	  } 

			   		  }

			   		} else {
			   			
			   			cache.withinRange = false
			   			cache.clear()
			   			
			   		  // Remove light
			   		  character.lightOut(light)
			   		  
			   		}

			   	  // Update cache
			   	  character.vLights[light.counter] = light.vCharacters[character.counter] = character.cell.characterShadowCache[light.counter] = cache

			   }

			}


			// Process New cell for Characters
			private function processNewCellCharacter(character:fCharacter):void {
			
				 // Init
				 var light:fLight, elements:Array, nEl:Number, distL:Number, range:Number,x:Number, y:Number, z:Number
				 var cache:fCharacterShadowCache, oldCache:fCharacterShadowCache, elementsV:Array, el:fPlane
				 var s:Number, len:Number,i:Number,i2:Number

		 		 // Change depth of object
				 var r:Number = getTimer()
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
				   	      			 	if(el.testShadow(character,x,y,z) == fCoverage.SHADOWED) cache.addElement(el)
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
				   	      				 	if(el.testShadow(character,x,y,z) == fCoverage.SHADOWED) cache.addElement(el)
				   	      				} catch(e:Error) {
				   	      				}
                  		
				   		    		}
				   		      } catch(e:Error) {
				   		      	
				   		      }
                  
						      }
						      
						  }
			   			
			   		} else {
			   		
			   			//trace("Out range")
			   			cache.withinRange = false
			   			cache.clear()
			   		  
 			   		  // And remove light
			   		  character.lightOut(light)
			   		  
			   		}

			   	  
	  				// Delete shadows from this character that are no longer visible
			   		oldCache = character.vLights[light.counter]
			   		if(oldCache!=null) {
						 	elements = oldCache.elements
						 	nEl = elements.length
		   	 		 	for(var i3:Number=0;i3<nEl;i3++) {
			   					if(cache.elements.indexOf(elements[i3])<0) {
			   						elements[i3].unrenderShadowAlone(light,character)
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
				
			   if(evt.target is fOmniLight) this.renderOmniLight(evt.target as fOmniLight)
				 if(evt.target is fCharacter) this.renderCharacter(evt.target as fCharacter)
				
			}

			// Main render method for omni lights
			private function renderOmniLight(light:fOmniLight):void {
			
			   // Step 1: Init
			   var x:Number = light.x, y:Number = light.y, z:Number = light.z, nElements:Number = light.nElements, tempElements:Array = light.elementsV, el:fRenderableElement,others:Array,withinRange:Number
			   
			   // Step 2: render Start
				 for(var i2:Number=0;i2<nElements;i2++) tempElements[i2].obj.renderStart(light)
		
			   // Step 3: render light and shadows 
				 for(i2=0;i2<nElements;i2++) {
				    el = tempElements[i2].obj
				    others = tempElements[i2].shadows
				    withinRange = tempElements[i2].withinRange
				    el.renderLight(light)
			    
				    // Shadow from statics
				    for(var i3:Number=0;i3<withinRange;i3++) {
				    	try {
				    		//trace(el.id+" -> "+others[i3].obj.id)
				    		el.renderShadow(light,others[i3].obj)
				    	} catch(e:Error) {
				    		
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
			   			character.renderStart(light)
			   			character.renderLight(light)
			   			character.renderFinish(light)
			   		
			   			for(i2=0;i2<elements.length;i2++) {
					    	try {
			   					elements[i2].renderShadow(light,character)
			   				} catch(e:Error) {
			   					
			   		  	}
			   			}
			   		}
			   		
			   }

			   // Step 5: End render
			   for(i2=0;i2<nElements;i2++) tempElements[i2].obj.renderFinish(light)

			}

			// Main render method for characters
			private function renderCharacter(character:fCharacter):void {
			
			   var light:fLight, elements:Array, nEl:Number, len:Number, cache:fCharacterShadowCache 
			   
			   // Render all lights and shadows
			   
			   len = character.vLights.length
			   for(var i:Number=0;i<len;i++) {
			   
					 	cache =  character.vLights[i]
					 	if(cache.withinRange) {
					 	
					 		// Start
					 		light = cache.light
			   		  character.renderStart(light)
			   		  character.renderLight(light)
			    		
			    		// Update shadows for this character
			    		elements = cache.elements
			    		nEl = elements.length
		   	 		  if(fEngine.characterShadows) for(var i2:Number=0;i2<nEl;i2++) {
		   	 		  	try {
			    				elements[i2].renderShadowAlone(light,character)
			    			} catch(e:Error) {
			    			
			    			}
			    			
			    		}

							// End
			   		  character.renderFinish(light)
			   		  
			   	  }
			   
			   }

			}

			private function addLight(definitionObject:XML):void {
			
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

			private function addCharacter(definitionObject:XML):void {
			
				 // Create
				 var spr:MovieClip = new MovieClip()
		   	 this.elements.addChild(spr)			   
			   var nCharacter = new fCharacter(spr,definitionObject,this,null)
			   
			   // Events
				 nCharacter.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 nCharacter.addEventListener(fElement.MOVE,this.renderElement)			   

			   // Add to lists
 			   nCharacter.counter = this.characters.length
			   this.characters.push(nCharacter)
			   this.everything.push(nCharacter)
			   this.all[nCharacter.id] = nCharacter
			   
				 // Set global light
			   nCharacter.setGlobalLight(this.environmentLight)

			   // Translate to 2D coordinates
			   nCharacter.place()
			
			}

			// Return the cell containing the given coordinates
			/** @private */
			public function translateToCell(x:Number,y:Number,z:Number):fCell {
				 
				 var ret:fCell
				 try {
				 		ret = this.grid[int(Math.floor(x/this.gridSize))][int(Math.floor(y/this.gridSize))][int(Math.floor(z/this.levelSize))]
				 } catch(e:Error) {
				    ret = null
				 }
			   return ret

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
			internal function calcVisibles(cell:fCell,range:Number=Infinity):void {
			   var r:Array = this.calcVisiblesCoords(cell.x,cell.y,cell.z,range)
			   cell.visibleObjs = r
			   cell.visibleRange = range
			}
			
			// Get visible elements from given coordinates, sorted by distance
			/** @private */
			internal function calcVisiblesCoords(x:Number,y:Number,z:Number,range:Number=Infinity):Array {
			
			   // Init
			   var rcell:Array = new Array, candidates:Array = new Array, allElements:Array = new Array, floorc:fFloor, dist:Number, w:Number, len:Number, wallc:fWall, objc:fObject

			   // Add possible floors
			   len = this.floors.length
			   for(w=0;w<len;w++) {
			      floorc = this.floors[w] 
			      dist = floorc.distanceTo(x,y,z)
			      if(dist<range) {
			      	if(floorc.receiveLights) if(floorc.z<z) candidates.push(new fShadowedVisibilityInfo(floorc,dist))
			      	if(floorc.castShadows) allElements.push(new fShadowedVisibilityInfo(floorc,dist))
			      }
			   }
			
			   // Add possible walls
			   len = this.walls.length
			   for(w=0;w<len;w++) {
			      wallc = this.walls[w]
			      dist = wallc.distanceTo(x,y,z)
			      if(dist<range) {
			      	if(wallc.receiveLights) if((wallc.vertical && wallc.x>x) || (!wallc.vertical && wallc.y<y)) candidates.push(new fShadowedVisibilityInfo(wallc,dist))
					  	if(floorc.castShadows) allElements.push(new fShadowedVisibilityInfo(wallc,dist))
					  }
			   }
			
				 // Add possible objects
				 var withObjects:Boolean = fEngine.objectShadows
				 len = this.objects.length
			   for(w=0;w<len;w++) {
			      objc = this.objects[w]
			      dist = objc.distanceTo(x,y,z)
			      if(dist<range) {
			      	if(objc.receiveLights) candidates.push(new fShadowedVisibilityInfo(objc,dist))
			      	if(withObjects) if(objc.castShadows) allElements.push(new fShadowedVisibilityInfo(objc,dist))
			      }
			   }

			   // For each candidate, calculate possible shadows
			   var candidate:fShadowedVisibilityInfo, covered:Boolean, other:fShadowedVisibilityInfo, result:int, len2:Number

			   len = candidates.length
			   for(w=0;w<len;w++) {
			      
			      candidate = candidates[w]
			      covered = false
			      len2 = allElements.length
			      
			      // Shadows from other elements
			      if(candidate.obj.receiveShadows) {
			      	
			      	for(var k:Number=0;covered==false && k<len2;k++) {
			      	   other = allElements[k]
			      	   if(candidate.obj!=other.obj) {
			      	      result = candidate.obj.testShadow(other.obj,x,y,z)
			      	   	  //trace("Test "+candidate.obj.id+" "+other.obj.id+" "+result)
			      	      switch(result) {
			      	         case fCoverage.COVERED: covered = true;
			      	         case fCoverage.SHADOWED: candidate.addShadow(new fVisibilityInfo(other.obj,other.distance))
			      	      }
			      	   }
			      	}
			      
			      }

			      // If not covered, sort shadows by distance to coords and add candidate to result list
			      if(!covered) { 
			         
			         candidate.shadows.sortOn("distance",Array.NUMERIC)
			         rcell.push(candidate)
			         
			      }
			
			   }

			   // Sort results by distance to coords 
	       rcell.sortOn("distance",Array.NUMERIC)	
			   return rcell      
			
			}
			

/*			
			function searchPath(origin,destiny,limit) {
			
			      propagation = [origin]
			      explored_so_far = [origin]
			      origin.counter = " "
			      var found = false
			      
			      for(var propagation_count=1;!found && propagation_count<limit;propagation_count++) {
			         
			         var aux_list = new Array
			
			         // For each in list
			         for(var i=0;!found && i<propagation.length;i++) {
			
			            var cell = propagation[i]
			
			            if(cell.i==destiny.i && cell.j==destiny.j)  {
			               
			               found = true
			               
			            } else {
			                     
			               // Right
			               if(this.grid[cell.i+1][cell.j].counter==0 && this.grid[cell.i][cell.j].walls.up==false) {
			                  explored_so_far[explored_so_far.length] = this.grid[cell.i+1][cell.j]
			                  aux_list[aux_list.length] = {i: cell.i+1,j: cell.j}
			                  this.grid[cell.i+1][cell.j].counter = this.grid[cell.i][cell.j].counter+"R"
			               }
			               
			               // Down
			               if(this.grid[cell.i][cell.j+1].counter==0 && this.grid[cell.i][cell.j].walls.right==false) {
			                  explored_so_far[explored_so_far.length] = this.grid[cell.i][cell.j+1]
			                  aux_list[aux_list.length] = {i: cell.i,j: cell.j+1}
			                  this.grid[cell.i][cell.j+1].counter = this.grid[cell.i][cell.j].counter+"D"
			               }
			   
			               // Left
			               if(this.grid[cell.i-1][cell.j].counter==0 && this.grid[cell.i][cell.j].walls.down==false) {
			                  explored_so_far[explored_so_far.length] = this.grid[cell.i-1][cell.j]
			                  aux_list[aux_list.length] = {i: cell.i-1,j: cell.j}
			                  this.grid[cell.i-1][cell.j].counter = this.grid[cell.i][cell.j].counter+"L"
			               }
			               
			               // Up
			               if(this.grid[cell.i][cell.j-1].counter==0 && this.grid[cell.i][cell.j].walls.left==false) {
			                  explored_so_far[explored_so_far.length] = this.grid[cell.i][cell.j-1]
			                  aux_list[aux_list.length] = {i: cell.i,j: cell.j-1}
			                  this.grid[cell.i][cell.j-1].counter = this.grid[cell.i][cell.j].counter+"U"
			               }
			            }
			            
			         }
			         
			         propagation = aux_list
			      }
			   
			      // Generate output array ( path )
			      var ret = []
			      if(found) {
			         
			         var str = this.grid[cell.i][cell.j].counter
			         for(var i=str.length-1;i>=0;i--) ret[ret.length] = str.charAt(i)
			
			      }
			      
			      // Reset all counters
			      for(var i=0;i<explored_so_far.length;i++) explored_so_far[i].counter = 0
			
			      return ret
			}
		*/
		
		}


}

