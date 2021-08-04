#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>
#include <xs>

//#define DEBUG

#define linux_diff_player 5
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])
#define LifeTime 			25 //Время Жизни трайла
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)


#define MsgId_ScreenShake 97

native jbe_aliveplayersnum(iType);
native jbe_is_user_edit_fbox(id);

//#define STEPCHIEF

enum
{
	V_GOLDEN_AK47 = 1,
	P_GOLDEN_AK47,
	V_ELECTRO_MP5,
	GOLDEN_AK_SHOT_1
};

const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41
const PDATA_SAFE = 2


#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


#define CHIEF_SPEED		350.0

forward jbe_set_user_chief_fwd(pId);
forward jbe_remove_user_chief_fwd(pId, iType);
forward jbe_lr_duels();


native jbe_get_stepchief();
native jbe_iduel_status();

native get_login(pId);
native jbe_mysql_stats_systems_add(pId, stats,iNum)
native jbe_mysql_stats_systems_get(pId, stats)

//crusader
native jbe_get_ff_crusader();
native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);
native jbe_playersnum(iType);
native jbe_is_user_duel(pid);
new g_iBitUserHaveGoldAK47,
	g_iBitUserHaveGoldMP5;

new g_iBitUserChief;

new bool:g_bIsHoldingPaint[MAX_PLAYERS+1];

new Float:g_iOriginPaint[MAX_PLAYERS+1][3];

new g_iColorRed,
	g_iColorGreen,
	g_iColorBlue,
	g_pSpriteLightning,
	iEnt;
	
enum
{
	SELECT_PRISON = 1,
	SELECT_GUARD,
	SELECT_CVARS,
	SELECT_SOUND
};
	
enum _:PLAYER_HAND
{
	GOLDEN_AK47_V = 1,
	GOLDEN_AK47_P,
	ELECTRO_MP5_V,
	GOLDEN_AK47_SHOT1_SOUND
}

new g_szPlayerHand[PLAYER_HAND][64];
new g_szPlayerSound[PLAYER_HAND][64];

//new g_TotalChiefPlayerTime[MAX_PLAYERS + 1];
//new iDelayChief

//new HamHook:g_FwrPrimary[2];

public plugin_init()
{
	register_plugin("[JBE] Set  Chief - Addon", "1.0", "DalgaPups");
	
	//DisableHamForward( g_FwrPrimary[0] = RegisterHam(Ham_Weapon_PrimaryAttack,	 	"weapon_ak47", 		"Ham_Ak47PrimaryAttack_Pre", 			false));
	//DisableHamForward( g_FwrPrimary[1] = RegisterHam(Ham_Weapon_PrimaryAttack, 		"weapon_ak47", 		"Ham_Ak47PrimaryAttack_Post", 			true));
	
	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false);
	
	RegisterHam(Ham_Item_Deploy, 				"weapon_ak47", 		"Ham_Ak47Deploy_Post", 					true);
	RegisterHam(Ham_Item_Deploy, 				"weapon_mp5navy", 	"Ham_MP5NavyDeploy_Post", 				true);
	RegisterHam(Ham_Weapon_PrimaryAttack,		"weapon_ak47", 		"HamHook_Item_PrimaryAttack",	false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 				"HookResetMaxSpeed", 				true);
	
	jbe_get_cvars();
}

enum _:CVAR
{
	ADD_MONEY_CHIEF,
	REMOVE_MONEY_CHIEF
}
new g_iAllCvars[CVAR];
jbe_get_cvars()
{

	new pcvar;
	
	pcvar = create_cvar("jbe_set_user_chief", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADD_MONEY_CHIEF]);
	
	pcvar = create_cvar("jbe_transfer_user_chief", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[REMOVE_MONEY_CHIEF]);
	
	AutoExecConfig(true, "Jail_Chief_Addon");
}

public plugin_precache()
{
	g_pSpriteLightning = precache_model("sprites/333.spr");
	LOAD_CONFIGURATION();
}

