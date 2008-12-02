// XML PARSER
package org.ffilmation.engine.core.sceneInitialization {
	
		// Imports
		import flash.xml.*
		import flash.utils.getDefinitionByName

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.elements.*
		

		/**
		* <p>The fSceneXMLParser class contains static methods that translate data from XML files into FFilmation Objects during initialization.</p>
		*
		* <p>Exception: Definitions ( objects, materials, etc ) are managed by the fSceneResourcemanager class</p>
		*
		* @private
		*/
		public class fSceneXMLParser {		


			/** Updates an scene's properties from an XML */
			public static function parseSceneGeometryFromXML(scene:fScene,xmlObj:XML):void {
				
			   // Grid initialization
			   if(xmlObj.@gridsize.length()>0) scene.gridSize = new Number(xmlObj.@gridsize)
			   if(xmlObj.@levelsize.length()>0) scene.levelSize = new Number(xmlObj.@levelsize)
				
				 // Search for BOX tags and decompile into walls and floors
				 var tempObj:XMLList = xmlObj.body.child("box")
			   while(tempObj.length()>0) {
			   	 var box:XML = tempObj[0]
			   	 if(box.@src1.length()>0) xmlObj.body.appendChild('<wall id="'+(box.@id+"_side1")+'" src="'+(box.@src1)+'" size="'+(box.@sizex)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="horizontal"/>')
			   	 if(box.@src2.length()>0) xmlObj.body.appendChild('<wall id="'+(box.@id+"_side2")+'" src="'+(box.@src2)+'" size="'+(box.@sizey)+'" height="'+(box.@sizez)+'" x="'+(parseInt(box.@x)+parseInt(box.@sizex))+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="vertical"/>')
			   	 if(box.@src3.length()>0) xmlObj.body.appendChild('<wall id="'+(box.@id+"_side3")+'" src="'+(box.@src3)+'" size="'+(box.@sizex)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(parseInt(box.@y)+parseInt(box.@sizey))+'" z="'+(box.@z)+'" direction="horizontal"/>')
			   	 if(box.@src4.length()>0) xmlObj.body.appendChild('<wall id="'+(box.@id+"_side4")+'" src="'+(box.@src4)+'" size="'+(box.@sizey)+'" height="'+(box.@sizez)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(box.@z)+'" direction="vertical"/>')
			   	 if(box.@src5.length()>0) xmlObj.body.appendChild('<floor id="'+(box.@id+"_side5")+'" src="'+(box.@src5)+'" width="'+(box.@sizex)+'" height="'+(box.@sizey)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(parseInt(box.@z)+parseInt(box.@sizez))+'"/>')
			   	 if(box.@src6.length()>0) xmlObj.body.appendChild('<floor id="'+(box.@id+"_side6")+'" src="'+(box.@src6)+'" width="'+(box.@sizex)+'" height="'+(box.@sizey)+'" x="'+(box.@x)+'" y="'+(box.@y)+'" z="'+(parseInt(box.@z))+'"/>')
			   	 delete tempObj[0]
				 }

			   scene.top = 0
			   scene.gridWidth = 0
			   scene.gridDepth = 0
			   scene.gridHeight = 0

			   // Parse FLOOR Tags
				 tempObj = xmlObj.body.child("floor")
				 for(var i:Number=0;i<tempObj.length();i++) fSceneXMLParser.parseFloorFromXML(scene,tempObj[i])
				 
			   // Parse WALL Tags
 				 tempObj = xmlObj.body.child("wall")
			   for(i=0;i<tempObj.length();i++) fSceneXMLParser.parseWallFromXML(scene,tempObj[i])

			   // Parse OBJECT Tags
			   tempObj = xmlObj.body.child("object")
			   for(i=0;i<tempObj.length();i++) {
			   		if(fScene.allCharacters || tempObj[i].@dynamic=="true") fSceneXMLParser.parseCharacterFromXML(scene,tempObj[i])
			   		else fSceneXMLParser.parseObjectFromXML(scene,tempObj[i])
			   }

			   // Parse CHARACTER Tags
			   tempObj = xmlObj.body.child("character")
			   for(i=0;i<tempObj.length();i++) fSceneXMLParser.parseCharacterFromXML(scene,tempObj[i])

			   // Final geometry adjustments
			   scene.top += scene.levelSize*10
			   scene.gridHeight = int((scene.top/scene.levelSize)+0.5)
			   scene.height = scene.gridHeight*scene.levelSize


			}
			
			/** Updates an scene's environment (lighting and sounds) from an XML */
			public static function parseSceneEnvironmentFromXML(scene:fScene,xmlObj:XML):void {

			   // Parse environment light, if any
			   scene.environmentLight = new fGlobalLight(xmlObj.head.child("light")[0],scene)

			   // Parse dynamic lights
			   var objfLight:XMLList = xmlObj.body.child("light")
			   for(var i=0;i<objfLight.length();i++) fSceneXMLParser.parseLightFromXML(scene,objfLight[i])

			}


			/** Updates an scene's controller from an XML */
			public static function parseSceneControllerFromXML(scene:fScene,xmlObj:XML):void {
		   	
		   	if(xmlObj.@controller.length()==1) {
	   			var cls:String = xmlObj.@controller
	   			var r:Class = getDefinitionByName(cls) as Class
		  		scene.controller = new r()		
		   	}
		   	
			}

			/** Updates an scene's events from an XML */
			public static function parseSceneEventsFromXML(scene:fScene,xmlObj:XML):void {

				 // Retrieve events
				 var tempObj:XMLList = xmlObj.body.child("event")
			    for(var i:Number=0;i<tempObj.length();i++) {
			   	  var evt:XML = tempObj[i]
			   	  var tEvt:fCellEventInfo = new fCellEventInfo(evt)
			   	  
						var rz:int = int((new Number(evt.@z[0]))/scene.levelSize)
			   		var obi:int = int((new Number(evt.@x[0]))/scene.gridSize)
			   		var obj:int = int((new Number(evt.@y[0]))/scene.gridSize)
			   		
			   		var height:int = int((new Number(evt.@height[0]))/scene.levelSize)
			   		var width:int = int((new Number(evt.@width[0]))/(2*scene.gridSize))
			   		var depth:int = int((new Number(evt.@depth[0]))/(2*scene.gridSize))
			   		
			   		for(var n:Number=obj-depth;n<=(obj+depth);n++) {
			   			for(var l:Number=obi-width;l<=(obi+width);l++) {
			   				for(var k:Number=rz;k<=(rz+height);k++) {
			   					try {
			   						var cell:fCell = scene.getCellAt(l,n,k)
			   						cell.events.push(tEvt)   	  
			   					} catch(e:Error){}
			   	  		}
			   	  	}
			   	  }
			   }

			}

			/** Inserts a new floor into an scene from an XML node */
			public static function parseFloorFromXML(scene:fScene,xmlObj:XML):void {
			
				 if(xmlObj.@src.length()==0) xmlObj.@src="default"

				 var nFloor:fFloor = new fFloor(xmlObj,scene)
         scene.floors.push(nFloor)
         scene.everything.push(nFloor)
			   scene.all[nFloor.id] = nFloor
			   		   	    
			   // Update scene bounds
			   if(scene.gridWidth<(nFloor.i+nFloor.gWidth)) scene.gridWidth = nFloor.i+nFloor.gWidth
			   if(scene.gridDepth<(nFloor.j+nFloor.gDepth)) scene.gridDepth = nFloor.j+nFloor.gDepth
			   scene.width = scene.gridWidth*scene.gridSize
			   scene.depth = scene.gridDepth*scene.gridSize
			   if(nFloor.z>scene.top) scene.top = nFloor.z

			}
			
			/** Inserts a new wall into an scene from an XML node */
			public static function parseWallFromXML(scene:fScene,xmlObj:XML):void {
			
				 if(xmlObj.@src.length()==0) xmlObj.@src="default"

	       var nWall:fWall = new fWall(xmlObj,scene)
			   scene.walls.push(nWall)
			   scene.everything.push(nWall)
			   scene.all[nWall.id] = nWall
			   
			   // Update scene bounds
			   if(nWall.top>scene.top) scene.top = nWall.top

			}

			/** Inserts a new character into an scene from an XML node */
			public static function parseCharacterFromXML(scene:fScene,xmlObj:XML):void {

				 var nCharacter:fCharacter = new fCharacter(xmlObj,scene)
			   scene.characters.push(nCharacter)
			   scene.everything.push(nCharacter)
			   scene.all[nCharacter.id] = nCharacter

			   // Update scene bounds
			   if(nCharacter.top>scene.top) scene.top = nCharacter.top
			   	
			}

			/** Inserts a new object into an scene from an XML node */
			public static function parseObjectFromXML(scene:fScene,xmlObj:XML):void {

			   var nObject:fObject = new fObject(xmlObj,scene)
			   scene.objects.push(nObject)
			   scene.everything.push(nObject)
			   scene.all[nObject.id] = nObject
			   
			   // Update scene bounds
			   if(nObject.top>scene.top) scene.top = nObject.top
			   	
			}


			/** Inserts a new light into an scene from an XML node */
			public static function parseLightFromXML(scene:fScene,xmlObj:XML):void {

			   var nfLight:fOmniLight = new fOmniLight(xmlObj,scene)
			   	
			   // Events
				 nfLight.addEventListener(fElement.NEWCELL,scene.processNewCell,false,0,true)			   
				 nfLight.addEventListener(fElement.MOVE,scene.renderElement,false,0,true)			   
				 nfLight.addEventListener(fLight.RENDER,scene.processNewCell,false,0,true)			   
				 nfLight.addEventListener(fLight.RENDER,scene.renderElement,false,0,true)			   
				 nfLight.addEventListener(fLight.SIZECHANGE,scene.processNewLightDimensions,false,0,true)			   
			   	
			   // Add to lists
			   scene.lights.push(nfLight)
			   scene.everything.push(nfLight)
			   scene.all[nfLight.id] = nfLight
			   	
			}


	}

}