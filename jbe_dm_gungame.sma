#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <jbe_core>
#include <engine>
#include <reapi>
new g_iGlobalDebug;
#include <util_saytext>

//#define DEBUG

#define TIME_FOR_GAME		300
#define KILLED_FRAG 		3
#define TIME_TO_VOTE		10
#define TIME_TO_RESPAWN 	3
#define TIMEPUTIN_TO_RESPAWN 	5
#define WEAPON_BPAMMO		90
#define GIVE_HEGRANADE_TIME	3
#define SPAWN_HEALTH		100.0
#define START_LEVEL			0

#define WIN_EXP				20

#define MsgId_RoundTime 101

#define ENEMY_INFO


#define WIN_MONEY			25

native get_login(pId);
native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);
native jbe_mysql_get_exp(pPlayer, iType);
native jbe_mysql_set_exp(id, iType, set);

native jbe_exp_give_type(id);

#define TASK_SPAWN 547568
#define TASK_OFFSET 4756859
#define TASK_HUDINFO 4564885698
#define TASK_GIVEGRENADE_ID 5674578


#define PLUGIN "[JBE_DM] GunGame"
#define VERSION "1.2.0"
#define AUTHOR "DalgaPups"

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define SetBit(%0,%1) ((%0) |= (1<<(%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1<<(%1)))
#define IsSetBit(%0,%1) ((%0) & (1<<(%1)))
#define InvertBit(%0,%1) ((%0) ^= (1<<(%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1<<(%1)))

#define MsgId_ScreenFade 98


enum
{
	WORLD = 0,
	BULLET,
	KNIFE,
	GRENADE
}


native jbe_Status_CustomSpawns(iType);

native jbe_set_user_model_ex(pId, iType)
native jbe_set_friendlyfire(iType);


new const g_iData_Wpn[][][] = 
{
	{"Glock 18", "weapon_glock18", "17"},
	{"HK USP .45 Tactical", "weapon_usp", "16"},
	{"SIG-Sauer P228", "weapon_p228", "1"},
	{"IMI Desert Eagle .50AE", "weapon_deagle", "26"},
	{"FN Five-Seven", "weapon_fiveseven", "11"},
	{"Benelli M3 Super 90", "weapon_m3", "21"},
	{"Benelli XM1014", "weapon_xm1014", "5"},
	{"Ingram MAC-10", "weapon_mac10", "7"},
	{"Steyr TMP", "weapon_tmp", "23"},
	{"HK MP5 Navy", "weapon_mp5navy", "19"},
	{"HK UMP 45", "weapon_ump45", "12"},
	{"FN P90", "weapon_p90", "30"},
	{"FAMAS", "weapon_famas", "15"},
	{"IMI Galil ARM", "weapon_galil", "14"},
	{"Colt M4A1", "weapon_m4a1", "22"},
	{"AK-47", "weapon_ak47", "28"},
	{"Steyr AUG", "weapon_aug", "8"},
	{"SG-552", "weapon_sg552", "27"},
	{"Arctic Warfare Police", "weapon_awp", "18"},
	{"SG-550 Sniper Rifle", "weapon_sg550", "13"},
	{"G3/SG-1 Sniper Rifle", "weapon_g3sg1", "24"},
	{"Steyr Scout", "weapon_scout", "3"},
	{"M249 PARA", "weapon_m249", "20"},
	{"HE Grenade", "weapon_hegrenade", "4"}
};
new g_iUserLvl[MAX_PLAYERS + 1],
	g_iUserKilled[MAX_PLAYERS + 1];
	
new g_iMaxLevel;
new bool:g_bGame,
	g_iDayModeGunGame,
	g_iTimeVote;

new bool:g_iPreStartGG,
	bool:g_iEndFackRound;
//new g_iCvarRoundEnd[32];
new HamHook:g_iHamHookForwards[13],
	HookChain:HookPlayer_Killed,
	HookChain:HookPlayer_Spawn,
	HookChain:HookPlayer_TraceAttack,
	HookChain:HookPlayer_DropPlayerItem,
	HookChain:HookPlayer_DeadPlayerWeapons;
	//HookChain:HookPlayer_HcRoundEnd;
#if defined ENEMY_INFO
new g_iMsgTeamInfo;
#endif
new g_iSyncStatusText;
new g_iUserStatusText;
new g_iLeaderId;
new g_iLeaderLevel;

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

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_iDayModeGunGame = jbe_register_day_mode("JBE_DAY_MODE_GUNGAME", 2, TIME_FOR_GAME);
	
	DisableHookChain(HookPlayer_Killed = 			RegisterHookChain(RG_CBasePlayer_Killed, 			"HC_CBasePlayer_PlayerKilled_Post", true));
	DisableHookChain(HookPlayer_Spawn   = 			RegisterHookChain(RG_CBasePlayer_Spawn, 			"HC_CBasePlayer_PlayerSpawn_Post", true));
	DisableHookChain(HookPlayer_TraceAttack = 		RegisterHookChain(RG_CBasePlayer_TraceAttack,		"HC_CBasePlayer_TraceAttack_Player", false));
	DisableHookChain(HookPlayer_DropPlayerItem = 	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, 	"HC_CBasePlayer_DropPlayerItem", false));
	DisableHookChain(HookPlayer_DeadPlayerWeapons = RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "CSGameRules_DeadPlayerWeapons"));
	//DisableHookChain(HookPlayer_HcRoundEnd 		= 	RegisterHookChain(RG_RoundEnd, 						"HC_RoundEnd_Pre", .post = false));
	
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	
	register_clcmd("drop", "ClCmd_Drop");

	g_iMaxLevel = charsmax(g_iData_Wpn);
	
	g_iSyncStatusText = CreateHudSyncObj();
	g_iUserStatusText = CreateHudSyncObj();
	
	register_event("AmmoX","EventAmmoX","be");
	
	//register_message(g_iMsgTeamInfo = get_user_msgid("TeamInfo"), "msg_TeamInfo");
	
	#if defined ENEMY_INFO
	g_iMsgTeamInfo = get_user_msgid("TeamInfo");
	register_message(g_iMsgTeamInfo, "msg_TeamInfo");
	#endif
	
	#if defined DEBUG
	register_clcmd("say /lvlup" , "lvlup");
	#endif
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}
#if defined DEBUG
public lvlup(pId) 
{
	g_iUserLvl[pId] = 21
	rg_give_item(pId, "weapon_knife", GT_REPLACE);
	rg_give_item_ex(pId, g_iData_Wpn[g_iUserLvl[pId]][1], GT_REPLACE, WEAPON_BPAMMO);
}
#endif	

