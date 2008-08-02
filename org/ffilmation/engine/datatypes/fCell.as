package org.ffilmation.engine.datatypes {

		// Imports
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.helpers.*
	
		/** 
		* @private
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
				public var i:Number

				/**
				* The y coordinate of this cell in the grid. The measure is array position, not pixels.
				*/
				public var j:Number

				/**
				* The z coordinate of this cell in the grid. The measure is array position, not pixels.
				*/
				public var k:Number

				/**
				* The x coordinate in pixels of the center of this cell grid.
				*/
				public var x:Number

				/**
				* The y coordinate in pixels of the center of this cell grid.
				*/
				public var y:Number

				/**
				* The z coordinate in pixels of the center of this cell grid.
				*/
				public var z:Number

				/**
				* If this cell "touches" any wall or floor, it is stored in this object. This information is used when
				* moving objects throught the scene, in order to detect colisions. When an element moves from one cell
				* to another, walls are cheched to see if any was inbetween
				*/
				public var walls:fCellWalls
				
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
				* This is the list of characters that occupy this cell
				*/
				public var charactersOccupying:Array

				// The following properties are used by pathFinding algorythms
				
				public var g:Number = 0													
				public var h:Number = 0													// Heuristic score
				public var cost:Number = 0											// Movement cost
				public var parent:fCell													// Needed to return a solution (trackback)
				
				public function get f():Number { return g+h }


				/**
				* Constructor
				*/
				function fCell():void {
					
					this.characterShadowCache = new Array
					this.walls = new fCellWalls
					this.events = new Array
					this.elementsInFront = new Array
					this.charactersOccupying = new Array
					
				}

				/**
				* Frees memory allocated by this cell
				*/
				public function dispose():void {
					this.walls.dispose()
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
					if(this.charactersOccupying) {
						for(i=0;i<this.charactersOccupying.length;i++) delete this.charactersOccupying[i]
						this.charactersOccupying = null
					}
					if(this.events) {
						for(i=0;i<this.events.length;i++) delete this.events[i]
						this.events = null
					}
					
				}

		}
		
}