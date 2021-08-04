#include AmxModX
#include FakeMeta
#include HamSandwich
#include Reapi
#pragma semicolon 1





#define GRAB_EFFECTS	false
#define GRAB_LEN_INFO	false

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))




#define cprintf(%1,%2) client_print(%1,print_center,%2)
#define index_is_player(%1) ( 0 < %1 <= MaxClients )
	
#define g_fGrabChokeReloadTime		1.0
#define g_iGrabMinimalDistance 		90
#define g_iGrabSpeed 				5

#define MsgId_ScreenFade 98

#define SOUND_PLAYER_FROST		"jb_engine/freeze_player.wav"
#define SOUND_PLAYER_DEFROST	"jb_engine/defrost_player.wav"
#define MODEL_FROST				"models/glassgibs.mdl"

const m_flLastAttackTime = 220;

#define m_bloodColor 89
#define m_afButtonPressed 246
const linux_diff_player = 5;
#define ACT_RANGE_ATTACK1  28
#define m_flFrameRate  36
#define m_flGroundSpeed  37
#define m_flLastEventCheck  38
#define m_fSequenceFinished  39
#define m_fSequenceLoops  40
#define m_Activity 73
#define m_IdealActivity 74

new Float:Origin[MAX_PLAYERS + 1][3];
new g_iBitUserGrab;
new bool:bStatus[MAX_PLAYERS + 1];
//new bool:bColorStatus[MAX_PLAYERS + 1];

new Float:pGravity[MAX_PLAYERS + 1],Float:pSpeed[MAX_PLAYERS + 1];

native is_entity_box_breakable(ent);
native get_countbox();
native set_countbox(iNum);
native jbe_is_user_alive(pId);
native jbe_is_user_connected(pId);
native jbe_is_user_chief(pId);
native jbe_is_user_user_boxcreat(pId);
native jbe_get_status_boxcreator() ;
native jbe_iduel_status();
native jbe_is_user_blind(id);

new g_iGlobalDebug;
#include <util_saytext>

enum _: eData_Flags
{
	Flags_Immunity = 0,
	Flags_Grab,
	Flags_FullGrab,
	Flags_Curator
};
	
	// Структура перечисления для массива с настройкой граба
enum _: eData_PlayersClientData
{
	ClientData_Grabbed = 0,
	ClientData_Grabber,
	ClientData_GrabLen,
	ClientData_GrabBox
};

new g_iUserSkin[MAX_PLAYERS + 1];
new const g_iSkinNumber[][] = 
{
	"Белый",
	"Синий",
	"Фиолетовый",
	"Желтый",
	"Серый",
	"Зеленый",
	"Красный"
};
	// Прочее.
new g_iClientData[ 33 ][ eData_PlayersClientData ];
new g_iFlags[ eData_Flags ];

native jbe_set_user_skin(pId, iNum);

	// Константы
new const g_szTeamName[ 4 ][] = { "Наблюдатель", "Арестант", "Охранник", "Арестант" };


//new bColor;


#define GetFunc(%1) native %1

	GetFunc( jbe_get_day_week() );
	GetFunc( jbe_add_user_wanted( pId ) );
	GetFunc( jbe_add_user_free( pId ) );
	GetFunc( jbe_sub_user_wanted( pId ) );
	GetFunc( jbe_sub_user_free( pId ) );
	GetFunc( jbe_get_user_noclip( pId ) );
	GetFunc( jbe_set_user_noclip( pId, bStatus ) );
	GetFunc( jbe_get_day_mode() );
	GetFunc( jbe_set_user_team( pId, iTeam ) );
	GetFunc( jbe_get_user_team( pId ) );
	GetFunc( jbe_is_user_free( pId ) );
	GetFunc( jbe_is_user_wanted( pId ) );
	GetFunc( jbe_is_user_ghost( pId ) );

#undef GetFunc

new g_iModelIndex_Frost;

new g_iFwdSetSkin;

	const TaskId_GrabLine  = 1252;
	//const TaskId_GrabBall  = 1421;
	
	
	new g_pSpriteGrabLine;//, Float: g_vecHookOrigin[ 33 ][ 3 ];


	const TaskId_Grabbed = 1235;
	public plugin_precache()
	{
		g_pSpriteGrabLine = engfunc( EngFunc_PrecacheModel, "sprites/333.spr" ); 
//#if GRAB_EFFECTS
		//g_pSpriteGrabLine = engfunc( EngFunc_PrecacheModel, "sprites/lgtning.spr" ); 
		//g_pSpriteGrabBall = engfunc( EngFunc_PrecacheModel, "sprites/speed.spr" ); 
//#endif
		g_iModelIndex_Frost 	= engfunc( EngFunc_PrecacheModel, MODEL_FROST);
		engfunc( EngFunc_PrecacheSound, SOUND_PLAYER_FROST);
		engfunc( EngFunc_PrecacheSound, SOUND_PLAYER_DEFROST);

	}


public plugin_init( )
{
	register_plugin( "Grab", "v1.3", "Grab" );
	
	register_clcmd( "+grab", "ClCmd_Grab" );
	register_clcmd( "-grab", "unset_grabbed" );	

	//register_clcmd( "+use", "ClCmd_UseGrab" );
	//register_clcmd( "-use", "unset_Usegrabbed" );	



	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	register_clcmd( "lastinv", "ClCmd_Lastinv" );
	register_clcmd( "drop" ,"ClCmd_Throw" );
	//register_clcmd( "say /frozen" ,"set_frozen_status" );
	
	register_forward( FM_CmdStart, "FakeMeta_CmdStart", true );

	RegisterHookChain(RG_CBasePlayer_PreThink, "HC_CBasePlayer_PreThink", false);
	//RegisterHookChain(RG_CBasePlayer_PreThink, "HC_CBasePlayer_PostThink", true);
	
	RegisterHam( Ham_Touch, "weaponbox", "Ham_WeaponBoxTouch", false );
	
	//register_logevent( "LogEvent_RoundEnd", 2, "1=Round_End" );	
	register_event( "DeathMsg", "DeathMsg", "a" );
	
	register_event( "CurWeapon", "WeaponChange", "be", "1=1" );
	//register_logevent( "Event_RoundStart", 2, "1=Round_Start" );
	
	register_menucmd( register_menuid( "Show_GrabMenu" ), ( 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9 ), "Handle_GrabMenu" );
	//register_menucmd( register_menuid( "Show_GrabColorMenu" ), ( 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9 ), "Handle_GrabColorMenu" );
	

	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);

	
	register_cvar( "jbe_grab_access", "p" );

	
	set_task( 2.0, "LoadCvarsDelay" );
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage,"player_damage", .post = false);
	
	g_iFwdSetSkin = CreateMultiForward("jbe_fwd_when_set_skin", ET_CONTINUE, FP_CELL) ;
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(!is_user_alive(iVictim)) return;

	if (bStatus[iVictim]) 
	{
		//set_entvar(iVictim,var_maxspeed,250.0);
		//set_entvar(iVictim,var_gravity,1.0);
		bStatus[iVictim] = false;
	}
}



