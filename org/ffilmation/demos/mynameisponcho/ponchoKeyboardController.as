package org.ffilmation.demos.mynameisponcho {

	// Imports
	import flash.display.*
	import flash.events.*
	import flash.ui.Keyboard
	import org.ffilmation.engine.core.*
	import org.ffilmation.engine.elements.*
	import org.ffilmation.engine.events.*
	import org.ffilmation.engine.interfaces.*

	/**
		This class controls the hero in our demo
	*/	
	public class ponchoKeyboardController implements fEngineElementController {
	
		// Properties
		public var character:fCharacter
		private var keysDown:Object

		// Status
		public var running:Boolean
		public var walking:Boolean
		public var crouching:Boolean
		public var shooting:Boolean
		public var jumping:Boolean
		public var rolling:Boolean
		public var cnt:Number
		public var angle:Number
		public var turnSpeed:Number
		public var vx:Number
		public var vy:Number
		public var vz:Number
		
		// Constructor
		public function ponchoKeyBoardController():void { 
		}
		
		// Implements interface
		public function assignElement(element:fElement):void {

			this.character = element as fCharacter
			
			// Init position and speed
			this.angle = this.character.orientation
			this.vx = 0
			this.vy = 0
			this.vz = 0

		}

		// Implements interface
		public function enable():void {
			this.keysDown = new Object()
			fEngine.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.keyPressed)
			fEngine.stage.addEventListener(KeyboardEvent.KEY_UP, this.keyReleased)
			fEngine.stage.addEventListener('enterFrame', this.control)
			this.character.addEventListener(fCharacter.COLLIDE, this.collision)
		}

		// Implements interface
		public function disable():void {
			fEngine.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyPressed)
			fEngine.stage.removeEventListener(KeyboardEvent.KEY_UP, this.keyReleased)
			fEngine.stage.removeEventListener('enterFrame', this.control)
			this.character.removeEventListener(fCharacter.COLLIDE, this.collision)
		  this.keysDown = {}
			this.stopRunning()		
		  this.stopWalking()
		  this.character.gotoAndPlay("Stand")
		  this.vx = this.vy = this.vz = 0
		}

		// Receives keypresses		
	  private function keyPressed(evt:KeyboardEvent):void {
		    
				// Ignore auto key repeats
				
				if(this.keysDown[evt.keyCode] == true) return
				this.keysDown[evt.keyCode] = true

		    switch(evt.keyCode) {
		
		    	case Keyboard.SPACE: this.jump(); break;
		
		    	case Keyboard.SHIFT: this.run(); break;
		
		    	case Keyboard.UP: this.walk(); break;

		    	case Keyboard.RIGHT: this.walk(); break;

		    	case Keyboard.LEFT: this.walk(); break;

		    	case Keyboard.DOWN: this.walk(); break;
		    } 


		}
				
		// Receives key releases
		private function keyReleased(evt:KeyboardEvent):void {
		
				delete this.keysDown[evt.keyCode]

		    switch(evt.keyCode) {
		
		    	case Keyboard.SHIFT: this.stopRunning(); break;
		
		    	case Keyboard.UP: this.stopWalking(); break;

		    	case Keyboard.RIGHT: this.stopWalking(); break;

		    	case Keyboard.LEFT: this.stopWalking(); break;
		    	
		    	case Keyboard.DOWN: this.stopWalking(); break;
		    	
		    } 
		
		}
		
		// Main control loop
		public function control(evt:Event) {
			
				var x:Number = this.character.x
				var y:Number = this.character.y
				var z:Number = this.character.z
				var angleRad:Number = this.angle*Math.PI/180
				
				// Gravity
				this.vz-=1
				
				// Speed from status
				if(this.rolling || this.jumping) {
				
				} else if(this.walking) {
					
					if(this.running) {
						this.vx = 10*Math.cos(angleRad)
						this.vy = 10*Math.sin(angleRad)
					} else {
						this.vx = 5*Math.cos(angleRad)
						this.vy = 5*Math.sin(angleRad)
					}
					
				} else {
					
					this.vx = 0
					this.vy = 0
					
				}
				
				if(this.vx!=0 || this.vy!=0 || this.vz!=0) this.character.moveTo(x+this.vx,y+this.vy,z+this.vz)
				
		}

		// Collision listener
		public function collision(evt:fCollideEvent):void {
				if(evt.victim is fFloor || (evt.victim is fObject && this.character.z>evt.victim.top)) {
					this.vz = 0
					
					if(this.jumping) {
						if(this.walking) {
							if(this.running) this.character.gotoAndPlay("Run")
							else this.character.gotoAndPlay("Walk")
						} 
						else this.character.gotoAndPlay("Land")
					}
					this.jumping = false
				}
		}

		// Movement methods
		public function jump():void {
			
			// If dodging, ignore
			if(this.rolling || this.jumping) return

			this.vz = 15
			this.jumping = true
			this.character.gotoAndPlay("Jump")
			
	  }


		public function dodge():void {
		
			// If dodging, ignore
			if(this.rolling) return
		
			var angleRad:Number = this.angle*Math.PI/180
			

			if(this.running) {
				this.vx = 12*Math.cos(angleRad)
				this.vy = 12*Math.sin(angleRad)
			} else if(this.walking){
				this.vx = 8*Math.cos(angleRad)
				this.vy = 8*Math.sin(angleRad)
			} else return
			
			this.rolling = true
			this.cnt = 25
			this.character.gotoAndPlay("Roll")
		
			fEngine.stage.addEventListener('enterFrame', this.controlDodge)			
			
		}

		public function controlDodge(evt:Event):void {
			this.cnt--
			if(this.cnt==0) {
				fEngine.stage.removeEventListener('enterFrame', this.controlDodge)
				this.doneDodging()
			}
		}
		
		public function doneDodging():void {
	
			this.rolling = false
			if(this.walking) {
				if(this.running) this.character.gotoAndPlay("Run")
				else this.character.gotoAndPlay("Walk")
			} 
			else this.character.gotoAndPlay("Stand")

			this.character.orientation = this.angle

		}
		
		
		public function run():void {
				
			this.running = true
		
			// If dodging, ignore
			if(this.rolling) return
		
			if(this.walking) {
				this.character.gotoAndPlay("runLoop")
			}
					
		}
		
		public function stopRunning():void {
		
			this.running = false
		
			// If dodging, ignore
			if(this.rolling) return
		
			if(this.walking) {
				this.character.gotoAndPlay("walkLoop")
			}
		
		}
		
		
		public function walk():void {
			
			this.updateAngle()
		
			// If already walking, don't reset animation
			if(this.walking) return
			
			this.walking = true

			// If dodging, ignore
			if(this.rolling || this.jumping) return

			if(this.running) this.character.gotoAndPlay("Run")
			else this.character.gotoAndPlay("Walk")
		
		}
		
		public function stopWalking():void {
		
			this.updateAngle()
			if(this.keysDown[Keyboard.UP] == true || this.keysDown[Keyboard.DOWN] == true || this.keysDown[Keyboard.LEFT] == true || this.keysDown[Keyboard.RIGHT] == true) return

			this.walking = false
			if(!this.rolling && !this.jumping) this.character.gotoAndPlay("Stand")
		
		}


		private function updateAngle():void {
			
			if(this.keysDown[Keyboard.UP] == true) {
				
				if(this.keysDown[Keyboard.LEFT] == true) this.angle = 270
				else if(this.keysDown[Keyboard.RIGHT] == true) this.angle = 0
				else this.angle = 315
				
			} else if(this.keysDown[Keyboard.DOWN] == true) {
				
				if(this.keysDown[Keyboard.LEFT] == true) this.angle = 180
				else if(this.keysDown[Keyboard.RIGHT] == true) this.angle = 90
				else this.angle = 135
				
			} else if(this.keysDown[Keyboard.RIGHT] == true) {
				
				this.angle = 45
			
			}	else if(this.keysDown[Keyboard.LEFT] == true) {
				
				this.angle = 225
			
			}
			
			if(!this.rolling) this.character.orientation = this.angle
			
		}
		
		
	}

}

