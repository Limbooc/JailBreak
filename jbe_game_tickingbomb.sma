#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <jbe_core>
#include <reapi>

#define PLUGIN "[JB] MINIGAMES: TIPED BOMB"
#define VERSION "1.0"
#define AUTHOR "DalgaPups"

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define MsgId_ScreenShake 97
#define TASK_TICKINGBOMB 4876574321111

native jbe_aliveplayersnum(iType)
native jbe_is_opened_door();
native jbe_open_main_menu(pId, iMenu);

new HookChain:HookPlayer_PlayerTraceAttack, 
	jbe_is_user_hasbomb[MAX_PLAYERS + 1], 
	ThinkPost;
	

new g_pcvar_one,
	g_pcvar_two;

new const tickingbomb_classname[] = "tickingbomb";
new tickingbomb_model[64] = "models/jb_engine/w_bomb.mdl";

new sprites_eexplo,
	g_iSyncGame;

new bool:g_iGameStart,
	bool:g_iRepeatPlayers;

new bomb_tick_sounds[][64] = {
	"weapons/c4_beep1.wav",
	"weapons/c4_beep2.wav",
	"weapons/c4_beep3.wav",
	"weapons/c4_beep4.wav",
	"weapons/c4_beep5.wav"
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	
	g_pcvar_one = register_cvar("jb_minigame_tickingbomb_glow", "0");
	g_pcvar_two = register_cvar("jb_minigame_tickingbomb_life", "15");
	
	ThinkPost = register_forward(FM_Think, "fw_think_info_target_post", 1);
	unregister_forward(FM_Think, ThinkPost, 1);
	
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	DisableHookChain(HookPlayer_PlayerTraceAttack	= 	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false));
	register_menucmd(register_menuid("Show_BossGiveRole"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_BossGiveRole");
	
	g_iSyncGame = CreateHudSyncObj();
}

public plugin_natives()
{
	register_native("jbe_open_tickitbomb", "jbe_open_tickitbomb", 1);
}

public plugin_precache()
{
	new i, szBuffer[64];
	new const szSound[][] = {"c4_beep1", "c4_beep2", "c4_beep3", "c4_beep4", "c4_beep5"};
	for(i = 0; i < sizeof(szSound); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "weapons/%s.wav", szSound[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	engfunc(EngFunc_PrecacheModel, tickingbomb_model);

	sprites_eexplo = engfunc(EngFunc_PrecacheModel, "sprites/eexplo.spr");
}

public jbe_open_tickitbomb(pId) return Show_BossGiveRole(pId)

Show_BossGiveRole(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yПередай бомбу^n^n");
	
	FormatItem("\y1. \w%s игру^n^n", g_iGameStart ? "Отключить" : "Включить"), iKeys |= 1<<0;

	if(g_iGameStart)
	{
		
		FormatItem("\y2. \wВыдать случайному игроку^n"), iKeys |= 1<<1;
		FormatItem("\y3. \wПосле смерти выбрать другого: \y%s^n", g_iRepeatPlayers ? "ON" : "OFF"), iKeys |= 1<<2;
	}
	else 
	{
		FormatItem("\y2. \dВыдать случайному игроку^n");
		FormatItem("\y3. \dПосле смерти выбрать другого: \y%s^n", g_iRepeatPlayers ? "ON" : "OFF");
	}

	FormatItem("^n^n\y0. \Назад^n");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_BossGiveRole");
}

public Handle_BossGiveRole(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: 
		{
			g_iGameStart = !g_iGameStart
			
			switch(g_iGameStart)
			{
				case true:
				{
					ThinkPost = register_forward(FM_Think, "fw_think_info_target_post", 1);
					EnableHookChain(HookPlayer_PlayerTraceAttack);
				}
				case false:
				{
					unregister_forward(FM_Think, ThinkPost, 1);
					DisableHookChain(HookPlayer_PlayerTraceAttack);
					
					if(task_exists(TASK_TICKINGBOMB))
						remove_task(TASK_TICKINGBOMB);
	
					new ent;
					while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", tickingbomb_classname)) > 0)
					{
						engfunc(EngFunc_RemoveEntity, ent);
					}
					
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots);
					
					for(new i; i < iPlayerCount; i++)
					{
						jbe_is_user_hasbomb[iPlayers[i]] = 0;
					}
				}
			}
		}
		case 1: minigame_handling(pId);
		case 2: g_iRepeatPlayers = !g_iRepeatPlayers;

		case 9: return jbe_open_main_menu(pId, 1);
	}
	return Show_BossGiveRole(pId);
}

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	if(g_iGameStart)
	{
		unregister_forward(FM_Think, ThinkPost, 1);
		DisableHookChain(HookPlayer_PlayerTraceAttack);
		
		if(task_exists(TASK_TICKINGBOMB))
			remove_task(TASK_TICKINGBOMB);

		new ent;
		while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", tickingbomb_classname)) > 0)
		{
			engfunc(EngFunc_RemoveEntity, ent);
		}
		
		static iPlayers[MAX_PLAYERS], iPlayerCount;
		get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots);
		
		for(new i; i < iPlayerCount; i++)
		{
			jbe_is_user_hasbomb[iPlayers[i]] = 0;
		}
		
		g_iGameStart = false;
	}
}



