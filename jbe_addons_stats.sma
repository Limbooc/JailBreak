#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>

#pragma semicolon 1

//#define DEBUG
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

#define IsGodMode(%1) (bool:(get_entvar(%1, var_takedamage) == DAMAGE_NO))

native jbe_set_butt(pId, iMoney);
native jbe_set_butt_ex(pId, iMoney, iFlash = 1);
native jbe_get_butt(pId);


new g_iBitUserWantedMoney;
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

native jbe_mysql_stats_systems_get(pId, iType);
native jbe_mysql_stats_systems_add(pId, iType, iNumm);
native jbe_all_users_wanted();

native jbe_get_stepchief();
native jbe_get_soccergame();
native jbe_iduel_status();
native jbe_is_user_duel(id);
native jbe_playersnum(iType);
native jbe_is_user_dont_attacked(id);
native jbe_is_user_not_wanted_weapon(pId);
native jbe_show_lastmenu(id);

native get_login(index);


native jbe_restartgame();

forward jbe_set_user_chief_fwd(pPlayer);
forward jbe_fwd_add_user_free(pPlayer);
forward jbe_fwd_add_user_wanted(pPlayer);

native jbe_globalnyizapret();

native jbe_get_ff_crusader();



enum _:STATS
{
	STATS_KILLS_PN,		//Всего убийств
	STATS_KILLS_PN_GR,	//Зек убил Охрану
	STATS_KILLS_PN_CH,	//Зек убил Начальника
	STATS_KILLS_PN_PN,	//Зек убил Зека
	STATS_KILLS_GR_PN,	//Охрана Убила Зека
	STATS_KILLS_KNIFE,	//Убийств с ножа
	STATS_KILLS_DUELS,	//Убийств в дуэли
	STATS_KILLS_DAMAGE,	//Нанес урона
	STATS_ADD_WANTED,
	STATS_ADD_FREE,
	STATS_ADD_CHIEF
};

enum _:MONEY
{
	MODEY_FOR_SPAWN_ALIVE,
	MODEY_FOR_SPAWN_DEAD,
	RIOT_START_MODEY,
	KILLED_GUARD_MODEY,
	KILLED_CHIEF_MODEY,
	KILLED_WANTED_MODEY,
	KILLED_PRISON_MODEY,
	ADWERD_FOR_LOXOTRON_WIN,
	PN_KILLED_PN_MODEY
}


new g_iUserStats[MAX_PLAYERS + 1][STATS],
	g_iAllCvars[MONEY];
	
new g_iBitUserusedLox,
	g_iBitUserSpawn;


public plugin_init()
{
	register_plugin("[JBE] Addons Stats", "1.0", "DalgaPups");
	
	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false);

	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true);
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 					"HC_CBasePlayer_TakeDamage_Player", 	false);

	register_event ("Damage", "eDamage", "b", "2!0");
	
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	register_menucmd(register_menuid("Show_LoxotronMenu"), (1<<0|1<<1|1<<8|1<<9), "Handle_LoxotronMenu");
	
	register_clcmd("say /lox", "open_loxmenu" );
	register_clcmd("lox", "open_loxmenu" );
	
	cvars_init();
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}




