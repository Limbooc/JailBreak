#include <amxmodx>
#include <center_msg_fix>
#include <reapi>
#include <fun>
#include <amxmisc>
#include <jbe_core>
#include <fakemeta>
//#include <gamecms5>

new g_iGlobalDebug;
#include <util_saytext>
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define AUTO_GIVE_FREE
#define PrunedDays 10



#define TASK_PLAYER_NO_WEAPON 98787567
#define TASK_ROUND_TIME  98787667
#define ROULETTE_MONEY  		2

#define FREE_GRAVITY 0.9
#define FREE_SPEED 300
#define LONG_JUMPTIME 15.0
#define HIGH_JUMPTIME 15.0

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)
#define PLAYERS_PER_PAGE 8
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))
#define itemKey(%0) 							iKeys |= (1<<%0)

native jbe_mysql_set_exp(id, iType, set);
native jbe_mysql_get_exp(id, iType);

native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);

native jbe_is_user_flags(i, iType)
native jbe_is_user_duel(pId);
native jbe_get_soccergame();
native jbe_set_user_godmode(pId, bType);
native jbe_globalnyizapret();
native jbe_all_users_wanted();
native jbe_get_friendlyfire();
native jbe_iduel_status();

native jbe_give_strip_nade(pId);
native jbe_give_wh_nade(pId);


forward jbe_reset_all_user_flags(bool:status);
forward jbe_lr_duels();

native jbe_playersnum(iType);
native jbe_show_adminmenu(pId);



new g_iBitUserVip;

native jbe_restartgame()





/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1];


#define LEVEL_ZERO			0
#define LEVEL_ONE			1
#define LEVEL_TWO 			2
#define LEVEL_THREE			3
#define LEVEL_FOUR			4

new g_iVipStatus[MAX_PLAYERS + 1];
new bool:g_iStatusSpeed[MAX_PLAYERS + 1];
new bool:g_iStatusGravity[MAX_PLAYERS + 1];
new bool:g_iStatusSilteSteps[MAX_PLAYERS +1];

native jbe_set_user_model_ex(pId, iType);

new g_iUserInfoVip[MAX_PLAYERS + 1];


new g_iBitUserSpeed,
	g_iBitUserGravity,
	g_iBitUserSilentSteps,
	g_iBitUserNoWeapon,
	
	g_iBitUserHitZone,
	g_iBitUserRoulleteBhop,
	g_iBitUserRoulleteBychki,
	g_iBitUserRoulleteMoney,
	g_iBitUserRoulleteFreeDay,
	g_iBitUserUseRoullete,
	g_iBitUserParachute,
	g_iBitUserLongJump,
	g_iBitUserHighJump,
	g_iBitUserGodMode,
	g_iBitUserDontAttacked,
	g_iBitUserFF;
	
new g_iBitUserDontWantedForSpeed,
	g_iBitUserDontWantedForGravity;

enum _: eData_Flags
{
	Flags_Vips_Zero = 0,
	Flags_Vips_One,
	Flags_Vips_Two,
	Flags_Vips_Three

};
new g_iFlags[ eData_Flags ];
new bool:g_iRouneTimeEnd;

new g_iVipRespawn[MAX_PLAYERS + 1],
	g_iVipSpeed[MAX_PLAYERS + 1],
	g_iVipGravity[MAX_PLAYERS + 1],
	g_iVipMoney[MAX_PLAYERS + 1],
	g_iVipHealth[MAX_PLAYERS + 1],
	g_iVipPlayerRespawn[MAX_PLAYERS + 1],
	g_iVipSkin[MAX_PLAYERS + 1],
	g_iVipExpMoney[MAX_PLAYERS + 1],
	g_iVipRoulette[MAX_PLAYERS + 1],
	g_iVipGodModeChief[MAX_PLAYERS + 1];
	
new sprite2;


/* -> Индексы общих настроек для кваров -> */
enum _:CVARS_COUNT
{
	VIP_RESPAWN_ONE = 0,
	VIP_RESPAWN_TWO,
	VIP_RESPAWN_THREE,

	VIP_SPEED_ONE,
	VIP_SPEED_TWO,
	VIP_SPEED_THREE,
	
	VIP_GRAVITY_ONE,
	VIP_GRAVITY_TWO,
	VIP_GRAVITY_THREE,
	
	VIP_MONEY_ONE,
	VIP_MONEY_TWO,
	VIP_MONEY_THREE,
	
	VIP_EXP_ONE,
	VIP_EXP_TWO,
	VIP_EXP_THREE,
	VIP_EXP_MONEY_COUNT,
	
	VIP_RESPAWN_PLAYER_ONE,
	VIP_RESPAWN_PLAYER_TWO,
	VIP_RESPAWN_PLAYER_THREE,
	
	VIP_HEALTH_FREE,
	VIP_HEALTH_ONE,
	VIP_HEALTH_TWO,
	VIP_HEALTH_THREE,
	
	VIP_SKIN_ONE,
	VIP_SKIN_TWO,
	VIP_SKIN_THREE,
	
	VIP_EXPMONEY_FREE_ROUND,
	VIP_EXPMONEY_ONE_ROUND,
	VIP_EXPMONEY_TWO_ROUND,
	VIP_EXPMONEY_THREE_ROUND,
	
	VIP_ROULETTE_ONE,
	VIP_ROULETTE_TWO,
	VIP_ROULETTE_THREE,
	
	VIP_GRAVITY_FREE,
	VIP_SPEED_FREE,
	
	VIP_GODMODE_ONE,
	VIP_GODMODE_TWO,
	VIP_GODMODE_THREE,
	
	VIP_LONG_JUMP_LEVEL,
	VIP_HIGH_JUMP_LEVEL,
	VIP_PARACHUTE_LEVEL,
	VIP_HOOK_LEVEL
	
}

new g_iAllCvars[CVARS_COUNT];


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


public plugin_init()
{
	register_plugin("[JBE] VipMenu", "2.0", "DalgaPups");
	
	register_clcmd("say /vipka", "open_vipmenu");
	
	//register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");
	//register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 				"HookResetMaxSpeed", 					false);
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1" )
	
	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	
	RegisterMenu("Show_MainVipMenu", 					"Handle_MainVipMenu");
	RegisterMenu("Show_MainVip2Menu", 					"Handle_MainVip2Menu");
	RegisterMenu("Show_TransferMenu",  					"Handle_TransferMenu");
	RegisterMenu("Show_SpawnPlayer",  					"Handle_SpawnPlayer");
	RegisterMenu("Show_RouletteMenu",  					"Handle_RouletteMenu");
	RegisterMenu("Show_InfoVip",  						"Handle_InfoVip");
	
	
	
	
	#undef RegisterMenu
	
	RegisterHookChain(RG_CBasePlayer_Jump, 							"HC_CBasePlayer_PlayerJump_Post", 	.post = true);
	RegisterHookChain(RG_PM_AirMove, 								"PM_AirMove", 						.post = false);
	
	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 					"HC_CBasePlayer_TakeDamage_Player", 	false);
	
	


	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public plugin_cfg()
{
	jbe_get_cvars();
}

public open_vipmenu(pId) return Show_MainVipMenu(pId);

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, "jb_engine/other/woohoo2.wav");
	sprite2 = engfunc(EngFunc_PrecacheModel, "sprites/333.spr");
	//g_axcid = precache_model("sprites/jb_engine/acid_pou.spr");


}

public plugin_natives()
{
	register_native("jbe_is_user_dont_attacked", "jbe_is_user_dont_attacked", true);
	register_native("jbe_open_vipmenu", "jbe_open_vipmenu", true);
	register_native("jbe_open_infovip", "jbe_open_infovip", true);
	register_native("jbe_is_user_vip", "jbe_is_user_vip", true);
	register_native("jbe_vip_is_user_speed", "jbe_vip_is_user_speed", true);
}

public jbe_is_user_vip(pId) return g_iVipStatus[pId];
public jbe_vip_is_user_speed(pId) return IsSetBit(g_iBitUserSpeed, pId);
public jbe_open_infovip(pId) return Show_InfoVip(pId);
public jbe_open_vipmenu(pId) return Show_MainVipMenu(pId);
public jbe_is_user_dont_attacked(pId) 
{
	if(IsSetBit(g_iBitUserDontWantedForGravity, pId) || IsSetBit(g_iBitUserDontWantedForSpeed, pId) || IsSetBit(g_iBitUserDontAttacked, pId))
	return true;
	else return false;
}

new szFlags[ 10 ];
/*===== -> Квары -> =====*///{

