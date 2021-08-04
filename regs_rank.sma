#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>
#include <reapi>

new g_iGlobalDebug;
#include <util_saytext>


#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

native jbe_playersnum(iType);

enum _:(+= 100)
{
	TASK_RANK_REWARD_EXP = 200,
	TASK_RANK_UPDATE_RANK
}
const TASK_UPDATE = 600
#define TOTAL_PLAYER_LEVELS 					16
#define MAX_LEVEL 								TOTAL_PLAYER_LEVELS - 1

new g_iLevelT[MAX_PLAYERS + 1];
new g_iLevelCT[MAX_PLAYERS + 1];

native jbe_mysql_stats_systems_get(pId, iType)
native jbe_mysql_stats_systems_add(pId, iType, iNum) 

forward jbe_set_team_fwd(pId);
native get_login(pPlayer);

new g_iExpT[MAX_PLAYERS + 1], g_iExpCT[MAX_PLAYERS + 1];

//#define DEBUG

#define DEBUG_LOG_EXP

native jbe_is_user_duel(index);

new const g_szExp[TOTAL_PLAYER_LEVELS]= 
{ 
	0, 
	25, 
	50, 
	120, 
	300, 
	500, 
	750, 
	1500, 
	2300, 
	3100, 
	4500, 
	6000, 
	8000, 
	10000, 
	12000, 
	15000 
};



new const Float:g_iHealth[][TOTAL_PLAYER_LEVELS] = 
{
	{
	},
	{
		0.0, 
		3.0, 
		6.0, 
		9.0, 
		12.0, 
		15.0, 
		18.0, 
		21.0, 
		24.0, 
		27.0, 
		30.0, 
		33.0, 
		36.0, 
		39.0, 
		41.0, 
		45.0 
	},
	{
		0.0,
		6.25, 
		12.5, 
		18.25, 
		24.5, 
		30.75, 
		37.0, 
		43.25, 
		49.5, 
		55.75, 
		62.0, 
		68.25, 
		74.5, 
		80.75, 
		87.0, 
		100.0
	}
};


enum _:STATS
{
	PN_KILLED_PN,
	PN_KILLED_GR,
	PN_KILLED_CH,
	PN_WIN_DAYMODE,
	PN_VICTIM_PN,
	PN_VICTIM_GR_WT,
	PN_WIN_DUEL,
	PN_LOSE_DUEL,
	
	GR_KILLED_PN,
	GR_KILLED_PN_WT,
	GR_TAKE_CHIEF,
	GR_TRANSFER_CHIEF,
	GR_WIN_DAYMODE,
	GR_VICTIM_PN_GR,
	GR_VICTIM_PN_DUELS,
	GR_WIN_DUEL,
	
	MAX_PRISONER_FARM,
	
	DEFAULT_HEALTH_PRISONER,
	DEFAULT_HEALTH_GUARD
};