/*===== -> Квары -> =====*///{
cvars_init()
{
	new pcvar;
	
	pcvar = create_cvar("jbe_modey_for_spawn_alive", "2", FCVAR_SERVER, "Кол-во бычков в начале раунда если остался живым");
	bind_pcvar_num(pcvar, g_iAllCvars[MODEY_FOR_SPAWN_ALIVE]);
	
	pcvar = create_cvar("jbe_modey_for_spawn_dead", "1", FCVAR_SERVER, "Кол-во бычков в начале раунда");
	bind_pcvar_num(pcvar, g_iAllCvars[MODEY_FOR_SPAWN_DEAD]);
	
	pcvar = create_cvar("jbe_riot_start_money", "35", FCVAR_SERVER, "Кол-во бычков за начало бунта");
	bind_pcvar_num(pcvar, g_iAllCvars[RIOT_START_MODEY]); 

	pcvar = create_cvar("jbe_killed_guard_money", "50", FCVAR_SERVER, "Кол-во бычков за убийства охранника");
	bind_pcvar_num(pcvar, g_iAllCvars[KILLED_GUARD_MODEY]); 

	pcvar = create_cvar("jbe_killed_chief_money", "5", FCVAR_SERVER, "Кол-во бычков за убийства начальника");
	bind_pcvar_num(pcvar, g_iAllCvars[KILLED_CHIEF_MODEY]); 

	pcvar = create_cvar("jbe_round_wanted_killed_money", "25", FCVAR_SERVER, "Кол-во бычков за убийства бунтаря");
	bind_pcvar_num(pcvar, g_iAllCvars[KILLED_WANTED_MODEY]); 
	
	pcvar = create_cvar("jbe_round_prisoin_killed_money", "1", FCVAR_SERVER, "Кол-во бычков за убийства простого заключенного");
	bind_pcvar_num(pcvar, g_iAllCvars[KILLED_PRISON_MODEY]); 
	
	pcvar = create_cvar("jbe_win_loxotron_game", "20", FCVAR_SERVER, "Кол-во бычков за выйграш в лохотроне");
	bind_pcvar_num(pcvar, g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN]);

	pcvar = create_cvar("jbe_killer_pn_killed_pn", "5", FCVAR_SERVER, "Кол-во бычков за убийства другого зека");
	bind_pcvar_num(pcvar, g_iAllCvars[PN_KILLED_PN_MODEY]);

	AutoExecConfig(true, "Jail_Money_Reward_For_Kill");
}




public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, "jb_engine/prison_riot.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/other/woohoo2.wav");
	
}

public open_loxmenu(pId)
{
	if(IsSetBit(g_iBitUserusedLox, pId))
	{
		UTIL_SayText(pId, "!g* !yВы уже использовали лохотрон в этом раунде");
		return PLUGIN_HANDLED;
	}
	else if(jbe_get_user_team(pId) != 1)
	{
		UTIL_SayText(pId, "!g* !yЛохотрон доступен только зекам");
		return PLUGIN_HANDLED;
	}
	else if(jbe_restartgame())
	{
		UTIL_SayText(pId, "!g* !yЛохотрон не доступен в рестарт раунде");
		return PLUGIN_HANDLED;
	}
	if(jbe_get_day_mode() == 2)
	{
		UTIL_SayText(pId, "!g* !yЛохотрон не доступен в глобальном свободном дне");
		return PLUGIN_HANDLED;
	}
	//UTIL_SayText(pId, "Calledwadwa");
	return Show_LoxotronMenu(pId);

}

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iBitUserusedLox = 0;
	g_iBitUserWantedMoney = 0;
}