public plugin_natives() 
{
	register_native("get_frozen_status", "get_frozen_status", 1);
	register_native("set_frozen_status", "set_frozen_status", 1);
	register_native("jbe_is_user_grabber", "jbe_is_user_grabber", 1);
}
public jbe_is_user_grabber(id) return g_iClientData[ id ][ ClientData_Grabber ];
public plugin_end()
{
	DestroyForward(g_iFwdSetSkin);
}

public player_damage(id, iWeapon, iAttacker, Float:fDamage, iType)
{
	if(iType == DMG_FALL && g_iClientData[ id ][ ClientData_Grabber ] && jbe_get_day_mode() != 3)
	{
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public WeaponChange(id) 
{
	if(bStatus[id]) set_entvar(id,var_maxspeed,0.0);
}

forward jbe_fwr_logevent_startround();
public jbe_fwr_logevent_startround()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!jbe_is_user_connected(i))  continue;
		
		if(bStatus[i])
		{
			rg_reset_maxspeed(i);
			set_entvar(i,var_gravity,1.0);
			bStatus[i] = false;
		}
	}
}

public LoadCvarsDelay()
{
	new szFlags[ 2 ];
	get_cvar_string( "jbe_grab_access", szFlags, charsmax( szFlags ) ); g_iFlags[ 1 ] = read_flags( szFlags );
}

public jbe_set_user_godmode(pId, bType) set_entvar( pId, var_takedamage, !bType ? DAMAGE_YES : DAMAGE_NO );
public bool: jbe_get_user_godmode(pId) return bool:( get_entvar(pId, var_takedamage) == DAMAGE_NO );



Show_GrabMenu( pId )
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	if( !iTarget || !pev_valid( iTarget ) ) return PLUGIN_HANDLED;
	
	if( jbe_get_day_mode() == 3 )
	{
		//UTIL_SayText( pId, "Простите, !gGrab!y во время !tИгрового Дня !y - запрещён." );
		return PLUGIN_HANDLED;
	}
	
	set_pdata_int( pId, 205, 0, 5 ); 
	
	
	
	if( index_is_player(iTarget) ) // is player?
	{
		new szMenu[ 512 ], iKeys = ( 1<<9 ), iLen;
	
		#define fmenu(%1) iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, %1 )
		
		iKeys |= ( 1<<0|1<<1|1<<2|1<<7 );
		
		new szName[ 32 ]; get_user_name( iTarget, szName, charsmax( szName ) );
		iLen = format( szMenu, charsmax( szMenu ), "\yВы взяли: \r%s^n\y%s.^n^n", 
			szName, g_szTeamName[ jbe_get_user_team( iTarget ) ] );
			
		
		fmenu( "\y1. \wПеревести за: \y%s^n", g_szTeamName[ GetFixTeam( iTarget ) ] );
		fmenu("\y2. %s \y%dHP.^n", (jbe_is_user_wanted(iTarget) && jbe_get_day_mode() == 3 && get_user_health(iTarget) >= 99) ? "\dВылечить игрока" : "\wВылечить игрока", get_user_health(iTarget));
		
		fmenu( "\y3. \wСтатус: \y%s^n", get_frozen_status( iTarget ) ? "Заморожен" : "Разморожен" );
		


		if( jbe_get_user_team( iTarget ) == 1 )
		{	
			if(jbe_get_user_team(pId) == 2 && jbe_get_day_mode() == 1)
			{
				fmenu( "\y4. \wФД: \y%s^n", jbe_is_user_free( iTarget ) ? "Забрать" : "Выдать" );
				fmenu( "\y5. \wРозыск: \y%s^n", jbe_is_user_wanted( iTarget ) ? "Забрать" : "Выдать" );
				iKeys |= (1<<3|1<<4);
			}
			else
			{
				fmenu( "\y4. \dФД: \y%s^n", jbe_is_user_free( iTarget ) ? "Забрать" : "Выдать" );
				fmenu( "\y5. \dРозыск: \y%s^n", jbe_is_user_wanted( iTarget ) ? "Забрать" : "Выдать" );
			}

			if(jbe_get_day_mode() == 1)
			{
				fmenu( "\y6. \wЦвет скина: \r%s^n", g_iSkinNumber[g_iUserSkin[pId]] );
				fmenu( "\y7. \wВыставить данный скин^n");
				iKeys |= (1<<5|1<<6);
			}
			else
			{
				fmenu("\y6. \dЦвет скина: \r%s \r[FD]^n", g_iSkinNumber[g_iUserSkin[pId]] );
				fmenu("\y7. \dВыставить данный скин \r[FD]^n");
			}
		}
		
		if(jbe_is_user_chief(pId) && jbe_get_user_team( iTarget ) == 1)
		{
			fmenu( "^n\y8. \rУбить зека^n"), iKeys |= (1<<7);
		}else fmenu( "^n\y8. \dУбить зека^n");



		
		formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\y0. \w%L", pId, "JBE_MENU_EXIT" );
		#undef fmenu
		return show_menu( pId, iKeys, szMenu, -1, "Show_GrabMenu" );
	}

	
	
	return PLUGIN_CONTINUE;
	
}

