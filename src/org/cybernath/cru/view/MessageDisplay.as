package org.cybernath.cru.view
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Quint;
	
	import lib.MessageBase;
	
	public class MessageDisplay extends MessageBase
	{
		private var _message:String;
		private var _nextMessage:String;
		private var _isTweening:Boolean = false;
		
		public function MessageDisplay()
		{
			super();
			this.txt_message.text = '';
			this.mc_shadow.txt_message.text = '';
		}
		private function updateMessage():void{
			_message = _nextMessage;
			this.txt_message.text = _message;
			this.mc_shadow.txt_message.text = _message;
			this.y = 450;
			TweenLite.from(this,0.5,{y:stage.stageHeight,ease:Quint.easeOut,onComplete:function():void{ _isTweening = false}});
		}
		public function set message(val:String):void{
			_isTweening = true;
			_nextMessage = val;
			TweenLite.to(this,0.5,{y:-this.height,ease:Quint.easeOut,onComplete:updateMessage});
		}
		
		public function get message():String{
			return _message;
		}
		
		public function get isTweening():Boolean{
			return _isTweening;
		}
	}
}