package org.ffilmation.engine.interfaces {

		// Imports
		import flash.display.*
		import flash.events.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*

		/**
		* This interface defines methods that any class that is to be used as a bullet renderer must implement.
		*/
		public interface fEngineBulletRenderer {

			/** 
			* This is the initialization method
			*
			* @param bullet The bullet object that we need to initialize
			*/
		  function init(bullet:fBullet):void;

			/** 
			* This method updates the drawing of the bullet. The engine already moves the bullet's sprite to its new position.
			* So if the bullet doesn't change its appearance, updating is not needed
			*
			* @param bullet The bullet object that is to be updated
			*/
			function update(bullet:fBullet):void;

			/** 
			* When the bullet dissapears, this is called
			*
			* @param bullet The bullet object that is to cleared
			*/
			function clear(bullet:fBullet):void;

		}

}
