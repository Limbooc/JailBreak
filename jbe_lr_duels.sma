#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>


native jbe_set_butt(p,ps);
native jbe_get_butt(p);


//#define DEBUG
#define BEAMDUELS


#define THIBKBEAM   0.3
#define BEAMLIFE 	3



#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define PLAYERS_PER_PAGE 8
#define linux_diff_player 5



#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

native jbe_hide_user_costumes(pTarget)


//#define PL_BET_MENU

new g_iUserDuels;

forward jbe_lr_duels()

new g_iCountDownLastPR;

new const g_szSound[][] =
{
	"sound/fvox/one.wav", "sound/fvox/two.wav", "sound/fvox/three.wav", "sound/fvox/four.wav", "sound/fvox/five.wav"
};

new iEnt;

new g_iUserQuestDuels[MAX_PLAYERS + 1]

new g_iDuelStatus,
	g_iDuelType,
	g_iAllCvars[2],
	g_iDuelUsersId[2],
	g_iDuelTimeToKill;
	
new g_iFriendPrise,
	g_iFriendPlayers;
	
new g_iSyncDuelInformer
	
/* -> Битсуммы, переменные и массивы для работы с дуэлями -> */
new g_iDuelNames[2][32], 
	g_iDuelCountDown, 
	g_iDuelTimerAttack;
	
new Float:fDuelOriginPrison[3];
new Float:fDuelOriginGuard[3];
	
//new g_pSpriteBeam;
	
	
new const g_iDuelLang[][] =
{
	"",
	"JBE_ALL_HUD_DUEL_DEAGLE",
	"JBE_ALL_HUD_DUEL_M3",
	"JBE_ALL_HUD_DUEL_HEGRENADE",
	"JBE_ALL_HUD_DUEL_M249",
	"JBE_ALL_HUD_DUEL_AWP",
	"JBE_ALL_HUD_DUEL_KNIFE",
	"JBE_ALL_HUD_DUEL_GOLDAK"
};
	
/* -> Массивы для работы с событиями 'hamsandwich' -> */
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
	"func_button", // Кнопка
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};
new HamHook:g_iHamHookForwards[14],
	HamHook:g_iHamHookAttack;
	
#define MsgId_SayText 76
	
/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1]
	//g_iMenuTarget[MAX_PLAYERS + 1];

enum _:(+= 100)
{
	TASK_DUEL_COUNT_DOWN  = 264567,
	TASK_DUEL_TIMER_ATTACK,
	TASK_DUEL_TIME_TO_KILL,
	TASK_SHOW_INFORMER,
	TASK_DUEL_LAST_PRISONER
}

#if defined PL_BET_MENU

#define PL_CHAT_PREFIX						"!t[!gСТАВКИ!t]!y"
#define PL_MENU_PREFIX						"\d[JBE]"

new g_iBetStatus[33], 
	g_iBetCost[33], 
	g_iBetPlayer[33];

//new bool:g_is_voice_simon;
new g_iMaxBetCost[] = {
	50, 
	100, 
	200, 
	300, 
	400, 
	500, 
	1000, 
	2000, 
	3000
};
#endif

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

native jbe_restartgame()
native jbe_aliveplayersnum(iType)
native jbe_daymodelistsize()
native jbe_show_mainmenu(id)
native jbe_is_user_boxing(id)
native jbe_blockedguardmenu(id)
native jbe_set_user_gold(pId, iType)
native jbe_get_syncinf_1()

native jbe_mysql_stats_systems_add(pPlayer, Type, gResult);
native jbe_mysql_stats_systems_get(pPlayer, Type);
native get_login(pPlayer);
native jbe_playersnum(iType);

new g_iLastPnId,
	g_iBitUserDuel;

new HookChain:HookPlayer_TakeDamage, 
	HookChain:HookPlayer_TraceAttack, 
	HookChain:HookPlayer_Killed;
	


public plugin_init()
{
	register_plugin("[JBE] JailDuels API", "1.0", "DalgaPups");

	DisableHookChain(HookPlayer_TakeDamage = 	RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Player", false));
	DisableHookChain(HookPlayer_TraceAttack = 	RegisterHookChain(RG_CBasePlayer_TraceAttack,		"HC_CBasePlayer_TraceAttack_Player", false));
	DisableHookChain(HookPlayer_Killed = 		RegisterHookChain(RG_CBasePlayer_Killed, 			"HC_CBasePlayer_PlayerKilled_Post", true));
	
	register_menucmd(register_menuid("Show_LastPrisonerMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_LastPrisonerMenu");
	register_menucmd(register_menuid("Show_ChoiceDuelMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9), "Handle_ChoiceDuelMenu");
	register_menucmd(register_menuid("Show_DuelUsersMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_DuelUsersMenu");
	register_menucmd(register_menuid("Show_DuelOptions"), (1<<0|1<<1|1<<2|1<<9), "Handle_DuelOptions");
	register_menucmd(register_menuid("Show_FriendsDuelsMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_FriendsDuelsMenu");
	register_menucmd(register_menuid("Show_FriendsDuelUsersMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_FriendsDuelUsersMenu");

	
	register_cvar("jbe_last_prisoner_money" , "15");
	register_cvar("jbe_last_prisoner_money_friends" , "25");
	for(new i; i <= 8; i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	new const g_szWeaponName[][] = 
	{
		"weapon_p228", "weapon_scout", "weapon_hegrenade", 
		"weapon_xm1014", "weapon_c4", "weapon_mac10", 
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", 
		"weapon_fiveseven", "weapon_ump45", "weapon_sg550", 
		"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", 
		"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", 
		"weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", 
		"weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"
	};
	for(new i; i < sizeof(g_szWeaponName); i++) 
	{
		g_iHamHookAttack = RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponName[i], "Ham_ItemPrimaryAttack_Post", true);
	}
	DisableHamForward(g_iHamHookAttack);
	
	RegisterHam(Ham_Weapon_SecondaryAttack , "weapon_awp", "Ham_ItemPSecondaryAttack");

	g_iSyncDuelInformer = CreateHudSyncObj();
	
	g_iAllCvars[0] = get_cvar_num("jbe_last_prisoner_money");
	g_iAllCvars[1] = get_cvar_num("jbe_last_prisoner_money_friends");
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	//register_clcmd("say /lr", "ClCmd_lrmenu");
	//register_clcmd("say_team /lr", "ClCmd_lrmenu");

#if defined PL_BET_MENU
	register_menucmd(register_menuid("Show_BetMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_BetMenu");
#endif
#if defined DEBUG
	//register_clcmd("say /duel", "ClCmd_duel");
	//register_clcmd("say /tp", "ClCmd_tp");
#endif
}



public jbe_set_user_godmode(pId, bType) set_entvar( pId, var_takedamage, !bType ? DAMAGE_YES : DAMAGE_NO );
public bool: jbe_get_user_godmode(pId) return bool:( get_entvar(pId, var_takedamage) == DAMAGE_NO );


public ClCmd_lrmenu(pId)
{
	if(pId != g_iLastPnId && jbe_aliveplayersnum(1) == 1 && jbe_is_user_alive(pId) && jbe_get_user_team(pId) == 1)
	{
		g_iLastPnId = pId;
		Show_LastPrisonerMenu(pId);
	}
	else 
	if(pId != g_iLastPnId && jbe_get_user_team(pId) == 1)
	{
		UTIL_SayText(pId, "!g* !yВы не последний заключенный");
	}
	if(pId == g_iLastPnId && jbe_is_user_alive(pId)) Show_LastPrisonerMenu(pId);
	//return PLUGIN_CONTINUE;
}


public HC_CBasePlayer_TakeDamage_Player(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		//if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iAttacker) && IsNotSetBit(g_iBitUserDuel, iVictim) && jbe_is_user_valid(iAttacker))
		if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iVictim) && !jbe_is_user_valid(iAttacker))
		{
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}
		if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iAttacker) && IsNotSetBit(g_iBitUserDuel, iVictim) && jbe_is_user_valid(iAttacker))
		{
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}
		/*if(iBitDamage & (1<<24))
		{
			if(IsSetBit(g_iBitUserDuel, iVictim) || IsSetBit(g_iBitUserDuel, iAttacker))
			{
				if(IsSetBit(g_iBitUserDuel, iVictim) && IsSetBit(g_iBitUserDuel, iAttacker)) 
				{
					return HC_CONTINUE;
				}
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE;
			}
		}*/
	}
	return HC_CONTINUE;
}


public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{

	if(jbe_is_user_valid(iAttacker))
	{
		if(g_iDuelStatus == 1 && IsSetBit(g_iBitUserDuel, iVictim)) 
		{
			SetHookChainArg(3, ATYPE_FLOAT, 0.0);
			return HC_SUPERCEDE;
		}
		if(g_iDuelStatus == 2)
		{
			if(IsSetBit(g_iBitUserDuel, iVictim) || IsSetBit(g_iBitUserDuel, iAttacker))
			{
				if(IsSetBit(g_iBitUserDuel, iVictim) && IsSetBit(g_iBitUserDuel, iAttacker)) 
				{
					return HC_CONTINUE;
				}
				SetHookChainArg(3, ATYPE_FLOAT, 0.0);
				return HC_SUPERCEDE;
			}
		}
	}

	return HC_CONTINUE;
}



public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	//if(!is_user_alive(iVictim)) return;
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iVictim)) 
		{
			jbe_duel_ended(iVictim);
			if(jbe_get_user_team(iVictim) == 1) g_iLastPnId = 0;
		}
	}
}



