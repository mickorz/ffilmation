package org.ffilmation.engine.interfaces {

		// Imports
		import flash.display.*
		import org.ffilmation.engine.core.*

		/**
		* This interface defines methods that any class that is to be used as a material in the engine must implement
		*/
		public interface fEngineMaterial {

			/**
			* Constructor
			* @param definitionXML The material definition data that created this class
			* @param element The element( wall or floor ) where this material will be applied
			*/
			public function fEngineMaterial(definitionXML:XML,element:fRenderableElement);

			/** 
			* Retrieves the diffuse map for this material. If you write custom classes, make sure they return the proper size.
			* 0,0 of the returned DisplayObject corresponds to the top-left corner of material
			*
			* @param width: Requested width
			* @param height: Requested width
			*
			* @return A DisplayObject (either Bitmap or MovieClip) that will be display onscreen
			*
			*/
		  function getDiffuse(width:Number,height:Number):DisplayObject;

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
			function getBump(width:Number,height:Number):DisplayObject;

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
			function getHoles(width:Number,height:Number):Array;
			
			/**
			* Retrieves the graphic element that is to be used to block a given hole when it is closed
			*
			* @param index The hole index, as returned by the getHoles() method
			* @return A MovieClip that will used to close the hole. If null is returned, the hole won't be "closeable".
			*/
			function getHoleBlock(index:Number):MovieClip;
			
			/**
			* Frees all allocated resources for this material. It is called when the scene is destroyed and we want to free as much RAM as possible
			*/
			function dispose():void;
			

		}

}