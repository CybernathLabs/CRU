package org.cybernath.cru.view
{
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import lib.MiniConsoleBase;
	
	import org.cybernath.cru.service.CRUConsole;
	
	public class MiniCRU extends MiniConsoleBase
	{
		private var _console:CRUConsole
		private var _t:Timer;
		
		public function MiniCRU(theCon:CRUConsole)
		{
			super();
			_console = theCon;
			this.txtConsoleName.text = theCon.consoleId;
			_t = new Timer(500);
			_t.addEventListener(TimerEvent.TIMER,onUpdateTick);
			_t.start();
		}
		
		private function onUpdateTick(event:TimerEvent):void
		{
			if(_console.message != null){
				this.txtControlDisplay.text = _console.message;
			}
			if(_console.timer.running){
				this.txtTimer.text ="" + (_console.timer.repeatCount - _console.timer.currentCount);
			}else{
				this.txtTimer.text = "";
			}
		}
	}
}