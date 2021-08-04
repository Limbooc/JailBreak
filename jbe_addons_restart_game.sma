#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>


#define MAX_SPEED		900.0
#define MAX_GRAVITY		0.4
forward jbe_fwr_restart_game(iType);
#define TASK_SPAWN_PLAYER 74564578


#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define linux_diff_weapon 4


new const ITEM_CLASSNAME[] = "weapon_knife";

new HookChain:HookPlayer_PlayerSpawnPost,
	HookChain:HookPlayer_PlayerKilledPost,
	//HookChain:HookPlayer_PlayerTakeDamage,
	HookChain:HookPlayer_ResetMaxSpeed,
	HookChain:HookPlayer_HcRoundEnd,
	HookChain:HookPlayer_ItemDeploy;

native jbe_set_friendlyfire(iType);
native jbe_Status_CustomSpawns(status);
native jbe_set_user_model_ex(pId, iType);
native jbe_top_damaget_status(status);
//native jbe_set_blocked_games_ct(bool:status);
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
new HamHook:g_iHamHookForwards[14];
new g_iFakeMetaEmitSound;
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

new g_szKnifeSound[SOUND_HAND][64],
	g_szPlayerHand[PLAYER_HAND][64];

new bool:g_bGame = true;
public plugin_init()
{
	register_plugin("[JBE] Addons RestartGame", "1.0", "DalgaPups");
	//register_event("CurWeapon", "Event_CurWeapon", "be", "1=1" )
	
	DisableHookChain(HookPlayer_ItemDeploy = 			RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", 		false));
	DisableHookChain(HookPlayer_PlayerSpawnPost = 		RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true));
	DisableHookChain(HookPlayer_PlayerKilledPost =		RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true));
	DisableHookChain(HookPlayer_ResetMaxSpeed =			RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 				"HookResetMaxSpeed", 				true));
	DisableHookChain(HookPlayer_HcRoundEnd 		= 	RegisterHookChain(RG_RoundEnd, 						"HC_RoundEnd_Pre", 						false));
	for(new i; i <= 8; i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, 		g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, 	g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
		
		
	g_iFakeMetaEmitSound = 		register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
	unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound);
	
	//DisableHookChain(HookPlayer_PlayerTakeDamage = RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Fall", false));
}
new g_pSpriteTrailHook;
public plugin_precache()
{	

	g_pSpriteTrailHook = precache_model("sprites/speed.spr");
	
	
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
				if(equal(szKey, 		"SND_SAW_DEPLOY"))			copy(g_szKnifeSound[CROWBAR_DEPLOY], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_HITWALL")) 		copy(g_szKnifeSound[CROWBAR_HITWALL], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_SLASH")) 			copy(g_szKnifeSound[CROWBAR_SLASH], 			charsmax(g_szKnifeSound[]), szValue);		
				else if(equal(szKey, 	"SND_SAW_STAB")) 			copy(g_szKnifeSound[CROWBAR_STAB], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_HIT")) 			copy(g_szKnifeSound[CROWBAR_HIT], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_METAL")) 			copy(g_szKnifeSound[CROWBAR_METAL], 				charsmax(g_szKnifeSound[]), szValue);
				
			}
			case SELECT_MODELS:
			{
				if(equal(szKey, 		"MDL_SAW_P"))				copy(g_szPlayerHand[CROWBAR_P], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_SAW_V"))				copy(g_szPlayerHand[CROWBAR_V], 		charsmax(g_szPlayerHand[]), szValue);
				//else if(equal(szKey, 	"MDL_CROWBAR_W"))				copy(g_szPlayerHand[CROWBAR_W], 		charsmax(g_szPlayerHand[]), szValue);
			}
		}
	}
	fclose(iFile);

}

