// Basic renderable element class

package org.ffilmation.engine.elements {
	
		// Imports
	  import flash.display.*
		import flash.events.*
		import flash.geom.Point
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.events.*


		/** 
		* <p>A Character is a dynamic object in the scene. Characters can move and rotate, and can be added and
		* removed from the scene at any time. Live creatures and vehicles are the most common
		* uses for the fCharacter class.</p>
		*
		* <p>There are other uses for fCharacter: If you want a chair to be "moveable", for example, you
		* will have to make it a fCharacter.</p>
		*
		* <p>You can add the parameter dynamic="true" to the XML definition for any object you want to be able to move
		* later. This will force the engine to make that object a Character.</p>
		*
		* <p>The main reason of having different classes for static and dynamic objects is that static objects can be
		* added to the light rendering cache along with floors and walls, whereas dynamic objects (characters) can't.</p>
		*
		* <p>Don't use this class to implement bullets. Use the fBullet class.</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS ELEMENT DIRECTLY.<br>
		* Use scene.createCharacter() to add new characters to an scene.</p>
		*
		* @see org.ffilmation.engine.core.fScene#createCharacter()
		*
		*/
		public class fCharacter extends fObject {
			
			// Constants

			/**
 			* The fCharacter.COLLIDE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactercollide</code> event.
 			* The event is dispatched when the character collides with another element in the scene
 			* 
 			* @eventType charactercollide
 			*/
 		  public static const COLLIDE:String = "charactercollide"

			/**
 			* The fCharacter.WALKOVER constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>characterwalkover</code> event.
 			* The event is dispatched when the character walks over a non-solid object of the scene
 			* 
 			* @eventType characterwalkover
 			*/
 		  public static const WALKOVER:String = "characterwalkover"

			/**
 			* The fCharacter.EVENT_IN constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactereventin</code> event.
 			* The event is dispatched when the character enters a cell where an event was defined
 			* 
 			* @eventType charactereventin
 			*/
 		  public static const EVENT_IN:String = "charactereventin"

			/**
 			* The fCharacter.EVENT_OUT constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactereventout</code> event.
 			* The event is dispatched when the character leaves a cell where an event was defined
 			* 
 			* @eventType charactereventout
 			*/
 		  public static const EVENT_OUT:String = "charactereventout"

			
			
			// Public properties
			
			/** 
			* Numeric counter assigned by scene
			* @private
			*/
			public var counter:int
			
			/** 
			* Array of render cache. For each light in the scene, a list of elements that are shadowed by this character at its current position
			* @private
			*/
			public var vLights:Array
			
			// Constructor
			/** @private */
			function fCharacter(container:MovieClip,defObj:XML,scene:fScene):void {
				
				 // Characters are animated always
				 this.animated = true
				 
				 // Previous
				 super(container,defObj,scene)
				 
				 // Lights
				 this.vLights = new Array
				 
			}
			
			
			/*
			* Moves a character into a new position, ignoring collisions
			* 
			* @param x: New x coordinate
			*
			* @param y: New y coordinate
			*
			* @param z: New z coordinate
			*
			*/
			public function teleportTo(x:Number,y:Number,z:Number):void {
					var s:Boolean = this.solid
					this.solid = false
					this.moveTo(x,y,z)
					this.solid = s
			}


			/*
			* Characters can be moved
			* 
			* @param x: New x coordinate
			*
			* @param y: New y coordinate
			*
			* @param z: New z coordinate
			*
			*/
			/** @private */
			public override function moveTo(x:Number,y:Number,z:Number):void {
			   
				 // Last position
			   var lx:Number = this.x
			   var ly:Number = this.y
			   var lz:Number = this.z
			   
			   // Movement
			   var dx:Number = x-lx
			   var dy:Number = y-ly
			   var dz:Number = z-lz

			   if(dx==0 && dy==0 && dz==0) return
			   
			   
			   try {
			   	
			   		// Set new coordinates			   
			   		this.x = (x<0)?(0):(x)
			   		this.y = (y<0)?(0):(y)
			   		this.z = (z<0)?(0):(z)
			   		
 		 		 		var radius:Number = this.radius
 		 		 		var height:Number = this.height
         		
			   		if(this.x>=this.scene.width) this.x=this.scene.width-1
			   		if(this.y>=this.scene.depth) this.y=this.scene.depth-1
			   		this.top = this.z+height
         		
				 		// Check for collisions against other fRenderableElements
				 		if(this.solid) {
				 			
		 		 				var testCell:fCell,testElement:fRenderableElement, confirm:fCollision
		 		 				var primaryCandidates:Array = new Array
		 		 				var secondaryCandidates:Array = new Array
		 		 				
			 				  // Test against floors
			 				  if(dz<0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y,z)
				 						if(testCell.walls.top) primaryCandidates.push(testCell.walls.top)
				 					} catch (e:Error) {
				 						testCell = this.scene.translateToCell(this.x,this.y,0)
										primaryCandidates.push(testCell.walls.bottom)
				 					}
				 					
			 						if(testCell.walls.up) secondaryCandidates.push(testCell.walls.up)
			 						if(testCell.walls.down) secondaryCandidates.push(testCell.walls.down)
			 						if(testCell.walls.left) secondaryCandidates.push(testCell.walls.left)
			 						if(testCell.walls.right) secondaryCandidates.push(testCell.walls.right)
			 						
			 						var nobjects:Number = testCell.walls.objects.length
			 						for(var k:Number=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) secondaryCandidates.push(testCell.walls.objects[k])
         		
				 				}
				 			
				 				if(dz>0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y,z+height)
				 						if(testCell.walls.bottom) primaryCandidates.push(testCell.walls.bottom)	
			 							
			 							if(testCell.walls.up) secondaryCandidates.push(testCell.walls.up)
			 							if(testCell.walls.down) secondaryCandidates.push(testCell.walls.down)
			 							if(testCell.walls.left) secondaryCandidates.push(testCell.walls.left)
			 							if(testCell.walls.right) secondaryCandidates.push(testCell.walls.right)
			 							
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) secondaryCandidates.push(testCell.walls.objects[k])
         		
				 					} catch (e:Error) {
				 						
				 					}
				 					
				 				}
				 		
								var l:Number
								l = primaryCandidates.length
				 				var some:Boolean = false
				 				for(var j:Number=0;j<l;j++) {
				 					testElement = primaryCandidates[j]
				 					confirm = testElement.testPrimaryCollision(this,dx,dy,dz)
		  					  if(confirm!=null) {
		  					  	
		  					  	if(testElement.solid) {
		  					  		some = true
 											this.z = confirm.z
 											this.top = this.z+height
	 										dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,testElement))
	 									} else {
	 										dispatchEvent(new fWalkoverEvent(fCharacter.WALKOVER,true,true,testElement))
	 									}
		 							}
				 					
				 				}
         		
								// If no primary fCollisions were confirmed, test secondary
				 				if(!some) {
				 					
				 					// Test secondary fCollisions
								  l = secondaryCandidates.length
				 					for(j=0;j<l;j++) {
				 						testElement = secondaryCandidates[j]
				 						confirm = testElement.testSecondaryCollision(this,dx,dy,dz)
		  					  	if(confirm!=null && confirm.z>=0) {
		  					  		
			  					  	if(testElement.solid) {
 												this.z = confirm.z
 												this.top = this.z+height
 												dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,testElement))
 											} else {
 												dispatchEvent(new fWalkoverEvent(fCharacter.WALKOVER,true,true,testElement))
 											}
 												
 										}
				 					}
				 					
								}
								
								// Retrieve list of possible walls. Separate between primary and secondary
								primaryCandidates = new Array
								secondaryCandidates = new Array
								
				 				if(dx<0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x-radius,this.y,this.z)
				 						if(testCell.walls.right) primaryCandidates.push(testCell.walls.right)
			 						  
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.up && testCell.walls.up.y>(this.y-radius)) secondaryCandidates.push(testCell.walls.up)
				 						if(testCell.walls.down && testCell.walls.down.y<(this.y+radius)) secondaryCandidates.push(testCell.walls.down)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dx - 1")
				 					}	
				 					try {
			 							testCell = this.scene.translateToCell(this.x-radius,this.y,this.top)
				 						if(testCell.walls.right) primaryCandidates.push(testCell.walls.right)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
				 						
				 						if(testCell.walls.up && testCell.walls.up.y>(this.y-radius)) secondaryCandidates.push(testCell.walls.up)
				 						if(testCell.walls.down && testCell.walls.down.y<(this.y+radius)) secondaryCandidates.push(testCell.walls.down)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dx - 2")
				 					}	
         		
				 				}
         		
				 				if(dx>0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x+radius,this.y,this.z)
				 						if(testCell.walls.left) primaryCandidates.push(testCell.walls.left)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.up && testCell.walls.up.y>(this.y-radius)) secondaryCandidates.push(testCell.walls.up)
				 						if(testCell.walls.down && testCell.walls.down.y<(this.y+radius)) secondaryCandidates.push(testCell.walls.down)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dx + 1")
				 					}
         		
				 					try {
			 							testCell = this.scene.translateToCell(this.x+radius,this.y,this.top)
				 						if(testCell.walls.left) primaryCandidates.push(testCell.walls.left)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.up && testCell.walls.up.y>(this.y-radius)) secondaryCandidates.push(testCell.walls.up)
				 						if(testCell.walls.down && testCell.walls.down.y<(this.y+radius)) secondaryCandidates.push(testCell.walls.down)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dx + 2")
				 					}
         		
				 				}
         		
				 				if(dy<0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y-radius,this.z)
				 						if(testCell.walls.down) primaryCandidates.push(testCell.walls.down)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.left && testCell.walls.left.x>(this.x-radius)) secondaryCandidates.push(testCell.walls.left)
				 						if(testCell.walls.right && testCell.walls.right.x<(this.x+radius)) secondaryCandidates.push(testCell.walls.right)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dy - 1")
				 					}
         		
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y-radius,this.top)
				 						if(testCell.walls.down) primaryCandidates.push(testCell.walls.down)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.left && testCell.walls.left.x>(this.x-radius)) secondaryCandidates.push(testCell.walls.left)
				 						if(testCell.walls.right && testCell.walls.right.x<(this.x+radius)) secondaryCandidates.push(testCell.walls.right)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dy - 2")
				 					}
				 					
				 				}
         		
				 				if(dy>0) {
				 					
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y+radius,this.z)
				 						if(testCell.walls.up) primaryCandidates.push(testCell.walls.up)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.left && testCell.walls.left.x>(this.x-radius)) secondaryCandidates.push(testCell.walls.left)
				 						if(testCell.walls.right && testCell.walls.right.x<(this.x+radius)) secondaryCandidates.push(testCell.walls.right)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dy + 1")
				 					}
         		
				 					try {
				 						testCell = this.scene.translateToCell(this.x,this.y+radius,this.top)
				 						if(testCell.walls.up) primaryCandidates.push(testCell.walls.up)
         		
			 						  nobjects = testCell.walls.objects.length
			 						  for(k=0;k<nobjects;k++) if(testCell.walls.objects[k]._visible) primaryCandidates.push(testCell.walls.objects[k])
         		
				 						if(testCell.walls.left && testCell.walls.left.x>(this.x-radius)) secondaryCandidates.push(testCell.walls.left)
				 						if(testCell.walls.right && testCell.walls.right.x<(this.x+radius)) secondaryCandidates.push(testCell.walls.right)
				 						if(testCell.walls.top && testCell.walls.top.z<this.top) secondaryCandidates.push(testCell.walls.top)
				 						if(testCell.walls.bottom && testCell.walls.bottom.z>this.z) secondaryCandidates.push(testCell.walls.bottom)
				 					} catch (e:Error) {
				 						//trace("Error dy + 1")
				 					}
         		
				 				}
         		
								// Make primary unique
								var temp:Array = new Array
								l = primaryCandidates.length
								for(j=0;j<l;j++) if(temp.indexOf(primaryCandidates[j])<0) temp.push(primaryCandidates[j])
								primaryCandidates = temp
								l = primaryCandidates.length
				 				
				 				// Test primary fCollisions
				 				some = false
				 				for(j=0;j<l;j++) {
				 					
				 					testElement = primaryCandidates[j]
				 					confirm = testElement.testPrimaryCollision(this,dx,dy,dz)
		  					  if(confirm!=null) {
		  					  	
		  					  	if(testElement.solid) {
		  					  		some = true
	 										if(confirm.x>=0) this.x = confirm.x
	 										if(confirm.y>=0) this.y = confirm.y
	 										dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,testElement))
	 									} else {
	 										dispatchEvent(new fWalkoverEvent(fCharacter.WALKOVER,true,true,testElement))
	 									}
	 									
		 							}
				 					
				 				}
				 				
				 				// If no primary fCollisions were confirmed, test secondary
				 				if(!some) {
         		
									// Make secondary unique
									temp = new Array
									l = secondaryCandidates.length
									for(j=0;j<l;j++) if(temp.indexOf(secondaryCandidates[j])<0) temp.push(secondaryCandidates[j])
									secondaryCandidates = temp
									l = secondaryCandidates.length
         		
				 					// Test secondary fCollisions
				 					for(j=0;j<l;j++) {
				 						
				 						testElement = secondaryCandidates[j]
				 						confirm = testElement.testSecondaryCollision(this,dx,dy,dz)
		  						  if(confirm!=null) {
		  						  	
		  					  		if(testElement.solid) {
		  					  			some = true
	 											if(confirm.x>=0) this.x = confirm.x
	 											if(confirm.y>=0) this.y = confirm.y
	 											dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,testElement))
	 										} else {
	 											dispatchEvent(new fWalkoverEvent(fCharacter.WALKOVER,true,true,testElement))
	 										}
		 								}
				 						
				 					}
				 					
				 				}
				 				
				 				
         		
				 		} // End collison detection
				 		
         		
				 		// Delete projection cache
			 	 		this.projectionCache = new fObjectProjectionCache				 
         		
			   		// Check if element moved into a different cell
			   		var cell:fCell = this.scene.translateToCell(this.x,this.y,this.z)
			   		if(cell!=this.cell || this.cell == null || cell==null) {
				 		
				 				// Check for XML events in cell we leave
				 				if(this.cell!=null) {
				 					k = this.cell.events.length
				 					for(var i:Number=0;i<k;i++) {
				 						var evt:fCellEventInfo = this.cell.events[i]
				 						dispatchEvent(new fEventOut(fCharacter.EVENT_OUT,true,true,evt.name,evt.xml))
				 					}
				 				}
         		
				 				this.cell = cell
				 				dispatchEvent(new Event(fElement.NEWCELL))
				 				
				 				// Check for XML events in new cell
				 				if(this.cell!=null) {
				 					k = this.cell.events.length
				 					for(i=0;i<k;i++) {
				 						evt = this.cell.events[i]
				 						dispatchEvent(new fEventIn(fCharacter.EVENT_IN,true,true,evt.name,evt.xml))
				 					}
				 				}
         		
				 		}
				 		
			   		// Update sprite
			   		var coords:Point = this.scene.translateCoords(this.x,this.y,this.z)
			   		this.container.x = coords.x
			   		this.container.y = coords.y
         		
				 		// Dispatch move event
				 		if(this.x!=lx || this.y!=ly || this.z!=lz) dispatchEvent(new fMoveEvent(fElement.MOVE,true,true,this.x-lx,this.y-ly,this.z-lz))
				 
			  } catch(e:Error) {
			  		
			  		// This means we tried to move outside scene limits
			  		this.x = lx
			  		this.y = ly
			  		this.z = lz
			  		dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,null))
			  		
			  }
				 
			}
		
	}	
		
}