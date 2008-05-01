package org.ffilmation.engine.helpers {
	
		// Imports

		/** 
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* This object stores data of a fCellEvent. This data comes from the XML definition for that event
		*
		*/
		public class fCellEventInfo {
		
				/**
				* Stores type of event
				*/
				public var name:String
				
				/**
				* Stores XML of event
				*/
				public var xml:XML


				/**
				* Constructor
				*/
				function fCellEventInfo(xml:XML):void {
					
					this.xml = xml
					this.name = xml.@name[0].toString()
					
				}

		}
		
}