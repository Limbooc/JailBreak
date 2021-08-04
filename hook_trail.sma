/*
 * Author: https://t.me/twisternick (https://dev-cs.ru/members/444/)
 */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>
#include <engine>
#include <jbe_core>

#pragma semicolon 1

native jbe_all_users_wanted();
native jbe_is_user_duel(id);
native jbe_get_soccergame();
native jbe_globalnyizapret();

new const PLUGIN_VERSION[] = "1.7";

/****************************************************************************************
****************************************************************************************/

#define IsPlayerValid(%0) (1 <= %0 <= MaxClients)
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

#define linux_diff_animating 4
#define linux_diff_player 5
#define m_flLastAttackTime 220
#define m_fSequenceLoops 40
#define m_fSequenceFinished 39
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define ACT_RANGE_ATTACK1 28


#define m_Activity 73
#define m_IdealActivity 74
#define m_flLastAttackTime 220


new g_iFlags;
new bool:g_bHookUse[MAX_PLAYERS+1], g_iHookOrigin[MAX_PLAYERS+1][3];
new bool:g_bNeedRefresh[MAX_PLAYERS+1];
new bool:g_bRoundEnd = false;
native zl_boss_map();

enum (+= 100)
{
	TASK_ID_HOOK,
	TASK_POWER_HOOK
};

new g_iLifeTime,
	g_iBitUserHook;

new g_pSpriteTrailHook;

public plugin_init()
{
	register_plugin("Hook Trail", PLUGIN_VERSION, "w0w");
	register_dictionary("hook_trail.ini");

	register_clcmd("+hook", "func_HookEnable");
	register_clcmd("-hook", "func_HookDisable");

	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "refwd_PlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "refwd_PlayerKilled_Post", true);
	
	if(zl_boss_map()) return;
	new iEnt = rg_create_entity("info_target", true);
	SetThink(iEnt, "think_Hook");
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
	
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
}
public LogEvent_RoundEnd() 
{
	if(!task_exists(TASK_POWER_HOOK)) 
		g_bRoundEnd = true;
}
forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv() {
	if(!task_exists(TASK_POWER_HOOK)) 
		set_task(3.0, "Task_On_Hook", TASK_POWER_HOOK);
}

public Task_On_Hook() g_bRoundEnd = false;


