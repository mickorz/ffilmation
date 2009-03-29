// GRID SORTER
package org.ffilmation.engine.core.sceneInitialization {
	
		// Imports
		import flash.net.*
		import flash.events.*
		import flash.geom.*
		import flash.display.*
		import flash.utils.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.events.*
		
		/**
		* The grid sorter performs zSorting of a given scene. zSorting is a cpu-intensive calculation that needs to be split into several cycles.
		* 
		* @private
		*/
		public class fSceneGridSorter extends EventDispatcher {

			/**
			* An string describing the process of zSorting.
			* Events dispatched by the grid sorter contain this String as a description of what is happening
			*/
			public static const SORTDESCRIPTION:String = "Z Sorting scene"
			
			// Simple sort functions
			public static function sortHorizontals(one:fWall,two:fWall):Number {
         if(one.j>two.j || (one.j==two.j && one.i>two.i)) return -1
         else return 1
			}
			
			public static function sortVerticals(one:fWall,two:fWall):Number {
         if(one.i<two.i || (one.i==two.i && one.j>two.j)) return -1
         else return 1
			}
			
			public static function sortFloors(onef:fFloor,twof:fFloor):Number {
         if(onef.j>twof.j || (onef.j==twof.j && onef.k<twof.k)) return -1
         else return 1
			}
			
			// Private properties
			private var scene:fScene
			private var verticals:Array
			private var horizontals:Array
			private var sortArray:Array
			private var duplicateSortArray:Array
			
			// Constructor
			public function fSceneGridSorter(s:fScene):void {
				 this.scene = s				
			}

	    // Create grid for this scene ( only where the are floors )
			public function createGrid():void {

			   this.scene.grid = new Array
			   this.scene.allUsedCells = new Array
			   var fl:int = this.scene.floors.length
				 for(var fi=0;fi<fl;fi++) {
	      	 var f:fFloor = this.scene.floors[fi]
	      	 if(f.k==0) {
	      	 	var fl2:int = (f.i+f.gWidth)
	      	 	for(var i:int = f.i;i<fl2;i++) {
 				 			if(!this.scene.grid[i]) this.scene.grid[i] = new Array
 				 			var temp:Array = this.scene.grid[i]
 				 			var fl3:int = (f.j+f.gDepth)
	      	 		for(var j:int = f.j;j<fl3;j++) {
	      	 			temp[j] = new Array
	      	 		}
	      	 	}
      		 }
	       }

		  }

			// Start zSorting algorythm.
			public function start():void {
			
				 // Init
				 this.verticals = new Array
				 this.horizontals = new Array
				 this.sortArray = new Array
				 this.duplicateSortArray = new Array
				 
				 // Populate wall arrays
				 var wl:int = this.scene.walls.length
				 for(var i:int=0;i<wl;i++) {
				 		var w:fWall = this.scene.walls[i]
				 		if(w.vertical) this.verticals[this.verticals.length] = w
				 		else this.horizontals[this.horizontals.length] = w
				 }
			
			   // Sort arrays
			   this.horizontals.sort(fSceneGridSorter.sortHorizontals)
			   this.verticals.sort(fSceneGridSorter.sortVerticals)
	       this.scene.floors.sort(fSceneGridSorter.sortFloors)


		     this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,0,fSceneGridSorter.SORTDESCRIPTION,0,fSceneGridSorter.SORTDESCRIPTION))

				 // Next step
				 var myTimer:Timer = new Timer(20, 1)
         myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.zSort,false,0,true)
         myTimer.start()
				 
			}
			
			// zSort Start
			private function zSort(event:TimerEvent):void {

        event.target.removeEventListener(TimerEvent.TIMER_COMPLETE, this.zSort)

	      // Start zSorting planes
	      this.sortArray = new Array
	      var vl:int = this.verticals.length
	      for(var i:int=0;i<vl;i++) {
	      	var w:fWall = this.verticals[i]
	      	w.setZ(this.scene.computeZIndex(w.i-1,w.j+w.size-1,w.k))
	      	this.sortArray[this.sortArray.length] = w
	      }
	      var hl:int = this.horizontals.length 
	      for(i=0;i<hl;i++) {
	      	w = this.horizontals[i]
	      	w.setZ(this.scene.computeZIndex(w.i,w.j,w.k))
	      	this.sortArray[this.sortArray.length] = w
	      }
	      var fl:int = this.scene.floors.length 
	      for(i=0;i<fl;i++) {
	      	var f:fFloor = this.scene.floors[i]
	      	if(f.k!=0) {
	      		f.setZ(this.scene.computeZIndex(f.i,f.j+f.gDepth-1,f.k))
      			this.sortArray[this.sortArray.length] = f
      		} else {
      			f.setZ(-this.scene.floors.length+this.scene.computeZIndex(f.i,f.j+f.gDepth-1,f.k))
      		}
	      }
	      this.sortArray.sortOn("zIndex",Array.NUMERIC | Array.DESCENDING)

				// z Sort loop
				if(this.sortArray.length>0) {
					var myTimer:Timer = new Timer(20, this.sortArray.length)
        	myTimer.addEventListener(TimerEvent.TIMER, this.zSortLoop,false,0,true)
        } else {
					myTimer = new Timer(20, 1)
        }
       	myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.zSortComplete,false,0,true)
        myTimer.start()
        	
      }

			// This determines which plane is in front of which plane. Took me months of work with incredibly slow, complex
			// and overall unclever algorythms to reach this. I don't know If I should feel incredibly smart or incredibly stupid.
			private function setD(p:fPlane,value:Number,initial:Boolean=false):void {
				
				  if(initial) p.setZ(value)
				  else p.setZ(p.zIndex+value)
				  
	      	var sl:int = this.sortArray.length
	      	for(var k:int=0;k<sl;k++) {
	      		 	var temp:fPlane = this.sortArray[k]
	      		  if(temp.zIndex<p.zIndex && temp.inFrontOf(p)) {
	      		  	this.duplicateSortArray[this.duplicateSortArray.length] =  { plane:temp,zValue: p.zIndex} 
	      		  }
	      	}
				
			}
	      
			// Sorts walls, assigns zIndexes to all cells
      public function zSortLoop(event:TimerEvent):void {
                        
         // Explore this plane
         var count:int = event.target.currentCount-1
         this.duplicateSortArray = new Array
				 this.setD(this.sortArray[count],this.sortArray[count].zIndex,true)
	       
				 // Sort again previous planes that may need to be resorted due to this plane changing zIndex
         do {
         	
             var tempP:Array = new Array
             var dl:int = this.duplicateSortArray.length
             for(var i:int=0;i<dl;i++) {
             	  var found:Boolean=false
             	  var tl:int = tempP.length
             	  for(var k:int=0;k<tl;k++) {
             	  	if(tempP[k].plane==this.duplicateSortArray[i].plane) {
             	  		 found = true
             	  		 if(tempP[k].zValue<this.duplicateSortArray[i].zValue) tempP[k].zValue=this.duplicateSortArray[i].zValue
             	  	}
                }
                if(!found) tempP[tempP.length] = this.duplicateSortArray[i]
             }
             this.duplicateSortArray = new Array
             
             tl = tempP.length
             for(i=0;i<tl;i++) this.setD(tempP[i].plane,tempP[i].zValue)
                 
         } while(tempP.length!=0)
	       
				 // Progress event
				 var current:Number = 100*((count)/this.sortArray.length)
         this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,current,fSceneGridSorter.SORTDESCRIPTION,current,fSceneGridSorter.SORTDESCRIPTION))
	       
	    }
	      
			// zSort End
			private function zSortComplete(event:TimerEvent):void {
	     
				event.target.removeEventListener(TimerEvent.TIMER, this.zSortLoop)
       	event.target.removeEventListener(TimerEvent.TIMER_COMPLETE, this.zSortComplete)

	      // Finish zSort and normalize zIndexes
	      this.sortArray.sortOn("zIndex",Array.NUMERIC)
	      var sl:int = this.sortArray.length
	      for(var i:int=0;i<sl;i++) (this.sortArray[i] as fPlane).setZ(i+1)

	      // Generate sort areas for the scene
	      var sortAreas:Array = new Array
	      sortAreas[sortAreas.length] = (new fSortArea(0,0,0,this.scene.gridWidth,this.scene.gridDepth,this.scene.gridHeight,0))
	      
	      var vl:int = this.verticals.length 
	      for(i=0;i<vl;i++) {
	      	var w:fWall = this.verticals[i]
	      	sortAreas[sortAreas.length] = (new fSortArea(0,w.j,0,w.i-1,this.scene.gridDepth-w.j,this.scene.gridHeight,w.zIndex))
	      }
	      
	      var hl:int = this.horizontals.length
	      for(i=0;i<hl;i++) {
	      	w = this.horizontals[i]
	      	sortAreas[sortAreas.length] = (new fSortArea(0,w.j,0,w.i+w.size-1,this.scene.gridDepth-w.j,this.scene.gridHeight,w.zIndex))
	      }
	      
	      var fl:int = this.scene.floors.length 
	      for(i=0;i<fl;i++) {
	      	var f:fFloor = this.scene.floors[i]
	      	if(f.k!=0) {
	      		sortAreas[sortAreas.length] = (new fSortArea(f.i,f.j,f.k,f.gWidth-1,f.gDepth-1,this.scene.gridHeight-f.k,f.zIndex))
	      		sortAreas[sortAreas.length] = (new fSortArea(0,f.j,0,f.i-1,this.scene.gridDepth-f.j,this.scene.gridHeight,f.zIndex))
	      		sortAreas[sortAreas.length] = (new fSortArea(f.i,f.j+f.gDepth,0,f.gWidth-1,this.scene.gridDepth-f.j-f.gDepth,this.scene.gridHeight,f.zIndex))
	      	}
	      }

	      // Split sortAreas per row, for faster lookups
	      sortAreas.sortOn("zValue",Array.DESCENDING | Array.NUMERIC)
	      this.scene.sortAreas = new Array
	      
	      var sw:int = this.scene.gridWidth 
	      for(i=0;i<sw;i++) {
	      	var temp:Array = new Array
	      	var sal:int = sortAreas.length 
	      	for(j=0;j<sal;j++) {
	      		var s:fSortArea = sortAreas[j]
	      		if(i>=s.i && i<=(s.i+s.width)) temp[temp.length] = s
	      	}
	      	this.scene.sortAreas[i] = temp
	      }

	      // Set depth of objects and characters and finish zSort
	      var ol:int = this.scene.objects.length
				for(var j:int=0;j<ol;j++) (this.scene.objects[j] as fObject).updateDepth()
				
				var cl:int = this.scene.characters.length
				for(j=0;j<cl;j++) (this.scene.characters[j] as fCharacter).updateDepth()
				
				// Dispose resources
				this.scene = null
				this.verticals = null
				this.horizontals = null
				this.sortArray = null
				this.duplicateSortArray = null

				// Events
        this.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,100,fSceneGridSorter.SORTDESCRIPTION,100,fSceneGridSorter.SORTDESCRIPTION))
				this.dispatchEvent(new Event(Event.COMPLETE))
			
			}

	}


}