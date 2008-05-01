package org.ffilmation.engine.generators {

		// Imports
		import flash.net.*
		import flash.events.*
		import flash.utils.*
		import flash.system.*

		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.interfaces.*
		
		
		/**
		* The scatter generator is used to randomly fill an area with objects. You specify the area to cover and a
    *	list of candidate object definitions. Elements from these definitions are randomly selected and placed
    *	along the surface.
    *
    * @example Here's an example of using this generator in a scene definition XML
    *
	  * <listing version="3.0">
    *  &lt;generator&gt;
    *  	
    *  	&lt;classname&gt;org.ffilmation.engine.generators.fScatterGenerator&lt;/classname&gt;
    *  	
    *  	&lt;data amount="50" minDistance="200" randomizeOrientation="true" noise="Ground_noise_1"&gt;
    *  	
    *  		&lt;!-- Area covered by the objects --&gt;
    *  		&lt;area&gt;
    *  			&lt;origin x="0" y="0" z="0"/&gt;
    *  			&lt;end x="4000" y="4000" z="0"/&gt;
    *  		&lt;/area&gt;
    *  		
    *  		&lt;!-- A Weighed list of candidates, so you can define which types appear more --&gt;
    *  		&lt;candidate definition="FFTrees_misc_tree5" weight="3"/&gt;
    *  		&lt;candidate definition="FFTrees_misc_tree8" weight="1"/&gt;
    *  	
    *  	&lt;/data&gt;
    *  	
    *  &lt;/generator&gt;
	  *
	  * </listing>
	  *
	  * <br><b>amount</b>: Number of elements to be scattered
	  * <br><b>minDistance</b>: Elements won't be closer than this distance
	  * <br><b>randomizeOrientation</b>: If true elements will be given random orientation, else all will be 0
	  * <br><b>noise</b>: If there's a perlin Noise definition that matches this name, only areas covered with that noise will be used to scatter elements
	  *
		*/
		public class fScatterGenerator extends EventDispatcher implements fEngineGenerator {
			
		  // Private data used by this generator
		  private var data:XMLList
		  private var scene:fScene
		  
			private	var amount:int
			private	var minDistance:int
			private	var randomize:Boolean
			private	var noise:fNoise
				
			// Area
			private	var originx:int
			private	var originy:int
			private	var originz:int
			private	var width:int
			private	var depth:int
			private	var height:int
				
			// Candidates
			private	var candidates:Array
			private var current:Number
			private var id:Number
			
			// Result
			private var result:Array
		  
		  /** @private */
		  public function fScatterGenerator() {
		  	
		  }
		  
		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#generate
		  */
		  public function generate(id:Number,scene:fScene,data:XMLList):EventDispatcher {
		  	
				// Init
				this.id = id
				this.scene = scene
				this.data = data
				
				// Generator parameters
				this.amount = parseInt(this.data.@amount)
				this.minDistance = parseInt(this.data.@minDistance)
				this.randomize = this.data.@randomizeOrientation!="false"
				this.noise = this.scene.noiseDefinitions[this.data.@noise]
				this.current = 0
				
				// Area
				this.originx = parseInt(this.data.area.origin.@x)
				this.originy = parseInt(this.data.area.origin.@y)
				this.originz = parseInt(this.data.area.origin.@z)
				this.width = parseInt(this.data.area.end.@x)-originx
				this.depth = parseInt(this.data.area.end.@y)-originy
				this.height = parseInt(this.data.area.end.@z)-originz
				
				// Candidates
				this.candidates = new Array()
				for(var j:Number=0;j<this.data.child("candidate").length();j++) this.candidates.push( { def:this.data.child("candidate")[j].@definition, weight:parseInt(this.data.child("candidate")[j].@weight)} )
				
				// Normalize weights
				var total:Number = 0
				for(j=0;j<this.candidates.length;j++) {
					total+=this.candidates[j].weight
					if(j!=0) this.candidates[j].weight+=this.candidates[j-1].weight
				}
				for(j=0;j<this.candidates.length;j++) this.candidates[j].weight/=total
				
				// Start distribution process (with a very poor algorithm, I must admit)
				this.result = new Array
				
				var myTimer:Timer = new Timer(20, this.amount)
        myTimer.addEventListener(TimerEvent.TIMER, this.loop)
        myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.loopComplete)
        myTimer.start()			
        
        return this	
				
			}	

		  /** @private */
			public function loop(e:Event) {

				var maxTry:Number = 100
				
				var j:Number = this.current = e.target.currentCount-1
						
				var random:Number = Math.random()
				for(var candidate:Number=0;this.candidates[candidate].weight<random;candidate++);
				
				var current:Number = 0
				var invalid:Boolean
				do {
					current++
					invalid = false
					var x:Number = this.originx+this.width*Math.random()
					var y:Number = this.originy+this.depth*Math.random()
					var z:Number = this.originz+this.height*Math.random()
					
					// Test collision with already placed
					for(var k:Number=0;!invalid && k<this.result.length;k++) {
						var other:Object = this.result[k]
						var dist:Number = mathUtils.distance3d(x,y,z,other.x,other.y,other.z)
						if(dist<minDistance) invalid = true
					}
					
					// Test noise
					if(!invalid && this.noise) {
						var value:Number = this.noise.getIntensityAt(x,y)
						if(value<0.6) invalid = true
					}
					
				} while(invalid && current<maxTry)
				
				if(invalid) {
					trace("Warning: Scatter algorythm failed to place an item of type: "+candidates[candidate].def)
				} else {
					this.result.push( {x:x,y:y,z:z,def:this.candidates[candidate].def} )
				}
				
		  	this.dispatchEvent(new Event(ProgressEvent.PROGRESS))
				
		  }
		  
		  /** @private */
		  public function loopComplete(e:Event) {
		  	this.dispatchEvent(new Event(Event.COMPLETE))
			}

		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#getPercent
		  */
		  public function getPercent():Number {
		  	return 100*this.current/this.amount
		  }


		  /**
		  * @see org.ffilmation.engine.interfaces.fEngineGenerator#getXML
		  */
			public function getXML():XMLList {
				
				var ret:XMLList = new XMLList()
				for(var j:Number=0;j<result.length;j++) {
					var orientation:Number = (randomize)?(Math.round(360*Math.random())):0
					ret+=new XML('<object orientation="'+orientation+'" id="Scatter'+this.id+'_Obj'+j+'" definition="'+result[j].def+'" x="'+result[j].x+'" y="'+result[j].y+'" z="'+result[j].z+'"/>')
				}
				return ret
			}
			

		}

}