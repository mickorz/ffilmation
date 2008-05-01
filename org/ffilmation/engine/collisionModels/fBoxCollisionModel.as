package org.ffilmation.engine.collisionModels {

		// Imports
		import flash.geom.Point
		import org.ffilmation.engine.geometry.*
		import org.ffilmation.engine.interfaces.*
		
		/**
		* This is a cilinder-shaped collision model. It is automatically assigned when the object's XML definition uses the BOX Tag
		* @private
		*/
		public class fBoxCollisionModel extends fBox implements fEngineCollisionModel {
			
			// Private vars
			private var definitionXML:XML
			private var _orientation:Number
			private var baseTopView:Array
			private var topView:Array
			
			// Constructor
			public function fBoxCollisionModel(definitionXML:XML):void {
				 
				 this.definitionXML = definitionXML
				 
				 // Parent
				 super(new Number(this.definitionXML.@width[0]),new Number(this.definitionXML.@depth[0]),new Number(this.definitionXML.@height[0]))
				 
				 // Orientation
				 this._orientation = 0
				 
				 // Precalc top view
				 this.baseTopView = new Array
		 		 this.baseTopView.push(new Point(this._width/2,-this._depth/2))
		 		 this.baseTopView.push(new Point(this._width/2,this._depth/2))
		 		 this.baseTopView.push(new Point(-this._width/2,this._depth/2))
		 		 this.baseTopView.push(new Point(-this._width/2,-this._depth/2))
				 this.topView = new Array
		 		 this.topView.push(new Point(this._width/2,-this._depth/2))
		 		 this.topView.push(new Point(this._width/2,this._depth/2))
		 		 this.topView.push(new Point(-this._width/2,this._depth/2))
		 		 this.topView.push(new Point(-this._width/2,-this._depth/2))
				 
			}

			/** 
			* Sets new orientation for this model
			*
			* @param orientation: In degrees, rotation along z-axis that is to be applied to the model. This corresponds to the
			* current orientation of the object who's shape is represented by this model 
			*
			*/
		  public function set orientation(orientation:Number):void {

				// New rotation
		  	this._orientation = orientation
		  	
		  	// Rotate all points from our projection
		  	var sin:Number = Math.sin(orientation*Math.PI/180)
		  	var cos:Number = Math.cos(orientation*Math.PI/180)

			  var q:Number = this.baseTopView.length
			  for(var i:Number=0;i<q;i++) {
			  	var p:Point = this.baseTopView[i]
			  	this.topView[i] = new Point((p.x)*cos - (p.y)*sin,(p.y)*cos + (p.x)*sin)
			  }
		  	
		  	
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
		  	return (Math.max(this._width,this._depth)/2)
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
				
				// Basic test
				if(z<0 || z>this._height) return false
				
				// Rotate point to 0 orientation, so it can be compared with the base model, which is a simpler calculation				
		  	var sin:Number = Math.sin(-this._orientation*Math.PI/180)
		  	var cos:Number = Math.cos(-this._orientation*Math.PI/180)
			  var nx:Number = x*cos - y*sin
			  var ny:Number = y*cos + x*sin
			  var halfWidth = this._width/2
			  var halfDepth = this._depth/2

		  	return (nx<=halfWidth && nx>=-halfWidth && ny<=halfDepth && ny>=-halfDepth)
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