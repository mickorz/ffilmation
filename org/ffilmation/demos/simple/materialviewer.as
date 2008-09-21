package org.ffilmation.demos.simple {

	// Imports
	import flash.display.*
	import flash.events.*
	import org.ffilmation.engine.core.*
	import org.ffilmation.engine.events.*
	import org.ffilmation.utils.*
	import org.ffilmation.engine.elements.*
	import org.ffilmation.engine.scenes.*
	import flash.ui.Keyboard
	
	
	/** @private */
	public class materialviewer {
		
		// Variables
		public var timeline:MovieClip
		public var container:Sprite
		public var engine:fEngine	
		public var scene:fScene
		public var gup:Boolean		
		public var gdown:Boolean		
		public var gleft:Boolean		
		public var gright:Boolean	
		public var l3:fOmniLight	
		
		// Init demo
		public function materialviewer(mainTimeline:MovieClip,container:Sprite,src:String) {
			
				this.timeline = mainTimeline
				this.container = container
				
				this.container.y = 25
	
				this.timeline.stage.quality = "low"

				// Create engine
				this.engine = new fEngine(this.container)
				
				this.gup = false
				this.gdown = false
				this.gleft = false
				this.gright = false
				
				// Goto first scene
				this.gotoScene(src)
				
		}
	
		// Load scene start
		public function gotoScene(path:String):void {
			
				// Stop control loop		
				this.timeline.removeEventListener('enterFrame', this.control)
	
				this.timeline.stage.quality = "high"
				this.timeline.gotoAndStop("Load")
				this.scene = this.engine.createScene(new fSceneLoader(path),700,450)
				this.scene.addEventListener(fScene.LOADPROGRESS, this.loadProgressHandler)
				this.scene.addEventListener(fScene.LOADCOMPLETE, this.loadCompleteHandler)
				
		}
	
		public function loadProgressHandler(evt:fProcessEvent):void {
				this.timeline.progres.update(evt.current,evt.currentDescription,evt.overall,evt.overallDescription)
		}
	
		public function loadCompleteHandler(evt:fProcessEvent):void {
				this.timeline.gotoAndStop("Play")
				this.timeline.stage.quality = "low"
				this.activateScene()
		}
	
		// Load scene complete
		public function activateScene():void {
			
			// Create camera
			var cam:fCamera = this.scene.createCamera()
			this.scene.setCamera(cam)
			
			this.l3 = scene.createOmniLight("l3",20,20,20,300,"#ffffff",100,0,true)
			this.l3.render()			
			
			cam.moveTo(l3.x,l3.y,l3.z)
			cam.follow(l3)
		
			
			// Render
			this.engine.showScene(this.scene)
			
			// Events
			this.timeline.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.keyPressed)
			this.timeline.stage.addEventListener(KeyboardEvent.KEY_UP, this.keyReleased)
			this.timeline.addEventListener('enterFrame', this.control)
	
		}	
	
		// Main control loop
		public function control(evt:Event) {
			
			var x:Number=l3.x
			var y:Number=l3.y
			var z:Number=l3.z
			
			if(this.gup) y-=10 
			if(this.gdown) y+=10 
			if(this.gleft) x-=10 
			if(this.gright) x+=10 
			
			if(this.gup||this.gdown||this.gleft||this.gright) l3.moveTo(x,y,z)
			
		}
	


		// Receives keypresses		
	  private function keyPressed(evt:KeyboardEvent):void {
		    
				// Ignore auto key repeats
				
		    switch(evt.keyCode) {
		
		    	case Keyboard.UP: this.gup=true; break;

		    	case Keyboard.RIGHT: this.gright=true; break;

		    	case Keyboard.LEFT: this.gleft=true; break;

		    	case Keyboard.DOWN: this.gdown=true; break;
		    } 


		}

		// Receives key releases
		private function keyReleased(evt:KeyboardEvent):void {
		
		    switch(evt.keyCode) {
		
		    	case Keyboard.UP: this.gup=false; break;

		    	case Keyboard.RIGHT: this.gright=false; break;

		    	case Keyboard.LEFT: this.gleft=false; break;

		    	case Keyboard.DOWN: this.gdown=false; break;
		    	
		    } 
		
		}


	}

}