public jbe_load_stats(pId)
{
	#if defined DEBUG
	UTIL_SayText(0, "PRE_LOAD PN_TOTAL %d", g_iUserStats[pId][STATS_KILLS_PN]);
	#endif

	g_iUserStats[pId][STATS_KILLS_PN_GR] = 0;
	g_iUserStats[pId][STATS_KILLS_PN_CH] = 0;
	g_iUserStats[pId][STATS_KILLS_PN_PN] = 0;
	g_iUserStats[pId][STATS_KILLS_GR_PN] = 0;
	g_iUserStats[pId][STATS_KILLS_KNIFE] = 0;
	g_iUserStats[pId][STATS_KILLS_DUELS] = 0;
	g_iUserStats[pId][STATS_KILLS_DAMAGE] = 0;
	g_iUserStats[pId][STATS_KILLS_PN] = 0;
	g_iUserStats[pId][STATS_ADD_FREE] = 0;
	g_iUserStats[pId][STATS_ADD_WANTED] = 0;
	g_iUserStats[pId][STATS_ADD_CHIEF] = 0;
	
	
	
	g_iUserStats[pId][STATS_KILLS_PN_GR] = jbe_mysql_stats_systems_get(pId, 13);
	g_iUserStats[pId][STATS_KILLS_PN_CH] = jbe_mysql_stats_systems_get(pId, 14);
	g_iUserStats[pId][STATS_KILLS_PN_PN] = jbe_mysql_stats_systems_get(pId, 15);
	g_iUserStats[pId][STATS_KILLS_GR_PN] = jbe_mysql_stats_systems_get(pId, 16);
	g_iUserStats[pId][STATS_KILLS_KNIFE] = jbe_mysql_stats_systems_get(pId, 17);
	g_iUserStats[pId][STATS_KILLS_DUELS] = jbe_mysql_stats_systems_get(pId, 18);
	g_iUserStats[pId][STATS_KILLS_DAMAGE] = jbe_mysql_stats_systems_get(pId, 19);
	g_iUserStats[pId][STATS_KILLS_PN] = jbe_mysql_stats_systems_get(pId, 21);
	g_iUserStats[pId][STATS_ADD_FREE] = jbe_mysql_stats_systems_get(pId, 22);
	g_iUserStats[pId][STATS_ADD_WANTED] = jbe_mysql_stats_systems_get(pId, 23);
	g_iUserStats[pId][STATS_ADD_CHIEF] = jbe_mysql_stats_systems_get(pId, 24);

	#if defined DEBUG
	UTIL_SayText(0, "POST_LOAD PN_TOTAL %d", g_iUserStats[pId][STATS_KILLS_PN]);
	#endif

	
}




public jbe_save_stats(pId)
{
	if(g_iUserStats[pId][STATS_KILLS_DAMAGE] >= 100000)
	{
		g_iUserStats[pId][STATS_KILLS_DAMAGE] = 0;
	}

	#if defined DEBUG
	UTIL_SayText(0, "PRE_SAVE PN_TOTAL %d", g_iUserStats[pId][STATS_KILLS_PN]);
	#endif
	
	
	jbe_mysql_stats_systems_add(pId, 13, g_iUserStats[pId][STATS_KILLS_PN_GR]); 
	jbe_mysql_stats_systems_add(pId, 14, g_iUserStats[pId][STATS_KILLS_PN_CH]); 
	jbe_mysql_stats_systems_add(pId, 15, g_iUserStats[pId][STATS_KILLS_PN_PN]); 
	jbe_mysql_stats_systems_add(pId, 16, g_iUserStats[pId][STATS_KILLS_GR_PN]); 
	jbe_mysql_stats_systems_add(pId, 17, g_iUserStats[pId][STATS_KILLS_KNIFE]);
	jbe_mysql_stats_systems_add(pId, 18, g_iUserStats[pId][STATS_KILLS_DUELS]);
	jbe_mysql_stats_systems_add(pId, 19, g_iUserStats[pId][STATS_KILLS_DAMAGE]);
	jbe_mysql_stats_systems_add(pId, 21, g_iUserStats[pId][STATS_KILLS_PN]);
	jbe_mysql_stats_systems_add(pId, 22, g_iUserStats[pId][STATS_ADD_FREE]);
	jbe_mysql_stats_systems_add(pId, 23, g_iUserStats[pId][STATS_ADD_WANTED]);
	jbe_mysql_stats_systems_add(pId, 24, g_iUserStats[pId][STATS_ADD_CHIEF]);

	
	g_iUserStats[pId][STATS_KILLS_PN_GR] = 0;
	g_iUserStats[pId][STATS_KILLS_PN_CH] = 0;
	g_iUserStats[pId][STATS_KILLS_PN_PN] = 0;
	g_iUserStats[pId][STATS_KILLS_GR_PN] = 0;
	g_iUserStats[pId][STATS_KILLS_KNIFE] = 0;
	g_iUserStats[pId][STATS_KILLS_DUELS] = 0;
	g_iUserStats[pId][STATS_KILLS_DAMAGE] = 0;
	g_iUserStats[pId][STATS_KILLS_PN] = 0;
	g_iUserStats[pId][STATS_ADD_FREE] = 0;
	g_iUserStats[pId][STATS_ADD_WANTED] = 0;
	g_iUserStats[pId][STATS_ADD_CHIEF] = 0;



	#if defined DEBUG
	UTIL_SayText(0, "POST_SAVE PN_TOTAL %d", g_iUserStats[pId][STATS_KILLS_PN]);
	#endif
}



