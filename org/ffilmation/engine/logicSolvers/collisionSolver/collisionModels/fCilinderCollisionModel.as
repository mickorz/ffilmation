package org.ffilmation.engine.logicSolvers.collisionSolver.collisionModels {

		// Imports
		import flash.geom.Point
		import org.ffilmation.utils.mathUtils
		import org.ffilmation.engine.datatypes.*
		
		/**
		* This is a cilinder-shaped collision model. It is automatically assigned when the object's XML definition uses the CILINDER Tag
		* @private
		*/
		public class fCilinderCollisionModel extends fCilinder implements fEngineCollisionModel {
			
			// Private vars
			private var definitionXML:XML
			private var _orientation:Number
			private var topView:Array
			
			// Constructor
			public function fCilinderCollisionModel(definitionXML:XML):void {
				 
				 this.definitionXML = definitionXML
				 
				 // Parent
				 super(new Number(this.definitionXML.@radius[0]),new Number(this.definitionXML.@height[0]))
				 
				 // Orientation
				 this._orientation = 0
				 
				 // Precalc top view
				 this.topView = new Array
				 for(var i:Number=0;i<360;i+=20) {
				 		var angle:Number = i*Math.PI/180
				 		this.topView.push(new Point(this._radius*Math.cos(angle),this._radius*Math.sin(angle)))
				 }
				 
			}

			/** 
			* Sets new orientation for this model
			*
			* @param orientation: In degrees, rotation along z-axis that is to be applied to the model. This corresponds to the
			* current orientation of the object who's shape is represented by this model 
			*
			*/
		  public function set orientation(orientation:Number):void {
		  	this._orientation = orientation
		  }
		  public function get orientation():Number {
		  	return this._orientation
		  }
		  

			/** 
			* Sets new height for this model
			*
			* @param height: New height
			*/
		  public function set height(height:Number):void {
				this._height = height
			}
		  public function get height():Number {
		  	return this._height
			}
			
		  /**
		  * Returns radius of an imaginary cilinder that encloses all points in this model. The engine uses this value for internal optimizations
		  *
		  * @return The desired radius
		  */
		  public function getRadius():Number {
		  	return this._radius
		  }

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
		  public function testPoint(x:Number,y:Number,z:Number):Boolean {
		  	return ((z>=0) && (z<=this._height) && (mathUtils.distance(0,0,x,y)<this._radius))
		  }
		  
		  /**
		  * Returns an array of points defining the polygon that represents this model from a "top view", ignoring the size along z-axis
		  * of this collision model
		  *
			* @return An array of Points		  
		  */
		  public function getTopPolygon():Array {
		  	return this.topView
		  }

		}
	
}