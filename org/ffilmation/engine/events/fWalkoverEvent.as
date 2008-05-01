package org.ffilmation.engine.events {

		// Imports
		import flash.events.*
		import org.ffilmation.engine.core.*
		
		/**
		* <p>The fWalkoverEvent event class stores information about a Walkover event.</p>
		*
		* <p>This event is dispatched when a character in the engine walks over a non-solid object in the scene. This is useful to collect items, for example.
		* </p>
		*
		*/
		public class fWalkoverEvent extends Event {
		
			 // Public
			 
			 /**
			 * The element of the scene we walk over
			 */
			 public var victim:fRenderableElement
			 
		
			 // Constructor

			 /**
		   * Constructor for the fWalkoverEvent class.
		   *
			 * @param type The type of the event. Event listeners can access this information through the inherited type property.
			 * 
			 * @param bubbles Determines whether the Event object participates in the bubbling phase of the event flow. Event listeners can access this information through the inherited bubbles property.
 			 *
			 * @param cancelable Determines whether the Event object can be canceled. Event listeners can access this information through the inherited cancelable property.
			 *
		   * @param victim The element of the scene we collide against
		   *
			 */
			 function fWalkoverEvent(type:String,bubbles:Boolean,cancelable:Boolean,victim:fRenderableElement):void {
			 	
			 		super(type,bubbles,cancelable)
			 		this.victim = victim
		
			 }
			

		}

}



