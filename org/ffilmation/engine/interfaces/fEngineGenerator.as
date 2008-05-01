package org.ffilmation.engine.interfaces {

		// Imports
		import flash.events.*
		import flash.net.*
		import org.ffilmation.engine.core.*

		/**
		* This interface defines methods that any class that is to be used as a generator must implement.
		* A generator is a class that given some data from an scene XML, returns extra xml elements that are added to that
		* XML at run time. This allows to use procedural methods to generate complex scenes effortlessly.
		* <br>
		* For example, a generator can create a forest or a maze given some simple parameters, sparing developers the burden of
		* doing it by hand and provinding more flexibility.
		*/
		public interface fEngineGenerator {

			/** 
			* The scene will call this when it encounters a generator Tag in a loaded XML. The CLASSNAME subTag will reference a
			* class that implements this interface. A new instance will be created and it will receive the data from the XML.
			* Then the engine will listen for the onProgress an onCOmplete events of the returned object before retrieving the result of the process.
			* This allows asynchornous generators, because some processes may need to be split into several frames.
			*
			* @param id A unique id for this generator. To make sure we generate unique element names
			*
			* @param scene The scene calling this generator
			*
			* @param data The XML data that was found within the GENERATOR Tag
			*
			* @return An object whose onProgress and onComplete events will be listened to follow generation status
			*/
		  function generate(id:Number,scene:fScene,data:XMLList):EventDispatcher;
		  
		  /**
		  * Return percentage of process already complete, from 0 to 100
		  */
		  function getPercent():Number;

			/** 
			* The scene will use this method to retrieve the XML definition once when a COMPLETE event is triggered
			*/
			function getXML():XMLList;

		}

}