public plugin_natives()
{
	register_native("jbe_is_user_lastid", "jbe_is_user_lastid", 1);
	register_native("jbe_show_lastmenu", "jbe_show_lastmenu", 1);
	register_native("jbe_is_user_duel", "jbe_is_user_duel", 1);
	register_native("jbe_iduel_status", "jbe_iduel_status", 1);
	register_native("jbe_duel_ended", "jbe_duel_ended" , 1);
	register_native("jbe_duel_show_tp_menu", "jbe_duel_show_tp_menu" , 1);
	register_native("jbe_get_user_lr_quest", "jbe_get_user_lr_quest");
}

public jbe_get_user_lr_quest(pId) return g_iUserQuestDuels[pId];

public jbe_duel_show_tp_menu(pId) return Show_DuelOptions(pId);

public plugin_precache()
{
	//g_pSpriteBeam = engfunc(EngFunc_PrecacheModel, "sprites/333.spr");
	//engfunc(EngFunc_PrecacheGeneric, "sound/jb_engine/duel/duel_ready.mp3");
	files_precache();
}

files_precache()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
	new szMapName[64];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/duels/%s.ini", szCfgDir, szMapName);
	
	switch(file_exists(szCfgFile)) 
	{
		case 1: 
		{
			new iFile = fopen(szCfgFile, "rt");
			
			new sStringBuf[512];
			new GetFloatString[3][64], GetString[2][64];
			
			while(!feof(iFile)) 
			{
				fgets(iFile, sStringBuf, charsmax(sStringBuf));
				
				if(sStringBuf[0] && sStringBuf[0] != ';' && parse(sStringBuf, GetString[0], charsmax(GetString[]), GetString[1], charsmax(GetString[]))) {
					parse(GetString[0], GetFloatString[0], charsmax(GetFloatString[]), GetFloatString[1], charsmax(GetFloatString[]), GetFloatString[2], charsmax(GetFloatString[]));
					
					fDuelOriginPrison[0] = str_to_float(GetFloatString[0]);
					fDuelOriginPrison[1] = str_to_float(GetFloatString[1]);
					fDuelOriginPrison[2] = str_to_float(GetFloatString[2]);
					
					parse(GetString[1], GetFloatString[0], charsmax(GetFloatString[]), GetFloatString[1], charsmax(GetFloatString[]), GetFloatString[2], charsmax(GetFloatString[]));
					
					fDuelOriginGuard[0] = str_to_float(GetFloatString[0]);
					fDuelOriginGuard[1] = str_to_float(GetFloatString[1]);
					fDuelOriginGuard[2] = str_to_float(GetFloatString[2]);
				}
			}
		}
		default: 
		{
			for(new i = 0; i < 3; i++) fDuelOriginPrison[i] = 0.0;
			for(new i = 0; i < 3; i++) fDuelOriginGuard[i] = 0.0;
			
			log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		}
	}
}



public jbe_iduel_status() return g_iDuelStatus;
public jbe_is_user_duel(id) return IsSetBit(g_iBitUserDuel, id);
public jbe_show_lastmenu(pId) return Show_LastPrisonerMenu(pId);
public jbe_is_user_lastid() return g_iLastPnId;


#if defined DEBUG
public ClCmd_duel(id)
{
	g_iLastPnId = id;
}

public ClCmd_tp(id) return Show_DuelOptions(id);
#endif

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iLastPnId = 0;
}

public LogEvent_RoundEndTask()
{
	if(jbe_get_day_week() != 3)
	{
		if(g_iDuelStatus)
		{
			g_iBitUserDuel = 0;
			if(task_exists(TASK_DUEL_COUNT_DOWN))
			{
				remove_task(TASK_DUEL_COUNT_DOWN);
				client_cmd(0, "mp3 stop");
			}
		}
		
	}
}



public HamHook_EntityBlock(iEntity, pId)
{
	if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, pId)) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}


