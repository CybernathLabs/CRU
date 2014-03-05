package org.cybernath.cru.view
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import lib.GameDisplayBase;
	
	public class ConsoleDisplay extends NativeWindow
	{
		private var _gameBg:GameDisplayBase;
		
		public function ConsoleDisplay()
		{
			var initOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			super(initOptions);
			this.width = 768;
			this.height = 768;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			this.activate();
			setupDisplay();
		}
		
		private function setupDisplay():void
		{
			_gameBg = new GameDisplayBase();
			this.stage.addChild(_gameBg);
		}
	}
}