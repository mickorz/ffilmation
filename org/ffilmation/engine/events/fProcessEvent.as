package org.ffilmation.engine.events {

		// Imports
		import flash.events.*
		
		/**
		* <p>The fProcessEvent event class stores information about a process event.</p>
		*
		* <p>Several processes in the filmation engine involve more than one subprocess,
		* and this class stores info about the overall task that is being monitored as
		* well as the status of the current subtask.</p>
		*
		* <p>This allows to have progress bars that go something like:</p>
		* 
		* Loading media file A. 20% done<br>
		* Overall loading process: 12% done
		*
		*/
		public class fProcessEvent extends Event {
		
			 // Public
			 
			 /**
			 * Overall process completion status, from 0 to 100
			 */
			 public var overall:Number
			 
			 /**
			 * Overall process description
			 */
			 public var overallDescription:String

			 /**
			 * Current process completion status, from 0 to 100
			 */
			 public var current:Number
			 
			 /**
			 * Current process description
			 */
			 public var currentDescription:String

			 /**
			 * A boolean value indicating if the overall process is considered done ( same as checking overall = 100 )
			 */
			 public var complete:Boolean
			 
		
			 // Constructor

			 /**
		   * Constructor for the fProcessEvent class.
		   *
			 * @param type The type of the event. Event listeners can access this information through the inherited type property.
			 * 
			 * @param bubbles Determines whether the Event object participates in the bubbling phase of the event flow. Event listeners can access this information through the inherited bubbles property.
 			 *
			 * @param cancelable Determines whether the Event object can be canceled. Event listeners can access this information through the inherited cancelable property.
			 *
		   * @param overall Overall process completion status, from 0 to 100
		   *
		   * @param overallDescription Overall process desccription
		   *
		   * @param current Cverall process completion status, from 0 to 100
		   *
		   * @param currentDescription Cverall process desccription
		   *
			 */
			 function fProcessEvent(type:String,bubbles:Boolean,cancelable:Boolean,overall:Number,overallDescription:String,current:Number,currentDescription:String):void {
			 	
			 		super(type,bubbles,cancelable)
			 		this.overall = overall
			 		this.overallDescription = overallDescription
			 		this.current = current
			 		this.currentDescription = currentDescription
			 		this.complete = overall == 100
		
			 }
			

		}

}



