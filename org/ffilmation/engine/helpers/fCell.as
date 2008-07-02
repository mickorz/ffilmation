package org.ffilmation.engine.helpers {

		// Imports
		import org.ffilmation.engine.elements.*
	
		/** 
		* @private
		* THIS IS A HELPER OBJECT. OBJECTS IN THE HELPERS PACKAGE ARE NOT SUPPOSED TO BE USED EXTERNALLY. DOCUMENTATION ON THIS OBJECTS IS 
		* FOR DEVELOPER REFERENCE, NOT USERS OF THE ENGINE
		*
		* Every scene is fit into a grid that allows to simplify visiblity and projection calculations.
		* This grid is formed of fCells, a container that keeps information necessary to perform all the public
		* rendering calculations
		*/
		public class fCell {
		
				/**
				* The zIndex of a cell indicates the display order. Elements in cells with higher zIndexes cover
				* elements in cells with lower zIndexes
				*/
				public var zIndex:Number
				
				/**
				* The x coordinate of this cell in the grid. The measure is array position, not pixels.
				*/
				public var i:int

				/**
				* The y coordinate of this cell in the grid. The measure is array position, not pixels.
				*/
				public var j:int

				/**
				* The z coordinate of this cell in the grid. The measure is array position, not pixels.
				*/
				public var k:int

				/**
				* The x coordinate in pixels of the center of this cell grid.
				*/
				public var x:int

				/**
				* The y coordinate in pixels of the center of this cell grid.
				*/
				public var y:int

				/**
				* The z coordinate in pixels of the center of this cell grid.
				*/
				public var z:int

				/**
				* If this cell "touches" any wall or floor, it is stored in this object. This information is used when
				* moving objects throught the scene, in order to detect colisions. When an element moves from one cell
				* to another, walls are cheched to see if any was inbetween
				*/
				public var walls:fCellWalls
				
				/**
				* If an object occupies space in the cell, it is stored in this property.
				* This information is used to test object collision
				*/
				public var object:fObject
				
				/**
				* The cell caches an array of visible elements. This array contains a list of all walls and floors "visible"
				* from this cells' center point, along with coverage info. This speeds up light and shadow calculations, as only
				* the fist time a cell is activated the algorythm builds the visibility info
				*/
				public var visibleObjs:Array
				
				/**
				* The max distance from which the visibility info has been calculated
				*/
				public var visibleRange:Number = 0

				/**
				* This is the character Shadow cache for this cell
				*/
				public var characterShadowCache:Array
				
				/**
				* This the list of events (type: fCellEvent) associated to this cell
				*/
				public var events:Array
				
				/**
				* This is the list of elements that "cover" ( once translated and placed onscreen ) this cell
				* It is used to apply camera occlusion
				*/
				public var elementsInFront:Array


				/**
				* Constructor
				*/
				function fCell():void {
					
					this.characterShadowCache = new Array
					this.walls = new fCellWalls
					this.events = new Array
					this.elementsInFront = new Array
					
				}

				function dispose():void {
					this.walls.dispose()
					this.object = null
					if(this.visibleObjs) {
						for(var i:Number=0;i<this.visibleObjs.length;i++) delete this.visibleObjs[i]
						this.visibleObjs = null
					}
					if(this.characterShadowCache) {
						for(i=0;i<this.characterShadowCache.length;i++) delete this.characterShadowCache[i]
						this.characterShadowCache = null
					}
					if(this.elementsInFront) {
						for(i=0;i<this.elementsInFront.length;i++) delete this.elementsInFront[i]
						this.elementsInFront = null
					}
					if(this.events) {
						for(i=0;i<this.events.length;i++) delete this.events[i]
						this.events = null
					}
					
				}

		}
		
}