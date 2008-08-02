package org.ffilmation.engine.logicSolvers.collisionSolver.collisionModels {

		// Imports
		import flash.display.*

		/**
		* This interface defines methods that any class that is to be used as a collision model in the engine must implement.<br>
		* A collision model is a matematical representation of an object's geometry that is ised to manage collisions.
		* For example, a box is a good collision model for a car, and a cilinder is a good collision model for people.<br>
		* Collision models need to be simple geometry so the engine can solve collisions fast.
		* @private
		*/
		public interface fEngineCollisionModel {

			/** 
			* Sets new orientation for this model
			*
			* @param orientation: In degrees, rotation along z-axis that is to be applied to the model. This corresponds to the
			* current orientation of the object who's shape is represented by this model 
			*
			*/
		  function set orientation(orientation:Number):void;
		  function get orientation():Number;

			/** 
			* Sets new height for this model
			*
			* @param height: New height
			*/
		  function set height(height:Number):void;
		  function get height():Number;
		  
		  /**
		  * Returns radius of an imaginary cilinder that encloses all points in this model. The engine uses this value for internal optimizations
		  *
		  * @return The desired radius
		  */
		  function getRadius():Number;

			/** 
			* Test if given point is inside the bounds of this collision model.
			*
			* @param x: Coordinate of tested point
			* @param y: Coordinate of tested point
			* @param z: Coordinate of tested point
			*
			* @return Boolean value indicating if the point is inside
			*
			*/
		  function testPoint(x:Number,y:Number,z:Number):Boolean;
		  
		  /**
		  * Returns an array of points defining the polygon that represents this model from a "top view", ignoring the size along z-axis
		  * of this collision model
		  *
			* @return An array of Points		  
		  */
		  function getTopPolygon():Array;

		}

}