public jbe_fwr_restart_game(iType)
{
	switch(iType)
	{
		case 0:
		{
			
			g_bGame = false;
			jbe_Status_CustomSpawns(false);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_alive(i)) continue;
				
				rg_remove_all_items(i);
				rg_give_item(i, "weapon_knife");
				rg_reset_maxspeed(i);
				set_entvar(i, var_gravity, 1.0);
				func_RemoveTrail(i);
			}
			
			jbe_set_friendlyfire(0);
			DisableHookChain(HookPlayer_PlayerSpawnPost);
			DisableHookChain(HookPlayer_ResetMaxSpeed);
			DisableHookChain(HookPlayer_PlayerKilledPost);
			DisableHookChain(HookPlayer_HcRoundEnd);
		//	DisableHookChain(HookPlayer_PlayerTakeDamage);
			unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound, true);
			DisableHookChain(HookPlayer_ItemDeploy);
			jbe_top_damaget_status(0);
			for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
			//jbe_set_blocked_games_ct(false);
		}
		case 1:
		{
			EnableHookChain(HookPlayer_PlayerSpawnPost);
			EnableHookChain(HookPlayer_PlayerKilledPost);
			EnableHookChain(HookPlayer_ResetMaxSpeed);
			EnableHookChain(HookPlayer_HcRoundEnd);
			jbe_top_damaget_status(true);
			//EnableHookChain(HookPlayer_PlayerTakeDamage);
			EnableHookChain(HookPlayer_ItemDeploy);
			g_iFakeMetaEmitSound = register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
			for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
			jbe_set_friendlyfire(3);
			jbe_Status_CustomSpawns(1);
			g_bGame = true;
			//set_cvar_num("mp_round_infinite", 1);
			//jbe_set_blocked_games_ct(true);
			
			
			/*for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_connected(i) || is_user_bot(i) || jbe_is_user_alive(i)) continue;
				
				rg_round_respawn(i);
			}*/
		}
	}
}



public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	rg_remove_all_items(pId);
	rg_give_item(pId, "weapon_knife");
	//jbe_crowbar_knife_mdl(pId)
	//jbe_shop_knifedeploy(pId)
	
	if(jbe_get_user_team(pId) == 2) 
	{
		jbe_set_user_model_ex(pId, 1);
		set_entvar(pId, var_health, 100.0);
	}
	UTIL_SayText(pId, "!g* !yЧтобы почувствовать максимальную скорость введите в консоле !gcl_forwardspeed 900");
	UTIL_SayText(pId, "!g* !yНе забудьте вернуть на стандартное значение, иначе престрейфы будут трудны !gcl_forwardspeed 400");
	func_SetTrail(pId)
	
	set_entvar(pId, var_maxspeed, MAX_SPEED); 
	set_entvar(pId, var_gravity, MAX_GRAVITY); 
	//set_entvar(pId, var_maxspeed, 900.0);
}
//public HC_CBasePlayer_PlayerKilled_Pre(iVictim , iKiller)
public HC_CBasePlayer_PlayerKilled_Post(iVictim , iKiller)
{
	if(jbe_is_user_valid(iKiller) && jbe_is_user_valid(iVictim))
	{
		set_task(3.0 , "spawn_player", iVictim + TASK_SPAWN_PLAYER)
					
		rg_send_bartime(iVictim, 3, false);
	
		func_RemoveTrail(iVictim);
		new damage = get_entvar(iVictim, var_dmg_take)
		
		if(damage < 1)
		{
			//return HC_CONTINUE;
		}

		else if(damage > 500)
		{	
			damage = 500
		}
		
		if(random_float(0.0, (1000.0 / damage)) > 1.0)
		{
			new
			
			Float:victim_origin[3],
			Float:killer_origin[3],
			max_damage
			
			get_entvar(iVictim, var_origin, victim_origin)
			victim_origin[2] += 17
			
			if(pev_valid(iKiller))
			{
				get_entvar(iKiller, var_origin, killer_origin)
				
				killer_origin[0] = (victim_origin[0] - killer_origin[0]) * random_float(0.5, 0.75)
				killer_origin[1] = (victim_origin[1] - killer_origin[1]) * random_float(0.5, 0.75)
				killer_origin[2] = floatsqroot(damage * get_distance_f(victim_origin, killer_origin))
			}
			else
			{
				killer_origin[0] = random_float(-256.0, 256.0)
				killer_origin[1] = random_float(-256.0, 256.0)
				killer_origin[2] = random_float(256.0, 1024.0)
			}
			
			switch(damage)
			{
				case 1..25:	max_damage = 75 	
				case 26..50:	max_damage = 82 	
				case 51..75:	max_damage = 89 		
				case 76..100:	max_damage = 96 		
				case 101..125:	max_damage = 103 	
				case 126..150:	max_damage = 110 	
				case 151..200:	max_damage = 117 	
				case 201..225:	max_damage = 124 	
				case 226..250:	max_damage = 131 	
				case 251..275:	max_damage = 138 	
				case 276..300:	max_damage = 145 	
				case 301..325:	max_damage = 152 	
				case 326..350:	max_damage = 159 	
				case 351..375:	max_damage = 166 	
				case 376..400:	max_damage = 173 	
				case 401..425:	max_damage = 180 	
				case 426..450:	max_damage = 187 	
				case 451..475:	max_damage = 194 	
				case 476..500:	max_damage = 201
			}
			
			blood_stream(victim_origin, killer_origin, max_damage)	
		
			
		}
	}
	return HC_CONTINUE;
}

