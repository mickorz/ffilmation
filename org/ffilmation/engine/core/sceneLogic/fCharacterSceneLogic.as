// CHARACTER LOGIC
package org.ffilmation.engine.core.sceneLogic {


		// Imports
		import flash.events.*
		import flash.display.*
		import flash.utils.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.logicSolvers.visibilitySolver.*
		import org.ffilmation.engine.logicSolvers.coverageSolver.*
		

		/**
		* This class stores static methods related to characters in the scene
		* @private
		*/
		public class fCharacterSceneLogic {	

			
			// Process New cell for Characters
			public static function processNewCellCharacter(scene:fScene,character:fCharacter,forceReset:Boolean = false):void {
			
				 // Init
				 var light:fOmniLight, elements:Array, nEl:int, distL:Number, range:Number,x:Number, y:Number, z:Number
				 var cache:fCharacterShadowCache, oldCache:fCharacterShadowCache, elementsV:Array, el:fPlane
				 var s:Number, len:int,i:int,i2:int

		 		 // Change depth of object
		 		 if(character.cell!=null) character.setDepth(character.cell.zIndex)
		 		 
			   // Count lights close enough
			   for(i2=0;i2<scene.lights.length;i2++) {
			   	
			   		light = scene.lights[i2]
			   		
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
			   			
		   		    // Add light
			   		  scene.renderEngine.lightIn(character,light)
			   			
			   			if(light.cell) {
			   				x = light.cell.x
			        	y = light.cell.y
			        	z = light.cell.z
			        } else {
			   				x = light.x
			        	y = light.y
			        	z = light.z
			        }
			   			
							if(!forceReset && cache.character==character && cache.cell==light.cell) {
				   		 	
				   		 	  // Cache is still valid, no need to update
				   		 	
				   		} else {
				   			
				   			 
				   			  // Cache is outdated. Update it
				   		 	  cache.clear()
				   		 	  cache.cell = light.cell
				   		 	  cache.character = character

				   		    if(fEngine.characterShadows) {
                  
							    	// Add visibles from foot
							    	if(!character.cell.visibleObjs || character.cell.visibleRange<range) {
							    		scene.calcVisibles(character.cell,range)
							    	}
			            	elementsV = character.cell.visibleObjs
				   		    	nEl = elementsV.length
				   		    	for(i=0;i<nEl && elementsV[i].distance<range;i++) {
                  	
				   		    			try {
				   		    				el = elementsV[i].obj
				   	      				// Shadows of scene character upon other elements
				   	      			 	if(fCoverageSolver.calculateCoverage(character,el,x,y,z) == fCoverage.SHADOWED) cache.addElement(el)
				   	      			} catch(e:Error) {
				   	      			}
                  	
				   		    	}
				   		    	
							    	// Add visibles from top
							    	try {
							    		var topCell:fCell = scene.translateToCell(character.x,character.y,character.top)
							    		if(!topCell.visibleObjs  || topCell.visibleRange<range) {
							    			scene.calcVisibles(topCell,range)
							    		}
			            		elementsV = topCell.visibleObjs
				   		    		nEl = elementsV.length
				   		    		for(i=0;i<nEl && elementsV[i].distance<range;i++) {
                  		
				   		    				try {
				   		    					el = elementsV[i].obj
				   	      					// Shadows of scene character upon other elements
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
			   		  if(scene.IAmBeingRendered) scene.renderEngine.lightOut(character,light)
			   		  
			   		}

	  				// Delete shadows from scene character that are no longer visible
			   		oldCache = character.vLights[light.counter]
			   		if(oldCache!=null) {
						 	elements = oldCache.elements
						 	nEl = elements.length
		   	 		 	for(var i3:Number=0;i3<nEl;i3++) {
			   					if(cache.elements.indexOf(elements[i3])<0) {
			   						scene.renderEngine.removeShadow(elements[i3],light,character)
			   					}
		   	 			}
		   	 		}
			   	  
			   	  // Update cache
			   	  character.vLights[light.counter] = light.vCharacters[character.counter] = character.cell.characterShadowCache[light.counter] = cache

			   }
			   
				 // Update occlusion for scene character
				 var oldOccluding:Array = character.currentOccluding
				 var newOccluding:Array = new Array
				 try {
				 	var newOccluding2:Array = character.cell.elementsInFront
				  for(var n:Number=0;n<newOccluding2.length;n++) if(newOccluding.indexOf(newOccluding2[n])<0) newOccluding[newOccluding.length] = newOccluding2[n]
				 	newOccluding2 = scene.translateToCell(character.x,character.y,character.top).elementsInFront
				  for(n=0;n<newOccluding2.length;n++) if(newOccluding.indexOf(newOccluding2[n])<0) newOccluding[newOccluding.length] = newOccluding2[n]
				 } catch(e:Error){}
				 
				 for(i=0;i<oldOccluding.length;i++) {
				 		// Disable occlusions no longer needed
				 		if(newOccluding.indexOf(oldOccluding[i])<0) scene.renderEngine.stopOcclusion(oldOccluding[i],character)
				 }
				 
				 if(character.occlusion>=100) return
				 
 				 for(i=0;i<newOccluding.length;i++) {
						// Enable new occlusions				 	
				 		if(oldOccluding.indexOf(newOccluding[i])<0) scene.renderEngine.startOcclusion(newOccluding[i],character)
				 }
				 
				 character.currentOccluding = newOccluding
			   
			   
			}


			// Main render method for characters
			public static function renderCharacter(scene:fScene,character:fCharacter):void {
			
			   
			   if(scene.prof) scene.prof.begin("Render char:"+character.id, true )
			   
			   var light:fOmniLight, elements:Array, nEl:int, len:int, cache:fCharacterShadowCache 
			   
				 // Move character to its new position
				 scene.renderEngine.updateCharacterPosition(character)

			   // Render all lights and shadows
			   len = character.vLights.length
			   for(var i:int=0;i<len;i++) {
			   
					 	cache =  character.vLights[i]
					 	if(!cache.light.removed && cache.withinRange) {
					 	
					 		// Start
					 		light = cache.light as fOmniLight
			   		  scene.renderEngine.renderStart(character,light)
			   		  scene.renderEngine.renderLight(character,light)
			    		
			    		// Update shadows for scene character
			    		elements = cache.elements
			    		nEl = elements.length
		   	 		  if(fEngine.characterShadows) for(var i2:Number=0;i2<nEl;i2++) {
		   	 		  	try {
		   	 		  		if(scene.prof) {
		   	 		  			scene.prof.begin("S: "+light.id+" "+elements[i2].id)
			    					scene.renderEngine.updateShadow(elements[i2],light,character)
		   	 		  			if(scene.prof) scene.prof.end("S: "+light.id+" "+elements[i2].id)
		   	 		  		} else {
		   	 		  			scene.renderEngine.updateShadow(elements[i2],light,character)
		   	 		  		}
			    			} catch(e:Error) {
			    			
			    			}
			    			
			    		}

							// End
			   		  scene.renderEngine.renderFinish(character,light)
			   		  
			   	  }
			   
			      
			   }
			   
				 // Update occlusion
				 if(character.currentOccluding.length>0) {
				 	
				 	 if(scene.prof) scene.prof.begin("Occlusion")
 				 	 for(i=0;i<character.currentOccluding.length;i++) scene.renderEngine.updateOcclusion(character.currentOccluding[i],character)
				 	 if(scene.prof) scene.prof.end("Occlusion")
				 	 
				 }

			   if(scene.prof) scene.prof.end("Render char:"+character.id)


			}



		}

}