public HamHook_EntityBlock() return HAM_SUPERCEDE;
public CBasePlayer_DropPlayerItem() return HC_SUPERCEDE;
public HC_CBasePlayer_DropPlayerItem(id) return HC_SUPERCEDE;

public ClCmd_Drop( pId ) <> { return PLUGIN_CONTINUE; }
public ClCmd_Drop( pId ) <dBlockCmd: Disabled> { return PLUGIN_CONTINUE; } 
public ClCmd_Drop( pId ) <dBlockCmd: Enabled> { return PLUGIN_HANDLED; }

public CSGameRules_DeadPlayerWeapons(const index)
{
    SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);
    return HC_SUPERCEDE;
}

public HC_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}


public jbe_day_mode_start(iDayMode, iAdmin)
{
	if(iDayMode == g_iDayModeGunGame)
	{
		g_bGame = true;
		state dBlockCmd: Enabled;
		
		for(new i = 0; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		EnableHookChain(HookPlayer_Spawn);
		EnableHookChain(HookPlayer_Killed);
		EnableHookChain(HookPlayer_TraceAttack);
		EnableHookChain(HookPlayer_DeadPlayerWeapons);
		EnableHookChain(HookPlayer_DropPlayerItem);
		//EnableHookChain(HookPlayer_HcRoundEnd);
		
		message_begin(MSG_BROADCAST, MsgId_RoundTime);
		write_short(TIME_FOR_GAME);
		message_end();
		
		jbe_set_friendlyfire(3);
		
		g_iPreStartGG = false;
		g_iEndFackRound = false;
		
		//get_cvar_string("mp_round_infinite", g_iCvarRoundEnd, charsmax(g_iCvarRoundEnd));
		set_cvar_num("mp_round_infinite", 1);
		
		jbe_Status_CustomSpawns(true);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!is_user_connected(i) || !jbe_is_user_alive(i)) continue;

			rg_reset_maxspeed(i);
			rg_remove_all_items(i);
			rg_give_item(i, "weapon_knife", GT_APPEND);
			
			
			g_iUserLvl[i] = 0;
			g_iUserKilled[i] = 0;
			
			//set_entvar(i, var_health, SPAWN_HEALTH);
			
			//rg_give_item_ex(i, g_iData_Wpn[g_iUserLvl[i]][1], GT_REPLACE, WEAPON_BPAMMO);
			
			rg_round_respawn(i);
		}
		
		g_iTimeVote = TIME_TO_VOTE;
		set_task(1.0, "Timer_Handler", TASK_OFFSET, _, _, "a", TIME_TO_VOTE);
		
		
	}
}

