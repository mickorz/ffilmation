package org.ffilmation.engine.materials {

		// Imports
		import flash.display.*
		import flash.geom.*
		import flash.filters.*
		import flash.utils.getDefinitionByName
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.helpers.*
		
		/**
		* This is the class for the Fence material. Keep in mind that holes have an impact in performace of the collision an light algorythms
		* and therefore, this material has to be used with moderation.
		*
		* <p>This class is automatically selected when you define a material as "fence" in your XMLs. You don't need to use
		* it or worry about how it works</p>
		* @private
		*/
		public class fFenceMaterial implements fEngineMaterial {
			
			// Private vars
			private var definition:fMaterialDefinition	// Definition data
			
			private	var width:Number										// Door size and position
			private	var gap:Number
			private	var irregular:Number
			
			// Constructor
			public function fFenceMaterial(definition:fMaterialDefinition):void {
				this.definition = definition
				
				
				// Retrieve door data
				this.width = new Number(this.definition.xmlData.width)
				this.gap = new Number(this.definition.xmlData.gap)
				this.irregular = new Number(this.definition.xmlData.irregular)
				
			}

			/**
			* Frees all allocated resources for this material. It is called when the scene is destroyed and we want to free as much RAM as possible
			*/
			public function dispose():void {
				this.definition = null
				
			}
			
			/** 
			* Retrieves the diffuse map for this material. If you write custom classes, make sure they return the proper size.
			* 0,0 of the returned DisplayObject corresponds to the top-left corner of material
			*
			* @param element: Element where this map is to be applied
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return A DisplayObject (either Bitmap or MovieClip) that will be display onscreen
			*
			*/
			public function getDiffuse(element:fRenderableElement,width:Number,height:Number):DisplayObject {
				
				var ret:Sprite = new Sprite

				// Draw base
				var tile:fMaterial = fMaterial.getMaterial(this.definition.xmlData.base)
				var base:BitmapData = new BitmapData(width,height,true,0x000000)
				base.draw(tile.getDiffuse(element,width,height))

				ret.addChild(new Bitmap(base,"auto",true))
				
				return ret
			}

			/** 
			* Retrieves the bump map for this material. If you write custom classes, make sure they return the proper size
			* 0,0 of the returned DisplayObject corresponds to the top-left corner of material
			*
			* @param element: Element where this map is to be applied
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return A DisplayObject (either Bitmap or MovieClip) that will used as BumpMap. If it is a MovieClip, the first frame will we used
			*
			*/
			public function getBump(element:fRenderableElement,width:Number,height:Number):DisplayObject {
				var ret:Sprite = new Sprite

				// Draw base
				var tile:fMaterial = fMaterial.getMaterial(this.definition.xmlData.base)
				var base:BitmapData = new BitmapData(width,height,true,0x000000)
				base.draw(tile.getBump(element,width,height))

				ret.addChild(new Bitmap(base,"auto",true))
				
				return ret
			}

			/** 
			* Retrieves an array of holes (if any) of this material. These holes will be used to render proper lights and calculate collisions
			* and bullet impacts
			*
			* @param element: Element where the holes will be applied
			* @param width: Requested width
			* @param height: Requested height
			*
			* @return An array of Rectangle objects, one for each hole. Positions and sizes are relative to material origin of coordinates
			*
			*/
			public function getHoles(element:fRenderableElement,width:Number,height:Number):Array {
				
				var nHoles:Number = Math.floor(width/(this.width+this.gap))
				var ret:Array = new Array
				var offset:Number = width-(nHoles*this.width)-(nHoles-1)*this.gap
				
				// Base holes
				for(var i:Number=0;i<nHoles;i++) ret.push(new Rectangle(offset+(this.width+this.gap)*i,0,this.gap,height))
				
				// Iregularity
				if(this.irregular!=0) {
					var n:Number = offset+this.gap
					do {
						ret.push(new Rectangle(n,0,this.width,Math.random()*this.irregular*height/100))
						n+=this.width+this.gap
					} while(n<width-this.width)
				}
				
				return ret 
			}

			/**
			* Retrieves the graphic element that is to be used to block a given hole when it is closed
			*
			* @param index The hole index, as returned by the getHoles() method
			* @return A Movieclip that will used to close the hole. If null is returned, the hole won't be "closeable".
			*/
			public function getHoleBlock(element:fRenderableElement,index:Number):MovieClip {
				
				return null
				
			}


		}

}