new g_iCvarStats[STATS];
	
	
public plugin_cfg()
{
	new pcvar;
	pcvar = create_cvar("amx_exp_pn_killed_pn", "+1", FCVAR_SERVER, "Убить заключённого");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_KILLED_PN]);
	
	pcvar = create_cvar("amx_exp_pn_killed_gr", "+1", FCVAR_SERVER, "Убить охранника");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_KILLED_GR]);
	
	pcvar = create_cvar("amx_exp_pn_killed_ch", "+2", FCVAR_SERVER, "Убить начальника");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_KILLED_CH]);	
	
	pcvar = create_cvar("amx_exp_pn_win_daymode", "+5", FCVAR_SERVER, "Выйграть в выходные дни (Сб-Вс)");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_WIN_DAYMODE]);	
	
	pcvar = create_cvar("amx_exp_pn_victim_pn", "-1", FCVAR_SERVER, "Вас убил другой заключенный");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_VICTIM_PN]);	
	
	pcvar = create_cvar("amx_exp_pn_victim_gr_wt", "-2", FCVAR_SERVER, "Вас убил охранник(вы бунтующий)");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_VICTIM_GR_WT]);	
	
	pcvar = create_cvar("amx_exp_pn_win_duel", "+2", FCVAR_SERVER, "Выйграть дуэль");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_WIN_DUEL]);	
	
	pcvar = create_cvar("amx_exp_pn_lose_duel", "-2", FCVAR_SERVER, "Проиграть дуэль");
	bind_pcvar_num(pcvar, g_iCvarStats[PN_LOSE_DUEL]);			
	
	
	pcvar = create_cvar("amx_exp_gr_killed_pn", "+1", FCVAR_SERVER, "Убить заключенного");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_KILLED_PN]);	
	
	pcvar = create_cvar("amx_exp_gr_killed_pn_wt", "+2", FCVAR_SERVER, "Убить бунтующего зека");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_KILLED_PN_WT]);	
	
	pcvar = create_cvar("amx_exp_gr_take_chief", "+1", FCVAR_SERVER, "Взять начальника");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_TAKE_CHIEF]);	
	
	pcvar = create_cvar("amx_exp_gr_transfer_chief", "-2", FCVAR_SERVER, "Передать начальника");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_TRANSFER_CHIEF]);		
	
	pcvar = create_cvar("amx_exp_gr_win_daymode", "+5", FCVAR_SERVER, "Выйграть в выходные дни (Сб-Вс)");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_WIN_DAYMODE]);	
	
	pcvar = create_cvar("amx_exp_gr_victim_pn_gr", "-3", FCVAR_SERVER, "Вас убил зек");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_VICTIM_PN_GR]);
	
	pcvar = create_cvar("amx_exp_gr_victim_pn_duel", "-5", FCVAR_SERVER, "Вас убил зек в дуэли");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_VICTIM_PN_DUELS]);	
	
	pcvar = create_cvar("amx_exp_gr_win_duel", "+2", FCVAR_SERVER, "Выйграть дуэль");
	bind_pcvar_num(pcvar, g_iCvarStats[GR_WIN_DUEL]);
	
	
	
	pcvar = create_cvar("amx_exp_max_pn_farm", "5", FCVAR_SERVER, "Со сколько зека начать учет");
	bind_pcvar_num(pcvar, g_iCvarStats[MAX_PRISONER_FARM]);
	
	pcvar = create_cvar("amx_prisoner_default_healt", "100", FCVAR_SERVER, "Дефаулт значение здоровье для зека");
	bind_pcvar_num(pcvar, g_iCvarStats[DEFAULT_HEALTH_PRISONER]);
	
	pcvar = create_cvar("amx_guard_default_healt", "150", FCVAR_SERVER, "Дефаулт значение здоровье для охраны");
	bind_pcvar_num(pcvar, g_iCvarStats[DEFAULT_HEALTH_GUARD]);
	

	
	AutoExecConfig();
}


// Lvl TIME
new g_iLevel[MAX_PLAYERS + 1], g_iExpName[MAX_PLAYERS + 1];
#define MAX_LIMIT_LEVEL			1000


//#define DEBUG


new g_iFwdUpdateRank;


public plugin_init()
{
	register_plugin("[MYSQL] Regs Rank", "1.0a", "DalgaPups");
	
	
	g_iFwdUpdateRank = CreateMultiForward("jbe_update_rank", ET_CONTINUE, FP_CELL) ;
	
	//RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true)
	
	
	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true);
	
	
	#if defined DEBUG
	register_clcmd("say /mestat", "ClCmd_statsme");
	#endif
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public plugin_natives()
{
	register_native("jbe_get_user_ranks", "jbe_get_user_ranks", 1);
	register_native("jbe_get_user_exp_next", "jbe_get_user_exp_next", 1);
	register_native("jbe_mysql_get_exp", "jbe_mysql_get_exp", 1)
	//register_native("jbe_mysql_max_exp", "jbe_mysql_max_exp", 1)
	register_native("jbe_mysql_set_exp", "jbe_mysql_set_exp", 1)
	
	register_native("jbe_exp_give_type", "jbe_exp_give_type");
	
}

