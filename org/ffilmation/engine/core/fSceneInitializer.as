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
			private var sortArray:Array
			private var duplicateSortArray:Array
			private var changes:Number
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
						for(i=0;i<defs.length();i++) this.scene.objectDefinitions[defs[i].@name] = defs[i].copy()
						
						// Retrieve Material definitions
						defs = xmlObj2.child("materialDefinition")
						for(i=0;i<defs.length();i++) this.scene.materialDefinitions[defs[i].@name] = defs[i].copy()
						
						// Retrieve Noise definitions
						defs = xmlObj2.child("noiseDefinition")
						for(i=0;i<defs.length();i++) this.scene.noiseDefinitions[defs[i].@name] = new fNoise(defs[i])

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
			      var current:Number = 100*(this.queuePointer)/this.mediaSrcs.length
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
				 
				 this.scene.top = 0   
 			   this.scene.gridWidth = 0
			   this.scene.gridDepth = 0
			   this.verticals = new Array()
			   this.horizontals = new Array()

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

			   // Add walls
 				 tempObj = this.xmlObj.body.child("wall")
			   for(i=0;i<tempObj.length();i++) { 
			   	  var spr:MovieClip = new MovieClip()
			   	  this.scene.elements.addChild(spr)
			   		
	       		var nWall:fWall = new fWall(spr,tempObj[i],this.scene)
			   		if(nWall.vertical) this.verticals[this.verticals.length] = nWall
			   		else this.horizontals[this.horizontals.length] = nWall
			   		this.scene.walls.push(nWall)
			   		this.scene.everything.push(nWall)
			   		this.scene.all[nWall.id] = nWall
			   		if(nWall.top>this.scene.top) this.scene.top = nWall.top
			   }


		 		 // Next step
		  	 this.scene.stat = "Optimizing geometry and applying materials."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,0,this.scene.stat))
			   if(this.xmlObj.body.child("floor").length()>0) {
			   		var myTimer:Timer = new Timer(20,this.xmlObj.body.child("floor").length())
				 		myTimer.addEventListener(TimerEvent.TIMER, this.optimizeGeometryT)
         } else {
			   		myTimer = new Timer(200,1)
         }
      	 myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part2T)
         myTimer.start()
				 
			}

			// Floors are split so they don't cross walls. This results in faster calculations and renders 
			private function optimizeGeometryT(event:TimerEvent):void {

				 var loop:Number = event.target.currentCount-1
				 var tempObj:XMLList = this.xmlObj.body.child("floor")
				 var floorNode:XML = tempObj[loop]

				 // Original geometry   
				 var fx:Number = this.scene.gridSize*Math.round(floorNode.@x/this.scene.gridSize)
			   var fy:Number = this.scene.gridSize*Math.round(floorNode.@y/this.scene.gridSize)
			   var fz:Number = this.scene.gridSize*Math.round(floorNode.@z/this.scene.levelSize)
			   var fw:Number = this.scene.gridSize*Math.round(floorNode.@width/this.scene.gridSize)
			   var fd:Number = this.scene.gridSize*Math.round(floorNode.@height/this.scene.gridSize)
			   
			   // Final geometry
			   var horizontalSplits:Array = new Array
			   var verticalSplits:Array = new Array
			   horizontalSplits.push(fx)
			   horizontalSplits.push(fx+fw)
			   verticalSplits.push(fy)
			   verticalSplits.push(fy+fd)
				 
 				 var materialType:XML = this.scene.materialDefinitions[floorNode.@src]
 				 var type:String = materialType.@type
 				 
 				 // This optimization is applied only to certain material types
 				 /* Disabled: doesn't work well
 				 if(fz!=0 && (type == fMaterialTypes.TILE || type == fMaterialTypes.PERLIN)) {
 				 			// Search for walls that cross this floor
			   			for(i=0;i<this.verticals.length;i++) {
			   					var candidate:Number = this.verticals[i].x
			   					if(this.verticals[i].y1<(fy+fd) && this.verticals[i].y0>fy && candidate>fx && candidate<(fx+fw) && horizontalSplits.indexOf(candidate)<0) horizontalSplits.push(candidate)
			   			}
			   			for(i=0;i<this.horizontals.length;i++) {
			   					candidate = this.horizontals[i].y
			   					if(this.horizontals[i].y1<(fx+fw) && this.horizontals[i].x0>fx && candidate>fy && candidate<(fy+fd) && verticalSplits.indexOf(candidate)<0) verticalSplits.push(candidate)
			   			}
			   }*/
			   horizontalSplits.sort(Array.NUMERIC)
			   verticalSplits.sort(Array.NUMERIC)
			   
			   // Generate resulting floors
			   for(var i:Number=0;i<horizontalSplits.length-1;i++) {
			   	
			   		for(var j:Number=0;j<verticalSplits.length-1;j++) {
			   			
			   			  // New size and position
			   			  var newFloorNode:XML = floorNode.copy()
			   			  newFloorNode.@x = horizontalSplits[i]
			   			  newFloorNode.@width = horizontalSplits[i+1]-horizontalSplits[i]
			   			  newFloorNode.@y = verticalSplits[j]
			   			  newFloorNode.@height = verticalSplits[j+1]-verticalSplits[j]
			   			  if(horizontalSplits.length>1 || verticalSplits.length>1) newFloorNode.@id+="_Split_"+i+"_"+j
			   	
			   	  		var spr:MovieClip = new MovieClip()
			   	  		spr.mouseEnabled = false
			   	  		this.scene.elements.addChild(spr)
			   	  		 
								var nFloor:fFloor = new fFloor(spr,newFloorNode,this.scene)
         				this.scene.floors.push(nFloor)
         				this.scene.everything.push(nFloor)
			   				this.scene.all[nFloor.id] = nFloor
			   				   	    
			   				if(this.scene.gridWidth<(nFloor.i+nFloor.gWidth)) this.scene.gridWidth = nFloor.i+nFloor.gWidth
			   				if(this.scene.gridDepth<(nFloor.j+nFloor.gDepth)) this.scene.gridDepth = nFloor.j+nFloor.gDepth
			   				
			   				if(nFloor.z>this.scene.top) this.scene.top = nFloor.z

			   		}
			   	
			   }			   

				var p:Number = loop/tempObj.length()
				this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50+10*p,fScene.LOADINGDESCRIPTION,100*p,this.scene.stat))				 
				
				
			}

			private function processXml_Part2T(event:TimerEvent):void {

		  	 this.scene.stat = "Processing objects."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60,fScene.LOADINGDESCRIPTION,50,this.scene.stat))
				 this.processXml_Part2()
		  }

			// Process and setup objects
			private function processXml_Part2():void {

			   // Add objects and characters
			   var tempObj:XMLList = this.xmlObj.body.child("object")
			   for(var i:Number=0;i<tempObj.length();i++) {
			   		var spr:MovieClip = new MovieClip()
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

			   this.scene.stat = "Objects done"
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60,fScene.LOADINGDESCRIPTION,100,this.scene.stat))
			
			   // Next step
 				 var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part3T)
         myTimer.start()			
			}

			private function processXml_Part3T(event:TimerEvent):void {
			   this.scene.stat = "Start Z sorting..."
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,60,fScene.LOADINGDESCRIPTION,100,this.scene.stat))
				 this.processXml_Part3()
		  }
			
			// Start zSorting algorythm.
			private function sortHorizontals(one:fWall,two:fWall):Number {
         if(one.j>two.j || (one.j==two.j && one.i>two.i)) return -1
         else return 1
			}
			
			private function sortVerticals(one:fWall,two:fWall):Number {
         if(one.i<two.i || (one.i==two.i && one.j>two.j)) return -1
         else return 1
			}
			
			private function sortFloors(onef:fFloor,twof:fFloor):Number {
         if(onef.j>twof.j || (onef.j==twof.j && onef.k<twof.k)) return -1
         else return 1
			}

			private function processXml_Part3():void {
			
			   for(var j:Number=0;j<this.scene.characters.length;j++) this.scene.characters[j].counter = j
			
			   // Sort horizontal walls
			   this.horizontals.sort(this.sortHorizontals)
			   
			   // Sort vertical walls
			   this.verticals.sort(this.sortVerticals)

			   // Sort floors
	       this.scene.floors.sort(this.sortFloors)

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
			   this.scene.height = this.scene.gridHeight*this.scene.levelSize
			   this.scene.grid = new Array

				 // Next step
 	       this.scene.stat = "Z sorting..."
		     this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

				 var myTimer:Timer = new Timer(20, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.zSort)
         myTimer.start()
				 
			}
			
			// zSort Start
			private function zSort(event:TimerEvent):void {

	      // Start zSorting planes
	      this.sortArray = new Array
	      for(var i=0;i<this.verticals.length;i++) {
	      	var w:fWall = this.verticals[i]
	      	w.setZ(this.scene.computeZIndex(w.i-1,w.j+w.size-1,w.k))
	      	this.sortArray.push(w)
	      }
	      for(i=0;i<this.horizontals.length;i++) {
	      	w = this.horizontals[i]
	      	w.setZ(this.scene.computeZIndex(w.i,w.j,w.k))
	      	this.sortArray.push(w)
	      }
	      for(i=0;i<this.scene.floors.length;i++) {
	      	var f:fFloor = this.scene.floors[i]
	      	if(f.k!=0) {
	      		f.setZ(this.scene.computeZIndex(f.i,f.j+f.gDepth-1,f.k))
      			this.sortArray.push(f)
      		}
	      }
	      this.sortArray.sortOn("zIndex",Array.NUMERIC | Array.DESCENDING)

				// z Sort loop
				if( this.sortArray.length>0) {
					var myTimer:Timer = new Timer(20, this.sortArray.length)
        	myTimer.addEventListener(TimerEvent.TIMER, this.zSortLoop)
        } else {
					myTimer = new Timer(20, 1)
        }
       	myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.zSortComplete)
        myTimer.start()
        	
      }

			// This determines which plane is in front of which plane. Took me months of work with incredibly slow, complex
			// and overall unclever algorythms to reach this. I don't know If I should feel incredibly smart or incredibly stupid.
			private function setD(p:fPlane,value:Number,initial:Boolean=false):void {
				
				  if(initial) p.setZ(value)
				  else p.setZ(p.zIndex+value)
				  
	      	for(var k:Number=0;k<this.sortArray.length;k++) {
	      		  if(this.sortArray[k].zIndex<p.zIndex && this.sortArray[k].inFrontOf(p)) {
	      		  	this.duplicateSortArray.push( { plane:this.sortArray[k],zValue: p.zIndex} )
	      		  }
	      	}
				
			}
	      
			// Sorts walls, assigns zIndexes to all cells
      public function zSortLoop(event:TimerEvent):void {
                        
         // Explore this plane
         var count = event.target.currentCount-1
         this.duplicateSortArray = new Array
				 this.setD(this.sortArray[count],this.sortArray[count].zIndex,true)
	       
				 // Sort again previous planes that may need to be resorted due to this plane changing zIndex
         do {
         	
             var tempP:Array = new Array
             for(var i:Number=0;i<this.duplicateSortArray.length;i++) {
             	  var found:Boolean=false
             	  for(var k:Number=0;k<tempP.length;k++) {
             	  	if(tempP[k].plane==this.duplicateSortArray[i].plane) {
             	  		 found = true
             	  		 if(tempP[k].zValue<this.duplicateSortArray[i].zValue) tempP[k].zValue=this.duplicateSortArray[i].zValue
             	  	}
                }
                if(!found) tempP.push(this.duplicateSortArray[i])
             }
             this.duplicateSortArray = new Array
             for(i=0;i<tempP.length;i++) this.setD(tempP[i].plane,tempP[i].zValue)
                 
         } while(tempP.length!=0)
	       
				 // Progress event
				 var current:Number = 100*((count)/this.sortArray.length)
         this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,70+current*0.15,fScene.LOADINGDESCRIPTION,current,this.scene.stat))
	       
	    }
	      
	      
			// zSort End
			private function zSortComplete(event:TimerEvent):void {
	     
	      // Finish zSort and normalize zIndexes
	      this.sortArray.sortOn("zIndex",Array.NUMERIC)
	      for(var i:Number=0;i<this.sortArray.length;i++) this.sortArray[i].setZ(i+1)

	      // Generate sort areas for the scene
	      var sortAreas:Array = new Array
	      sortAreas.push(new fSortArea(0,0,0,this.scene.gridWidth,this.scene.gridDepth,this.scene.gridHeight,0))
	      for(i=0;i<this.verticals.length;i++) {
	      	var w:fWall = this.verticals[i]
	      	sortAreas.push(new fSortArea(0,w.j,0,w.i-1,this.scene.gridDepth-w.j,this.scene.gridHeight,w.zIndex))
	      }
	      for(i=0;i<this.horizontals.length;i++) {
	      	w = this.horizontals[i]
	      	sortAreas.push(new fSortArea(0,w.j,0,w.i+w.size-1,this.scene.gridDepth-w.j,this.scene.gridHeight,w.zIndex))
	      }
	      for(i=0;i<this.scene.floors.length;i++) {
	      	var f:fFloor = this.scene.floors[i]
	      	if(f.k!=0) {
	      		sortAreas.push(new fSortArea(f.i,f.j,f.k,f.gWidth-1,f.gDepth-1,this.scene.gridHeight-f.k,f.zIndex))
	      		sortAreas.push(new fSortArea(0,f.j,0,f.i-1,this.scene.gridDepth-f.j,this.scene.gridHeight,f.zIndex))
	      		sortAreas.push(new fSortArea(f.i,f.j+f.gDepth,0,f.gWidth-1,this.scene.gridDepth-f.j-f.gDepth,this.scene.gridHeight,f.zIndex))
	      	}
	      }

	      // Split sortAreas per row, for faster lookups
	      sortAreas.sortOn("zValue",Array.DESCENDING | Array.NUMERIC)
	      this.scene.sortAreas = new Array
	      for(i=0;i<this.scene.gridWidth;i++) {
	      	var temp:Array = new Array
	      	for(j=0;j<sortAreas.length;j++) {
	      		var s:fSortArea = sortAreas[j]
	      		if(i>=s.i && i<=(s.i+s.width)) temp.push(s)
	      	}
	      	this.scene.sortAreas[i] = temp
	      }

	      // Set depth of objects and characters and finish zSort
				for(var j=0;j<this.scene.objects.length;j++) this.scene.objects[j].updateDepth()
				for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].updateDepth()
			  this.scene.depthSort()
	
	      // Next step: Setup initial raytracing
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
				 for(var j:Number=0;j<this.scene.gridDepth;j++) this.scene.calcVisibles(this.scene.getCellAt(i,j,k))

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
			   						var cell:fCell = this.scene.getCellAt(i,n,k)
			   						cell.walls.objects.push(ob)
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
			   				cell = this.scene.getCellAt(i,k,rz)
			   				cell.walls.bottom = fl
			   				if(rz>0) {
			   					cell = this.scene.getCellAt(i,k,rz-1)
			   					cell.walls.top = fl
			   				}
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
			   						cell = this.scene.getCellAt(wl.i,i,k)
			   						cell.walls.left = wl
			   					} catch(e:Error) {
			   				  }
			   					if(wl.i>0) {
			   						cell = this.scene.getCellAt(wl.i-1,i,k)
			   						cell.walls.right = wl
			   					}
			   				}
			   			}
			   		} else {
			   			for(i=wl.i;i<(wl.i+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					try {
			   						cell = this.scene.getCellAt(i,wl.j,k)
			   						cell.walls.up = wl
			   					} catch(e:Error) {
			   				  }

			   					if(wl.j>0) {
			   						cell = this.scene.getCellAt(i,wl.j-1,k)
			   						cell.walls.down = wl
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
											var cell:fCell = this.scene.getCellAt(row,col,z)
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
										cell = this.scene.getCellAt(row,col,Math.max(z,obz))
										candidate = this.scene.translateCoords(cell.x,cell.y,cell.z)
										candidate = this.scene.container.localToGlobal(candidate)
										if(wa.container.hitTestPoint(candidate.x,candidate.y,true))	some = true
									} catch(e:Error) {}

									do {

										try {
											cell = this.scene.getCellAt(row,col,z)
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
											cell = this.scene.getCellAt(row,col,z)
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
											cell = this.scene.getCellAt(row,col,z)
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


		  	 // HitTestPoint with shape flag enabled only worked if the DisplayObject was attached to the Stage
		  	 this.scene.engine.container.removeChild(this.scene.container)
		  	 this.scene.container.visible = true

		     // Next step
			   var myTimer:Timer = new Timer(200, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.processXml_Part7)
         myTimer.start()

		  }

			// Setup initial lights, render everything
			private function processXml_Part7(event:TimerEvent):void {
			
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
			   						var cell:fCell = this.scene.getCellAt(l,n,k)
			   						cell.events.push(new fCellEventInfo(evt))   	  
			   					} catch(e:Error){}
			   	  		}
			   	  	}
			   	  }
			   }

			   // Setup environment light, if any
			   this.scene.environmentLight = new fGlobalLight(this.xmlObj.head.child("light")[0],this.scene)
			   for(var j:Number=0;j<this.scene.floors.length;j++) this.scene.floors[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.walls.length;j++) this.scene.walls[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.objects.length;j++) this.scene.objects[j].setGlobalLight(this.scene.environmentLight)
			   for(j=0;j<this.scene.characters.length;j++) this.scene.characters[j].setGlobalLight(this.scene.environmentLight)
			
			   // Add dynamic lights
			   var objfLight:XMLList = this.xmlObj.body.child("light")
			   for(i=0;i<objfLight.length();i++) this.scene.addLight(objfLight[i])

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
			   
			   // Dispatch completion event
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADCOMPLETE,false,false,100,fScene.LOADINGDESCRIPTION,100,this.scene.stat))

			   // Free all resources allocated by this Object, to help the Garbage collector
			   this.dispose()

			}
			
			private function dispose():void {
				
				 this.scene = null
				 this.retriever = null
				 this.xmlObj = null
				 this.generators = null
				 this.generator = null
				 
				 if(this.mediaSrcs) for(var i:Number=0;i<this.mediaSrcs.length;i++) delete this.mediaSrcs[i]
				 this.mediaSrcs = null
				 if(this.srcs) for(i=0;i<this.srcs.length;i++) delete this.srcs[i]
				 this.srcs = null
				 if(this.verticals) for(i=0;i<this.verticals.length;i++) delete this.verticals[i]
				 this.verticals = null
				 if(this.horizontals) for(i=0;i<this.horizontals.length;i++) delete this.horizontals[i]
				 this.horizontals = null
				 if(this.sortArray) for(i=0;i<this.sortArray.length;i++) delete this.sortArray[i]
				 this.sortArray = null
				 if(this.duplicateSortArray) for(i=0;i<this.duplicateSortArray.length;i++) delete this.duplicateSortArray[i]
				 this.duplicateSortArray = null
				
			}
			
			
		}
			
}
