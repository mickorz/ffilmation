// COLLISION PARSER
package org.ffilmation.engine.core.sceneInitialization {
	
		// Imports
		import flash.xml.*
		import flash.geom.*
		import flash.display.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.elements.*
		
		/**
		* <p>The fSceneCollisionParser class contains static methods that fill the scene's grid with collision information of planes and objects.</p>
		* @private
		*/
		public class fSceneCollisionParser {		


			/** Updates an scene's grid with collision information from its elements */
			public static function calculate(scene:fScene):void {

		  	 // Update grid with object collision information
			   for(var j:Number=0;j<scene.objects.length;j++) {
			   		var ob:fObject = scene.objects[j]
			   		var rz:int = ob.z/scene.levelSize
			   		var obi:int = ob.x/scene.gridSize
			   		var obj:int = ob.y/scene.gridSize
			   		var height:int = ob.height/scene.levelSize
			   		var rad:int = Math.ceil(ob.radius/scene.gridSize)
			   		
			   		for(var n:int=obj-rad;n<=obj+rad;n++) {
			   			for(var i:int=obi-rad;i<(obi+rad);i++) {
			   				for(var k:int=rz;k<=(rz+height);k++) {
			   					try {
			   						var cell:fCell = scene.getCellAt(i,n,k)
			   						cell.walls.objects.push(ob)
			   					} catch(e:Error) {
			   						//trace("Warning: "+ob.id+" extends out of bounds.")
			   					}
			   			  }
			   			}
			   	  }

			   }

				 // Update grid with floor collision information
			   for(j=0;j<scene.floors.length;j++) {
			   		var fl:fFloor = scene.floors[j]
			   		rz = fl.z/scene.levelSize
			   		for(i=fl.i;i<(fl.i+fl.gWidth);i++) {
			   			for(k=fl.j;k<(fl.j+fl.gDepth);k++) {
			   				cell = scene.getCellAt(i,k,rz)
			   				cell.walls.bottom = fl
			   				if(rz>0) {
			   					cell = scene.getCellAt(i,k,rz-1)
			   					cell.walls.top = fl
			   				}
			   		  }
			   		}
			   }
			   
				 // Update grid with wall collision information
			   for(j=0;j<scene.walls.length;j++) {
			   		var wl:fWall = scene.walls[j]
			   		height = wl.height/scene.levelSize
			   		rz = wl.z/scene.levelSize
			   		if(wl.vertical) {
			   			for(i=wl.j;i<(wl.j+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					
			   					try {
			   						cell = scene.getCellAt(wl.i,i,k)
			   						cell.walls.left = wl
			   					} catch(e:Error) {
			   				  }
			   					if(wl.i>0) {
			   						cell = scene.getCellAt(wl.i-1,i,k)
			   						cell.walls.right = wl
			   					}
			   				}
			   			}
			   		} else {
			   			for(i=wl.i;i<(wl.i+wl.size);i++) {
			   				for(k=rz;k<(rz+height);k++) {
			   					try {
			   						cell = scene.getCellAt(i,wl.j,k)
			   						cell.walls.up = wl
			   					} catch(e:Error) {
			   				  }

			   					if(wl.j>0) {
			   						cell = scene.getCellAt(i,wl.j-1,k)
			   						cell.walls.down = wl
			   					}
			   				}
			   			}
			   		}
				 }
				 
				 // End wall loop
				 

			}

	}

}			