package org.cybernath.lib
{
	import org.cybernath.cru.vo.ControlVO;
	import org.cybernath.cru.vo.StateVO;

	public class CRUUtils
	{
		public function CRUUtils()
		{
		}
		
		public static function getAvailableState(controls:Array):StateVO
		{
			var randomControl:ControlVO = controls[Math.floor(Math.random()*controls.length)];
			var randomState:StateVO;
			var stateSanity:int = 0;
			do 
			{
				if(stateSanity > 10){
					// If it takes more than 10 tries to pick a random available state, then let's choose a different control.
					// Should help to prevent infinite loops in the cases of momentary switches.
					trace("Giving Up on " + randomControl.name);
					randomControl = controls[Math.floor(Math.random()*controls.length)];
					stateSanity = 0;
				}else{
					stateSanity++;
				}
				randomState = randomControl.states[Math.floor(Math.random()*randomControl.states.length)];
				trace("Getting Random State");
				
			} while(randomState == randomControl.currentState || randomState.isHidden);
			
			return randomState;
		}
		
		public static function obfuscateDirective(msg:String,threatLevel:uint = 0):String
		{
			var outMessage:String = msg;
			switch(threatLevel)
			{
				default:
					trace("no replacement");
					outMessage = msg;
					break;
				case 4:
					outMessage = outMessage.replace(/e/ig,'З');
					outMessage = outMessage.replace(/a/ig,'Λ');
					break;
				case 5:
					outMessage = outMessage.replace(/e/ig,'Ш');
					outMessage = outMessage.replace(/a/ig,'Д');
					outMessage = outMessage.replace(/s/ig,'§');
					outMessage = outMessage.replace(/i/ig,'!');
			}
			
			return outMessage;
		}
		
	}
}