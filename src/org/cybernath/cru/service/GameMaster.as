package org.cybernath.cru.service
{
	import com.greensock.TweenLite;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.CRUControlEvent;
	import org.cybernath.cru.events.GameStateEvent;
	import org.cybernath.cru.services.CRUClient;
	import org.cybernath.cru.services.CRUMessage;
	import org.cybernath.cru.services.CRUServer;
	import org.cybernath.cru.vo.StateVO;
	import org.cybernath.lib.CRUUtils;
	
	public class GameMaster extends EventDispatcher
	{
		public static const ATTRACT_MODE:String = 'attractMode';
		public static const INIT_GAME:String = 'initializingGame'; // Not currently used.
		public static const TUTORING_PLAYERS:String = 'tutoringPlayers';
		public static const PLAY:String = 'playingGame';
		public static const GAME_OVER_WIN:String = 'gameOverWin';
		public static const GAME_OVER_LOSE:String = 'gameOverLose';
		
		private static const WIN_THRESHOLD:int = 20;
		private static const LOSE_THRESHOLD:int = 10;
		
		private var _gameState:String;
		
		private static var _successes:int;
		
		private static var _failures:int;
		
		private static var _threatLevel:int;
		
		private var _comms:CRUServer;
		
		private var consoles:Array = [];
		
		public function GameMaster(target:IEventDispatcher=null)
		{
			super(target);
			gameState = ATTRACT_MODE;
			_comms = CRUServer.getInstance();
		}
		
		public function registerConsole(con:CRUConsole):void
		{
			consoles.push(con);	
			con.addEventListener(CRUConsoleEvent.REQUEST_NEW_MOVE,newMoveRequested);
			con.addEventListener(CRUControlEvent.STATE_CHANGED,processInput);
			con.addEventListener(CRUConsoleEvent.SUCCESS,onSuccess);
			con.addEventListener(CRUConsoleEvent.FAILURE,onFail);
		}
		
		private function onFail(event:CRUConsoleEvent):void
		{
			_failures++;
			var rat:int = (_failures / LOSE_THRESHOLD) * 5 ;
			trace("Failure Ratio:",rat);
			setThreatLevel(rat);
			
			if(_failures > LOSE_THRESHOLD){
				trace("YOU LOSE!");
				gameState = GAME_OVER_LOSE;
				_comms.sendString("You lose.\nBetter Luck Next Time!");
				for each(var con:CRUConsole in consoles){
					con.clearGame("Better Luck Next Time!");
				}
			}
		}
		
		private function onSuccess(event:CRUConsoleEvent):void
		{
			_successes++;
			if(_successes >= WIN_THRESHOLD){
				gameState = GAME_OVER_WIN;
				_comms.sendString("You Win!\nWelcome to the World of the Future!");
				for each(var con:CRUConsole in consoles){
					con.clearGame("You Win!\nWelcome to the World of the Future!");
				}
			}
		}
		
		private function processInput(event:CRUControlEvent):void
		{
			if(gameState != PLAY) return;
			
			var pass:Boolean = false;
			for each(var con:CRUConsole in consoles){
				if(con.verifyInput(event.newState)){
					pass = true;
				}
			}
			
			var c:CRUConsole = CRUConsole(event.currentTarget);
			
			if(c.nextState && !pass)
			{
				c.externalFailure();
			}
		}
		
		private function newMoveRequested(event:CRUConsoleEvent):void
		{
			var con:CRUConsole = CRUConsole(event.currentTarget);
			if(gameState == PLAY){
				// 10% chance of control coming from same machine...
				var nextState:StateVO;
				if(Math.random() < 0.1 || consoles.length == 1){
					nextState = CRUUtils.getAvailableState(con.controls);
				}else{
					// Otherwise, choose one of the other consoles, and get a state from it.
					var otherCon:CRUConsole;
					do 
					{
						otherCon = consoles[Math.floor(Math.random()*consoles.length)];
					} while(otherCon == con);
					nextState = CRUUtils.getAvailableState(otherCon.controls);
				}
				// Send the move to the console requesting it.
				trace("Chosen state: " + nextState.parentControl.name + " -> " + nextState.name);
				con.nextMove(nextState);
			}
		}
		
		// Launches Tutorial...
		public function beginGame():void
		{
			for each(var con:CRUConsole in consoles){
				if(con.currentState != CRUDuino.CONSOLE_READY){
					consoles.splice(consoles.indexOf(con),1);
				}
			}
			
			_comms.sendString("Beginning tutorial with " + consoles.length + " consoles.");
			_successes = 0;
			_failures = 0;
			setThreatLevel(0);
			
			// We're already tutoring.  Clearly someone is impatient.
			if(gameState == TUTORING_PLAYERS){
				for each(var con2:CRUConsole in consoles){
					con2.endTutorial();
				}
				tutorialEnded();
				return;
			}
			
			gameState = TUTORING_PLAYERS;
			for each(var con3:CRUConsole in consoles)
			{
				con3.displayTutorial();
				con3.addEventListener("tutorialComplete",tutorialEnd);
			}
			
		}
		
		private function tutorialEnd(event:Event):void
		{
			var tutCount:int = 0;
			for each(var con:CRUConsole in consoles)
			{
				if(con.isTutoring) tutCount++;
			}
			
			if(tutCount > 0){
				trace("Not finished yet.",tutCount);
			}else{
				tutorialEnded();
			}
		}
		
		// Kicks off the gameplay, wiping out previous values.
		private function tutorialEnded():void{
			
			trace("Beginning game with " + consoles.length + " consoles.");
			
			_comms.sendString("Beginning game with " + consoles.length + " consoles.");
			_successes = 0;
			_failures = 0;
			setThreatLevel(0);
			gameState = PLAY;
			for each(var con:CRUConsole in consoles){
				if(con.currentState == CRUDuino.CONSOLE_READY){
					con.beginGame();
				}else{
					consoles.splice(consoles.indexOf(con),1);
				}
			}
			trace("Beginning game with " + consoles.length + " consoles.");
			
		}
		
		// Kill Switch.
		public function abortGame():void
		{
			if(gameState == TUTORING_PLAYERS){
				for each(var con2:CRUConsole in consoles){
					con2.endTutorial();
				}
				tutorialEnded();
			}
			
			gameState = ATTRACT_MODE;
			setThreatLevel(0);
			for each(var con:CRUConsole in consoles){
				con.clearGame();
			}
		}
		
		// game state is used to keep track of the entire game.
		// I'm kinda a big deal.
		public function set gameState(val:String):void
		{
			_gameState = val;
			
			// Should put a SWITCH/CASE here for the different states, so we can act upon them...
			// Otherwise, this is kinda dull.
			
			var evt:GameStateEvent = new GameStateEvent(GameStateEvent.STATE_CHANGE);
			evt.state = val;
			dispatchEvent(evt);
			
		}
		
		public function get gameState():String
		{
			return _gameState;
		}
		
		public static function get successes():int
		{
			return _successes;
		}
		
		public static function get failures():int
		{
			return _failures;
		}
		
		public static function get threatLevel():int
		{
			return _threatLevel;
		}
		
		public function setThreatLevel(val:int):void
		{
			if(_threatLevel == val)return;
			_threatLevel = val;
			for each(var c:CRUConsole in consoles){
				c.terrorLevel = val;
			}

			// It seems like there's simply too much shit going on here, so MacOS thinks that the application froze.
			// By adding this to a delayed call, we take it out of the linear flow and give the system time to catch up.
			TweenLite.delayedCall(0.5,function():void{
				var msg:CRUMessage = new CRUMessage();
				msg.correctAnswers = _successes;
				msg.wrongAnswers = _failures;
				msg.threatLevel = _threatLevel;
				msg.value = "Threat Level: " + _threatLevel;
				msg.type = CRUMessage.CRU_EVENT;
				_comms.postMessage(msg);
			});
			
		}
	}
}