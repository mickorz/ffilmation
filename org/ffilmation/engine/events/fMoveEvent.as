package org.ffilmation.engine.events {

		// Imports
		import flash.events.*
		
		/**
		* <p>The fMoveEvent event class stores information about a move event.</p>
		*
		* <p>This event is dispatched whenever an element in the engine changes position.
		* This allows the engine to track objects and rerender the scene, as well as programming
		* reactions such as one element following another</p>
		*
		*/
		public class fMoveEvent extends Event {
		
			 // Public
			 
			 /**
			 * The increment of the x coordinate that corresponds to this movement. Equals new position - last position
			 */
			 public var dx:Number
			 
			 /**
			 * The increment of the y coordinate that corresponds to this movement. Equals new position - last position
			 */
			 public var dy:Number

			 /**
			 * The increment of the z coordinate that corresponds to this movement. Equals new position - last position
			 */
			 public var dz:Number
			 
		
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
		   * @param dx The increment of the x coordinate that corresponds to this movement
		   *
		   * @param dy The increment of the y coordinate that corresponds to this movement
		   *
		   * @param dz The increment of the z coordinate that corresponds to this movement
		   *
		   *
			 */
			 function fMoveEvent(type:String,bubbles:Boolean,cancelable:Boolean,dx:Number,dy:Number,dz:Number):void {
			 	
			 		super(type,bubbles,cancelable)
			 		this.dx = dx
			 		this.dy = dy
			 		this.dz = dz
		
			 }
			

		}

}



