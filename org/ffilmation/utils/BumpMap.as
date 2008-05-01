package org.ffilmation.utils {

		// Imports
		import flash.display.BitmapData;
		import flash.filters.ConvolutionFilter;
		import flash.geom.Point;

		/**
		* BumpMap class
		* From Ralph Hauwert's at UnitZeroOne (ralph@unitzeroone.com)
		*/
		public class BumpMap {

			private var __inputData : BitmapData;
			private var __outputData: BitmapData;
		
			public static var COMPONENT_X:Number = 1;
			public static var COMPONENT_Y:Number = 2;
			
			// Constructor
			public function BumpMap(inputData:BitmapData)	{
				this.inputData = inputData;
			}
			
			private function updateOutputData():void	{

				//Generates a Normal Map out of a supplied BitmapData, using the convolution filter.
				var tempMap:BitmapData;
				var p:Point = new Point();
				var convolve:ConvolutionFilter = new ConvolutionFilter();
				convolve.matrixX = 3;
				convolve.matrixY = 3;
				convolve.divisor = 1;
				convolve.bias = 127;
				
				if(__outputData != null){
					__outputData.dispose();	
				}
				__outputData = inputData.clone();
				
				//Calculate x normals, copy to outputData.
				convolve.matrix = new Array(0,0,0,-1,0,1,0,0,0);
				tempMap = inputData.clone();
				tempMap.applyFilter(inputData, inputData.rect, p, convolve);
				__outputData.copyPixels(tempMap, tempMap.rect,p);
				
				//Calculate y normals, copy to outputData.
				convolve.matrix = new Array(0,-1,0,0,0,0,0,1,0);
				tempMap = inputData.clone();
				tempMap.applyFilter(inputData, inputData.rect, p, convolve);
				__outputData.copyChannel(tempMap, tempMap.rect, p, 1, COMPONENT_Y);
				
				tempMap.dispose();
			}
			
			public function get outputData():BitmapData 	{
				return __outputData;	
			}
			
			public function set inputData(ainputData:BitmapData):void {
				__inputData = ainputData;
				updateOutputData();
			}
				
			public function get inputData():BitmapData {
				return __inputData;
			}

		}

}
