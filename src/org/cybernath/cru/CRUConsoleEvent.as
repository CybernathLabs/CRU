package org.cybernath.cru
{
	import flash.events.Event;
	
	public class CRUConsoleEvent extends Event
	{
		public var state:String;
		public static const CONSOLE_STATE_CHANGED:String = 'cruStateChanged';
		public static const REQUEST_NEW_MOVE:String = 'cruRequestNewMove';
		public static const FAILURE:String = 'cruFailure';
		public static const SUCCESS:String = 'cruSuccess';
		
		public function CRUConsoleEvent(type:String)
		{
			super(type,true);
		}
		
		public override function clone():Event
		{
			var e:CRUConsoleEvent = new CRUConsoleEvent(type);
			e.state = this.state;
			return e;
		}
	}
}