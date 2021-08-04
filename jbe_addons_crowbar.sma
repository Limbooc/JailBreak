#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <jbe_core>
#include <engine>



#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)


//*Натив
//*Натив возвращает true если у игрока есть бабочки,катана и другие холодные оружие
//*для взаймодейстие и коректной работы рекемендуею зарегеситировать натив в главном моде
// ==> public jbe_has_user_weaponknife(pId) return IsSetBit(g_iBitWeaponStatus,pId);
native jbe_has_user_weaponknife(pId);
native jbe_iduel_status();

forward jbe_lr_duels();
//*Натив

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))




enum
{
	SELECT_SOUND = 1,
	SELECT_MODELS
};

enum
{
	SND_CROWBAR_DEPLOY = 1,
	SND_CROWBAR_HITWALL,
	SND_CROWBAR_SLASH,
	SND_CROWBAR_STAB,
	SND_CROWBAR_HIT,
	SND_CROWBAR_METAL
};

enum _:SOUND_HAND
{
	CROWBAR_DEPLOY = 1,
	CROWBAR_HITWALL,
	CROWBAR_SLASH,
	CROWBAR_STAB,
	CROWBAR_HIT,
	CROWBAR_METAL
};



enum _:PLAYER_HAND
{
	MDL_CROWBAR_P = 1,
	MDL_CROWBA_V,
	MDL_CROWBA_W
};

enum
{
	CROWBAR_P = 1,
	CROWBAR_V,
	CROWBAR_W
};

new bool:g_iRoundEnd,
	g_szKnifeSound[SOUND_HAND][64],
	g_szPlayerHand[PLAYER_HAND][64],
	g_iBitUserCrowbar;

public plugin_init()
{
	register_plugin("[JBE] Crowbar Players", "1.0", "DalgaPups");
	
	register_touch("crowbar", 					"player", 			"Touch_Crowbar")
	register_clcmd("drop", 						"ClCmd_Drop");
	
	RegisterHam(Ham_Item_Deploy, 				"weapon_knife", 	"Ham_KnifeDeploy_Post", 				true);
	register_forward(FM_EmitSound, 									"FakeMeta_EmitSound", 					false);
	
	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false);
	
	
	//register_event("HLTV", "Event_HLTV", 		"a", 	"1=0", "2=0");
	//register_logevent("LogEvent_RoundEnd", 		2, 		"1=Round_End");
	//register_logevent("LogEvent_RoundStart", 	2, 		"0=World triggered", "1=Round_Start");
}

public plugin_precache()
{
	LOAD_CONFIGURATION()
}

LOAD_CONFIGURATION()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/shop_config.ini", szCfgDir);
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
			case SELECT_SOUND:
			{
				if(equal(szKey, 		"SND_CROWBAR_DEPLOY"))			copy(g_szKnifeSound[CROWBAR_DEPLOY], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_CROWBAR_HITWALL")) 		copy(g_szKnifeSound[CROWBAR_HITWALL], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_CROWBAR_SLASH")) 			copy(g_szKnifeSound[CROWBAR_SLASH], 			charsmax(g_szKnifeSound[]), szValue);		
				else if(equal(szKey, 	"SND_CROWBAR_STAB")) 			copy(g_szKnifeSound[CROWBAR_STAB], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_CROWBAR_HIT")) 			copy(g_szKnifeSound[CROWBAR_HIT], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_CROWBAR_METAL")) 			copy(g_szKnifeSound[CROWBAR_METAL], 				charsmax(g_szKnifeSound[]), szValue);
				
			}
			case SELECT_MODELS:
			{
				if(equal(szKey, 		"MDL_CROWBAR_P"))				copy(g_szPlayerHand[CROWBAR_P], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_CROWBAR_V"))				copy(g_szPlayerHand[CROWBAR_V], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_CROWBAR_W"))				copy(g_szPlayerHand[CROWBAR_W], 		charsmax(g_szPlayerHand[]), szValue);
			}
		}
	}
	fclose(iFile);

	PRECACHE_MODELS();
}