public Handle_GrabMenu( pId, iKey )
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	if( iTarget <= 0 || !pev_valid( iTarget ) || iKey == 9 ) return PLUGIN_HANDLED;
	
	static szName[ 2 ][ 32 ]; get_user_name( pId, szName[ 0 ], charsmax( szName[] ) );
	if( iTarget <= MaxClients )
		get_user_name( iTarget, szName[ 1 ], charsmax( szName[] ) );
	if( iTarget <= MaxClients ) // is player?
	{
		switch( iKey )
		{
			case 0: 
			{
				unset_grabbed( pId );
				switch( jbe_get_user_team( iTarget ) )
				{
					case 1:
					{
						jbe_set_user_team( iTarget, 2 );
						UTIL_SayText(0, "!g* !yАдминистратор !g%n!y перевёл !g%n!y за !gОхранников", pId, iTarget);
					}
					default: 
					{
						jbe_set_user_team( iTarget, 1 );
						UTIL_SayText(0, "!g* !yАдминистратор !g%n!y перевёл !g%n!y за !gЗаключенных", pId, iTarget);
					}
				}
			}
			
			case 1: 
			{
				if(jbe_iduel_status() || jbe_is_user_wanted(iTarget))
				{
					unset_grabbed( pId );
					UTIL_SayText(pId, "!g* !yИгрок или в розыске или в статусе дуэли");
					return PLUGIN_HANDLED;
				}
				if(jbe_get_day_mode() != 3 && get_user_health(iTarget) < 100)
				{
					set_entvar(iTarget, var_health, 100.0);
					UTIL_SayText(0, "!g* !yАдминистратор %n!y вылечил игрока !t%n!y.", pId, iTarget);
				} 
			}
			
			case 2: 
			{
				set_frozen_status( iTarget );
				
				switch(bStatus[iTarget])
				{
					case true: UTIL_SayText(0, "!g* !yАдминистратор %n!y заморозил игрока !t%n!y.", pId, iTarget);
					case false: UTIL_SayText(0, "!g* !yАдминистратор %n!y разморозил игрока !t%n!y.", pId, iTarget);
				}
			}
			case 3: 
			{
				if(jbe_is_user_free(iTarget))
				{
					UTIL_SayText(0, "!g* !yАдминистратор %n!y забрал свободный день игрока !t%n!y.", pId, iTarget);
					jbe_sub_user_free(iTarget);
				}
				else 
				{
					if(!jbe_is_user_wanted(iTarget))
					{
						UTIL_SayText(0, "!g* !yАдминистратор %n!y выдал свободный день игрока !t%n!y.", pId, iTarget);
						jbe_add_user_free(iTarget);
					}
				}
			}
			case 4: 
			{
				if(jbe_is_user_wanted(iTarget))
				{
					UTIL_SayText(0, "!g* !yАдминистратор %n!y забрал розыск игрока !t%n!y.", pId, iTarget);
					jbe_sub_user_wanted(iTarget);
				}
				else 
				{
					UTIL_SayText(0, "!g* !yАдминистратор %n!y выдал розыск игрока !t%n!y.", pId, iTarget);
					jbe_add_user_wanted(iTarget);
				}
			}
			case 5:
			{
				if(jbe_get_user_team(iTarget) == 1)
				{
					g_iUserSkin[pId]++;
					if(g_iUserSkin[pId] == 7) g_iUserSkin[pId] = 0;
				}
			}
			case 6:
			{
				if (jbe_get_user_team(iTarget) == 1)
				{
					if(jbe_is_user_free(iTarget))
					{
						UTIL_SayText(pId, "!g* !yДанный игрок имеет свободный день");
						return Show_GrabMenu( pId );
					}
					if(jbe_is_user_wanted(iTarget))
					{
						UTIL_SayText(pId, "!g* !yДанный игрок в розыск!");
						return Show_GrabMenu( pId );
					}
					set_entvar(iTarget, var_skin, g_iUserSkin[pId]);
					jbe_set_user_skin(iTarget, g_iUserSkin[pId]);
					UTIL_SayText(0,"!g* !yАдминистратор !g%n !yвыставил !g%s !yцвет игроку !g%n",pId,  g_iSkinNumber[g_iUserSkin[pId]], iTarget);
					
					new iRet;
					ExecuteForward(g_iFwdSetSkin, iRet, iTarget);
				}
			}
			
			case 7:
			{
				ExecuteHamB(Ham_Killed, iTarget, iTarget, 2);
				UTIL_SayText(0, "!g* !yАдминистратор !g%n убил зека !g%n",pId , iTarget);
				unset_grabbed( pId );
			}
			
			//case 8: return Show_GrabColorMenu( pId );
			case 9: return PLUGIN_HANDLED;
		}
	}
	
	
	return Show_GrabMenu( pId );
}

