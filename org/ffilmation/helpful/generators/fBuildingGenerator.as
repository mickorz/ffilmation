package org.ffilmation.helpful.generators {

		// Imports
		import flash.net.*
		import flash.events.*
		import flash.utils.*
		import flash.system.*

		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.interfaces.*
		
		
		/**
		* The building generator is used to build speed up the process of creating houses an buildings
    *
    * @example Here's an example of using this generator in a scene definition XML
    *
	  * <listing version="3.0">
	  *
	  * </listing>
	  *
	  * <br><b>amount</b>: Number of elements to be scattered
	  *
		*/
		public class fBuildingGenerator extends EventDispatcher implements fEngineGenerator {
			
		  // Private data used by this generator
			private var id:Number
		  private var data:XMLList
		  private var scene:fScene
			
			// Result
			private var result:Array
		  
		  /** @private */
		  public function fBuildingGenerator() {
		  	
		  }
		  
		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#generate
		  */
		  public function generate(id:Number,scene:fScene,data:XMLList):EventDispatcher {
		  	
				// Init
				this.id = id
				this.scene = scene
				this.data = data
				this.result = new Array
				
				// Generator parameters
				// Geometry
				var originx:Number = parseInt(this.data.geometry.position.@x)
				var originy:Number = parseInt(this.data.geometry.position.@y)
				var originz:Number = parseInt(this.data.geometry.position.@z)
				var width:Number = parseInt(this.data.geometry.width)
				var depth:Number = parseInt(this.data.geometry.depth)
				
				var minimum:Number = parseInt(this.data.geometry.floors.minimum)
				var maximum:Number = parseInt(this.data.geometry.floors.maximum)
				var floors:Number = Math.round(minimum+(maximum-minimum)*Math.random())
				
				minimum = parseInt(this.data.geometry.floorHeight.minimum)
				maximum = parseInt(this.data.geometry.floorHeight.maximum)
				var floorHeight:Number = Math.round(minimum+(maximum-minimum)*Math.random())
				floorHeight = this.scene.levelSize*(Math.floor(floorHeight/this.scene.levelSize))
				

				// Materials: Floors				
					var candidates:Array = new Array()
					for(var j:Number=0;j<this.data.materials.floors.child("candidate").length();j++) candidates.push( { def:this.data.materials.floors.child("candidate")[j], weight:parseInt(this.data.materials.floors.child("candidate")[j].@weight)} )
					
					// Normalize weights
					var total:Number = 0
					for(j=0;j<candidates.length;j++) {
						total+=candidates[j].weight
						if(j!=0) candidates[j].weight+=candidates[j-1].weight
					}
					for(j=0;j<candidates.length;j++) candidates[j].weight/=total
					
					// Select floor
					var random:Number = Math.random()
					for(var candidate:Number=0;candidates[candidate].weight<random;candidate++);
					var floorMaterial:XML = candidates[candidate].def
					
					
				// Materials: Roof				
					candidates = new Array()
					for(j=0;j<this.data.materials.roof.child("candidate").length();j++) candidates.push( { def:this.data.materials.roof.child("candidate")[j], weight:parseInt(this.data.materials.roof.child("candidate")[j].@weight)} )
					
					// Normalize weights
					total = 0
					for(j=0;j<candidates.length;j++) {
						total+=candidates[j].weight
						if(j!=0) candidates[j].weight+=candidates[j-1].weight
					}
					for(j=0;j<candidates.length;j++) candidates[j].weight/=total
					
					// Select roof
					random = Math.random()
					for(candidate=0;candidates[candidate].weight<random;candidate++);
					var roofMaterial:XML = candidates[candidate].def


				// Materials: wall
					candidates = new Array()
					for(j=0;j<this.data.materials.walls.child("candidate").length();j++) candidates.push( { def:this.data.materials.walls.child("candidate")[j], weight:parseInt(this.data.materials.walls.child("candidate")[j].@weight)} )
					
					// Normalize weights
					total = 0
					for(j=0;j<candidates.length;j++) {
						total+=candidates[j].weight
						if(j!=0) candidates[j].weight+=candidates[j-1].weight
					}
					for(j=0;j<candidates.length;j++) candidates[j].weight/=total
					
					// Select wall
					random = Math.random()
					for(candidate=0;candidates[candidate].weight<random;candidate++);
					var wallMaterial:XML = candidates[candidate].def

				// Create TAGS
				for(j=0;j<floors;j++) {
					var wall1:String = wallMaterial.@walldefinition
					var wall2:String = wallMaterial.@walldefinition
					var wall3:String = wallMaterial.@walldefinition
					if(j==0) wall3=wallMaterial.@doordefinition
					var wall4:String = wallMaterial.@walldefinition
					this.result.push('<box id="Building_'+this.id+'_Floor_'+j+'" x="'+originx+'" y="'+originy+'" z="'+(originz+j*floorHeight)+'" sizex="'+width+'" sizey="'+depth+'" sizez="'+floorHeight+'" src1="'+wall1+'" src2="'+wall2+'" src3="'+wall3+'" src4="'+wall4+'" src6="'+floorMaterial.@definition+'"/>')
				}
				this.result.push('<floor x="'+originx+'" y="'+originy+'" z="'+(originz+j*floorHeight)+'" width="'+width+'" height="'+depth+'" src="'+roofMaterial.@definition+'"/>')

				var myTimer:Timer = new Timer(20, 1)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.loopComplete)
        myTimer.start()			
        
        return this	
			}

		  /** @private */
		  public function loopComplete(e:Event) {
		  	this.dispatchEvent(new Event(Event.COMPLETE))
			}


		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#getPercent
		  */
		  public function getPercent():Number {
		  	return 100
		  }


		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#getXML
		  */
			public function getXML():XMLList {
				
				var ret:XMLList = new XMLList()
				for(var j:Number=0;j<this.result.length;j++) {
					ret+=new XML(this.result[j])
				}
				return ret
			}
			

		}

}