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
		*/
		public class fSceneInitializer {		

			private var scene:fScene
			private var retriever:fEngineSceneRetriever
			
			// Variables used during the load and init process
			private var mediaSrcs:Array
			private var xmlObj:XML
			private var generators:XMLList
			private var srcs:Array
			private var queuePointer:Number
			private var levelData:Array
		  private var levels:Array
			private var limitHeight:Number
			private var generator:fEngineGenerator
			/** @private */
			public var currentGenerator:Number


			// Constructor
			/** @private */
			public function fSceneInitializer(scene:fScene,retriever:fEngineSceneRetriever) {
				 
				 this.scene = scene
				 this.retriever = retriever
				 
			}					

			// Start initialization process
			/** @private */
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

			   // Base level
			   this.scene.stat = "Building levels"
 			   this.levels = new Array          
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,100,this.scene.stat))
			   this.levels[0] = new fLevel(this.scene.elements,this.levelData[0],this.scene,0,0,0)
			
			   // Setup main control grid
			   this.scene.gridWidth = this.levels[0].gridWidth
			   this.scene.gridHeight = this.levels[0].gridHeight
			   this.scene.width = this.scene.gridWidth*this.scene.gridSize
			   this.scene.depth = this.scene.gridHeight*this.scene.gridSize
			
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
	       this.scene.stat = "Building levels"
	       var current:Number = 100*((event.target.currentCount)/this.levelData.length)
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50+current/10,fScene.LOADINGDESCRIPTION,current,this.scene.stat))

			   this.levels[event.target.currentCount] = new fLevel(this.scene.elements,this.levelData[event.target.currentCount],this.scene,event.target.currentCount,this.scene.gridWidth,this.scene.gridHeight)
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
			      	this.scene.floors.push(this.levels[i].floors[j])
			      	this.scene.everything.push(this.levels[i].floors[j])
			      }
			      for(j=0;j<this.levels[i].walls.length;j++) {
			      	this.scene.walls.push(this.levels[i].walls[j])
			      	this.scene.everything.push(this.levels[i].walls[j])
			      }
			      for(j=0;j<this.levels[i].objects.length;j++) {
			      	this.scene.objects.push(this.levels[i].objects[j])
			      	this.scene.everything.push(this.levels[i].objects[j])
			      }
			      for(j=0;j<this.levels[i].characters.length;j++) {
			      	this.levels[i].characters[j].counter = this.scene.characters.length
			      	this.scene.characters.push(this.levels[i].characters[j])
			      	this.scene.everything.push(this.levels[i].characters[j])
			      }
			      for(var k:String in this.levels[i].all) this.scene.all[k] = this.levels[i].all[k]
			   }
			
			   // Place walls and floors
			   for(j=0;j<this.scene.floors.length;j++) this.scene.floors[j].place()
			   for(j=0;j<this.scene.walls.length;j++) this.scene.walls[j].place()
			   for(j=0;j<this.scene.objects.length;j++) this.scene.objects[j].place()
			   for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].place()
			   
			   // zSort walls and cells
			   this.levels[0].setZ(0)
			   var maxz:Number = this.levels[0].getMaxZIndex()
			   this.levels[0].zSort()
			   maxz = this.levels[0].getMaxZIndex()
			   //trace("Max z "+maxz)
			   //trace("Base Max z "+maxz)
			   //trace(this.scene.gridWidth*this.scene.gridHeight)

  	     this.scene.stat = "Z sorting levels"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

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
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60+current/10,fScene.LOADINGDESCRIPTION,current,this.scene.stat))
			   
			}
			
			// End zSorting algorythm
			private function processXml_Part4T(event:TimerEvent):void {
				
	   		 this.scene.stat = "Finishing Z Sort"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70,fScene.LOADINGDESCRIPTION,100,this.scene.stat))
				 this.processXml_Part4()
		  }

			// Generate grid
			private function processXml_Part4():void {
				
			
			   // Calculate top
			   for(var i:Number=0;i<this.levels.length;i++) if(this.levels[i].top>this.scene.top) this.scene.top = this.levels[i].top
			   
			   // Security margin
			   this.scene.top+=this.scene.levelSize*10
			
			   // Generate grid
			   this.scene.gridThickness = Math.ceil(this.scene.top/this.scene.levelSize)
			
	   		 this.scene.stat = "Generating grid"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

			   // Create grid
			   this.scene.grid = new Array

			   // Next step
			   var myTimer:Timer = new Timer(20, this.scene.gridWidth+1)
         myTimer.addEventListener(TimerEvent.TIMER, this.gridBuildLoop)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.gridBuildComplete)
         myTimer.start()
			
			}
			
			// Loop creation interval, to spare processor cycles
			private function gridBuildLoop(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount-1
			   var i:Number = i_loop
			   var levelCounter = 0

	       this.scene.grid[i] = new Array()
	       for(var j:Number=0;j<=this.scene.gridHeight;j++) this.scene.grid[i][j] = new Array()
	       
	       for(var k:Number=0;k<=this.scene.gridThickness;k++) {  
			
	         while(levelCounter<this.levels.length && this.levels[levelCounter].k<=k) levelCounter++
			         
			   	 for(j=0;j<=this.scene.gridHeight;j++) {  

			      	 // Calculate max zIndex
			      	 var tz:Number = 0
							 var lev:fLevel
			      	 for(var n:Number=levelCounter-1;n>=0;n--) {
									lev = this.levels[n]
									if(i>=lev.i && i<=(lev.i+lev.gWidth) && j>=lev.j && j<=(lev.j+lev.gDepth) && lev.grid[i][j].zIndex>tz) tz=lev.grid[i][j].zIndex
			      	 }

			         // Setup cell parameters
			         this.scene.grid[i][j][k] = new fCell()

			         // Initial Z-Index
			         this.scene.grid[i][j][k].zIndex = tz
			         
			         // Internal
			         this.scene.grid[i][j][k].i = i
			         this.scene.grid[i][j][k].j = j
			         this.scene.grid[i][j][k].k = k
			         this.scene.grid[i][j][k].x = (this.scene.gridSize/2)+(this.scene.gridSize*i)
			         this.scene.grid[i][j][k].y = (this.scene.gridSize/2)+(this.scene.gridSize*j)
			         this.scene.grid[i][j][k].z = (this.scene.levelSize/2)+(this.scene.levelSize*k)
			     }
		
			   } 
			   
	       var current:Number = 100*((i_loop)/this.scene.gridWidth)
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70+current*0.15,fScene.LOADINGDESCRIPTION,current,this.scene.stat))

			}   
			   
			// Complete grid creation and setup initial raytracing
			private function gridBuildComplete(event:TimerEvent):void {

	      // Free some memory
	      for(var i:Number=1;i<this.levels.length;i++) {
	      	delete this.levels[i].grid
	      	delete this.levels[i]
	      }
	      
	      // Correct floor depths
			  for(i=0;i<this.scene.floors.length;i++) {
			    var f:fFloor = this.scene.floors[i]
			    	if(f.z!=0) {
			   	  	var nz1:Number = this.scene.grid[f.i+f.gWidth-1][f.j][f.k].zIndex
			   	  	if((f.j+f.gDepth)<this.scene.gridHeight) var nz2:Number = this.scene.grid[f.i+f.gWidth-1][f.j+f.gDepth][f.k-1].zIndex
			   	  	else nz2 = Infinity
			   	  	if(f.i>0) var nz3:Number = this.scene.grid[f.i-1][f.j][f.k-1].zIndex
			   	  	else nz3 = Infinity
	   	 				this.scene.floors[i].setZ(Math.min(Math.min(nz1,nz2),nz3)-1)
	   	 			}
			  }
	      
	      // Set depth of objects and characters
				for(var j=0;j<this.scene.objects.length;j++) this.scene.objects[j].updateDepth()
				for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].updateDepth()

		    // Finish zSort
			  this.scene.depthSort()
	
	      // Next step
	      try {
	      	if(this.xmlObj.@prerender=="true") this.limitHeight = this.scene.gridThickness-1
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
				 for(var j:Number=0;j<=this.scene.gridHeight;j++) {
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