public Ham_WeaponBoxTouch( iWeapon, pPlayer )
{
	new iOwner = get_entvar( iWeapon, var_owner );
	if( g_iClientData[ iOwner ][ ClientData_Grabbed ] == iWeapon )
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

forward jbe_fwr_roundend();
public jbe_fwr_roundend() 
{
	for( new pId = 1; pId <= MaxClients; pId++ )
	{
		if(!jbe_is_user_connected(pId) || !g_iClientData[ pId ][ ClientData_Grabbed ] ) continue;
			
		unset_grabbed( pId ); 
	}
}

public FakeMeta_CmdStart( pId , uc_handle)
{
	if(jbe_get_status_boxcreator()) 
	{
		//if(index_is_player(pId))
		//{
			if(jbe_is_user_user_boxcreat(pId) && jbe_is_user_alive(pId))
			{
				new buttons = get_uc(uc_handle, UC_Buttons),
				oldbutton = get_entvar(pId,var_oldbuttons);

				if((buttons & IN_USE) && !(oldbutton & IN_USE)) 
				{
					//server_print("IN USE");
					if ( !g_iClientData[ pId ][ ClientData_Grabbed ] ) g_iClientData[ pId ][ ClientData_Grabbed ] = -1;
				}
				if (!(buttons & IN_USE) && (oldbutton & IN_USE)) 
				{
					//server_print("OFF USE");
					if( g_iClientData[ pId ][ ClientData_Grabbed ] ) 
					unset_grabbed( pId ); 
				}
				//server_print("Worked");

			}
		//}
	}
	//if( get_uc ( iUS_Handle, UC_Impulse ) == 100 && g_iClientData[ pId ][ ClientData_Grabbed ] ) {
		//Show_GrabMenu( pId ); return FMRES_HANDLED; }
	
	return FMRES_IGNORED;
}

		
public HC_CBasePlayer_PreThink( pId )
{
	static iTarget;

	
	//set_entvar(pId,var_velocity,Float:{0.0,0.0,0.0});
	new Float:vecVelocity[3];
	if (bStatus[pId])
	{
		new buttons = get_entvar(pId,var_button), 
		oldbutton = get_entvar(pId,var_oldbuttons);
		set_entvar(pId,var_velocity,Float:{0.0,0.0,0.0});
		new flags = get_entvar(pId,var_flags);

		if(((buttons & IN_JUMP) && !(oldbutton & IN_JUMP) && (flags & FL_ONGROUND)) || 
			(buttons & IN_FORWARD)  || 
			(buttons & IN_MOVERIGHT) || 
			(buttons & IN_BACK)||
			(buttons & IN_MOVELEFT))
			set_entvar(pId,var_origin, Origin[pId]);
	}
	
	if( g_iClientData[ pId ][ ClientData_Grabbed ] == -1)
	{
		
		get_entvar(pId, var_velocity, vecVelocity);
		
		
		new Float: vecOrigin[ 3 ]; get_view_pos( pId, vecOrigin );
		new Float: fRet[ 3 ]; fRet = vel_by_aim( pId, 9999 );
		
		fRet[ 0 ] += vecOrigin[ 0 ];
		fRet[ 1 ] += vecOrigin[ 1 ];
		fRet[ 2 ] += vecOrigin[ 2 ];
		
		iTarget = traceline( vecOrigin, fRet, pId, fRet );
		if( index_is_player( iTarget ) )
		{
			if(jbe_is_user_user_boxcreat(pId)) return HC_CONTINUE;
			
			if( is_grabbed( iTarget, pId ) )
			{
				UTIL_SayText(pId, "g* !yДанного игрока уже взяли грабом!");
				return HC_CONTINUE;
			}
			
			
			if(jbe_is_user_ghost(iTarget)) 
				return HC_CONTINUE;
			
//#if GRAB_EFFECTS
		//	grab_eff(iTarget);
//#endif

			set_grabbed( pId, iTarget );
			
			
		}
		else
		{
			new iMoveType;
			if( pev_valid( iTarget ) && iTarget )
			{
				if(!is_entity_box_breakable( iTarget ))
				{
					iMoveType = get_entvar( iTarget, var_movetype );
					if( !( iMoveType == MOVETYPE_WALK || iMoveType == MOVETYPE_STEP || iMoveType == MOVETYPE_TOSS ) )
						return HC_CONTINUE;
				}
			}
			else
			{			
				new iEntity; 
				iTarget = 0; 
				iEntity = engfunc( EngFunc_FindEntityInSphere, -1, fRet, 12.0 );

				while( !iTarget && iEntity > 0 )
				{
					iMoveType = get_entvar( iEntity, var_movetype );
					if( ( iMoveType == MOVETYPE_WALK || iMoveType == MOVETYPE_STEP || iMoveType == MOVETYPE_TOSS ) && iEntity != pId ) 
						iTarget = iEntity;
					
					iEntity = engfunc( EngFunc_FindEntityInSphere, iEntity, fRet, 12.0 );
				}
			}
			
			if( iTarget )
			{
				if( is_grabbed( iTarget, pId ) ) return HC_CONTINUE;
				set_grabbed( pId, iTarget );
			}

		}
	}
	
	iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	if( iTarget > 0 )
	{
		if( !pev_valid( iTarget ) || ( get_entvar( iTarget, var_health ) < 1 && get_entvar( iTarget, var_max_health ) ) )
		{
			unset_grabbed( pId );
			return HC_CONTINUE;
		}
		/*if(jbe_is_user_user_boxcreat(pId)) 
		{
			unset_grabbed( pId );
			return HC_CONTINUE;
		}*/
		 
		new iBitButtons = get_entvar( pId, var_button ), iBitOldButtons =  get_entvar( pId, var_oldbuttons );
		
		if(jbe_get_day_mode() != 3)
		{
			if( !jbe_is_user_user_boxcreat(pId) && iBitButtons & IN_USE && ~iBitOldButtons & IN_USE && g_iClientData[ pId ][ ClientData_GrabLen ] < 999 )
				g_iClientData[ pId ][ ClientData_GrabLen ] += 50;
				
			static Float: fReloadTime;
			if(!jbe_is_user_user_boxcreat(pId) && iBitButtons & IN_RELOAD && ~iBitOldButtons & IN_RELOAD && ( get_gametime() - fReloadTime ) > 3.0 && iTarget > 0)
			{	
				if( iTarget <= MaxClients )
				{
					fReloadTime = get_gametime(); 
					//fm_strip_user_weapons( iTarget ); 
					//fm_give_item( iTarget, "weapon_knife" ); 
					rg_remove_all_items(iTarget);
					rg_give_item(iTarget, "weapon_knife");
					UTIL_SayText(0, "!g* !yАдминистратор !g%n !yобезаружил игрока !g%n", pId, iTarget);
				}
				else 
				{
					if( get_entvar( iTarget, var_owner ) ) 
					{

						if(is_entity_box_breakable( iTarget )) 
						{
							if(pev_valid(iTarget))
							{
								UTIL_SayText(0, "!g* !yИгрок !g%n !yудалил с карты объект: !gЯщик", pId);
								set_countbox(get_countbox() - 1);
								engfunc( EngFunc_RemoveEntity, iTarget );
							}
							
						}
						else
						{
								
							UTIL_SayText(0, "!g* !yИгрок !g%n !yудалил с карты объект: !g%s", pId, GetWeaponNameByEntityId( iTarget ) );
							fReloadTime = get_gametime() + 2.0;
							engfunc( EngFunc_RemoveEntity, iTarget );
						}

						unset_grabbed( pId );
						return HC_CONTINUE;
					}
				}
			}
		}
	
		//if(!jbe_is_user_user_boxcreat(pId) && iBitButtons & IN_ATTACK2 && iTarget <= MaxClients )
		//{
		//	do_choke( pId );
		//}

		if( iTarget > MaxClients )
		{
			if( get_entvar( iTarget, var_owner ) ) 
				grab_think( pId ); 		
			/*else
			{
				if( get_user_flags( pId ) & g_iFlags[ Flags_Curator ] ) grab_think( pId );
				else
				{
					cprintf( pId, "Брать коренное оружие с карты - запрещено!" );
					unset_grabbed( pId ); return HC_CONTINUE;
				}
			}*/
		}
	}
	
	iTarget = g_iClientData[ pId ][ ClientData_Grabber ];
	if( iTarget > 0 ) grab_think( iTarget );
	
	return HC_CONTINUE;
}

public grab_think( pId ) //id of the grabber
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	
	if( get_entvar( iTarget, var_movetype ) == MOVETYPE_FLY && !(get_entvar( iTarget, var_button ) & IN_JUMP ) ) 
		ExecuteHam( Ham_Player_Jump, pId );
	
	new Float:tmpvec[3], Float:tmpvec2[3], Float:torig[3], Float:tvel[3];
	
	get_view_pos( pId, tmpvec );
	
	tmpvec2 = vel_by_aim( pId, g_iClientData[ pId ][ ClientData_GrabLen ] );
	
	torig = get_target_origin_f( iTarget );
	
	#define iForse 15

	tvel[0] = ( ( tmpvec[0] + tmpvec2[0] ) - torig[0] ) * iForse;
	tvel[1] = ( ( tmpvec[1] + tmpvec2[1] ) - torig[1] ) * iForse;
	tvel[2] = ( ( tmpvec[2] + tmpvec2[2] ) - torig[2] ) * iForse;
	
	#undef iForse
	
	set_entvar( iTarget, var_velocity, tvel );
}

