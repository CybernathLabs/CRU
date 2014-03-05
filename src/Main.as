package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.utils.setTimeout;
	
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	
	import org.cybernath.ArduinoSocket;
	import org.cybernath.SerproxyHelper;
	import org.cybernath.cru.service.CRUConsole;
	import org.cybernath.cru.service.GameMaster;
	
	public class Main extends Sprite
	{
		private var _consoles:Array = [];
		
		private var _gameMaster:GameMaster;
		
		public function Main()
		{
			
			var serp:SerproxyHelper = new SerproxyHelper();
			var sockets:Array = serp.connect();
			
			_gameMaster = new GameMaster();
			
			for each(var aSock:ArduinoSocket in sockets){
				var a:CRUConsole = new CRUConsole(aSock);
				_consoles.push(a);
				_gameMaster.registerConsole(a);
			}
		}
		
		
		
		
		
	}
}