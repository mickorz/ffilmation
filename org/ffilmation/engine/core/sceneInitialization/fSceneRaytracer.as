package org.ffilmation.engine.core.sceneInitialization {
	
		      try {
	      	if(this.xmlObj.@prerender=="true") this.limitHeight = this.scene.gridHeight-1
	      	else if(this.xmlObj.@prerender=="false") this.limitHeight = -1
	      	else this.limitHeight = Math.ceil(parseInt(this.xmlObj.@prerender)/this.scene.levelSize)
	      } catch (e:Error) {
	      	this.limitHeight = 0
	      }
	      // Next step: Setup initial raytracing
	      
	      this.limitHeight++
	      if(this.limitHeight>0) {
			   
			    var myTimer:Timer = new Timer(20, this.limitHeight*this.scene.gridWidth)
          myTimer.addEventListener(TimerEvent.TIMER, this.rayTraceLoop)
          myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.rayTraceComplete)
          myTimer.start()

        } else this.processXml_Part5()


			// RayTrace Loops
			private function rayTraceLoop(event:TimerEvent):void {
			
			   var i_loop:Number = event.target.currentCount-1
   
				 var i:Number = i_loop%this.scene.gridWidth
				 var k:Number = Math.floor(i_loop/this.scene.gridWidth) 
				 for(var j:Number=0;j<this.scene.gridDepth;j++) this.scene.calcVisibles(this.scene.getCellAt(i,j,k))

 	   		 this.scene.stat = "Raytracing..."
	       var current:Number = 100*(i_loop/(this.limitHeight*this.scene.gridWidth))
			   this.scene.dispatchEvent(new fProcessEvent(fScene.LOADPROGRESS,85+current*0.13,fScene.LOADINGDESCRIPTION,current,this.scene.stat))
			   
			}
			
			// RayTrace Ends
			private function rayTraceComplete(event:TimerEvent):void {
			   this.processXml_Part5()
			}
