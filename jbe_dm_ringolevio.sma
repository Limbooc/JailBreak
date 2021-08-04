#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <jbe_core>
#include <reapi>
#pragma semicolon 1

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

#define MsgId_ScreenFade 98

#define IUSER1_DEATH_TIMER 754645
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)
#define TASK_DEATH_TIMER 785689
#define TASK_PROTECTION_TIME 125908
#define TASK_DEFROST_TIME_CT 64574588


new g_iFreezeTimeCt;

new g_iDayModeRingolevio, g_iBitUserGame, g_iBitUserFrozen, g_iUserTeam[MAX_PLAYERS + 1], g_iUserEntityTimer[MAX_PLAYERS + 1],
Float:g_fUserDeathTimer[MAX_PLAYERS + 1], g_iUserLife[MAX_PLAYERS + 1], g_pSpriteFrost, g_pModelFrost,
g_iFakeMetaAddToFullPack, g_iFakeMetaCheckVisibility, HamHook:g_iHamHookForwards[15];
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

public plugin_precache()
{
	//engfunc(EngFunc_PrecacheModel, "models/jb_engine/days_mode/ringolevio/p_candy_cane.mdl");
	//engfunc(EngFunc_PrecacheModel, "models/jb_engine/days_mode/ringolevio/v_candy_cane.mdl");
	g_pSpriteFrost = engfunc(EngFunc_PrecacheModel, "sprites/jb_engine/frostgib.spr");
	g_pModelFrost = engfunc(EngFunc_PrecacheModel, "models/jb_engine/days_mode/ringolevio/frostgibs.mdl");
	engfunc(EngFunc_PrecacheSound, "jb_engine/days_mode/ringolevio/defrost_player.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/days_mode/ringolevio/freeze_player.wav");
	engfunc(EngFunc_PrecacheGeneric, "sound/jb_engine/days_mode/ringolevio/ambience.mp3");
	engfunc(EngFunc_PrecacheModel, "sprites/jb_engine/death_timer.spr");
}

