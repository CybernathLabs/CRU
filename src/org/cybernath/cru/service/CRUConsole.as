package org.cybernath.cru.service
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.CRUControlEvent;
	import org.cybernath.cru.view.ConsoleDisplay;
	import org.cybernath.cru.vo.ControlVO;
	import org.cybernath.cru.vo.StateVO;
	
	[Event(name="cruStateChanged", type="org.cybernath.cru.CRUConsoleEvent")]
	[Event(name="ctrlStateChanged", type="org.cybernath.cru.CRUControlEvent")]
	public class CRUConsole extends EventDispatcher
	{
		// CRU Console Represents one of the 2 Arduinos
		private var _configRetry:uint = 0;
		
		// CRU Console Display
		private var _consoleDisplay:ConsoleDisplay;
		
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
			
			// If we're connecting over bluetooth, then there was a delay connecting, so we'll need to retry.
			if(arduinoConsole.portName.indexOf("Ada") > -1){
				setTimeout(function():void{
					trace("Retrying Arduino Reset...");
					if(ard && ard.connected){
						//ard.resetBoard();
						ard.requestFirmwareVersionAndName();
					}
				},5000);
			}
			
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
			// Still seems to receive invalid console Ids where it shows as length=8, but traces as empty string. :-(\
			// Config Error Catches this issue.
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
			trace("Console Firmware Version Received:",event.value);
			
		}
		
		public function get consoleId():String
		{
			return _consoleId;
		}
		
		private function parse(e:Event):void
		{
			var ctrlArray:Array = [];
			var xmlData:XML= new XML(e.target.data);
			
			for each(var controlNode:XML in xmlData.control){
				var ctrl:ControlVO = new ControlVO();
				
				// Name is required
				ctrl.name = controlNode.@name;
				
				// Directives
				for each(var directiveNode:XML in controlNode.directives.directive)
				{
					ctrl.directives.push(directiveNode.label);
				}
				// Default Directive...
				if(ctrl.directives.length == 0){
					ctrl.directives.push("Set {name} to {state}");
				}
				
				// Loop over States
				for each(var stateNode:XML in controlNode.states.state)
				{
					var st:StateVO = new StateVO();
					st.name = stateNode.@name;
					st.inputPin = stateNode.input.@pin
					st.inputValue =  (stateNode.input.@value == "1")?Arduino.HIGH:Arduino.LOW;
					
					// Output is optional
					if(stateNode.output && stateNode.output.pin && stateNode.output.pin.length)
					{
						st.outputPin = stateNode.output.@pin;
						st.outputValue = (stateNode.output.@value == "1")?Arduino.HIGH:Arduino.LOW;
					}
					
					// This is optional, but hopefully if it's missing, it'll default to false.
					// May need to fix this later.
					st.isHidden = (stateNode.@hidden == "true");
					
					st.parentControl = ctrl;
					
					ctrl.states.push(st);
					
				}
				
				ctrlArray.push(ctrl);
				//trace(controlNode);
			}//for each
			trace(ctrlArray);
			// Setting IO Pins based on the XML loaded.
			var redundancyCheck:Array = [];
			for each(var c:ControlVO in ctrlArray){
				for each(var s:StateVO in c.states){
					if(redundancyCheck.indexOf(s.inputPin) == -1){
						ard.setPinMode(s.inputPin,Arduino.INPUT);
						redundancyCheck.push(s.inputPin);
						trace("Setting Pin " + s.inputPin + " to INPUT");
					}
					if(s.outputPin){
						if(redundancyCheck.indexOf(s.outputPin) == -1){
							ard.setPinMode(s.outputPin,Arduino.OUTPUT);
							ard.writeDigitalPin(s.outputPin,Arduino.LOW);
							trace("Setting Pin " + s.outputPin + " to OUTPUT");
							redundancyCheck.push(s.outputPin);
						}
					}
					
				}
			}
			
			ard.enableDigitalPinReporting();
			controls = ctrlArray;
			
			_consoleDisplay = new ConsoleDisplay();
			
			currentState = CONSOLE_READY;
			
			
		}

		
		private function onDigitalInput(event:ArduinoEvent):void
		{
			//trace("Input " + event.pin + " - " + event.value + " (" + _consoleId + ")");
			for each(var c:ControlVO in controls){
				for each(var s:StateVO in c.states){
					if(s.inputPin == event.pin && s.inputValue == event.value){
						// Store Updated State
						c.currentState = s;
						
						// We'll only notify of change if it's not a "hidden" control state.
						// (For example, momentary switches being released)
						if(!s.isHidden && Math.abs(c.lastUpdated - getTimer()) > 200){
							trace("STATE CHANGE: " + c.name + " = " + s.name);
							var e:CRUControlEvent = new CRUControlEvent(CRUControlEvent.STATE_CHANGED);
							e.newState = s;
							dispatchEvent(e);
						}
						
						if(s.outputPin > 0 && Math.abs(c.lastUpdated - getTimer()) > 200){
							trace("OUTPUT: ",s.outputPin + " - " + s.outputValue);
							ard.writeDigitalPin(s.outputPin,s.outputValue);
						}
						
						// Time stamp this change to filter bouncing
						c.lastUpdated = getTimer();
					}
				}
			}
			
			
		}
	}
}