public jbe_get_cvars()
{
	new pcvar;
	
	pcvar = create_cvar("jbe_access_flag_vip_free", "t", FCVAR_SERVER, "");
	bind_pcvar_string(pcvar, szFlags, charsmax( szFlags ) ); 

	g_iFlags[ Flags_Vips_Zero ] = read_flags( szFlags );
	
	pcvar = create_cvar( "jbe_access_flag_vip_one", "t", FCVAR_SERVER, "");
	bind_pcvar_string(pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ Flags_Vips_One ] = read_flags( szFlags );
	
	pcvar = create_cvar( "jbe_access_flag_vip_two", "k", FCVAR_SERVER, "");
	bind_pcvar_string(pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ Flags_Vips_Two ] = read_flags( szFlags );
	
	pcvar = create_cvar( "jbe_access_flag_vip_three", "q", FCVAR_SERVER, "");
	bind_pcvar_string(pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ Flags_Vips_Three ] = read_flags( szFlags );
	

	pcvar = create_cvar("jbe_vip_count_gravity_one", "0.8", FCVAR_SERVER, "");
	bind_pcvar_float(pcvar, Float:g_iAllCvars[VIP_GRAVITY_ONE]); 
	pcvar = create_cvar("jbe_vip_count_gravity_two", "0.6", FCVAR_SERVER, "");
	bind_pcvar_float(pcvar, Float:g_iAllCvars[VIP_GRAVITY_TWO]); 
	pcvar = create_cvar("jbe_vip_count_gravity_three", "0.4", FCVAR_SERVER, "");
	bind_pcvar_float(pcvar, Float:g_iAllCvars[VIP_GRAVITY_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_respawn_one", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_ONE]); 

	pcvar = create_cvar("jbe_vip_count_respawn_two", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_respawn_three", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_THREE]); 

	pcvar = create_cvar("jbe_vip_count_speed_one", "300", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SPEED_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_speed_two", "350", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SPEED_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_speed_three", "400", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SPEED_THREE]); 


	pcvar = create_cvar("jbe_vip_count_money_one", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_MONEY_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_money_two", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_MONEY_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_money_three", "30", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_MONEY_THREE]); 

	pcvar = create_cvar("jbe_vip_count_exp_one", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXP_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_exp_two", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXP_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_exp_three", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXP_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_exp_money", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXP_MONEY_COUNT]); 

	pcvar = create_cvar("jbe_vip_count_respawnplayer_one", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_PLAYER_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_respawnplayer_two", "24", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_PLAYER_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_respawnplayer_three", "100", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_PLAYER_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_healt_free_round", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HEALTH_FREE]); 
	
	pcvar = create_cvar("jbe_vip_count_healt_one_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HEALTH_ONE]);
	
	pcvar = create_cvar("jbe_vip_count_healt_two_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HEALTH_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_healt_three_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HEALTH_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_expmoney_free_round", "6", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXPMONEY_FREE_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_count_expmoney_one_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXPMONEY_ONE_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_count_expmoney_two_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXPMONEY_TWO_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_count_expmoney_three_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_EXPMONEY_THREE_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_count_roulette_one_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_ROULETTE_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_roulette_two_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_ROULETTE_TWO]); 
	
	pcvar = create_cvar("jbe_vip_count_roulette_three_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_ROULETTE_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_skin_one_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SKIN_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_skin_two_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SKIN_TWO]); 
	pcvar = create_cvar("jbe_vip_count_skin_three_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SKIN_THREE]); 
	
	pcvar = create_cvar("jbe_vip_count_gravity_free_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_GRAVITY_FREE]); 
	
	pcvar = create_cvar("jbe_vip_count_speed_free_round", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_SPEED_FREE]); 
	
	pcvar = create_cvar("jbe_vip_count_godmode_one_round", "6", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_GODMODE_ONE]); 
	
	pcvar = create_cvar("jbe_vip_count_godmode_two_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_GODMODE_TWO]); 
	pcvar = create_cvar("jbe_vip_count_godmode_three_round", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_GODMODE_THREE]); 
	
	pcvar = create_cvar("jbe_vip_high_jump_level", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HIGH_JUMP_LEVEL]); 
	
	pcvar = create_cvar("jbe_vip_long_jump_level", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_LONG_JUMP_LEVEL]); 
	
	pcvar = create_cvar("jbe_vip_parachute_level", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_PARACHUTE_LEVEL]);
	
	pcvar = create_cvar("jbe_vip_hook_level", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HOOK_LEVEL]);
	
	AutoExecConfig(true, "Jail_VipMenu");
	
	
	
	
}


public client_putinserver(pId)
{
	g_iVipStatus[pId] = LEVEL_ZERO;
	ClearBit(g_iBitUserVip, pId);
	new iFlags = get_user_flags(pId);
	//if(iFlags & g_iFlags[ Flags_Vips_Zero ]) 
	//{
		//SetBit(g_iBitUserVip, pId);
		//g_iVipStatus[pId] = LEVEL_ONE;
		if(iFlags & g_iFlags[ Flags_Vips_One ])
		{
			SetBit(g_iBitUserVip, pId);
			g_iVipStatus[pId] = LEVEL_TWO;
			if(iFlags & g_iFlags[ Flags_Vips_Two ])
			{
				g_iVipStatus[pId] = LEVEL_THREE;
				if(iFlags & g_iFlags[ Flags_Vips_Three ])
				{
					g_iVipStatus[pId] = LEVEL_FOUR;
				}
			}
		}
	//}
	
	

}

public frallion_access_user(pId, szFlags[])
{
	//g_iVipStatus[pId] = LEVEL_ZERO;
	//ClearBit(g_iBitUserVip, pId);
	new iFlags = read_flags(szFlags);
	//if(iFlags & g_iFlags[ Flags_Vips_Zero ]) 
	//{
	//SetBit(g_iBitUserVip, pId);
	//g_iVipStatus[pId] = LEVEL_ONE;
	if(iFlags & g_iFlags[ Flags_Vips_One ])
	{
		SetBit(g_iBitUserVip, pId);
		g_iVipStatus[pId] = LEVEL_TWO;
		if(iFlags & g_iFlags[ Flags_Vips_Two ])
		{
			g_iVipStatus[pId] = LEVEL_THREE;
			if(iFlags & g_iFlags[ Flags_Vips_Three ])
			{
				g_iVipStatus[pId] = LEVEL_FOUR;
			}
		}
	}
}


public OnAPIAdminConnected(pId, const szName[], adminID, iFlags)
{
	g_iVipStatus[pId] = LEVEL_ZERO;
	ClearBit(g_iBitUserVip, pId);
	//new iFlags = get_user_flags(pId);
	if(iFlags & g_iFlags[ Flags_Vips_Zero ]) 
	{
		SetBit(g_iBitUserVip, pId);
		g_iVipStatus[pId] = LEVEL_ONE;
		if(iFlags & g_iFlags[ Flags_Vips_One ])
		{
			g_iVipStatus[pId] = LEVEL_TWO;
			if(iFlags & g_iFlags[ Flags_Vips_Two ])
			{
				g_iVipStatus[pId] = LEVEL_THREE;
				if(iFlags & g_iFlags[ Flags_Vips_Three ])
				{
					g_iVipStatus[pId] = LEVEL_FOUR;
				}
			}
		}
	}
}




/*public OnAPIMemberConnected(id, memberId, memberName[])
{
	#if defined AUTO_GIVE_FREE
	

	
	
	new g_UserId = cmsapi_get_user_group(id, "", 0);
	if(g_UserId == 2 && !cmsapi_get_user_services(id, "", "motq", 0, true))
	{
		new p_gametime = get_systime();
		new UNIXTIME = cmsapi_get_user_regdate(id);

		if(UNIXTIME > 0 && (UNIXTIME > (p_gametime - (PrunedDays * 86400))))
		{

			SetBit(g_iBitUserVip, id);
			g_iVipStatus[id] = LEVEL_TWO;
		}
	}
	
	#endif
}*/


//forward jbe_fwr_logevent_startround();
public Event_HLTV()
{
	g_iBitUserSpeed = 0;
	g_iBitUserGravity = 0;
	g_iBitUserSilentSteps = 0;
	g_iBitUserNoWeapon = 0;
	
	g_iBitUserHitZone = 0;
	g_iBitUserRoulleteBhop = 0;
	g_iBitUserRoulleteBychki = 0;
	g_iBitUserRoulleteMoney = 0;
	g_iBitUserRoulleteFreeDay = 0;
	
	g_iBitUserHighJump = 0;
	g_iBitUserLongJump = 0;
	g_iBitUserGodMode = 0;
	
	g_iBitUserUseRoullete = 0;
	g_iBitUserDontAttacked = 0;
	g_iBitUserFF = 0;
	
	g_iBitUserDontWantedForGravity = 0;
	g_iBitUserDontWantedForSpeed = 0;
	
	if(jbe_restartgame()) return;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i)) continue;
		if(IsNotSetBit(g_iBitUserVip, i)) continue;

		
		g_iVipRespawn[i] = jbe_get_vip_level(i, 0);
		g_iVipPlayerRespawn[i] = jbe_get_vip_level(i, 5);
		g_iVipSpeed[i]++;
		g_iVipGravity[i]++;
		g_iVipMoney[i]++;
		g_iVipHealth[i]++;
		g_iVipExpMoney[i]++;
		g_iVipSkin[i]++;
		g_iVipRoulette[i]++;
		//server_print("%d", g_iVipSkin[i])
		
		if(g_iStatusSpeed[i]) g_iStatusSpeed[i] = false;
		if(g_iStatusGravity[i]) g_iStatusGravity[i] = false;
		if(g_iStatusSilteSteps[i]) g_iStatusSilteSteps[i] = false;
		
		
		if(jbe_get_user_team(i) != 2) continue;
		g_iVipGodModeChief[i] ++;
		
		
	}
	
	new Float:Time = get_cvar_float("mp_roundtime") * 60.0;
	
	if(task_exists(TASK_ROUND_TIME)) remove_task(TASK_ROUND_TIME);
	g_iRouneTimeEnd = false;
	set_task(Time, "jbe_task_end_rountime", TASK_ROUND_TIME);
	
	
	
}

public jbe_task_end_rountime() 
{
	g_iRouneTimeEnd = true;
	
	set_dhudmessage(255, 255, 255, -1.0, 0.67, 0, 6.0, 5.0);
	show_dhudmessage(0, "На таймере 0:0^nнекоторые функции ограничены");
}

public client_disconnected(pId)
{
	if(!is_user_connected(pId)) return;

	if(IsSetBit(g_iBitUserVip, pId))
	{
		g_iVipStatus[pId] = LEVEL_ZERO;
		ClearBit(g_iBitUserVip, pId);
	

		ClearBit(g_iBitUserSpeed, pId);
		ClearBit(g_iBitUserGravity, pId);
		ClearBit(g_iBitUserSilentSteps, pId);
		ClearBit(g_iBitUserNoWeapon, pId);
		ClearBit(g_iBitUserHitZone, pId);
		ClearBit(g_iBitUserRoulleteBhop, pId);
		ClearBit(g_iBitUserRoulleteBychki, pId);
		ClearBit(g_iBitUserRoulleteMoney, pId);
		ClearBit(g_iBitUserRoulleteFreeDay, pId);
		ClearBit(g_iBitUserUseRoullete, pId);
		ClearBit(g_iBitUserGodMode, pId);
		ClearBit(g_iBitUserLongJump, pId);
		ClearBit(g_iBitUserHighJump, pId);
		ClearBit(g_iBitUserDontAttacked, pId);
		ClearBit(g_iBitUserFF, pId);
		ClearBit(g_iBitUserDontWantedForGravity, pId);
		ClearBit(g_iBitUserDontWantedForSpeed, pId);
		
		if(task_exists(pId + TASK_PLAYER_NO_WEAPON)) remove_task(pId + TASK_PLAYER_NO_WEAPON);
		
		if(g_iStatusSpeed[pId]) g_iStatusSpeed[pId] = false;
		if(g_iStatusGravity[pId]) g_iStatusGravity[pId] = false;
		if(g_iStatusSilteSteps[pId]) g_iStatusSilteSteps[pId] = false;
	}
}

