
package org.ffilmation.utils  {

 import flash.display.MovieClip;
 import flash.text.TextField;
 import flash.utils.getTimer;
 import flash.events.Event;
 
 /** @private */
 public class fps extends MovieClip
 {
  private var startTick : Number;
  private var numFrames : Number;
  private var FPS :TextField;
  
  public function fps()
  {
   numFrames = 0;
   startTick  = getTimer();
   FPS = new TextField();
   FPS.textColor = 0xFF00FF;
   addChild(FPS);
   
   addEventListener(Event.ENTER_FRAME,onEnterFrame);

  }
  
  public function onEnterFrame(event:Event):void
  {
   numFrames++;
   var t : Number = (getTimer() - startTick) * 0.001;
   
   
   if(t > 0.1)
   {
    FPS.text = "FPS: " + (Math.floor((numFrames/t)*10.0)/10.0); 
   }
  }
 }
 
 
}