public client_disconnected(pId)
{
	if(!is_user_connected(pId)) return;

	if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, pId)) jbe_duel_ended(pId);
	
	
	//if(!get_login(pId))g_iUserQuestDuels[pId] = 0;
	
}

Show_LastPrisonerMenu(pId)
{
	if(g_iDuelStatus || !jbe_is_user_alive(pId) || pId != g_iLastPnId) return PLUGIN_HANDLED;

	g_iFriendPrise = 0;
	g_iFriendPlayers = 0;

	new szMenu[512],  iLen, iKeys = (1<<8|1<<9);
	FormatMain("\y%L^n^n", pId, "JBE_MENU_LAST_PRISONER_TITLE");
	
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_FREE_DAY"), iKeys |= 1<<0;
	if(jbe_playersnum(1) >= 3) FormatItem("\y2. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[0]), iKeys |= 1<<1;
	else FormatItem("\y2. \d%L \r[Мало зека]^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[0]);
	FormatItem("\y3. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_VOICE"), iKeys |= 1<<2;
	FormatItem("\y4. \w%L^n", pId, "JBE_MENU_LAST_TAKE_WEAPONS"), iKeys |= 1<<3;
	FormatItem("\y5. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_CHOICE_DUEL"), iKeys |= 1<<4;
	FormatItem("\y6. \wВыйграть дуэль другу^n^n^n^n"), iKeys |= 1<<5;

	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_LastPrisonerMenu");
}

public Handle_LastPrisonerMenu(pId, iKey)
{
	if(g_iDuelStatus || !jbe_is_user_alive(pId) || pId != g_iLastPnId) return PLUGIN_HANDLED;
	
	if(jbe_aliveplayersnum(2) == 0)
	{
		CenterMsgFix_PrintMsg( 0, print_center, "Нет охраны для выполнение действий!" );
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 0:
		{
			rg_round_end(.tmDelay = 2.5, .st = WINSTATUS_TERRORISTS, .message = "Последний зек взял фд!");
			jbe_add_user_free_next_round(pId);
			g_iLastPnId = 0;
			if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
			
		}
		case 1:
		{
			rg_round_end(.tmDelay = 2.5, .st = WINSTATUS_TERRORISTS, .message = "Последний зек взял бычки");
			//jbe_set_user_money(pId, jbe_get_user_money(pId) + g_iAllCvars, 1);
			jbe_set_butt(pId, jbe_get_butt(pId) + g_iAllCvars[0]);
			g_iLastPnId = 0;
			if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
		}
		case 2:
		{
			rg_round_end(.tmDelay = 2.5, .st = WINSTATUS_TERRORISTS, .message = "Последний зек взял голос");
			jbe_set_user_voice_next_round(pId);
			g_iLastPnId = 0;
			if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
		}
		case 3:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 2) continue;
				rg_remove_all_items(i);
			}
			rg_give_item_ex(pId,"weapon_ak47", GT_REPLACE, 200);
			set_entvar(pId, var_takedamage, DAMAGE_NO);
			g_iLastPnId = 0;
			CenterMsgFix_PrintMsg( 0, print_center, "Последний зек хочет убить всю охрану" );
			if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
		}
		case 4: 
		{
			CenterMsgFix_PrintMsg( 0, print_center, "Последний зек выбирает дуэль" );
			return Show_ChoiceDuelMenu(pId);
		}
		case 5: 
		{
			CenterMsgFix_PrintMsg( 0, print_center, "Последний зек выбирает дуэль другу" );
			return Cmd_FriendsDuelUsersMenu(pId);
		}
		case 8: return jbe_show_mainmenu(pId)
	}
	return PLUGIN_HANDLED;
}

Cmd_FriendsDuelUsersMenu(pId) return Show_FriendsDuelUsersMenu(pId, g_iMenuPosition[pId] = 0);
Show_FriendsDuelUsersMenu(pId, iPos)
{
	if(iPos < 0 || pId != g_iLastPnId || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 ) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_LastPrisonerMenu(pId);
		}
		default: FormatMain("\yВыберите друга \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		if(i == pId)
		{
			FormatItem("\y%d. \y%s (Вы)^n", ++b, szName);
		}
		else
		FormatItem("\y%d. \w%s^n", ++b, szName);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_FriendsDuelUsersMenu");
}


public Handle_FriendsDuelUsersMenu(pId, iKey)
{
	if(pId != g_iLastPnId || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: Show_FriendsDuelUsersMenu(pId, ++g_iMenuPosition[pId]);
		case 9: Show_FriendsDuelUsersMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			g_iFriendPlayers = iTarget;
			return Show_FriendsDuelsMenu(pId);
		}
	}
	return PLUGIN_HANDLED;
}

