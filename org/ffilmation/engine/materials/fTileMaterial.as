package org.ffilmation.engine.materials {

		// Imports
		import flash.display.*
		import flash.geom.*
		import flash.utils.getDefinitionByName
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		
		/**
		* This class creates a material by "Tiling" an image in the imported libraries
		*
		* <p>This class is automatically selected when you define a material as "tile" in your XMLs. You don't need to use
		* it or worry about how it works</p>
		* @private
		*/
		public class fTileMaterial implements fEngineMaterial {
			
			// Private vars
			private var definitionXML:XML								// Definition data
			private var element:fRenderableElement			// The element where this material is applied.
			
			// Constructor
			public function fTileMaterial(definitionXML:XML,element:fRenderableElement):void {
				this.definitionXML = definitionXML
				this.element = element
				
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
				
				var clase:Class = getDefinitionByName(this.definitionXML.diffuse) as Class
				var image:BitmapData = new clase(0,0) as BitmapData
				
				var matrix:Matrix = new Matrix()
				if(this.element is fFloor) matrix.translate(-this.element.x,-this.element.y)
				if(this.element is fWall) {
					var tempw:fWall = this.element as fWall
					if(tempw.vertical) matrix.translate(-this.element.y,-this.element.z)
					else matrix.translate(-this.element.x,-this.element.z)
				}

				temp.graphics.beginBitmapFill(image,matrix,true,true)
				temp.graphics.drawRect(0,0,width,height)
				temp.graphics.endFill()

			  var msk:BitmapData = new BitmapData(width,height,true,0x000000)
				msk.draw(temp)
				image.dispose()
				ret.addChild(new Bitmap(msk,"auto",true))

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
				var ret:Sprite = new Sprite
				var clase:Class = getDefinitionByName(this.definitionXML.bump) as Class
				var image:BitmapData = new clase(0,0) as BitmapData
				ret.graphics.beginBitmapFill(image,null,true,true)
				ret.graphics.drawRect(0,0,width,height)
				ret.graphics.endFill()
				return ret
			}

			/** 
			* Retrieves an array of holes (if any) of this material. These holes will be used to render proper lights and calculate collisions
			* and bullet impatcs
			*
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return An array of Rectangle objects, one for each hole. Positions and sizes are relative to material origin of coordinates
			*
			*/
			public function getHoles(width:Number,height:Number):Array {
				return []
			}

			/**
			* Retrieves the graphic element that is to be used to block a given hole when it is closed
			*
			* @param index The hole index, as returned by the getHoles() method
			* @return A MovieClip that will used to close the hole. If null is returned, the hole won't be "closeable".
			*/
			public function getHoleBlock(index:Number):MovieClip {
				return null
			}


		}

}