forward jbe_fwr_roundend();
public jbe_fwr_roundend()
{
	if(jbe_restartgame()) return;
	
	g_iBitUserGodMode = 0;
	g_iBitUserLongJump = 0;
	g_iBitUserHighJump = 0;
	g_iBitUserSpeed = 0;
	g_iBitUserGravity = 0;
	g_iBitUserSilentSteps = 0;
	g_iBitUserDontWantedForGravity = 0;
	g_iBitUserDontWantedForSpeed = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i)) continue;
		if(IsNotSetBit(g_iBitUserVip, i)) continue;

		if(g_iStatusSpeed[i]) g_iStatusSpeed[i] = false;
		if(g_iStatusGravity[i]) g_iStatusGravity[i] = false;
		if(g_iStatusSilteSteps[i]) g_iStatusSilteSteps[i] = false;
		
		if(IsNotSetBit(g_iBitUserUseRoullete, i)) continue;
		
		
		if(task_exists(i + TASK_PLAYER_NO_WEAPON)) 
		{
			rg_give_item(i, "weapon_knife");
			remove_task(i + TASK_PLAYER_NO_WEAPON);
		}
		
		ClearBit(g_iBitUserNoWeapon, i);
		ClearBit(g_iBitUserHitZone, i);
		ClearBit(g_iBitUserRoulleteBhop, i);
		ClearBit(g_iBitUserRoulleteBychki, i);
		ClearBit(g_iBitUserRoulleteMoney,  i);
		ClearBit(g_iBitUserRoulleteFreeDay, i);
		
		ClearBit(g_iBitUserUseRoullete, i);
		
		
		
	}
	
	g_iRouneTimeEnd = false;
}

public jbe_lr_duels()
{
	reset_players();
	
	g_iBitUserDontWantedForGravity = 0;
	g_iBitUserDontWantedForSpeed = 0;
	g_iBitUserDontAttacked = 0;
}

public jbe_reset_all_user_flags(bool:status)
{
	if(status)
	{
		reset_players();
		UTIL_SayText(0, "!g* !yВключен глобальный режим, !gVIP !yпреимущества для зеков были сброшены!");
	}
}

stock reset_players()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i)) continue;
		if(IsNotSetBit(g_iBitUserVip, i)) continue;
		
		if(g_iStatusSpeed[i]) g_iStatusSpeed[i] = false;
		if(g_iStatusGravity[i]) g_iStatusGravity[i] = false;
		if(g_iStatusSilteSteps[i]) g_iStatusSilteSteps[i] = false;
		
		ClearBit(g_iBitUserSpeed, i);
		ClearBit(g_iBitUserGravity, i);
		ClearBit(g_iBitUserSilentSteps, i);
		ClearBit(g_iBitUserNoWeapon, i);
		ClearBit(g_iBitUserHitZone, i);
		
		ClearBit(g_iBitUserDontWantedForGravity, i);
		ClearBit(g_iBitUserDontWantedForSpeed, i);
		ClearBit(g_iBitUserDontAttacked, i);
		
		
		rg_reset_maxspeed(i);
		set_entvar(i, var_gravity, 1.0);
		rg_set_user_footsteps(i, false);
		
		ClearBit(g_iBitUserUseRoullete, i);
		ClearBit(g_iBitUserGodMode, i);
		ClearBit(g_iBitUserLongJump, i);
		ClearBit(g_iBitUserHighJump, i);
		
		
		if(IsNotSetBit(g_iBitUserUseRoullete, i)) continue;
		
		
		if(task_exists(i + TASK_PLAYER_NO_WEAPON)) 
		{
			rg_give_item(i, "weapon_knife");
			remove_task(i + TASK_PLAYER_NO_WEAPON);
		}
		
		ClearBit(g_iBitUserRoulleteBhop, i);
		ClearBit(g_iBitUserRoulleteBychki, i);
		ClearBit(g_iBitUserRoulleteMoney,  i);
		ClearBit(g_iBitUserRoulleteFreeDay, i);
		
	}
}