public Ham_Ak47Deploy_Post(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	if(IsSetBit(g_iBitUserHaveGoldAK47, pId))
	{
		set_entvar(pId, var_viewmodel, g_szPlayerHand[GOLDEN_AK47_V]);
		set_entvar(pId, var_weaponmodel, g_szPlayerHand[GOLDEN_AK47_P]);
		return;
	}
}

public Ham_MP5NavyDeploy_Post(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	if(IsSetBit(g_iBitUserHaveGoldMP5, pId))
	{
		set_entvar(pId, var_viewmodel, g_szPlayerHand[ELECTRO_MP5_V]);
		return;
	}
	
}

public plugin_natives()
{
	register_native("jbe_set_user_gold", "jbe_set_user_gold", 1);
	register_native("jbe_get_user_goldak", "jbe_get_user_goldak", 1);
	register_native("jbe_get_user_goldmp5", "jbe_get_user_goldmp5", 1);
}

public jbe_get_user_goldak(pId) return IsSetBit(g_iBitUserHaveGoldAK47, pId);
public jbe_get_user_goldmp5(pId) return IsSetBit(g_iBitUserHaveGoldMP5, pId);

new Float:g_angPunchAngles[MAX_PLAYERS + 1][3];
const m_flAccuracy= 62;
new g_iClip[MAX_PLAYERS + 1];


public jbe_set_user_gold(pId, iType)
{
	switch(iType)
	{
		case true:
		{
			SetBit(g_iBitUserHaveGoldAK47, pId);
			SetBit(g_iBitUserHaveGoldMP5, pId);
			
		}
		case false:
		{
			ClearBit(g_iBitUserHaveGoldAK47, pId);
			ClearBit(g_iBitUserHaveGoldMP5, pId);
		}
	}
	new iActiveItem = get_member(pId, m_pActiveItem);
	if(iActiveItem > 0)
	{
		ExecuteHamB(Ham_Item_Deploy, iActiveItem);
		UTIL_WeaponAnimation(pId, 3);
	}
}

public HookResetMaxSpeed(const pId)
{
	if(IsSetBit(g_iBitUserChief, pId) && !jbe_is_user_duel(pId))
	{
		set_entvar(pId, var_maxspeed, CHIEF_SPEED);
	}

}

