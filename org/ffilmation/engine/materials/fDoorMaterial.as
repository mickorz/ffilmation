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
		* This class creates a door in any wall. The Door material allows users to build doors fast.
		*
		* <p>This class is automatically selected when you define a material as "door" in your XMLs. You don't need to use
		* it or worry about how it works</p>
		* @private
		*/
		public class fDoorMaterial implements fEngineMaterial {
			
			// Private vars
			private var definitionXML:XML								// Definition data
			private var element:fRenderableElement			// The element where this material is applied.
			
			private	var dwidth:Number										// Door size and position
			private	var dheight:Number
			private	var position:Number
			private	var realPosition:Number
			
			// Constructor
			public function fDoorMaterial(definitionXML:XML,element:fRenderableElement):void {
				this.definitionXML = definitionXML
				this.element = element
				
				// Retrieve door data
				this.dwidth = new Number(this.definitionXML.width)
				this.dheight = new Number(this.definitionXML.height)
				this.position = new Number(this.definitionXML.position)
				
			}

			/**
			* Frees all allocated resources for this material. It is called when the scene is destroyed and we want to free as much RAM as possible
			*/
			public function dispose():void {
				this.definitionXML = null
				this.element = null
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

				this.realPosition = (this.dwidth/2)+(width-this.dwidth)*(0.5+(this.position/200))

				// Draw base
				var tile:fTileMaterial = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.base],this.element)
				var base:BitmapData = new BitmapData(width,height,true,0x000000)
				base.draw(tile.getDiffuse(width,height))
				
				temp.graphics.beginBitmapFill(base,null,true,true)
				temp.graphics.moveTo(0,0)
				temp.graphics.lineTo(width,0)
				temp.graphics.lineTo(width,height)
				temp.graphics.lineTo(this.realPosition+this.dwidth/2,height)
				temp.graphics.lineTo(this.realPosition+this.dwidth/2,height-this.dheight)
				temp.graphics.lineTo(this.realPosition-this.dwidth/2,height-this.dheight)
				temp.graphics.lineTo(this.realPosition-this.dwidth/2,height)
				temp.graphics.lineTo(0,height)
				temp.graphics.lineTo(0,0)
				temp.graphics.endFill()				
				
				// Draw frame, if any
				var framesize:Number = new Number(this.definitionXML.framesize)
				if(framesize>0 && this.definitionXML.frame) {
					tile = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.frame],this.element)
					var base2:BitmapData = new BitmapData(width,height,true,0x000000)
					base2.draw(tile.getDiffuse(width,height))
					
					var temp2:Sprite = new Sprite
					temp2.graphics.beginBitmapFill(base2,null,true,true)
					temp2.graphics.moveTo(this.realPosition+this.dwidth/2,height)
					temp2.graphics.lineTo(this.realPosition+this.dwidth/2,height-this.dheight)
					temp2.graphics.lineTo(this.realPosition-this.dwidth/2,height-this.dheight)
					temp2.graphics.lineTo(this.realPosition-this.dwidth/2,height)
					temp2.graphics.lineTo(this.realPosition-this.dwidth/2-framesize,height)
					temp2.graphics.lineTo(this.realPosition-this.dwidth/2-framesize,height-this.dheight-framesize)
					temp2.graphics.lineTo(this.realPosition+this.dwidth/2+framesize,height-this.dheight-framesize)
					temp2.graphics.lineTo(this.realPosition+this.dwidth/2+framesize,height)
					temp2.graphics.lineTo(this.realPosition+this.dwidth/2,height)
					temp2.graphics.endFill()
					
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
				return [ new Rectangle(this.realPosition-this.dwidth/2,height-this.dheight,this.dwidth,this.dheight)]
			}

			/**
			* Retrieves the graphic element that is to be used to block a given hole when it is closed
			*
			* @param index The hole index, as returned by the getHoles() method
			* @return A Movieclip that will used to close the hole. If null is returned, the hole won't be "closeable".
			*/
			public function getHoleBlock(index:Number):MovieClip {
				
				if(index!=0) return null
				
				var ret:MovieClip = new MovieClip
				var tile:fTileMaterial = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.door],this.element)
				var door:BitmapData = new BitmapData(this.dwidth,this.dheight,true,0x000000)
				door.draw(tile.getDiffuse(this.dwidth,this.dheight))
				ret.addChild(new Bitmap(door,"auto",true))

				return ret				
				
			}


		}

}