// AI methods

package org.ffilmation.engine.core {
	
		// Imports
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.logicSolvers.pathfindSolver.*

		/**
		* <p>This object provides access to the AI methods of the engine.</p>
		*
		*/
		public class fAiContainer  {
		
			/**
			* This is the maximum depth pathfinding will reach before failing.
			*/
			public static const MAXSEARCHDEPTH:Number = 200

			// Private properties
			private var scene:fScene

			/**
			* Constructor for the fAiContainer class
			*
			* @param scene The scene associated to this AI
		  *
			* @private
			*/
			function fAiContainer(scene:fScene) {
				 this.scene = scene		 
			}

		  /**
		  * <p>Finds a path between 2 points, using an AStar search algorythm. It works in 3d. This is a CPU-intensive calculation: If you have
		  * several elements trying to find its way around at the same time, it will impact your performance: try to use it sparingly. If you
		  * want an example of how to make a character walk around your scene using this, download the mynameisponcho sources from the download area.</p>
		  *
		  * <p>I took it from <a href="http://blog.baseoneonline.com/?p=87" target="_blank">here</a>. Thank you!</p>
		  *
		  * <p>TODO: 
		  * <ul>
		  * <li>Accept a character as optional parameter and take its dimensions into account.</li>
		  * <li>Include objects and try to find ways around them.</li>
		  * <li>More precise hole calculations. Now it will try to search through any open hole.</li>
		  * </ul></p>
		  *
		  * @param originx Origin point
		  * @param destinyx Destination point
		  * @param withDiagonals Is diagonal movement allowed for this calculation ?
		  *
		  * @return	An array of 3dPoints describing the resulting path. Null if it fails
		  */
		  public function findPath(origin:fPoint3d,destiny:fPoint3d,withDiagonals:Boolean=true):Array {
					return fPathfindSolver.findPathAStar(new fDefaultPathfindCriteria(this.scene,origin,destiny,withDiagonals))
		  }
			
		  /**
		  * <p>Finds a path between 2 points, using an AStar search algorythm and a custom find criteria. It works in 3d. This is a CPU-intensive calculation: If you have
		  * several elements trying to find its way around at the same time, it will impact your performance: try to use it sparingly.</p>
		  *
		  * @param criteria An object implementing the fEnginePathfindCriteria interface that contains the find criteria.
		  *
		  * @return	An array of 3dPoints describing the resulting path. Null if it fails
		  */
		  public function findPathCustomCriteria(criteria:fEnginePathfindCriteria):Array {
					return fPathfindSolver.findPathAStar(criteria)
		  }
		
		
	}
		
		
}