public plugin_init()
{
	register_plugin("[JBE_DM] Ringolevio", "1.1", "Freedo.m");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	DisableHamForward(g_iHamHookForwards[13] = RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_Pre", 0));
	DisableHamForward(g_iHamHookForwards[14] = RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", 1));
	g_iDayModeRingolevio = jbe_register_day_mode("JBE_DAY_MODE_RINGOLEVIO", 2, 152);

}

public client_disconnected(id)
{
	if(IsSetBit(g_iBitUserFrozen, id))
	{
		ClearBit(g_iBitUserFrozen, id);
		if(pev_valid(g_iUserEntityTimer[id])) set_pev(g_iUserEntityTimer[id], pev_flags, pev(g_iUserEntityTimer[id], pev_flags) | FL_KILLME);
	}
	ClearBit(g_iBitUserGame, id);
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;
public Ham_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vecDeriction[3], iTrace, iBitDamage)
{
	if(IsSetBit(g_iBitUserGame, iAttacker) && jbe_is_user_valid(iAttacker))
	{
		switch(jbe_get_user_team(iAttacker))
		{
			case 1: if(IsSetBit(g_iBitUserFrozen, iVictim) && jbe_get_user_team(iVictim) == 1) jbe_dm_user_defrost(iVictim/*, iAttacker*/);
			case 2: if(IsNotSetBit(g_iBitUserFrozen, iVictim) && jbe_get_user_team(iVictim) == 1 && !task_exists(iVictim+TASK_PROTECTION_TIME)) jbe_dm_user_freeze(iVictim, iAttacker);
		}
	}
	return HAM_SUPERCEDE;
}
public Ham_PlayerKilled_Post(iVictim) ClearBit(g_iBitUserGame, iVictim);

jbe_dm_user_defrost(iVictim/*, iAttacker*/)
{
	if(task_exists(iVictim+TASK_DEATH_TIMER)) remove_task(iVictim+TASK_DEATH_TIMER);
	ClearBit(g_iBitUserFrozen, iVictim);
	set_pev(iVictim, pev_flags, pev(iVictim, pev_flags) & ~FL_FROZEN);
	set_member(iVictim, m_flNextAttack, 0.0);
	fm_set_user_rendering(iVictim, kRenderFxGlowShell, 255.0, 0.0, 0.0, kRenderNormal, 0.0);
	set_task(3.0, "jbe_dm_protection_time", iVictim+TASK_PROTECTION_TIME);
	UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 32, 164, 241, 200, 1);
	new Float:fOrigin[3];
	pev(iVictim, pev_origin, fOrigin);
	CREATE_BREAKMODEL(fOrigin, _, _, 10, g_pModelFrost, 10, 25, BREAK_GLASS);
	emit_sound(iVictim, CHAN_AUTO, "jb_engine/days_mode/ringolevio/defrost_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	if(pev_valid(g_iUserEntityTimer[iVictim])) set_pev(g_iUserEntityTimer[iVictim], pev_flags, pev(g_iUserEntityTimer[iVictim], pev_flags) | FL_KILLME);
	//if(iAttacker) g_iUserLife[iAttacker]++; //Почему то не отнимается антифриз
}

public jbe_dm_protection_time(id)
{
	id -= TASK_PROTECTION_TIME;
	if(IsSetBit(g_iBitUserGame, id)) fm_set_user_rendering(id, kRenderFxNone, 255.0, 0.0, 0.0, kRenderNormal, 0.0);
}

jbe_dm_user_freeze(iVictim, iAttacker)
{
	if(--g_iUserLife[iVictim])
	{
		SetBit(g_iBitUserFrozen, iVictim);
		set_member(iVictim, m_flNextAttack, 20.0);
		fm_set_user_rendering(iVictim, kRenderFxGlowShell, 32.0, 164.0, 241.0, kRenderNormal, 0.0);
		UTIL_ScreenFade(iVictim, 0, 0, 4, 32, 164, 241, 200);
		new Float:vecOrigin[3];
		pev(iVictim, pev_origin, vecOrigin);
		set_pev(iVictim, pev_flags, pev(iVictim, pev_flags) | FL_FROZEN);
		set_pev(iVictim, pev_origin, vecOrigin);
		vecOrigin[2] += 15.0;
		CREATE_SPRITETRAIL(vecOrigin, g_pSpriteFrost, 30, 20, 2, 20, 10);
		g_fUserDeathTimer[iVictim] = 20.0;
		jbe_dm_create_death_timer(iVictim, vecOrigin);
		emit_sound(iVictim, CHAN_AUTO, "jb_engine/days_mode/ringolevio/freeze_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		new iArg[1]; iArg[0] = iAttacker;
		set_task(1.0, "jbe_dm_user_death_timer", iVictim+TASK_DEATH_TIMER, iArg, sizeof(iArg), "a", 20);
	}
	else ExecuteHamB(Ham_Killed, iVictim, iAttacker, 2);
}

public jbe_dm_user_death_timer(const iAttacker[], iVictim)
{
	iVictim -= TASK_DEATH_TIMER;
	if(IsNotSetBit(g_iBitUserFrozen, iVictim) && task_exists(iVictim+TASK_DEATH_TIMER))
	{
		remove_task(iVictim+TASK_DEATH_TIMER);
		return;
	}
	if(g_fUserDeathTimer[iVictim] -= 1.0) return;
	ClearBit(g_iBitUserFrozen, iVictim);
	set_pev(iVictim, pev_flags, pev(iVictim, pev_flags) & ~FL_FROZEN);
	fm_set_user_rendering(iVictim, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
	UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 32, 164, 241, 200, 1);
	ExecuteHamB(Ham_Killed, iVictim, iAttacker[0], 2);
	if(pev_valid(g_iUserEntityTimer[iVictim])) set_pev(g_iUserEntityTimer[iVictim], pev_flags, pev(g_iUserEntityTimer[iVictim], pev_flags) | FL_KILLME);
}

public jbe_day_mode_start(iDayMode, iAdmin)
{
	if(iDayMode == g_iDayModeRingolevio)
	{

		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i)) continue;
			
			SetBit(g_iBitUserGame, i);
			//fm_strip_user_weapons(i);
			rg_remove_all_items(i);
			fm_give_item(i, "weapon_knife");
			set_pev(i, pev_gravity, 0.3);
			switch(jbe_get_user_team(i))
			{
				case 1:
				{
					g_iUserTeam[i] = 1;
					set_pev(i, pev_maxspeed, 380.0);
					g_iUserLife[i] = 3;
				}
				case 2:
				{
					g_iUserTeam[i] = 2;
					/*static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/jb_engine/days_mode/ringolevio/v_candy_cane.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/jb_engine/days_mode/ringolevio/p_candy_cane.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);*/
					set_pev(i, pev_maxspeed, 400.0);
					
					
					//set_pdata_float(i, m_flNextAttack, 10.0, lunux_offset_player);
					set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN);
					set_pev(i, pev_takedamage, DAMAGE_NO);
					//UTIL_ScreenFade(i,  0, 0, 4, 0, 0, 0, 255, 1);
				}
			}
		}
		for(new i = 0; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		g_iFakeMetaAddToFullPack = register_forward(FM_AddToFullPack, "FakeMeta_AddToFullPack_Post", 1);
		g_iFakeMetaCheckVisibility = register_forward(FM_CheckVisibility, "FakeMeta_CheckVisibility", 0);
		
		g_iFreezeTimeCt = 11;
		jbe_defrost_ct();
		set_task_ex(1.0, "jbe_defrost_ct",TASK_DEFROST_TIME_CT , _, _, SetTask_RepeatTimes, g_iFreezeTimeCt);
	}
}

