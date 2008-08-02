package org.ffilmation.engine.materials {

		// Imports
		import flash.display.*
		import flash.geom.*
		import flash.filters.*
		import flash.utils.getDefinitionByName
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		
		/**
		* This class adds windows to any wall. This is a fast way of creating nicer buildings with little effort
		*
		* <p>This class is automatically selected when you define a material as "window" in your XMLs. You don't need to use
		* it or worry about how it works</p>
		* @private
		*/
		public class fWindowMaterial implements fEngineMaterial {
			
			// Private vars
			private var definitionXML:XML								// Definition data
			private var element:fRenderableElement			// The element where this material is applied.
			
			private	var wwidth:Number										// Windows dimensions
			private	var wheight:Number
			private	var windows:Array
			private	var position:Number
			private	var framesize:Number
			private	var separation:Number
			private	var geometryW:int
			private	var geometryH:int
			private	var hDivisionSize:Number
			private	var vDivisionSize:Number
			
			// Constructor
			public function fWindowMaterial(definitionXML:XML,element:fRenderableElement):void {
				this.definitionXML = definitionXML
				this.element = element
				
				// Retrieve window data
				this.wwidth = new Number(this.definitionXML.width)
				this.wheight = new Number(this.definitionXML.height)
				this.position = new Number(this.definitionXML.position)
				this.framesize = new Number(this.definitionXML.framesize)
				this.separation = new Number(this.definitionXML.separation)
				
				var t:String = this.definitionXML.geometry
				try { this.geometryW = new Number(t.split("x")[0]) } catch(e:Error) { this.geometryW = 1}
				try { this.geometryH = new Number(t.split("x")[1]) } catch(e:Error) { this.geometryH = 1}

				// Subdivisions in frame
				this.hDivisionSize = (this.wwidth-(this.geometryW-1)*this.framesize)/this.geometryW
				this.vDivisionSize = (this.wheight-(this.geometryH-1)*this.framesize)/this.geometryH
				
			}
			
			/**
			* Frees all allocated resources for this material. It is called when the scene is destroyed and we want to free as much RAM as possible
			*/
			public function dispose():void {
				this.definitionXML = null
				this.element = null
			}
			

			private function calcWindows(width:Number,height:Number) {

				// Count how many windows fit in
				var nWindows:Number = Math.floor(width/(this.wwidth+this.separation+this.framesize))
				
				// Calculate window vertical position
				var range:Number = (height-this.wheight)/2
				var vPosition:Number = Math.round((height/2)+(-range*this.position/100)-(this.wheight/2))
				
				// Generate window array
				this.windows = new Array()
				for(var j:Number=1;j<=nWindows;j++) {
					this.windows.push(new Rectangle(j*width/(nWindows+1)-this.wwidth/2,vPosition,this.wwidth,this.wheight))
				}
				
			}
			
			
			/** 
			* Retrieves the diffuse map for this material. If you write custom classes, make sure they return the proper size.
			* 0,0 of the returned DisplayObject corresponds to the top-left corner of material
			*
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return A DisplayObject (either Bitmap or MovieClip) that will be display onscreen
			*
			*/
			public function getDiffuse(width:Number,height:Number):DisplayObject {
				
				var ret:Sprite = new Sprite
				var temp:Sprite = new Sprite
				
				this.calcWindows(width,height)

				// Draw base
				var tile:fTileMaterial = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.base],this.element)
				var base:BitmapData = new BitmapData(width,height,true,0x000000)
				base.draw(tile.getDiffuse(width,height))
				
				temp.graphics.beginBitmapFill(base,null,true,true)
				temp.graphics.moveTo(0,0)
				temp.graphics.lineTo(width,0)
				temp.graphics.lineTo(width,height)
				temp.graphics.lineTo(0,height)
				temp.graphics.lineTo(0,0)
				
				for(var j:Number=0;j<this.windows.length;j++) {
					
					var window:Rectangle = this.windows[j]
					
					temp.graphics.moveTo(window.x,window.y)
					temp.graphics.lineTo(window.x,window.y+window.height)
					temp.graphics.lineTo(window.x+window.width,window.y+window.height)
					temp.graphics.lineTo(window.x+window.width,window.y)
					temp.graphics.lineTo(window.x,window.y)
					
				}

				temp.graphics.endFill()				


				// Draw frame, if any
				var framesize:Number = new Number(this.definitionXML.framesize)
				if(framesize>0 && this.definitionXML.frame) {
					tile = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.frame],this.element)
					var base2:BitmapData = new BitmapData(width,height,true,0x000000)
					base2.draw(tile.getDiffuse(width,height))
					
					var temp2:Sprite = new Sprite
					for(j=0;j<this.windows.length;j++) {
						
						window = this.windows[j]
					
						temp2.graphics.beginBitmapFill(base2,null,true,true)
						temp2.graphics.moveTo(window.x-this.framesize,window.y-this.framesize)
						temp2.graphics.lineTo(window.x-this.framesize,window.y+window.height+this.framesize)
						temp2.graphics.lineTo(window.x+window.width+this.framesize,window.y+window.height+this.framesize)
						temp2.graphics.lineTo(window.x+window.width+this.framesize,window.y-this.framesize)
						temp2.graphics.lineTo(window.x-this.framesize,window.y-this.framesize)
						
						// Draw subdivisions in frame
						for(var k:Number=0;k<this.geometryW;k++) {
							for(var k2:Number=0;k2<this.geometryH;k2++) {
								temp2.graphics.moveTo(window.x+k*(this.framesize+this.hDivisionSize),window.y+k2*(this.framesize+this.vDivisionSize))
								temp2.graphics.lineTo(window.x+k*(this.framesize+this.hDivisionSize)+this.hDivisionSize,window.y+k2*(this.framesize+this.vDivisionSize))
								temp2.graphics.lineTo(window.x+k*(this.framesize+this.hDivisionSize)+this.hDivisionSize,window.y+k2*(this.framesize+this.vDivisionSize)+this.vDivisionSize)
								temp2.graphics.lineTo(window.x+k*(this.framesize+this.hDivisionSize),window.y+k2*(this.framesize+this.vDivisionSize)+this.vDivisionSize)
								temp2.graphics.lineTo(window.x+k*(this.framesize+this.hDivisionSize),window.y+k2*(this.framesize+this.vDivisionSize))
							}
						}	
						temp2.graphics.endFill()
					
					}
					
					// Use a dropShadow filter to add some thickness to the frame
					var angle:Number = 225
					if(this.element is fWall && (this.element as fWall).vertical) angle=315
					
					var fil = new DropShadowFilter(3,angle,0,1,5,5,1,BitmapFilterQuality.HIGH)
					temp2.filters = [fil]
					
				}


				// Merge layers
			  var msk:BitmapData = new BitmapData(width,height,true,0x000000)
				msk.draw(temp)
				msk.draw(temp2)
				ret.addChild(new Bitmap(msk,"auto",true))

				base.dispose()
				base2.dispose()
				
				return ret
			}

			/** 
			* Retrieves the bump map for this material. If you write custom classes, make sure they return the proper size
			* 0,0 of the returned DisplayObject corresponds to the top-left corner of material
			*
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return A DisplayObject (either Bitmap or MovieClip) that will used as BumpMap. If it is a MovieClip, the first frame will we used
			*
			*/
			public function getBump(width:Number,height:Number):DisplayObject {
				return null
			}

			/** 
			* Retrieves an array of holes (if any) of this material. These holes will be used to render proper lights and calculate collisions
			* and bullet impacts
			*
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return An array of Rectangle objects, one for each hole. Positions and sizes are relative to material origin of coordinates
			*
			*/
			public function getHoles(width:Number,height:Number):Array {
				
				this.calcWindows(width,height)

				var holes:Array = new Array
				for(var j:Number=0;j<this.windows.length;j++) {
					
					var window:Rectangle = this.windows[j]
				
					// Push subdivisions in frame
					for(var k:Number=0;k<this.geometryW;k++) {
						for(var k2:Number=0;k2<this.geometryH;k2++) {
							holes.push(new Rectangle(window.x+k*(this.framesize+this.hDivisionSize),window.y+k2*(this.framesize+this.vDivisionSize),this.hDivisionSize,this.vDivisionSize))
						}
					}	
				
				}
				return holes
			}

			/**
			* Retrieves the graphic element that is to be used to block a given hole when it is closed
			*
			* @param index The hole index, as returned by the getHoles() method
			* @return A Movieclip that will used to close the hole. If null is returned, the hole won't be "closeable".
			*/
			public function getHoleBlock(index:Number):MovieClip {
				
				return null
				
			}


		}

}