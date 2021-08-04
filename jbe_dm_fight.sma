#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <jbe_core>
#include <reapi>

#define PLUGIN "[JBE_DM] Fight"
#define VERSION "1.0.0"
#define AUTHOR "A5800000BD79867"
#define lunux_offset_player 5
#define MsgId_CurWeapon 66

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

native jbe_set_friendlyfire(iType);
native jbe_totalalievplayers();
#define SetBit(%0,%1) ((%0) |= (1<<(%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1<<(%1)))
#define IsSetBit(%0,%1) ((%0) & (1<<(%1)))
#define InvertBit(%0,%1) ((%0) ^= (1<<(%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1<<(%1)))

#define TIME_TO_VOTE	15
#define TASK_OFFSET 16161112
#define TASK_CHECK_PLAYERS 16161208
#define TASK_SPAWN_PLAYER 74564578

native jbe_set_user_model_ex(pId, iType)
native jbe_Status_CustomSpawns(status);
native jbe_top_damaget_status(iType);
native jbe_is_user_top();

#define WIN_MONEY			20



native get_login(pId);
native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);

native jbe_exp_give_type(id);



new g_iDayModeFight, g_bGame;
new HamHook:g_iHamHookForwards[13];

new g_iTypeGame, g_iVote[3], iBit_Voted, g_iTimeVote;

new g_iFakeMetaKillConsole;
new g_iCvarRoundEnd[32];
//new g_iKillCount[33];
//new g_iUserGame;
new g_iSyncStatusText;

new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"game_player_equip", // Выдаёт оружие
	"player_weaponstrip", // Забирает всё оружие
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};

new HookChain:HookPlayer_Killed;
new HookChain:HookPlayer_Spawns;
new HookChain:HookPlayer_TraceAttack;
new HookChain:HookPlayer_HcRoundEnd;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_iDayModeFight = jbe_register_day_mode("JBE_DAY_MODE_FIGHT", 2, 180);


	register_menucmd(register_menuid("Show_VoteMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_VoteMenu");


	DisableHookChain(HookPlayer_Spawns = 		RegisterHookChain(RG_CBasePlayer_Spawn, 			"HC_CBasePlayer_PlayerSpawn_Post", 	true));
	DisableHookChain(HookPlayer_Killed = 		RegisterHookChain(RG_CBasePlayer_Killed, 			"HC_CBasePlayer_PlayerKilled_Post", true));
	DisableHookChain(HookPlayer_TraceAttack = 	RegisterHookChain(RG_CBasePlayer_TraceAttack,		"HC_CBasePlayer_TraceAttack_Player", false));
	DisableHookChain(HookPlayer_HcRoundEnd 		= 	RegisterHookChain(RG_RoundEnd, 						"HC_RoundEnd_Pre", .post = false));


	g_iFakeMetaKillConsole = 	register_forward( FM_ClientKill, "ClCmd_Kill" );
	unregister_forward(FM_ClientKill, g_iFakeMetaKillConsole, false);
	
	
	
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));

	g_iSyncStatusText = CreateHudSyncObj();
}

public client_disconnected(id)
{
	if(g_bGame)
	{
		//g_iKillCount[id] = 0;

		ClearBit(iBit_Voted, id);
	}
}


public ClCmd_Kill(pId)
{
	if( !is_user_alive(pId) && is_user_connected(pId))
		return FMRES_IGNORED;

	client_print(pId, print_console, "Стоит глобальный запрет на самоубиство");
	return FMRES_SUPERCEDE;
}


public client_putinserver(id)
{
	if(g_bGame)
	{
		if(!is_user_alive(id)) return;
		
		set_task(3.0 , "spawn_player", id + TASK_SPAWN_PLAYER)
				
		rg_send_bartime(id, 3, false);
	}
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{

	//if(!is_user_alive(iVictim)) return;
	if(g_bGame)
	{
		//if(jbe_is_user_valid(iVictim) && jbe_is_user_valid(iKiller)) g_iUserGame--;
		
		//if(jbe_totalalievplayers() <= 1)
				//rg_round_end(.tmDelay = 5.0, .st = WINSTATUS_TERRORISTS, .message = "Игра закончена!");
		switch(g_iTypeGame)
		{
			case 2: 
			{
				//g_iKillCount[iKiller]++;
				
				set_task(3.0 , "spawn_player", iVictim + TASK_SPAWN_PLAYER)
				
				rg_send_bartime(iVictim, 3, false);


			}
		}
		
		
		//server_print("%d", g_iUserGame);

		set_pev(iKiller, pev_health, 100.0);
	}	
}

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(is_user_alive(pId))
	{
		if(jbe_get_user_team(pId) == 2) 
		{
			jbe_set_user_model_ex(pId, 1);
			set_entvar(pId, var_health, 100.0);
		}
	}
	
}

