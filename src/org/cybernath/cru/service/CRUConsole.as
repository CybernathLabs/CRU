package org.cybernath.cru.service
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.vo.ControlVO;
	import org.cybernath.cru.vo.StateVO;
	
	[Event(name="cruStateChanged", type="org.cybernath.cru.CRUConsoleEvent")]
	public class CRUConsole extends EventDispatcher
	{
		// CRU Console Represents one of the 2 Arduinos
		private var _configRetry:uint = 0;
		
		// CRU States:
		private var _currentState:String;
		public static const CONSOLE_CONNECTING:String = 'consoleConnecting';
		public static const CONSOLE_IDENTIFIED:String = 'consoleIdentified';
		public static const LOADING_CONFIG:String = 'loadingConfig';
		public static const CONSOLE_READY:String = 'consoleReady';
		public static const CONSOLE_ERROR:String = 'consoleError';
		
		// Controls
		public var controls:Array = [];
		
		private var ard:Arduino;
		
		private var _consoleId:String;
		
		public function CRUConsole(arduinoConsole:ArduinoSocket)
		{
			currentState = CONSOLE_CONNECTING;
			
			// Initiates connection to Arduino.  Resets it and awaits the console identification.
			ard = new Arduino("127.0.0.1",arduinoConsole.portNumber);
			ard.addEventListener(ArduinoEvent.FIRMWARE_VERSION,onFirmware);
			ard.addEventListener(ArduinoEvent.CONSOLE_ID,onConsoleId);
			ard.addEventListener(ArduinoEvent.DIGITAL_DATA,onDigitalInput);
			ard.resetBoard();
			
		}
		
		private function onDigitalInput(event:ArduinoEvent):void
		{
			trace("Input " + event.pin + " - " + event.value + " (" + _consoleId + ")");
		}
		
		public function get currentState():String
		{
			return _currentState;
		}

		public function set currentState(value:String):void
		{
			_currentState = value;
			trace("Console State changed (" + _consoleId + "): " + _currentState);
			
			// Notify listeners of state changes.
			var e:CRUConsoleEvent = new CRUConsoleEvent(CRUConsoleEvent.STATE_CHANGED);
			e.state = _currentState;
			dispatchEvent(e);
		}

		private function onConsoleId(event:ArduinoEvent):void
		{
			//Once Console ID has been received, we can load the config file for that console.
			trace("Console ID Received:'" + event.consoleId + "'");
			if(event.consoleId && event.consoleId.length == 8){
				trace("Console ID Accepted:'" + event.consoleId + "'",event.consoleId.length);
				_consoleId = event.consoleId;
				if(currentState == CONSOLE_CONNECTING){
					currentState = LOADING_CONFIG;
					loadConfig(_consoleId);
				}
			}
		}
		
		private function loadConfig(configName:String):void
		{
			if(_configRetry > 2){
				currentState = CONSOLE_ERROR;
				return;
			}
			// Load the controls from the config file provided.
			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest(configName + ".xml"));
			loader.addEventListener(Event.COMPLETE, parse);
			loader.addEventListener(IOErrorEvent.IO_ERROR,onConfigFail);
		}
		
		private function onConfigFail(event:IOErrorEvent):void
		{
			_configRetry++;
			trace("Console Load Failed.  Retry " + _configRetry);
			currentState = CONSOLE_CONNECTING;
			ard.resetBoard();
		}
		
		private function onFirmware(event:ArduinoEvent):void
		{
			// TODO Auto-generated method stub
			trace("Console Firmware Version Received:",event.value);
			
		}
		
		public function get consoleId():String
		{
			return _consoleId;
		}
		
		private function parse(e:Event):void
		{
			//var prevControl:String = "";
			var xmlData:XML= new XML(e.target.data);
			var cvo:ControlVO = new ControlVO();
			cvo.states = [];
			var firstRun:Boolean = true;
			
			for each(var controlNode:XML in xmlData.control){
				if(controlNode.name != cvo.name){
					if(!firstRun) controls.push(cvo);
					cvo = new ControlVO();
					cvo.name = controlNode.name;
					cvo.currentState = null;
					cvo.states = [];
					cvo.mo = (controlNode.mo == "true")?true:false;
					firstRun = false;
				}//if
				var svo:StateVO = new StateVO();
				svo.name = controlNode.state1;
				svo.output = controlNode.light1;
				svo.pin = controlNode.pin;
				svo.value = controlNode.state1value;
				cvo.states.push(svo);
				trace(controlNode.state2, controlNode.state1);
				if(controlNode.state2 !=""){
					svo = new StateVO();
					svo.name = controlNode.state2;
					svo.output = controlNode.light2;
					svo.pin = controlNode.pin;
					svo.value = controlNode.state2value;
					cvo.states.push(svo);
				}//if
			}//for each
			controls.push(cvo);
			
			// Vomit loaded controls out to the console.
			for each(var c:ControlVO in controls){
				trace(c.name);
				for each(var s:StateVO in c.states) trace("state: ", s.name, s.value);
			}
			
			ard.enableDigitalPinReporting();
			currentState = CONSOLE_READY;
		}
	}
}