package org.cybernath.cru.service
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.CRUControlEvent;
	import org.cybernath.cru.view.CRUDisplay;
	import org.cybernath.cru.view.TutorialDisplay;
	import org.cybernath.cru.vo.StateVO;
	import org.cybernath.lib.CRUUtils;
	
	public class CRUConsole extends EventDispatcher
	{
		private var _input:CRUDuino;
		private var _display:CRUDisplay;
		private var _nextState:StateVO;
		
		private var _terrorLevel:int;
		
		private var _moveTimer:Timer;
		
		private var _glitchTimer:Timer;
		
		private var _tut:TutorialDisplay;
		
		
		public function CRUConsole(arduinoConsole:ArduinoSocket)
		{
			super(null);
			
			// CRUDuino is responsible for communicating with the Arduino stuff
			_input = new CRUDuino(arduinoConsole);
			_input.addEventListener("cruStateChanged",onStateChanged);
			_input.addEventListener(CRUControlEvent.STATE_CHANGED,onControlStateChange);
			
			// The moveTimer keeps track of how many seconds the player has to respond.
			_moveTimer = new Timer(100,100);
			_moveTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onMoveTimerComplete);
			_moveTimer.addEventListener(TimerEvent.TIMER,onTimerTick);
			
			_glitchTimer = new Timer(1000,0);
			_glitchTimer.addEventListener(TimerEvent.TIMER,onGlitchTimer);
		}
		
		private function onTimerTick(event:TimerEvent):void
		{
			_input.setTimer(_moveTimer.currentCount/_moveTimer.repeatCount);
		}
		
		private function onGlitchTimer(event:TimerEvent):void
		{
			// CRUDisplay will decide what glitch is appropriate based on current threat level.
			_display.doGlitch();
			_glitchTimer.delay = Math.random()*500 + 500;
		}		

		private function onMoveTimerComplete(event:TimerEvent):void
		{
			trace("Time's Up!!");
			_display.feedback(false,moveOn);
			dispatchEvent(new CRUConsoleEvent(CRUConsoleEvent.FAILURE));
		}
		
		// Poor-man's Event Bubbling.
		private function onControlStateChange(event:CRUControlEvent):void
		{
			dispatchEvent(event.clone());
		}
		
		// If our console is READY, let's put up a display for it!
		private function onStateChanged(event:CRUConsoleEvent):void
		{
			if(event.state == CRUDuino.CONSOLE_READY){
				_display = new CRUDisplay(_input.consoleId);
			}
			
			dispatchEvent(event.clone());
		}
		
		public function displayTutorial():void{
			if(!_display)return;
			if(_tut && _display.contains(_tut))
			{
				_display.removeChild(_tut);
			}
			_tut = new TutorialDisplay();
			_display.addChild(_tut);
			_tut.addEventListener("tutorialComplete",endTutorial);
		}
		public function get isTutoring():Boolean{
			return (_tut && _display.contains(_tut));
		}
		
		public function endTutorial(event:Event = null):void
		{
			if(_tut){
				_tut.removeEventListener("tutorialComplete",endTutorial);
				_display.removeChild(_tut);
			}
			this.dispatchEvent(new Event("tutorialComplete"));
		}
		
		public function verifyInput(testState:StateVO):Boolean
		{
			if(testState == _nextState){
				trace("YAY!")
				_nextState = null;
				dispatchEvent(new CRUConsoleEvent(CRUConsoleEvent.SUCCESS));
				_display.feedback(true,moveOn);
				return true;
			}else if(testState && _nextState && testState.parentControl.name == _nextState.parentControl.name){
				// If we're passing an incorrect value on the correct control, we'll ignore it
				// assuming the user is on their way to the correct value.   
				// For example, going from 1 to 3, 2 isn't wrong...
				return true; 
			}else{
				return false;
			}
		}
		
		public function externalFailure():void{
			_moveTimer.reset();
			_input.setTimer(0);
			_display.feedback(false,moveOn);
			dispatchEvent(new CRUConsoleEvent(CRUConsoleEvent.FAILURE));
		}
		
		// This callback is used when the feedback animation completes.
		private function moveOn():void
		{
			dispatchEvent(new CRUConsoleEvent(CRUConsoleEvent.REQUEST_NEW_MOVE));
		}
		
		// Right now, this simply kicks off the first move
		// In the future, it may also need to clean up some garbage from the "Attract Mode"
		public function beginGame():void
		{
			trace(consoleId + " Requesting Move");
			dispatchEvent(new CRUConsoleEvent(CRUConsoleEvent.REQUEST_NEW_MOVE));
			_glitchTimer.start();
		}
		
		// When the game ends, this wipes out the display.
		// Probably need to find a way to differentiate between an aborted game, and a win/lose scenario.
		public function clearGame(msg:String = ""):void
		{
			_display.message = msg;
			_moveTimer.reset();
			_input.setTimer(0);
			_glitchTimer.reset();
		}
		
		// Who R U?
		public function get consoleId():String{
			return _input.consoleId;
		}
		
		// Reveals all available controls for this console. 
		public function get controls():Array{
			return _input.controls
			
		}
		
		// Exposes the currently displayed Message.  Used primarily for the Console Monitor Window.
		public function get message():String{
			return _display.message;
		}
		
		// Also used for the console monitor window.
		public function get timer():Timer
		{
			return _moveTimer;
		}
		
		// Currently, we'll just use the state from the CRUDuino class.  Not sure whether we'll need to change that in the future.
		public function get currentState():String
		{
			return _input.currentState;
		}
		
		// When the GameMaster says to jump, we say how high...
		// Or at least we get the NextMove into the queue.
		public function nextMove(s:StateVO):void
		{
			_moveTimer.reset();
			_input.setTimer(0);
			// If the user has gotten more than 10 answers correct, let's make it harder.
			_moveTimer.repeatCount = (GameMaster.successes > 10)?80:150;
//			_moveTimer.repeatCount = (GameMaster.successes > 10)?5:5;
			_nextState = s;
			
			
//			Pulls the instructions from the Directive nodes in the XML.  This may need some tweaking to fully support multiple directives.
//			Also considering moving the "directives" node into the states...  This would remove the need for wildcards.
			var msg:String = s.parentControl.directives[Math.floor(s.parentControl.directives.length * Math.random())];
			msg = msg.replace("{name}",s.parentControl.name);
			msg = msg.replace("{state}",s.name);
			_display.message = CRUUtils.obfuscateDirective(msg,terrorLevel);
			
			_moveTimer.start();
		}
		
		
		public function get terrorLevel():int
		{
			return _terrorLevel;
		}

		public function set terrorLevel(value:int):void
		{
			_terrorLevel = value;
			if(_display){
				_display.terrorLevel = _terrorLevel;
			}
			
			if(_input){
				_input.threatLevel = _terrorLevel;
			}
		}
		
		public function get nextState():StateVO
		{
			return _nextState;
		}
	}
}