PRECACHE_MODELS()
{
	new i, szBuffer[64];
	for(i = 0; i < sizeof(g_szKnifeSound); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szKnifeSound[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	for(i = 0; i < sizeof(g_szPlayerHand); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szPlayerHand[i]);
		engfunc(EngFunc_PrecacheModel, szBuffer);
	}
}

public plugin_natives()
{
	register_native("jbe_is_user_has_crowbar", "jbe_is_user_has_crowbar", 1);
	register_native("jbe_set_user_crowbar", "jbe_set_user_crowbar", 1);
	register_native("jbe_shop_knifeweapons", "jbe_shop_knifeweapons", 1);	
}

//*Возвращает true если игрок с ломом
public jbe_is_user_has_crowbar(pId) return IsSetBit(g_iBitUserCrowbar, pId);

//*Выдает игроку лом
public jbe_set_user_crowbar(pId)
{
	if(IsNotSetBit(g_iBitUserCrowbar, pId))
	{
		SetBit(g_iBitUserCrowbar, pId);
		if(get_user_weapon(pId) != CSW_KNIFE) engclient_cmd(pId, "weapon_knife");
		else
		{
			new iActiveItem = get_member(pId, m_pActiveItem);
			if(iActiveItem > 0)
			{
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				jbe_crowbar_knife_mdl(pId);
				UTIL_WeaponAnimation(pId, 3);
			}
		}
	}
}

//В магазине *можно(необязательно) вшить данный натив,чтобы игрок выкинул когда покупал холодное оружие
public jbe_shop_knifeweapons(pId)
{
	if(IsSetBit(g_iBitUserCrowbar, pId))
	{
		DropSpawn_Crowbar(pId);
		ClearBit(g_iBitUserCrowbar, pId);
		if(get_user_weapon(pId) == CSW_KNIFE)
		{
			new iActiveItem = get_member(pId, m_pActiveItem);
			if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
			UTIL_WeaponAnimation(pId, 3);
		}
	}
}

public LogEvent_RoundStart()
{		
	new iEnt = FM_NULLENT;
	
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "crowbar")))
		if(is_entity(iEnt))
			set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
			
	if(jbe_get_day_mode() == 1)
	{
		//set_task_ex(1.0, "Select_RandomPlayerCrowbar", 68758999);
	}
}

//forward jbe_fwr_roundend();
/*public jbe_fwr_roundend()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || IsNotSetBit(g_iBitUserCrowbar, i)) continue;
		
		DropSpawn_Crowbar(i);
		ClearBit(g_iBitUserCrowbar, i);
		if(get_user_weapon(i) == CSW_KNIFE)
		{
			new iActiveItem = get_member(i, m_pActiveItem);
			if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
			UTIL_WeaponAnimation(i, 3);
		}
	}
	g_iBitUserCrowbar = 0;
	g_iRoundEnd = true;
}*/

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iRoundEnd = false;
}