public grab_Boxthink( pId ) //id of the grabber
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	

	
	new Float:tmpvec[3], Float:tmpvec2[3], Float:torig[3], Float:tvel[3];
	
	get_view_pos( pId, tmpvec );
	
	tmpvec2 = vel_by_aim( pId, g_iClientData[ pId ][ ClientData_GrabLen ] );
	
	torig = get_target_origin_f( iTarget );
	
	#define iForse 15

	tvel[0] = ( ( tmpvec[0] + tmpvec2[0] ) - torig[0] ) * iForse;
	tvel[1] = ( ( tmpvec[1] + tmpvec2[1] ) - torig[1] ) * iForse;
	tvel[2] = ( ( tmpvec[2] + tmpvec2[2] ) - torig[2] ) * iForse;
	
	#undef iForse
	
	set_entvar( iTarget, var_velocity, tvel );
}

public client_putinserver(pId)
{
	new iFlags = get_user_flags( pId );
	if( iFlags & g_iFlags[ Flags_Grab ] ) 
	{
		SetBit(g_iBitUserGrab, pId);
	}
}

public frallion_access_user(pId, szFlags[])
{
	new iFlags = read_flags(szFlags);
	
	if( iFlags & g_iFlags[ Flags_Grab ] ) 
	{
		SetBit(g_iBitUserGrab, pId);
	}
}

forward OnAPIAdminConnected(id, const szName[], adminID, Flags);

public OnAPIAdminConnected(pId, const szName[], adminID, iFlags)
{

	ClearBit(g_iBitUserGrab, pId);
	//new iFlags = get_user_flags( pId );
	if( iFlags & g_iFlags[ Flags_Grab ] ) 
	{
		SetBit(g_iBitUserGrab, pId);
	}
}



public ClCmd_Grab( pId )
{
	/*if( jbe_get_day_mode() == 3 || jbe_get_day_week() > 5 )
	{
		UTIL_SayText( pId, "Простите, !gGrab!y во время !tИгрового Дня !y - запрещён." );
		return PLUGIN_HANDLED;
	}*/
	if( IsNotSetBit(g_iBitUserGrab, pId) ) return PLUGIN_HANDLED;
	if ( !g_iClientData[ pId ][ ClientData_Grabbed ] ) g_iClientData[ pId ][ ClientData_Grabbed ] = -1;
	return PLUGIN_HANDLED;
}

public ClCmd_UseGrab( pId )
{
	if(jbe_get_status_boxcreator())
	{
		if( jbe_get_day_mode() == 3 || jbe_get_day_week() > 5 )
		{
			return PLUGIN_CONTINUE;
		}
		if(!jbe_is_user_user_boxcreat(pId)) return PLUGIN_CONTINUE;
		if (!g_iClientData[ pId ][ ClientData_GrabBox ] ) g_iClientData[ pId ][ ClientData_GrabBox ] = -1;
	}
	return PLUGIN_CONTINUE;
}

public unset_Usegrabbed( pId )
{
	if (g_iClientData[ pId ][ ClientData_GrabBox ] == -1) g_iClientData[ pId ][ ClientData_GrabBox ] = 0;
	return PLUGIN_HANDLED;
}

public ClCmd_Throw( pId )
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	if( iTarget > 0 && !jbe_is_user_user_boxcreat(pId))
	{ 
		set_entvar( iTarget, var_velocity, vel_by_aim( pId, 1500 ) );
		unset_grabbed( pId );
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public unset_grabbed( pId )
{
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	if( pev_valid( iTarget ) )
	{
		
		/*if( !jbe_is_user_free( iTarget ) && !jbe_is_user_wanted( iTarget ) && get_entvar( iTarget, var_renderamt ) == 17)
		{
			set_entvar( iTarget, var_renderfx, kRenderFxNone );
			set_entvar( iTarget, var_rendercolor, { 255.0, 255.0, 255.0 } );
			set_entvar( iTarget, var_rendermode, kRenderNormal );
			set_entvar( iTarget, var_renderamt, 0.0 );
		}*/
		

		
		if( index_is_player( iTarget ) )
		{
			g_iClientData[ iTarget ][ ClientData_Grabber ] = 0;
			if(bStatus[iTarget])
			{
				set_entvar(iTarget,var_velocity,Float:{0.0,0.0,0.0});
				get_entvar(iTarget, var_origin, Origin[iTarget]);
				
			}
			if( jbe_get_day_mode() != 3 )
			{
				show_menu( pId, 0, "^n", 1 );
			}
			
		}
		CREATE_KILLBEAM(iTarget);
		//set_user_godmode(iTarget, 0);
	}
	g_iClientData[ pId ][ ClientData_Grabbed ] = 0;

	//if(!is_entity_box_breakable( iTarget )) 

	
	//#if GRAB_EFFECTS
	//if( task_exists( pId + TaskId_GrabLine ) ) remove_task( pId + TaskId_GrabLine );
		//if( task_exists( pId + TaskId_GrabBall ) ) remove_task( pId + TaskId_GrabBall );
	//#endif
	
	if(task_exists(pId + TaskId_Grabbed)) remove_task(pId + TaskId_Grabbed);
	
	#if GRAB_LEN_INFO
		cprintf( pId, " " );
	#endif
	
	return PLUGIN_HANDLED;
}

stock CREATE_KILLBEAM(pEntity)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[Grab] CREATE_KILLBEAM");
	}
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(pEntity);
	message_end();
}

//new g_iColor[3];

