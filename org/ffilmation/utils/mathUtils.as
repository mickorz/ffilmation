package org.ffilmation.utils {

		// Imports
		import flash.geom.Point
		
		/** 
		* This class provides various useful math methods
	  */
		public class mathUtils {
		
			// Angle between two points
			public static function getAngle(x1:Number, y1:Number, x2:Number, y2:Number, dist:Number=0):Number {
			   var d:Number = dist || mathUtils.distance(x1,y1,x2,y2)
			   var ret:Number = (Math.asin((y2-y1)/d))
				 if(x1>=x2) ret = Math.PI-ret
				 if(ret<0) ret += 2*Math.PI
				 return ret*180/Math.PI
			}
			
			/** 
			* Distance between two points
			*/
			public static function distance(x1:Number,y1:Number,x2:Number,y2:Number):Number {
			   var dx:Number = x1-x2
			   var dy:Number = y2-y1
			   return Math.sqrt(dx*dx + dy*dy)
			}
			
			/**
			* Distance between two points (3d)
			*/
			public static function distance3d(x1:Number,y1:Number,z1:Number,x2:Number,y2:Number,z2:Number):Number {
			   var dx:Number = x1-x2
			   var dy:Number = y2-y1
			   var dz:Number = z2-z1
			   return Math.sqrt(dx*dx + dy*dy + dz*dz)
			}
			
			/**
			* Finds out if a line an a circle intersect and if so, return the intersection points
			* @return An lineCircleIntersectionResult with the results of the calculation
			* 
			* source: http://keith-hair.net/blog/2008/08/05/line-to-circle-intersection-data/#more-23
			**/
			public static function lineIntersectCircle(A : Point, B : Point, C : Point, r : Number ):lineCircleIntersectionResult {
				
				var result:lineCircleIntersectionResult = new lineCircleIntersectionResult()
				result.inside = false
				result.tangent = false
				result.intersects = false
				result.enter=null
				result.exit=null
				
				var a : Number = (B.x - A.x) * (B.x - A.x) + (B.y - A.y) * (B.y - A.y)
				var b : Number = 2 * ((B.x - A.x) * (A.x - C.x) +(B.y - A.y) * (A.y - C.y))
				var cc : Number = C.x * C.x + C.y * C.y + A.x * A.x + A.y * A.y - 2 * (C.x * A.x + C.y * A.y) - r * r
				var deter : Number = b * b - 4 * a * cc
				
				if (deter <= 0 ) {
					result.inside = false
				} else {
					var e : Number = Math.sqrt (deter)
					var u1 : Number = ( - b + e ) / (2 * a )
					var u2 : Number = ( - b - e ) / (2 * a )
					if ((u1 < 0 || u1 > 1) && (u2 < 0 || u2 > 1)) {
						if ((u1 < 0 && u2 < 0) || (u1 > 1 && u2 > 1)) {
							result.inside = false
						} else {
							result.inside = true
						}
					} else {
						if (0 <= u2 && u2 <= 1) {
							result.enter=Point.interpolate (A, B, 1 - u2)
						}
						if (0 <= u1 && u1 <= 1) {
							result.exit=Point.interpolate (A, B, 1 - u1)
						}
						result.intersects = true;
						if (result.exit != null && result.enter != null && result.exit.equals (result.enter)) {
							result.tangent = true;
						}
					}
				}
				
				return result
				
			}


			/**
			* Find out if two segments intersect and if so, retrieve the point 
			* of intersection
			*
			* source: http://vision.dai.ed.ac.uk/andrewfg/c-g-a-faq.html
			*/
			public static function segmentsIntersect(xa:Number, ya:Number, xb:Number, yb:Number, xc:Number, yc:Number, xd:Number, yd:Number):Point {

        //trace("Intersect "+xa+","+ya+" "+xb+","+yb+" -> "+xc+","+yc+" "+xd+","+yd)
        var result:Point

        var ua_t:Number = (xd-xc)*(ya-yc)-(yd-yc)*(xa-xc)
        var ub_t:Number = (xb-xa)*(ya-yc)-(yb-ya)*(xa-xc)
        var u_b:Number = (yd-yc)*(xb-xa)-(xd-xc)*(yb-ya)

        if (u_b!=0)  {

            var ua:Number = ua_t/u_b;
            var ub:Number = ub_t/u_b;

            if (ua>=0 && ua<=1 && ub>=0 && ub<=1) {
                result = new Point(xa+ua*(xb-xa),ya+ua*(yb-ya))
            } else result = null
        }
        else result = null

        return result
			
			}
			
			/**
			* Find out if two lines intersect and if so, retrieve the point 
			* of intersection
			*
			* source: http://members.shaw.ca/flashprogramming/wisASLibrary/wis/math/geom/intersect2D/Intersect2DLine.as
			*
			*/
			public static function linesIntersect(xa:Number,ya:Number, xb:Number, yb:Number, xc:Number, yc:Number, xd:Number, yd:Number):Point {
	    
        var result:Point

        var ua_t:Number = (xd-xc)*(ya-yc)-(yd-yc)*(xa-xc)
        var ub_t:Number = (xb-xa)*(ya-yc)-(yb-ya)*(xa-xc)
        var u_b:Number = (yd-yc)*(xb-xa)-(xd-xc)*(yb-ya)

        if (u_b!=0)  {
            var ua:Number = ua_t/u_b;
            var ub:Number = ub_t/u_b;
            result = new Point(xa+ua*(xb-xa),ya+ua*(yb-ya))
        }
        else result = null
        return result
		}

	}

}