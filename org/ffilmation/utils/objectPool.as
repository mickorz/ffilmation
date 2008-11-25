package org.ffilmation.utils {

		// Imports
		import flash.display.*
		import flash.utils.*
		import flash.geom.*
		
		/** 
		* <p>Object pooling is the process of storing objects in a pool when they are not in use so as to avoid the
		* overhead of creating them again and again. In AS3, objects that are tied to the library are expensive
		* to create. By storing them in a pool for later use you can greatly reduce memory usage and save a handful
		* of milliseconds every frame. ( This definition was copied from here http://mikegrundvig.blogspot.com/2007/05/as3-is-fast.html)</p>
		*
		* <p>This class will return instancies of any given class. When an object is no longer used, if you return it
		* to the pool it will be available to be used again. In a good implementation there would be some sort of factory
		* interface and you would provide an initialization method for each class to ensure properties are properly
		* initialized, but this is not the case here.</p>
		*
		* <p>The engine uses this pool mainly to reuse Sprites and MovieClips, which are very expensive to instantiate. You can
		* use it for you own projects if you want too</p>
		*
		* @see http://mikegrundvig.blogspot.com/2007/05/as3-is-fast.html
		*/
		public class objectPool {
			
			/** @private */
			private static var classInstances:Dictionary = new Dictionary(false)
		
			/**
			* This method returns an instance of a given Class. If some is available to be reused, that one is used. Otherwise a new instance
			* will be created.
			*
			* @param c The Class that is to be instantiated
			* @return An instance of the given class. You will need to cast it into the appropiate type
			*/
			public static function getInstanceOf(c:Class):Object {
				
				// Retrieve list of available objects for this class
				if(!objectPool.classInstances[c]) objectPool.classInstances[c] = new Array
				var instances:Array = objectPool.classInstances[c]
				
				// Is it empty ? Then add one
				if(instances.length==0) {
					instances.push(new c())
				}
				
				// Return
				return instances.pop()

			}
			
			/**
			* Use this method to return unused objects to the pool and make them available to be used again later. Make sure you remove old
			* references to this object or you will get all sorts of weird results.
			*
			* <p>For convenience, if the instance is a DisplayObject, its coordinates, transform values, filters, etc. are reset.</p>
			*
			* @param object The object you are returning to the pool
			*/
			public static function returnInstance(object:Object):void {

				if(!object) return
				var c:Class = object.constructor
				
				// Reset display objects
				if(object is MovieClip) {
					var m:MovieClip = object as MovieClip
					m.gotoAndStop(1)
				}

				if(object is Sprite) {
					var s:Sprite = object as Sprite
					s.graphics.clear()
				}

				if(object is DisplayObject) {
					var d:DisplayObject = object as DisplayObject
					d.x = 0
					d.y = 0
					d.alpha = 1
					d.blendMode = BlendMode.NORMAL
					d.cacheAsBitmap = false
					d.filters = []
					d.mask = null
					d.rotation = 0
					d.scaleX = 1
					d.scaleY = 1
					d.scrollRect = null
					d.visible = true
					d.transform.matrix = new Matrix()
					d.transform.colorTransform = new ColorTransform()
					
					
				}


				// Retrieve list of available objects for this class
				if(!objectPool.classInstances[c]) objectPool.classInstances[c] = new Array
				var instances:Array = objectPool.classInstances[c]
				
				instances.push(object)

			}

			/**
			* Use this method delete stored instances and free some memory
			*
			* @param c The Class whose stored instances are to be flushed. Pass nothing or null to flush them all.
			*/
			public static function flush(c:Class=null):void {
				
				if(c) objectPool.classInstances[c] = null
				else {
					for(var i in objectPool.classInstances) objectPool.classInstances[i] = null
				}

			}
			
		}

}