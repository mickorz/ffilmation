package org.ffilmation.engine.events {

		// Imports
		import flash.events.*
		
		/**
		* <p>The fEventIn event class stores information about an IN event.</p>
		*
		* <p>This event is dispatched whenever a character in the engine moves into a cell
		* where an XML even was defined</p>
		*
		*/
		public class fEventIn extends Event {
		
			 // Public
			 
			 /**
			 * Stores name of event
			 */
			 public var name:String
				
			 /**
			 * Stores XML of event
			 */
			 public var xml:XML
			 
		
			 // Constructor

			 /**
		   * Constructor for the fEventIn class.
		   *
			 * @param type The type of the event. Event listeners can access this information through the inherited type property.
			 * 
			 * @param bubbles Determines whether the Event object participates in the bubbling phase of the event flow. Event listeners can access this information through the inherited bubbles property.
 			 *
			 * @param cancelable Determines whether the Event object can be canceled. Event listeners can access this information through the inherited cancelable property.
			 *
		   * @param name Name that was given to this event in its XML definition
		   *
		   * @xml XML node associated tot he event in the XMl file
		   *
			 */
			 function fEventIn(type:String,bubbles:Boolean,cancelable:Boolean,name:String,xml:XML):void {
			 	
			 		super(type,bubbles,cancelable)
			 		this.name = name
			 		this.xml = xml
		
			 }
			

		}

}