Show_InfoVip(pId)
{
	
	new szMenu[512], iLen, iKeys;
	
	
	FormatMain("\yИнформации о Vip - статусах^n^n");
	
	FormatItem("\y1.w %d уровень^n", g_iUserInfoVip[pId]), itemKey(0)
	
	switch(g_iUserInfoVip[pId])
	{
		case 0: 
		{
			FormatItem("^t^t\dГравитация %.1f ^n" , FREE_GRAVITY);
			FormatItem("^t^t\dСкорость %dunts.^n" , FREE_SPEED);
			FormatItem("^t^t\d+1 Бчк. и +5 Опыт (раз %d рнд.)^n" ,g_iAllCvars[VIP_EXPMONEY_FREE_ROUND]);
			FormatItem("^t^t\d200 ХП \y|Зек|Охрана|Начальника (раз %d рнд.)^n" ,g_iAllCvars[VIP_HEALTH_FREE]);
			FormatItem("%s" ,g_iAllCvars[VIP_LONG_JUMP_LEVEL] == LEVEL_ONE ? "^t^t\dДлинный прыжок ^n" : "^n");
			FormatItem("%s" ,g_iAllCvars[VIP_HIGH_JUMP_LEVEL] == LEVEL_ONE ? "^t^t\dВысокий прыжок ^n" : "^n");
		}
		case 1: 
		{
			FormatItem("^t^t\dГравитация \y|ON|OFF| (раз %d рнд.)^n" ,Float:g_iAllCvars[VIP_GRAVITY_ONE]);
			FormatItem("^t^t\dСкорость \y|ON|OFF| (раз %d рнд.)^n" ,g_iAllCvars[VIP_SPEED_ONE]);
			FormatItem("^t^t\dБычки и Опыт \y|+1Exp|+5Бчк.| (раз %d рнд.)^n" ,g_iAllCvars[VIP_EXPMONEY_ONE_ROUND]);
			FormatItem("^t^t\d%d ХП (раз %d рнд.)^n" ,g_iAllCvars[VIP_HEALTH_ONE], g_iAllCvars[VIP_HEALTH_ONE]);
			FormatItem("^t^t\dВозрадить (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_ONE]);
			FormatItem("^t^t\dФорма зека (раз %d рнд.)^n" ,g_iAllCvars[VIP_SKIN_ONE]);
			FormatItem("^t^t\dРулетка (раз %d рнд.)^n" ,g_iAllCvars[VIP_ROULETTE_ONE]);
			FormatItem("^t^t\dПеревод охраны^n");
			FormatItem("^t^t\dВозрадить зека (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_PLAYER_ONE]);
			FormatItem("^t^t\dБесшумные шаги \y|ON|OFF|^n");
			FormatItem("^t^t\dБесмертие начальника (раз %d рнд.)^n" ,g_iAllCvars[VIP_GODMODE_ONE]);
			FormatItem("%s" ,g_iAllCvars[VIP_LONG_JUMP_LEVEL] == LEVEL_TWO ? "^t^t\dДлинный прыжок ^n" : "^n");
			FormatItem("%s" ,g_iAllCvars[VIP_HIGH_JUMP_LEVEL] == LEVEL_TWO ? "^t^t\dВысокий прыжок ^n" : "^n");
		}
		case 2: 
		{
			FormatItem("^t^t\dГравитация \y|ON|OFF| (раз %d рнд.)^n" ,Float:g_iAllCvars[VIP_GRAVITY_TWO]);
			FormatItem("^t^t\dСкорость \y|ON|OFF| (раз %d рнд.)^n" , g_iAllCvars[VIP_SPEED_TWO]);
			FormatItem("^t^t\dБычки и Опыт \y|+1Exp|+5Бчк.| (раз %d рнд.)^n" ,g_iAllCvars[VIP_EXPMONEY_TWO_ROUND]);
			FormatItem("^t^t\d%d ХП (раз %d рнд.)^n" ,g_iAllCvars[VIP_HEALTH_TWO], g_iAllCvars[VIP_HEALTH_TWO]);
			FormatItem("^t^t\dВозрадить (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_TWO]);
			FormatItem("^t^t\dФорма зека (раз %d рнд.)^n" ,g_iAllCvars[VIP_SKIN_TWO]);
			FormatItem("^t^t\dРулетка (раз %d рнд.)^n" ,g_iAllCvars[VIP_ROULETTE_TWO]);
			FormatItem("^t^t\dПеревод охраны^n");
			FormatItem("^t^t\dВозрадить зека (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_PLAYER_TWO]);
			FormatItem("^t^t\dБесшумные шаги \y|ON|OFF|^n");
			FormatItem("^t^t\dБесмертие начальника (раз %d рнд.)^n" ,g_iAllCvars[VIP_GODMODE_TWO]);
			FormatItem("%s" ,g_iAllCvars[VIP_LONG_JUMP_LEVEL] == LEVEL_THREE ? "^t^t\dДлинный прыжок ^n" : "^n");
			FormatItem("%s" ,g_iAllCvars[VIP_HIGH_JUMP_LEVEL] == LEVEL_THREE ? "^t^t\dВысокий прыжок ^n" : "^n");
		}
		case 3: 
		{
			FormatItem("^t^t\dГравитация \y|ON|OFF| (раз %d рнд.)^n" ,Float:g_iAllCvars[VIP_GRAVITY_THREE]);
			FormatItem("^t^t\dСкорость \y|ON|OFF| (раз %d рнд.)^n" , g_iAllCvars[VIP_SPEED_THREE]);
			FormatItem("^t^t\dБычки и Опыт \y|+1Exp|+5Бчк.| (раз %d рнд.)^n" ,g_iAllCvars[VIP_EXPMONEY_THREE_ROUND]);
			FormatItem("^t^t\d%d ХП (раз %d рнд.)^n" ,g_iAllCvars[VIP_HEALTH_THREE], g_iAllCvars[VIP_HEALTH_THREE]);
			FormatItem("^t^t\dВозрадить (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_THREE]);
			FormatItem("^t^t\dФорма зека (раз %d рнд.)^n" ,g_iAllCvars[VIP_SKIN_THREE]);
			FormatItem("^t^t\dРулетка (раз %d рнд.)^n" ,g_iAllCvars[VIP_ROULETTE_THREE]);
			FormatItem("^t^t\dПеревод охраны^n");
			FormatItem("^t^t\dВозрадить зека (%d раз за рнд.)^n" ,g_iAllCvars[VIP_RESPAWN_PLAYER_THREE]);
			FormatItem("^t^t\dБесшумные шаги \y|ON|OFF|^n");
			FormatItem("^t^t\dБесмертие начальника (раз %d рнд.)^n" ,g_iAllCvars[VIP_GODMODE_THREE]);
			FormatItem("%s" ,g_iAllCvars[VIP_LONG_JUMP_LEVEL] == LEVEL_FOUR ? "^t^t\dДлинный прыжок ^n" : "^n");
			FormatItem("%s" ,g_iAllCvars[VIP_HIGH_JUMP_LEVEL] == LEVEL_FOUR ? "^t^t\dВысокий прыжок ^n" : "^n");
		}
	}
	FormatItem("\y0. \wВыход"), itemKey(9);
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_InfoVip");
}

public Handle_InfoVip(pId, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			g_iUserInfoVip[pId]++;
			if(g_iUserInfoVip[pId] > 4)
				g_iUserInfoVip[pId] = 0;
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_InfoVip(pId);
}


Show_MainVipMenu(pId)
{
	new szMenu[512], iLen, iKeys;

	
	
	new iTeam = jbe_get_user_team(pId);
	new Float:Health;
	
	switch(iTeam)
	{
		case 1: Health = 200.0;
		case 2: 
		{
			if(jbe_is_user_chief(pId)) Health = 500.0;
			else Health = 255.0;
		}
	}
			
	FormatMain("\wVip Menu \y1/2^n\wУровень VIP: \d%d^n^n", g_iVipStatus[pId]);

	if(g_iVipStatus[pId] > LEVEL_ONE && !jbe_is_user_alive(pId) && g_iVipRespawn[pId])
	{
		FormatItem("\y1. \wВоскреснуть \y(%d)^n", g_iVipRespawn[pId]), itemKey(0);
	}else FormatItem("\y1. \dВоскреснуть \y(%d)^n", g_iVipRespawn[pId]);
	
	if(g_iVipStatus[pId] && jbe_is_user_alive(pId) && g_iVipHealth[pId] >= jbe_get_vip_level(pId, 6)) 
	{
		
		FormatItem("\y2. \w%d ХП^n", floatround(Health)), itemKey(1);
	}
	else 
	{
		if(g_iVipStatus[pId])
		{
		
			new iCount = (jbe_get_vip_level(pId, 6) - g_iVipHealth[pId]);
			if(iCount < 0) iCount = 1;
			FormatItem("\y2. \d%d ХП \y(%d рнд.)^n", floatround(Health), iCount);
			
		}else FormatItem("\y2. \d%d ХП^n", floatround(Health));
	}
	if(jbe_is_user_alive(pId) && g_iVipStatus[pId] == LEVEL_ONE && g_iVipSpeed[pId] >= g_iAllCvars[VIP_SPEED_FREE])
	{
		FormatItem("\y4. \wСкорость в \y%d \wunts. \y%s^n",FREE_SPEED, g_iStatusSpeed[pId] ? "вкл." : "выкл."), itemKey(2);
	}
	else
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && IsNotSetBit(g_iBitUserSpeed, pId))
	{
		FormatItem("\y3. \wСкорость \y%d \wunts. \y%s^n", jbe_get_vip_level(pId, 1), g_iStatusSpeed[pId] ? "вкл." : "выкл."), itemKey(2);
	}else 
	{
		if(g_iVipStatus[pId] == LEVEL_ONE && IsNotSetBit(g_iBitUserSpeed, pId))
		{
			new iCount = (g_iAllCvars[VIP_SPEED_FREE] - g_iVipSpeed[pId]);
			FormatItem("\y3. \dСкорость %d unts. \y(%d рнд.)^n", FREE_SPEED, iCount);
		}else FormatItem("\y3. \dСкорость %d unts. \y%s^n", jbe_get_vip_level(pId, 1), g_iStatusSpeed[pId] ? "вкл." : "выкл.");
	}
	
	if(jbe_is_user_alive(pId) && g_iVipStatus[pId] == LEVEL_ONE && g_iVipGravity[pId] >= g_iAllCvars[VIP_GRAVITY_FREE])
	{
		FormatItem("\y4. \wГравитации \y%.2f \wunts. \y%s^n",FREE_GRAVITY, g_iStatusGravity[pId] ? "вкл." : "выкл."), itemKey(3);
	}
	else
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && IsNotSetBit(g_iBitUserGravity, pId)) 
	{
		FormatItem("\y4. \wГравитации \y%.2f \wunts. \y%s^n", jbe_get_gravity_float(pId), g_iStatusGravity[pId] ? "вкл." : "выкл."), itemKey(3);
	}
	else 
	{
		if(g_iVipStatus[pId] == LEVEL_ONE && IsNotSetBit(g_iBitUserGravity, pId))
		{
			new iCount = (g_iAllCvars[VIP_GRAVITY_FREE] - g_iVipGravity[pId]);
			FormatItem("\y4. \dГравитации %.1f unts. \y(%d рнд.)^n", FREE_GRAVITY, iCount);
		}else FormatItem("\y4. \dГравитации %.1f unts. \y%s^n", jbe_get_gravity_float(pId), g_iStatusGravity[pId] ? "вкл." : "выкл.");
	} 
	
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && g_iVipSkin[pId] >= jbe_get_vip_level(pId, 7) && jbe_get_user_team(pId) == 2) 
	{
		FormatItem("\y5. \wФорма %s^n" , jbe_get_user_team(pId) ? "зека" : "охраны"  ), itemKey(4);
	}
	else 
	{
		if(g_iVipStatus[pId] > LEVEL_ONE && jbe_get_user_team(pId) == 2)
		{
		
			new iCount = (jbe_get_vip_level(pId, 7) - g_iVipSkin[pId]);
			FormatItem("\y5. \dФорма %s \y(%d рнд.)^n" , jbe_get_user_team(pId) ? "зека" : "охраны", iCount);
		}
		else FormatItem("\y5. \dФорма %s^n" , jbe_get_user_team(pId) ? "зека" : "охраны");
	}
	
	if(g_iVipStatus[pId] == LEVEL_ONE && jbe_is_user_alive(pId) && g_iVipExpMoney[pId] >= jbe_get_vip_level(pId, 8) && jbe_playersnum(1) >= 5) 
	{
		FormatItem("\y6. \wОпыт (+5) и бычки (+1)^n"), itemKey(5);
	}
	else
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && g_iVipExpMoney[pId] >= jbe_get_vip_level(pId, 8) && jbe_playersnum(1) >= 5) 
	{
		FormatItem("\y6. \wОпыт (+%d) и бычки (+%d)^n", jbe_get_vip_level(pId, 4), jbe_get_vip_level(pId, 3)), itemKey(5);
	}
	else 
	{
		if(g_iVipStatus[pId] > LEVEL_ONE)
		{
		
			if(jbe_playersnum(1) >= 5)
			{
				new iCount = (jbe_get_vip_level(pId, 8) - g_iVipExpMoney[pId]);
				FormatItem("\y6. \dОпыт и бычки \y(%d рнд.)^n", iCount);
			}
			else FormatItem("\y6. \dОпыт и бычки (мало зека)^n");
		}
		else 
		{
			if(g_iVipStatus[pId] == LEVEL_ONE)
			{
				if(jbe_playersnum(1) >= 5)
				{
					new iCount = (jbe_get_vip_level(pId, 8) - g_iVipExpMoney[pId]);
					FormatItem("\y6. \dОпыт и бычки \y(%d рнд.)^n", iCount);
				}
				else FormatItem("\y6. \dОпыт и бычки (мало зека)^n");
			}
			else FormatItem("\y6. \dОпыт и бычки^n");
		}
	}
	
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && g_iVipRoulette[pId] >= jbe_get_vip_level(pId, 9)) FormatItem("\y7. \wРулетка (разр.)^n ");
	else 
	{
		if(g_iVipStatus[pId] > LEVEL_ONE)
		{
		
			new iCount = (jbe_get_vip_level(pId, 9) - g_iVipRoulette[pId]);
			FormatItem("\y7. \dРулетка \y(%d рнд.)^n",iCount);
		}
		else FormatItem("\y7. \dРулетка \y(4LVL)^n^n");
	}
	
	if(g_iVipStatus[pId] >= LEVEL_THREE) FormatItem("\y8. \wПеревести охрану^n^n"), itemKey(7);
	else FormatItem("\y8. \dПеревести охрану \y(3LVL)^n^n^n");
	
	FormatItem("\y9. \wДалее^n"), itemKey(8);
	FormatItem("\y0. \wНазад"), itemKey(9);

	return show_menu(pId, iKeys, szMenu, -1, "Show_MainVipMenu");
}

