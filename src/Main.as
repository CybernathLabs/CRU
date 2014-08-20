package
{
	//import com.adobe.viewsource.ViewSource;
	import com.drastudio.Utilities;
	
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.SerproxyHelper;
	import org.cybernath.cru.CRUConsoleEvent;
	import org.cybernath.cru.service.CRUConsole;
	import org.cybernath.cru.service.CRUDuino;
	import org.cybernath.cru.service.GameMaster;
	import org.cybernath.cru.services.CRUServer;
	import org.cybernath.cru.services.CommEvent;
	import org.cybernath.cru.view.MiniCRU;
	import org.cybernath.cru.view.ScoreDisplay;
	import org.cybernath.lib.LayoutBox;
	
	[SWF(height="600",width="800")]
	public class Main extends Sprite
	{
		private var _consoles:Array = [];
		
		private var _gameMaster:GameMaster;
		
		private var _lBox:LayoutBox;
		
		private var _buttonBox:LayoutBox;
		
		private var _comms:CRUServer;
		
		private var _clientText:TextField;
		
		public function Main()
		{
			_comms = CRUServer.getInstance();
			_comms.addEventListener(CommEvent.CRU_COMMS_EVENT,onCommsEvent);
			
			var serp:SerproxyHelper = new SerproxyHelper();
			var sockets:Array = serp.connect();
			
			_gameMaster = new GameMaster();

			
			for each(var aSock:ArduinoSocket in sockets){
				var a:CRUConsole = new CRUConsole(aSock);
				a.addEventListener(CRUConsoleEvent.CONSOLE_STATE_CHANGED,cruStateChanged);
				_consoles.push(a);
				_gameMaster.registerConsole(a);
			}
			
			_lBox = new LayoutBox();
			addChild(_lBox);
			_lBox.x = stage.stageWidth/2;
			_lBox.y = 50;
			
			_buttonBox = new LayoutBox();
			addChild(_buttonBox);
			_buttonBox.x = stage.stageWidth/2;
			_buttonBox.y = stage.stageHeight - 100;
			
			var startBtn:Sprite = Utilities.easyButton("Start Game");
			startBtn.addEventListener(MouseEvent.CLICK,startClick);
			_buttonBox.addChild(startBtn);
			
			var endBtn:Sprite = Utilities.easyButton("End Game");
			endBtn.addEventListener(MouseEvent.CLICK,endClick);
			_buttonBox.addChild(endBtn);
			
			var resetBtn:Sprite = Utilities.easyButton("Reset Window Loc");
			resetBtn.addEventListener(MouseEvent.CLICK,function(evt:MouseEvent):void{
				var lso:SharedObject = SharedObject.getLocal("windowPos");
				lso.clear();
			});
			_buttonBox.addChild(resetBtn);
			
			stage.nativeWindow.addEventListener(Event.CLOSE,function():void{ NativeApplication.nativeApplication.exit(); });
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			var scoreDisp:ScoreDisplay = new ScoreDisplay();
			scoreDisp.x = (stage.stageWidth - scoreDisp.width)/2;
			scoreDisp.y = (_buttonBox.y - scoreDisp.height) - 10;
			addChild(scoreDisp);
			
			_clientText = Utilities.easyText("0 Clients Connected...");
			_clientText.x = 10;
			_clientText.y = stage.stageHeight - _clientText.height - 10;
			addChild(_clientText);
		}
		
		private function onCommsEvent(event:CommEvent):void
		{
			_clientText.text = event.value;
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub
			if(event.keyCode == Keyboard.PAGE_DOWN){
				startClick(null);
			}else if(event.keyCode == Keyboard.B || event.keyCode == Keyboard.PAGE_UP){
				endClick(null);
			}
		}
		
		private function endClick(event:Event):void
		{
			_gameMaster.abortGame();
		}
		
		private function startClick(event:Event):void
		{
			if(_gameMaster.gameState != GameMaster.PLAY){
				_gameMaster.beginGame();
			}
		}
		
		private function cruStateChanged(event:CRUConsoleEvent):void
		{
			
			if(event.state == CRUDuino.CONSOLE_READY){
				trace(CRUConsole(event.currentTarget).consoleId + " is now ready.");
				
				_lBox.addChild(new MiniCRU(CRUConsole(event.currentTarget)));
			}
			
		}		
		
		
		
		
	}
}