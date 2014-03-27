package org.cybernath.cru.view
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Quint;
	
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class VideoOverlay extends Sprite
	{
		private var _vid:Video;
		
		private var _url:String;

		private var _ns:NetStream;
		
		public function VideoOverlay(url:String)
		{
			super();
			
			_url = url;
			
			this.addEventListener(Event.ADDED_TO_STAGE,onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE,onRemoved);
			
			var vid:Video = new Video(1024, 1280);
			//if(activeVid == "smoke.flv"){
				//while(videos.length) NetStream(videos.pop()).close();
				//vid.name = "deleteToReset";
				//mc_stub.addChild(vid);
				//vid.alpha = 0;
				TweenLite.from(this, 2, {alpha:0, y: 1024});
			//}else{
				this.addChild(vid);
			//}
			
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			
			_ns = new NetStream(nc);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			vid.attachNetStream(_ns);
			//if(activeVid != "smoke.flv"){
			//	videos.push(ns);
				vid.blendMode = BlendMode.SCREEN;
			//}
			
			var customClient:Object = new Object();
			_ns.client = customClient;
			customClient.onMetaData = onMetaData;
			
			
			function onNetStatus(e:NetStatusEvent):void{
				if(e.info.code == "NetStream.Play.Stop") {
					//if(activeVid == "fireBigLoop.flv" || activeVid == "fireSmall.flv" || activeVid=="sparksFalling.flv" || activeVid=="smoke.flv"){
						_ns.seek(0);
						_ns.play(0);
					}else{
				//		removeChild(vid);
					}
				}
			
			function onMetaData(infoObject:Object):void
			{
				if(infoObject.duration != null)
				{
					trace("our video is "+infoObject.duration+" seconds long");
				}
				
				if(infoObject.height != null && infoObject.width != null)
				{
					//do stuff with scaling
				}
			}
		}
		
		private function onRemoved(event:Event):void
		{
			_ns.close();
		}
		
		private function onAdded(event:Event):void
		{
			_ns.play(_url);
		}
	}
}