public jbe_exp_give_type(plugin_id, num_params)
{
	new id = get_param(1);
	
	switch(jbe_get_user_team(id))
	{
		case 1:
		{
			jbe_mysql_set_exp(id, jbe_get_user_team(id), jbe_mysql_get_exp( id, jbe_get_user_team(id) ) + g_iCvarStats[PN_WIN_DAYMODE]);
				
			#if defined DEBUG_LOG_EXP
			server_print("PN_WIN_DAYMODE | %d", jbe_mysql_get_exp( id, jbe_get_user_team(id) ));
			#endif
		}
		case 2:
		{
			jbe_mysql_set_exp(id, jbe_get_user_team(id), jbe_mysql_get_exp( id, jbe_get_user_team(id) ) + g_iCvarStats[GR_WIN_DAYMODE]);
				
			#if defined DEBUG_LOG_EXP
			server_print("GR_WIN_DAYMODE | %d", jbe_mysql_get_exp( id, jbe_get_user_team(id) ));
			#endif
		}
	}
}

public jbe_get_user_ranks(pId) 
{
	switch(jbe_get_user_team(pId))
	{
		case 1: return g_iLevelT[pId]
		case 2: return g_iLevelCT[pId]
	}
	return false;
}



#if defined DEBUG
public ClCmd_statsme(pId)
{
	jbe_rank_reward_exp(pId);

}
#endif

public jbe_get_user_exp_next(pId)
{
	new iLenLevelTemp = jbe_get_user_ranks(pId);
	new iLevel = iLenLevelTemp == MAX_LEVEL ? MAX_LEVEL : (iLenLevelTemp + 1);
	return g_szExp[iLevel];
}

public jbe_mysql_set_exp(id, iType, set)
{
	switch(iType)
	{
		case 1: g_iExpT[id] = set;
		case 2: g_iExpCT[id] = set;
	}
}

/*public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		if(!jbe_is_user_valid(iKiller)) return HC_CONTINUE;
		if(!jbe_is_user_connected(iKiller)) return HC_CONTINUE;

		if(
			!get_login(iKiller) && 
			iVictim != iKiller && g_iLevel[iKiller] < MAX_LIMIT_LEVEL 
			&& jbe_playersnum(1) <= 5
			) 
			return HC_CONTINUE;
		
		
		switch(jbe_get_user_team(iVictim))
		{
			case 1:
			{
				if(jbe_is_user_wanted(iVictim)) g_iExpName[iKiller] += 2;
				else g_iExpName[iKiller]++;
				
				
				if(jbe_get_user_team(iKiller) == 1)
				{
					if(g_iExpName[iKiller] >= 10)
					{
						g_iLevel[iKiller]++;
						g_iExpName[iKiller] = 0;
					}
				}
			}
			case 2:
			{
				if(jbe_is_user_chief(iVictim)) g_iExpName[iKiller] += 4;
				else g_iExpName[iKiller] += 2;
				
				if(g_iExpName[iKiller] >= 10)
				{
					g_iLevel[iKiller]++;
					g_iExpName[iKiller] = 0;
				}
			}
		}
	}
	return HC_CONTINUE;
}*/

public jbe_mysql_get_exp(id, iType)
{
	

	switch(iType)
	{
		case 1: 
		{
			if(g_iExpT[id] < 0)
			g_iExpT[id] = 0;
			return g_iExpT[id];
		}
		case 2: 
		{
			if(g_iExpCT[id] < 0)
			g_iExpCT[id] = 0;
			
			return g_iExpCT[id];
		}
	}
	return PLUGIN_HANDLED;
}


jbe_get_user_level(pId, iType)
{
	
	switch(iType)
	{
		case 1:
		{
			new iCurrentLevel;
			for(new i = 0; i <= TOTAL_PLAYER_LEVELS; i++)
			{
				switch(i)
				{
					case TOTAL_PLAYER_LEVELS: iCurrentLevel = MAX_LEVEL;
					default:
					{
						if(jbe_mysql_get_exp( pId, 1 ) < g_szExp[i])
						{
							iCurrentLevel = i - 1;
							break;
						}
					}
				}
			}
			return iCurrentLevel;
		}
		case 2:
		{
			new iCurrentLevel;
			for(new i = 0; i <= TOTAL_PLAYER_LEVELS; i++)
			{
				switch(i)
				{
					case TOTAL_PLAYER_LEVELS: iCurrentLevel = MAX_LEVEL;
					default:
					{
						if(jbe_mysql_get_exp( pId, 2 ) < g_szExp[i])
						{
							iCurrentLevel = i - 1;
							break;
						}
					}
				}
			}
			return iCurrentLevel;
		}
	}
	return false;
	
}