public Handle_MainVipMenu(pId, iKey)
{

	
	if(jbe_get_day_mode() > 2) return PLUGIN_HANDLED;
	
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yВключен глобальный режим");
		return PLUGIN_HANDLED;
	}
	
	if(iKey != 7 && (jbe_is_user_duel(pId) || jbe_get_soccergame()))
	{
		UTIL_SayText(pId, "!g* !yВо время дуэли нельзя\футбола");
		return PLUGIN_HANDLED;
	}
	if(jbe_iduel_status())
	{
		UTIL_SayText(pId, "!g* !yИдет дуэль!, воскрешение не доступно!");
		return PLUGIN_HANDLED;
	}
	
	
	
	switch(iKey)
	{
		case 0:
		{
			if(!jbe_is_user_alive(pId) && g_iVipRespawn[pId])
			{
				if(jbe_all_users_wanted())
				{
					UTIL_SayText(pId, "!g* !yЗапрещено рес во время бунта!");
					return PLUGIN_HANDLED;
				}
				if(g_iRouneTimeEnd)
				{
					UTIL_SayText(pId, "!g* !yТаймер равен 0!, вип меню не доступно!");
					return PLUGIN_HANDLED;
				}
				
				PlayerSpawn(pId);
				g_iVipRespawn[pId]--;
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y- !gВоскрес", g_iVipStatus[pId], pId);
			}
		}
		case 1:
		{
			if(jbe_is_user_alive(pId) && g_iVipHealth[pId])
			{
				new iTeam = jbe_get_user_team(pId);
				new Float:Health;
				
				new VipTeam[32]
				
				
				
				switch(iTeam)
				{
					case 1: 
					{
						Health = 200.0;
						VipTeam = "Зек"
					}
					case 2: 
					{
						if(jbe_is_user_chief(pId)) 
						{
							Health = 500.0;
							VipTeam = "Начальник"
						}
						else 
						{
							Health = 255.0;
							VipTeam = "Охрана"
						}
					}
				}
				set_entvar(pId, var_health, Health);
				
				g_iVipHealth[pId] = 0;
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !yвзял: !g%d HP !y(%s)", g_iVipStatus[pId], pId, floatround(Health), VipTeam);
			}
		}
		case 2:
		{
			if(jbe_is_user_alive(pId) && IsNotSetBit(g_iBitUserSpeed, pId))
			{
				g_iStatusSpeed[pId] = !g_iStatusSpeed[pId];
				
				switch(g_iStatusSpeed[pId])
				{
					case true: 
					{
						if(g_iVipStatus[pId] == LEVEL_ONE)
						{
							set_entvar(pId, var_maxspeed, float(FREE_SPEED));
							UTIL_SayText(0, "!g[VIP: %d LVL] !g%n !y%s: !gСкорость", g_iVipStatus[pId], pId, g_iStatusSpeed[pId] ? "взял" : "сбросил");
							g_iVipSpeed[pId] = 0;
							
							
							return 0;
						}
						else set_entvar(pId, var_maxspeed, float(jbe_get_vip_level(pId, 1)));
						
						
						SetBit(g_iBitUserDontWantedForSpeed, pId);
						UTIL_SayText(pId, "!g* !yСо скоростью вы не сможете сбунтануть");
					}
					case false: 
					{
						rg_reset_maxspeed(pId);
						SetBit(g_iBitUserSpeed, pId);
						ClearBit(g_iBitUserDontWantedForSpeed, pId);
					}
				}
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gCкорость",  g_iVipStatus[pId],pId, g_iStatusSpeed[pId] ? "взял" : "сбросил");
			}
		}
		case 3:
		{
			if(jbe_is_user_alive(pId) && IsNotSetBit(g_iBitUserGravity, pId))
			{
				g_iStatusGravity[pId] = !g_iStatusGravity[pId];
				
				switch(g_iStatusGravity[pId])
				{
					case true: 
					{
						if(g_iVipStatus[pId] == LEVEL_ONE)
						{
							set_entvar(pId, var_gravity, FREE_GRAVITY);
							UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gГравитацию",  g_iVipStatus[pId], pId, g_iStatusGravity[pId] ? "взял" : "сбросил");
							g_iVipGravity[pId] = 0;
							
							
							return 0;
						}
						else set_entvar(pId, var_gravity, jbe_get_gravity_float(pId));
						
						
						
						UTIL_SayText(pId, "!g* !yС гравитацией вы не сможете сбунтануть");
					}
						
					case false: 
					{
						set_entvar(pId, var_gravity, 1.0);
						SetBit(g_iBitUserGravity, pId);
						
						
					}
				}
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gГравитацию",  g_iVipStatus[pId],pId, g_iStatusGravity[pId] ? "взял" : "сбросил");
			}
		}
		case 4:
		{
			if(jbe_is_user_alive(pId) && jbe_get_user_team(pId) != 3 && g_iVipSkin[pId])
			{
				new SkinUser;

				switch(jbe_get_user_team(pId))
				{
					case 1: SkinUser = 2;
					case 2: SkinUser = 1;
				}
				jbe_set_user_model_ex(pId, SkinUser);
				g_iVipSkin[pId] = 0;
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !yвзял: !gФорму %s",  g_iVipStatus[pId],pId, jbe_get_user_team(pId) ? "охраны" : "зека");
			}
		}
		case 5:
		{
			
			if(jbe_is_user_alive(pId) && g_iVipExpMoney[pId] && jbe_playersnum(1) >= 5)
			{
				g_iVipExpMoney[pId] = 0;
				
				
				if(g_iVipStatus[pId] == LEVEL_ONE)
				{
					jbe_mysql_set_exp(pId, jbe_get_user_team(pId), jbe_mysql_get_exp(pId, jbe_get_user_team(pId)) + 5);
					jbe_set_butt(pId, jbe_get_butt(pId) + 1);
					
					UTIL_SayText(0, "!g[VIP: FREEVIP] !t%n !yвзял: !g+1 бычков и +5 опыта",  pId);
				}
				else
				{
					jbe_mysql_set_exp(pId, jbe_get_user_team(pId), jbe_mysql_get_exp(pId, jbe_get_user_team(pId)) + jbe_get_vip_level(pId, 4));
					jbe_set_butt(pId, jbe_get_butt(pId) + jbe_get_vip_level(pId, 3));
					
					UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !yвзял: !g%d бычков и %d опыта",  g_iVipStatus[pId],pId, jbe_get_vip_level(pId, 3), jbe_get_vip_level(pId, 4));
				}
			}
		
		}
		case 6:
		{
			return Show_RouletteMenu(pId);
			
		}
		
		case 7: return Cmd_TransferMenu(pId);
		
		case 8: return Show_MainVip2Menu(pId);
		case 9: return jbe_show_adminmenu(pId);
	}

	return Show_MainVipMenu(pId);
}

Show_MainVip2Menu(pId)
{
	new szMenu[512], iLen, iKeys;
	

	FormatMain("\wVip Menu \y2/2^n\wУровень VIP: \y%d^n^n", g_iVipStatus[pId]);
	
	if(g_iVipStatus[pId] > LEVEL_ONE && g_iVipPlayerRespawn[pId])
	{
		FormatItem("\y1. \wВозродить зека \y(%d)^n", g_iVipPlayerRespawn[pId]), itemKey(0);
	}else  FormatItem("\y1. \dВозрадить зека^n");
	
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId))
	{
		FormatItem("\y2. \wБесшумные шаги \y%s^n", IsSetBit(g_iBitUserSilentSteps, pId) ? "вкл." : "выкл."), itemKey(1);
	}else FormatItem("\y2. \dБесшумные шаги \y%s^n",IsSetBit(g_iBitUserSilentSteps, pId) ? "вкл." : "выкл.");
	
	if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && jbe_is_user_chief(pId) && g_iVipGodModeChief[pId] >= jbe_get_vip_level(pId, 10) && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitUserGodMode, pId))
	{
		FormatItem("\y3. \wБесмертие для начальника^n"), itemKey(2);
	}
	else 
	{
		FormatItem("\y3. \dБесмертие для начальника^n");
	}
	
	
	if(g_iVipStatus[pId]  >= g_iAllCvars[VIP_LONG_JUMP_LEVEL]) FormatItem("\y5. %sДлинный прыжок \y%s^n", jbe_is_user_alive(pId) ? "\w" : "\d", IsSetBit(g_iBitUserLongJump, pId) ? "вкл." : "выкл."), itemKey(4);
	else FormatItem("\y5. \dДлинный прыжок \y(%d LVL)^n", g_iAllCvars[VIP_LONG_JUMP_LEVEL]);

	if(g_iVipStatus[pId]  >= g_iAllCvars[VIP_HIGH_JUMP_LEVEL]) FormatItem("\y6. %sВысокий прыжок \y%s^n", jbe_is_user_alive(pId) ? "\w" : "\d", IsSetBit(g_iBitUserHighJump, pId) ? "вкл." : "выкл."), itemKey(5);
	else FormatItem("\y6. \dВысокий прыжок \y(%d LVL)^n", g_iAllCvars[VIP_HIGH_JUMP_LEVEL]);
	
	if(g_iVipStatus[pId]  >= g_iAllCvars[VIP_HIGH_JUMP_LEVEL]) 
	{
		if(jbe_get_user_team(pId) == 2)FormatItem("\y7. %sПаразитирующая дым.граната^n", jbe_is_user_alive(pId) ? "\w" : "\d"), itemKey(6);
		else FormatItem("\y7. \dПаразитирующая дым.граната \r(для охран)^n");
	}else FormatItem("\y7. \dПаразитирующая граната \y(%d LVL)^n", g_iAllCvars[VIP_HIGH_JUMP_LEVEL]);
	
	if(g_iVipStatus[pId]  >= g_iAllCvars[VIP_HIGH_JUMP_LEVEL]) 
	{
		if(jbe_get_user_team(pId) == 2)FormatItem("\y8. %sГраната WallHack^n", jbe_is_user_alive(pId) ? "\w" : "\d"), itemKey(7);
		else FormatItem("\y8. \dГраната WallHack \r(для охран)^n");
	}else FormatItem("\y8. \dГраната WallHack \y(%d LVL)^n", g_iAllCvars[VIP_HIGH_JUMP_LEVEL]);

	
	//FormatItem("^n^n^n\y9. \wНазад^n"), itemKey(8);
	FormatItem("^n^n^n\y0. \wНазад"), itemKey(9);

	return show_menu(pId, iKeys, szMenu, -1, "Show_MainVip2Menu");
}

