package org.cybernath.cru.view
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import lib.ScoreDisplayBase;
	
	import org.cybernath.cru.service.GameMaster;
	
	public class ScoreDisplay extends ScoreDisplayBase
	{
		public function ScoreDisplay()
		{
			super();
			var t:Timer = new Timer(500);
			t.addEventListener(TimerEvent.TIMER,onUpdateTick);
			t.start();
		}
		
		private function onUpdateTick(event:TimerEvent):void
		{
			txtScore.text = GameMaster.successes + " / " + (GameMaster.successes + GameMaster.failures);
			
			txtThreatLevel.text = "Threat Level: "  + GameMaster.threatLevel ;
		}
	}
}