public jbe_load_stats(id)
{
	#if defined DEBUG
	server_print("LOAD_PRE T - %d | CT - %d | LVL_T - %d | LVL_CT - %d", g_iExpT[id], g_iExpCT[id], g_iLevelT[id],  g_iLevelCT[id])
	#endif

	g_iExpT[id] = jbe_mysql_stats_systems_get(id, 86);
	g_iExpCT[id] = jbe_mysql_stats_systems_get(id, 87);
	
	g_iLevel[id] = jbe_mysql_stats_systems_get(id, 66);
	g_iExpName[id] = jbe_mysql_stats_systems_get(id, 67);

	//g_iLevel[id] = jbe_mysql_stats_systems_get(id, 70);

	#if defined DEBUG
	server_print("LOAD_POST T - %d | CT - %d | LVL_T - %d | LVL_CT - %d", g_iExpT[id], g_iExpCT[id], g_iLevelT[id],  g_iLevelCT[id])
	#endif

	new iCurrentLevelT = jbe_get_user_level(id, 1);
	if(g_iLevelT[id] != iCurrentLevelT) 
	{
		if(iCurrentLevelT > MAX_LEVEL) iCurrentLevelT = MAX_LEVEL;
		g_iLevelT[id] = iCurrentLevelT;
	}
	new iCurrentLevelCT = jbe_get_user_level(id, 2);
	if(g_iLevelCT[id] != iCurrentLevelCT) 
	{
		if(iCurrentLevelCT > MAX_LEVEL) iCurrentLevelCT = MAX_LEVEL;
		g_iLevelCT[id] = iCurrentLevelCT;
	}
	
	
	new iRet;
	ExecuteForward(g_iFwdUpdateRank , iRet , id);
}



public jbe_save_stats(id)
{
	//remove_task(id + TASK_RANK_REWARD_EXP);

	#if defined DEBUG
	server_print("SAVE_PRE T - %d | CT - %d | LVL_T - %d | LVL_CT - %d", g_iExpT[id], g_iExpCT[id], g_iLevelT[id],  g_iLevelCT[id])
	#endif
	
	jbe_mysql_stats_systems_add(id, 86, g_iExpT[id]);
	jbe_mysql_stats_systems_add(id, 87, g_iExpCT[id]);
	
	jbe_mysql_stats_systems_add(id, 66, g_iLevel[id]);
	jbe_mysql_stats_systems_add(id, 67, g_iExpName[id]);
	
	jbe_mysql_stats_systems_add(id, 69, g_iLevelT[id]);
	jbe_mysql_stats_systems_add(id, 68, g_iLevelCT[id]);
	g_iLevelT[id] = 0;
	g_iLevelCT[id] = 0;
	g_iExpT[id] = 0; 
	g_iExpCT[id] = 0; 
	g_iLevel[id] = 0;
	g_iExpName[id] = 0;
	
	#if defined DEBUG
	server_print("SAVE_POST T - %d | CT - %d | LVL_T - %d | LVL_CT - %d", g_iExpT[id], g_iExpCT[id], g_iLevelT[id],  g_iLevelCT[id])
	#endif

}


/*public jbe_rank_reward_exp(pPlayer)
{

	pPlayer -= TASK_RANK_REWARD_EXP;

	new Exp_Time = random_num(2, 5);
	if(jbe_get_user_team(pPlayer) != 3)
	{
		if(jbe_mysql_get_exp(pPlayer, jbe_get_user_team(pPlayer)) < 12000)
		{
			jbe_mysql_set_exp(pPlayer, jbe_get_user_team(pPlayer), jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ) + Exp_Time)
			client_print_color(pPlayer, 0, "^x04[RankSystems] ^x01Ваш авторитет повысился на +%d. Итого: %d/%d", Exp_Time,jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ), jbe_get_user_exp_next(pPlayer))
			
			set_dhudmessage(150, 255, 150, -1.0, 0.67, 1, 6.0, 5.0);
			show_dhudmessage(pPlayer, "ВАШ АВТОРИТЕТ ПОВЫСИЛСЯ на +%d.^nИТОГО: %d/%d", Exp_Time,jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ), jbe_get_user_exp_next(pPlayer));
		} else remove_task(pPlayer + TASK_RANK_REWARD_EXP);

		new iCurrentLevelT = jbe_get_user_level(pPlayer, 1);
		if(g_iLevelT[pPlayer] != iCurrentLevelT) 
		{
			if(iCurrentLevelT > MAX_LEVEL) iCurrentLevelT = MAX_LEVEL;
			g_iLevelT[pPlayer] = iCurrentLevelT;
		}
		new iCurrentLevelCT = jbe_get_user_level(pPlayer, 2);
		if(g_iLevelCT[pPlayer] != iCurrentLevelCT) 
		{
			if(iCurrentLevelCT > MAX_LEVEL) iCurrentLevelCT = MAX_LEVEL;
			g_iLevelCT[pPlayer] = iCurrentLevelCT;
		}
		
		
	}
}*/