public spawn_player(pId)
{
	pId -= TASK_SPAWN_PLAYER
	
	
	if(!jbe_is_user_connected(pId)) return;
	
	if(!jbe_is_user_alive(pId))
		rg_round_respawn(pId);
}

public jbe_day_mode_start(iDayMode, iAdmin)
{
	if(iDayMode == g_iDayModeFight)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i)) continue;

			//g_iKillCount[i] = 0;

			set_pev(i, pev_health, 100.0);

			fm_strip_user_weapons(i, 1);
			fm_give_item(i, "weapon_knife");

			jbe_set_user_model_ex(i, 1);
		}
		jbe_Status_CustomSpawns(true);
		g_bGame = true;

		g_iTypeGame = 0;

		Timer_Handler();
		g_iTimeVote = TIME_TO_VOTE;
		set_task(1.0, "Timer_Handler", TASK_OFFSET, _, _, "a", TIME_TO_VOTE);
		
		

		//for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		for(new i = 0; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		
		EnableHookChain(HookPlayer_Killed);
		EnableHookChain(HookPlayer_Spawns);
		EnableHookChain(HookPlayer_TraceAttack);
		EnableHookChain(HookPlayer_HcRoundEnd);
		
		g_iFakeMetaKillConsole = register_forward( FM_ClientKill, "ClCmd_Kill" );
		
		
	}
}

public Timer_Handler()
{
	if (--g_iTimeVote)
	{
		set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 0.8, 0.2, 0.2, -1);
		ShowSyncHudMsg
		(
			0, g_iSyncStatusText, "Разбегаемся^nБокс начнеться через %d секнуд^n^n^nДо последнего: %d^nПо кол-во убийств: %d" , g_iTimeVote, g_iVote[1], g_iVote[2]
		);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i)) continue;
			
			Show_VoteMenu(i);
		}
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i)) continue;
			
			show_menu(i, 0, "^n");
		}

		if (g_iVote[1] > g_iVote[2])
		{
			g_iTypeGame = 1;
			set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 0.8, 0.2, 0.2, -1);
			ShowSyncHudMsg
			(
				0, g_iSyncStatusText, "Включен каждый сам за себя"
			);
			
			set_task(3.0, "TimeCheckPlayers", TASK_CHECK_PLAYERS , _,_, "b");
		} else 
		{
			g_iTypeGame = 2;
			
			jbe_top_damaget_status(1);
			
			set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 5.8, 2.2, 5.2, -1);
			ShowSyncHudMsg
			(
				0, g_iSyncStatusText, "Включен по количеству убийств"
			);
			
		}
		
		//get_cvar_string("mp_round_infinite", g_iCvarRoundEnd, charsmax(g_iCvarRoundEnd));
		set_cvar_num("mp_round_infinite", 1);
		
		jbe_set_friendlyfire(3);
		UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	}
}