public plugin_precache()
{
	new pCvar, szCvarSprite[MAX_RESOURCE_PATH_LENGTH];

	pCvar = create_cvar("hook_trail_life_time", "2", FCVAR_NONE, fmt("%l", "HOOK_TRAIL_CVAR_LIFE_TIME"), true, 1.0, true, 25.0);
	bind_pcvar_num(pCvar, g_iLifeTime);

	pCvar = create_cvar("hook_trail_sprite", "sprites/speed.spr", FCVAR_NONE, fmt("%l", "HOOK_TRAIL_CVAR_SPRITE"));

	AutoExecConfig(true, "hook_trail");

	get_pcvar_string(pCvar, szCvarSprite, charsmax(szCvarSprite));

	pCvar = register_cvar("hook_trail_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	set_pcvar_string(pCvar, PLUGIN_VERSION);
	
	register_cvar( "jbe_hook_access", "s" );
	
	set_task( 2.0, "LoadCvarsDelay" );

	if(!file_exists(szCvarSprite))
		set_fail_state("[Hook Trail] Model ^"%s^" doesn't exist", szCvarSprite);

	g_pSpriteTrailHook = precache_model(szCvarSprite);
}

public LoadCvarsDelay()
{
	new szFlags[ 2 ];
	get_cvar_string( "jbe_hook_access", szFlags, charsmax( szFlags ) ); g_iFlags = read_flags( szFlags );
}

forward OnAPIAdminConnected(id, const szName[], adminID, Flags);

public client_putinserver(id)
{
	new iFlags = get_user_flags(id);
	if(iFlags & g_iFlags) SetBit(g_iBitUserHook, id);
}
public OnAPIAdminConnected(id, const szName[], adminID, iFlags)
{
	ClearBit(g_iBitUserHook, id);
	//new iFlags = get_user_flags(id);
	if(iFlags & g_iFlags) SetBit(g_iBitUserHook, id);
}

public frallion_access_user(pId, szFlags[])
{
	new iFlags = read_flags(szFlags);
	
	if( iFlags & g_iFlags ) 
	{
		SetBit(g_iBitUserHook, pId);
	}
}

public refwd_PlayerSpawn_Post(id)
{
	if(jbe_is_user_alive(id))
	{
		g_bHookUse[id] = false;
	}
}

public refwd_PlayerKilled_Post(iVictim)
{
	g_bHookUse[iVictim] = false;
	remove_task(iVictim+TASK_ID_HOOK);
}

public client_disconnected(id)
{
	g_bHookUse[id] = false;
	remove_task(id+TASK_ID_HOOK);
	ClearBit(g_iBitUserHook, id);
}

public func_HookEnable(id)
{
	if(!jbe_is_user_alive(id))
	{
		client_print_color(id, 0, "^x04*^x01 Полет разрешен только живым!");
		return PLUGIN_HANDLED;
	}
	else
	if(IsNotSetBit(g_iBitUserHook, id))
	{
		client_print_color(id, 0, "^x04*^x01 У вас недостаточна прав для использование полета");
		return PLUGIN_HANDLED;
	}
	else
	if(jbe_all_users_wanted())
	{
		client_print_color(id, 0, "^x04*^x01 Среди заключенных есть бунтарь, полет запрещен!");
		return PLUGIN_HANDLED;
	}
	else
	if(jbe_get_day_mode() == 3) 
	{
		client_print_color(id, 0, "^x04*^x01Во время игр, полет недоступен."); 
		return PLUGIN_HANDLED;
	}
	else
	if(jbe_get_user_team(id) == 1 && (jbe_is_user_duel(id) || jbe_get_soccergame()))
	{
		client_print_color(id, 0, "^x04*^x01Во время дуэли\футбола, полет недоступен."); 
		return PLUGIN_HANDLED;
	}
	else
	if(id != jbe_get_chief_id() && jbe_globalnyizapret())
	{
		client_print_color(id, 0, "^x04*^x01Во время глобального режима, полет запрещен"); 
		return PLUGIN_HANDLED;
	}
	else
	if(zl_boss_map())
	{
		client_print_color(id, 0, "^x04*^x01В режиме битвы с боссом, полет запрещен"); 
		return PLUGIN_HANDLED;
	}
		

	g_bHookUse[id] = true;
	get_user_origin(id, g_iHookOrigin[id], Origin_AimEndEyes);

	if(!task_exists(id+TASK_ID_HOOK))
	{
		func_RemoveTrail(id);
		func_SetTrail(id);
		set_task_ex(0.1, "task_HookWings", id+TASK_ID_HOOK, .flags = SetTask_Repeat);
		UTIL_PlayerAnimation(id, "swim");
	}

	return PLUGIN_HANDLED;
}

Show_OtherUaio(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yНастройки Полета^n^n");
	
	FormatItem("\y1. \dРежим полета: \y%s^n", g_iTypeHook[pId] ? "Полет" : "Паутинка");
	FormatItem("\y2. \dСк^n");
	FormatItem("\y3. \dРазные команды^n");
	FormatItem("\y4. \dВернуть к стандарту^n^n");
	FormatItem("\y5. \rСбросить все^n");

	
	FormatItem("\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_OtherUaio");
}

Handle_OtherUaio(pId, iKey) 
{
	switch(iKey)
	{
		case 8: return PLUGIN_HANDLED;
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public func_HookDisable(id)
{
	g_bHookUse[id] = false;
	return PLUGIN_HANDLED;
}

func_SetTrail(id)
{
	if(!jbe_is_user_connected(id)) return;
	
	//new iColor = random_num(1, 255);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);					// entity
	write_short(g_pSpriteTrailHook);	// sprite index
	write_byte(g_iLifeTime * 10);		// life
	write_byte(15);						// width
	write_byte(random_num(1, 255));					// red
	write_byte(random_num(1, 255));					// green
	write_byte(random_num(1, 255));					// blue
	write_byte(255);					// brightness
	message_end();
}

func_RemoveTrail(id)
{
	if(!jbe_is_user_connected(id)) return;
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(id);
	message_end();
}

public task_HookWings(id)
{
	id -= TASK_ID_HOOK;

	if(get_entvar(id, var_flags) & FL_ONGROUND && !g_bHookUse[id])
	{
		remove_task(id);
		func_RemoveTrail(id);
		return;
	}

	static Float:flVelocity[3];
	get_entvar(id, var_velocity, flVelocity);

	if(vector_length(flVelocity) < 10.0)
		g_bNeedRefresh[id] = true;
	else if(g_bNeedRefresh[id])
	{
		g_bNeedRefresh[id] = false;
		func_RemoveTrail(id);
		func_SetTrail(id);
	}
}

public think_Hook(iEnt)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);

	static 	Float:iOrigin[3], 
			Float:flVelocity[3], 
			iDistance, 
			iOriginW[3];

	for(new i, iPlayer; i < iPlayerCount; i++)
	{
		iPlayer = iPlayers[i];

		if(!g_bHookUse[iPlayer] || !jbe_is_user_alive(iPlayer))
			continue;
		if(jbe_all_users_wanted() || g_bRoundEnd)
		{
			//g_bHookUse[iPlayer] = false;
			continue;
		}
		//get_user_origin(iPlayer, iOriginW);
		get_entvar(iPlayer, var_origin, iOriginW);
		iDistance = get_distance(g_iHookOrigin[iPlayer], iOriginW);
		if(iDistance > 25)
		{
			VelocityByAim(iPlayer, 650, iOrigin);
			
			flVelocity[0] = iOrigin[0];
			flVelocity[1] = iOrigin[1];
			flVelocity[2] = iOrigin[2];
			set_entvar(iPlayer, var_velocity, flVelocity);
		}
	}

	set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
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

/****************************************************************************************
****************************************************************************************/
