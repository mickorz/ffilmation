// RENDER AND ZSORT LOGIC
package org.ffilmation.engine.core.sceneLogic {


		// Imports
		import flash.events.*
		import flash.display.*
		import flash.utils.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.logicSolvers.visibilitySolver.*
		import org.ffilmation.engine.logicSolvers.coverageSolver.*
		

		/**
		* This class manages which elements are visible inside the viewport, zSorts them, and calls
		* methods from the render engine to create/destroy their graphic assets
		* @private
		*/
		public class fSceneRenderManager {	
			
			// Properties
			private var scene:fScene												// Reference to the scene being managed
			private var range:Number												// The range of visible elements for the current viewport size
			private var depthSortArr:Array									// Array of elements for depth sorting
			private var elementsV:Array											// An array of the elements currently visible
			private var charactersV:Array										// An array of the characters currently visible
			private var cell:fCell													// The cell where the camera is
			private var renderEngine:fEngineRenderEngine		// A reference to the render engine
			
			// Constructor
			public function fSceneRenderManager(scene:fScene):void {
				this.scene = scene
				this.renderEngine = this.scene.renderEngine

		    this.depthSortArr = new Array
		    this.elementsV = new Array          
		    this.charactersV = new Array

			}
			
			// Receives the viewport size for this scene
			public function setViewportSize(width:Number,height:Number):void {
				this.range = Math.sqrt(width*width+height*height)/(2*fEngine.DEFORMATION)
			}
			
			// This method is called when the scene is to be rendered and its render engine is ready
			public function initialize():void {
		    this.depthSortArr = new Array
		    this.elementsV = new Array          
		    this.charactersV = new Array
		    
		    // This is temporal
		    this.depthSort()
		              
			}

			// Process new cell for cameras. It is only called when the scene is being rendered, so it can assume that
			// assets do exist
			public function processNewCellCamera(cam:fCamera):void {
				
				 // Disabled
				 return
				
			   // Init
			   this.cell = cam.cell
			   var x:Number, y:Number,z:Number
				 var tempElements:Array

				 try {
			    x = this.cell.x
			    y = this.cell.y
			    z = this.cell.z
			   } catch (e:Error) {
			    x = cam.x
			    y = cam.y
			    z = cam.z
			   }
			   
			   if(this.cell==null) {
			      // Camera outside grid
			      tempElements = fVisibilitySolver.calcVisibles(this.scene,x,y,z,this.range)
			   } 
			   else {
			      // Camera enters new cell
			      if(!this.cell.visibleElements || this.cell.visibleRange<this.range) this.scene.getVisibles(this.cell,this.range)
			      tempElements = this.cell.visibleElements
			   }
			   
			   var anyChanges:Boolean = false
			   
			   // Step 1: static elements
			   
			   // Update list of elements close enough
		     var newElementsV = []
			   var nEl:int = tempElements.length
			   for(var nElements:int=0;nElements<nEl && tempElements[nElements].distance<this.range;nElements++) {
	     			newElementsV[newElementsV.length] = tempElements[nElements].obj
		     }			   
			   
		     // Hide elements no longer within range (if they where visible) 
		     nEl = this.elementsV.length
		     for(i2=0;i2<nEl;i2++) {
		     	var ele:fRenderableElement = this.elementsV[i2]
		     	var pos:int = newElementsV.indexOf(ele)
		     	if((pos<0 || pos>=nElements) && ele._visible) {
		     		
		     		// Remove asset
		     		this.renderEngine.hideElement(ele)
		     		this.removeFromDepthSort(ele)
		     		anyChanges = true
		     		
		     	}
		     }
			   
		     // Show elements that are now within camera range and are visible
		     for(var i2:int=0;i2<nElements;i2++) {
		     	ele = newElementsV[i2]
		     	if(this.elementsV.indexOf(ele)<0 && ele._visible) {

		     		// Add asset
		     		this.renderEngine.showElement(ele)
		     		this.addToDepthSort(ele)
		     		anyChanges = true
		     		
		     	}
		     }

			   // Update list
			   this.elementsV = newElementsV
				 
				 // Step 2: Characters			   
				 
			   var chLength:int = scene.characters.length
			   var character:fCharacter
			   
			   var newV:Array = []
			   for(i2=0;i2<chLength;i2++) {
			   		// Is character within range ?
			   		character = scene.characters[i2]
			   		if(character.distanceTo(x,y,z)<this.range) newV[newV.length] = character
			   }
			   
		     // Hide characters no longer within range (if they where visible) 
		     nEl = this.charactersV.length
		     for(i2=0;i2<nEl;i2++) {
		     	character = this.charactersV[i2]
		     	if(newV.indexOf(character)<0 && character._visible) {
		     		
		     		// Remove asset
		     		this.renderEngine.hideElement(character)
		     		this.removeFromDepthSort(character)
		     		anyChanges = true
		     		
		     	}
		     }
			   
		     // Show characters that are now within camera range and are visible
		     nElements = newV.length
		     for(i2=0;i2<nElements;i2++) {
		     	character = newV[i2]
		     	if(this.charactersV.indexOf(ele)<0 && character._visible) {

		     		// Add asset
		     		this.renderEngine.showElement(character)
		     		this.addToDepthSort(character)
		     		anyChanges = true
		     		
		     	}
		     }

			   // Update list
			   this.charactersV = newV
			   
			   // Redo depth sort if needed
				 if(anyChanges) this.depthSort()
			   

			}
			
			// Process
			public function processNewCellCharacter(character:fCharacter):void {
				
		 		 // Change depth of object
		 		 if(character.cell!=null) character.setDepth(character.cell.zIndex)
		 		 
		 		 // If not visible, we don't care
		 		 return
		 		 if(!character._visible) return

		   	 var x:Number, y:Number,z:Number
		     x = this.cell.x
			   y = this.cell.y
			   z = this.cell.z
		 		 
		 		 // Inside range ?
		 		 if(character.distanceTo(x,y,z)<this.range) {
		 		 	
		 		 		// Create if it enters the screen
		 		 		if(this.charactersV.indexOf(character)<0) {
		 		 			
			   			this.charactersV[this.charactersV.length] = character
			   			this.renderEngine.showElement(character)
			   			this.addToDepthSort(character)
			   			
			   			// Redo depth sort
			   			this.depthSort() 
		 		 			
		 		 		}
		 		 	
		 		 } else {
		 		 	
		 		 		// Destroy if it leaves the screen
				 		var pos:int = this.charactersV.indexOf(character)
				 		if(pos>=0) {
				 			
				 			this.charactersV.splice(pos,1)
							this.renderEngine.hideElement(character)
							this.removeFromDepthSort(character)          
				   		
				   		// Redo depth sort
				   		this.depthSort() 

		 		 		}
		 		 	
		 		 }
		 		 

			}		

			// Listens to elements made visible and adds assets to display list if they are within display range
			public function showListener(evt:Event):void {
				 var ele:fRenderableElement = evt.target as fRenderableElement
			 
			   		this.renderEngine.showElement(ele)
			   		this.addToDepthSort(ele)
						return

		   	 var x:Number, y:Number,z:Number
		     x = this.cell.x
			   y = this.cell.y
			   z = this.cell.z

				 if(ele.distanceTo(x,y,z)<this.range) {
			   		
			   		this.renderEngine.showElement(ele)
			   		this.addToDepthSort(ele)
			   		if(ele is fCharacter) this.charactersV[this.charactersV.length] = ele as fCharacter
			   		else this.elementsV[this.elementsV.length] = ele
			   		
			   		// Redo depth sort
			   		//this.depthSort() 
			   }
			}
			
			// Listens to elements made invisible and removes assets to display list if they were within display range
			public function hideListener(evt:Event):void {
				
				 var ele:fRenderableElement = evt.target as fRenderableElement

							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
							return

				 if(ele is fCharacter) {
				 		var ch:fCharacter = ele as fCharacter
				 		var pos:int = this.charactersV.indexOf(ch)
				 		if(pos>=0) {
				 			this.charactersV.splice(pos,1)
							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
				   		// Redo depth sort
				   		//this.depthSort() 
				 		}
				 } else {
				 		pos = this.elementsV.indexOf(ele)
				 		if(pos>=0) {
				 			this.charactersV.splice(pos,1)
							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
				   		// Redo depth sort
				   		//this.depthSort() 
				 		}
				 }

			}

			// Listens to elements being removed on the fly
			public function removedItem(ele:fRenderableElement):void {
				
							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
							return


				 if(ele is fCharacter) {
				 		var ch:fCharacter = ele as fCharacter
				 		var pos:int = this.charactersV.indexOf(ch)
				 		if(pos>=0) {
				 			this.charactersV.splice(pos,1)
							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
				   		// Redo depth sort
				   		this.depthSort() 
				 		}
				 } else {
				 		pos = this.elementsV.indexOf(ele)
				 		if(pos>=0) {
				 			this.charactersV.splice(pos,1)
							this.renderEngine.hideElement(ele)
							this.removeFromDepthSort(ele)          
				   		// Redo depth sort
				   		this.depthSort() 
				 		}
				 }

			}

			// Adds an element to the depth sort array
			public function addToDepthSort(item:fRenderableElement):void {				

				if(this.depthSortArr.indexOf(item)<0) {
				 	this.depthSortArr.push(item)
			   	item.addEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener,false,0,true)
			  }
			
			}

			// Removes an element from the depth sort array
			public function removeFromDepthSort(item:fRenderableElement):void {				
				
				 this.depthSortArr.splice(this.depthSortArr.indexOf(item),1)
			   item.removeEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener)
			
			}

			// Listens to renderableitems changing its depth
			public function depthChangeListener(evt:Event):void {
				
				var el:fRenderableElement = evt.target as fRenderableElement
				var oldD:int = el.depthOrder
				this.depthSortArr.sortOn("_depth", Array.NUMERIC)
				var newD:int = this.depthSortArr.indexOf(el)
				if(newD!=oldD) {
					el.depthOrder = newD
					this.scene.container.setChildIndex(el.container, newD)
				}
				
			}
			
		  // Depth sorts all elements currently displayed
			public function depthSort():void {

				var ar:Array = this.depthSortArr
				ar.sortOn("_depth", Array.NUMERIC)
    		var i:int = ar.length;
    		var p:Sprite = this.scene.container
    		
    		while(i--) {
        	p.setChildIndex(ar[i].container, i)
        	ar[i].depthOrder = i
        }
				
			}
			
			// Frees resources
			public function dispose():void {			
				for(var i:int=0;i<this.depthSortArr.length;i++) delete this.depthSortArr[i]
				this.depthSortArr = null
				for(i=0;i<this.elementsV.length;i++) delete this.elementsV[i]
				this.elementsV = null
				for(i=0;i<this.charactersV.length;i++) delete this.charactersV[i]
				this.charactersV = null
				this.cell = null
			}

		}

}
