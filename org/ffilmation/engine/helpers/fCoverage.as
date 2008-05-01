package org.ffilmation.engine.helpers {

		/**
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* The fCoverage class provides constants for the return values of the testShadow methods in fRenderableElements
		*/
		public class fCoverage {
		
		   /**
		   * Constant for "totally covered" result
		   */
			 public static const COVERED:int = 1
			 
		   /**
		   * Constant for "receives shadow" result
		   */
			 public static const SHADOWED:int = 2


		   /**
		   * Constant for "doesn't receive shadow" result
		   */
			 public static const NOT_SHADOWED:int = 3
			 
		}
		
		
}