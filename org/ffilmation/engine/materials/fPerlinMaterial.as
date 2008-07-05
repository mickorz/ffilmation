package org.ffilmation.engine.materials {

		// Imports
		import flash.display.*
		import flash.geom.*
		import flash.utils.getDefinitionByName
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.datatypes.*
		
		/**
		* This class creates a material by stacking several layers of "tile" materials, using a perlin noise funcion as alpha mask for each layer
		*
		* <p>This class is automatically selected when you define a material as "perlin" in your XMLs. You don't need to use
		* it or worry about how it works</p>
		* @private
		*/
		public class fPerlinMaterial implements fEngineMaterial {
			
			// Private vars
			private var definitionXML:XML								// Definition data
			private var element:fRenderableElement			// The element where this material is applied. In perlin materials you need to know
																									// its coordinates so the material moves seamlessly between planes
			
			// Constructor
			public function fPerlinMaterial(definitionXML:XML,element:fRenderableElement):void {
				this.definitionXML = definitionXML
				this.element = element
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

				// Draw base
				var tile:fTileMaterial = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.base],this.element)
				temp.addChild(tile.getDiffuse(width,height))
				
				
				// Draw layers, if any
				var layers:XMLList = this.definitionXML.child("layer")
				for(var i:Number=0;i<layers.length();i++) {
					
				  tile = new fTileMaterial(this.element.scene.materialDefinitions[layers[i].material],this.element)
					var layer:BitmapData = new BitmapData(width,height,true,0x00000000)
					var diffuse:DisplayObject = tile.getDiffuse(width,height)
					layer.draw(diffuse)
					var msk:BitmapData = new BitmapData(width,height,false,0x000000)
					try {
						this.element.scene.noiseDefinitions[layers[i].noise].drawNoise(msk,BitmapDataChannel.RED,this.element.x,this.element.y)
					} catch(e:Error) {
						throw new Error("Filmation Engine Exception: Attempt to use a nonexistent noise definition: '"+layers[i].noise+"'")
					}
					layer.copyChannel(msk,new Rectangle(0, 0, width,height),new Point(0,0),BitmapDataChannel.RED, BitmapDataChannel.ALPHA)
					msk.dispose()
					
					temp.addChild(new Bitmap(layer))
					
				}
				
				// Merge layers
			  msk = new BitmapData(width,height)
				msk.draw(temp)				
				ret.addChild(new Bitmap(msk))
				
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
				var temp:Sprite = new Sprite

				// Draw base
				var tile:fTileMaterial = new fTileMaterial(this.element.scene.materialDefinitions[this.definitionXML.base],this.element)
				temp.addChild(tile.getBump(width,height))
				
				// Draw layers, if any
				var layers:XMLList = this.definitionXML.child("layer")
				for(var i:Number=0;i<layers.length();i++) {
					
				  tile = new fTileMaterial(this.element.scene.materialDefinitions[layers[i].material],this.element)
					var layer:BitmapData = new BitmapData(width,height,true,0x00000000)
					var diffuse:DisplayObject = tile.getBump(width,height)
					layer.draw(diffuse)
					var msk:BitmapData = new BitmapData(width,height,false,0x000000)
					try {
						this.element.scene.noiseDefinitions[layers[i].noise].drawNoise(msk,BitmapDataChannel.RED,this.element.x,this.element.y)
					} catch(e:Error) {
						throw new Error("Filmation Engine Exception: Attempt to use a nonexistent noise definition: '"+layers[i].noise+"'")
					}
					layer.copyChannel(msk,new Rectangle(0, 0, width,height),new Point(0,0),BitmapDataChannel.RED, BitmapDataChannel.ALPHA)
					msk.dispose()
					
					temp.addChild(new Bitmap(layer))
					
				}
				
				// Merge layers
			  msk = new BitmapData(width,height)
				msk.draw(temp)				
				ret.addChild(new Bitmap(msk))
				
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