//Форвард когда кто-то взял начальника
public jbe_set_user_chief_fwd(pPlayer)
{
	
	if(jbe_playersnum(1) >= 6 && get_login(pPlayer))
	{
		//g_iAllCvars[ADD_MONEY_CHIEF]
		jbe_set_butt(pPlayer, jbe_get_butt(pPlayer) + g_iAllCvars[ADD_MONEY_CHIEF]);
	}

	rg_remove_all_items(pPlayer);
	rg_give_item(pPlayer, "weapon_knife", GT_APPEND);
	
	set_entvar(pPlayer, var_maxspeed, CHIEF_SPEED);
	set_entvar(pPlayer, var_gravity, 0.5);
	
	

	rg_give_item_ex(pPlayer, "weapon_deagle", GT_REPLACE, 228);
	rg_give_item_ex(pPlayer, "weapon_ak47", GT_REPLACE, 228);
	rg_give_item_ex(pPlayer, "weapon_mp5navy", GT_APPEND, 228);
	
	engclient_cmd(pPlayer, "weapon_ak47");
	
	jbe_set_user_gold(pPlayer, true); //Выдача Голд Ак47 и MP5

	iEnt = rg_create_entity("info_target", true);
	SetThink(iEnt, "think_step");
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
	
	SetBit(g_iBitUserChief, pPlayer);
	/*for(new i; i < sizeof(g_FwrPrimary); i++)
	{
		EnableHamForward(g_FwrPrimary[i]);
	}*/
	
	emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	set_dhudmessage(255, 255, 255, -1.0, 0.2, 0, 1.0, 1.0);
	show_dhudmessage(0, "%n^nНачальник тюрьмы", pPlayer);


	/*if(get_login(pPlayer))
	{
		new Float:iNewDelay  = get_gametime();
		iDelayChief = floatround(iNewDelay);
	}*/
	
	new Float:HealtForZek = 15.0;
	
	if(jbe_aliveplayersnum(1) > 20)
	{
		set_entvar(pPlayer, var_health, 500.0);
		UTIL_SayText(0, "!g[ChiefHP] !yСоотношение живых зеков больше !g20 !yигроков. Здоровье Начальника: !g500 ХП");
	}
	else
	if(jbe_aliveplayersnum(1) > 5)
	{
		new Float:NewHealtChief = (jbe_aliveplayersnum(1) * HealtForZek)
		UTIL_SayText(0, "!g[ChiefHP] !yБалансировка здоровье начальника: 1 зек = +15ХП");
		UTIL_SayText(0, "!g[ChiefHP] !yСоотношение живых зеков !g150 + (%dЗек * 15Хп)!y. Здоровье Начальника: !g%d !yХП",jbe_aliveplayersnum(1), floatround(150.0 + NewHealtChief));
		
		set_entvar(pPlayer, var_health, 150.0 + NewHealtChief);
	}
	else 
	{
		set_entvar(pPlayer, var_health, 250.0);
		UTIL_SayText(0, "!g[ChiefHP] !yСоотношение живых зеков меньше !g5!y. Здоровье Начальника: !g250 ХП");
	}
}

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iBitUserHaveGoldAK47 = 0;
	g_iBitUserHaveGoldMP5 = 0;
}
//Форвард когда сняли с начальника
public jbe_remove_user_chief_fwd(pPlayer, iType)
{
	jbe_set_user_gold(pPlayer, false);
	if(jbe_is_user_alive(pPlayer))
	{
		set_entvar(pPlayer, var_health, 150.0);
		set_entvar(pPlayer, var_gravity, 1.0);
		rg_reset_maxspeed(pPlayer);
		rg_remove_all_items(pPlayer);
		rg_give_item(pPlayer, "weapon_knife");
		rg_give_item_ex(pPlayer, "weapon_deagle", GT_REPLACE, 90);
		rg_give_item_ex(pPlayer, "weapon_ak47", GT_REPLACE, 90);
		engclient_cmd(pPlayer, "weapon_ak47");
	}
	
	if(is_entity(iEnt))
	{
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
		set_entvar(iEnt, var_nextthink, get_gametime());
	}
	/*for(new i; i < sizeof(g_FwrPrimary); i++)
	{
		DisableHamForward(g_FwrPrimary[i]);
	}*/
	
	ClearBit(g_iBitUserChief, pPlayer);
	
	if(iType)
	{
		if(jbe_get_butt(pPlayer) >= g_iAllCvars[REMOVE_MONEY_CHIEF])
		{
			jbe_set_butt(pPlayer, jbe_get_butt(pPlayer) - g_iAllCvars[REMOVE_MONEY_CHIEF]);
		}
	}

	/*if(get_login(pPlayer))
	{
		new Float:finish_time = get_gametime() - iDelayChief;
		new gTime = floatround(finish_time);
		g_TotalChiefPlayerTime[pPlayer] = (g_TotalChiefPlayerTime[pPlayer] + (gTime/60));
	}*/
}

public jbe_lr_duels()
{
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_connected(id) || !jbe_get_user_goldak(id) || !jbe_get_user_goldmp5(id)) continue;
		
		jbe_set_user_gold(id, false);
	}


}

public Ham_Ak47PrimaryAttack_Pre(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	
	if(IsSetBit(g_iBitUserChief, pId) && !jbe_iduel_status())
	{
		if(jbe_get_user_goldak(pId) && get_user_weapon(pId) == CSW_AK47)
		{
			g_iClip[pId]= get_member(iEntity, m_Weapon_iClip);
			get_entvar(pId, var_punchangle, g_angPunchAngles[pId]);
			set_pdata_float(iEntity, m_flAccuracy, 0.0); // Тут либо 0.0, либо 1.0.
			return HAM_IGNORED;
		}
	}
	return HAM_IGNORED;
}

