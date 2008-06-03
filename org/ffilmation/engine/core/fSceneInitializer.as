// SCENE INITIALIZER

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
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.interfaces.*
		

		/**
		* <p>The fSceneInitializer class contains all methods involved in scene initialization.</p>
		*
		* <p>Originally, all this code was inside fScene, but it made the file so big and unpractical that I decided to move
		* these methods to another class. So, conceptually speaking, this belongs to fScene.</p>
		* <p>Users of the engine don't need to look into this class.</p>
		*
		* @private
		*/
		public class fSceneInitializer {		

			/** 
			* Depending on the scene topology, zSorting may run into infinite recursion.
			* To avoid timeout exceptions, this constant defines a max depth
			*/
			public static const maxLoop:Number = 500
			
			// Parameters
			private var scene:fScene
			private var retriever:fEngineSceneRetriever
			
			// Variables used during the load and init process
			private var mediaSrcs:Array
			private var xmlObj:XML
			private var generators:XMLList
			private var srcs:Array
			private var queuePointer:Number
			private var limitHeight:Number
			private var generator:fEngineGenerator
			private var verticals:Array           
			private var horizontals:Array
			private var exploredRow:int
			private var lastHorizontal:int
			private var processedWalls:Number
			public var currentGenerator:Number

			// Constructor
			public function fSceneInitializer(scene:fScene,retriever:fEngineSceneRetriever) {
				 
				 this.scene = scene
				 this.retriever = retriever
				 
			}					

			// Start initialization process
			public function start(): void {
				 this.retriever.start().addEventListener(Event.COMPLETE, this.loadListener)
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.scene.stat))
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
				 this.scene.objectDefinitions = new Object()
				 this.scene.materialDefinitions = new Object()
				 this.scene.noiseDefinitions = new Object()
				 this.srcs = new Array()
			   
			   srcs = this.xmlObj.head.child("definitions")
			   for(i=0;i<srcs.length();i++) this.srcs.push(srcs[i].@src)
			   
			   this.queuePointer = -1
			   this.scene.stat = "Loading definition files"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.scene.stat))
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
							this.scene.objectDefinitions[defs[i].@name] = defs[i].copy()
						}
						
						// Retrieve Material definitions
						defs = xmlObj2.child("materialDefinition")
						for(i=0;i<defs.length();i++) {
							this.scene.materialDefinitions[defs[i].@name] = defs[i].copy()
						}
						
						// Retrieve Noise definitions
						defs = xmlObj2.child("noiseDefinition")
						for(i=0;i<defs.length();i++) {
							this.scene.noiseDefinitions[defs[i].@name] = new fNoise(defs[i])
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
			   		this.scene.stat = "Loading definition file: "+this.srcs[this.queuePointer]
			   		this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.scene.stat))
						
				 } else {

				 		// All loaded
	          this.processXml_Part1()
				 }

			}
		  
			// Start loading media files
			private function processXml_Part1():void {

			   // Read media files
			   this.queuePointer = -1
			   this.scene.stat = "Loading media files"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,0,fScene.LOADINGDESCRIPTION,0,this.scene.stat))

				 // Listen to media load events
				 this.scene.engine.addEventListener(fEngine.MEDIALOADCOMPLETE,this.loadComplete)
				 this.scene.engine.addEventListener(fEngine.MEDIALOADPROGRESS,this.loadProgress)
			   this.loadComplete(new Event("Dummy"))

			}
			
			// Process loaded media file and load next one
			private function loadComplete(event:Event):void {
			
				 this.queuePointer++
				 if(this.queuePointer<this.mediaSrcs.length) {
				 	
				 	  // Load
				 		var src:String = this.mediaSrcs[this.queuePointer]
			  	  this.scene.stat = "Loading media files ( current: "+src+"  ) "
			      var current:Number = 100*(this.queuePointer)/this.srcs.length
			   		this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,current/2,fScene.LOADINGDESCRIPTION,current,this.scene.stat))

						this.scene.engine.loadMedia(src)
						
				 } else {
				 		// All loaded
			  	  this.scene.stat = "Load complete. Processing scene data."
			   	  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,33,this.scene.stat))
			   		var myTimer:Timer = new Timer(200, 1)
            myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_DecompileT)
            myTimer.start()
				 }

			}
			
	    // Update status of current media file
			private function loadProgress(event:ProgressEvent):void {

			   var percent:Number = (event.bytesLoaded/event.bytesTotal)
			   this.scene.stat = "Loading media files ( current: "+this.mediaSrcs[this.queuePointer]+"  ) "
			   var current:Number = 100*(this.queuePointer+percent)/this.mediaSrcs.length
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,current/2,fScene.LOADINGDESCRIPTION,current,this.scene.stat))
			   
			}
			
			private function processXml_DecompileT(event:TimerEvent):void {
				 this.processXml_Decompile()
		  }

			// Decompile BOX and GENERATOR Tags
			private function processXml_Decompile():void {
				
				 // Remove listeners. Otherwise we would react to other scene's load calls
				 this.scene.engine.removeEventListener(fEngine.MEDIALOADCOMPLETE,this.loadComplete)
				 this.scene.engine.removeEventListener(fEngine.MEDIALOADPROGRESS,this.loadProgress)
				 
				 // Create elements
				 this.scene.elements = new Sprite()
				 this.scene.elements.mouseEnabled = false
				 this.scene.container.addChild(this.scene.elements)
			
			   // Setup environment
			   if(this.xmlObj.@gridsize.length()>0) this.scene.gridSize = new Number(this.xmlObj.@gridsize)
			   if(this.xmlObj.@levelsize.length()>0) this.scene.levelSize = new Number(this.xmlObj.@levelsize)
			   if(this.xmlObj.@maxelementspercell.length()>0) this.scene.maxElementsPerfCell = new Number(this.xmlObj.@maxelementspercell)
			
			   // Setup environment light, if any
			   this.scene.environmentLight = new fGlobalLight(this.xmlObj.head.child("light")[0],this.scene)
				 
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

			   	var ret:EventDispatcher = this.generator.generate(this.currentGenerator,this.scene,data)
			   	ret.addEventListener(ProgressEvent.PROGRESS, this.onGeneratorProgress)
			   	ret.addEventListener(Event.COMPLETE, this.onGeneratorComplete)

					this.scene.stat = "Processing generator "+(this.currentGenerator+1)+" of "+this.generators.length()
			   	this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,0,this.scene.stat))

	   		} catch (e:Error) {
	   			throw new Error("Filmation Engine Exception: Scene contains an invalid generator definition: "+cls+" "+e)
	   		}
				 
			}
			
			// Process Generator progress
			private function onGeneratorProgress(evt:Event):void {

					this.scene.stat = "Processing generator "+(this.currentGenerator+1)+" of "+this.generators.length()
			   	this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,this.generator.getPercent(),this.scene.stat))
				
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

		 		 // Next step
		  	 this.scene.stat = "Processing geometry and materials."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,66,this.scene.stat))
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part2T)
         myTimer.start()
				 
			}

			private function processXml_Part2T(event:TimerEvent):void {
				 this.processXml_Part2()
		  }

			// Process and setup elements
			private function processXml_Part2():void {

				 this.scene.top = 0   
			   this.verticals = new Array()
			   this.horizontals = new Array()

			   // Add floors
 			   this.scene.gridWidth = 0
			   this.scene.gridDepth = 0

				 var tempObj:XMLList = tempObj = this.xmlObj.body.child("floor")
			   for(var i:Number=0;i<tempObj.length();i++) { 
			   	  var spr:MovieClip = new MovieClip()
			   	  spr.mouseEnabled = false
			   	  this.scene.elements.addChild(spr)
			   	   
						var nFloor:fFloor = new fFloor(spr,tempObj[i],this.scene)
						nFloor.setZ(i)
         		this.scene.floors.push(nFloor)
         		this.scene.everything.push(nFloor)
			   		this.scene.all[nFloor.id] = nFloor
			   		   	    
			   		if(this.scene.gridWidth<(nFloor.i+nFloor.gWidth)) this.scene.gridWidth = nFloor.i+nFloor.gWidth
			   		if(this.scene.gridDepth<(nFloor.j+nFloor.gDepth)) this.scene.gridDepth = nFloor.j+nFloor.gDepth
			   		
			   		if(nFloor.z>this.scene.top) this.scene.top = nFloor.z
				 }
			
			   // Add walls
			   tempObj = this.xmlObj.body.child("wall")
			   for(i=0;i<tempObj.length();i++) { 
			   	  spr = new MovieClip()
			   	  this.scene.elements.addChild(spr)
			   		
	       		var nWall:fWall = new fWall(spr,tempObj[i],this.scene)
			   		if(nWall.vertical) this.verticals[this.verticals.length] = nWall
			   		else this.horizontals[this.horizontals.length] = nWall
			   		this.scene.walls.push(nWall)
			   		this.scene.everything.push(nWall)
			   		this.scene.all[nWall.id] = nWall
			   		if(nWall.top>this.scene.top) this.scene.top = nWall.top
			   		
			   }
			   
			   // Add objects and characters
			   tempObj = this.xmlObj.body.child("object")
			   for(i=0;i<tempObj.length();i++) {
			   		spr = new MovieClip()
		   	    this.scene.elements.addChild(spr)
			   		if(tempObj[i].@dynamic=="true") {
						  var nCharacter:fCharacter = new fCharacter(spr,tempObj[i],this.scene)
			   			this.scene.characters.push(nCharacter)
			   			this.scene.everything.push(nCharacter)
			   			this.scene.all[nCharacter.id] = nCharacter
			   		}
			   		else {
			   			var nObject:fObject = new fObject(spr,tempObj[i],this.scene)
			   			this.scene.objects.push(nObject)
			   			this.scene.everything.push(nObject)
			   			this.scene.all[nObject.id] = nObject
			   			if(nObject.top>this.scene.top) this.scene.top = nObject.top
			   		}
			   }

			   tempObj = this.xmlObj.body.child("character")
			   for(i=0;i<tempObj.length();i++) {
			   		spr = new MovieClip()
		   	    this.scene.elements.addChild(spr)
						nCharacter = new fCharacter(spr,tempObj[i],this.scene)
			   		this.scene.characters.push(nCharacter)
			   		this.scene.everything.push(nCharacter)
			   		this.scene.all[nCharacter.id] = nCharacter
			   }
			
			   // Setup main control grid
			   this.scene.width = this.scene.gridWidth*this.scene.gridSize
			   this.scene.depth = this.scene.gridDepth*this.scene.gridSize
			
			   // Next step
     		 this.processXml_Part3()
			
			}
			
			// Start zSorting algorythm. I'm not even remotely try to explain how it works.
			private function processXml_Part3():void {
			
			   // Z Sort
			   this.scene.stat = "Initial sort"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,100,this.scene.stat))
			   
			   for(var j:Number=0;j<this.scene.characters.length;j++) this.scene.characters[j].counter = j
			
			   // Sort horizontal walls ( bubble algorythm )
			   var changes:Boolean
         var one:fWall
         var two:fWall

			   do {
			      changes = false
			      for(var i:Number=0;i<(this.horizontals.length-1);i++) {
			         one = this.horizontals[i]
			         two = this.horizontals[i+1]
			         if(one.j>two.j || (one.j==two.j && one.i>two.i)) {
			            this.horizontals[i] = two
			            this.horizontals[i+1] = one
			            changes = true
			         }
			      }
			   } while(changes==true)
			   
			   // Sort vertical walls ( bubble algorythm )
			   do {
			      changes = false
			      for(i=0;i<(this.verticals.length-1);i++) {
			         one = this.verticals[i]
			         two = this.verticals[i+1]
			         if(one.i<two.i || (one.i==two.i && one.j>two.j)) {
			            this.verticals[i] = two
			            this.verticals[i+1] = one
			            changes = true
			         }
			      }
			   } while(changes==true)

			   // Place walls and floors
			   for(j=0;j<this.scene.floors.length;j++) this.scene.floors[j].place()
			   for(j=0;j<this.scene.walls.length;j++) this.scene.walls[j].place()
			   for(j=0;j<this.scene.objects.length;j++) this.scene.objects[j].place()
			   for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].place()
			   

			   // Next step
         this.processXml_Part4()
			
			}
			
			// Generate grid
			private function processXml_Part4():void {
				
			   // Security margin
			   this.scene.top+=this.scene.levelSize*10
			
			   // Generate grid
			   this.scene.gridHeight = Math.ceil(this.scene.top/this.scene.levelSize)
			
	   		 this.scene.stat = "Generating grid"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

			   // Create grid
			   this.scene.grid = new Array

			   // Next step
			   var myTimer:Timer = new Timer(20, this.scene.gridWidth+1)
         myTimer.addEventListener(TimerEvent.TIMER, this.gridBuildLoop)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.gridBuildComplete)
         myTimer.start()
			
			}
			
			// Part of zSorting algorythm
			public function computeZIndex(i:int,j:int,k:int,ow:int,od:int,oh:int):int {
			   return ((((this.scene.floors.length)+((ow-i+1)+(j*ow+2)))*oh)+k)*this.scene.maxElementsPerfCell
			}

			// Loop creation interval, to spare processor cycles
			private function gridBuildLoop(event:TimerEvent):void {
			
			   var i:Number = event.target.currentCount-1

	       this.scene.grid[i] = new Array()
	       for(var j:Number=0;j<=this.scene.gridDepth;j++) {
	       	
	       		this.scene.grid[i][j] = new Array()
	       		for(var k:Number=0;k<=this.scene.gridHeight;k++) {  

			         // Setup cell parameters
			         this.scene.grid[i][j][k] = new fCell()

			         // Initial Z-Index
			         this.scene.grid[i][j][k].zIndex = this.computeZIndex(i,j,k,this.scene.gridWidth,this.scene.gridDepth,this.scene.gridHeight)
			         
			         // Internal
			         this.scene.grid[i][j][k].i = i
			         this.scene.grid[i][j][k].j = j
			         this.scene.grid[i][j][k].k = k
			         this.scene.grid[i][j][k].x = (this.scene.gridSize/2)+(this.scene.gridSize*i)
			         this.scene.grid[i][j][k].y = (this.scene.gridSize/2)+(this.scene.gridSize*j)
			         this.scene.grid[i][j][k].z = (this.scene.levelSize/2)+(this.scene.levelSize*k)
			     }
		
			   } 
			   
	       var current:Number = 100*((i)/this.scene.gridWidth)
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50+current*0.15,fScene.LOADINGDESCRIPTION,current,this.scene.stat))

			}   
			   
			// Complete grid creation and start zSort
			private function gridBuildComplete(event:TimerEvent):void {

 	       this.scene.stat = "Z sorting"
		     this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,65,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

			   // Sort walls and cells
			   this.lastHorizontal = 0
			   
				 var myTimer:Timer = new Timer(20, this.scene.gridDepth)
         myTimer.addEventListener(TimerEvent.TIMER, this.zSortLoop)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.zSortComplete)
         myTimer.start()
			   
			}
			
			// Sorts walls, assigns zIndexes to all cells
			public function zSortLoop(event:TimerEvent):void {
			
		      // Avoids infinite loops
		      this.processedWalls = 0

		      // Explore this row
		      this.exploredRow = event.target.currentCount-1
		      while(this.lastHorizontal<this.horizontals.length && this.horizontals[this.lastHorizontal].j==this.exploredRow) {
		         // Change zIndex of wall
		         this.zSortHorizontal(this.lastHorizontal)
		         lastHorizontal++
		      }
			
		      for(var lastVertical:Number=0;lastVertical<this.verticals.length;lastVertical++) {
		         if(this.verticals[lastVertical].j==this.exploredRow) {
		            // Change zIndex of wall
		            this.zSortVertical(lastVertical)
		         }
		      }
			   
	       var current:Number = 100*((this.exploredRow)/this.scene.gridDepth)
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,65+current*0.20,fScene.LOADINGDESCRIPTION,current,this.scene.stat))

			}
			
			
			// Part of zSorting algorythm
			private function zSortHorizontal(wid:int):void {
					
			    var wall:fWall = this.horizontals[wid]
			    
					this.processedWalls++
					if(this.processedWalls>fSceneInitializer.maxLoop) {
						trace("FFilmation Info: Infinite recursion was avoided in ZSort")
						return	
					}

			    var newZ:Number = this.scene.grid[wall.i][wall.j][wall.k].zIndex
			    wall.setZ(newZ)
			    // Change ZIndex of cells below to be bigger
			    for(var i:Number=0;i<wall.i+wall.size;i++)
			       for(var j:Number=wall.j;j<=this.scene.gridDepth;j++)
			       		for(var k:Number=0;k<this.scene.gridHeight;k++)
			         		try {
			         		 this.scene.grid[i][j][k].zIndex= Math.max(this.scene.grid[i][j][k].zIndex,newZ+this.computeZIndex(i,j-wall.j,k,wall.i+wall.size,this.scene.gridDepth-wall.j,this.scene.gridHeight));
			         		} catch(e:Error) {	}
			
			    // Must redo previous vertical walls ?
			    for(j=0;j<this.verticals.length;j++) {
			       var wall2:fWall = this.verticals[j]
			       if(wall.j<this.exploredRow && wall2.i<(wall.i+wall.size) && (wall2.j+wall2.size)>wall.j && wall2.k>=wall.k) this.zSortVertical(j)
			    }
			
			}
			
			// Part of zSorting algorythm
			private function zSortVertical(wid:int):void {
				
			    var wall:fWall = this.verticals[wid]

					this.processedWalls++
					if(this.processedWalls>fSceneInitializer.maxLoop) {
						trace("FFilmation Info: Infinite recursion was avoided in ZSort")
						return	
					}

					var newZ:Number
			    if(wall.i!=0) {
			       newZ = this.scene.grid[wall.i-1][wall.j+wall.size-1][wall.k].zIndex 
			       wall.setZ(newZ)                        
			       // Change ZIndex of cells below to be bigger
			       for(var j:Number=wall.j;j<=this.scene.gridDepth;j++) {
			          for(var i:Number=wall.i-1;i>=0;i--) 
			       			 for(var k:Number=0;k<this.scene.gridHeight;k++)
      			       		try {
			             			this.scene.grid[i][j][k].zIndex=Math.max(this.scene.grid[i][j][k].zIndex,newZ+this.computeZIndex(i,j-wall.j,k,wall.i,this.scene.gridDepth-wall.j,this.scene.gridHeight));
			             		} catch(e:Error) { }
			       }
			    } else {
			       newZ = this.scene.grid[wall.i][wall.j+wall.size-1][wall.k].zIndex 
			       wall.setZ(newZ+1)
			    }
			
			    // Must redo previous vertical walls ?
			    for(j=0;j<this.verticals.length;j++) {
			       var wall2:fWall = this.verticals[j]
			       if((wall2.j<this.exploredRow) && wall2.i<wall.i && (wall2.j+wall2.size)>wall.j && wall2.k>=wall.k) this.zSortVertical(j)
			    }
			
			    // Must redo previous horizontal walls ?
			    for(j=0;j<this.horizontals.length;j++) {
			       wall2 = this.horizontals[j]
			       if(wall2.j<=this.exploredRow && wall2.j>wall.j && wall2.i<wall.i && wall2.k>=wall.k) this.zSortHorizontal(j)
			    }
			}


			// Complete zSort. Setup initial raytracing
			private function zSortComplete(event:TimerEvent):void {

	      // Correct floor depths
			  for(var i:Number=0;i<this.scene.floors.length;i++) {
			    var f:fFloor = this.scene.floors[i]
			    	if(f.z!=0) {
			   	  	var nz1:Number = this.scene.grid[f.i+f.gWidth-1][f.j][f.k].zIndex
			   	  	var nz1b:Number = this.scene.grid[f.i][f.j][f.k].zIndex
			   	  	
			   	  	if((f.j+f.gDepth)<this.scene.gridDepth) var nz2:Number = this.scene.grid[f.i+f.gWidth-1][f.j+f.gDepth][f.k-1].zIndex
			   	  	else nz2 = Infinity
			   	  	if(f.i>0) var nz3:Number = this.scene.grid[f.i-1][f.j][f.k-1].zIndex
			   	  	else nz3 = Infinity
			   	  	var candidate:Number = Math.min(Math.min(Math.min(nz1,nz1b),nz2),nz3)-1
	   	 				this.scene.floors[i].setZ(candidate)
	   	 			}
			  }
	      
	      // Set depth of objects and characters
				for(var j=0;j<this.scene.objects.length;j++) this.scene.objects[j].updateDepth()
				for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].updateDepth()

		    // Finish zSort
			  this.scene.depthSort()
	
	      // Next step
	      try {
	      	if(this.xmlObj.@prerender=="true") this.limitHeight = this.scene.gridHeight-1
	      	else if(this.xmlObj.@prerender=="false") this.limitHeight = -1
	      	else this.limitHeight = Math.ceil(parseInt(this.xmlObj.@prerender)/this.scene.levelSize)
	      } catch (e:Error) {
	      	this.limitHeight = 0
	      }
	      
	      this.limitHeight++
	      if(this.limitHeight>0) {
			   
			    var myTimer:Timer = new Timer(20, this.limitHeight*this.scene.gridWidth)
          myTimer.addEventListener(TimerEvent.TIMER, this.rayTraceLoop)
          myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.rayTraceComplete)
          myTimer.start()
      

        } else this.processXml_Part5()
			
			}


			// RayTrace Loops
			private function rayTraceLoop(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount-1
   
				 var i:Number = i_loop%this.scene.gridWidth
				 var k:Number = Math.floor(i_loop/this.scene.gridWidth) 
				 for(var j:Number=0;j<=this.scene.gridDepth;j++) {
				 	this.scene.calcVisibles(this.scene.grid[i][j][k])
				 }

 	   		 this.scene.stat = "Raytracing..."
	       var current:Number = 100*(i_loop/(this.limitHeight*this.scene.gridWidth))
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,85+current*0.13,fScene.LOADINGDESCRIPTION,current,this.scene.stat))
			   
			}
			
			// RayTrace Ends
			private function rayTraceComplete(event:TimerEvent):void {
			   this.processXml_Part5()
			}

			// Add collision info
			private function processXml_Part5():void {
			
			   this.scene.stat = "Collision..."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,98,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

		  	 // Update grid with object collision information
			   for(var j:Number=0;j<this.scene.objects.length;j++) {
			   		var ob:fObject = this.scene.objects[j]
			   		var rz:int = ob.z/this.scene.levelSize
			   		var obi:int = ob.x/this.scene.gridSize
			   		var obj:int = ob.y/this.scene.gridSize
			   		var height:int = ob.height/this.scene.levelSize
			   		var rad:int = Math.ceil(ob.radius/this.scene.gridSize)
			   		
			   		for(var n:int=obj-rad;n<=obj+rad;n++) {
			   			for(var i:int=obi-rad;i<(obi+rad);i++) {
			   				for(var k:int=rz;k<=(rz+height);k++) {
			   					try {
			   						this.scene.grid[i][n][k].walls.objects.push(ob)
			   					} catch(e:Error) {
			   						//trace("Warning: "+ob.id+" extends out of bounds.")
			   					}
			   			  }
			   			}
			   	  }

			   }

				 // Update grid with floor fCollision information
			   for(j=0;j<this.scene.floors.length;j++) {
			   		var fl:fFloor = this.scene.floors[j]
			   		rz = fl.z/this.scene.levelSize
			   		for(i=fl.i;i<(fl.i+fl.gWidth);i++) {
			   			for(k=fl.j;k<(fl.j+fl.gDepth);k++) {
			   				this.scene.grid[i][k][rz].walls.bottom = fl
			   				if(rz>0) this.scene.grid[i][k][rz-1].walls.top = fl
			   		  }
			   		}
			   }
			   
				 // Update grid with wall fCollision information
			   for(j=0;j<this.scene.walls.length;j++) {
			   		var wl:fWall = this.scene.walls[j]
			   		height = wl.height/this.scene.levelSize
			   		rz = wl.z/this.scene.levelSize
			   		if(wl.vertical) {
			   			for(i=wl.j;i<(wl.j+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					
			   					try {
			   						this.scene.grid[wl.i][i][k].walls.left = wl
			   					} catch(e:Error) {
			   				  }
			   					if(wl.i>0) {
			   						this.scene.grid[wl.i-1][i][k].walls.right = wl
			   					}
			   				}
			   			}
			   		} else {
			   			for(i=wl.i;i<(wl.i+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					try {
			   						this.scene.grid[i][wl.j][k].walls.up = wl
			   					} catch(e:Error) {
			   				  }

			   					if(wl.j>0) {
			   						this.scene.grid[i][wl.j-1][k].walls.down = wl
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

			   this.scene.stat = "Occlusion..."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,99,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

		  	 // HitTestPoint with shape flag enabled only works if the DisplayObject is attached to the Stage. Go figure...
		  	 this.scene.engine.container.addChild(this.scene.container)
		  	 this.scene.container.visible = false
		  	 
		  	 // Update grid with object occlusion information
			   for(var n:Number=0;n<this.scene.objects.length;n++) {
			   		var ob:fObject = this.scene.objects[n]
			   		var obz:int = ob.z/this.scene.levelSize
			   		var obi:int = ob.x/this.scene.gridSize
			   		var obj:int = ob.y/this.scene.gridSize
			   		var height:int = ob.height/this.scene.levelSize
			   		var rad:int = Math.ceil(ob.radius/this.scene.gridSize)
			   		var bounds:Rectangle = ob.container.getRect(this.scene.container) 
			   		
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
											var cell:fCell = this.scene.grid[row][col][z]
										} catch(e:Error) {
											cell = null
										}

										if(cell) {
											var candidate:Point = this.scene.translateCoords(cell.x,cell.y,cell.z)
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
			   for(n=0;n<this.scene.walls.length;n++) {
			   		var wa:fWall = this.scene.walls[n]
			   		obz = wa.z/this.scene.levelSize
			   		obi = ((wa.vertical)?(wa.x):(wa.x0))/this.scene.gridSize
			   		obj = ((wa.vertical)?(wa.y0):(wa.y))/this.scene.gridSize
			   		height = wa.height/this.scene.levelSize
			   		

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
			   				  z = 0
									
									// Test lower cells
									try {
										cell = this.scene.grid[row][col][Math.max(z,obz)]
										candidate = this.scene.translateCoords(cell.x,cell.y,cell.z)
										candidate = this.scene.container.localToGlobal(candidate)
										if(wa.container.hitTestPoint(candidate.x,candidate.y,true))	some = true
									} catch(e:Error) {}

									do {

										try {
											cell = this.scene.grid[row][col][z]
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
			   for(n=0;n<this.scene.floors.length;n++) {
			   		var flo:fFloor = this.scene.floors[n]
			   		obz = flo.z/this.scene.levelSize
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
											cell = this.scene.grid[row][col][z]
											candidate = this.scene.translateCoords(cell.x,cell.y,cell.z)
											candidate = this.scene.container.localToGlobal(candidate)
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
											cell = this.scene.grid[row][col][z]
											candidate = this.scene.translateCoords(cell.x,cell.y,cell.z)
											candidate = this.scene.container.localToGlobal(candidate)
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


		  	 // HitTestPoint with shape flag enabled only worked if the DisplayObject is attached to the Stage
		  	 this.scene.engine.container.removeChild(this.scene.container)
		  	 this.scene.container.visible = true

		     // Next step
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part7)
         myTimer.start()

		  }

			// Setup initial lights, render everything
			private function processXml_Part7(event:TimerEvent):void {
			
				 // Render
			   this.scene.stat = "Rendering..."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,100,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

				 // Retrieve events
				 var tempObj:XMLList = this.xmlObj.body.child("event")
			    for(var i:Number=0;i<tempObj.length();i++) {
			   	  var evt:XML = tempObj[i]
			   	  
						var rz:int = Math.floor((new Number(evt.@z[0]))/this.scene.levelSize)
			   		var obi:int = Math.floor((new Number(evt.@x[0]))/this.scene.gridSize)
			   		var obj:int = Math.floor((new Number(evt.@y[0]))/this.scene.gridSize)
			   		
			   		var height:int = Math.floor((new Number(evt.@height[0]))/this.scene.levelSize)
			   		var width:int = Math.floor((new Number(evt.@width[0]))/(2*this.scene.gridSize))
			   		var depth:int = Math.floor((new Number(evt.@depth[0]))/(2*this.scene.gridSize))

			   		
			   		for(var n:Number=obj-depth;n<=(obj+depth);n++) {
			   			for(var l:Number=obi-width;l<=(obi+width);l++) {
			   				for(var k:Number=rz;k<=(rz+height);k++) {
			   					try {
			   						this.scene.grid[l][n][k].events.push(new fCellEventInfo(evt))   	  
			   					} catch(e:Error){}
			   	  		}
			   	  	}
			   	  }
			   }

		     // Prepare global light
			   for(var j:Number=0;j<this.scene.floors.length;j++) this.scene.floors[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.walls.length;j++) this.scene.walls[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.objects.length;j++) this.scene.objects[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].setGlobalLight(this.scene.environmentLight)
			
			   // Add dynamic lights
			   var objfLight:XMLList = this.xmlObj.body.child("light")
			   for(i=0;i<objfLight.length();i++) {
			   	  this.scene.addLight(objfLight[i])
			   }

			   // Prepare characters
			   for(j=0;j<this.scene.characters.length;j++) {
			   	  this.scene.characters[j].cell = this.scene.translateToCell(this.scene.characters[j].x,this.scene.characters[j].y,this.scene.characters[j].z)
				 		this.scene.characters[j].addEventListener(fElement.NEWCELL,this.scene.processNewCell)			   
				 		this.scene.characters[j].addEventListener(fElement.MOVE,this.scene.renderElement)			   
				 }

		   	 
		   	 // Create controller for this scene, if any was specified in the XML
		   	 if(this.xmlObj.@controller.length()==1) {
				 	try {
	   				var cls:String = this.xmlObj.@controller
	   				var r:Class = getDefinitionByName(cls) as Class
			   		this.scene.controller = new r()		
			   		this.scene.controller.enable()   	 
		   	 	} catch(e:Error) {
						throw new Error("Filmation Engine Exception: Scene contains an invalid controller definition: "+cls+" "+e)		   	 		
		   	 	}
		   	 }
		   	 
		   	 // Initial render pass
		   	 this.scene.render()
		   	 
		   	 var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Complete)
         myTimer.start()
			}
			
			// Complete process, mark scene as ready. We are done !
			private function processXml_Complete(event:TimerEvent):void {

				 // Update status
			   this.scene.stat = "Ready"
			   this.scene.ready = true

			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADCOMPLETE,false,false,100,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

			}
			
		}
			
}
