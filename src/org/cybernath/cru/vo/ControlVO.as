package org.cybernath.cru.vo
{
	public class ControlVO
	{
		public var name:String;
		public var states:Array = [];
		public var directives:Array = [];
		public var currentState:StateVO;
		public var lastUpdated:int;
		
		public function ControlVO()
		{
		}
	}
}