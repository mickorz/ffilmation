package org.ffilmation.engine.helpers {
	
		// Imports
		import flash.utils.*
		
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* This object defines an area that shares a common zSort value. Each plane generates several of these areas. Then
		* to assign a zIndex to a given cell, these areas a searched to see where the cell belongs.
	  */
		public class fSortArea {

			// Private
			private var i:Number
			private var j:Number
			private var k:Number
			private var width:Number
			private var depth:Number
			private var height:Number
			
			// Public properties
			public var zValue:Number

			// Constructor
			public function fSortArea(i:Number,j:Number,k:Number,width:Number,depth:Number,height:Number,zValue:Number):void {
				
			   this.i = i
			   this.j = j
			   this.k = k
			   this.width = width
			   this.depth = depth
			   this.height = height
			   this.zValue = zValue
			   
			}
			
			// Tests a coordinate against this area
			public function isPointInside(i:Number,j:Number,k:Number):Boolean {
				if(i<this.i || i>this.i+this.width) return false
				if(j<this.j || j>this.j+this.depth) return false
				if(k<this.k || k>this.k+this.height) return false
				return true
			}

		}
		
} 
