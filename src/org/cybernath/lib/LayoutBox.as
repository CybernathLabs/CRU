package org.cybernath.lib
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	public class LayoutBox extends Sprite
	{
		private var _contents:Array = [];
		
		private static const PADDING:Number = 15;
		
		public function LayoutBox()
		{
			super();
		}
		
		public override function addChild(child:DisplayObject):DisplayObject
		{
			_contents.push(child);
			super.addChild(child);
			
			updateDisplay();
			return child;
		}
		
		public override function removeChild(child:DisplayObject):DisplayObject
		{
			super.removeChild(child);
			
			updateDisplay();
			
			return child;
		}
		
		private function updateDisplay():void
		{
			var xpos:Number = 0;
			
			for each(var c:DisplayObject in _contents)
			{
				c.x = xpos;
				xpos += c.width + PADDING;
				
			}
			
			var offset:Number = (xpos - PADDING)/2;
			
			for each(var c2:DisplayObject in _contents)
			{
				c2.x -= xpos/2;
			}
		}
		
	}
}