public set_grabbed( pId, iTarget )
{	
	if(jbe_is_user_user_boxcreat(pId))
	{
		if(index_is_player(iTarget))
		{
			unset_grabbed( pId );
			return 0;
		}
	}

	if( index_is_player( iTarget ) )
	{
		UTIL_SayText(pId, "!g* !yВы взяли грабом: %n", iTarget );
		UTIL_SayText(iTarget, "!g* !yВас взял грабом: %n", pId );
		
		
		client_cmd( iTarget, "stopsound;spk ambience/doorbell.wav" );
		g_iClientData[ iTarget ][ ClientData_Grabber ] = pId;
		
		
		/*new iRandom = random_num(1, 2);
		switch(iRandom)
		{
			case 1: UTIL_PlayerAnimation(iTarget, "treadwater");
			case 2: UTIL_PlayerAnimation(iTarget, "animation_5");
		}*/
		//UTIL_PlayerAnimation(iTarget, "treadwater");
		
	//	fnGrabLine( pId + TaskId_GrabLine ); 
		//set_task( 0.5, "fnGrabLine", pId + TaskId_GrabLine, _,_, "b" );
		
		
		get_entvar(pId, var_origin, Origin[pId]);
		get_entvar(iTarget, var_origin, Origin[iTarget]);
		//if(bStatus[iTarget]) set_task( 0.1, "GrabOrigin", iTarget + TaskId_Grabbed, _,_, "b" );
	}
	if(is_entity_box_breakable( iTarget ) && !jbe_is_user_user_boxcreat(pId)) UTIL_SayText(0, "!g* !y%s !g%n !yВзял грабом !gЯщик", jbe_is_user_user_boxcreat(pId) ? "Игрок" : "Администратор", pId );
				
	
	//set_user_godmode(iTarget, 1);
	g_iClientData[ pId ][ ClientData_Grabbed ] = iTarget;
	//client_cmd( pId, "stopsound;spk ambience/lv_fruit1.wav" );
	if(!is_entity_box_breakable( iTarget )) Show_GrabMenu(pId);
	#define PLAYER 0
	#define TARGET 1
	
	new Float: vecOrigin[ 2 ][ 3 ]; get_entvar( iTarget, var_origin, vecOrigin[ TARGET ] ); get_entvar( pId, var_origin, vecOrigin[ PLAYER ] );
	
	g_iClientData[ pId ][ ClientData_GrabLen ] = floatround( get_distance_f( vecOrigin[ TARGET ], vecOrigin[ PLAYER ] ) );
	if( g_iClientData[ pId ][ ClientData_GrabLen ] < g_iGrabMinimalDistance ) g_iClientData[ pId ][ ClientData_GrabLen ] = g_iGrabMinimalDistance;
	
	
	
	
//#if GRAB_EFFECTS	
	/*if(is_entity_box_breakable( iTarget ) && jbe_is_user_user_boxcreat(pId))
	{
		new iOrigin[ 3 ]; get_user_origin( pId, iOrigin, 3 );
		g_vecHookOrigin[ pId ][ 0 ] = float( iOrigin[ 0 ] );
		g_vecHookOrigin[ pId ][ 1 ] = float( iOrigin[ 1 ] );
		g_vecHookOrigin[ pId ][ 2 ] = float( iOrigin[ 2 ] );

		g_iColor[0] = random_num(1, 255);
		g_iColor[1] = random_num(1, 255);
		g_iColor[2] = random_num(1, 255);
		
		fnGrabLine( pId + TaskId_GrabLine ); 
		set_task( 0.5, "fnGrabLine", pId + TaskId_GrabLine, _,_, "b" );
	}*/
	//set_task( 0.4, "fnGrabBall", pId + TaskId_GrabBall, _,_, "b" );
//#else
	#if GRAB_LEN_INFO
		cprintf( pId, "Расстояние между Вами: %d метров%s", g_iClientData[ pId ][ ClientData_GrabLen ] / 22, !get_entvar( iTarget, var_owner ) ? " | Коренное оружие" : "." );
	#endif

	
	#undef PLAYER
	#undef TARGET
	return 1;
}

public GrabOrigin(pId) 
{
	pId -= TaskId_Grabbed;
	get_entvar(pId, var_origin, Origin[pId]);
}

public fnGrabLine( pId )
{
	pId -= TaskId_GrabLine;

	if(!jbe_is_user_alive(pId) ) return;
	
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];
	
	if(jbe_is_user_alive(iTarget))
	{
		/*message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_BEAMENTPOINT );
		write_short( pId );
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 0 ] );
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 1 ] );
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 2 ] );

		write_short( g_pSpriteGrabLine );
		write_byte(0);               //Стартовый кадр
		write_byte(1);                 //Скорость анимации
		write_byte(1);                //Врмея существования
		write_byte( 0 );
		write_byte( 0 ); // 0.01's
		write_byte( 255);
		write_byte( 0);
		write_byte( 0);
		write_byte( 2000 );
		write_byte( 1 ); // 0.1's
		message_end();*/
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMPOINTS);
		engfunc( EngFunc_WriteCoord, Origin[pId][ 0 ]);     //Стартовая точка x
		engfunc( EngFunc_WriteCoord, Origin[pId][1]);     //Стартовая точка y
		engfunc( EngFunc_WriteCoord, Origin[pId][2]);     //Стартовая точка z
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 0 ]);     //Конечная точка x
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 0 ]);     //Конечная точка y
		engfunc( EngFunc_WriteCoord, Origin[iTarget][ 0 ]);     //Конечная точка z
		engfunc( EngFunc_WriteCoord, g_pSpriteGrabLine);         //Индекс спрайта
		write_byte(0);                 //Стартовый кадр
		write_byte(1);                 //Скорость анимации
		write_byte(1);            //Время существования
		write_byte(0);     //Толщина луча
		write_byte(0);     //Искажение
		write_byte(255);            //Цвет красный
		write_byte(0);            //Цвет зеленый
		write_byte(0);            //Цвет синий
		write_byte(2000);            //Яркость
		write_byte(0);                //...
		message_end();
	}
}


//#if GRAB_EFFECTS

	
#if GRAB_EFFECTS
	public fnGrabBall( pId )
	{
		pId -= TaskId_GrabBall;
		
		if( !pev_valid( pId ) || pId <= 0 || !is_user_connected( pId ) )
		return;
		
		#if GRAB_LEN_INFO
			#define iTarget g_iClientData[ pId ][ ClientData_Grabbed ]
			cprintf( pId, \
				"Расстояние между Вами: %d метров%s", \
					g_iClientData[ pId ][ ClientData_GrabLen ] / 22, \
						( !get_entvar( iTarget, var_owner ) && iTarget > MaxClients ) ? " | Коренное оружие" : "." );
			#undef iTarget
		#endif
		
		/*engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_vecHookOrigin[ pId ], 0 );
		write_byte( TE_SPRITETRAIL );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 0 ] );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 1 ] );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 2 ] );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 0 ] );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 1 ] );
		engfunc( EngFunc_WriteCoord, g_vecHookOrigin[ pId ][ 2 ] );
		write_short( g_pSpriteGrabBall );
		write_byte( 3 );
		write_byte( 1 ); // 0.1's
		write_byte( 1 );
		write_byte( 20 );
		write_byte( 2 );
		message_end(); */
	}

#endif

#if GRAB_EFFECTS
public grab_eff(id)
{
	new origin[3];
   
	get_user_origin(id,origin);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[Grab] grab_eff");
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);
	write_short(g_pSpriteGrabBall);
	write_byte(20);
	write_byte(10);
	write_byte( random_num(1, 255) );
	write_byte( random_num(1, 255) );
	write_byte( random_num(1, 255) );
	write_byte(255);
	message_end();
}
#endif

