package
{
	import com.xophiix.algorithm.RussionRoulette;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.media.Sound;
	import flash.net.getClassByAlias;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.clearInterval;
	import flash.utils.getDefinitionByName;
	import flash.utils.setInterval;
	
	public class PennyGirl extends Sprite
	{
		public function PennyGirl()
		{
			super();
			
			this.stage.addEventListener(Event.RESIZE, onStageResize );
			
			m_russianRoulette = new RussionRoulette;
			m_russianRoulette.addEventListener( RussionRoulette.EVENT_SHOT, _onShot );
			m_russianRoulette.addEventListener( RussionRoulette.EVENT_SURVIVE, _onSurvive );
			m_russianRoulette.addEventListener( RussionRoulette.EVENT_RESET, _onReset );			
			
			stage.color = 0;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var preface:Bitmap = new Preface as Bitmap;
			preface.y = stage.fullScreenHeight / 2 - preface.height / 2;
			preface.width = stage.fullScreenWidth;

			preface.name = "preface";
			this.addChild( preface );
			m_prefaceDitherID = setInterval( _prefaceDither, 33 );
			
			m_titleTextfield = new TextField;
			m_titleTextfield.name = "title";
			m_titleTextfield.selectable = false;
			m_titleTextfield.background = false;
			m_titleTextfield.x = stage.fullScreenWidth * 0.4;
			m_titleTextfield.y = preface.y + preface.height * 1.1;
			m_titleTextfield.defaultTextFormat = new TextFormat( null, 24, 0xffffffff, true );
			m_titleTextfield.text = "ペニー保健室w";
			m_titleTextfield.width = 300;
			this.addChild( m_titleTextfield );
			
			_initAvatars();
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown );
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _onRightMouseDown );
			
			var bmData:BitmapData = new BitmapData( 32, 32, false, 0xffff0000 );
			m_deadMaskImage = new Bitmap( bmData );
			
			m_rollBtn = new Sprite;
			var btnBitmap:Bitmap = new RollButton;
			btnBitmap.smoothing = true;
			m_rollBtn.addChild( btnBitmap );
			m_rollBtn.scaleX = m_rollBtn.scaleY = 0.4; 
		}
		
		private function _initAvatars():void
		{			
			var avatarClasses:Array = [[Avator01, Avator01Die], [Avator02, Avator02Die], [Avator03, Avator03Die], [Avator04, Avator04Die] ];
			for ( var i:uint = 0; i < avatarClasses.length; ++i )
			{
				var avatar:AvatarInfo = new AvatarInfo;
				avatar.name = "avatar" + (i+1);

				avatar.aliveImage = new avatarClasses[i][0] as Bitmap;
				avatar.deadImage = new avatarClasses[i][1] as Bitmap;
				
				m_availableAvatars.push( avatar );
			}
		}
		
		private function _prefaceDither():void
		{
			var preface:DisplayObject = this.getChildByName( "preface" );
			if ( preface )
			{
				preface.y = stage.fullScreenHeight / 2 - preface.height / 2;
				preface.width = stage.fullScreenWidth;
				
				preface.x = -5 + Math.random() * 5;
				preface.y += -5 + Math.random() * 5;
			}
		}
		
		private function showDeadEffect():void
		{
			m_deadMaskImage.width = stage.fullScreenWidth;
			m_deadMaskImage.height = stage.fullScreenHeight;
			m_deadMaskImage.alpha = 1.0;
			
			if ( !this.contains( m_deadMaskImage ) )
				addChild( m_deadMaskImage );
			
			var id = setInterval( _updateDeadEffect, 33 );
			
			function _updateDeadEffect():void
			{
				m_deadMaskImage.alpha -= 0.07;
				if ( m_deadMaskImage.alpha <= 0 )
				{
					removeChild( m_deadMaskImage );
					clearInterval(id);
				}
			}
		}
		
		private function _layoutAvatar( image:Bitmap ):void
		{
			image.x = stage.fullScreenWidth / 2 - image.width / 2; 
			image.y = stage.fullScreenHeight * 0.2;
			image.width = stage.fullScreenWidth;
			image.height = stage.fullScreenHeight * 0.58;
		}
		
		private function _onShot( event:Event ):void
		{
			this.removeChild( m_availableAvatars[ m_curAvatarIndex ].aliveImage );
			
			var image:Bitmap = m_availableAvatars[ m_curAvatarIndex ].deadImage;
			this.addChild( image );
			_layoutAvatar( image );
			
			m_gameState = GAME_STATE_DEAD;
			showDeadEffect();
			m_shotSound.play();
		}
		
		private function _onSurvive( event:Event ):void
		{			
			m_curScore += m_nextShotScore;
			m_topScore = Math.max( m_topScore, m_curScore );
			m_nextShotScore = (m_russianRoulette.surviveCount + 1) * (m_russianRoulette.surviveCount + 1) * m_scorePerShot;
			
			updateUI();
			m_shotEmptySound.play();
		}
		
		private function _changeAvatar():void
		{
			var avatar:AvatarInfo;
			if ( m_curAvatarIndex < m_availableAvatars.length )
			{
				avatar = m_availableAvatars[ m_curAvatarIndex ];
				
				if ( this.contains( avatar.aliveImage ) )
					this.removeChild( avatar.aliveImage );
				
				if ( this.contains( avatar.deadImage ) )
					this.removeChild( avatar.deadImage );
			}
			
			m_curAvatarIndex = uint( Math.random() * m_availableAvatars.length );
			if ( m_curAvatarIndex < m_availableAvatars.length )
			{
				avatar = m_availableAvatars[ m_curAvatarIndex ];
				if ( !this.contains( avatar.aliveImage ) )
				{
					this.addChild( avatar.aliveImage );
					
					var image:Bitmap = avatar.aliveImage;
					_layoutAvatar( image );
				}			
			}			
		}
		
		private function _onReset( event:Event ):void
		{
			m_gameState = GAME_STATE_ALIVE;
			m_curScore = 0;
			m_nextShotScore = m_scorePerShot;
			updateUI();
		}
		
		private function _onMouseDown( event:MouseEvent ):void
		{
			if ( m_gameState == GAME_STATE_MENU )
			{
				this.removeChild( this.getChildByName( "preface" ) );
				clearInterval( m_prefaceDitherID );
				
				this.removeChild( this.getChildByName( "title" ) );
				
				this.stage.color = 0xffffffff;				
				this.addChild( m_rollBtn );
				m_rollBtn.addEventListener(MouseEvent.MOUSE_DOWN, _onRightMouseDown );
				
				initUI();
				initSounds();
				
				m_russianRoulette.reset();
				_changeAvatar();
			}
			else if ( m_gameState == GAME_STATE_ALIVE )
				m_russianRoulette.tryShoot();
			else
			{
				m_russianRoulette.reset();
				_changeAvatar();
			}
		}
		
		private function _onRightMouseDown( event:MouseEvent ):void
		{
			event.stopImmediatePropagation();
			
			if ( m_gameState == GAME_STATE_ALIVE )
			{
				m_rollSound.play();
				m_russianRoulette.reset();				
			}
			else
				; // exit
		}
		
		public function updateUI():void
		{
			m_curScoreLabel.text = "TOTAL\n$" + m_curScore;
			
			var bigBoldFormat:TextFormat = new TextFormat( m_curScoreLabel.defaultTextFormat.font, 28, m_curScoreLabel.defaultTextFormat.color );
			
			m_curScoreLabel.setTextFormat( bigBoldFormat, 6, m_curScoreLabel.length ); 
			
			var firstLine:String = "NEXT " + (m_russianRoulette.surviveCount + 1).toString() 
				+ " x " + ((m_russianRoulette.surviveCount + 1) * m_scorePerShot).toString();
			
			m_nextShotScoreLabel.text = firstLine + "\n$" + m_nextShotScore;
			m_nextShotScoreLabel.setTextFormat( bigBoldFormat, firstLine.length + 1, m_nextShotScoreLabel.length ); 

			m_helpLabel.text = 
				  "CLICK L:  shot\n" 
				+ "CLICK R:  roll\n"
				+ "CLICK Rx2:stop";
			
			m_topScoreLabel.text = "TOP: \n" + m_topScore;
			m_topScoreLabel.setTextFormat( bigBoldFormat, 6, m_topScoreLabel.length );
		}
		
		private function initUI():void
		{
			m_scorePanel = new Sprite;
			this.addChild( m_scorePanel );
			
			m_curScoreLabel = new TextField;
			m_scorePanel.addChild( m_curScoreLabel );
			
			m_nextShotScoreLabel = new TextField;
			m_scorePanel.addChild( m_nextShotScoreLabel );
			
			m_topScoreLabel = new TextField;
			m_scorePanel.addChild( m_topScoreLabel );
			
			m_helpLabel = new TextField;
			m_scorePanel.addChild( m_helpLabel );
			
			var labels:Array = [ m_curScoreLabel, m_nextShotScoreLabel, m_topScoreLabel, m_helpLabel ];
			for ( var i:uint = 0; i < labels.length; ++i )
			{
				var label:TextField = labels[i];
				label.textColor = 0xff0000;
				label.backgroundColor = 0xffffff;
				label.alpha = 0.9;	
				label.selectable = false;				
			}
			
			onStageResize(null);
		}
		
		private function onStageResize( event:Event ):void
		{
			relayout();
		}
		
		private function relayout():void
		{
			if ( !m_scorePanel )
				return;
			
			m_scorePanel.y = stage.fullScreenHeight * 0.8;
			m_scorePanel.height = stage.fullScreenHeight * 0.2;
			
			var startHorzX:uint;
			var labels:Array = [ m_curScoreLabel, m_nextShotScoreLabel, m_topScoreLabel, m_helpLabel ];
			var widthRatios:Array = [ 0.25, 0.25, 0.2, 0.3 ];
			for ( var i:uint = 0; i < labels.length; ++i )
			{
				var label:TextField = labels[i];
				label.width = stage.fullScreenWidth * widthRatios[i];
				label.height = m_scorePanel.height;
				startHorzX += label.width;
				
				if ( i + 1 < labels.length )
					labels[i+1].x = startHorzX;
			}
		}
		
		public static const GAME_STATE_DEAD:uint = 0;
		public static const GAME_STATE_ALIVE:uint = 1;
		public static const GAME_STATE_MENU:uint = 2;
		
		[Embed(source="../res/girl01.png")]
		static private var Avator01:Class;		
		
		[Embed(source="../res/girl01_die.png")]
		static private var Avator01Die:Class;
		
		[Embed(source="../res/girl02.png")]
		static private var Avator02:Class;		
		
		[Embed(source="../res/girl02_die.png")]
		static private var Avator02Die:Class;
		
		[Embed(source="../res/girl03.png")]
		static private var Avator03:Class;		
		
		[Embed(source="../res/girl03_die.png")]
		static private var Avator03Die:Class;
		
		[Embed(source="../res/x.png")]
		static private var Avator04:Class;		
		
		[Embed(source="../res/x_die.png")]
		static private var Avator04Die:Class;
				
		[Embed(source="../res/preface.jpg")]
		static private var Preface:Class;
		
		[Embed(source="../res/roll.png")]
		static private var RollButton:Class;
		
		[Embed(source="../res/roll.mp3")]
		static private var RollSound:Class;
		
		[Embed(source="../res/pistol2.mp3")]
		static private var ShotSound:Class;
		
		[Embed(source="../res/shot_empty.mp3")]
		static private var ShotEmptySound:Class;
		
		private var m_availableAvatars:Vector.<AvatarInfo> = new Vector.<AvatarInfo>;
		
		private var m_russianRoulette:RussionRoulette;
		
		private var m_curAvatarIndex:uint;
		private var m_gameState:uint = GAME_STATE_MENU;
		
		private var m_curScore:uint;
		private var m_nextShotScore:uint;
		private var m_scorePerShot:uint = 10;
		private var m_topScore:uint;
		
		private var m_scorePanel:Sprite;
		private var m_curScoreLabel:TextField;
		private var m_nextShotScoreLabel:TextField;		
		private var m_topScoreLabel:TextField;
		private var m_helpLabel:TextField;
		
		private var m_prefaceDitherID:uint;
		private var m_deadMaskImage:Bitmap;
		private var m_titleTextfield:TextField;
		
		private var m_shotEmptySound:Sound;
		private var m_shotSound:Sound;
		private var m_rollSound:Sound;
		
		private var m_rollBtn:Sprite;
		
		private function initSounds():void
		{
			m_shotEmptySound = new ShotEmptySound;
			m_shotSound = new ShotSound;
			m_rollSound = new RollSound;
		}
	}
}

import flash.display.Bitmap;

class AvatarInfo
{
	public var name:String = "";
	public var aliveImage:Bitmap;
	public var deadImage:Bitmap;
}