Show_FriendsDuelsMenu(pId)
{
	if(g_iDuelStatus || !jbe_is_user_alive(pId) || pId != g_iLastPnId) return PLUGIN_HANDLED;
	
	new szMenu[512],  iLen, iKeys = (1<<8|1<<9);
	FormatMain("\yВыберите приз для друга^n^n");
	
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_FREE_DAY"), iKeys |= 1<<0;
	if(g_iFriendPlayers == pId)
	{
		if(jbe_playersnum(1) >= 3) FormatItem("\y2. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[0]), iKeys |= 1<<1;
		else FormatItem("\y2. \d%L \r[Мало зека]^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[0]), iKeys |= 1<<2;
	}
	else
	{
		if(jbe_playersnum(1) >= 3) FormatItem("\y2. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[1]), iKeys |= 1<<1;
		else FormatItem("\y2. \d%L \r[Мало зека]^n", pId, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[1]), iKeys |= 1<<2;
	}
	FormatItem("\y3. \w%L^n", pId, "JBE_MENU_LAST_PRISONER_VOICE"), iKeys |= 1<<3;
	

	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_FriendsDuelsMenu");
}

public Handle_FriendsDuelsMenu(pId, iKey)
{

	if(!jbe_is_user_connected(g_iFriendPlayers))
	{
		UTIL_SayText(pId, "!g* !yИгрок отключился, выберите другого!");
		return Show_LastPrisonerMenu(pId)
	}
	
	switch(iKey)
	{
		case 0:
		{
			if(g_iFriendPlayers == pId)
			{
				UTIL_SayText(0, "!g * !yдуэлянт играет на ФД себе");
			}
			else UTIL_SayText(0, "!g * !yдуэлянт играет другу !g%n !yна ФД", g_iFriendPlayers);
			g_iFriendPrise = 1;
		}
		case 1:
		{
			if(g_iFriendPlayers == pId)
			{
				UTIL_SayText(0, "!g * !yдуэлянт играет на деньги себе");
			}
			else UTIL_SayText(0, "!g * !yдуэлянт играет другу !g !yна деньги", g_iFriendPlayers);
			g_iFriendPrise = 2;
		}
		case 2:
		{
			if(g_iFriendPlayers == pId)
			{
				UTIL_SayText(0, "!g * !yдуэлянт играет на голос себе");
			}
			else UTIL_SayText(0, "!g * !yдуэлянт играет другу !g !yна голос", g_iFriendPlayers);
			g_iFriendPrise = 3
			
		}
		case 8: return Show_LastPrisonerMenu(pId)
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ChoiceDuelMenu(pId);
}

public Show_DuelOptions(id) 
{
	new szMenu[512],  iLen;
	
	FormatMain("\yНастройки дуэли^n^n");
	
	FormatItem("\y1. \rСохранить настройки^n^n");
	FormatItem("\y2. \wУстановить координаты \r[заключенные]^n");
	FormatItem("\y3. \wУстановить координаты \r[охрана]^n^n");
	
	FormatItem("\y0. \wВыход");
	
	return show_menu(id, (1<<0|1<<1|1<<2|1<<9), szMenu, -1, "Show_DuelOptions");
}

public Handle_DuelOptions(id, i_Key)
{
	switch(i_Key) 
	{
		case 0: 
		{
			new szCfgDir[64], szCfgFile[128];
			get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
			new szMapName[64];
			get_mapname(szMapName, charsmax(szMapName));
			
			formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/duels/%s.ini", szCfgDir, szMapName);
			
			if(file_exists(szCfgFile)) delete_file(szCfgFile);
			
			new szString[512];
			
			format(szString, charsmax(szString), "^"%f %f %f^" ^"%f %f %f^"", fDuelOriginPrison[0], fDuelOriginPrison[1], fDuelOriginPrison[2], fDuelOriginGuard[0], fDuelOriginGuard[1], fDuelOriginGuard[2]);
			write_file(szCfgFile, szString, -1);
		}
		case 1: 
		{
			get_entvar(id, var_origin, fDuelOriginPrison);
			UTIL_SayText(id, "%L Координаты для !t[заключённых]!y установлены!", LANG_PLAYER, "JBE_PREFIX_CHAT");
		}
		case 2:
		{
			get_entvar(id, var_origin, fDuelOriginGuard);
			UTIL_SayText(id, "%L Координаты для !t[охраны]!y установлены!", LANG_PLAYER, "JBE_PREFIX_CHAT");
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_DuelOptions(id);
}

Show_ChoiceDuelMenu(pId)
{
	if(!jbe_is_user_alive(pId) || pId != g_iLastPnId) return PLUGIN_HANDLED;
	
	new szMenu[512],  iLen;
	FormatMain("\y%L^n^n", pId, "JBE_MENU_CHOICE_DUEL_TITLE");
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_DEAGLE");
	FormatItem("\y2. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_M3");
	FormatItem("\y3. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_HEGRENADE");
	FormatItem("\y4. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_M249");
	FormatItem("\y5. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_AWP");
	FormatItem("\y6. \w%L^n", pId, "JBE_MENU_CHOICE_DUEL_KNIFE");
	FormatItem("\y7. \w%L^n^n", pId, "JBE_MENU_CHOICE_DUEL_GOLDAK47");
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9), szMenu, -1, "Show_ChoiceDuelMenu");
}

public Handle_ChoiceDuelMenu(pId, iKey)
{
	if(!jbe_is_user_alive(pId) || pId != g_iLastPnId) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			UTIL_SayText(0, "!g * !yДуалянт !g%n !yвыбрал на !gПистолетах", pId);
			g_iDuelType = 1;
			return Cmd_DuelUsersMenu(pId);
		}
		case 1:
		{
			UTIL_SayText(0, "!g * !yДуалянт !g%n !yвыбрал на !gДробовиках", pId);
			g_iDuelType = 2;
			return Cmd_DuelUsersMenu(pId);
		}
		case 2:
		{
			UTIL_SayText(0, "!g * !yДуалянт !g%n !yвыбрал на !gГранатаз", pId);
			g_iDuelType = 3;
			return Cmd_DuelUsersMenu(pId);
		}
		case 3:
		{
			UTIL_SayText(0, "!g* !yДуалянт !g%n !yвыбрал на !gПулиметах", pId);
			g_iDuelType = 4;
			return Cmd_DuelUsersMenu(pId);
		}
		case 4:
		{
			UTIL_SayText(0, "!g * !yДуалянт !g%n !yвыбрал на !gАвп", pId);
			g_iDuelType = 5;
			return Cmd_DuelUsersMenu(pId);
		}
		case 5:
		{
			UTIL_SayText(0, "!g * !yДуалянт !g%n !yвыбрал на !gНожах", pId);
			g_iDuelType = 6;
			return Cmd_DuelUsersMenu(pId);
		}
		case 6:
		{
			g_iDuelType = 7;
			return Cmd_DuelUsersMenu(pId);
		}
		case 8: return Show_LastPrisonerMenu(pId);
	}
	return PLUGIN_HANDLED;
}

Cmd_DuelUsersMenu(pId) return Show_DuelUsersMenu(pId, g_iMenuPosition[pId] = 0);
Show_DuelUsersMenu(pId, iPos)
{
	if(iPos < 0 || pId != g_iLastPnId || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 2 || !jbe_is_user_alive(i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_LastPrisonerMenu(pId);
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_DUEL_USERS", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		FormatItem("\y%d. \w%s^n", ++b, szName);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_DuelUsersMenu");
}

public Handle_DuelUsersMenu(pId, iKey)
{
	if(pId != g_iLastPnId || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: Show_DuelUsersMenu(pId, ++g_iMenuPosition[pId]);
		case 9: Show_DuelUsersMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(jbe_is_user_alive(iTarget)) jbe_duel_start_ready(pId, iTarget);
			else Show_DuelUsersMenu(pId, g_iMenuPosition[pId]);
		}
	}
	return PLUGIN_HANDLED;
}

#if defined PL_BET_MENU
Show_BetMenu(client) 
{	
	if(!g_iDuelStatus || !jbe_is_user_alive(client) || jbe_get_user_team(client) != 1) return PLUGIN_HANDLED;
	new buffer[512], keys = (1<<0|1<<1|1<<2|1<<9), len = format(buffer, charsmax(buffer), "%L^n", client, "JBE_MENU_BET_TITLE", jbe_get_user_money(client));
	new player = g_iDuelUsersId[0], target = g_iDuelUsersId[1], name[2][33];
	get_user_name(player, name[0], charsmax(name[]));
	get_user_name(target, name[1], charsmax(name[]));
		
	len += format(buffer[len], charsmax(buffer) - len, "\y1. \w \r%L^n^n", client, "JBE_MENU_BET_COST", g_iMaxBetCost[g_iBetCost[client]]);
	len += format(buffer[len], charsmax(buffer) - len, "\y2. \w %L^n", client, "JBE_MENU_BET_PLAYER", name[0]);
	len += format(buffer[len], charsmax(buffer) - len, "\y3. \w %L^n^n", client, "JBE_MENU_BET_PLAYER", name[1]);
		
	format(buffer[len], charsmax(buffer) - len, "^n\y0. \w %L", client, "JBE_MENU_EXIT");
	return show_menu(client, keys, buffer, -1, "Show_BetMenu");
}
	
public Handle_BetMenu(client, key) 
{
		if(!g_iDuelStatus || !jbe_is_user_alive( client) || jbe_get_user_team(client) != 1) return PLUGIN_HANDLED;
		new player = g_iDuelUsersId[0], target = g_iDuelUsersId[1], name[3][33];
		get_user_name(player, name[0], charsmax(name[]));
		get_user_name(target, name[1], charsmax(name[]));
		get_user_name(client, name[2], charsmax(name[]));
		switch(key) 
		{
			case 0: 
			{
				if(g_iBetCost[client] == (sizeof(g_iMaxBetCost)-1)) 
				{
					g_iBetCost[client] = 0;
					return Show_BetMenu(client);
				}
				if(jbe_get_user_money(client) >= g_iMaxBetCost[g_iBetCost[client]+1]) 
				{
					if(g_iBetCost[client] == (sizeof(g_iMaxBetCost) - 1)) g_iBetCost[client] = 0;
					else g_iBetCost[client]++;
				} else UTIL_SayText(client, "%L", LANG_PLAYER, "JBE_BET_NO_MONEY", PL_CHAT_PREFIX);
				return Show_BetMenu(client);
			}
			case 1: 
			{
				if(jbe_get_user_money(client) < g_iMaxBetCost[g_iBetCost[client]]) 
				{
					UTIL_SayText(client, "%L", LANG_PLAYER, "JBE_BET_NO_MONEY", PL_CHAT_PREFIX);
					return Show_BetMenu(client);
				} 
				else 
				{
					g_iBetPlayer[client] = player;
					//jbe_set_user_money(client, jbe_get_user_money(client) - g_iMaxBetCost[g_iBetCost[client]], 1);
					jbe_set_butt(client, jbe_get_butt(client) - g_iMaxBetCost[g_iBetCost[client]]);
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_BET_SET_MONEY", PL_CHAT_PREFIX, name[2], g_iMaxBetCost[g_iBetCost[client]], name[0]);
					g_iBetStatus[client] = true;
				}
			}
			case 2: 
			{
				if(jbe_get_user_money(client) < g_iMaxBetCost[g_iBetCost[client]]) 
				{
					UTIL_SayText(client, "%L", LANG_PLAYER, "JBE_BET_NO_MONEY", PL_CHAT_PREFIX);
					return Show_BetMenu(client);
				} 
				else 
				{
					g_iBetPlayer[client] = target;
					//jbe_set_user_money(client, jbe_get_user_money(client) - g_iMaxBetCost[g_iBetCost[client]], 1);
					jbe_set_butt(client, jbe_get_butt(client) - g_iMaxBetCost[g_iBetCost[client]]);
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_BET_SET_MONEY", PL_CHAT_PREFIX, name[2], g_iMaxBetCost[g_iBetCost[client]], name[1]);
					g_iBetStatus[client] = true;
				}
			}
		}
		return PLUGIN_HANDLED;
	}
#endif



public jbe_lr_duels()
{
	g_iLastPnId = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
		
		g_iLastPnId = i;
		if(g_iLastPnId)
			break;
	}
	if(g_iLastPnId)
	{
		set_hudmessage(127, 255, 255, -1.0, 0.65, 0, 0.0, 5.0, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncDuelInformer, "Последний заключенный - %n", g_iLastPnId);
		
		//set_task_ex(1.0, "jbe_last_prisoner_time", TASK_DUEL_LAST_PRISONER ,_, _, SetTask_RepeatTimes, g_iCountDownLastPR = 30);
#if defined DEBUG
		//log_amx("jbe_lr_duels Called");
		//server_print("jbe_lr_duels Called");
#endif
		return Show_LastPrisonerMenu(g_iLastPnId);
	}
	
	return PLUGIN_HANDLED;
}

public jbe_last_prisoner_time()
{
	if(--g_iCountDownLastPR) 
	{
		CenterMsgFix_PrintMsg(0, print_center, "У заключенного есть %d секунд на желание", g_iCountDownLastPR);
	}
	else 
	{
		if(jbe_is_user_alive(g_iLastPnId))
		{
			ExecuteHamB(Ham_Killed, g_iLastPnId, g_iLastPnId, 0);
		}
	}
}

/*===== -> Дуэль -> =====*///{
jbe_duel_start_ready(pPlayer, pTarget)
{
	EnableHookChain(HookPlayer_TakeDamage);
	EnableHookChain(HookPlayer_TraceAttack);
	EnableHookChain(HookPlayer_Killed);
	for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
	EnableHamForward(g_iHamHookAttack);
	
#if defined BEAMDUELS
	iEnt = rg_create_entity("info_target", true);
	SetThink(iEnt, "think_step");
	set_entvar(iEnt, var_nextthink, get_gametime() + THIBKBEAM);
#endif
	if(fDuelOriginPrison[0] != 0.0 || fDuelOriginPrison[1] != 0.0 || fDuelOriginPrison[2] != 0.0)
		set_entvar(pPlayer, var_origin, fDuelOriginPrison);
	
	if(fDuelOriginGuard[0] != 0.0 || fDuelOriginGuard[1] != 0.0 || fDuelOriginGuard[2] != 0.0)
		set_entvar(pTarget, var_origin, fDuelOriginGuard);

	
	
	if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
	g_iDuelStatus = 1;

	rg_remove_all_items(pPlayer);
	rg_remove_all_items(pTarget);

	g_iDuelUsersId[0] = pPlayer;
	g_iDuelUsersId[1] = pTarget;

	SetBit(g_iBitUserDuel, pPlayer);
	SetBit(g_iBitUserDuel, pTarget);

	rg_reset_maxspeed(pPlayer);
	rg_reset_maxspeed(pTarget);

	set_entvar(pPlayer, var_gravity, 1.0);
	set_entvar(pTarget, var_gravity, 1.0);

	if(jbe_get_user_godmode(pPlayer)) jbe_set_user_godmode(pPlayer, 0);
	if(jbe_get_user_godmode(pTarget)) jbe_set_user_godmode(pTarget, 0);

	get_user_name(pPlayer, g_iDuelNames[0], charsmax(g_iDuelNames[]));
	get_user_name(pTarget, g_iDuelNames[1], charsmax(g_iDuelNames[]));
	
	jbe_hide_user_costumes(pPlayer);
	jbe_hide_user_costumes(pTarget);
	
	jbe_set_user_rendering(pPlayer, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
	jbe_set_user_rendering(pTarget, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 0);
	
	g_iDuelCountDown = 5;

	set_task_ex(1.0, "jbe_main_informer", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);
	
	set_task_ex(1.0, "jbe_duel_count_down", TASK_DUEL_COUNT_DOWN, _, _, SetTask_RepeatTimes, g_iDuelCountDown);
	

	if(get_login(pPlayer) && jbe_mysql_stats_systems_get(pPlayer, 85) < get_cvar_num("jbe_quest_duel"))
	{
		//g_iUserQuestDuels[pPlayer]++;
		//jbe_mysql_stats_systems_add(pPlayer, 115, g_iUserQuestDuels[pPlayer]);
		jbe_mysql_stats_systems_add(pPlayer, 85, jbe_mysql_stats_systems_get(pPlayer, 85) + 1);
	}

#if defined PL_BET_MENU

	for(new client = 1; client <= MaxClients; client++) 
	{
		if(!jbe_is_user_alive(client) && jbe_get_user_team(client) == 1) 
		{
			g_iBetStatus[client] = false;
			g_iBetPlayer[client] = -1;
			g_iBetCost[client] = 0;
			Show_BetMenu(client);
		} 
		else g_iBetStatus[client] = false;
	}
	
#endif
}



public jbe_duel_count_down()
{
	if(!--g_iDuelCountDown) jbe_duel_start();
}

jbe_duel_start()
{
	g_iDuelStatus = 2;
	if(g_iDuelType != 6) 
		set_task_ex(1.0, "jbe_duel_time_to_kill", TASK_DUEL_TIME_TO_KILL, _, _, SetTask_RepeatTimes, g_iDuelTimeToKill = 60 + 1);
/*	if(!is_user_connected(g_iDuelUsersId[0]) || !is_user_connected(g_iDuelUsersId[1])) 
	{
		return 0;
	}*/
	switch(g_iDuelType)
	{
		case 1:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item(g_iDuelUsersId[0], "weapon_deagle" , GT_REPLACE);
			set_entvar(g_iDuelUsersId[0], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);
			g_iUserDuels = g_iDuelUsersId[0];
			set_task_ex(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
			set_entvar(g_iDuelUsersId[1], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);
		}
		case 2:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item(g_iDuelUsersId[0], "weapon_m3" , GT_REPLACE);
			set_entvar(g_iDuelUsersId[0], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);
			g_iUserDuels = g_iDuelUsersId[0];
			set_task_ex(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
			set_entvar(g_iDuelUsersId[1], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0, linux_diff_player);
		}
		case 3:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item_ex(g_iDuelUsersId[0],"weapon_hegrenade", GT_REPLACE, 200);
			set_entvar(g_iDuelUsersId[0], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);

			rg_remove_all_items(g_iDuelUsersId[1]);
			rg_give_item_ex(g_iDuelUsersId[1],"weapon_hegrenade", GT_REPLACE, 200);
			set_entvar(g_iDuelUsersId[1], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
		}
		case 4:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item_ex(g_iDuelUsersId[0],"weapon_m249", GT_REPLACE, 200);
			set_entvar(g_iDuelUsersId[0], var_health, 506.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);

			rg_remove_all_items(g_iDuelUsersId[1]);
			rg_give_item_ex(g_iDuelUsersId[1],"weapon_m249", GT_REPLACE, 200);
			set_entvar(g_iDuelUsersId[1], var_health, 506.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
		}
		case 5:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item(g_iDuelUsersId[0], "weapon_awp" , GT_REPLACE);
			set_entvar(g_iDuelUsersId[0], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);
			g_iUserDuels = g_iDuelUsersId[0];
			set_task_ex(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
			set_entvar(g_iDuelUsersId[1], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);
			
		}
		case 6:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item(g_iDuelUsersId[0], "weapon_knife");
			set_entvar(g_iDuelUsersId[0], var_health, 150.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);

			rg_remove_all_items(g_iDuelUsersId[1]);
			rg_give_item(g_iDuelUsersId[1], "weapon_knife");
			set_entvar(g_iDuelUsersId[1], var_health, 150.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
		}
		case 7:
		{
			rg_remove_all_items(g_iDuelUsersId[0]);
			rg_give_item(g_iDuelUsersId[0], "weapon_ak47" , GT_REPLACE);
			set_entvar(g_iDuelUsersId[0], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[0], 100, ARMOR_VESTHELM);
			g_iUserDuels = g_iDuelUsersId[0];
			set_task_ex(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
			set_entvar(g_iDuelUsersId[1], var_health, 100.0);
			rg_set_user_armor(g_iDuelUsersId[1], 100, ARMOR_VESTHELM);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);

			jbe_set_user_gold(g_iDuelUsersId[0], true);
			jbe_set_user_gold(g_iDuelUsersId[1], true);
		}
	}
}

public jbe_duel_time_to_kill()
{
	if( !--g_iDuelTimeToKill )
	{
		new hp0 = get_user_health(g_iDuelUsersId[0]);
		new hp1 = get_user_health(g_iDuelUsersId[1]);

		if(hp0 > hp1) ExecuteHamB( Ham_Killed, g_iDuelUsersId[ 1 ], g_iDuelUsersId[ 0 ], 0 )
		else if(hp1 > hp0) ExecuteHamB( Ham_Killed, g_iDuelUsersId[ 0 ], g_iDuelUsersId[ 1 ], 0 ) ;
		else ExecuteHamB( Ham_Killed, g_iDuelUsersId[ 1 ], g_iDuelUsersId[ 0 ], 0 ) ;
	}
}

public jbe_duel_timer_attack(pPlayer)
{
	pPlayer -= TASK_DUEL_TIMER_ATTACK;
	
	if(!--g_iDuelTimerAttack)
	{
		new iActiveItem = get_member(pPlayer, m_pActiveItem);
		if(iActiveItem > 0) ExecuteHamB(Ham_Weapon_PrimaryAttack, iActiveItem);
	}
}

public jbe_main_informer()
{
	set_hudmessage(255, 255, 0, 0.7, 0.05, 0, 0.0, 1.1, 0.2, 0.2, -1);

	if(g_iDuelCountDown <= 5 && g_iDuelCountDown) 
	{
		ShowSyncHudMsg(0, jbe_get_syncinf_1(), "^n^n^n%L", LANG_PLAYER, "JBE_ALL_HUD_DUEL_START_READY", LANG_PLAYER, g_iDuelLang[g_iDuelType], g_iDuelNames[0], g_iDuelNames[1], g_iDuelCountDown);
		SendAudio(0, g_szSound[g_iDuelCountDown - 1], PITCH_NORM);
	}
	else
	{
		if(g_iDuelType == 1 || g_iDuelType == 2 || g_iDuelType == 5 ||g_iDuelType == 7)
		{
			new hp0 = get_user_health(g_iDuelUsersId[0]);
			new hp1 = get_user_health(g_iDuelUsersId[1]);
			ShowSyncHudMsg(0, jbe_get_syncinf_1(), 
			
			"^n^n^n\
			Стреляет - %s^n\
			Автовыстрел через %d секунд!^n\
			Зек     - [%dHP]^n\
			Охрана  - [%dHP]^n^n\
			До конца Дуэли - %d сек.", 
			
			g_iUserDuels == g_iDuelUsersId[0] ? g_iDuelNames[0] : g_iDuelNames[1],
			g_iDuelTimerAttack, 
			hp0, hp1, g_iDuelTimeToKill);
		}
	}
}


public jbe_duel_ended(pPlayer)
{
	for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
	DisableHamForward(g_iHamHookAttack);
	DisableHookChain(HookPlayer_TakeDamage);
	DisableHookChain(HookPlayer_TraceAttack);
	DisableHookChain(HookPlayer_Killed);

	if(is_entity(iEnt))
	{
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
		set_entvar(iEnt, var_nextthink, get_gametime());
	}
	if(task_exists(TASK_DUEL_LAST_PRISONER)) remove_task(TASK_DUEL_LAST_PRISONER);
	g_iBitUserDuel = 0;
	g_iUserDuels = 0
	remove_task(TASK_SHOW_INFORMER);
	jbe_set_user_rendering(g_iDuelUsersId[0], kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	jbe_set_user_rendering(g_iDuelUsersId[1], kRenderFxNone, 0, 0, 0, kRenderNormal, 0);

	if(task_exists(g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK)) remove_task(g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK);
	if(task_exists(g_iDuelUsersId[1]+TASK_DUEL_TIMER_ATTACK)) remove_task(g_iDuelUsersId[1]+TASK_DUEL_TIMER_ATTACK);
	
	remove_task(TASK_DUEL_TIME_TO_KILL);

	new iPlayer = g_iDuelUsersId[0] != pPlayer ? g_iDuelUsersId[0] : g_iDuelUsersId[1];

	rg_reset_maxspeed(iPlayer);

	rg_remove_all_items(iPlayer);
	rg_give_item(iPlayer, "weapon_knife");

	switch(g_iDuelStatus)
	{
		case 1:
		{
			if(task_exists(TASK_DUEL_COUNT_DOWN))
			{
				remove_task(TASK_DUEL_COUNT_DOWN);
				client_cmd(0, "mp3 stop");
			}
		}
		case 2: 
		{
			if(jbe_get_user_team(iPlayer) == 1)
			{
				switch(g_iFriendPrise)
				{
					case 0:
					{
						//jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 200, 1);
						jbe_set_butt(iPlayer, jbe_get_butt(iPlayer) + 2);
						if(g_iDuelType == 7)
						{
							jbe_set_user_gold(iPlayer, false);
						}
					}
					case 1:
					{
						if(is_user_connected(g_iFriendPlayers))
						{
							jbe_add_user_free_next_round(g_iFriendPlayers);
							UTIL_SayText(0, "!g * !y%n выйграл для %n ФД в следуещем раунде",iPlayer, g_iFriendPlayers)
						}
						else
						{
							jbe_add_user_free_next_round(iPlayer);
							UTIL_SayText(0, "!g * !yДруг победитея вышел с игры, приз достается %n", iPlayer)
						}
					}
					case 2:
					{
						if(is_user_connected(g_iFriendPlayers))
						{
							//jbe_set_user_money(g_iFriendPlayers, jbe_get_user_money(g_iFriendPlayers) + g_iAllCvars, 1);
							if(g_iFriendPlayers == iPlayer)
							{
								jbe_set_butt(g_iFriendPlayers, jbe_get_butt(g_iFriendPlayers) + g_iAllCvars[0]);
								UTIL_SayText(0, "!g * !y%n выйграл себе %d бычков  в следуещем раунде",iPlayer,g_iAllCvars[0])
							}
							else
							{
								jbe_set_butt(g_iFriendPlayers, jbe_get_butt(g_iFriendPlayers) + g_iAllCvars[1]);
								UTIL_SayText(0, "!g * !y%n выйграл для %n %d бычков  в следуещем раунде",iPlayer, g_iFriendPlayers,g_iAllCvars[1])
							}
						}
						else
						{
							jbe_set_butt(iPlayer, jbe_get_butt(iPlayer) + g_iAllCvars[0]);
							UTIL_SayText(0, "!g * !yДруг победитея вышел с игры, приз достается %n", iPlayer)
						}
					}
					case 3:
					{
						if(is_user_connected(g_iFriendPlayers)) 
						{
							jbe_set_user_voice_next_round(g_iFriendPlayers);
							UTIL_SayText(0, "!g * !y%n выйграл для %n голос в следуещем раунде",iPlayer, g_iFriendPlayers)
						}
						else
						{
							jbe_set_user_voice_next_round(iPlayer);
							UTIL_SayText(0, "!g * !yДруг победитея вышел с игры, приз достается %n",iPlayer)
						}
					}
				}
			}
			
		}
	}
	g_iFriendPlayers = 0;
	g_iFriendPrise = 0;
	g_iDuelStatus = 0;
	g_iDuelUsersId[0] = 0;
	g_iDuelUsersId[1] = 0;
	
}
/*===== -> Дуэль -> =====*///}


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


public Ham_ItemPSecondaryAttack(iEntity)
{
	if(g_iDuelStatus && g_iDuelType == 5)
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}
public Ham_ItemPrimaryAttack_Post(iEntity)
{
	if(g_iDuelStatus)
	{
		new pId = get_member(iEntity, m_pPlayer);
		
		static iActiveItem;
		iActiveItem = get_member(pId, m_pActiveItem);
		if(IsSetBit(g_iBitUserDuel, pId))
		{
			switch(g_iDuelType)
			{
				case 1:
				{
					set_member(pId, m_flNextAttack, 11.0);
					rg_remove_all_items(pId);
					if(task_exists(pId+TASK_DUEL_TIMER_ATTACK)) remove_task(pId+TASK_DUEL_TIMER_ATTACK);
					pId = g_iDuelUsersId[0] != pId ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(pId, m_flNextAttack, 0.0);
					rg_give_item(pId, "weapon_deagle" , GT_REPLACE);
					g_iUserDuels = pId;
					set_task_ex(1.0, "jbe_duel_timer_attack", pId+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
				}
				case 2:
				{
					set_member(pId, m_flNextAttack, 11.0);
					rg_remove_all_items(pId);
					if(task_exists(pId+TASK_DUEL_TIMER_ATTACK)) remove_task(pId+TASK_DUEL_TIMER_ATTACK);
					pId = g_iDuelUsersId[0] != pId ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(pId, m_flNextAttack, 0.0);
					rg_give_item(pId, "weapon_m3" , GT_REPLACE);
					set_member(iActiveItem, m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
					g_iUserDuels = pId;
					set_task_ex(1.0, "jbe_duel_timer_attack", pId+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
				}
				case 5:
				{
					set_member(pId, m_flNextAttack, 11.0);
					rg_remove_all_items(pId);
					if(task_exists(pId+TASK_DUEL_TIMER_ATTACK)) remove_task(pId+TASK_DUEL_TIMER_ATTACK);
					pId = g_iDuelUsersId[0] != pId ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(pId, m_flNextAttack, 0.0);
					rg_give_item(pId, "weapon_awp" , GT_REPLACE);
					set_member(iActiveItem, m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
					g_iUserDuels = pId;
					set_task_ex(1.0, "jbe_duel_timer_attack", pId+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
				}
				case 7:
				{
					set_member(pId, m_flNextAttack, 11.0);
					rg_remove_all_items(pId);
					if(task_exists(pId+TASK_DUEL_TIMER_ATTACK)) remove_task(pId+TASK_DUEL_TIMER_ATTACK);
					pId = g_iDuelUsersId[0] != pId ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(pId, m_flNextAttack, 0.0);
					rg_give_item(pId, "weapon_ak47" , GT_REPLACE);
					set_member(iActiveItem, m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
					g_iUserDuels = pId;
					set_task_ex(1.0, "jbe_duel_timer_attack", pId+TASK_DUEL_TIMER_ATTACK, _, _, SetTask_RepeatTimes, g_iDuelTimerAttack = 11);
				}
			}
		}
	}
}


/*===== -> Стоки -> =====*///{

#if defined BEAMDUELS
public think_step(iEnt)
{
	if(g_iDuelStatus && g_iDuelUsersId[0] && g_iDuelUsersId[1])
	{
		static  Float:origin2_F[3],
				Float:vecOrigin[3], 
				origin2[3], 
				pId;

		get_entvar(g_iDuelUsersId[1], var_origin, origin2_F);
		get_entvar(g_iDuelUsersId[0], var_origin, vecOrigin);
		
		
		origin2[0] = floatround(origin2_F[0]);
		origin2[1] = floatround(origin2_F[1]);
		origin2[2] = floatround(origin2_F[2]);

		//Create red beam
		/*if(jbe_is_user_valid(g_iDuelUsersId[0]))
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
			write_byte(1);		//TE_BEAMENTPOINT
			write_short(g_iDuelUsersId[0]);		// start entity
			write_coord(origin2[0]);
			write_coord(origin2[1]);
			write_coord(origin2[2]);
			write_short(g_pSpriteBeam);
			write_byte(1);		// framestart
			write_byte(1);		// framerate
			write_byte(BEAMLIFE);		// life in 0.1's
			write_byte(5);		// width
			write_byte(0);		// noise
			write_byte(255);		// red
			write_byte(0);		// green
			write_byte(0);		// blue
			write_byte(200);	// brightness
			write_byte(0);		// speed
			message_end();
		}*/
		
		while((pId = engfunc(EngFunc_FindEntityInSphere, pId, vecOrigin, 200.0)))
		{
			if(jbe_is_user_valid(pId) && jbe_is_user_alive(pId) && pId != g_iDuelUsersId[0] && pId != g_iDuelUsersId[1])
			{
				new Float:ptd[3], 
					Float:push = 3.0;
	 
				get_entvar(pId, var_origin, ptd);

				ptd[0] -= origin2_F[0]; 
				ptd[1] -= origin2_F[1]; 
				ptd[2] -= origin2_F[2];
				
				ptd[0] *= push; 
				ptd[1] *= push; 
				ptd[2] *= push;
				
				set_entvar(pId, var_velocity, ptd);
			}
		}
		
		while((pId = engfunc(EngFunc_FindEntityInSphere, pId, origin2_F, 200.0)))
		{
			if(jbe_is_user_valid(pId) && jbe_is_user_alive(pId) && pId != g_iDuelUsersId[0] && pId != g_iDuelUsersId[1])
			{
				new Float:ptd[3], 
					Float:push = 3.0;
	 
				get_entvar(pId, var_origin, ptd);

				ptd[0] -= origin2_F[0]; 
				ptd[1] -= origin2_F[1]; 
				ptd[2] -= origin2_F[2];
				
				ptd[0] *= push; 
				ptd[1] *= push; 
				ptd[2] *= push;
				
				set_entvar(pId, var_velocity, ptd);
			}
		}
	}
	set_entvar(iEnt, var_nextthink, get_gametime() + THIBKBEAM);
}
#endif


/*public jbe_save_stats(pId)
{
	#if defined DEBUG
	server_print("***********************************")
	server_print("before :DUELS %d AND %d" ,jbe_mysql_stats_systems_get(pId, 115),jbe_get_user_lr_quest(pId));
	server_print("***********************************")
	#endif
	jbe_mysql_stats_systems_add(pId, 115, g_iUserQuestDuels[pId]);
	g_iUserQuestDuels[pId] = 0;

	#if defined DEBUG
	server_print("***********************************")
	server_print("after :DUELS %d AND %d" ,jbe_mysql_stats_systems_get(pId, 115), jbe_get_user_lr_quest(pId));
	server_print("***********************************")
	#endif
}

public jbe_load_stats(pId)
{
	#if defined DEBUG
	server_print("***********************************")
	server_print("before :DUELS %d AND %d" ,jbe_mysql_stats_systems_get(pId, 115), jbe_get_user_lr_quest(pId));
	server_print("***********************************")
	#endif
	g_iUserQuestDuels[pId] = 0;
	g_iUserQuestDuels[pId] = jbe_mysql_stats_systems_get(pId, 115);
	#if defined DEBUG
	server_print("***********************************")
	server_print("after :DUELS %d AND %d" ,jbe_mysql_stats_systems_get(pId, 115), jbe_get_user_lr_quest(pId));
	server_print("***********************************")
	#endif
}*/


stock SendAudio(id, audio[], pitch)
{
	static iMsgSendAudio;
	if(!iMsgSendAudio) iMsgSendAudio = get_user_msgid("SendAudio");

	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsgSendAudio, _, id);
	write_byte(id);
	write_string(audio);
	write_short(pitch);
	message_end();
}


stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}