public Ham_Ak47PrimaryAttack_Post(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	
	if(IsSetBit(g_iBitUserChief, pId) && !jbe_iduel_status())
	{
		if(jbe_get_user_goldak(pId) && get_user_weapon(pId) == CSW_AK47)
		{
			if (get_member(iEntity, m_Weapon_iClip) >= g_iClip[pId])
                return HAM_IGNORED;
			set_entvar(pId, var_punchangle, g_angPunchAngles[pId]);
		}
	}
	return HAM_IGNORED;

}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(!jbe_is_user_valid(iAttacker))
		return HC_CONTINUE;
		
	if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2) && !jbe_get_ff_crusader())
	{
	
		new Float:fDamageOld = fDamage;
		
		
		#if defined DEBUG
		server_print("#1 Attack %n Victim %n Damage %d", iAttacker, iVictim, floatround(fDamage));
		#endif
		if(g_iBitUserHaveGoldAK47)
		{
			if(IsSetBit(g_iBitUserHaveGoldAK47, iAttacker) && get_user_weapon(iAttacker) == CSW_AK47)
			{
				fDamage = (fDamage * 2);
				#if defined DEBUG
				server_print("#2 Attack %n Victim %n Damage %d", iAttacker, iVictim, floatround(fDamage));
				#endif
			}
		}
		
		if(g_iBitUserHaveGoldMP5)
		{
			if(IsSetBit(g_iBitUserHaveGoldMP5, iAttacker) && get_user_weapon(iAttacker) == CSW_MP5NAVY)
			{
				emit_sound(iVictim, CHAN_WEAPON, "jb_engine/weapons/spark.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
				fDamage = 1.0;
				#if defined DEBUG
				server_print("#3Attack %n Victim %n Damage %d", iAttacker, iVictim, floatround(fDamage));
				#endif
			}
		}
		if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
	}

	

	return HC_CONTINUE;
}

native jbe_is_user_vip(id);
public think_step(iEnt)
{
	//server_print("TEST");
	/*static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

	for(new i, id; i < iPlayerCount; i++)
	{	
		id = iPlayers[i];
		if(jbe_is_user_vip(id) >= 3)
		{
			if(get_entvar(id, var_button) & IN_USE)
			{
				if(!func_IsAimingAtSky(id))
				{
					static Float:flOrigin[3], Float:flDistance;
					flOrigin = g_iOriginPaint[id];

					if(!g_bIsHoldingPaint[id])
					{
						g_bIsHoldingPaint[id] = true;
						
						func_GetAimOrigin(id, g_iOriginPaint[id]);
						func_MoveTowardClient(id, g_iOriginPaint[id]);
						
						g_iColorRed 	= random_num(1, 255);
						g_iColorGreen 	= random_num(1, 255);
						g_iColorBlue 	= random_num(1, 255);
						
						set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
						return;
					}

					func_GetAimOrigin(id, g_iOriginPaint[id]);
					func_MoveTowardClient(id, g_iOriginPaint[id]);

					flDistance = get_distance_f(g_iOriginPaint[id], flOrigin);

					if(flDistance > 2)
						func_StartPainting_Ex(g_iOriginPaint[id], flOrigin);
						
					//set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
					//return;
				}else g_bIsHoldingPaint[id] = false;
				
			}else g_bIsHoldingPaint[id] = false;
		}
	
	}*/
		new id = jbe_get_chief_id()
		if(IsNotSetBit(g_iBitUserChief, id))
		{
			set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
			return;
		}
		
		if(get_entvar(id, var_button) & IN_USE)
		{
			if(!func_IsAimingAtSky(id))
			{
				static Float:flOrigin[3], Float:flDistance;
				flOrigin = g_iOriginPaint[id];

				if(!g_bIsHoldingPaint[id])
				{
				
					if(jbe_is_user_edit_fbox(id))
					{

						CenterMsgFix_PrintMsg(id, print_center, "Включен редактор сетки, Маркер выключен");

						set_entvar(iEnt, var_nextthink, get_gametime() + 5.0);
						return;
					}
					g_bIsHoldingPaint[id] = true;
					
					func_GetAimOrigin(id, g_iOriginPaint[id]);
					func_MoveTowardClient(id, g_iOriginPaint[id]);
					
					g_iColorRed 	= random_num(1, 255);
					g_iColorGreen 	= random_num(1, 255);
					g_iColorBlue 	= random_num(1, 255);
					
					set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
					return;
				}

				func_GetAimOrigin(id, g_iOriginPaint[id]);
				func_MoveTowardClient(id, g_iOriginPaint[id]);

				flDistance = get_distance_f(g_iOriginPaint[id], flOrigin);

				if(flDistance > 2)
					func_StartPainting(g_iOriginPaint[id], flOrigin);
					
				//set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
				//return;
			}else g_bIsHoldingPaint[id] = false;
			
		}else g_bIsHoldingPaint[id] = false;
		
		
		#if defined STEPCHIEF
		if(jbe_get_stepchief() || !(get_entvar(id, var_flags) & FL_ONGROUND) || get_entvar(id, var_groundentity))
			continue;
	
		static Float:origin[3];
		static Float:last[3];

		get_entvar(id, var_origin, origin);
		if(get_distance_f(origin, last) < 32.0)
		{
			continue;
		}

		vec_copy(origin, last);
		if(get_entvar(id, var_bInDuck))
			origin[2] -= 18.0;
		else
			origin[2] -= 36.0;


		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0);
		write_byte(TE_WORLDDECAL);
		write_coord(floatround(origin[0]));
		write_coord(floatround(origin[1]));
		write_coord(floatround(origin[2]));
		write_byte(105);
		message_end();
		
		#endif
	
	//log_amx("logged");
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
}