public HookResetMaxSpeed(const pId)
{
	set_entvar(pId, var_maxspeed, MAX_SPEED);  
	set_entvar(pId, var_gravity, MAX_GRAVITY);  
}


public client_putinserver(id)
{
	if(g_bGame)
	{
		if(is_user_bot(id) || is_user_hltv(id)) return;
		
		set_task(3.0 , "spawn_player", id + TASK_SPAWN_PLAYER)
				
		if(is_user_connected(id)) rg_send_bartime(id, 3, false);
	}
}

public HamHook_EntityBlock(iEntity, pId)
{
	return HAM_SUPERCEDE;
}

public spawn_player(pId)
{
	pId -= TASK_SPAWN_PLAYER
	
	
	if(!jbe_is_user_connected(pId) || is_user_bot(pId)) return;
	
	if(!jbe_is_user_alive(pId))
		rg_round_respawn(pId);
		
	//server_print("spawn_player");
}

/*jbe_crowbar_knife_mdl(pPlayer)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szPlayerHand[CROWBAR_V]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szPlayerHand[CROWBAR_P]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_pdata_float(pPlayer, m_flNextAttack, 0.75);
}*/

/*jbe_shop_knifedeploy(pId)
{
	if(get_user_weapon(pId) == CSW_KNIFE)
	{
		new iActiveItem = get_member(pId, m_pActiveItem);
		if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
		UTIL_WeaponAnimation(pId, 3);
		//server_print("$eawswdas");
	}
	set_entvar(pId, var_maxspeed, MAX_SPEED); 
	set_entvar(pId, var_gravity, MAX_GRAVITY);  
}*/

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

public HC_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

public CBasePlayerWeapon_DefaultDeploy_Pre(const iEntity, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) {

    if (FClassnameIs(iEntity, ITEM_CLASSNAME)) 
	{

		new pId = get_member(iEntity, m_pPlayer);
		
		if(!is_user_connected(pId) || !is_user_alive(pId))
			return HC_CONTINUE;
		

		SetHookChainArg(2, ATYPE_STRING, g_szPlayerHand[CROWBAR_V]);
		SetHookChainArg(3, ATYPE_STRING, g_szPlayerHand[CROWBAR_P]);
		
		set_member(pId, m_flNextAttack, 0.75);
			
    }
	return HC_CONTINUE;
}