public Task_Timer()
{
	set_hudmessage(
		255, 
		255, 
		255, 
		
		-1.0, 
		0.2, 
		
		0, 0.0, 1.1, 0.2, 0.2, -1
	);
	
	if(g_iLeaderId && is_user_connected(g_iLeaderId))
	{
	
		ShowSyncHudMsg
		(
		0, g_iSyncStatusText, "\
		ЛИДЕР^n%n (Ур: %d)^n%s",
		g_iLeaderId, g_iUserLvl[g_iLeaderId], g_iData_Wpn[g_iUserLvl[g_iLeaderId]][0]
		);	
	}
	else
	{
		ShowSyncHudMsg
		(
		0, g_iSyncStatusText, "\
		ЛИДЕР^nЕЩЕ НЕ ПОЯВИЛСЯ"
		);
	}
	
	static iPlayers[MAX_PLAYERS], iPlayerCount, pIde;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots | GetPlayers_ExcludeDead);
	
	set_hudmessage(
		255, 
		255, 
		255, 
		
		0.00, 
		0.35, 
		
		0, 0.0, 1.1, 0.2, 0.2, -1
	);
	
	for(new i; i < iPlayerCount; i++)
	{
		pIde = iPlayers[i];
		
		
		ShowSyncHudMsg
		(
		pIde, g_iUserStatusText, "\
		%s^n\
		-> %s <-^n\
		%s^n^nОсталось убийств: %d\
		",
		g_iUserLvl[pIde] > 0 ? g_iData_Wpn[g_iUserLvl[pIde] - 1][0] : "", 
		g_iData_Wpn[g_iUserLvl[pIde]][0],
		g_iUserLvl[pIde] < g_iMaxLevel ? g_iData_Wpn[g_iUserLvl[pIde]  + 1][0] : "",
		KILLED_FRAG - g_iUserKilled[pIde]
		);
	
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam)
{
	if(iDayMode == g_iDayModeGunGame)
	{
		g_bGame = false;
		g_iPreStartGG = false;
		
		remove_task(TASK_HUDINFO);
		
		state dBlockCmd: Disabled;
		DisableHookChain(HookPlayer_Spawn);
		DisableHookChain(HookPlayer_Killed);
		DisableHookChain(HookPlayer_TraceAttack);
		DisableHookChain(HookPlayer_DropPlayerItem);
		DisableHookChain(HookPlayer_DeadPlayerWeapons);
		//DisableHookChain(HookPlayer_HcRoundEnd);
		
		set_cvar_string("mp_round_infinite", "abeg");
		jbe_set_friendlyfire(0);
		
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i)) continue;
			
			g_iUserLvl[i] = 0;
			g_iUserKilled[i] = 0;
			
			rg_remove_all_items(i);
		}
		
		if(!g_iEndFackRound)
		{
			rg_round_end(.tmDelay = 10.0, .st = WINSTATUS_TERRORISTS, .message = "Игра закончена!");
		}
		
		if(is_user_connected(g_iLeaderId))
		{
			set_hudmessage(
			255, 
			255, 
			255, 
			
			-1.0, 
			0.2, 
			
			0, 0.0, 0.1, 7.0, 0.2, -1
			);
			ShowSyncHudMsg
			(
			0, g_iSyncStatusText, "Победил игрок: %n^nПриз %d бычков^n^nЗавершение через 7 секунд" , g_iLeaderId, WIN_MONEY
			);	
			
			if(get_login(g_iLeaderId))
			{
				jbe_set_butt(g_iLeaderId, jbe_get_butt(g_iLeaderId) + WIN_MONEY);
				//jbe_mysql_set_exp(g_iLeaderId, jbe_get_user_team(g_iLeaderId) ,jbe_mysql_get_exp(g_iLeaderId, 1) + WIN_EXP);
				
				//jbe_exp_give_type(g_iLeaderId);
			}
			else
			{
					UTIL_SayText(0, "!g* !yИгрок !g%n !yничего не получил, т.к. не авторизован", g_iLeaderId);
			}
		}
		
		
		
		client_cmd(0 , "spk jb_engine/bell.wav");
		
		
	}
}