/*stock jbe_rank_reward_exp_ex(pPlayer)
{
	new iCurrentLevelT = jbe_get_user_level(pPlayer, 1);
	if(g_iLevelT[pPlayer] != iCurrentLevelT) 
	{
		if(iCurrentLevelT > MAX_LEVEL) iCurrentLevelT = MAX_LEVEL;
		g_iLevelT[pPlayer] = iCurrentLevelT;
	}
	new iCurrentLevelCT = jbe_get_user_level(pPlayer, 2);
	if(g_iLevelCT[pPlayer] != iCurrentLevelCT) 
	{
		if(iCurrentLevelCT > MAX_LEVEL) iCurrentLevelCT = MAX_LEVEL;
		g_iLevelCT[pPlayer] = iCurrentLevelCT;
	}
	
	new iRet;
	ExecuteForward(g_iFwdUpdateRank , iRet , pPlayer);
}
*/
public jbe_set_team_fwd(pPlayer)
{
	//log_amx("Forwad team select call");
	if(get_login(pPlayer))
	{
		//g_iExpT[pPlayer] = jbe_mysql_stats_systems_get(pPlayer, 86);
		//g_iExpCT[pPlayer] = jbe_mysql_stats_systems_get(pPlayer, 87);
		
		new iCurrentLevelT = jbe_get_user_level(pPlayer, 1);
		if(g_iLevelT[pPlayer] != iCurrentLevelT) 
		{
			if(iCurrentLevelT > MAX_LEVEL) iCurrentLevelT = MAX_LEVEL;
			g_iLevelT[pPlayer] = iCurrentLevelT;
		}
		new iCurrentLevelCT = jbe_get_user_level(pPlayer, 2);
		if(g_iLevelCT[pPlayer] != iCurrentLevelCT) 
		{
			if(iCurrentLevelCT > MAX_LEVEL) iCurrentLevelCT = MAX_LEVEL;
			g_iLevelCT[pPlayer] = iCurrentLevelCT;
		}
	}
}

public client_disconnected(id)
{
	if(task_exists(id + TASK_RANK_REWARD_EXP)) remove_task(id + TASK_RANK_REWARD_EXP);
}




public jbe_set_user_chief_fwd(pPlayer)
{
	if(jbe_playersnum(1) >= g_iCvarStats[MAX_PRISONER_FARM] && get_login(pPlayer))
	{
		jbe_mysql_set_exp(pPlayer, jbe_get_user_team(pPlayer), jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ) + g_iCvarStats[GR_TAKE_CHIEF]);
				
		#if defined DEBUG_LOG_EXP
		server_print("GR_TAKE_CHIEF | %d", jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ));
		#endif
	}

}

public jbe_remove_user_chief_fwd(pPlayer, iType)
{
	if(iType)
	{
		jbe_mysql_set_exp(pPlayer, jbe_get_user_team(pPlayer), jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ) + g_iCvarStats[GR_TRANSFER_CHIEF]);
				
		#if defined DEBUG_LOG_EXP
		server_print("GR_TRANSFER_CHIEF | %d", jbe_mysql_get_exp( pPlayer, jbe_get_user_team(pPlayer) ));
		#endif
	}
}


