package com.xophiix.algorithm
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class RussionRoulette extends EventDispatcher
	{
		public function RussionRoulette( bulletAllowed:uint = 1 )
		{
			m_bulletAllowed = bulletAllowed;
			reset();
		}
		
		public function get bulletAllowed():uint
		{
			return m_bulletAllowed;
		}

		public function set bulletAllowed(value:uint):void
		{
			m_bulletAllowed = value;
		}

		public function get surviveCount():uint
		{
			return m_suviveCount;
		}
		
		public function reset():void
		{
			for ( var i:uint = 0; i < m_slot.length; ++i )
			{
				m_slot[i] = false;
			}
			
			var bulletCount:uint = 0;
			while ( bulletCount < m_bulletAllowed )
			{
				var randIndex:uint = uint( Math.random() * BULLET_SLOT_COUNT );
				if ( !m_slot[ randIndex ] )
				{				
					m_slot[ randIndex ] = true;
					++bulletCount;
				}	
			}
			
			trace( "bullet layout", m_slot, m_curSlotIndex );
			m_curSlotIndex = uint( Math.random() * BULLET_SLOT_COUNT );
			m_suviveCount = 0;
			
			if ( hasEventListener( EVENT_RESET ) )
				dispatchEvent( new Event( EVENT_RESET ) );
		}
		
		public function tryShoot():void
		{
			if ( m_slot[ m_curSlotIndex ] )
				_shot();
			else
			{
				_survive();
				
				m_curSlotIndex++;
				if ( m_curSlotIndex >= BULLET_SLOT_COUNT )
					m_curSlotIndex = 0;
			}
		}
		
		private function _shot():void
		{
			onShot();
			if ( hasEventListener( EVENT_SHOT ) )
				dispatchEvent( new Event( EVENT_SHOT ) );
		}
		
		private function _survive():void
		{
			++m_suviveCount;
			onSurvive();
			if ( hasEventListener( EVENT_SURVIVE ) )
				dispatchEvent( new Event( EVENT_SURVIVE ) );
		}
		
		protected function onShot():void
		{
			
		}
		
		protected function onSurvive():void
		{
			
		}
		
		protected function onReset():void
		{
			
		}
		
		public static const EVENT_SHOT:String = "RR_shot";
		public static const EVENT_SURVIVE:String = "RR_survive";
		public static const EVENT_RESET:String = "RR_reset";
		
		public static const BULLET_SLOT_COUNT:uint = 6;
		public static const DEFAULT_BULLET_COUNT:uint = 1;
		
		private var m_bulletAllowed:uint = DEFAULT_BULLET_COUNT;
		private var m_slot:Vector.<Boolean> = new Vector.<Boolean>( BULLET_SLOT_COUNT, true );
		private var m_curSlotIndex:uint;
		private var m_suviveCount:uint;
	}
}