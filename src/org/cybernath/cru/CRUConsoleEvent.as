package org.cybernath.cru
{
	import flash.events.Event;
	
	public class CRUConsoleEvent extends Event
	{
		public var state:String;
		public static const STATE_CHANGED:String = 'cruStateChanged';
		
		public function CRUConsoleEvent(type:String)
		{
			super(type);
		}
	}
}