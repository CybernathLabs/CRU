package org.cybernath.cru.service
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import org.cybernath.cru.events.GameStateEvent;
	
	public class GameMaster extends EventDispatcher
	{
		public static const ATTRACT_MODE:String = 'attractMode';
		public static const INIT_GAME:String = 'initializingGame';
		public static const PLAY:String = 'playingGame';
		public static const GAME_OVER_WIN:String = 'gameOverWin';
		public static const GAME_OVER_LOSE:String = 'gameOverLose';
		
		private var _gameState:String;
		
		private var consoles:Array = [];
		
		public function GameMaster(target:IEventDispatcher=null)
		{
			super(target);
			_gameState = ATTRACT_MODE;
			
		}
		
		public function registerConsole(con:CRUConsole):void
		{
			consoles.push(con);	
		}
		
		private function set gameState(val:String):void
		{
			_gameState = val;
			
			var evt:GameStateEvent = new GameStateEvent(GameStateEvent.STATE_CHANGE);
			evt.state = val;
			dispatchEvent(evt);
			
		}
		
		private function get gameState():String
		{
			return _gameState;
		}
		
		
	}
}