public minigame_handling(pId)
{
	if(task_exists(TASK_TICKINGBOMB)) 
	{
		UTIL_SayText(pId, "!g* !yПовторите еще раз!");
		return;
	}
	if(!jbe_is_opened_door())
	{
		UTIL_SayText(pId, "!g* !yНельзя играть в закрытах клетках");
		return;
	}
	set_task(3.0, "give_tickingbomb", TASK_TICKINGBOMB)
	UTIL_SayText(0, "!g* !tБОМБА !yИгра начнется через 3 секунды, !gУдачи!")
}


public give_tickingbomb(TASK_ID)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount, pPlayer;

	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
	if (!iPlayerCount) 
	{	
		UTIL_SayText(0, "!g* !yПодходящих игроков не найдено");
		return ;
	}
	if(jbe_aliveplayersnum(1) > 1)
	{
		pPlayer = iPlayers[random_num(0, iPlayerCount - 1)];

		if(!is_user_connected(pPlayer)) return;
		jbe_set_user_tickingbomb(pPlayer)
		UTIL_SayText(0, "!g* !tПередай бомбу !g- !t%n !yв руках бомба!", pPlayer)
		
		set_hudmessage(255, 0, 0, -1.0, 0.35, 1, 6.0, 6.0, 0.01, 0.05, -1)
		ShowSyncHudMsg(pPlayer, g_iSyncGame,"!! У вас бомба!! ^n скорей передайте кому-то!")
	}
	else
	{
		UTIL_SayText(0, "!g* !yПодходящих игроков не найдено");
		return;
	}
	
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{

	if(jbe_is_user_valid(iAttacker))
	{

		if(!g_iGameStart)
			return HC_CONTINUE;
		
		if(jbe_get_user_team(iAttacker) != jbe_get_user_team(iVictim))
			return HC_CONTINUE;
		
		if(get_user_weapon(iAttacker) != CSW_KNIFE)
			return HC_CONTINUE;

		new ent;
		if((ent = jbe_is_user_hasbomb[iAttacker]) > 0 && !jbe_is_user_hasbomb[iVictim])
		{
			set_entvar(ent, var_aiment, iVictim)
			set_entvar(ent, var_owner, iAttacker)
			jbe_is_user_hasbomb[iVictim] = ent;
			jbe_is_user_hasbomb[iAttacker] = 0;
			
			UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
			
			set_hudmessage(255, 0, 0, -1.0, 0.35, 1, 6.0, 6.0, 0.01, 0.05, -1)
			ShowSyncHudMsg(iVictim, g_iSyncGame, "!! У вас бомба!! ^n скорей передайте кому-то!")
			
			ShowSyncHudMsg(iAttacker, g_iSyncGame, "")
		}
	}
	return HC_CONTINUE;
}