public ClCmd_Lastinv( pId )
{
	if( g_iClientData[ pId ][ ClientData_Grabbed ] && !jbe_is_user_user_boxcreat(pId))
	{
		new iLen = g_iClientData[ pId ][ ClientData_GrabLen ];		
		if( iLen > 90 )
		{
			iLen -= 50; 
			if( iLen <  g_iGrabMinimalDistance ) iLen = g_iGrabMinimalDistance;
			g_iClientData[ pId ][ ClientData_GrabLen ] = iLen;
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}


public do_choke( pId )
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[Grab] do_choke");
	}
	static Float: fReloadTime;
	
	new iTarget = g_iClientData[ pId ][ ClientData_Grabbed ];

	if( ( get_gametime() - fReloadTime ) < g_fGrabChokeReloadTime || pId == iTarget || iTarget > MaxClients ) 
		return;
	
	#define iDamage 7

	if(!jbe_is_user_connected(iTarget) || !jbe_is_user_alive(iTarget))
		return;
	
	new Float: vecOrigin[ 3 ]; vecOrigin = get_target_origin_f( iTarget );
	
	message_begin( MSG_ONE_UNRELIABLE, 97, _, iTarget );
	write_short( ( 1<<15 ) );
	write_short( ( 1<<14 ) );
	write_short( ( 1<<15 ) );
	message_end();
	
	message_begin( MSG_ONE_UNRELIABLE, 98, _, iTarget );
	write_short( ( 1<<13 ) );
	write_short( ( 1<<13 ) );
	write_short( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 200 );
	message_end();
	
	message_begin( MSG_ONE_UNRELIABLE, 71, _, iTarget );
	write_byte( 0 );
	write_byte( iDamage );
	write_long( DMG_CRUSH );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 2 ] );
	message_end();
		
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BLOODSTREAM );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 2 ] + 15.0 );
	engfunc( EngFunc_WriteCoord, random_float( 0.0, 255.0 ) );
	engfunc( EngFunc_WriteCoord, random_float( 0.0, 255.0 ) );
	engfunc( EngFunc_WriteCoord, random_float( 0.0, 255.0 ) );
	write_byte( 70 );
	write_byte( random_num( 50, 250 ) );
	message_end();
	

	ExecuteHam( Ham_TakeDamage, iTarget, get_pdata_cbase( pId, 373, 5 ), pId, iDamage.0, DMG_CRUSH );
		
	fReloadTime = get_gametime();
	#undef iDamage
}

public is_grabbed( iTarget, grabber )
{
	for( new i = 1; i <= MaxClients; i++ )
		if( g_iClientData[ i ][ ClientData_Grabbed ] == iTarget )
		{
			unset_grabbed( grabber );
			return true;
		}
	return false;
}

public DeathMsg() kill_grab( read_data( 2 ) );
public client_disconnected( id ) 
{
	kill_grab( id );
	ClearBit(g_iBitUserGrab, id);
}

public kill_grab( pId )
{
	if( g_iClientData[ pId ][ ClientData_Grabbed ] )
		unset_grabbed( pId );
	else if( g_iClientData[ pId ][ ClientData_Grabber ] )
		unset_grabbed( g_iClientData[ pId ][ ClientData_Grabber ] );
		
	if (bStatus[pId]) 
	{
		bStatus[pId] = false;
	}
}

stock traceline( const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3] )
{
	engfunc( EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0 );
	get_tr2( 0, TR_vecEndPos, vHitPos );
	return get_tr2( 0, TR_pHit );
}

stock get_view_pos( const id, Float:vViewPos[3] )
{
	new Float:vOfs[3];
	get_entvar( id, var_origin, vViewPos );
	get_entvar( id, var_view_ofs, vOfs );	
	
	vViewPos[0] += vOfs[0];
	vViewPos[1] += vOfs[1];
	vViewPos[2] += vOfs[2];
}

stock Float: vel_by_aim( id, speed = 1 )
{
	new Float:v1[3], Float:vBlah[3];
	get_entvar( id, var_v_angle, v1 );
	engfunc( EngFunc_AngleVectors, v1, v1, vBlah, vBlah );
	
	v1[0] *= speed;
	v1[1] *= speed;
	v1[2] *= speed;
	
	return v1;
}

stock Float: get_target_origin_f( pId )
{
	new Float: vecOrigin[ 3 ]; get_entvar( pId, var_origin, vecOrigin );
	if( pId > MaxClients )
	{
		new Float: fMinS[ 3 ]; get_entvar( pId, var_mins, fMinS );
		new Float: fMaxS[ 3 ]; get_entvar( pId, var_maxs, fMaxS );
		if( !fMinS[ 2 ] ) vecOrigin[ 2 ] += fMaxS[ 2 ] / 2;
	}
	
	return vecOrigin;
}

stock fm_strip_user_weapons( pPlayer )
{
	static iEntity, iszWeaponStrip = 0;
	if(iszWeaponStrip || (iszWeaponStrip = engfunc(EngFunc_AllocString, "player_weaponstrip"))) iEntity = engfunc(EngFunc_CreateNamedEntity, iszWeaponStrip);
	if(!pev_valid(iEntity)) return 0;
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Use, iEntity, pPlayer);
	engfunc(EngFunc_RemoveEntity, iEntity);
	set_pdata_int(pPlayer, 116, 0, 5);
	return 1;
}

