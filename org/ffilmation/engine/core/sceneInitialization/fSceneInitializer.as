// SCENE INITIALIZER
package org.ffilmation.engine.core.sceneInitialization {

		// Imports
		import flash.xml.*
		import flash.net.*
		import flash.events.*
		import flash.display.*
		import flash.utils.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.interfaces.*
		

		/**
		* <p>The fSceneInitializer class does all the job of creating an scene from an XML file.
		* It uses all the classes in this package</p>
		*
		* @private
		*/
		public class fSceneInitializer {		

			// Private properties
			private var scene:fScene
			private var retriever:fEngineSceneRetriever
			private var xmlObj:XML
			
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
         this.initialization_Part1()
        
			}
			
			// Part 1 of scene initialization is loading definitions
			private function initialization_Part1() {
				
				 this.scene.resourceManager = new fSceneResourceManager(this.scene)
				 this.scene.resourceManager.addEventListener(fScene.LOADPROGRESS,this.part1Progress)
				 this.scene.resourceManager.addEventListener(Event.COMPLETE,this.part1Complete)
				 this.scene.resourceManager.addEventListener(ErrorEvent.ERROR,this.part1Error)
				 this.scene.resourceManager.addResourcesFrom(this.xmlObj.head[0],this.retriever.getBasePath())
				 
			}

			private function part1Error(evt:ErrorEvent):void {
				
				 this.scene.resourceManager.removeEventListener(fScene.LOADPROGRESS,this.part1Progress)
				 this.scene.resourceManager.removeEventListener(Event.COMPLETE,this.part1Complete)
				 this.scene.resourceManager.removeEventListener(ErrorEvent.ERROR,this.part1Error)
				 
			   this.scene.dispatchEvent(evt)
			   
			}

			private function part1Progress(evt:fProcessEvent):void {
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,evt.overall/2,fScene.LOADINGDESCRIPTION,evt.overall,evt.currentDescription))
			}

			private function part1Complete(evt:Event):void {
				
				this.scene.resourceManager.removeEventListener(fScene.LOADPROGRESS,this.part1Progress)
				this.scene.resourceManager.removeEventListener(Event.COMPLETE,this.part1Complete)
				this.scene.resourceManager.removeEventListener(ErrorEvent.ERROR,this.part1Error)
			  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,50,"Parsing XML"))
		   	// Next step
		   	var myTimer:Timer = new Timer(200, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part2)
        myTimer.start()
        
			}

			// Part 2 of scene initialization is parsing the global parameters and geometry of the scene
			private function initialization_Part2(e:Event) {
				
				e.target.removeEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part2)
				
				fSceneXMLParser.parseSceneGeometryFromXML(this.scene,this.xmlObj)
			  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50,fScene.LOADINGDESCRIPTION,0,"Parsing XML. Done."))

		   	// Next step
		   	var myTimer:Timer = new Timer(200, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part3)
        myTimer.start()
        
			}

			// Part 3 of scene initialization grid is zSorting
			private function initialization_Part3(e:Event) {
				
				e.target.removeEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part3)

				var sceneGridSorter:fSceneGridSorter = new fSceneGridSorter(this.scene)
				sceneGridSorter.addEventListener(fScene.LOADPROGRESS,this.part3Progress)
				sceneGridSorter.addEventListener(Event.COMPLETE,this.part3Complete)
				sceneGridSorter.start()
				
			}

			private function part3Progress(evt:fProcessEvent):void {
			  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,50+30*evt.overall/100,fScene.LOADINGDESCRIPTION,evt.overall,evt.overallDescription))
			}

			private function part3Complete(evt:Event):void {

				evt.target.removeEventListener(fScene.LOADPROGRESS,this.part3Progress)
				evt.target.removeEventListener(Event.COMPLETE,this.part3Complete)
			  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,80,fScene.LOADINGDESCRIPTION,100,"Z sorting done."))
		   	
		   	// Next step
		   	var myTimer:Timer = new Timer(200, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part4)
        myTimer.start()
        
			}

			// Collision and occlusion
			private function initialization_Part4(event:TimerEvent):void {
			
				event.target.removeEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part4)
			  this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,false,false,95,fScene.LOADINGDESCRIPTION,100,"Calculating collision and occlusion grid."))
				
				fSceneCollisionParser.calculate(this.scene)
				fSceneOcclusionParser.calculate(this.scene)
			  
		   	// Next step
		   	var myTimer:Timer = new Timer(200, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part5)
        myTimer.start()
        
      }

			// Setup initial lights, render everything
			private function initialization_Part5(event:TimerEvent):void {
			
				event.target.removeEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Part5)

				// Environment and lights
				fSceneXMLParser.parseSceneEnvironmentFromXML(this.scene,this.xmlObj)

				// Events
				fSceneXMLParser.parseSceneEventsFromXML(this.scene,this.xmlObj)

			  // Prepare characters
			  for(var j:Number=0;j<this.scene.characters.length;j++) {
			  	  this.scene.characters[j].cell = this.scene.translateToCell(this.scene.characters[j].x,this.scene.characters[j].y,this.scene.characters[j].z)
						this.scene.characters[j].addEventListener(fElement.NEWCELL,this.scene.processNewCell)			   
						this.scene.characters[j].addEventListener(fElement.MOVE,this.scene.renderElement)			   
				}
		   	
		   	// Create controller for this scene, if any was specified in the XML
				try {
					fSceneXMLParser.parseSceneControllerFromXML(this.scene,this.xmlObj)
	   		} catch(e:Error) {
					this.scene.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,"Scene contains an invalid controller definition. "+e))
	   		}
		   	
		   	// Next step
		   	var myTimer:Timer = new Timer(200, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.initialization_Complete)
        myTimer.start()
        
			}
			
			// Complete process, mark scene as ready. We are done !
			private function initialization_Complete(event:TimerEvent):void {

				 event.target.removeEventListener(TimerEvent.TIMER_COMPLETE,this.initialization_Complete)

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
				 
			}
			
			
		}
			
}
