package org.ffilmation.utils {


		/** 
		* A 2d Vector class
		*
	  */
		public class Vector	{

				/** 
				* X component
				*/
		    public var x:Number;

				/**
				* Y component
				*/
		    public var y:Number;

		    /**
		    * Constructor for this class
		    */
		    public function Vector(vx:Number,vy:Number) {
			    x = vx;
			    y = vy;
		    }
		
		    /**
		     * Generates a string from this vector. Useful to debug
		     * @return A string containing 2d class properties.
		    **/
		    public function toString():String {
			    return ("["+x+","+y+"]")
		    }
		
		    /**
		     * Calculates the dot product of this and given vectors
		     * @param The second vector vector.
		     * @return  returns the dot product of this instance and 'V'.
		    **/
		    public function dotProduct(V:Vector):Number {
			    return (x*V.x)+(y*V.y)
		    }
		
		
		    /**
		     * Calculates normal of this instance vector
		     * @return returns normal of this instance.
		    **/
		    public function norm():Number  {
			    return Math.sqrt((x*x)+(y*y))
		    }
		
		
		    /**
		     * Returns the unit vector of this instance.
		     * @return A new Vector object populated with this instance's unit vector.
		    **/
		    public function unitVector():Vector  {
			    var unit:Vector
			    var norm:Number = this.norm()
		      unit = new Vector(x,y)
			    unit.x /= norm;
			    unit.y /= norm;
			    return unit;
		    }
		
		
		    /**
		     * Normalizes this instance.
		    **/
		    public function normalize(): void  {
			    var norm:Number = this.norm()
			    x /= norm;
			    y /= norm;
		    }
		
		    /**
		     * Returns angle between this instance and given parameter
		     * @param Another vector
		     * @return the angle between this instance and the parameter
		    **/
		    public function angleVector(V:Vector):Number  {
			    return this.dotProduct(V)/(this.norm()*V.norm());
		    }
		
		
		    /**
		     * Defines perpendicular direction vector of this instance.
		     * @return A perpendicular direction vector of this instance.
		    **/
		    public function getPerpendicular():Vector  {
		        return new Vector(-y,x)
		    }
		
		}

}
