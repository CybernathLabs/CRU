package org.cybernath.cru.view
{
	import com.drastudio.Utilities;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	public class TutorialDisplay extends Sprite
	{
		private var _displayText:TextField;
		private var _timer:Timer = new Timer(1000,10);
		
		public function TutorialDisplay()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE,onAdd);
			this.addEventListener(Event.REMOVED_FROM_STAGE,onRemove);
			_timer.addEventListener(TimerEvent.TIMER,updateText);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE,timerComplete);
			_displayText = Utilities.easyText("10");
			
		}
		
		private function onRemove(event:Event):void
		{
			_timer.stop();
		}
		
		private function timerComplete(event:TimerEvent):void
		{
			dispatchEvent(new Event("tutorialComplete"));
		}
		
		private function updateText(event:TimerEvent):void
		{
			_displayText.text = (_timer.repeatCount - _timer.currentCount) + "";
		}
		
		private function onAdd(event:Event):void
		{
			this.graphics.beginFill(0xff0000);
			this.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			this.graphics.endFill();
			
			this.addChild(_displayText);
			_displayText.x = (stage.stageWidth - _displayText.width)/2;
			_displayText.y = (stage.stageHeight - _displayText.height)/2;
			
			_timer.start();
		}
	}
}