public Handle_MainVip2Menu(pId, iKey)
{
	
	if(jbe_get_day_mode() > 2) return PLUGIN_HANDLED;
	
	if(jbe_is_user_duel(pId) || jbe_get_soccergame())
	{
		UTIL_SayText(pId, "!g* !yВо время дуэли нельзя\футбола");
		return PLUGIN_HANDLED;
	}
	
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yВключен глобальный режим");
		return PLUGIN_HANDLED;
	}
	if(jbe_iduel_status())
	{
		UTIL_SayText(pId, "!g* !yИдет дуэль!, воскрешение не доступно!");
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 0: return Cmd_SpawnPlayer(pId);
		case 1: 
		{
			if(jbe_is_user_alive(pId))
			{
				InvertBit(g_iBitUserSilentSteps, pId);
				
				if(IsSetBit(g_iBitUserSilentSteps, pId)) rg_set_user_footsteps(pId, true);
				else rg_set_user_footsteps(pId, false);

				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gБесшумные шаги", g_iVipStatus[pId],pId, IsSetBit(g_iBitUserSilentSteps, pId) ? "взял" : "сбросил");
			}
		}
		case 2:
		{
			if(g_iVipStatus[pId] > LEVEL_ONE && jbe_is_user_alive(pId) && jbe_is_user_chief(pId))
			{
				
				InvertBit(g_iBitUserGodMode, pId);
				
				if(IsSetBit(g_iBitUserGodMode, pId) && g_iVipGodModeChief[pId]) jbe_set_user_godmode(pId, 1);
				else jbe_set_user_godmode(pId, 0);

				g_iVipGodModeChief[pId] = 0;
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gБессмертие", g_iVipStatus[pId],pId, IsSetBit(g_iBitUserGodMode, pId) ? "включил" : "выключил");
			}
		}
		
		case 3: 
		{
			if(!jbe_is_user_alive(pId))
			{
				UTIL_SayText(pId, "!g* !yВы мертвы!");
				return Show_MainVip2Menu(pId);
			}
			UTIL_SayText(pId, "!g* !yВ разработке!");
			
			if(g_iVipStatus[pId] >= g_iAllCvars[VIP_HOOK_LEVEL])
			{
				return Show_MainVip2Menu(pId);
			}
			
			
			
		}
		case 4:
		{
			if(!jbe_is_user_alive(pId))
			{
				UTIL_SayText(pId, "!g* !yВы мертвы!");
				return Show_MainVip2Menu(pId);
			}
			if(g_iVipStatus[pId] >= g_iAllCvars[VIP_LONG_JUMP_LEVEL] && jbe_is_user_alive(pId))
			{
				InvertBit(g_iBitUserLongJump, pId);
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gДлинный прыжок", g_iVipStatus[pId], pId,IsSetBit(g_iBitUserLongJump, pId) ? "включил" : "выключил");
			}
		}
		case 5:
		{
			if(!jbe_is_user_alive(pId))
			{
				UTIL_SayText(pId, "!g* !yВы мертвы!");
				return Show_MainVip2Menu(pId);
			}
			if(g_iVipStatus[pId] >= g_iAllCvars[VIP_HIGH_JUMP_LEVEL] && jbe_is_user_alive(pId))
			{
				InvertBit(g_iBitUserHighJump, pId)
				
				UTIL_SayText(0, "!g[VIP: %d LVL] !t%n !y%s: !gВысокий прыжок", g_iVipStatus[pId],pId, IsSetBit(g_iBitUserHighJump, pId) ? "включил" : "выключил");
			}
		}
		case 6:
		{
			if(!jbe_is_user_alive(pId))
			{
				UTIL_SayText(pId, "!g* !yВы мертвы!");
				return Show_MainVip2Menu(pId);
			}
			if(jbe_get_user_team(pId) != 2)
			{
				UTIL_SayText(pId, "!g* !yДанный товар доступен только охранникам!");
				return Show_MainVip2Menu(pId);
			}
			
			jbe_give_strip_nade(pId);
			return PLUGIN_HANDLED;
		}
		case 7:
		{
			if(!jbe_is_user_alive(pId))
			{
				UTIL_SayText(pId, "!g* !yВы мертвы!");
				return Show_MainVip2Menu(pId);
			}
			if(jbe_get_user_team(pId) != 2)
			{
				UTIL_SayText(pId, "!g* !yДанный товар доступен только охранникам!");
				return Show_MainVip2Menu(pId);
			}
			jbe_give_wh_nade(pId);
			return PLUGIN_HANDLED;
		}

		
		case 9: return Show_MainVipMenu(pId);
	}

	return Show_MainVip2Menu(pId);
}



stock PlayerSpawn(pId)
{
	if(jbe_get_user_team(pId) == 1)
	{
		SetBit(g_iBitUserDontAttacked, pId);
	}
	rg_round_respawn(pId);
	
	
	
}

stock Float:jbe_get_gravity_float(pId)
{
	switch(g_iVipStatus[pId])
	{
		case 2: return Float:g_iAllCvars[VIP_GRAVITY_ONE];
		case 3: return Float:g_iAllCvars[VIP_GRAVITY_TWO];
		case 4: return Float:g_iAllCvars[VIP_GRAVITY_THREE];
	}
	return 0.0;
}

stock jbe_get_vip_level(pId, iType)
{
	switch(iType)
	{
		case 0:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_RESPAWN_ONE];
				case 3: return g_iAllCvars[VIP_RESPAWN_TWO];
				case 4: return g_iAllCvars[VIP_RESPAWN_THREE];
			}
		}
		case 1:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_SPEED_ONE];
				case 3: return g_iAllCvars[VIP_SPEED_TWO];
				case 4: return g_iAllCvars[VIP_SPEED_THREE];
			}
			
		}

		case 3:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_MONEY_ONE];
				case 3: return g_iAllCvars[VIP_MONEY_TWO];
				case 4: return g_iAllCvars[VIP_MONEY_THREE];
			}
			
		}
		case 4:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_EXP_ONE];
				case 3: return g_iAllCvars[VIP_EXP_TWO];
				case 4: return g_iAllCvars[VIP_EXP_THREE];
			}
		}
		case 5:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_RESPAWN_PLAYER_ONE];
				case 3: return g_iAllCvars[VIP_RESPAWN_PLAYER_TWO];
				case 4: return g_iAllCvars[VIP_RESPAWN_PLAYER_THREE];
			}
		}
		case 6:
		{
			switch(g_iVipStatus[pId])
			{
				case 1: return g_iAllCvars[VIP_HEALTH_FREE];
				case 2: return g_iAllCvars[VIP_HEALTH_ONE];
				case 3: return g_iAllCvars[VIP_HEALTH_TWO];
				case 4: return g_iAllCvars[VIP_HEALTH_THREE];
			}
		}
		case 7:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_SKIN_ONE];
				case 3: return g_iAllCvars[VIP_SKIN_TWO];
				case 4: return g_iAllCvars[VIP_SKIN_THREE];
			}
		}
		case 8:
		{
			switch(g_iVipStatus[pId])
			{
				case 1: return g_iAllCvars[VIP_EXPMONEY_FREE_ROUND];
				case 2: return g_iAllCvars[VIP_EXPMONEY_ONE_ROUND];
				case 3: return g_iAllCvars[VIP_EXPMONEY_TWO_ROUND];
				case 4: return g_iAllCvars[VIP_EXPMONEY_THREE_ROUND];
			}
		}
		case 9:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_ROULETTE_ONE];
				case 3: return g_iAllCvars[VIP_ROULETTE_TWO];
				case 4: return g_iAllCvars[VIP_ROULETTE_THREE];
			}
		}
		case 10:
		{
			switch(g_iVipStatus[pId])
			{
				case 2: return g_iAllCvars[VIP_GODMODE_ONE];
				case 3: return g_iAllCvars[VIP_GODMODE_TWO];
				case 4: return g_iAllCvars[VIP_GODMODE_THREE];
			}
		}
	}
	return 0;
}



public Cmd_TransferMenu(pId) return Show_TransferMenu(pId, g_iMenuPosition[pId] = 0);
Show_TransferMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || jbe_get_user_team(i) != 2 || is_user_hltv(i) || i == pId) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
		
	

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED
			
		}
		default: FormatMain("\yПеревод за Зеков \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		
		if(jbe_is_user_flags(i, 3))
		{
			FormatItem("\y%d. \d%n \r*UAIO^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 1))
		{
			FormatItem("\y%d. \d%n \r*Admin^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 0))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*VIP^n", ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n^n", ++b, i);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_TransferMenu");
}

public Handle_TransferMenu(pId, iKey)
{
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yВключен глобальный режим");
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 8: return Show_TransferMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_TransferMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			jbe_set_user_team(iTarget, 1);
			UTIL_SayText(0, "!g[VIP] !t%n !yперевел охранника !g%n !yза !gЗаключенных", pId, iTarget);

		}
	}
	return Show_TransferMenu(pId, g_iMenuPosition[pId]);
}

public Cmd_SpawnPlayer(pId) return Show_SpawnPlayer(pId, g_iMenuPosition[pId] = 0);
Show_SpawnPlayer(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || is_user_hltv(i) || i == pId) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
		
	

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED
			
		}
		default: FormatMain("\wКого возрадить? \y[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n^n", ++b, i);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_SpawnPlayer");
}

public Handle_SpawnPlayer(pId, iKey)
{
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yВключен глобальный режим");
		return PLUGIN_HANDLED;
	}
	
	if(g_iRouneTimeEnd)
	{
		UTIL_SayText(pId, "!g* !yТаймер равен 0!, вип меню не доступно!");
		return PLUGIN_HANDLED;
	}
	if(jbe_iduel_status())
	{
		UTIL_SayText(pId, "!g* !yИдет дуэль!, воскрешение не доступно!");
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 8: return Show_SpawnPlayer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_SpawnPlayer(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			//jbe_set_user_team(iTarget, 1);
			
			if(jbe_is_user_connected(iTarget))
			{
				if(jbe_all_users_wanted())
				{
					UTIL_SayText(pId, "!g* !yЗапрещено рес во время бунта!");
					return PLUGIN_HANDLED;
				
				}
				
				
				
				PlayerSpawn(iTarget);
				g_iVipPlayerRespawn[pId]--;
				UTIL_SayText(0, "!g[VIP] !t%n !yвозродил !g%n", pId, iTarget);
			}else Show_SpawnPlayer(pId, g_iMenuPosition[pId]);

		}
	}
	return Show_SpawnPlayer(pId, g_iMenuPosition[pId]);
}

