package org.cybernath.cru.view
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Quint;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	
	import lib.GameDisplayBase;
	import lib.ThumbsDown;
	import lib.ThumbsUp;
	
	public class CRUDisplay extends NativeWindow
	{
		private var _gameBg:GameDisplayBase;
		private var _consoleId:String;
		
		private var _thumbUp:ThumbsUp;
		private var _thumbDown:ThumbsDown;
		
		private var _resizeHandle:Sprite;
		
		private var _msg:MessageDisplay;
		
		private var _terrorLevel:int;
		
		private var _levelOneOverlay:VideoOverlay = new VideoOverlay("sparksShort.flv");
		private var _levelTwoOverlay:VideoOverlay = new VideoOverlay("sparksShort.flv");
		private var _levelThreeOverlay:VideoOverlay = new VideoOverlay("fireSmall.flv");
		private var _levelFourOverlay:VideoOverlay = new VideoOverlay("sparksFalling.flv");
		private var _levelFiveOverlay:VideoOverlay = new VideoOverlay("fireBigLoop.flv");
		
		private var _videos:Array = [ _levelOneOverlay,_levelTwoOverlay,_levelThreeOverlay,_levelFourOverlay,_levelFiveOverlay];
		
		
		public function CRUDisplay(consoleId:String)
		{
			_consoleId = consoleId;
			
			
			var initOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			initOptions.systemChrome = NativeWindowSystemChrome.NONE;
			super(initOptions);
			//this.width = 768; // Height and width will be overridden by stored values.
			//this.height = 768;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			
			this.activate();

			this.stage.addEventListener(MouseEvent.MOUSE_DOWN,function(evt:MouseEvent):void{
				stage.nativeWindow.startMove();
			});
			
			
			this.title = _consoleId;
			setupDisplay();
			this.addEventListener(NativeWindowBoundsEvent.MOVE,storeWindowLoc);
			this.addEventListener(NativeWindowBoundsEvent.RESIZE,storeWindowLoc);
		}
		
		public function doGlitch():void
		{
			if(terrorLevel > 2){
				// Need to test whether the msg is currently animating, and skip the glitch if it is.
				if(!_msg.isTweening){
					var xOff:Number = (Math.random()*100) - 50;
					var yOff:Number = (Math.random()*100) - 50;
					TweenLite.from(_msg,.35,{x:_msg.x + xOff,y:_msg.y + yOff});
				}
			}
		}
		
		// Stores the window location for this window based on the console ID.
		private function storeWindowLoc(event:NativeWindowBoundsEvent):void
		{
			var lso:SharedObject = SharedObject.getLocal("windowPos");
			lso.data[_consoleId] = this.bounds;
			
			// Tweak the positioning of the thumbs.
			if(_thumbUp){
				_thumbUp.x = stage.stageWidth/2;
				_thumbUp.y = -_thumbUp.height;
			}
			if(_thumbDown){
				_thumbDown.x = stage.stageWidth/2;
				_thumbDown.y = stage.stageHeight;
			}
			
			if(_msg){
				_msg.y = 450;
				_msg.x = (stage.stageWidth - _msg.width) /2;
			}
			
			if(_resizeHandle){
				_resizeHandle.x = stage.stageWidth - 35;
				_resizeHandle.y = stage.stageHeight - 35;
			}
		}
		
		// Initializes the display.
		private function setupDisplay():void
		{
			// If we've previously stored a location for this console window, use that...
			var lso:SharedObject = SharedObject.getLocal("windowPos");
			if(lso.data[_consoleId]){
				this.bounds = new Rectangle(lso.data[_consoleId].x,lso.data[_consoleId].y,lso.data[_consoleId].width,lso.data[_consoleId].height);
			}
			
			// Background image
			_gameBg = new GameDisplayBase();
			this.stage.addChild(_gameBg);
			
			// Used for displaying in-game messages...
			_msg = new MessageDisplay();
			_msg.y = 450;
			_msg.x = (stage.stageWidth - _msg.width) /2;
			trace("Message Height",_msg.height);
			this.stage.addChild(_msg);
			
			// Graphics for use later in the game...
			_thumbUp = new ThumbsUp();
			_thumbUp.x = stage.stageWidth/2;
			_thumbUp.y = -_thumbUp.height;
			_thumbDown= new ThumbsDown();
			_thumbDown.x = stage.stageWidth/2;
			_thumbDown.y = stage.stageHeight;
			this.stage.addChild(_thumbDown);
			this.stage.addChild(_thumbUp);
			
			
			// Resize Handle
			_resizeHandle = new Sprite();
			_resizeHandle.graphics.beginFill(0xff0000);
			_resizeHandle.graphics.drawRect(0,0,25,25);
			_resizeHandle.graphics.endFill();
			this.stage.addChild(_resizeHandle);
			_resizeHandle.buttonMode = true;
			_resizeHandle.addEventListener(MouseEvent.MOUSE_DOWN,function(evt:MouseEvent):void{
				stage.nativeWindow.startResize();
			});
			
			_resizeHandle.x = stage.stageWidth - 35;
			_resizeHandle.y = stage.stageHeight - 35;
		}
		
		// Displays feedback to the user, positive or negative.  :-)
		public function feedback(isPositive:Boolean,callback:Function):void
		{
			if(isPositive){
				_thumbUp.y = stage.stageHeight;
				TweenLite.to(_thumbUp, 1, {y:-_thumbUp.height, ease:Quint.easeIn,onComplete:callback});
			}else{
				_thumbDown.y = -_thumbDown.height;
				TweenLite.to(_thumbDown, 1, {y:stage.stageHeight, ease:Quint.easeIn,onComplete:callback});
			}
		}
		
		public function set message(val:String):void
		{
			_msg.message = val;
		}
		public function get message():String
		{
			return _msg.message;
		}
		
		public function get terrorLevel():int
		{
			return _terrorLevel;
		}
		
		public function set terrorLevel(val:int):void
		{
			_terrorLevel = val;
			switch(val){
				case 1: 
					addVideo(_levelOneOverlay);
					break;
				case 2:
					addVideo(_levelTwoOverlay);
					break;
				case 3:
					addVideo(_levelThreeOverlay);
					break;
				case 4:
					addVideo(_levelFourOverlay);
					break;
				case 5:
					addVideo(_levelFiveOverlay);
					break;
				default :
					for each(var vo:VideoOverlay in _videos){
						if(this.stage.contains(vo)){
							this.stage.removeChild(vo);
						};
					};
					break;
			}
			
		}
	
		private function addVideo(vo:VideoOverlay):void
		{
			if(!this.stage.contains(vo))
			{
				this.stage.addChild(vo);
			}
		}
	}
}