/*func_StartPainting_Ex(Float:flOrigin1[3], Float:flOrigin2[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord_f(flOrigin1[0]);		// startposition x
	write_coord_f(flOrigin1[1]);		// startposition y
	write_coord_f(flOrigin1[2]);		// startposition z
	write_coord_f(flOrigin2[0]);		// endposition x
	write_coord_f(flOrigin2[1]);		// endposition y
	write_coord_f(flOrigin2[2]);		// endposition z
	write_short(g_pSpriteLightning);	// sprite index
	write_byte(0);						// starting frame
	write_byte(10);						// frame rate in 0.1's
	write_byte(1);		// life in 0.1's
	write_byte(25);						// line width in 0.1's
	write_byte(0);						// noise aimplitude in 0.01's
	write_byte(g_iColorRed);		// red
	write_byte(g_iColorGreen);		// green
	write_byte(g_iColorBlue);		// blue
	write_byte(255);					// brightness
	write_byte(0);						// scroll speed in 0.1's
	message_end();
}*/


func_StartPainting(Float:flOrigin1[3], Float:flOrigin2[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord_f(flOrigin1[0]);		// startposition x
	write_coord_f(flOrigin1[1]);		// startposition y
	write_coord_f(flOrigin1[2]);		// startposition z
	write_coord_f(flOrigin2[0]);		// endposition x
	write_coord_f(flOrigin2[1]);		// endposition y
	write_coord_f(flOrigin2[2]);		// endposition z
	write_short(g_pSpriteLightning);	// sprite index
	write_byte(0);						// starting frame
	write_byte(10);						// frame rate in 0.1's
	write_byte(LifeTime * 10);		// life in 0.1's
	write_byte(50);		
	write_byte(0);						// noise aimplitude in 0.01's
	write_byte(g_iColorRed);		// red
	write_byte(g_iColorGreen);		// green
	write_byte(g_iColorBlue);		// blue
	write_byte(255);					// brightness
	write_byte(0);						// scroll speed in 0.1's
	message_end();
}

func_GetAimOrigin(id, Float:flOrigin[3])
{
	static Float:flStart[3], Float:flViewOfs[3];
	get_entvar(id, var_origin, flStart);
	get_entvar(id, var_view_ofs, flViewOfs);
	xs_vec_add(flStart, flViewOfs, flStart);

	static Float:flDest[3];
	get_entvar(id, var_v_angle, flDest);
	engfunc(EngFunc_MakeVectors, flDest);
	global_get(glb_v_forward, flDest);
	xs_vec_mul_scalar(flDest, 9999.0, flDest);
	xs_vec_add(flStart, flDest, flDest);

	engfunc(EngFunc_TraceLine, flStart, flDest, 0, id, 0);
	get_tr2(0, TR_vecEndPos, flOrigin);
}

stock func_MoveTowardClient(id, Float:flOrigin[3])
{
	static Float:flPlayerOrigin[3];

	get_entvar(id, var_origin, flPlayerOrigin);

	flOrigin[0] += (flPlayerOrigin[0] > flOrigin[0]) ? 1.0 : -1.0;
	flOrigin[1] += (flPlayerOrigin[1] > flOrigin[1]) ? 1.0 : -1.0;
	flOrigin[2] += (flPlayerOrigin[2] > flOrigin[2]) ? 1.0 : -1.0;
}

bool:func_IsAimingAtSky(id)
{
	new Float:flOrigin[3];
	func_GetAimOrigin(id, flOrigin);
	return (engfunc(EngFunc_PointContents, flOrigin) == CONTENTS_SKY);
}


stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

/*public jbe_save_stats(pId)
{
	jbe_mysql_stats_systems_add(pId, 6, g_TotalChiefPlayerTime[pId]) 
	g_TotalChiefPlayerTime[pId] = 0;
}

public jbe_load_stats(pId)
{
	g_TotalChiefPlayerTime[pId] = 0;
	g_TotalChiefPlayerTime[pId] = jbe_mysql_stats_systems_get(pId, 6);
}*/

LOAD_CONFIGURATION()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
// CONFIG.INI
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/config.ini", szCfgDir);
	if(!file_exists(szCfgFile))
	{
		new szError[100];
		formatex(szError, charsmax(szError), "[JBE] Отсутсвтует: %s!", szCfgFile);
		set_fail_state(szError);
		return;
	}
	new szBuffer[128], szKey[64], szValue[960], iSectrion;
	new iFile = fopen(szCfgFile, "rt");
	while(iFile && !feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer));
		replace(szBuffer, charsmax(szBuffer), "^n", "");
		if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '{' || szBuffer[0] == '}' || szBuffer[0] == '#') continue;
		if(szBuffer[0] == '[')
		{
			iSectrion++;
			continue;
		}
		parse(szBuffer, szKey, charsmax(szKey), szValue, charsmax(szValue));
		trim(szKey);
		trim(szValue);
		
	
		switch (iSectrion)
		{
			case SELECT_PRISON:
			{		
				if(equal(szKey, 	"V_GOLDEN_AK47")) 					copy(g_szPlayerHand[GOLDEN_AK47_V], 			charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"P_GOLDEN_AK47")) 				copy(g_szPlayerHand[GOLDEN_AK47_P], 			charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"V_ELECTRO_MP5")) 				copy(g_szPlayerHand[ELECTRO_MP5_V], 			charsmax(g_szPlayerHand[]), szValue);		
				else if(equal(szKey, 	"GOLDEN_AK_SHOT_1")) 			copy(g_szPlayerSound[GOLDEN_AK47_SHOT1_SOUND], 			charsmax(g_szPlayerSound[]), szValue);					
			}
			case SELECT_GUARD:
			{
			
			}
			case SELECT_CVARS:
			{

			}
			case SELECT_SOUND:
			{

			}
		}
	}
	fclose(iFile);

	PRECACHE_MODELS();
}

PRECACHE_MODELS()
{
	new i, szBuffer[64];
	for(i = 0; i < sizeof(g_szPlayerHand); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szPlayerHand[i]);
		engfunc(EngFunc_PrecacheModel, szBuffer);
	}
	
	for(i = 0; i < sizeof(g_szPlayerSound); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szPlayerSound[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
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

public HamHook_Item_PrimaryAttack(Weapon) 
{
	static Player;
	Player = fm_cs_get_weapon_ent_owner(Weapon);
	// Valid owner?
	if (!pev_valid(Player) || !g_iBitUserHaveGoldAK47)
		return;

	if(IsSetBit(g_iBitUserHaveGoldAK47, Player) && get_user_weapon(Player) == CSW_AK47)
	{
		emit_sound(Player, CHAN_WEAPON, g_szPlayerSound[GOLDEN_AK47_SHOT1_SOUND], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}


