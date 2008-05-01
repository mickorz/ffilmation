package org.ffilmation.engine.helpers {
	
		// Imports

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Caches projection information for a given object and projection point
	  */
		public class fObjectProjectionCache {

			// Public properties
	    public var projection:fObjectProjection
			public var floorz:Number
			public var x:Number
			public var y:Number
			public var z:Number
			
			// Constructor
			function fObjectProjectionCache():void {
			
			}
			
			/**
			* Test values against cache key
			*/
			public function test(floorz:Number,x:Number,y:Number,z:Number):Boolean {
					return (floorz==this.floorz && x==this.x && y==this.y && z==this.z)
			}

			/**
			* Updates values 
			*/
			public function update(floorz:Number,x:Number,y:Number,z:Number,proj:fObjectProjection):void {
					this.floorz = floorz
					this.x = x
					this.y = y
					this.z = z
					this.projection = proj
			}


		}
		
} 