public jbe_fwr_playerkilled_post(iVictim, iKiller)
{
	if(!jbe_is_user_valid(iKiller)) return HC_CONTINUE;
	if(!jbe_is_user_connected(iKiller)) return HC_CONTINUE;
	if(jbe_get_user_team(iKiller) == 3) return HC_CONTINUE;

	if(!get_login(iKiller) || iVictim == iKiller || jbe_mysql_get_exp(iKiller, jbe_get_user_team(iKiller)) > 12000 ||
	jbe_playersnum(1) <= g_iCvarStats[MAX_PRISONER_FARM]) 
		return HC_CONTINUE;
	#if defined DEBUG_LOG_EXP
	new ExpKiller = jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller));
	new ExpVictim = jbe_mysql_get_exp( iVictim, jbe_get_user_team(iVictim));
	#endif
	if(jbe_get_user_team(iKiller) == 1)
	{
		if(jbe_get_user_team(iVictim) == 1)
		{
			jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[PN_KILLED_PN]);
			
			#if defined DEBUG_LOG_EXP
			server_print("Killer == 1 | Victim == 1 | PN_KILLED_PN | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
			#endif
			
			
			
			jbe_mysql_set_exp(iVictim, jbe_get_user_team(iVictim), jbe_mysql_get_exp( iVictim, jbe_get_user_team(iVictim) ) + g_iCvarStats[PN_VICTIM_PN]);
			
			#if defined DEBUG_LOG_EXP
			server_print("Killer == 1 | Victim == 1 | PN_VICTIM_PN | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
			#endif
		}
		else
		if(jbe_get_user_team(iVictim) == 2)
		{
			if(jbe_is_user_chief(iVictim))
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[PN_KILLED_CH]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 1 | Victim == 2 | PN_KILLED_CH | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
			}
			else
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[PN_KILLED_GR]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 1 | Victim == 2 | PN_KILLED_GR | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
			}
			if(jbe_is_user_duel(iKiller))
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[PN_WIN_DUEL]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 1 | Victim == 2 | PN_WIN_DUEL | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
				
				if(jbe_is_user_duel(iVictim))
				{
					jbe_mysql_set_exp(iVictim, jbe_get_user_team(iVictim), jbe_mysql_get_exp( iVictim, jbe_get_user_team(iVictim) ) + g_iCvarStats[GR_VICTIM_PN_DUELS]);
					
					#if defined DEBUG_LOG_EXP
					server_print("Killer == 1 | Victim == 2 | GR_VICTIM_PN_DUELS | %d | %d", ExpVictim, jbe_mysql_get_exp( iVictim, jbe_get_user_team(iVictim) ));
					#endif
				}
			}
			
		}
	}
	else
	if(jbe_get_user_team(iKiller) == 2)
	{
		if(jbe_get_user_team(iVictim) == 1)
		{
			if(jbe_is_user_wanted(iVictim))
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[GR_KILLED_PN_WT]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 2 | Victim == 1 | GR_KILLED_PN_WT | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
			}
			else
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[GR_KILLED_PN]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 2 | Victim == 1 | GR_KILLED_PN | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
			}
			if(jbe_is_user_duel(iKiller))
			{
				jbe_mysql_set_exp(iKiller, jbe_get_user_team(iKiller), jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ) + g_iCvarStats[GR_WIN_DUEL]);
				
				#if defined DEBUG_LOG_EXP
				server_print("Killer == 2 | Victim == 1 | GR_WIN_DUEL | %d | %d", ExpKiller, jbe_mysql_get_exp( iKiller, jbe_get_user_team(iKiller) ));
				#endif
			}
		}
	}
	
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(!jbe_is_user_connected(pId)) return;
	
	new Float:TotalHP;
	
	switch(jbe_get_user_team(pId))
	{
		case 1:
		{
			TotalHP = float(g_iCvarStats[DEFAULT_HEALTH_PRISONER]) + g_iHealth[jbe_get_user_team(pId)][jbe_get_user_ranks(pId)];
		}
		case 2:
		{
			TotalHP = float(g_iCvarStats[DEFAULT_HEALTH_PRISONER]) + g_iHealth[jbe_get_user_team(pId)][jbe_get_user_ranks(pId)];
		}
	}
	if(TotalHP) 
	{
		set_entvar(pId, var_health, TotalHP);
		UTIL_SayText(pId, "!g[LV: Health] !yСоотношение здоровья равносильно вашему уровню. Ваше Здоровье: !g%.1f HP", TotalHP);
	}
}