public fw_think_info_target_post(const ent)
{
	if(!pev_valid(ent)) return FMRES_IGNORED;


	static classname[32]
	get_entvar(ent, var_classname, classname, charsmax(classname))
	
	if(!equal(classname, tickingbomb_classname)) return FMRES_IGNORED;
	
	
	static Float:fExpTime, Float:fGTime, iTarget, iOwner;
	iOwner =  get_entvar(ent, var_owner);
	iTarget = get_entvar(ent, var_aiment);
	
	if(!is_user_connected(iOwner))
	{
		iOwner = iTarget;
		set_entvar(ent, var_owner, iTarget);
	}
	
	if(!is_user_alive(iTarget))
	{
		jbe_remove_user_tickingbomb(iTarget);
		

		set_task(3.0, "give_tickingbomb", TASK_TICKINGBOMB)
		UTIL_SayText(0, "!g* !tПередай бомбу, !yЧерез 3 секунды будет определенн случайный игрок с бомбой, !gУдачи!")
		
		return FMRES_IGNORED;
	}
	
	if(jbe_aliveplayersnum(1) == 1)
	{
		jbe_remove_user_tickingbomb(iTarget);
		return FMRES_IGNORED;
	}
	
	fGTime = get_gametime();
	get_entvar(ent, var_fuser4, fExpTime)
	
	switch( floatround((fExpTime - fGTime)) )
	{
		case 25..999:
		{
			emit_sound(ent, CHAN_AUTO, bomb_tick_sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(ent, var_nextthink, fGTime + 1.4);
		}
		case 15..24:
		{
			emit_sound(ent, CHAN_AUTO, bomb_tick_sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(ent, var_nextthink, fGTime + 1.2);
		}
		case 10..14:
		{
			emit_sound(ent, CHAN_AUTO, bomb_tick_sounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(ent, var_nextthink, fGTime + 1.0);
		}
		case 4..9:
		{
			emit_sound(ent, CHAN_AUTO, bomb_tick_sounds[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(ent, var_nextthink, fGTime + 0.8);
		}
		case 0..3:
		{
			emit_sound(ent, CHAN_AUTO, bomb_tick_sounds[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(ent, var_nextthink, fGTime + 0.4);
		}
		default:
		{
			static Float:fOrigin[3];
			get_entvar(ent, var_origin, fOrigin);
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2])
			write_short(sprites_eexplo)
			write_byte(10)
			write_byte(10)
			write_byte(0)
			message_end()
			
			jbe_remove_user_tickingbomb(iTarget)
			
			new frags = get_entvar(iOwner, var_frags);
			set_entvar(iOwner, var_frags, frags + 1);
			ExecuteHamB(Ham_Killed, iTarget, iOwner, 1);
			
			if(g_iRepeatPlayers && jbe_aliveplayersnum(1) > 1)
			{
				set_task(3.0, "give_tickingbomb", TASK_TICKINGBOMB)
				UTIL_SayText(0, "!g* !tПередай бомбу, !yЧерез 3 секунды будет определен случайный игрок с бомбой, !gУдачи!")
			}
		}
	}
	return FMRES_IGNORED;
}

jbe_remove_user_tickingbomb(const index)
{
	new ent;
	if(!pev_valid((ent = jbe_is_user_hasbomb[index]))) return 0;
	
	engfunc(EngFunc_RemoveEntity, ent);
	jbe_is_user_hasbomb[index] = 0;
	return 1;
}

public client_disconnected(id)
{
	jbe_remove_user_tickingbomb(id)
}

jbe_set_user_tickingbomb(const index)
{
	if(jbe_is_user_hasbomb[index] > 0) return 0;
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	if(!ent) return 0;
	
	jbe_is_user_hasbomb[index] = ent;
	
	new Float:fgametime = get_gametime();
	
	set_entvar(ent, var_classname, tickingbomb_classname);
	engfunc(EngFunc_SetModel, ent, tickingbomb_model);
	set_entvar(ent, var_solid, SOLID_NOT);
	set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(ent, var_aiment, index);
	set_entvar(ent, var_owner, index);
	set_entvar(ent, var_fuser4, (fgametime + floatclamp(get_pcvar_float(g_pcvar_two), 5.0, 30.0)));
	set_entvar(ent, var_nextthink, fgametime + 0.5);

	
	if(get_pcvar_num(g_pcvar_one) > 0)
	{
		set_entvar(ent, var_renderfx, kRenderFxGlowShell);
		set_entvar(ent, var_rendercolor, Float:{255.0,0.0,0.0});
		set_entvar(ent, var_renderamt, 255.0);
	}
	
	return ent;
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}