public Timer_Handler()
{
	if(--g_iTimeVote)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.22, 0, 0.0, 0.8, 0.2, 0.2, -1);
		ShowSyncHudMsg
		(
			0, g_iSyncStatusText, "До начало игры %d секунд^n^nПодсказка:^nУбив с ножа вы крадёте уровень жертвы" , g_iTimeVote
		);
	}
	else
	{
		g_iPreStartGG = true;
		set_task(1.0, "Task_Timer", TASK_HUDINFO, _, _, "b");
		
		client_cmd(0 , "spk jb_engine/bell.wav");
	}
}

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(!g_bGame)
		return HC_CONTINUE;
	
	rg_remove_all_items(pId);
	if(g_iUserLvl[pId] != g_iMaxLevel) 
	{
		rg_give_item(pId, "weapon_knife");
		rg_give_item_ex(pId, g_iData_Wpn[g_iUserLvl[pId]][1], GT_REPLACE, WEAPON_BPAMMO);
	}
	else
	{
		rg_give_item_ex(pId, g_iData_Wpn[g_iUserLvl[pId]][1], GT_REPLACE);
	}
	set_entvar(pId, var_health, SPAWN_HEALTH);
	jbe_set_user_model_ex(pId, 1);
	#if defined DEBUG
	server_print("У вас %s", g_iData_Wpn[g_iUserLvl[pId]][0])
	#endif
	
	return HC_CONTINUE;
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		if(!g_iPreStartGG)
		{
			SetHookChainArg(3, ATYPE_FLOAT, 0.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	set_task(TIME_TO_RESPAWN.0, "jbe_respawn_player", iVictim + TASK_SPAWN);
	
	if(!jbe_is_user_valid(iKiller))
		return HC_CONTINUE;	
	if(is_user_connected(iVictim))
		rg_send_bartime(iVictim, TIME_TO_RESPAWN, false);
	
	if(iVictim == iKiller || !g_iPreStartGG)
		return HC_CONTINUE;
	
	g_iUserKilled[iKiller]++;
	rg_instant_reload_weapons(iKiller, 0);
	client_cmd(iKiller, "spk fvox/bell.wav");

	
	if(g_iUserKilled[iKiller] >= KILLED_FRAG && g_iUserLvl[iKiller] < g_iMaxLevel)
	{
		g_iUserLvl[iKiller]++;
		g_iUserKilled[iKiller] = 0;
		Effects_one(iKiller);
		
		calculationleader(iKiller);
		
		rg_remove_all_items(iKiller);
		if(g_iUserLvl[iKiller] != g_iMaxLevel) 
		{
			rg_give_item(iKiller, "weapon_knife");
			rg_give_item_ex(iKiller, g_iData_Wpn[g_iUserLvl[iKiller]][1], GT_REPLACE, WEAPON_BPAMMO);
		}
		else 
		{
			rg_give_item_ex(iKiller, g_iData_Wpn[g_iUserLvl[iKiller]][1], GT_REPLACE);
		}
		
		set_entvar(iKiller, var_health, SPAWN_HEALTH);
	}
	
	static iInflictor;
	get_death_reason(iVictim, iKiller, iInflictor);
	
	
	if(g_iUserLvl[iKiller] == g_iMaxLevel && g_iUserKilled[iKiller] >= KILLED_FRAG && iInflictor == GRENADE)
	{
		#if defined DEBUG
		server_print("Убил всех с гранатой")
		#endif
		
		rg_round_end(.tmDelay = 7.0, .st = WINSTATUS_TERRORISTS, .message = "Игра окончено");
		g_iEndFackRound = true;
		g_iLeaderId = iKiller;
	}
	
	
	
	if(iInflictor == KNIFE)
	{
		if(g_iUserLvl[iKiller] != g_iMaxLevel)
		{
			g_iUserLvl[iKiller]++;
			g_iUserKilled[iKiller] = 0;
			Effects_one(iKiller);
			set_entvar(iKiller, var_health, SPAWN_HEALTH);
		}
		calculationleader(iKiller);
		
		rg_remove_all_items(iKiller);
		if(g_iUserLvl[iKiller] != g_iMaxLevel) 
		{
			rg_give_item(iKiller, "weapon_knife");
			rg_give_item_ex(iKiller, g_iData_Wpn[g_iUserLvl[iKiller]][1], GT_REPLACE, WEAPON_BPAMMO);
		}
		else
		{
			rg_give_item_ex(iKiller, g_iData_Wpn[g_iUserLvl[iKiller]][1], GT_REPLACE);
		}
		
		if(g_iUserLvl[iVictim] > 0) g_iUserLvl[iVictim]--;
		g_iUserKilled[iVictim] = 0;
		
		#if defined DEBUG
		server_print("Своровал с ножа")
		#endif
	}
	
	
	
	#if defined DEBUG
	server_print("Data: LvlUserKiller: %d | LvlFragKiller: %d LvlUserVictim: %d | LvlFragVictim: %d | MAXUSERKILLER: %d | MAXUSERFRAG: %d", 
	g_iUserLvl[iKiller], g_iUserKilled[iKiller], g_iUserLvl[iVictim], g_iUserKilled[iVictim], g_iMaxLevel, KILLED_FRAG);
	#endif
	
	return HC_CONTINUE;
}

public client_disconnected(id)
{
	if(g_bGame)
	{
		g_iUserLvl[id] = 0;
		g_iUserKilled[id] = 0;
	}
}

public client_putinserver(id)
{
	if(g_bGame)
	{
		g_iUserLvl[id] = 0;
		g_iUserKilled[id] = 0;
		
		
		set_task(TIMEPUTIN_TO_RESPAWN.0, "jbe_respawn_player", id + TASK_SPAWN);
		rg_send_bartime(id, TIMEPUTIN_TO_RESPAWN, false);
	}
}

public jbe_respawn_player(pId)
{
	pId -= TASK_SPAWN;
	
	if(jbe_is_user_alive(pId)) return;
	
	if(!is_user_connected(pId)) return;
	
	rg_round_respawn(pId);
}

public EventAmmoX(id)
{
	if(g_bGame)
	{
		
		if(g_iUserLvl[id] == g_iMaxLevel)
		{
			new iAmount = read_data(2);
			
			if(iAmount > 0)
			{
				remove_task(id + TASK_GIVEGRENADE_ID);
				return;
			}
			
			set_task(GIVE_HEGRANADE_TIME.0, "GiveGrenade", id + TASK_GIVEGRENADE_ID);
			
			rg_send_bartime(id, GIVE_HEGRANADE_TIME, false);
		}
	}
}


public GiveGrenade(id)
{
	remove_task(id);
	id -= TASK_GIVEGRENADE_ID;
	
	if(jbe_is_user_alive(id) && g_bGame)
	{
		//rg_remove_all_items(id);
		rg_remove_all_items(id);
		rg_give_item(id, "weapon_hegrenade", GT_REPLACE);
	}
}
public calculationleader(iKiller)
{
	//if(iKiller == g_iLeaderId)
	//	return;
	if(jbe_is_user_connected(g_iLeaderId))
	{
	
		if(g_iUserLvl[iKiller] < g_iUserLvl[g_iLeaderId]) 
			return;
	}
	
	g_iLeaderId = 0;
	g_iLeaderLevel = 0;

	new iTempPlayerLevel;

	for(new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_connected(id)) continue;
		
		iTempPlayerLevel = g_iUserLvl[id];
		if(iTempPlayerLevel == START_LEVEL) continue;
		
		if(iTempPlayerLevel > g_iLeaderLevel)
		{
			g_iLeaderLevel = iTempPlayerLevel;
			g_iLeaderId = id;
		}
	}
	

}