Show_RouletteMenu(id)
{
	//jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<8|1<<9), iLen;
	

	FormatMain("\
	\wИграем в рулетку?^n^n\
	\r80%%\w - \yБез рук^n\
	\r60%%\w - \yХолостые патроны^n\
	\r50%%\w - \y%d$^n\
	\r35%%\w - \yРаспрыг^n\
	\r7%%\w - \yБычки^n\
	\r5%%\w - \yСвободный день^n^n^n", ROULETTE_MONEY);

	FormatItem("\y1. \wДа^n");
	FormatItem("\y2. \wНет^n");
	
	FormatItem("^n\y9. \w%L", id, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, iKeys, szMenu, -1, "Show_RouletteMenu");
}

public Handle_RouletteMenu(pId, key)
{
	if(!jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yВключен глобальный режим");
		return PLUGIN_HANDLED;
	}
	
	if(IsSetBit(g_iBitUserUseRoullete, pId))
	{
		UTIL_SayText(pId, "!g* !yВы уже использовали рулетку за этот раунд");
		return Show_RouletteMenu(pId);
	}
	
	if(jbe_get_user_team(pId) != 1)
	{
		UTIL_SayText(pId, "!g* !yРулетка доступно только зекам!");
		return Show_RouletteMenu(pId);
	}
	
	

	switch( key ) 
	{
		case 0:
		{
			new shans;
			shans = random_num(1,100);
			SetBit(g_iBitUserUseRoullete, pId);
			g_iVipRoulette[pId] = 0;
			rh_emit_sound2(pId, 0, CHAN_STATIC, "jb_engine/other/woohoo2.wav", VOL_NORM, ATTN_NORM);
			
			if (shans < 80)
			{
				new NewShans;
				NewShans = random_num(1, 100);
				
				switch(NewShans)
				{
					case 1..50: //Без рук
					{
						if(IsNotSetBit(g_iBitUserNoWeapon, pId))
						{
							SetBit(g_iBitUserNoWeapon, pId)
							rg_remove_all_items(pId);
							
							set_task_ex(1.0, "Checking_ForWeapon", pId + TASK_PLAYER_NO_WEAPON, .flags = SetTask_Repeat);
							
							UTIL_SayText(0, "!g[VIP] !t%n !yвыйграл в рулетке: !gОбезаруживание рук", pId);
						
						}
					
					}
					case 51..80: //Скользий
					{
						if(IsNotSetBit(g_iBitUserHitZone, pId))
						{
							set_user_hitzones(pId,0,0);
							SetBit(g_iBitUserHitZone, pId);
							UTIL_SayText(0, "!g[VIP] !t%n !yвыйграл в рулетке: !gХолостые патроны", pId)
						}
					}
					case 81..100: //Скользий
					{
						if(IsNotSetBit(g_iBitUserRoulleteMoney, pId))
						{
							//jbe_set_user_money(pId, jbe_get_user_money(pId) + ROULETTE_MONEY, 1);
							jbe_set_butt(pId, jbe_get_butt(pId) + ROULETTE_MONEY);
							SetBit(g_iBitUserRoulleteMoney, pId);
							UTIL_SayText(0, "!g[VIP] !t%n !yвыйграл в рулетке: !g%dбычков", pId, ROULETTE_MONEY)
						}
					}
				}
			}
			else 
			{
				new NewShans;
				NewShans = random_num(50, 100);
				
				switch(NewShans)
				{
					case 51..70: //Распрыг
					{
						if(IsNotSetBit(g_iBitUserRoulleteBhop, pId))
						{
							SetBit(g_iBitUserRoulleteBhop, pId);
							UTIL_SayText(0, "!g[VIP] !t%n !yвыграл в рулетке: !gРаспрыжку", pId)
						}
					
					}
					case 71..88://Бычки
					{
						if(IsNotSetBit(g_iBitUserRoulleteBychki, pId))
						{
							new iRandom = random_num(1, 4);
							SetBit(g_iBitUserRoulleteBychki, pId)
							jbe_set_butt(pId, jbe_get_butt(pId) + iRandom)
							UTIL_SayText(0, "!g[VIP] !t%n !yвыйграл в рулетке: !g%d быч.", pId, iRandom)
						}
					
					}
					case 89..100://ФД
					{
						if(IsNotSetBit(g_iBitUserRoulleteFreeDay, pId))
						{

							SetBit(g_iBitUserRoulleteFreeDay, pId)
							jbe_add_user_free(pId);
							UTIL_SayText(0, "!g[VIP] !t%n !yвыйграл в рулетке: !gCвободный день", pId)
						}
					
					
					}
				}
			}

		}
		
		case 8: return Show_MainVipMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public Checking_ForWeapon(pId)
{
	pId -= TASK_PLAYER_NO_WEAPON;
	
	if(jbe_get_friendlyfire() && IsNotSetBit(g_iBitUserFF, pId))
	{
		SetBit(g_iBitUserFF, pId);
		rg_give_item(pId, "weapon_knife");
		return;
	}
	
	new iBitWeapons = get_entvar(pId, var_weapons);
	if(iBitWeapons &= ~(1<<31))
	{
		rg_remove_all_items(pId);
		CenterMsgFix_PrintMsg(pId, print_center, "Вы лешились рук!");
	}


}

public HC_CBasePlayer_PlayerJump_Post(const pId)
{
	if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2 ))
	{
		if((!jbe_is_user_duel(pId) && !jbe_all_users_wanted() && !jbe_get_soccergame()) && IsSetBit(g_iBitUserRoulleteBhop, pId) && get_entvar(pId, var_flags) & (FL_ONGROUND|FL_CONVEYOR))
		{
			new Float:vecVelocity[3];
			get_entvar(pId, var_velocity, vecVelocity);
			vecVelocity[2] = 250.0;
			set_entvar(pId, var_velocity, vecVelocity);
			set_entvar(pId, var_gaitsequence, 6);
		}
		
		static Float: fCurTime, Float: fNextTime[MAX_PLAYERS + 1]; fCurTime = get_gametime();
		
		if((!jbe_is_user_duel(pId) && !jbe_all_users_wanted() && !jbe_get_soccergame()) && IsSetBit(g_iBitUserLongJump, pId) && (get_entvar(pId, var_button) & IN_DUCK) && (get_entvar(pId, var_flags) & (FL_ONGROUND|FL_CONVEYOR)))
		{
			

			if(fNextTime[pId] <= fCurTime)
			{
				fNextTime[pId] = fCurTime + LONG_JUMPTIME;
				long_jump(pId);
				//acid_eff(pId)
				rh_emit_sound2(pId, 0, CHAN_STATIC, "jb_engine/use_skills.wav", VOL_NORM, ATTN_NORM);
				rg_send_bartime(pId, floatround(LONG_JUMPTIME), false);
				
			}else CenterMsgFix_PrintMsg(pId, print_center, "Ждите еще %.1f секунд!", fNextTime[pId] - fCurTime);
			
		}
		if( (!jbe_is_user_duel(pId) && !jbe_all_users_wanted() && !jbe_get_soccergame()) && IsSetBit(g_iBitUserHighJump, pId) && !(get_entvar(pId, var_button) & IN_DUCK) && (get_entvar(pId, var_flags) & (FL_ONGROUND|FL_CONVEYOR)))
		{

			if(fNextTime[pId] <= fCurTime)
			{
				fNextTime[pId] = fCurTime + HIGH_JUMPTIME;
				
				new Float:fVelocity[3]
				get_entvar(pId, var_velocity, fVelocity);
				fVelocity[2] += 900.0;
				set_entvar(pId, var_velocity, fVelocity);
				rh_emit_sound2(pId, 0, CHAN_STATIC, "jb_engine/use_skills.wav", VOL_NORM, ATTN_NORM);
				rg_send_bartime(pId, floatround(HIGH_JUMPTIME), false);
				//acid_eff(pId)
				
				if(g_iGlobalDebug)
				{
					log_to_file("globaldebug.log", "[vipmenu] HC_CBasePlayer_PlayerJump_Post");
				}
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMFOLLOW)
				write_short(pId)
				write_short(sprite2)
				write_byte(10)
				write_byte(5)
				write_byte(255)
				write_byte(126)
				write_byte(0)
				write_byte(192)
				message_end()
				
				set_task(2.0, "Kill_Trail",pId + 47476598)
				
			}else CenterMsgFix_PrintMsg(pId, print_center, "Ждите еще %.1f секунд!", fNextTime[pId] - fCurTime);
			
		}
	}
}


stock long_jump(long_jump) 
{
	set_speed( long_jump, 1000.0, 3 );
	static Float:velocity[3];
	pev(long_jump, pev_velocity, velocity);
	velocity[ 2 ] = get_pcvar_float( get_cvar_pointer("sv_gravity")) / 3.0;
	new button = pev(long_jump, pev_button);
	if(button & IN_BACK) 
	{
		velocity[0] *= -1;
		velocity[1] *= -1;
	}
	set_pev(long_jump, pev_velocity, velocity);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[vipmenu] long_jump");
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(long_jump)
	write_short(sprite2)
	write_byte(10)
	write_byte(5)
	write_byte(255)
	write_byte(126)
	write_byte(0)
	write_byte(192)
	message_end()
	
	set_task(1.0, "Kill_Trail",long_jump + 47476598)
}

