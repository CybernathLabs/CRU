package org.cybernath.cru.service
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.CRUControlEvent;
	import org.cybernath.cru.view.CRUDisplay;
	import org.cybernath.cru.vo.ControlVO;
	import org.cybernath.cru.vo.OutputVO;
	import org.cybernath.cru.vo.StateVO;
	import org.cybernath.cru.vo.ThreatVO;
	import org.cybernath.cru.vo.TimerVO;
	
	[Event(name="cruStateChanged", type="org.cybernath.cru.CRUConsoleEvent")]
	[Event(name="ctrlStateChanged", type="org.cybernath.cru.CRUControlEvent")]
	public class CRUDuino extends EventDispatcher
	{
		// CRU Console Represents one of the 2 Arduinos
		private var _configRetry:uint = 0;
		
		// CRU Console Display
		private var _consoleDisplay:CRUDisplay;
		
		// CRU States:
		private var _currentState:String;
		public static const CONSOLE_CONNECTING:String = 'consoleConnecting';
		public static const CONSOLE_IDENTIFIED:String = 'consoleIdentified';
		public static const LOADING_CONFIG:String = 'loadingConfig';
		public static const CONSOLE_READY:String = 'consoleReady';
		public static const CONSOLE_ERROR:String = 'consoleError';
		
		// Controls
		public var controls:Array = [];
		
		// Special Digital Outputs... Based on threat level.
		private var outputs:Array = [];
		
		// Timer Output.
		private var timerOutputs:Array = [];
		
		// Threat Level Output as analog...
		private var threatOutputs:Array = [];
		
		private var ard:Arduino;
		
		private var _threatLevel:int = 0;
		
		private var _consoleId:String;
		
		public function CRUDuino(arduinoConsole:ArduinoSocket)
		{
			currentState = CONSOLE_CONNECTING;
			
			// Initiates connection to Arduino.  Resets it and awaits the console identification.
			ard = new Arduino("127.0.0.1",arduinoConsole.portNumber);
			ard.addEventListener(ArduinoEvent.FIRMWARE_VERSION,onFirmware);
			ard.addEventListener(ArduinoEvent.CONSOLE_ID,onConsoleId);
			ard.addEventListener(ArduinoEvent.DIGITAL_DATA,onDigitalInput);
			ard.resetBoard();
			
			// If we're connecting over bluetooth, then there was a delay connecting, so we'll need to retry.
			if(arduinoConsole.portName.indexOf("Ada") > -1 || Capabilities.os.indexOf("Win") > -1){
				setTimeout(function():void{
					trace("Retrying Arduino Reset...");
					if(ard && ard.connected){
						//ard.resetBoard();
						ard.requestFirmwareVersionAndName();
					}
				},5000);
			}
			
		}
		
		
		public function get threatLevel():int
		{
			return _threatLevel;
		}

		public function set threatLevel(value:int):void
		{
			_threatLevel = value;
			for each(var out:OutputVO in outputs){
				if(_threatLevel >= out.minThreat && _threatLevel <= out.maxThreat){
					ard.writeDigitalPin(out.pin,out.activeValue);
				}else{
					ard.writeDigitalPin(out.pin,out.inactiveValue);
				}
			}
			
			for each(var th:ThreatVO in threatOutputs){
				var val:Number = (( th.endValue - th.startValue) + th.startValue) * (_threatLevel/5); 
				ard.writeAnalogPin(th.pin,val);
			}
		}

		public function get consoleDisplay():CRUDisplay
		{
			return _consoleDisplay;
		}

		public function set consoleDisplay(value:CRUDisplay):void
		{
			_consoleDisplay = value;
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
			var e:CRUConsoleEvent = new CRUConsoleEvent(CRUConsoleEvent.CONSOLE_STATE_CHANGED);
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
			ard.requestFirmwareVersionAndName();
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
			
			for each(var controlNode:XML in xmlData.controls.control){
				var ctrl:ControlVO = new ControlVO();
				
				// Name is required
				ctrl.name = controlNode.@name;
				
				// Directives
				for each(var directiveNode:XML in controlNode.directives.directive)
				{
					ctrl.directives.push(directiveNode.@label);
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
			
			for each(var out:XML in xmlData.special.output){
//				<output name="" minThreat="" maxThreat="" pin="" activeValue="" inactiveValue="" />
				var outVO:OutputVO = new OutputVO();
				outVO.name = out.@name;
				outVO.minThreat = out.@minThreat;
				outVO.maxThreat = out.@maxThreat;
				outVO.pin = out.@pin;
				outVO.activeValue = out.@activeValue;
				outVO.inactiveValue = out.@inactiveValue;
				outputs.push(outVO);
			}
			
			for each(var tim:XML in xmlData.special.timer){
				var timVO:TimerVO = new TimerVO();
				timVO.pin = tim.@pin;
				timVO.startValue = tim.@startValue;
				timVO.endValue = tim.@endValue;
				ard.setPinMode(timVO.pin,Arduino.PWM);
				timerOutputs.push(timVO);
			}
			
			for each(var th:XML in xmlData.special.threat){
				var thVO:ThreatVO = new ThreatVO();
				thVO.pin = th.@pin;
				thVO.startValue = th.@startValue;
				thVO.endValue = th.@endValue;
				ard.setPinMode(thVO.pin,Arduino.PWM);
				threatOutputs.push(thVO);
			}
			
			
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
					if(ard.getDigitalData(s.inputPin) == s.inputValue){
						trace("Setting current State for " + s.parentControl.name + " to " + s.name);
						s.parentControl.currentState = s;
					}
				}
			}
			
			ard.enableDigitalPinReporting();
			controls = ctrlArray;
			
			
			currentState = CONSOLE_READY;
			
			
		}

		public function setTimer(pct:Number):void{
			for each(var t:TimerVO in timerOutputs){
				
				var val:Number = (( t.endValue - t.startValue) * pct) + t.startValue;
				trace("settingTimer in CRUDUINO:",t.pin,val);
				ard.writeAnalogPin(t.pin,val);
			}
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