package org.cybernath.cru
{
	import flash.events.Event;
	
	import org.cybernath.cru.vo.StateVO;
	
	public class CRUControlEvent extends Event
	{
		public static const STATE_CHANGED:String = "ctrlStateChanged";
		
		public var newState:StateVO;
		
		public function CRUControlEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}