public Kill_Trail(pId)
{
	pId -= 47476598
	
	if(!jbe_is_user_connected(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[vipmenu] Kill_Trail");
	}
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(99); // TE_KILLBEAM
	write_short(pId)
	message_end()
}

public HC_CBasePlayer_PlayerKilled_Post(pId, iKiller)
{
	if(IsSetBit(g_iBitUserVip, pId))
	{
		//ClearBit(g_iBitUserVip, pId);
	

		ClearBit(g_iBitUserSpeed, pId);
		ClearBit(g_iBitUserGravity, pId);
		ClearBit(g_iBitUserSilentSteps, pId);
		ClearBit(g_iBitUserNoWeapon, pId);
		ClearBit(g_iBitUserHitZone, pId);
		ClearBit(g_iBitUserRoulleteBhop, pId);
		ClearBit(g_iBitUserRoulleteBychki, pId);
		ClearBit(g_iBitUserRoulleteMoney, pId);
		ClearBit(g_iBitUserRoulleteFreeDay, pId);
		ClearBit(g_iBitUserUseRoullete, pId);
		ClearBit(g_iBitUserGodMode, pId);
		ClearBit(g_iBitUserLongJump, pId);
		ClearBit(g_iBitUserHighJump, pId);
		ClearBit(g_iBitUserDontAttacked, pId);
		ClearBit(g_iBitUserFF, pId);
		ClearBit(g_iBitUserDontWantedForSpeed, pId);
		
		if(task_exists(pId + TASK_PLAYER_NO_WEAPON)) remove_task(pId + TASK_PLAYER_NO_WEAPON);
		
		if(g_iStatusSpeed[pId]) g_iStatusSpeed[pId] = false;
		if(g_iStatusGravity[pId]) g_iStatusGravity[pId] = false;
		if(g_iStatusSilteSteps[pId]) g_iStatusSilteSteps[pId] = false;
	}
}

public bool:BufferPushTeleport[MAX_PLAYERS + 1];

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		
		//new Float:fDamageOld = fDamage;
		if(jbe_get_user_team(iAttacker) == 1 && jbe_get_user_team(iVictim) == 2)
		{
			if(IsSetBit(g_iBitUserDontAttacked, iAttacker) || IsSetBit(g_iBitUserDontWantedForSpeed, iAttacker) || IsSetBit(g_iBitUserDontWantedForGravity, iAttacker))
			{
				if(!BufferPushTeleport[iAttacker] && !task_exists(iAttacker + 45748))
				{
					if(IsSetBit(g_iBitUserDontAttacked, iAttacker))
					{
						CenterMsgFix_PrintMsg(iAttacker, print_center, "Запрещено бунт после реса!");
						CenterMsgFix_PrintMsg(iVictim, print_center, "Вам не нанес урон игрок %n, поскольку бунт после реса запрещен!", iAttacker);
					}
					else
					if(IsSetBit(g_iBitUserDontWantedForSpeed, iAttacker) || IsSetBit(g_iBitUserDontWantedForGravity, iAttacker))
					{
						CenterMsgFix_PrintMsg(iAttacker, print_center, "Запрещено бунт если у вас есть гравитации или скорость!");
						CenterMsgFix_PrintMsg(iVictim, print_center, "Вам не нанес урон игрок %n, поскольку у него есть грава или скорость!", iAttacker);
					}
					set_task_ex(1.0, "dontwanted", iAttacker + 45748);
					BufferPushTeleport[iAttacker] = true;
				}
				
				
				SetHookChainArg(3, ATYPE_FLOAT, 0.0);
				return HC_SUPERCEDE;
			}
			
		}
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_TakeDamage_Player(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(!jbe_is_user_valid(iAttacker))
		return HC_CONTINUE;
	if(!g_iBitUserDontWantedForSpeed || !g_iBitUserDontAttacked)
		return HC_CONTINUE;
		
	if(iBitDamage & (1<<24))
	{
		if(jbe_get_user_team(iAttacker) == 1 && jbe_get_user_team(iVictim) == 2)
		{
			if(IsSetBit(g_iBitUserDontAttacked, iAttacker) || IsSetBit(g_iBitUserDontWantedForSpeed, iAttacker) || IsSetBit(g_iBitUserDontWantedForGravity, iAttacker))
			{
				if(!BufferPushTeleport[iAttacker] && !task_exists(iAttacker + 45748))
				{
					if(IsSetBit(g_iBitUserDontAttacked, iAttacker))
					{
						CenterMsgFix_PrintMsg(iAttacker, print_center, "Запрещено бунт после реса!");
						CenterMsgFix_PrintMsg(iVictim, print_center, "Вам не нанес урон игрок %n, поскольку бунт после реса запрещен!", iAttacker);
					}
					else
					if(IsSetBit(g_iBitUserDontWantedForSpeed, iAttacker) || IsSetBit(g_iBitUserDontWantedForGravity, iAttacker))
					{
						CenterMsgFix_PrintMsg(iAttacker, print_center, "Запрещено бунт если у вас есть гравитации или скорость!");
						CenterMsgFix_PrintMsg(iVictim, print_center, "Вам не нанес урон игрок %n, поскольку у него есть грава или скорость!", iAttacker);
					}
					set_task_ex(1.0, "dontwanted", iAttacker + 45748);
					BufferPushTeleport[iAttacker] = true;
				}
				
				
				
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE;
			}
			
		}
	}

	return HC_CONTINUE;
}



public dontwanted(id)
{
	id -= 45748;

	BufferPushTeleport[id] = false;
}

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(is_user_alive(pId))
	{
		if(IsSetBit(g_iBitUserDontAttacked, pId))
		{
			CenterMsgFix_PrintMsg(pId, print_center, "Вам запрещено бунтовать, так как вы реснулись через вип меню!");
			UTIL_SayText(pId, "!g* !yВам запрещено бунтовать, так как вы реснулись через вип меню!");
		
		}
	}
}


public PM_AirMove(const pId)
{
	if(jbe_get_day_mode() > 2 || jbe_all_users_wanted() ) return;
	
	if(!(get_entvar(pId, var_button) & IN_USE) || get_entvar(pId, var_waterlevel) > 0) return;
	if(jbe_is_user_duel(pId) || jbe_get_soccergame()) return;
	if(g_iVipStatus[pId] <= LEVEL_ONE || IsNotSetBit(g_iBitUserParachute, pId)) return;
	
	new Float:flVelocity[3];
	get_entvar(pId, var_velocity, flVelocity);
	if(flVelocity[2] < 0.0)
	{
		flVelocity[2] = (flVelocity[2] + 40.0 < -100.0) ? flVelocity[2] + 40.0 : -100.0;
		set_entvar(pId, var_sequence , ACT_WALK);
		set_entvar(pId, var_gaitsequence, ACT_IDLE);
		set_pmove(pm_velocity, flVelocity);
		set_movevar(mv_gravity, 80.0);
	}
}

public HookResetMaxSpeed(const pId)
{
	if(jbe_get_day_mode() > 2 || jbe_all_users_wanted() || jbe_is_user_duel(pId) || jbe_get_soccergame()) return;
	
	if(g_iStatusSpeed[pId])
        set_entvar(pId, var_maxspeed, float(jbe_get_vip_level(pId, 1)));  
}

public Event_CurWeapon(const pId)
{
	if(jbe_get_day_mode() > 2 || jbe_all_users_wanted() || jbe_is_user_duel(pId) || jbe_get_soccergame() ) return;
	if(g_iStatusSpeed[pId])
		set_entvar(pId, var_maxspeed, float(jbe_get_vip_level(pId, 1))); 
}


stock set_speed(ent,Float:speed,mode=0,const Float:origin[3]={0.0,0.0,0.0})
{
	if(!jbe_is_user_valid(ent))
		return 0;

	switch(mode)
	{
		case 0:
		{
			static Float:cur_velo[3];

			get_entvar(ent,var_velocity,cur_velo);

			new Float:y;
			y = cur_velo[0]*cur_velo[0] + cur_velo[1]*cur_velo[1];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			cur_velo[0] *= x;
			cur_velo[1] *= x;

			if(speed<0.0)
			{
				cur_velo[0] *= -1;
				cur_velo[1] *= -1;
			}

			set_entvar(ent,var_velocity,cur_velo);
		}
		case 1:
		{
			static Float:cur_velo[3];

			get_entvar(ent,var_velocity,cur_velo);

			new Float:y;
			y = cur_velo[0]*cur_velo[0] + cur_velo[1]*cur_velo[1] + cur_velo[2]*cur_velo[2];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			cur_velo[0] *= x;
			cur_velo[1] *= x;
			cur_velo[2] *= x;

			if(speed<0.0)
			{
				cur_velo[0] *= -1;
				cur_velo[1] *= -1;
				cur_velo[2] *= -1;
			}

			set_entvar(ent,var_velocity,cur_velo);
		}
		case 2:
		{
			static Float:vangle[3];
			if(ent<= MaxClients ) get_entvar(ent,var_v_angle,vangle);
			else get_entvar(ent,var_angles,vangle);

			static Float:new_velo[3];

			angle_vector(vangle,1,new_velo);

			new Float:y;
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1] + new_velo[2]*new_velo[2];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			new_velo[0] *= x;
			new_velo[1] *= x;
			new_velo[2] *= x;

			if(speed<0.0)
			{
				new_velo[0] *= -1;
				new_velo[1] *= -1;
				new_velo[2] *= -1;
			}

			set_entvar(ent,var_velocity,new_velo);
		}
		case 3:
		{
			static Float:vangle[3];
			if(ent<=MaxClients) get_entvar(ent,var_v_angle,vangle);
			else get_entvar(ent,var_angles,vangle);

			static Float:new_velo[3];

			get_entvar(ent,var_velocity,new_velo);

			angle_vector(vangle,1,new_velo);

			new Float:y;
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			new_velo[0] *= x;
			new_velo[1] *= x;

			if(speed<0.0)
			{
				new_velo[0] *= -1;
				new_velo[1] *= -1;
			}

			set_entvar(ent,var_velocity,new_velo);
		}
		case 4:
		{
			static Float:origin1[3];
			get_entvar(ent,var_origin,origin1);

			static Float:new_velo[3];

			new_velo[0] = origin[0] - origin1[0];
			new_velo[1] = origin[1] - origin1[1];
			new_velo[2] = origin[2] - origin1[2];

			new Float:y;
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1] + new_velo[2]*new_velo[2];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			new_velo[0] *= x;
			new_velo[1] *= x;
			new_velo[2] *= x;

			if(speed<0.0)
			{
				new_velo[0] *= -1;
				new_velo[1] *= -1;
				new_velo[2] *= -1;
			}

			set_entvar(ent,var_velocity,new_velo);
		}
		default: return 0;
	}
	return 1;
}