stock fm_give_item(pPlayer, const szItem[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:vecOrigin[3];
	get_entvar(pPlayer, var_origin, vecOrigin);
	set_entvar(iEntity, var_origin, vecOrigin);
	set_entvar(iEntity, var_spawnflags, get_entvar(iEntity, var_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Touch, iEntity, pPlayer);
	if(get_entvar(iEntity, var_solid) != SOLID_NOT)
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
		return -1;
	}
	return iEntity;
}


stock GetFixTeam( pId )
{
	if( jbe_get_user_team( pId ) == 2 || !jbe_get_user_team( pId ) || jbe_get_user_team( pId ) == 3 )
		return 1;
	return 2;
}


public get_frozen_status( pId ) return bStatus[pId];

public set_frozen_status( id )
{

	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	if(!index_is_player(id)) 
		return PLUGIN_CONTINUE;
		
	//bStatus[id] = status;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[Grab] set_frozen_status");
	}
		
	if (!bStatus[id])
	{
		bStatus[id] = true;
	
		pGravity[id] = get_entvar(id,var_gravity);
		pSpeed[id] = get_entvar(id,var_maxspeed);
	
		set_entvar(id,var_gravity, 0.000001);
		set_entvar(id,var_velocity,Float:{0.0,0.0,0.0});
		//set_entvar(id,var_movetype, MOVETYPE_FLY); 
		set_entvar(id,var_maxspeed,0.0);
		
		get_entvar(id, var_origin, Origin[id]);

		set_entvar(id, var_renderfx, kRenderFxGlowShell);
		set_entvar(id, var_rendercolor, Float:{ 0.0, 100.0, 200.0 });
		set_entvar(id, var_rendermode, kRenderNormal);
		set_entvar(id, var_renderamt, 25.0);
		
		emit_sound(id, CHAN_BODY, SOUND_PLAYER_FROST, 1.0, ATTN_NORM, 0, PITCH_HIGH);
		
		if(!jbe_is_user_blind(id)) FreezeScreenFade(id,0,50,200,1);
	}
	else	// Размораживаем игрока
	{
		bStatus[id] = false;
	
		set_entvar(id,var_gravity,pGravity[id]);
		set_entvar(id,var_maxspeed,pSpeed[id]);

		set_entvar(id, var_renderfx, kRenderFxGlowShell);
		set_entvar(id, var_rendercolor, Float:{ 0.0, 0.0, 0.0 });
		set_entvar(id, var_rendermode, kRenderNormal);
		set_entvar(id, var_renderamt, 25.0);

		emit_sound(id, CHAN_BODY, SOUND_PLAYER_DEFROST, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		/*if(bColorStatus[id])
		{
			set_entvar( id, var_renderfx, kRenderFxGlowShell );		
			set_entvar( id, var_renderamt, 20.0 );
			set_entvar(id, var_rendercolor, g_fColor[bColor] );
			set_entvar( id, var_rendermode, kRenderNormal );
		}
		*/
	
	
		

		new origin[3];
		get_user_origin(id, origin);

		message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BREAKMODEL);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2] + 24);
		write_coord(16);
		write_coord(16);
		write_coord(16);
		write_coord(random_num(-50, 50));
		write_coord(random_num(-50, 50));
		write_coord(25);
		write_byte(10);
		write_short(g_iModelIndex_Frost);
		write_byte(10);
		write_byte(25);
		write_byte(0x01);
		message_end();
		
		if(!jbe_is_user_blind(id)) FreezeScreenFade(id);
	}
	return PLUGIN_CONTINUE;
}

stock FreezeScreenFade(id,r=0,g=0,b=0,t=0) 
{
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[Grab] FreezeScreenFade");
	}
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
	write_short(t ? 0:(1<<12));
	write_short(0);
	write_short(t ? 0x0004:0x0000);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(100);
	message_end();
}



stock GetWeaponNameByEntityId( iEntity )
{
	new szName[ 35 ]; 
	szName = "Не опознан."; 
	get_entvar( iEntity, var_model, szName, charsmax( szName ) );
	replace_all2( szName, charsmax( szName ), "models/jb_engine/weapons/w_", "" ); 
	replace_all2( szName, charsmax( szName ), "models/w_", "" ); 
	replace_all2( szName, charsmax( szName ), ".mdl", "" );
	replace_all2( szName, charsmax( szName ), "/", "" ); 
	return szName;
}

stock replace_all2(szString[], iLen, const szWhat[], const szWith[])
{
	new iPos;
	
	if((iPos = contain(szString, szWhat)) == -1) return 0;
	
	new iTotal, iWithLen = strlen(szWith), iDiff = strlen(szWhat) - iWithLen, iTotalLen = strlen(szString), iTempPos;
	
	while(iTotalLen + iWithLen < iLen && replace(szString[iPos], iLen - iPos, szWhat, szWith) != 0)
	{
		iTotal++;
		iPos += iWithLen;
		iTotalLen -= iDiff;
		
		if(iPos >= iTotalLen) break;
		
		iTempPos = contain(szString[iPos], szWhat);
		
		if(iTempPos == -1) break;
		
		iPos += iTempPos;
	}
	
	return iTotal;
}

stock fm_get_user_bpammo(pPlayer, iWeaponId)
{
	new iOffset;
	switch(iWeaponId)
	{
		case CSW_AWP: iOffset = 377; // ammo_338magnum
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: iOffset = 378; // ammo_762nato
		case CSW_M249: iOffset = 379; // ammo_556natobox
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: iOffset = 380; // ammo_556nato
		case CSW_M3, CSW_XM1014: iOffset = 381; // ammo_buckshot
		case CSW_USP, CSW_UMP45, CSW_MAC10: iOffset = 382; // ammo_45acp
		case CSW_FIVESEVEN, CSW_P90: iOffset = 383; // ammo_57mm
		case CSW_DEAGLE: iOffset = 384; // ammo_50ae
		case CSW_P228: iOffset = 385; // ammo_357sig
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: iOffset = 386; // ammo_9mm
		case CSW_FLASHBANG: iOffset = 387;
		case CSW_HEGRENADE: iOffset = 388;
		case CSW_SMOKEGRENADE: iOffset = 389;
		case CSW_C4: iOffset = 390;
		default: return 0;
	}
	return get_pdata_int(pPlayer, iOffset, 5);
}

stock UTIL_PlayerAnimation(pPlayer, const szAnimation[]) // Спасибо большое KORD_12.7
{
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	new Float:flGametime = get_gametime();
	set_pev(pPlayer, pev_frame, 0.0);
	set_pev(pPlayer, pev_framerate, 1.0);
	set_pev(pPlayer, pev_animtime, flGametime);
	set_pev(pPlayer, pev_sequence, iAnimDesired);
	set_pdata_int(pPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(pPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	set_pdata_float(pPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(pPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(pPlayer, m_flLastEventCheck, flGametime, linux_diff_animating);
	set_pdata_int(pPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);   
	set_pdata_float(pPlayer, m_flLastAttackTime, flGametime, linux_diff_player);
}

/*
new const g_szWeaponName[ 31 ][] = 
{ 	"Пистолет: p228", "Снайперка: Scout", "Граната: Взрывная", "Дробовик М.: Xm1014", "Взрывчатка: C4", "Автомат: Mac10",
	"Автомат: Aug", "Граната: Дым", "Пистолет: Elite", "Пистолет: FiveSeven", "Автомат: Ump45", "Скорострел: Sg550",
	"Автомат: Galil", "Автомат: Famas Сержант", "Пистолет: Usp", "Пистолет: Glock18", "Снайперка: AWP", "Автомат: MP5 Navy",
	"Пулемёт: M249", "Дробовик: M3", "Автомат: M4A1", "Автомат: TMP", "Скорострел: G3SG1", "Граната: леповая", "Пистолет: Дигл",
	"Автомат: AUG", "Автомат: AK47", "Слава Украине!", "Автомат: P90 [Петух]", "Обмундирование: Бронь", "Обмундирование: Бронь + Шлем" };

stock GetWeaponNameByEntityId( iEntity )
{				
	new iWeaponId = get_pdata_int( iEntity, 43, 4 ); 
	return g_szWeaponName[ --iWeaponId ];
}
*//// Метод работает только на ReAPI.
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
