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
			   var ret:Number = -(Math.asin((y2-y1)/d))
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