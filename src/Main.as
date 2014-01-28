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
	
	public class Main extends Sprite
	{
		private var _consoles:Array = [];
		
		public function Main()
		{
			
			var serp:SerproxyHelper = new SerproxyHelper();
			var sockets:Array = serp.connect();
			
			for each(var aSock:ArduinoSocket in sockets){
				var a:CRUConsole = new CRUConsole(aSock);
				_consoles.push(a);
			}
		}
		
		
		
		
		
	}
}