public FakeMeta_EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(jbe_is_user_valid(id))
	{
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e')
		{
			if(IsSetBit(g_iBitUserCrowbar, id) )
			{
				switch(szSample[17])
				{
					case 'l': emit_sound(id, iChannel, g_szKnifeSound[CROWBAR_DEPLOY], fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
					case 'w': emit_sound(id, iChannel, g_szKnifeSound[CROWBAR_HITWALL], fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
					case 's': emit_sound(id, iChannel, g_szKnifeSound[CROWBAR_SLASH], fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
					case 'b': emit_sound(id, iChannel, g_szKnifeSound[CROWBAR_STAB], fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					default: emit_sound(id, iChannel, g_szKnifeSound[CROWBAR_HIT], fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
				}
				return FMRES_SUPERCEDE;
			}
		}
	}
	return FMRES_IGNORED;
}

public client_disconnected(pId)
{
	if(!is_user_connected(pId)) return;
	if(IsSetBit(g_iBitUserCrowbar, pId))
	{
		DropSpawn_Crowbar(pId);
		ClearBit(g_iBitUserCrowbar, pId);
	}
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(IsSetBit(g_iBitUserCrowbar, iVictim))
	{
		DropSpawn_Crowbar(iVictim);
		ClearBit(g_iBitUserCrowbar, iVictim);
	}
}



public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		new Float:fDamageOld = fDamage;
		
		if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
		{
			if(IsSetBit(g_iBitUserCrowbar, iAttacker)) fDamage = (fDamage + (fDamage * 1.5));
		}
		if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
	}
	return HC_CONTINUE;
}



public Ham_KnifeDeploy_Post(iEntity)
{
	new id = get_member(iEntity, m_pPlayer);
	if(IsSetBit(g_iBitUserCrowbar, id) )
	{
		jbe_crowbar_knife_mdl(id);
		return;
	}

}





public ClCmd_Drop(id)
{
	if(IsSetBit(g_iBitUserCrowbar, id) && get_user_weapon(id) == CSW_KNIFE) 
	{
		ClearBit(g_iBitUserCrowbar, id);
		DropSpawn_Crowbar(id);

		if(get_user_weapon(id) == CSW_KNIFE)
		{
			new iActiveItem = get_member(id, m_pActiveItem);
			if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
		}
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE;
}


public DropSpawn_Crowbar(id)
{
	new ent;
	static iszInfoTarget = 0;
	if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) ent = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);

	if(!is_entity(ent)) return 0;
	
	set_entvar(ent, var_classname, "crowbar")
	set_entvar(ent,var_solid, SOLID_TRIGGER)
	set_entvar(ent, var_movetype, MOVETYPE_TOSS)
	engfunc(EngFunc_SetModel, ent, g_szPlayerHand[CROWBAR_W]);

	new Float:where[3]

	get_entvar(id, var_origin, where)
	where[0] += 0.0
	where[1] += 0.0
	where[2] += 50.0
	entity_set_origin(ent, where)
	where[0] = 200.0
	where[1] = 200.0
	where[2] = 200.0
	velocity_by_aim(id, 300, where)
	set_entvar(ent, var_velocity, where)

	return PLUGIN_HANDLED
}

public Select_RandomPlayerCrowbar()
{
	if(jbe_get_day_mode() == 1)
	{
		static iPlayers[MAX_PLAYERS], iPlayerCount;
		
		get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

		/*for(new i, Players; i < iPlayerCount; i++)
		{
			if(iPlayerCount)
			{
				Players = iPlayers[random(iPlayerCount)];
				if(jbe_is_user_alive(Players))
				{
					jbe_set_user_crowbar(Players)
				}
			}
		}*/

		new players[32], pnum;

        get_players_ex(players, pnum, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

        new i = random_num(0, pnum-1);


		if(jbe_is_user_alive(i))
		{
			jbe_set_user_crowbar(i)
		}
	
	}
}



public jbe_lr_duels()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || IsNotSetBit(g_iBitUserCrowbar, i)) continue;
		
		DropSpawn_Crowbar(i);
		ClearBit(g_iBitUserCrowbar, i);
	}

}


jbe_crowbar_knife_mdl(pPlayer)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szPlayerHand[CROWBAR_V]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szPlayerHand[CROWBAR_P]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.75);
}

public Touch_Crowbar(crowbar, player)
{
	if(IsNotSetBit(g_iBitUserCrowbar, player) && jbe_get_user_team(player) == 1 && !g_iRoundEnd)
	{
		if(jbe_has_user_weaponknife(player) || get_pdata_int(player, 510) & (1 << 24) || jbe_iduel_status()) return FMRES_IGNORED;

		jbe_set_user_crowbar(player)
		remove_entity(crowbar)
		emit_sound(player, CHAN_AUTO, g_szKnifeSound[CROWBAR_DEPLOY], 0.5, ATTN_NORM, 0, PITCH_NORM)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public Sound_Crowbar(id, world)
{
	new Float:v[3]
	
	entity_get_vector(id, EV_VEC_velocity, v)
	v[0] = (v[0] * 0.45)
	v[1] = (v[1] * 0.45)
	v[2] = (v[2] * 0.45)
	entity_set_vector(id, EV_VEC_velocity, v)
	
	return PLUGIN_CONTINUE	
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}