get_death_reason(const id, const pevAttacker, &iType)
{
	new iInflictor = get_entvar(id, var_dmg_inflictor);
	
	if( iInflictor == pevAttacker )
	{
		new iWpnId = get_member(get_member(pevAttacker, m_pActiveItem), m_iId);

		if(iWpnId == CSW_KNIFE) iType = KNIFE;
		else iType = BULLET;
	}
	else
	{
		if(get_member(id, m_bKilledByGrenade)) iType = GRENADE;
		else  iType = WORLD;
	}
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}
#if defined ENEMY_INFO
public msg_TeamInfo(id, dest, player)
{
	if(g_bGame)
	{
		new teamName[2];
		get_msg_arg_string(2, teamName, charsmax(teamName));

		new playerId = get_msg_arg_int(1);
		
		if (!(teamName[0] == 'T' || teamName[0] == 'C'))
			return PLUGIN_CONTINUE;
		
		if (dest == MSG_ONE)
		{
			SendTeamInfo(player, playerId, player == playerId ? "CT" : "TERRORIST");
		}
		else
		{
			new TeamName:teamNum;

			for (new i = 1; i <= MaxClients; i++)
			{
				if (!jbe_is_user_connected(i))
					continue;

				teamNum = get_member(i, m_iTeam);

				if (!(teamNum == TEAM_TERRORIST || teamNum == TEAM_CT))
					continue;


				SendTeamInfo(i, playerId, i == playerId ? "CT" : "TERRORIST");
			}
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
#endif
SendTeamInfo(id, playerId, teamName[])
{
	message_begin(MSG_ONE, g_iMsgTeamInfo, _, id);
	write_byte(playerId);
	write_string(teamName);
	message_end();
}



stock Effects_one(pId)
{
	if(!is_user_connected(pId)) return 0;
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0,0,0}, pId);
	write_short(1<<12);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(0);
	write_byte(125);
	write_byte(0);
	write_byte(50);
	message_end();
	return 0;
}