public TimeCheckPlayers()
{
	if(jbe_totalalievplayers() <= 1)
	{
		if(g_iTypeGame == 1)
		{
			new iLastPlayer;
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_alive(i)) continue;
				
				iLastPlayer = i;
				break;
			}
		
			set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 5.8, 2.2, 5.2, -1);
			ShowSyncHudMsg
			(
				0, g_iSyncStatusText, "Драка окончена!^nПоследний Боец - %n^nПриз 5 Бычков" , iLastPlayer
			);
		}
		
		rg_round_end(.tmDelay = 7.0, .st = WINSTATUS_TERRORISTS, .message = "Игра закончена!");
		//UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	}


}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{

	if(jbe_is_user_valid(iAttacker))
	{
		if(g_iTimeVote)
		{
			SetHookChainArg(3, ATYPE_FLOAT, 0.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
	
}



public jbe_day_mode_ended(iDayMode, iWinTeam)
{
	if(iDayMode == g_iDayModeFight)
	{
		g_bGame = false;
		
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);

		iBit_Voted = 0;
		
		jbe_set_friendlyfire(0);
		
		DisableHookChain(HookPlayer_Killed);
		DisableHookChain(HookPlayer_Spawns);
		DisableHookChain(HookPlayer_TraceAttack);
		DisableHookChain(HookPlayer_HcRoundEnd);
		jbe_Status_CustomSpawns(false);
		
		g_iVote[1] = 0;
		g_iVote[2] = 0;
		
		remove_task(TASK_CHECK_PLAYERS);
		
		jbe_top_damaget_status(0);
		
		unregister_forward(FM_ClientKill, g_iFakeMetaKillConsole, true);
		
		//set_cvar_string("mp_round_infinite", "aeg");
		//set_cvar_string("mp_round_infinite", g_iCvarRoundEnd);
		set_cvar_string("mp_round_infinite", "abeg");
		
		rg_round_end(.tmDelay = 7.0, .st = WINSTATUS_TERRORISTS, .message = "Игра закончена!");
		UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		switch(g_iTypeGame)
		{
			case 2:
			{
				/*new iPrev, iMax, winner_id;
				for(new i = 1; i <= MaxClients; i++)
				{
					if (!is_user_connected(i)) continue;

					iPrev = g_iKillCount[i];

					if (iMax < iPrev)
					{
						iMax = iPrev;
						winner_id = i;
					}
				}*/
				
				set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 5.8, 2.2, 5.2, -1);
				ShowSyncHudMsg
				(
					0, g_iSyncStatusText, "Драка окончена!^nПобедитель по киллу - %n^nПриз %d Бычков" , jbe_is_user_top(), WIN_MONEY
				);
				
				if(get_login(jbe_is_user_top()))
				{
					jbe_set_butt(jbe_is_user_top(), jbe_get_butt(jbe_is_user_top()) + WIN_MONEY);
					
					jbe_exp_give_type(jbe_is_user_top());
				}
				else
				{
					UTIL_SayText(0, "!g* !yИгрок !g%n !yничего не получил, т.к. не авторизован", jbe_is_user_top());
				}

				//if (!winner_id) Present_Handler(winner_id);
			}
			case 1:
			{
				new pIde
				for(new i = 1; i <= MaxClients; i++)
				{
					if(!jbe_is_user_alive(i)) continue;
					
					pIde = i;
					break;
				}
				
				if(get_login(pIde))
				{
					set_hudmessage(100, 100, 100, -1.0, 0.22, 0, 0.0, 5.8, 2.2, 5.2, -1);
					ShowSyncHudMsg
					(
						0, g_iSyncStatusText, "Драка окончена!^nПобедитель по киллу - %n^nПриз 5 Бычков" , pIde
					);
					
					jbe_set_butt(pIde, jbe_get_butt(pIde) + WIN_MONEY);
					
					jbe_exp_give_type(pIde);
				}
				else
				{
					UTIL_SayText(0, "!g* !yИгрок !g%n !yничего не получил, т.к. не авторизован", pIde);
				}
			}
		}

		remove_task(TASK_OFFSET);
	}
}

public HC_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

public bool:Present_Handler(id)
{
	return true;
}

Show_VoteMenu(id)
{
	new szMenu[256], iKey, iLen;
	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yВыберите режим:^nДо начало игры: %d сек^n^n", g_iTimeVote);

	if(IsNotSetBit(iBit_Voted, id))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \wДо последнего \y[%d]^n", g_iVote[1]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2. \wПо количеству убийств \y[%d]^n", g_iVote[2]);
		iKey |= (1<<0|1<<1);
	}
	else 
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \dДо последнего \y[%d]^n", g_iVote[1]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2. \dПо количеству убийств \y[%d]^n", g_iVote[2]);
	}
	return show_menu(id, iKey, szMenu, -1, "Show_VoteMenu");
}

public Handle_VoteMenu(id, iKey)
{
	if (!jbe_is_user_alive(id)) return PLUGIN_HANDLED;

	g_iVote[iKey+1]++;

	SetBit(iBit_Voted, id);

	return PLUGIN_HANDLED;
}

stock fm_strip_user_weapons(id, iType = 0)
{
	new iEntity;
	static iszWeaponStrip = 0;
	if(iszWeaponStrip || (iszWeaponStrip = engfunc(EngFunc_AllocString, "player_weaponstrip"))) iEntity = engfunc(EngFunc_CreateNamedEntity, iszWeaponStrip);
	if(!pev_valid(iEntity)) return 0;
	if(iType && get_user_weapon(id) != CSW_KNIFE)
	{
		engclient_cmd(id, "weapon_knife");
		message_begin(MSG_ONE_UNRELIABLE, MsgId_CurWeapon, _, id);
		write_byte(1);
		write_byte(CSW_KNIFE);
		write_byte(0);
		message_end();
	}
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Use, iEntity, id);
	engfunc(EngFunc_RemoveEntity, iEntity);
	return 1;
}

stock fm_give_item(id, const szItem[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:vecOrigin[3];
	pev(id, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	new iSolid = pev(iEntity, pev_solid);
	dllfunc(DLLFunc_Touch, iEntity, id);
	if(pev(iEntity, pev_solid) == iSolid)
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
		return -1;
	}
	return iEntity;
}



#define MsgId_SendAudio 100

stock UTIL_SendAudio(pPlayer, iPitch = 100, const szPathSound[], any:...)
{
	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(MSG_BROADCAST, MsgId_SendAudio);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SendAudio, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
	}
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