public FakeMeta_EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(jbe_is_user_valid(id))
	{
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e' && g_bGame)
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
	return FMRES_IGNORED;
}
#define BLOOD_COLOR_RED		247
#define BLOOD_STREAM_RED	70
#define CL_CORPSE_MSG		122 	// DOD = 126
#define BODY			0
blood_stream(Float:origin[], Float:velocity_vec[], damage)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	
	write_byte(TE_BLOODSTREAM)
	
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	
	engfunc(EngFunc_WriteCoord, velocity_vec[0])
	engfunc(EngFunc_WriteCoord, velocity_vec[1])
	engfunc(EngFunc_WriteCoord, velocity_vec[2])
	
	write_byte(BLOOD_STREAM_RED)
	write_byte(damage)
	
	message_end()
}

//Offsets to place blood is more realistic hit location
new Offset[8][3] = {{0,0,10},{0,0,30},{0,0,16},{0,0,10},{4,4,16},{-4,-4,16},{4,4,-12},{-4,-4,-12}}

#define BLOOD_SM_NUM 8
#define BLOOD_LG_NUM 2
new blood_small_red[BLOOD_SM_NUM];
//Forward for CS/CZ, DoD, TFC, TS
#include <fun>
public HC_CBasePlayer_TakeDamage_Fall(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker) && jbe_is_user_valid(iVictim))
		process_damage(iAttacker, iVictim, 0)
}

//This will process the damage info for all mods
process_damage(iAgressor, iVictim, iHitPlace)
{
	if (!pev_valid(iAgressor)) {
		iAgressor = iVictim
		iHitPlace = 0
	}

	//Crash/error check
	if (!jbe_is_user_connected(iVictim)) return
	if (iHitPlace < 0 || iHitPlace > 7) iHitPlace = 0

	new iOrigin[3], iOrigin2[3]
	get_origin_int(iVictim,iOrigin)
	get_origin_int(iAgressor,iOrigin2)

	fx_blood(iOrigin,iOrigin2,iHitPlace)
	fx_blood_small(iOrigin,8)

	fx_blood(iOrigin,iOrigin2,iHitPlace)
	fx_blood(iOrigin,iOrigin2,iHitPlace)
	fx_blood(iOrigin,iOrigin2,iHitPlace)
	fx_blood_small(iOrigin,4)
}

fx_blood(origin[3],origin2[3],HitPlace)
{
	//Crash Checks
	if (HitPlace < 0 || HitPlace > 7) HitPlace = 0
	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1

	new rX = ((origin[0]-origin2[0]) * 3000) / rDistance
	new rY = ((origin[1]-origin2[1]) * 3000) / rDistance
	new rZ = ((origin[2]-origin2[2]) * 3000) / rDistance

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0]+Offset[HitPlace][0])
	write_coord(origin[1]+Offset[HitPlace][1])
	write_coord(origin[2]+Offset[HitPlace][2])
	write_coord(rX) // x
	write_coord(rY) // y
	write_coord(rZ) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(100,200)) // speed
	message_end()
}

//Custom function to get origin with FM and return it as an integer
public get_origin_int(index, origin[3])
{
	new Float:FVec[3]

	get_entvar(index,var_origin,FVec)

	origin[0] = floatround(FVec[0])
	origin[1] = floatround(FVec[1])
	origin[2] = floatround(FVec[2])

	return 1
}

fx_blood_small(origin[3],num)
{
	for (new j = 0; j < num; j++) 
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-100,100))
		write_coord(origin[1]+random_num(-100,100))
		write_coord(origin[2]-36)
		write_byte(blood_small_red[random_num(0,BLOOD_SM_NUM - 1)]) // index
		message_end()
	}
}

func_SetTrail(id)
{
	if(!jbe_is_user_connected(id)) return;
	
	//new iColor = random_num(1, 255);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);					// entity
	write_short(g_pSpriteTrailHook);	// sprite index
	write_byte(2 * 10);		// life
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

