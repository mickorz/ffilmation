package org.ffilmation.engine.core {

		// Imports
		import flash.system.*
		import flash.net.*
		import flash.utils.*
		import flash.events.*
		import flash.display.*
		import flash.geom.Rectangle
		import org.ffilmation.engine.interfaces.fEngineSceneRetriever
		
		
		/**
		* <p>The fEngine class is the main class in the game engine.</p>
		*
		* <p>Use the fEngine class to create and attach game scenes to your game.</p>
		*
		* <p>You can also use it to load external swfs containing media you want to add to you scenes.</p>
		*
		* <p>Once the scenes are created you can go from one to another using the methods in
		* the fEngine class. The class handles all the drawing and screen refreshing.</p>
		*
		* @example The following code sets a basic isometric application with one scene
		*
		* <listing version="3.0">
		* // Create container
		* var filmationTest:Sprite = new Sprite()
		* addChild(filmationTest)
		* filmationTest.x = 0
		* filmationTest.y = 100
		* 
		* // Create engine
		* var film = new fEngine(filmationTest)
		* 
		* // Create scene and listen to load events
		* var scenel = film.createScene(new fSceneLoader("western.xml"),800,400)
		* scenel.addEventListener(fScene.CHANGESTAT, actionHandler)
		* scenel.addEventListener(fScene.LOAD, loadHandler)

		* function actionHandler(evt:Event) {
		*   trace("EVENT "+evt.target.stat)
		* }
		*
		* function loadHandler(evt:Event) {
		* 	// Scene is loaded and ready
		* 
		* 	// Create a camera and make it active
		* 	var cam = scenel.createCamera()
		* 	scenel.setCamera(cam)
		* 
		* 	// Render
		* 	scenel.render()
		* 	film.showScene(scenel)
		* }		
		*
		* </listing>
		*
		*/
		public class fEngine extends EventDispatcher {
		
			 // Constants
			 
			 /**
		   * This constant is used everywhere to apply perspective correction to all heights
		   * @private
			 */
			 public static const DEFORMATION:Number = 0.79
			 
		   
		   /** @private */
		   public static var stage:Stage


			 /**
 			 * The fEngine.MEDIALOADPROGRESS constant defines the value of the 
 			 * <code>type</code> property of the event object for a <code>enginemedialoadprogress</code> event.
 			 * The event is dispatched when there is a progress in loading an external media file, allowing to update a progress bar, for example.
 			 * 
 			 */
 		   public static const MEDIALOADPROGRESS:String = "enginemedialoadprogress"
       
			 /**
 			 * The fEngine.MEDIALOADCOMPLETE constant defines the value of the 
 			 * <code>type</code> property of the event object for a <code>enginemedialoadcomplete</code> event.
 			 * The event is dispatched when the external media file finishes loading.
 			 * 
 			 */
 		   public static const MEDIALOADCOMPLETE:String = "enginemedialoadcomplete"


			 // Static properties that define graphic options
			 
			 /**
			 * This property enables/disables shadow projection of objects
			 */
			 private static var _objectShadows:Boolean = true

			 /**
			 * This property enables/disables shadow projection of characters
			 */
			 private static var _characterShadows:Boolean = true
			 
			 /**
			 * This property defines the quality at which object and character shadows are rendered
			 */
			 private static var _shadowQuality:int = fShadowQuality.BEST


			 /**
			 * This property enables/disables bumpmapping globally. Please note that for the bumpMapping to work in a given surface and light, the surface
			 * will need a bumpMap definition and the light must be defined as bumpmapped. Beware that only fast computers will be able to handle this
			 * in realtime
			 */
			 private static var _bumpMapping:Boolean = false

			 // Static private
		   private static var engines:Array = new Array
		   																	  // All engines
		   																	  

		   private static var media:Array = new Array
		   																		// List of media files that have already been loaded
		   																		// Static so it wotks with several engines ( eventhought I can't think of an scenario where you
		   																		// would want more than one engine

			 // Private
		   public var container:Sprite    		// Main moviecontainer
		   private var scenes:Array           // List of scenes
		   private var current: fScene				// fScene currently displayed

		
			 // Constructor

			 /**
		   * Constructor for the fEngine class.
		   *
		   * @param container An sprite object where the engine will draw your game
			 */
			 function fEngine(container:Sprite):void {
		
					this.container = container
					this.scenes	= new Array
					this.current = null
					
					// Arrg dirty trick !! So I have acces to onenterframe events from anywhere in the engine
					if(!fEngine.stage) fEngine.stage = container.stage
					
					// Add engine to list of all engines
					fEngine.engines[fEngine.engines.length] = this
			 }
			
			 /**
			 * This method loads an external media file. Once the media file is loaded, the symbols in that file can
			 * be used in you scene definitions. Listen to the engine's MEDIALOADPROGRESS and MEDIALOADCOMPLETE to
			 * control the process. The class checks if the media is already loaded to avoid duplicate loads.
			 *
			 * @param src Path to the swf file you want to load
			 *
			 */
			 public function loadMedia(src:String) {
			 	
				 	if(fEngine.media[src]==null) {
				 	
				 		// This file is not loaded
				 		fEngine.media[src] = true
				 		
				 		var cLoader:Loader = new Loader()
				 		var cont:LoaderContext = new LoaderContext(true,ApplicationDomain.currentDomain)
				  	cLoader.load(new URLRequest(src),cont)
				  	cLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.loadComplete)
				  	cLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,this.loadProgress)
				  
					} else {
						
						// Already loaded
						this.dispatchEvent(new Event(fEngine.MEDIALOADCOMPLETE))
					
					}
			 	
			 }

			 private function loadComplete(event:Event):void {
			
			   	this.dispatchEvent(new Event(fEngine.MEDIALOADCOMPLETE))

			 }
			
			 private function loadProgress(event:ProgressEvent):void {
			 	
			 	  var ret:ProgressEvent = new ProgressEvent(fEngine.MEDIALOADPROGRESS)
			 	  ret.bytesLoaded = event.bytesLoaded
			 	  ret.bytesTotal = event.bytesTotal
			    dispatchEvent(ret)
			   
			 }

			 /**
		   * This method creates an scene from an XML definition file. The scene starts loading and
		   * compiling at this moment, but will not be ready to use yet. You should wait for the scene's LOAD
		   * event before making it active
		   *
		   * @param retriever Any class that implements the fEngineSceneRetriever interface
			 *
			 * @param width Width of the viewport, in pixels. This avoids the need of masking the whole sprite		   
		   *
			 * @param height Height of the viewport, in pixels. This avoids the need of masking the whole sprite		   
			 *
		   * @return A fScene Object.
			 */
			 public function createScene(retriever:fEngineSceneRetriever,width:Number,height:Number):fScene {
		
		   		// Create container for scene
		   		var nSprite:Sprite = new Sprite()

		   		// Create scene
		   		var nfScene:fScene = new fScene(this,nSprite,retriever,width,height)
		
		   		// Add to list and return
		   		this.scenes[this.scenes.length] = nfScene
		   		return nfScene
		   		
		   }
		
			 /**
		   * Makes active one scene in the Engine. Only one scene can be active ( visible ) at the same time.
		   * The current active scene, if any, will me moved to the inactive scene list
		   *
		   * @param sc The fScene you want to activate
		   */
			 public function showScene(sc:fScene):void {
			 	
			 	  if(this.current!=null) {
			 	  	this.current.disable()
			 	  	this.container.removeChild(this.current.container)
			 	  }
			 	  this.container.addChild(sc.container)
			 	  this.current = sc
			 	  
			 	  // Resize viewable area
			 	  this.container.scrollRect = new Rectangle(0, 0, sc.viewWidth, sc.viewHeight)
			 	  
			 	  // Enable
		 	  	this.current.enable()

			 }

			 /**
		   * Hides / disables a scene
		   *
		   * @param sc The fScene you want to hide
		   */
			 public function hideScene(sc:fScene):void {
			 	
			 	  if(this.current==sc) {
			 	  	this.current.disable()
			 	  	this.container.removeChild(this.current.container)
			 	    this.current = null
			 	  }

			 }
			 
			 
			 // SET AND GET METHODS

			 /**
			 * This property enables/disables bumpmapping globally. Please note that for the bumpMapping to work in a given surface and light, the surface
			 * will need a bumpMap definition and the light must be defined as bumpmapped. Beware that only fast computers will be able to handle this
			 * in realtime
			 */			 
			 public static function get bumpMapping():Boolean {
         return fEngine._bumpMapping
       }

       public static function set bumpMapping(bmp:Boolean):void {
         fEngine._bumpMapping = bmp
         
         // Update scenes
         for(var i:Number=0;i<fEngine.engines.length;i++) {
         	
         		var e:fEngine = fEngine.engines[i]
            for(var j:Number=0;j<e.scenes.length;j++) {
            	
            	var s:fScene = e.scenes[j]
							// Render again
            	s.render()
         		
         	  }
         }
       
       }			 

			 /**
			 * This property enables/disables shadow projection of objects
			 */
			 public static function get objectShadows():Boolean {
         return fEngine._objectShadows
       }

       public static function set objectShadows(shd:Boolean):void {
       	
         fEngine._objectShadows = shd

         // Update scenes
         for(var i:Number=0;i<fEngine.engines.length;i++) {
         	
         		var e:fEngine = fEngine.engines[i]
            for(var j:Number=0;j<e.scenes.length;j++) {
            	
            	var s:fScene = e.scenes[j]
            	s.resetGrid()
							// Render again
							s.resetShadows()
            	s.render()
         		
         	  }
         }

       }			 

			 /**
			 * This property enables/disables shadow projection of characters
			 */
			 public static function get characterShadows():Boolean {
         return fEngine._characterShadows
       }

       public static function set characterShadows(shd:Boolean):void {

         fEngine._characterShadows = shd

         // Update scenes
         for(var i:Number=0;i<fEngine.engines.length;i++) {
         	
         		var e:fEngine = fEngine.engines[i]
            for(var j:Number=0;j<e.scenes.length;j++) {
            	
            	var s:fScene = e.scenes[j]
							// Render again
							s.resetShadows()
            	s.render()
         		
         	  }
         }

       }			 


			 /**
			 * This property defines the quality at which object and character shadows are rendered
			 *
			 * @see org.ffilmation.engine.core.fShadowQuality
			 */
			 public static function get shadowQuality():int {
         return fEngine._shadowQuality
       }

       public static function set shadowQuality(shd:int):void {

         fEngine._shadowQuality = shd

         // Update scenes
         for(var i:Number=0;i<fEngine.engines.length;i++) {
         	
         		var e:fEngine = fEngine.engines[i]
            for(var j:Number=0;j<e.scenes.length;j++) {
            	
            	var s:fScene = e.scenes[j]
							// Render again
							s.resetShadows()
            	s.render()
         		
         	  }
         }

       }			 


		}

}