public jbe_defrost_ct()
{
	if(--g_iFreezeTimeCt)
	{
		set_dhudmessage(255, 255, 255, -1.0, 0.2, 0, 1.0, 1.0);
		show_dhudmessage(0, "У заключённых %d секунд для^nФОРЫ!!", g_iFreezeTimeCt);
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 2) continue;
			
			//UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
			set_pev(i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN);
			
		}
		client_cmd(0, "mp3 play sound/jb_engine/days_mode/ringolevio/ambience.mp3");
	
	}
}
public FakeMeta_AddToFullPack_Post(ES_Handle, iE, iEntity, iHost, iHostFlags, iPlayer, pSet)
{
	if(!pev_valid(iEntity) || pev(iEntity, pev_iuser1) != IUSER1_DEATH_TIMER) return FMRES_IGNORED;
	if(IsNotSetBit(g_iBitUserGame, iHost) || g_iUserTeam[iHost] == 2)
	{
		static iEffects;
		if(!iEffects) iEffects = get_es(ES_Handle, ES_Effects);
		set_es(ES_Handle, ES_Effects, iEffects | EF_NODRAW);
		return FMRES_IGNORED;
	}
	new Float:vecHostOrigin[3], Float:vecEntityOrigin[3], Float:vecEndPos[3], Float:vecNormal[3];
	pev(iHost, pev_origin, vecHostOrigin);
	pev(iEntity, pev_origin, vecEntityOrigin);
	new pTr = create_tr2();
	engfunc(EngFunc_TraceLine, vecHostOrigin, vecEntityOrigin, IGNORE_MONSTERS, iEntity, pTr);
	get_tr2(pTr, TR_vecEndPos, vecEndPos);
	get_tr2(pTr, TR_vecPlaneNormal, vecNormal);
	xs_vec_mul_scalar(vecNormal, 10.0, vecNormal);
	xs_vec_add(vecEndPos, vecNormal, vecNormal);
	set_es(ES_Handle, ES_Origin, vecNormal);
	new Float:fDist, Float:fScale;
	fDist = get_distance_f(vecNormal, vecHostOrigin);
	fScale = fDist / 300.0;
	if(fScale < 0.4) fScale = 0.4;
	else if(fScale > 1.0) fScale = 1.0;
	set_es(ES_Handle, ES_Scale, fScale);
	set_es(ES_Handle, ES_Frame, g_fUserDeathTimer[pev(iEntity, pev_iuser2)]);
	free_tr2(pTr);
	return FMRES_IGNORED;
}

public FakeMeta_CheckVisibility(iEntity, pSet)
{
	if(!pev_valid(iEntity) || pev(iEntity, pev_iuser1) != IUSER1_DEATH_TIMER) return FMRES_IGNORED;
	forward_return(FMV_CELL, 1);
	return FMRES_SUPERCEDE;
}