public jbe_set_user_chief_fwd(pPlayer)
{
	if(get_login(pPlayer))
	{
		g_iUserStats[pPlayer][STATS_ADD_CHIEF]++;
	}
}

public jbe_fwd_add_user_free(pPlayer)
{
	if(get_login(pPlayer))
	{
		g_iUserStats[pPlayer][STATS_ADD_FREE]++;
	}
}

public jbe_fwd_add_user_wanted(pPlayer)
{
	if(get_login(pPlayer))
	{
		g_iUserStats[pPlayer][STATS_ADD_WANTED]++;
	}
}


public eDamage(victim)
{
    static attacker;
    attacker = get_user_attacker(victim);
	
	if(!jbe_is_user_valid(victim)) return;
	if(!jbe_is_user_valid(attacker)) return;
	if(victim == attacker) return;
	if(jbe_get_user_team(attacker) != 1) return;
	if(!get_login(attacker)) return;
	
    g_iUserStats[attacker][STATS_KILLS_DAMAGE] += read_data(2);
	#if defined DEBUG
	UTIL_SayText(0, "DAMAGE %d", g_iUserStats[attacker][STATS_KILLS_DAMAGE]);
	#endif
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		if(jbe_is_user_valid(iKiller) && jbe_is_user_valid(iVictim))
		{
			static Float: fCurTime, Float: fNextTime[MAX_PLAYERS + 1]; fCurTime = get_gametime();
			if(jbe_get_user_team(iVictim) == 1 && (iVictim != iKiller) && fNextTime[iKiller] <= fCurTime)
			{
				switch(jbe_get_user_team(iKiller))
				{
					case 1:
					{
						if(get_login(iKiller))
						{
							//g_iUserStats[iKiller][STATS_KILLS_GR_PN]++;
							
							g_iUserStats[iKiller][STATS_KILLS_PN_PN]++;
							
						}
						if(jbe_playersnum(1) > 5)
						{
							
							//jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[PN_KILLED_PN_MODEY], 1);
							jbe_set_butt(iKiller, jbe_get_butt(iKiller) + g_iAllCvars[PN_KILLED_PN_MODEY]);
							
						}
						#if defined DEBUG
						UTIL_SayText(0, "GR_PN %d", g_iUserStats[iKiller][STATS_KILLS_PN_PN]);
						#endif
					}
					case 2:
					{

						if(get_login(iKiller))
						{
	
							g_iUserStats[iKiller][STATS_KILLS_GR_PN]++;
							
							
						}
						if(jbe_playersnum(1) > 5)
						{
							if(jbe_is_user_wanted(iVictim)) 
							{
								//jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[KILLED_WANTED_MODEY], 1);
								jbe_set_butt(iKiller, jbe_get_butt(iKiller) + g_iAllCvars[KILLED_WANTED_MODEY]);
							} 
							else
							{
								jbe_set_butt(iKiller, jbe_get_butt(iKiller) + g_iAllCvars[KILLED_PRISON_MODEY]);
							}
						}
						#if defined DEBUG
						UTIL_SayText(0, "GR_PN |%d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_GR_PN], g_iUserStats[iKiller][STATS_KILLS_PN]);
						#endif
					}
				}
				fNextTime[iKiller] = fCurTime + 1.0;
			}
			else
			if(jbe_get_user_team(iVictim) == 2 && (iVictim != iKiller) && fNextTime[iKiller] <= fCurTime)
			{
				if(jbe_get_user_team(iKiller) == 1)
				{
					{
						if(get_login(iKiller))
						{

							g_iUserStats[iKiller][STATS_KILLS_PN_GR]++;
							
							#if defined DEBUG
							UTIL_SayText(0, "PN_GR |%d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_PN_GR], g_iUserStats[iKiller][STATS_KILLS_PN]);
							#endif
							
							
						}
					}
				}
				if(iVictim == jbe_get_stepchief())
				{
					if(get_login(iKiller))
					{
						
						g_iUserStats[iKiller][STATS_KILLS_PN_CH]++;
						
						
					}
					//jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[KILLED_CHIEF_MODEY], 1);
					jbe_set_butt(iKiller, jbe_get_butt(iKiller) + g_iAllCvars[KILLED_CHIEF_MODEY]);
					
					#if defined DEBUG
					UTIL_SayText(0, "PN_CH |%d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_PN_CH], g_iUserStats[iKiller][STATS_KILLS_PN]);
					#endif
				}else //jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[KILLED_GUARD_MODEY], 1);
				jbe_set_butt(iKiller, jbe_get_butt(iKiller) + g_iAllCvars[KILLED_GUARD_MODEY]);
				#if defined DEBUG
				UTIL_SayText(0, "PN_GR |%d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_PN_GR], g_iUserStats[iKiller][STATS_KILLS_PN]);
				#endif
				fNextTime[iKiller] = fCurTime + 1.0;
			}
			
			if(get_login(iKiller))
			{

				if(get_user_weapon(iKiller) == CSW_KNIFE && iKiller != iVictim)
				{
					g_iUserStats[iKiller][STATS_KILLS_KNIFE]++;
					#if defined DEBUG
					UTIL_SayText(0, "KNIFE |%d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_KNIFE], g_iUserStats[iKiller][STATS_KILLS_PN]);
					#endif
				}
				if(jbe_iduel_status())
				{
					if(jbe_is_user_duel(iKiller) && iVictim != iKiller)
					{
						g_iUserStats[iKiller][STATS_KILLS_DUELS]++;
								
						#if defined DEBUG
						UTIL_SayText(0, "DUELS %d and PN_TOTAL %d", g_iUserStats[iKiller][STATS_KILLS_DUELS], g_iUserStats[iKiller][STATS_KILLS_PN]);
						#endif
					
					}
				}
				if((iVictim != iKiller)) g_iUserStats[iKiller][STATS_KILLS_PN]++;
			}
		}
		
	}
}

public HC_CBasePlayer_TakeDamage_Player(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(!jbe_is_user_valid(iAttacker))
		return HC_CONTINUE;
	
	if(jbe_get_day_mode() > 2 || jbe_iduel_status() || jbe_get_ff_crusader() /*|| jbe_get_soccergame()*/  ||jbe_restartgame())
		return HC_CONTINUE;
		
	if(jbe_is_user_wanted(iAttacker) || jbe_is_user_dont_attacked(iAttacker) || jbe_is_user_not_wanted_weapon(iAttacker))
		return HC_CONTINUE;
		
	if(jbe_get_user_team(iAttacker) != 1)
		return HC_CONTINUE;

	if(jbe_get_user_team(iVictim) != 2)
		return HC_CONTINUE;
		
		
	if(IsGodMode(iVictim))
		return HC_CONTINUE;
		
		
	if(iBitDamage & (1<<24))
	{
		if(!jbe_all_users_wanted())
		{
			emit_sound(0, CHAN_AUTO, "jb_engine/prison_riot.wav", 0.3, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(0, CHAN_AUTO, "jb_engine/prison_riot.wav", 0.3, ATTN_NORM, 0, PITCH_NORM);
		}
		
		if(IsNotSetBit(g_iBitUserWantedMoney, iAttacker))
		{
			//jbe_set_user_money(iAttacker, jbe_get_user_money(iAttacker) + g_iAllCvars[RIOT_START_MODEY], 1);
			jbe_set_butt(iAttacker, jbe_get_butt(iAttacker) + g_iAllCvars[RIOT_START_MODEY]);
			SetBit(g_iBitUserWantedMoney, iAttacker);
		}
		jbe_add_user_wanted(iAttacker);
	}

	return HC_CONTINUE;
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(!jbe_is_user_valid(iAttacker))
		return HC_CONTINUE;
	
	if(jbe_get_day_mode() > 2 || jbe_iduel_status() || jbe_get_ff_crusader() || jbe_restartgame()/* || jbe_get_soccergame()*/)
		return HC_CONTINUE;
		
	if(jbe_is_user_wanted(iAttacker))
		return HC_CONTINUE;
		
	if(jbe_get_user_team(iAttacker) != 1)
		return HC_CONTINUE;
		
	if(jbe_get_user_team(iVictim) != 2)
		return HC_CONTINUE;
		
	if(jbe_globalnyizapret() || jbe_is_user_dont_attacked(iAttacker) || jbe_is_user_not_wanted_weapon(iAttacker))
		return HC_CONTINUE;
	
	//if(rg_is_player_can_takedamage(iVictim, iAttacker) == false)
	if(IsGodMode(iVictim))
		return HC_CONTINUE;
		
		
		
	if(!jbe_all_users_wanted())
	{
		emit_sound(0, CHAN_AUTO, "jb_engine/prison_riot.wav", 0.3, ATTN_NORM, SND_STOP, PITCH_NORM);
		emit_sound(0, CHAN_AUTO, "jb_engine/prison_riot.wav", 0.3, ATTN_NORM, 0, PITCH_NORM);
	}
	
	if(IsNotSetBit(g_iBitUserWantedMoney, iAttacker))
	{
		//jbe_set_user_money(iAttacker, jbe_get_user_money(iAttacker) + g_iAllCvars[RIOT_START_MODEY], 1);
		jbe_set_butt(iAttacker, jbe_get_butt(iAttacker) +  g_iAllCvars[RIOT_START_MODEY]);
		SetBit(g_iBitUserWantedMoney, iAttacker);
	}
	jbe_add_user_wanted(iAttacker);

	return HC_CONTINUE;
}

#define MsgId_Money 102

public jbe_fwr_roundend() g_iBitUserSpawn = 0;

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(jbe_get_day_mode() != 3)
	{
		
		new iMoney = g_iAllCvars[MODEY_FOR_SPAWN_ALIVE];
		if(jbe_is_user_alive(pId))
		{
			if(jbe_playersnum(1) < 5)
			{
				iMoney = 0;
			}
		}
		else iMoney = 0;
		if(IsSetBit(g_iBitUserSpawn, pId)) iMoney = 0;
		
		
		if(!get_login(pId))
		{
			iMoney = 0;
			UTIL_SayText(pId, "!g* !yВы не авторизованы, для поступление валюты авторизуйтесь !tsay !g/reg");
			
			if(IsNotSetBit(g_iBitUserSpawn, pId))
			{
				iMoney = g_iAllCvars[MODEY_FOR_SPAWN_DEAD];
			}
		}
		
		jbe_set_butt_ex(pId, jbe_get_butt(pId) +  iMoney);
		
		SetBit(g_iBitUserSpawn, pId);
	}
	return HC_CONTINUE;
}

Show_LoxotronMenu(id)
{
	//jbe_informer_offset_up(id);
	new szMenu[1024], iKeys = (1<<0|1<<1|1<<8|1<<9), iLen;
	

	FormatMain("\rИграем в лохотрон?^n\r50%%\w - \yСмерть^n\r20%%\w - \yОболочка^n\r15%%\w - \y150 Брони и 150 Здоровья^n\r10%%\w - \yКольт^n\r5%% - %d бычков^n^n^n", g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN]);

	FormatItem("\y1. \wДа^n");
	FormatItem("\y2. \wНет^n");
	
	FormatItem("^n\y0. \w%L", id, "JBE_MENU_BACK");

	return show_menu(id, iKeys, szMenu, -1, "Show_LoxotronMenu");
}

public Handle_LoxotronMenu(id, key)
{
	if(!jbe_is_user_alive(id))
	{
		UTIL_SayText(id, "!g* !yЛохотрон доступно только живым!");
		return PLUGIN_HANDLED;
	}
	
	if(jbe_get_user_team(id) != 1)
	{
		UTIL_SayText(id, "!g* !yЛохотрон доступно только pfrk.xtyysv!");
		return PLUGIN_HANDLED;
	}
	
	if(jbe_get_day_mode() == 3)
	{
		UTIL_SayText(id, "!g* !yЛохотрон не доступно во время игр");
		return PLUGIN_HANDLED;
	}
	if(jbe_iduel_status() || jbe_get_soccergame())
	{
		UTIL_SayText(id, "!g* !yЛохотрон не доступно во время бокса или футбола");
		return PLUGIN_HANDLED;
	}
	
	switch( key ) 
	{
		case 0:
		{
			
				new shans;

				shans = random_num(0,100);
				if (shans < 50)
				{
					UTIL_SayText(0, "!g[Лохотрон] !y%n Выиграл смерть", id);
					UTIL_SayText(id, "!g[Лохотрон] !tИзвините, но вы выиграли !tсмерть, Квест не засчиталось");
					user_kill(id);
				}
				else 
				if (shans > 50 && shans < 65)
				{
					UTIL_SayText(0, "!g[Лохотрон] !y%n Выиграл 150 брони и 150 здоровья", id);
					UTIL_SayText(id, "!g[Лохотрон] !tВы выиграли !g150 !tброни !tи !g150 !tздоровья");
					rg_set_user_armor(id, 150, ARMOR_VESTHELM);
					set_entvar(id, var_health, 150.0);
					emit_sound(id, CHAN_AUTO, "jb_engine/other/woohoo2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
				else
				if (shans > 65 && shans < 75)
				{
					UTIL_SayText(0, "!g[Лохотрон] !y%n Выиграл кольт", id);
					UTIL_SayText(id, "!g[Лохотрон] !tВы выиграли !gкольт");
					rg_remove_item(id, "weapon_deagle");
					new iEntity = rg_give_item(id, "weapon_deagle", GT_REPLACE);
					if(iEntity > 0) set_member(iEntity, m_Weapon_iClip, 3);
					emit_sound(id, CHAN_AUTO, "jb_engine/other/woohoo2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
				else
				if (shans > 75 && shans < 95)
				{
					UTIL_SayText(0, "!g[Лохотрон] !y%n Выиграл оболочку", id);
					UTIL_SayText(id, "!g[Лохотрон] !tВы выиграли !gоболочку");
					jbe_set_user_rendering(id, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, random_num(0, 255) );
					emit_sound(id, CHAN_AUTO, "jb_engine/other/woohoo2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
				else
				if (shans > 95 && shans < 100)
				{
					UTIL_SayText(0, "!g[Лохотрон] !y%n Выиграл %d бычков", id, g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN]);
					UTIL_SayText(id, "!g[Лохотрон] !tВы выиграли !g%d !tбычков", g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN]);
					//jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN], 1);
					jbe_set_butt(id, jbe_get_butt(id) +  g_iAllCvars[ADWERD_FOR_LOXOTRON_WIN]);
					emit_sound(id, CHAN_AUTO, "jb_engine/other/woohoo2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				}
				
				
				
				if(shans >50 && shans <100 && get_login(id))
				{
					if(jbe_playersnum(1) >= 5)
					{
						if(jbe_mysql_stats_systems_get(id, 77) <= get_cvar_num("jbe_quest_loxotron"))
						{
							jbe_mysql_stats_systems_add(id, 77, jbe_mysql_stats_systems_get(id, 77) + 1);
						}
					}else UTIL_SayText(id, "!g[Лохотрон] !tКвест не засчиталось так как мало зеков. Необходимо больше или равно 5-и зеку");
				}
				
			
				//Linial(id);
				SetBit(g_iBitUserusedLox, id);
		}
				
		case 1: UTIL_SayText(id, "!g[Лохотрон] !tНе хотите - как хотите");
			
		case 9: return client_cmd(id, "jbe_pnmenu");
	}
	
	return PLUGIN_HANDLED;
}
