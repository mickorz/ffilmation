package org.ffilmation.engine.events {

		// Imports
		import flash.events.*
		import org.ffilmation.engine.core.*
		
		/**
		* <p>The fCollideEvent event class stores information about a collision event.</p>
		*
		* <p>This event is dispatched when a character in the engine collides whith another solid element in the scene
		* </p>
		*
		*/
		public class fCollideEvent extends Event {
		
			 // Public
			 
			 /**
			 * The element of the scene we collide against
			 */
			 public var victim:fRenderableElement
			 
		
			 // Constructor

			 /**
		   * Constructor for the fMoveEvent class.
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
			 function fCollideEvent(type:String,bubbles:Boolean,cancelable:Boolean,victim:fRenderableElement):void {
			 	
			 		super(type,bubbles,cancelable)
			 		this.victim = victim
		
			 }
			

		}

}