public jbe_dm_create_death_timer(id, Float:vecOrigin[3])
{
	static iszInfoTarget = 0;
	if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) g_iUserEntityTimer[id] = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
	if(!pev_valid(g_iUserEntityTimer[id])) return;
	vecOrigin[2] += 35.0;
	set_pev(g_iUserEntityTimer[id], pev_classname, "death_timer");
	set_pev(g_iUserEntityTimer[id], pev_origin, vecOrigin);
	set_pev(g_iUserEntityTimer[id], pev_iuser1, IUSER1_DEATH_TIMER);
	set_pev(g_iUserEntityTimer[id], pev_iuser2, id);
	engfunc(EngFunc_SetModel, g_iUserEntityTimer[id], "sprites/jb_engine/death_timer.spr");
	fm_set_user_rendering(g_iUserEntityTimer[id], kRenderFxNone, 0.0, 0.0, 0.0, kRenderTransAdd, 255.0);
	set_pev(g_iUserEntityTimer[id], pev_solid, SOLID_NOT);
	set_pev(g_iUserEntityTimer[id], pev_movetype, MOVETYPE_NONE);
}

public jbe_day_mode_ended(iDayMode, iWinTeam)
{
	if(iDayMode == g_iDayModeRingolevio)
	{
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		unregister_forward(FM_AddToFullPack, g_iFakeMetaAddToFullPack, 1);
		unregister_forward(FM_CheckVisibility, g_iFakeMetaCheckVisibility, 0);
		for(i = 1; i <= MaxClients; i++)
		{
			if(IsSetBit(g_iBitUserGame, i))
			{
				switch(jbe_get_user_team(i))
				{
					case 1:
					{
						//fm_strip_user_weapons(i, 1);
						rg_remove_all_items(i);
						if(IsSetBit(g_iBitUserFrozen, i)) jbe_dm_user_defrost(i/*, 0*/);
					}
					case 2:
					{
						if(iWinTeam) rg_remove_all_items(i);
						else ExecuteHamB(Ham_Killed, i, i, 0);
					}
				}
				jbe_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);

			}
		}
		g_iBitUserGame = 0;
		g_iBitUserFrozen = 0;
		client_cmd(0, "mp3 stop");
	}
}

stock fm_give_item(id, const szItem[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:fOrigin[3];
	pev(id, pev_origin, fOrigin);
	set_pev(iEntity, pev_origin, fOrigin);
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



stock fm_set_user_rendering(id, iRenderFx, Float:flRed, Float:flGreen, Float:flBlue, iRenderMode,  Float:flRenderAmt)
{
	new Float:fRenderColor[3];
	fRenderColor[0] = flRed;
	fRenderColor[1] = flGreen;
	fRenderColor[2] = flBlue;
	set_pev(id, pev_renderfx, iRenderFx);
	set_pev(id, pev_rendercolor, fRenderColor);
	set_pev(id, pev_rendermode, iRenderMode);
	set_pev(id, pev_renderamt, flRenderAmt);
}

stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_SPRITETRAIL(const Float:fOrigin[3], pSprite, iCount, iLife, iScale, iVelocityAlongVector, iRandomVelocity)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSprite);
	write_byte(iCount);
	write_byte(iLife); // 0.1's
	write_byte(iScale);
	write_byte(iVelocityAlongVector);
	write_byte(iRandomVelocity);
	message_end(); 
}

stock CREATE_BREAKMODEL(const Float:fOrigin[3], Float:fSize[3] = {16.0, 16.0, 16.0}, Float:fVelocity[3] = {25.0, 25.0, 25.0}, iRandomVelocity, pModel, iCount, iLife, iFlags)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 24);
	engfunc(EngFunc_WriteCoord, fSize[0]);
	engfunc(EngFunc_WriteCoord, fSize[1]);
	engfunc(EngFunc_WriteCoord, fSize[2]);
	engfunc(EngFunc_WriteCoord, fVelocity[0]);
	engfunc(EngFunc_WriteCoord, fVelocity[1]);
	engfunc(EngFunc_WriteCoord, fVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(pModel);
	write_byte(iCount); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iFlags);
	message_end();
}