// LEVEL

package org.ffilmation.engine.helpers {

		// Imports
		import flash.events.*
		import flash.display.*
		import flash.utils.getDefinitionByName
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Helps process the XML definition file and build the scene. Contains Z-sorting algorythm
		*
		* After the scene is loaded, it is not used anymore
		*/
		public class fLevel extends EventDispatcher {  	
		
			// Private properties
			private var scene:fScene      // Pointer to scene
			private var gridSize:int
			private var levelSize:int

			private var _orig_container:Sprite    // Backup reference
			private var container:Sprite          // Were scene is drawn
			private var zIndexOffset:int
			private var zIndex:int

			private var width:int									// Size
			private var depth:int								
			
			// Internal properties
			
			public var top:int										// Highest height of this level
			public var id:String								  // fLevel id
			
			// Temp			
			private var exploredRow:int

			// Public properties
			public var i:Number										// fLevel coordinates in cells
			public var j:Number
			public var k:Number
			public var x:int											// Position
			public var y:int											
			public var z:int

			public var grid:Array                // Grid ( for collisions and visibility )   
			public var floors:Array							 // List of all floors
			public var verticals:Array           // List of vertical walls
			public var horizontals:Array         // List of horizontal walls
			public var walls:Array               // List of all walls
			public var objects:Array             // List of objects
			public var characters:Array          // List of characters
			public var all:Array                 // Everything ( for 'id' access )

			public var gridWidth:int						 // Grid size in pixels
			public var gridHeight:int
			public var gWidth:int								 // Grid size in cells
			public var gDepth:int
			
			// Static properties
			private static var count:Number = 1

			// Constructor
			function fLevel(container:Sprite,data:fTempLevelData,scene:fScene,zIndexOffset:int,gridWidth:int,gridHeight:int):void {
			
			   // Init properties
			   this._orig_container = container           
			   this.container = container                 
				 this.scene = scene                  
					
				 this.gridSize = this.scene.gridSize
				 this.levelSize = this.scene.levelSize
			   this.gridWidth = gridWidth
			   this.gridHeight = gridHeight
				 this.gWidth = 0
			   this.gDepth = 0
				 this.i = Infinity
			   this.j = Infinity
			   this.zIndexOffset = zIndexOffset
			   this.z = data.z
			   this.k = Math.round(this.z/scene.levelSize)
			   this.z = scene.levelSize*this.k
			   this.top = 0  
			   
			   this.id = "fLevel_"+(fLevel.count++)			    

				 // Init arrays
			   this.grid = new Array()
			   this.floors = new Array()
			   this.verticals = new Array()
			   this.horizontals = new Array()
			   this.walls = new Array()
			   this.objects = new Array()
			   this.characters = new Array()
			   this.all = new Array()

			   // Setup floor (pieces )
			   var floorObj:Array = data.floors
			   for(var i:Number=0;i<floorObj.length;i++) {
			   	    var spr:MovieClip = new MovieClip()
			   	    spr.mouseEnabled = false
			   	    this.container.addChild(spr)
							this.addFloor(floorObj[i],spr)
			   			if(this.i>this.floors[i].i) this.i = this.floors[i].i
			   			if(this.j>this.floors[i].j) this.j = this.floors[i].j
			   			if(this.gWidth<(this.floors[i].i+this.floors[i].gWidth)) this.gWidth = this.floors[i].i+this.floors[i].gWidth
			   			if(this.gDepth<(this.floors[i].j+this.floors[i].gDepth)) this.gDepth = this.floors[i].j+this.floors[i].gDepth
				 }
				 this.gWidth-=this.i
				 this.gDepth-=this.j
			   this.x = this.i*scene.gridSize
			   this.y = this.j*scene.gridSize
			   this.width = scene.gridSize*this.gWidth
			   this.depth = scene.gridSize*this.gDepth
			
				 // Setup grid
				 this.createGrid()
			
			   // Add walls
			   var wallObj:Array = data.walls
			   for(i=0;i<wallObj.length;i++) {
			   	  spr = new MovieClip()
			   	  this.container.addChild(spr)
			   		this.addWall(wallObj[i],spr)
			   }
			   
			   // Sort horizontal walls ( bubble algorythm )
			   var changes:Boolean
         var one:fWall
         var two:fWall

			   do {
			      changes = false
			      for(i=0;i<(this.horizontals.length-1);i++) {
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
			
			   // Add objects and characters
			   var objObj:Array = data.objects
			   for(i=0;i<objObj.length;i++) {
			   		spr = new MovieClip()
		   	    this.container.addChild(spr)
			   		if(objObj[i].@dynamic=="true") this.addCharacter(objObj[i],spr)
			   		else this.addObject(objObj[i],spr)
			   }
			
			   objObj = data.characters
			   for(i=0;i<objObj.length;i++) {
			   		spr = new MovieClip()
		   	    this.container.addChild(spr)
			   		this.addCharacter(objObj[i],spr)
			   }
			
			}
			

			// Create grid for this level
			public function createGrid():void {
				
			   // Calculate size and collision of floor shape (if undefined)
			   if(this.gridWidth==0) this.gridWidth = Math.round(this.width/this.gridSize)
			   if(this.gridHeight==0) this.gridHeight = Math.round(this.depth/this.gridSize)
			   
			   // One cell more for walls ( see this.zSort() )
			   for(var i:Number=0;i<=this.gridWidth;i++) {
			      this.grid[i] = new Array()
			      for(var j:Number=0;j<=this.gridHeight;j++) {  
			
			         // Setup cell parameters
			         this.grid[i][j] = new fCell()
			   
			         // Initial Z-Index
			         this.grid[i][j].zIndex = this.computeZIndex(i,j,this.gridWidth,this.gridHeight)
			
			      }
			   }
			
			}
			
			// Part of zSorting algorythm
			private function computeZIndex(i:int,j:int,ow:int,oh:int):int {
				
				 //return (2+this.floors.length)*mathUtils.distance(i,j,i,0)
			   return (2+this.floors.length)+((ow-i+1)+(j*ow+2))*this.scene.maxElementsPerfCell
			}
			
			
			// Part of zSorting algorythm
			public function setZ(z:int):void {
			   //trace(this.id+" setZ "+z)
			   for(var i:Number=0;i<this.floors.length;i++) this.floors[i].setZ(z+i)
			   this.zIndex = z
			   for(i=0;i<=this.gridWidth;i++) {
			      for(var j:Number=0;j<=this.gridHeight;j++) {
			         this.grid[i][j].zIndex+=z
			      }
			   }
			}
			
			// Part of zSorting algorythm
			public function getMaxZIndex():int {
			   return this.grid[this.i][this.j+this.gDepth-1].zIndex
			}
			
			// Part of zSorting algorythm
			public function propagateZ(ci:int,cij:int,cji:int,cj:int,z:int):void {
			   
			   // Propagate into grid
			   for(var i:Number=0;i<ci;i++) {
			      // Potser és for "cji"
			      var ini:Number = cji
			      if(this.z!=0 && this.floors[0].j<ini) ini=this.floors[0].j
			      for(var j:Number=ini;j<=this.gridHeight;j++) {
			         this.grid[i][j].zIndex+=z
			      }
			   }
			   for(i=ci;i<=cij;i++) {
			      for(j=cj+1;j<=this.gridHeight;j++) {
			         this.grid[i][j].zIndex+=z
			      }
			   }
			   
			   // Propagate into walls
			   this.exploredRow = ci
			   
			   var wall:fWall
			   var newZ:Number
			   for(i=this.horizontals.length-1;i>=0;i--) {
			      if(((this.horizontals[i].i+this.horizontals[i].size)<=ci && this.horizontals[i].j>cji) || (this.horizontals[i].j>cj && this.horizontals[i].i<cij)) {
			         //trace(this.horizontals[i].id+" passa de "+this.horizontals[i].zIndex+" a "+(this.horizontals[i].zIndex+z))
			         wall = this.horizontals[i]
			         newZ = wall.zIndex+z
			         wall.setZ(newZ)
			         
    			     // Change ZIndex of cells below to be bigger
			         for(var i2:Number=0;i2<wall.i+wall.size;i2++)
			           for(j=wall.j;j<=this.gridHeight;j++)
			             this.grid[i2][j].zIndex= Math.max(this.grid[i2][j].zIndex,newZ+this.computeZIndex(i2,j-wall.j,wall.i+wall.size,this.gridHeight-wall.j));
			             
					    // Must redo other vertical walls ?
					    for(j=0;j<this.verticals.length;j++) {
					       var wall2:fWall = this.verticals[j]
					       if(wall2.i>=wall.i && ( wall2.i<(wall.i+wall.size)) && (wall2.j>=wall.j)) this.zSortVertical(j)
					    }
					
					    // Must redo other horizontal walls ?
					    for(j=i+1;j<this.horizontals.length;j++) {
					      wall2 = this.horizontals[j]
					      if(wall2.j>wall.j && wall2.i<(wall.i+wall.size) && wall2.i>=cij) this.zSortHorizontal(j)
					    }
			             
			      }
			   }
			   
			   for(i=0;i<this.verticals.length;i++) {
			      if((this.verticals[i].i<=ci && (this.verticals[i].j+this.verticals[i].size>cji)) || (this.verticals[i].j>cj && this.verticals[i].i<cij)) {
			         //trace(this.verticals[i].id+" passa de "+this.verticals[i].zIndex+" a "+(this.verticals[i].zIndex+z))
 			         wall = this.verticals[i]
			         newZ = wall.zIndex+z
			         wall.setZ(newZ)
			         
 							 // Change ZIndex of cells below to be bigger
			         for(j=wall.j;j<=this.gridHeight;j++) 
			            for(i2=wall.i-1;i2>=0;i2--) 
			             this.grid[i2][j].zIndex=Math.max(this.grid[i2][j].zIndex,newZ+this.computeZIndex(i2,j-wall.j,wall.i,this.gridHeight-wall.j));

					     // Must redo other vertical walls ?
					     for(j=0;j<this.verticals.length;j++) {
					        wall2 = this.verticals[j]
					        if((wall2.j<wall.j) && wall2.i<wall.i && (wall2.j+wall2.size)>wall.j) this.zSortVertical(j)
					     }
					     
					     // Must redo other horizontal walls ?
					     for(j=0;j<this.horizontals.length;j++) {
					        wall2 = this.horizontals[j]
					        if(wall2.j>wall.j && wall2.i<wall.i) this.zSortHorizontal(j)
					     }
			         
			      }
			   } 
			
			   // Propagate into floor
			   
/*			   for(i=0;i<this.floors.length;i++) {
			   	  var f:fFloor = this.floors[i]
			   	  if((f.i+f.gWidth)<=ci  || f.j>cj) {
		 		        //trace("Terra "+i+" de "+this.id+" passa a "+(this.floors[i].zIndex+z))
			   	 			this.floors[i].setZ(this.floors[i].zIndex+z)
						} else {
								//trace("Terra "+i+" de "+this.id+" es queda igual.")
						}
						
			   }*/
			   
/*			   for(i=0;i<this.floors.length;i++) {
			   	  var f:fFloor = this.floors[i]
			   	  if((f.i+f.gWidth<=ci && f.j>cji) || (f.j>cj)) {
			   	 			this.floors[i].setZ(this.floors[i].zIndex+z)
						}
			   }*/
			   
			
			}
			
			// Sorts walls, assigns zIndexes to all cells
			public function zSort():void {
			
			   // Start assigning zIndexes to walls and cells
			   var lastHorizontal:Number = 0
			   for(var count:Number=0;count<=this.gridHeight;count++) {
			
			      // Explore this row
			      this.exploredRow = count
			      while(lastHorizontal<this.horizontals.length && this.horizontals[lastHorizontal].j==this.exploredRow) {
			         // Change zIndex of wall
			         this.zSortHorizontal(lastHorizontal)
			         lastHorizontal++
			      }
			
			      for(var lastVertical:Number=0;lastVertical<this.verticals.length;lastVertical++) {
			         if(this.verticals[lastVertical].j==this.exploredRow) {
			            // Change zIndex of wall
			            this.zSortVertical(lastVertical)
			         }
			      }
			      
			   }
			   
			}
			
			// Part of zSorting algorythm
			private function zSortHorizontal(wid:int):void {
			    var wall:fWall = this.horizontals[wid]
			    var newZ:Number = this.grid[wall.i][wall.j].zIndex
			    wall.setZ(newZ)
			    // Change ZIndex of cells below to be bigger
			    for(var i:Number=0;i<wall.i+wall.size;i++)
			       for(var j:Number=wall.j;j<=this.gridHeight;j++)
			         try {
			         	 this.grid[i][j].zIndex= Math.max(this.grid[i][j].zIndex,newZ+this.computeZIndex(i,j-wall.j,wall.i+wall.size,this.gridHeight-wall.j));
			         } catch(e:Error) {
			         }
			
			    // Must redo previous vertical walls ?
			    for(j=0;j<this.verticals.length;j++) {
			       var wall2:fWall = this.verticals[j]
			       if(wall.j<this.exploredRow && wall2.i<wall.i && (wall2.j+wall2.size)>wall.j) this.zSortVertical(j)
			    }
			
			    // Must redo previous horizontal walls ?
			    for(j=0;j<this.horizontals.length;j++) {
			      wall2 = this.horizontals[j]
			      if(wall2.j>wall.j && wall2.i<(wall.i+wall.size) && wall2.j<this.exploredRow) this.zSortHorizontal(j)
			    }
			}
			
			// Part of zSorting algorythm
			private function zSortVertical(wid:int):void {
			    var wall:fWall = this.verticals[wid]
			    var newZ:Number
			    if(wall.i!=0) {
			       newZ = this.grid[wall.i-1][wall.j+wall.size-1].zIndex 
			       wall.setZ(newZ)                        
			       // Change ZIndex of cells below to be bigger
			       for(var j:Number=wall.j;j<=this.gridHeight;j++) {
			          for(var i:Number=wall.i-1;i>=0;i--) 
      			       try {
			             	this.grid[i][j].zIndex=Math.max(this.grid[i][j].zIndex,newZ+this.computeZIndex(i,j-wall.j,wall.i,this.gridHeight-wall.j));
			             } catch(e:Error) {
			             }
			       }
			    } else {
			       newZ = this.grid[wall.i][wall.j+wall.size-1].zIndex 
			       wall.setZ(newZ+1)
			    }
			
			    // Must redo previous vertical walls ?
			    for(j=0;j<this.verticals.length;j++) {
			       var wall2:fWall = this.verticals[j]
			       if((wall2.j<this.exploredRow) && wall2.i<wall.i && (wall2.j+wall2.size)>wall.j) this.zSortVertical(j)
			    }
			
			    // Must redo previous horizontal walls ?
			    for(j=0;j<this.horizontals.length;j++) {
			       wall2 = this.horizontals[j]
			       if(wall2.j<=this.exploredRow && wall2.j>wall.j && wall2.i<wall.i) this.zSortHorizontal(j)
			    }
			}
			
			// Create floor
			private function addFloor(definitionObject:XML,container:MovieClip):void {
			
			   var nFloor:fFloor = new fFloor(container,definitionObject,this.scene,this.z)

         this.floors[this.floors.length] = nFloor
			   this.all[floors.id] = nFloor			   
			
			}
			
			// Adds a wall object to this level
			private function addWall(definitionObject:XML,container:MovieClip):void {
			   
	       var nWall:fWall = new fWall(container,definitionObject,this.scene)

			   // Add to lists
			   if(nWall.vertical) this.verticals[this.verticals.length] = nWall
			   else this.horizontals[this.horizontals.length] = nWall
			   this.walls[this.walls.length] = nWall
			   this.all[nWall.id] = nWall
			
			   if(nWall.top>this.top) this.top = nWall.top
			
			}   
			
			// Adds an object to this level
			private function addObject(definitionObject:XML,container:MovieClip):void {
			
			   var nObject = new fObject(container,definitionObject,this.scene,this)
			   
			   // Add to lists
			   this.objects[this.objects.length] = nObject
			   this.all[nObject.id] = nObject

			   if(nObject.top>this.top) this.top = nObject.top
			
			}
    	
			// Adds a character to this level
			private function addCharacter(definitionObject:XML,container:MovieClip):void {
			
			   var nCharacter = new fCharacter(container,definitionObject,this.scene,this)
			   
			   // Add to lists
			   this.characters[this.characters.length] = nCharacter
			   this.all[nCharacter.id] = nCharacter
			
			}


	}
}
