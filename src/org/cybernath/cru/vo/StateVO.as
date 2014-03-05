package org.cybernath.cru.vo
{
	public class StateVO
	{
		public var name:String;
		public var inputPin:int;
		public var inputValue:int;
		public var outputPin:int;
		public var outputValue:int;
		public var parentControl:ControlVO;
		public var isHidden:Boolean = false;
		
		public function StateVO()
		{
		}
	}
}