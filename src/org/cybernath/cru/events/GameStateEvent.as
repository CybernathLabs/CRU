package org.cybernath.cru.events
{
	import flash.events.Event;
	
	public class GameStateEvent extends Event
	{
		public static const STATE_CHANGE:String = 'stateChange';
		
		public var state:String;
		
		public function GameStateEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}