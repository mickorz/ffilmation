package org.ffilmation.engine.helpers {
	
		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Encapsulates Data passed to the level at creation time
	  */
		public class fTempLevelData {

			// Public properties
	    public var z:Number
			public var floors:Array
			public var walls:Array
			public var objects:Array
			public var characters:Array
			

			// Constructor
			function fTempLevelData(z:Number):void {
			
					this.z = z
					this.floors = new Array			   
					this.walls = new Array			   
					this.objects = new Array			   
					this.characters = new Array			   
			}

		}
}
