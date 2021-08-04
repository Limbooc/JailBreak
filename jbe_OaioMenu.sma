#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>

#define PLUGIN	"[JBE] Oaio Menu"
#define VERSION	"3.0"
#define AUTHOR	"ALIK | Modified for Reapi by DalgaPups"

#define PLAYERS_PER_PAGE 8

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iMenuTarget[MAX_PLAYERS + 1]

// #define DEF_RESET_WPN

#define PREFIX	"^4*^1"

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

native jbe_globalnyizapret()

native zl_boss_map();


#define ALL 0

/** pId */
#define IsValidPev(%1) (bool:(pev_valid(%1) == 2))

/** pId */
#define IsAlive(%1) (bool:(is_user_alive(%1)))

#if defined client_disconnected
	#define player_disconnect client_disconnected
#else
	#define player_disconnect client_disconnect
#endif


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


#define rg_set_weapon_ammo(%0,%1) set_member(%0, m_Weapon_iClip, %1)

/** pId, ADMIN_ */
#define IsFlag(%1,%2) (bool:(get_user_flags(%1) & %2))

/** pId, TEAM_ */
#define IsTeam(%1,%2) (jbe_get_user_team(%1) == %2)

/** szMenu, iLen, szMenuTitle */
#define MENU_TITLE(%1,%2,%3) (%2 = formatex(%1[%2], charsmax(%1) - %2, %3))

/** szMenu[], iLen, szItemName */
#define MENU_ITEM(%1,%2,%3) (%2 += formatex(%1[%2], charsmax(%1) - %2, %3))

/** pId, bitsKeys, szMenu, szMenuId */
#define SHOW_MENU(%1,%2,%3,%4) show_menu(%1, %2, %3, -1, %4)

/** szMenuId, szMenu_Handler */
#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)

/** pId */
#define Player_SetLife(%1) rg_round_respawn(%1)

/** pId */
#define Player_SetGodMode(%1) set_entvar(%1, var_takedamage, DAMAGE_NO)

/** pId */
#define Player_ResetGodMode(%1) set_entvar(%1, var_takedamage, DAMAGE_YES)

/** pId */
#define IsGodMode(%1) (bool:(get_entvar(%1, var_takedamage) == DAMAGE_NO))

/** pId, iGravity */
#define Player_SetGravity(%1) set_entvar(%1, var_gravity, CVAR_GRAVITY), g_bGravity[%1] = true

/** pId */
#define Player_ResetGravity(%1) set_entvar(%1, var_gravity, 1.0), g_bGravity[%1] = false

/** pId, iSpeed */
#define Player_SetSpeed(%1) \
	set_entvar(%1, var_maxspeed, float(CVAR_SPEED)), g_bSpeed[%1] = true

/** pId */
#define Player_ResetSpeed(%1) rg_reset_maxspeed(%1), g_bSpeed[%1] = false

/** pId */
#define Player_SetInvis(%1) \
	set_entvar(%1, var_renderfx, kRenderFxGlowShell), set_entvar(%1, var_rendercolor, {0.0, 0.0, 0.0}), set_entvar(%1, var_rendermode, kRenderTransAlpha), set_entvar(%1, var_renderamt, 0), g_bInvis[%1] = true
	
/** pId */
#define Player_ResetInvis(%1) \
	set_entvar(%1, var_renderfx, kRenderFxNone), set_entvar(%1, var_rendercolor, {255.0, 255.0, 255.0}), set_entvar(%1, var_rendermode, kRenderNormal), set_entvar(%1, var_renderamt, 18.0), g_bInvis[%1] = false
	
/** pId */
#define Player_SetGlow(%1,%2) \
	set_entvar(%1, var_renderfx, kRenderFxGlowShell), set_entvar(%1, var_rendercolor, %2), set_entvar(%1, var_rendermode, kRenderNormal), set_entvar(%1, var_renderamt, 18.0), g_bGlow[%1] = true


/** pId */
#define Player_ResetGlow(%1) \
	set_entvar(%1, var_renderfx, kRenderFxNone), set_entvar(%1, var_rendercolor, {255.0, 255.0, 255.0}), set_entvar(%1, var_rendermode, kRenderNormal), set_entvar(%1, var_renderamt, 18.0), g_bGlow[%1] = false
	
/** pId */
#define Player_SetNoClip(%1) set_entvar(%1, var_movetype, 8)

/** pId */
#define Player_ResetNoClip(%1) set_entvar(%1, var_movetype, 3)

/** pId */
#define IsNoClip(%1) (bool:(get_entvar(%1, var_movetype) == 8))

/** pId */
#define Player_SetNoSteps(%1) rg_set_user_footsteps(%1, true), g_bNoSteps[%1] = true

/** pId */
#define Player_ResetNoSpeps(%1) rg_set_user_footsteps(%1, false), g_bNoSteps[%1] = false

/** pId, pIda, iGibType */
#define Player_SetKill(%1,%2,%3) ExecuteHamB(Ham_Killed, %1, %2, %3)

/** pId, iHealth */
#define Player_SetHealth(%1,%2) set_entvar(%1, var_health, %2)

/** pId */
#define Player_GetHealth(%1) get_entvar(%1, var_health)

/** iMenuKey */
#define KEY(%0) (1 << (((%0) + 9) % 10))
#define KEY_HANDLER(%0) ((%0 + 1) % 10)

/** FUNCTION NAME, pId */
#define _HELP_MENU_CALLBACK(%0,%1) \
	Player_GetMenu_%0(%1, g_iPlayerMenuPage[%1], HELP_MENU_TITLE, HELP_MENU_ID, g_szItems_HepMenu, sizeof(g_szItems_HepMenu))

/** FUNCTION NAME, pId */
#define _PUNISH_MENU_CALLBACK(%0,%1) \
	Player_GetMenu_%0(%1, g_iPlayerMenuPage[%1], PUNISH_MENU_TITLE, PUNISH_MENU_ID, g_szItems_PunishMenu, sizeof(g_szItems_PunishMenu))

/** FUNCTION NAME, pId */
#define _OTHER_MENU_CALLBACK(%0,%1) \
	Player_GetMenu_%0(%1, g_iPlayerMenuPage[%1], OTHER_MENU_TITLE, OTHER_MENU_ID, g_szItems_OtherMenu, sizeof(g_szItems_OtherMenu))

/** FUNCTION NAME, pId */
#define _RESET_MENU_CALLBACK(%0,%1) \
	Player_GetMenu_%0(%1, g_iPlayerMenuPage[%1], RESET_MENU_TITLE, RESET_MENU_ID, g_szItems_ResetMenu, sizeof(g_szItems_ResetMenu))

/** FUNCTION NAME, pId */
#define _PLAYERS_MENU_CALLBACK(%0,%1) \
	Player_GetPlayersMenu_%0(%1, g_iPlayerMenuPage[%1], g_aPlayerType[%1][PL_TYPE_ME], g_aPlayerType[%1][PL_TYPE_TEAM], g_aPlayerType[%1][PL_TYPE_ALIVE], PLAYERS_MENU_TITLE, PLAYERS_MENU_ID)
	
#define OAIO_MENU_ID 		"OAIO MENU ID"
#define OAIO_MENU_TITLE 	"\yМеню выбора^n \d^"say /uaio^""
#define OAIO_MENU_ACCESS 	ADMIN_LEVEL_F

#define WEAPON_MENU_ID 		"OAIO WEAPON MENU ID"
#define WEAPON_MENU_TITLE 	"\yМеню выбора"

#define COLOR_MENU_ID 		"OAIO COLOR MENU ID"
#define COLOR_MENU_TITLE 	"\yМеню выбора"

#define CHOOSE_MENU_ID		"OAIO CHOOSE MENU ID"

#define PISTOLS_MENU_ID		"OAIO PISTOLS MENU ID"

#define RIFLES_MENU_ID		"OAIO RIFLES MENU ID"

#define SHOTGUNS_MENU_ID	"OAIO SHOTGUNS MENU ID"

#define HELP_MENU_ID		"OAIO HELP MENU ID"
#define HELP_MENU_TITLE		"\yВспомогательные команды"

#define PUNISH_MENU_ID		"OAIO PUNISH MENU ID"
#define PUNISH_MENU_TITLE	"\yНаказательные команды"

#define OTHER_MENU_ID		"OAIO OTHER MENU ID"
#define OTHER_MENU_TITLE	"\yОружейнная"

#define RESET_MENU_ID		"OAIO RESET MENU ID"
#define RESET_MENU_TITLE	"\yВернуть к стандарту"

#define PLAYERS_MENU_ID 	"OAIO PLAYERS MENU ID"
#define PLAYERS_MENU_TITLE 	"\yВыбор игрока"

enum (+= 1000)
{
	TASK_PLAYER_RESPAWN = 777,
	TASK_PLAYER_GRENADE,
	TASK_PLAYER_POSION,
	TASK_PLAYER_SHAKE,
	TASK_PLAYER_BURN
};

enum _:TOTAL_WEAPONS_RESET
{
	WPN_ALL,
	WPN_PRIMARY,
	WPN_SECONDARY,
	WPN_KNIFE,
	WPN_GRENADES
};

enum _:TOTAL_TEAMS
{
	TEAM_NULL,
	TEAM_PRISON,
	TEAM_GUARD
};

enum _:TOTAL_HELP_ITEMS
{
	ITEM_HELP_RESTORE, 		//Восстановить
	ITEM_HELP_HIDEWALL,		//Скрыть стены
	ITEM_HELP_GODMODE,		//Бессмертие
	ITEM_HELP_GRAVITY,		//Гравитация
	ITEM_HELP_SPEED,		//Скорость
	ITEM_HELP_INVIS,		//Невидимость
	ITEM_HELP_NOSTEPS,		//Бесшумные шаги
	ITEM_HELP_UNLIMAMMO,	//Бесконечные патроны
	ITEM_HELP_UNLIMHE,		//Бесконечные гранаты
	ITEM_HELP_GLOW			//Свечение
}

static const g_szItems_HepMenu[TOTAL_HELP_ITEMS][]=
{
	"Возродить",
	"Скрыть стены",
	"Бессмертие",
	"Гравитация",
	"Скорость",
	"Невидимость",
	"Бесшумные шаги",
	"Бесконечные патроны",
	"Бесконечные гранаты (HE)",
	"Свечение"
}

enum _:TOTAL_PUNISH_ITEMS
{
	ITEM_PUNISH_KILL,		//Убить
	ITEM_PUNISH_BURY,		//Закопать
	ITEM_PUNISH_MUTE,		//Вставить кляп
	ITEM_PUNISH_BURN,		//Поджечь
	ITEM_PUNISH_POSION,		//Отравить
	ITEM_PUNISH_STRIP,		//Лишить оружия
	ITEM_PUNISH_BLIND,		//Ослепить
	ITEM_PUNISH_GRUGS,		//Наркотики
	ITEM_PUNISH_SHAKE,		//Землетрясение
	ITEM_PUNISH_FROST		//Заморозить игрока
}

new g_iBitUserNotAttacked;

static const g_szItems_PunishMenu[TOTAL_PUNISH_ITEMS][]=
{
	"Убить",
	"Закопать",
	"Вставить кляп",
	"Поджечь",
	"Отравить",
	"Лишить оружия",
	"Ослепить",
	"Наркотики",
	"Землетрясение",
	"Заморозить"
}

enum _:TOTAL_OTHER_ITEMS
{
	ITEM_OTHER_EDITWPN		//Редактировать оружие
}

static const g_szItems_OtherMenu[TOTAL_OTHER_ITEMS][]=	
{
	"Редактировать оружие"
}

enum _:TOTAL_RESET_ITEMS
{
	ITEM_RESET_INVIS,		//Убрать невидимость
	ITEM_RESET_FROST,		//Разморозить
	ITEM_RESET_SHAKE,		//Убрать землетресение
	ITEM_RESET_DRUGS,		//Убрать наркотики
	ITEM_RESET_BLIND,		//Венуть зрение
	ITEM_RESET_SPEED,		//Убрать скорость
	ITEM_RESET_GRAVITY,		//Убрать гравитацию
	ITEM_RESET_HIDEWALL,	//Вернуть стены
	ITEM_RESET_GODMODE,		//Убрать бессмертие
	ITEM_RESET_GLOW,		//Убрать свечение
	ITEM_RESET_UNLIMAMMO,	//Убрать беск. патроны
	ITEM_RESET_UNLIMHE,		//Убрать беск. гранаты
	ITEM_RESET_NOSTEPS,		//Убрать бесшумные шаги
	ITEM_RESET_BURN,		//Потушить игрока
	ITEM_RESET_POSION,		//Вылечить от яда
	ITEM_RESET_MUTE,		//Убрать кляп
	ITEM_RESET_BURY			//Потушить игрока
}

static const g_szItems_ResetMenu[TOTAL_RESET_ITEMS][]=
{
	"Невидимость",
	"Разморозить",
	"Землетрясение",
	"Наркотики",
	"Вернуть зрение",
	"Скорость",
	"Гравитацию",
	"Скрыть стены",
	"Бессмертие",
	"Свечение",
	"Бесконечные патроны",
	"Бесконечные гранаты (HE)",
	"Бесшумные шаги",
	"Потушить игрока",
	"Излечить отравление",
	"Снять кляп",
	"Раскопать"
}

#define TOTAL_PISTOLS 6
static const g_szWeapon_Pistols[TOTAL_PISTOLS * 2][]=
{
	"GLOCK 18", 		"weapon_glock18",
	"USP", 				"weapon_usp",
	"P228 COMBAT", 		"weapon_p228",
	"DESERT DEAGLE", 	"weapon_deagle",
	"FIVE-SEVEN", 		"weapon_fiveseven",
	"ЩИТ", 				"weapon_shield"
}

#define TOTAL_SHOTGUNS 8
static const g_szWeapon_Shotguns[TOTAL_SHOTGUNS * 2][]=
{
	"LEONE SUPER M3", 	"weapon_m3",
	"LEONE XM1014", 	"weapon_xm1014",
	"MAC 10", 			"weapon_mac10",
	"MP5 NAVY", 		"weapon_mp5navy",
	"UMP45", 			"weapon_ump45",
	"P90", 				"weapon_p90",
	"GALIL", 			"weapon_galil",
	"M249", 			"weapon_m249"
}

#define TOTAL_RIFLES 9
static const g_szWeapon_Rifles[TOTAL_RIFLES * 2][]=
{
	"M4A1", 			"weapon_m4a1",
	"AK47", 			"weapon_ak47",
	"AWP",		 		"weapon_awp",
	"AUG", 				"weapon_aug",
	"SG550", 			"weapon_sg550",
	"FAMAS", 			"weapon_famas",
	"SG552", 			"weapon_sg552",
	"SCOUT", 			"weapon_scout",
	"G3SG1", 			"weapon_g3sg1"
}

#define TOTAL_COLORS 5

new Float:g_flColor[TOTAL_COLORS][3]=
{
	{255.0, 0.0, 0.0}, {0.0, 0.0, 255.0}, {255.0, 200.0, 3.0}, {0.0, 255.0, 0.0}, {247.0, 0.0, 108.0}
}

static const g_szColor[TOTAL_COLORS][]=
{
	"Красный", "Синий", "Жёлтый", "Зелёный", "Розовый"
}

enum _:TOTAL_ITEM_TYPES
{
	ITEM_TYPE_HELP,
	ITEM_TYPE_PUNISH,
	ITEM_TYPE_OTHER,
	ITEM_TYPE_RESET
};
new g_iPlayerItemType[33];
	
	/** pId */
	#define Player_GetMenuItemType(%1) g_iPlayerItemType[%1]
	
	/** pId, ITEM_TYPE_ */
	#define Player_SetMenuItemType(%1,%2) (g_iPlayerItemType[%1] = %2)

new g_iPlayerMenuPage[33], g_iPlayerMenuTarget[33][32];

	/** pId, iKey */
	#define Player_GetMenuItemTarget(%1,%2) (g_iPlayerMenuTarget[%1][(g_iPlayerMenuPage[%1] * 7) + %2])

new g_iPlayerMenuItem[33];

	/** pId */
	#define Player_GetMenuItem(%1) g_iPlayerMenuItem[%1]
	
	/** pId, ITEM_ */
	#define Player_SetMenuItem(%1,%2) (g_iPlayerMenuItem[%1] = %2)

enum _:TOTAL_CHOOSE_PRISONYPES
{
	CHOOSE_PRISON,
	CHOOSE_GUARD,
	CHOOSE_ID
};
new g_iPlayerItemChoose[33];
	
	/** pId */
	#define Player_GetItemChoose(%1) g_iPlayerItemChoose[%1]
	
	/** pId, CHOOSE_ */
	#define Player_SetItemChoose(%1,%2) (g_iPlayerItemChoose[%1] = %2)
	
enum _:TOTAL_PLAYER_TYPES
{
	PL_TYPE_TEAM,
	PL_TYPE_ALIVE,
	
	bool:PL_TYPE_ME
};
new g_aPlayerType[33][TOTAL_PLAYER_TYPES];

new g_iPlayerValue[33], g_iPlayerTarget[33],
	
	g_iModelIndex_RockGibs, g_iModelIndex_Frost,
	
	g_iSpriteIndex_Smoke, g_iSpriteIndex_Flame;

new bool:g_bGravity[33];
	
	/** pId */
	#define IsGravity(%1) g_bGravity[%1]
	
new bool:g_bSpeed[33];
	
	/** pId */
	#define IsSpeed(%1) g_bSpeed[%1]

new bool:g_bUnlimAmmo[33];
	
	/** pId */
	#define IsUnlimAmmo(%1) g_bUnlimAmmo[%1]
	#define Player_SetUnlimAmmo(%1) (g_bUnlimAmmo[%1] = true)
	#define Player_ResetUnlimAmmo(%1) (g_bUnlimAmmo[%1] = false)
	
new bool:g_bUnlimHe[33];
	
	/** pId */
	#define IsUnlimHe(%1) g_bUnlimHe[%1]
	#define Player_SetUnlimHe(%1) g_bUnlimHe[%1] = true, rg_give_item_ex(%1, "weapon_hegrenade", .ammount = 255)
	#define Player_ResetUnlimHe(%1) g_bUnlimHe[%1] = false, rg_remove_items_by_slot(%1, GRENADE_SLOT)

new bool:g_bInvis[33];

	/** pId */
	#define IsInvis(%1) g_bInvis[%1]

new bool:g_bGlow[33];
	
	/** pId */
	#define IsGlow(%1) g_bGlow[%1]

new bool:g_bBury[33];
	
	/** pId */
	#define IsBury(%1) g_bBury[%1]
	
new bool:g_bMute[33];

	/** pId */
	#define IsMute(%1) g_bMute[%1]
	#define Player_SetMute(%1) (g_bMute[%1] = true)
	#define Player_ResetMute(%1) (g_bMute[%1] = false)

new bool:g_bBurn[33];
	
	/** pId */
	#define IsBurn(%1) g_bBurn[%1]

new bool:g_bBlind[33];
	
	/** pId */
	#define IsBlind(%1) g_bBlind[%1]

new bool:g_bDrugs[33];

	/** pId */
	#define IsDrugs(%1) g_bDrugs[%1]
	
new bool:g_bPoison[33];
	
	/** pId */
	#define IsPoison(%1) g_bPoison[%1]

new bool:g_bShake[33];
	
	/** pId */
	#define IsShake(%1) g_bShake[%1]

new bool:g_bNoSteps[33];

	/** pId */
	#define IsNoSteps(%1) g_bNoSteps[%1]
	
new bool:g_bFrozen[33];
	
	/** pId */
	#define IsFrozen(%1) g_bFrozen[%1]
	
new bool:g_bShowPlayers[33];

new g_iBitUserConnected;
	
#define CVAR_RESPAWN_TIME		0.1
#define CVAR_RESPAWN_TIME2		0.5

#define CVAR_MAX_HP				1000
#define CVAR_MAX_MONEY			16000

#define CVAR_GRAVITY			0.3
#define CVAR_SPEED				400
#define CVAR_BURN_DEMAGE		1.0
#define CVAR_POISON_DEMAGE		2

#define SPRITE_FLAME			"sprites/jb_engine/flame.spr"
#define SPRITE_SMOKE			"sprites/black_smoke3.spr"

#define MODEL_GIBS				"models/rockgibs.mdl"
#define MODEL_FROST				"models/glassgibs.mdl"

#define SOUND_PLAYER_FROST		"jb_engine/freeze_player.wav"
#define SOUND_PLAYER_DEFROST	"jb_engine/defrost_player.wav"



native jbe_is_user_ghost_respawn(id)
native jbe_is_user_ghost(id)
native jbe_show_hpmenu(pId)
native jbe_open_globalmenu(pId)

native jbe_show_adminmenu(pId)

native bool:get_frozen_status(pId)
native set_frozen_status(pId)

public plugin_natives() 
{
	register_native("Open_Oaio", "Cmd_OaioMenu", 1);
	register_native("jbe_is_user_bury", "jbe_is_user_bury", 1);
	register_native("jbe_is_user_not_wanted_weapon", "jbe_is_user_not_wanted_weapon" , 1);
	register_native("jbe_is_user_blind", "jbe_is_user_blind" , 1);
	register_native("jbe_uaio_is_user_status", "jbe_uaio_is_user_status" , 1);
}

public jbe_uaio_is_user_status(id, iParams)
{
	switch(iParams)
	{
		case 0: return g_bSpeed[id];
		default: return true;
	}
	return false;
}
public jbe_is_user_blind(id) return g_bBlind[id];
public jbe_is_user_not_wanted_weapon(pId) return IsSetBit(g_iBitUserNotAttacked, pId)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	RegisterMenu(OAIO_MENU_ID, 		"ShowMenu_Oaio_Handler");
	RegisterMenu(CHOOSE_MENU_ID, 	"ShowMenu_Choose_Handler");
	RegisterMenu(PLAYERS_MENU_ID,	"ShowMenu_Players_Handler");
	RegisterMenu(WEAPON_MENU_ID, 	"ShowMenu_Weapons_Handler");
	RegisterMenu(RIFLES_MENU_ID, 	"ShowMenu_Rifles_Handler");
	RegisterMenu(PISTOLS_MENU_ID, 	"ShowMenu_Pistols_Handler");
	RegisterMenu(SHOTGUNS_MENU_ID, 	"ShowMenu_Shotguns_Handler");
	RegisterMenu(COLOR_MENU_ID, 	"ShowMenu_ChooseGlow_Handler");
	
	RegisterMenu(HELP_MENU_ID, 		"ShowMenu_HelpCommands_Handler");
	RegisterMenu(PUNISH_MENU_ID, 	"ShowMenu_PunishCommands_Handler");
	RegisterMenu(OTHER_MENU_ID, 	"ShowMenu_OtherCommands_Handler");
	RegisterMenu(RESET_MENU_ID, 	"ShowMenu_ResetCommands_Handler");
	

	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 				"HookResetMaxSpeed", 					true);
	
	RegisterHookChain(RG_PlayerBlind, "PlayerBlind", .post = false)
	

	register_logevent("EventHook_RoundEnd", 2, "1=Round_End");
	register_event("CurWeapon", "Event_CurWeapon", "be", "3=1");
	
	RegisterHookChain(RG_CBasePlayer_TraceAttack,		"HC_CBasePlayer_TraceAttack_Player", 	false);
	
	register_clcmd("say /uaio" , "Cmd_OaioMenu");
	register_clcmd("uaio" , "Cmd_OaioMenu");
	
	register_menucmd(register_menuid("Show_ResetControlMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ResetControlMenu");
	register_menucmd(register_menuid("Show_ResetMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ResetMenu");

}

public PlayerBlind(const iFlashed, const iInflictor, const iFlasher, const Float:fFadeTime, const Float:fFadeHold, const iAlpha, Float:fColor[3])
{
	if(IsBlind(iFlashed)) return HC_SUPERCEDE;
	
	return HC_CONTINUE;
}

public jbe_is_user_bury(pId) return g_bBury[pId];

public client_putinserver(pId)
{
	SetBit(g_iBitUserConnected, pId);
}
public player_disconnect(pId)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	ClearBit(g_iBitUserConnected, pId);
	
	if(task_exists(pId + TASK_PLAYER_GRENADE)) remove_task(pId + TASK_PLAYER_GRENADE);
	if(task_exists(pId + TASK_PLAYER_POSION)) remove_task(pId + TASK_PLAYER_POSION);
	if(task_exists(pId + TASK_PLAYER_SHAKE)) remove_task(pId + TASK_PLAYER_SHAKE);
	if(task_exists(pId + TASK_PLAYER_BURN)) remove_task(pId + TASK_PLAYER_BURN);
	if(task_exists(pId + TASK_PLAYER_RESPAWN)) remove_task(pId + TASK_PLAYER_RESPAWN);
	
	if(IsBury(pId)) 		Player_ResetBury(pId);
	if(IsBurn(pId)) 		Player_ResetBurn(pId);
	if(IsMute(pId)) 		Player_ResetMute(pId);
	if(IsGlow(pId)) 		Player_ResetGlow(pId);
	if(IsDrugs(pId)) 		Player_ResetDrugs(pId);
	if(IsShake(pId)) 		Player_ResetShake(pId);
	if(IsBlind(pId)) 		Player_ResetBlind(pId);
	if(IsInvis(pId)) 		Player_ResetInvis(pId);
	if(IsSpeed(pId)) 		Player_ResetSpeed(pId);
	//if(IsFrozen(pId)) 		Player_ResetFrozen(pId);
	if(get_frozen_status(pId)) set_frozen_status(pId);
	if(IsPoison(pId)) 		Player_ResetPoison(pId);
	if(IsNoClip(pId)) 		Player_ResetNoClip(pId);
	if(IsNoSteps(pId)) 		Player_ResetNoSpeps(pId);
	if(IsGravity(pId)) 		Player_ResetGravity(pId);
	if(IsGodMode(pId)) 		Player_ResetGodMode(pId);
	if(IsUnlimHe(pId)) 		Player_ResetUnlimHe(pId);
	if(IsUnlimAmmo(pId)) 	Player_ResetUnlimAmmo(pId);
	
	set_entvar(pId, var_maxspeed, 250.0);
}

#define PRECACHE_MODEL(%0) engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0) engfunc(EngFunc_PrecacheSound, %0)

public plugin_precache()
{
	g_iModelIndex_Frost 	= PRECACHE_MODEL(MODEL_FROST);
	g_iModelIndex_RockGibs 	= PRECACHE_MODEL(MODEL_GIBS);
	
	g_iSpriteIndex_Smoke 	= PRECACHE_MODEL(SPRITE_SMOKE);
	g_iSpriteIndex_Flame 	= PRECACHE_MODEL(SPRITE_FLAME);
	
	PRECACHE_SOUND(SOUND_PLAYER_FROST);
	PRECACHE_SOUND(SOUND_PLAYER_DEFROST);
}


public EventHook_RoundEnd()
{
	for(new pId = 1; pId <= MaxClients; pId++)
	{
		if(IsNotSetBit(g_iBitUserConnected, pId)) continue;
		
		if(task_exists(pId + TASK_PLAYER_GRENADE)) remove_task(pId + TASK_PLAYER_GRENADE);
		if(task_exists(pId + TASK_PLAYER_POSION)) remove_task(pId + TASK_PLAYER_POSION);
		if(task_exists(pId + TASK_PLAYER_SHAKE)) remove_task(pId + TASK_PLAYER_SHAKE);
		if(task_exists(pId + TASK_PLAYER_BURN)) remove_task(pId + TASK_PLAYER_BURN);
		if(task_exists(pId + TASK_PLAYER_RESPAWN)) remove_task(pId + TASK_PLAYER_RESPAWN);
		
		if(!jbe_is_user_alive(pId)) continue;
		
		if(IsBurn(pId)) 		Player_ResetBurn(pId);
		if(IsBury(pId)) 		Player_ResetBury(pId);
		if(IsMute(pId)) 		Player_ResetMute(pId);
		if(IsGlow(pId)) 		Player_ResetGlow(pId);
		if(IsDrugs(pId)) 		Player_ResetDrugs(pId);
		if(IsShake(pId)) 		Player_ResetShake(pId);
		if(IsBlind(pId)) 		Player_ResetBlind(pId);
		if(IsInvis(pId)) 		Player_ResetInvis(pId);
		if(IsSpeed(pId)) 		
		{
			rg_reset_maxspeed(pId);
			Player_ResetSpeed(pId);
		}
		//if(IsFrozen(pId)) 		Player_ResetFrozen(pId);
		if(get_frozen_status(pId)  == true) set_frozen_status(pId);
		if(IsPoison(pId)) 		Player_ResetPoison(pId);
		if(IsNoClip(pId)) 		Player_ResetNoClip(pId);
		if(IsNoSteps(pId)) 		Player_ResetNoSpeps(pId);
		if(IsGravity(pId)) 		Player_ResetGravity(pId);
		if(IsGodMode(pId)) 		Player_ResetGodMode(pId);
		if(IsUnlimHe(pId)) 		Player_ResetUnlimHe(pId);
		if(IsUnlimAmmo(pId)) 	Player_ResetUnlimAmmo(pId);
		
		
	}
	
	g_iBitUserNotAttacked = 0;
}

public HC_CBasePlayer_PlayerKilled_Post(pId)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;

	if(!is_user_alive(pId)) return;
	

	if(task_exists(pId + TASK_PLAYER_GRENADE)) remove_task(pId + TASK_PLAYER_GRENADE);
	if(task_exists(pId + TASK_PLAYER_POSION)) remove_task(pId + TASK_PLAYER_POSION);
	if(task_exists(pId + TASK_PLAYER_SHAKE)) remove_task(pId + TASK_PLAYER_SHAKE);
	if(task_exists(pId + TASK_PLAYER_BURN)) remove_task(pId + TASK_PLAYER_BURN);
	if(task_exists(pId + TASK_PLAYER_RESPAWN)) remove_task(pId + TASK_PLAYER_RESPAWN);

	
	if(IsSpeed(pId)) 		Player_ResetSpeed(pId);
	if(IsUnlimHe(pId)) 		Player_ResetUnlimAmmo(pId);
	if(IsGravity(pId)) 		Player_ResetGravity(pId);
	
	if(IsBurn(pId)) 		Player_ResetBurn(pId);
	if(IsBury(pId)) 		Player_ResetBury(pId);
	if(IsMute(pId)) 		Player_ResetMute(pId);
	if(IsGlow(pId)) 		Player_ResetGlow(pId);
	if(IsBlind(pId)) 		Player_ResetBlind(pId);
	if(IsDrugs(pId)) 		Player_ResetDrugs(pId);
	if(IsShake(pId)) 		Player_ResetShake(pId);
	if(IsInvis(pId)) 		Player_ResetInvis(pId);
	if(IsPoison(pId)) 		Player_ResetPoison(pId);
	//if(IsFrozen(pId)) 		Player_ResetFrozen(pId);
	if(get_frozen_status(pId) == true) set_frozen_status(pId);
	if(IsNoClip(pId)) 		Player_ResetNoClip(pId);
	if(IsNoSteps(pId)) 		Player_ResetNoSpeps(pId);
	if(IsGodMode(pId)) 		Player_ResetGodMode(pId);
	if(IsUnlimHe(pId)) 		Player_ResetUnlimHe(pId);
	if(IsUnlimAmmo(pId)) 	Player_ResetUnlimAmmo(pId);
	if(IsSetBit(g_iBitUserNotAttacked, pId)) ClearBit(g_iBitUserNotAttacked, pId);
}

public jbe_lr_duels()
{
	player_reset()

}

public player_reset()

{
	for(new pId = 1; pId <= MaxClients; pId++)
	{
		if(IsNotSetBit(g_iBitUserConnected, pId)) continue;
			


		if(task_exists(pId + TASK_PLAYER_GRENADE)) remove_task(pId + TASK_PLAYER_GRENADE);
		if(task_exists(pId + TASK_PLAYER_POSION)) remove_task(pId + TASK_PLAYER_POSION);
		if(task_exists(pId + TASK_PLAYER_SHAKE)) remove_task(pId + TASK_PLAYER_SHAKE);
		if(task_exists(pId + TASK_PLAYER_BURN)) remove_task(pId + TASK_PLAYER_BURN);
		if(task_exists(pId + TASK_PLAYER_RESPAWN)) remove_task(pId + TASK_PLAYER_RESPAWN);

		
		if(IsSpeed(pId)) 		Player_ResetSpeed(pId);
		if(IsUnlimHe(pId)) 		Player_ResetUnlimAmmo(pId);
		if(IsGravity(pId)) 		Player_ResetGravity(pId);
		
		if(IsBurn(pId)) 		Player_ResetBurn(pId);
		if(IsBury(pId)) 		Player_ResetBury(pId);
		if(IsMute(pId)) 		Player_ResetMute(pId);
		if(IsGlow(pId)) 		Player_ResetGlow(pId);
		if(IsBlind(pId)) 		Player_ResetBlind(pId);
		if(IsDrugs(pId)) 		Player_ResetDrugs(pId);
		if(IsShake(pId)) 		Player_ResetShake(pId);
		if(IsInvis(pId)) 		Player_ResetInvis(pId);
		if(IsPoison(pId)) 		Player_ResetPoison(pId);
		//if(IsFrozen(pId)) 		Player_ResetFrozen(pId);
		if(get_frozen_status(pId) == true) set_frozen_status(pId);
		if(IsNoClip(pId)) 		Player_ResetNoClip(pId);
		if(IsNoSteps(pId)) 		Player_ResetNoSpeps(pId);
		if(IsGodMode(pId)) 		Player_ResetGodMode(pId);
		if(IsUnlimHe(pId)) 		Player_ResetUnlimHe(pId);
		if(IsUnlimAmmo(pId)) 	Player_ResetUnlimAmmo(pId);
		if(IsSetBit(g_iBitUserNotAttacked, pId)) ClearBit(g_iBitUserNotAttacked, pId);
	}
}





public HookResetMaxSpeed(const pId)
{
    if(IsSpeed(pId))
        set_entvar(pId, var_maxspeed, float(CVAR_SPEED));  
}


public Event_CurWeapon(pId)
{
	if(IsSpeed(pId))
		set_entvar(pId, var_maxspeed, float(CVAR_SPEED));
	if(!IsUnlimAmmo(pId))
		return PLUGIN_CONTINUE;

	enum { weapon = 2 };

	new iWeapon = read_data(weapon);

	new iClip = rg_get_weapon_info(iWeapon, WI_GUN_CLIP_SIZE);

	if(iClip < 0)
		return PLUGIN_CONTINUE;

	rg_set_weapon_ammo(get_member(pId, m_pActiveItem), iClip + 1);

	return PLUGIN_CONTINUE;
}

public Cmd_OaioValue(pId)
{
	if(!IsFlag(pId, OAIO_MENU_ACCESS))
		return PLUGIN_HANDLED;
	
	new szArg[10];
	read_argv(1, szArg, charsmax(szArg));
	
	if(equal(szArg, "")) return PLUGIN_HANDLED;
	
	new pIde, iValue = g_iPlayerValue[pId] = str_to_num(szArg);

	switch(Player_GetMenuItem(pId))
	{


	}
	return PLUGIN_HANDLED;
}

ShowMenu_ChooseGlow(pId)
{
	new iLen, szMenu[256];
	
	new bitsKeys = KEY(0);
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", COLOR_MENU_TITLE);
	
	for(new i = 0, j = 1; i < TOTAL_COLORS; i++, j++)
	{
		bitsKeys |= KEY(j);
		
		MENU_ITEM(szMenu, iLen, "\y%d. \w%s^n", j, g_szColor[i]);
	}
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	SHOW_MENU(pId, bitsKeys, szMenu, COLOR_MENU_ID);
}

public ShowMenu_ChooseGlow_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	new pIde;
	
	switch(Player_GetItemChoose(pId))
	{
		case CHOOSE_PRISON:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_PRISON)) continue;
				
				Player_SetGlow(pIde, g_flColor[iKey]);
			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^3%s^1 выставил всем зэкам свечение: ^4%s^1 !", PREFIX, Player_GetName(pId), g_szColor[iKey]
			);
		}
		case CHOOSE_GUARD:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_PRISON)) continue;
				
				Player_SetGlow(pIde, g_flColor[iKey]);
			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^3%s^1 выставил всей охране свечение: ^4%s^1 !", PREFIX, Player_GetName(pId), g_szColor[iKey]
			);
		}
		case CHOOSE_ID:
		{
			
			pIde = g_iPlayerTarget[pId];
			
			if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) return;
			
			Player_SetGlow(pIde, g_flColor[iKey]);
			
			if(pId == pIde)
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^3%s^1 выставил себе свечение (^4%s^1) !", PREFIX, Player_GetName(pId), g_szColor[iKey]
				);
			}
			else
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^3%s^1 выставил свечение ^3%s^1 (^4%s^1) !", PREFIX, Player_GetName(pId), Player_GetName(pIde), g_szColor[iKey]
				);
			}
		}
	}
	
	ShowMenu_Oaio(pId);
}

ShowMenu_Weapons(pId)
{
	new iLen, szMenu[128];
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", WEAPON_MENU_TITLE);
	
	MENU_ITEM(szMenu, iLen, "\y1. \wПистолеты^n");
	MENU_ITEM(szMenu, iLen, "\y2. \wПолуавтоматы^n");
	MENU_ITEM(szMenu, iLen, "\y3. \wВинтовки^n");
	
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	const bitsKeys = KEY(0)|KEY(1)|KEY(2)|KEY(3);
	SHOW_MENU(pId, bitsKeys, szMenu, WEAPON_MENU_ID);
}

public ShowMenu_Weapons_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 1: ShowMenu_Pistols(pId);
		case 2: ShowMenu_Shotguns(pId);
		case 3: ShowMenu_Rifles(pId);
	}
}

public ShowMenu_Pistols(pId)
{
	new iLen, szMenu[256], bitsKeys = KEY(0);
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", WEAPON_MENU_TITLE);
	
	for(new i = 0, j = 1; j <= TOTAL_PISTOLS; i+= 2, j++)
	{
		bitsKeys |= KEY(j);
		
		MENU_ITEM(szMenu, iLen, "\y%d. \w%s^n", j, g_szWeapon_Pistols[i]);
	}
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	SHOW_MENU(pId, bitsKeys, szMenu, PISTOLS_MENU_ID);
}

public ShowMenu_Pistols_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	new pIde;

	if(iKey == 9) return;
	
	switch(Player_GetItemChoose(pId))
	{
		case CHOOSE_PRISON:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_PRISON)) continue;
				
				#if defined DEF_RESET_WPN
					
					Player_ResetWeapons(pIde, WPN_SECONDARY);
				
				#endif
				
				if(iKey == TOTAL_PISTOLS)
				{
					rg_give_shield(pIde);
				
				}
				else
				{
					rg_give_item_ex(pIde, g_szWeapon_Pistols[iKey * 2 + 1],GT_APPEND, 1000);
				}

			}
			
			
			{
			
				if(iKey == TOTAL_PISTOLS)
				{
					Player_SendTextInfo
					(
						ALL, "%s Администратор ^4%s^1 выдал заключенным ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
					);
				}
				else
				{
					Player_SendTextInfo
					(
						ALL, "%s Администратор ^4%s^1 изменил заключённым пистолет на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
					);
				}
			}
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_GUARD:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_GUARD)) continue;
				
				#if defined DEF_RESET_WPN
				
					Player_ResetWeapons(pIde, WPN_SECONDARY);
				
				#endif
				
				if(iKey == TOTAL_PISTOLS)
				{
					rg_give_shield(pIde);
				
				}
				else
				{
					rg_give_item_ex(pIde, g_szWeapon_Pistols[iKey * 2 + 1],GT_APPEND, 1000);
				}
			}
			
			
			{
				if(iKey == TOTAL_PISTOLS)
				{
					Player_SendTextInfo
					(
						ALL, "%s Администратор ^4%s^1 выдал охране ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
					);
				
				}
				else
				{
					Player_SendTextInfo
					(
						ALL, "%s Администратор ^4%s^1 изменил охране пистолет на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
					);
				}
			}
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_ID:
		{
			
			pIde = g_iPlayerTarget[pId];
			
			
			
			#if defined DEF_RESET_WPN
			
				Player_ResetWeapons(pIde, WPN_SECONDARY);
			
			#endif
			

			if(iKey == TOTAL_PISTOLS)
			{
				//rg_give_item(pIde, g_szWeapon_Pistols[iKey * 2 + 1]);
				rg_give_shield(pIde);
			}
			else
			{
				rg_give_item_ex(pIde, g_szWeapon_Pistols[iKey * 2 + 1],GT_APPEND, 1000);
			}

			
			if(pId == pIde)
			{
				
				{
					if(iKey == TOTAL_PISTOLS)
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 взял себе ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
						);
					}
					else
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 изменил себе пистолет на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Pistols[iKey * 2]
						);
					}
				}
			}
			else
			{
				
				{
					if(iKey == TOTAL_PISTOLS)
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 выдал игроку ^3%s^1 ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde), g_szWeapon_Pistols[iKey * 2]
						);
					}
					else
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 изменил ^3%s^1 пистолет на ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde), g_szWeapon_Pistols[iKey * 2]
						);
					}
				}
			}
			_PLAYERS_MENU_CALLBACK(Saved, pId);
		}
	}
}

public ShowMenu_Shotguns(pId)
{
	new iLen, szMenu[256], bitsKeys = KEY(0);
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", WEAPON_MENU_TITLE);
	
	for(new i = 0, j = 1; j <= TOTAL_SHOTGUNS; i+= 2, j++)
	{
		bitsKeys |= KEY(j);
		
		MENU_ITEM(szMenu, iLen, "\y%d. \w%s^n", j, g_szWeapon_Shotguns[i]);
	}
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	SHOW_MENU(pId, bitsKeys, szMenu, SHOTGUNS_MENU_ID);
}

public ShowMenu_Shotguns_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	new pIde;

	if(iKey == 9) return;
	
	switch(Player_GetItemChoose(pId))
	{
		case CHOOSE_PRISON:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_PRISON)) continue;
				
				#if defined DEF_RESET_WPN
				
					Player_ResetWeapons(pIde, WPN_PRIMARY);
				
				#endif
				
				rg_give_item_ex(pIde, g_szWeapon_Shotguns[iKey * 2 + 1],GT_APPEND, 1000);

			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 изменил заключённым оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Shotguns[iKey * 2]
			);
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_GUARD:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_GUARD)) continue;
				
				#if defined DEF_RESET_WPN
				
					Player_ResetWeapons(pIde, WPN_PRIMARY);
				
				#endif
				

				rg_give_item_ex(pIde, g_szWeapon_Shotguns[iKey * 2 + 1],GT_APPEND, 1000);

			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 изменил охране оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Shotguns[iKey * 2]
			);
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_ID:
		{
			pIde = g_iPlayerTarget[pId];
			
			#if defined DEF_RESET_WPN
				
				Player_ResetWeapons(pIde, WPN_PRIMARY);
			
			#endif
			

			rg_give_item_ex(pIde, g_szWeapon_Shotguns[iKey * 2 + 1],GT_APPEND, 1000);

			
			if(pId == pIde)
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^4%s^1 изменил себе оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Shotguns[iKey * 2]
				);
			}
			else
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^4%s^1 изменил ^3%s^1 оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde), g_szWeapon_Shotguns[iKey * 2]
				);
			}
			_PLAYERS_MENU_CALLBACK(Saved, pId);
		}
	}
}

public ShowMenu_Rifles(pId)
{
	new iLen, szMenu[256], bitsKeys = KEY(0);
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", WEAPON_MENU_TITLE);
	
	for(new i = 0, j = 1; j <= TOTAL_RIFLES; i+= 2, j++)
	{
		bitsKeys |= KEY(j);
		
		MENU_ITEM(szMenu, iLen, "\y%d. \w%s^n", j, g_szWeapon_Rifles[i]);
	}
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	SHOW_MENU(pId, bitsKeys, szMenu, RIFLES_MENU_ID);
}

public ShowMenu_Rifles_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	new pIde;

	if(iKey == 9) return;
	
	switch(Player_GetItemChoose(pId))
	{
		case CHOOSE_PRISON:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_PRISON)) continue;
				
				#if defined DEF_RESET_WPN
				
					Player_ResetWeapons(pIde, WPN_PRIMARY);
				
				#endif
				

				rg_give_item_ex(pIde, g_szWeapon_Rifles[iKey * 2 + 1],GT_APPEND, 1000);

			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 изменил заключённым оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Rifles[iKey * 2]
			);
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_GUARD:
		{
			for(pIde = 1; pIde <= MaxClients; pIde++)
			{
				if(IsNotSetBit(g_iBitUserConnected, pIde) || jbe_is_user_not_alive((pIde))) continue;
				if(!IsTeam(pIde, TEAM_GUARD)) continue;
				
				#if defined DEF_RESET_WPN
	
					Player_ResetWeapons(pIde, WPN_PRIMARY);
				
				#endif
				
				rg_give_item_ex(pIde, g_szWeapon_Rifles[iKey * 2 + 1],GT_APPEND, 1000);

			}
			
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 изменил охране оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Rifles[iKey * 2]
			);
			ShowMenu_Oaio(pId);
		}
		case CHOOSE_ID:
		{
			pIde = g_iPlayerTarget[pId];
			
			#if defined DEF_RESET_WPN
			
				Player_ResetWeapons(pIde, WPN_PRIMARY);
			
			#endif
			

			rg_give_item_ex(pIde, g_szWeapon_Rifles[iKey * 2 + 1],GT_APPEND, 1000);
			
			if(pId == pIde)
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^4%s^1 изменил себе оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), g_szWeapon_Rifles[iKey * 2]
				);
			}
			else
			{
				Player_SendTextInfo
				(
					ALL, "%s Администратор ^4%s^1 изменил ^3%s^1 оружие на ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde), g_szWeapon_Rifles[iKey * 2]
				);
			}
			_PLAYERS_MENU_CALLBACK(Saved, pId);
		}
	}
}
native jbe_restartgame();
public Cmd_OaioMenu(pId) 
{
	if(!IsFlag(pId, OAIO_MENU_ACCESS) || jbe_restartgame()) return PLUGIN_HANDLED;
	if(zl_boss_map()) 
	{
		Player_SendTextInfo(pId, "Во время босса запрещено");
		return PLUGIN_HANDLED;
	}
	if(jbe_get_day_mode() == 3)
	{
		Player_SendTextInfo(pId, "Во время игр, привилегия запрещена");
		return PLUGIN_HANDLED;
	}
	ShowMenu_Oaio(pId);
	return PLUGIN_HANDLED;
}
ShowMenu_Oaio(pId)
{
	new iLen, szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", OAIO_MENU_TITLE);
	
	MENU_ITEM(szMenu, iLen, "\y1. \wВспомогательные команды^n");
	MENU_ITEM(szMenu, iLen, "\y2. \wНаказательные команды^n");
	//MENU_ITEM(szMenu, iLen, "\y3. \wРазные команды^n");
	MENU_ITEM(szMenu, iLen, "\y3. \wРедактировать оружие^n");
	MENU_ITEM(szMenu, iLen, "\y4. \wВернуть к стандарту");
	MENU_ITEM(szMenu, iLen, "^n^n\y5. \rСбросить все!");
	
	MENU_ITEM(szMenu, iLen, "^n\y6. \wРедактор Жизней!");
	MENU_ITEM(szMenu, iLen, "^n\y7. \wДополнительно!");

	
	//MENU_ITEM(szMenu, iLen, "^n^n\y9. \wНазад");
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wНазад");
	
	
	SHOW_MENU(pId, iKeys, szMenu, OAIO_MENU_ID);
}

public ShowMenu_Oaio_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId) || !IsFlag(pId, OAIO_MENU_ACCESS)) return;
	
	switch(iKey)
	{
		case 0: ShowMenu_HelpCommands(pId);
		case 1: ShowMenu_PunishCommands(pId);
		case 2: 
		{
			Player_SetMenuItemType(pId, ITEM_TYPE_OTHER);
	
			_OTHER_MENU_CALLBACK(New, pId);
		}
		case 3: ShowMenu_ResetMenu(pId);
		case 4: 
		{
			Show_ResetMenu(pId)
		}
		case 5: jbe_show_hpmenu(pId);
		case 6: jbe_open_globalmenu(pId);
		
		case 9: jbe_show_adminmenu(pId);
	}

}

ShowMenu_HelpCommands(pId)
{
	Player_SetMenuItemType(pId, ITEM_TYPE_HELP);
	
	_HELP_MENU_CALLBACK(New, pId);
}

public ShowMenu_HelpCommands_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 0: return;
		case 8: _HELP_MENU_CALLBACK(Back, pId);
		case 9: _HELP_MENU_CALLBACK(Next, pId);
		default:
		{
			new iItem = Player_GetMenuItemTarget(pId, iKey);
			
			Player_SetMenuItem(pId, iItem);
			
			ShowMenu_ChooseType(pId);
		}
	}
}

ShowMenu_PunishCommands(pId)
{
	Player_SetMenuItemType(pId, ITEM_TYPE_PUNISH);
	
	_PUNISH_MENU_CALLBACK(New, pId);
}

public ShowMenu_PunishCommands_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 0: return;
		case 8: _PUNISH_MENU_CALLBACK(Back, pId);
		case 9: _PUNISH_MENU_CALLBACK(Next, pId);
		default:
		{
			new iItem = Player_GetMenuItemTarget(pId, iKey);
			
			Player_SetMenuItem(pId, iItem);
			
			ShowMenu_ChooseType(pId);
		}
	}
}

ShowMenu_OtherCommands(pId)
{
	Player_SetMenuItemType(pId, ITEM_TYPE_OTHER);
	
	_OTHER_MENU_CALLBACK(New, pId);
}

public ShowMenu_OtherCommands_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 0: return;
		case 8: _OTHER_MENU_CALLBACK(Back, pId);
		case 9: _OTHER_MENU_CALLBACK(Next, pId);
		default:
		{
			new iItem = Player_GetMenuItemTarget(pId, iKey);
			
			Player_SetMenuItem(pId, iItem);
			
			ShowMenu_ChooseType(pId);
		}
	}
}

ShowMenu_ResetMenu(pId)
{
	Player_SetMenuItemType(pId, ITEM_TYPE_RESET);
	
	_RESET_MENU_CALLBACK(New, pId);
}

public ShowMenu_ResetCommands_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 0: return;
		case 8: _RESET_MENU_CALLBACK(Back, pId);
		case 9: _RESET_MENU_CALLBACK(Next, pId);
		default:
		{
			new iItem = Player_GetMenuItemTarget(pId, iKey);
			
			Player_SetMenuItem(pId, iItem);
			
			ShowMenu_ChooseType(pId);
		}
	}
}

ShowMenu_ChooseType(pId)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	new iLen, szMenu[256];
	
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", OAIO_MENU_TITLE);
	
	MENU_ITEM(szMenu, iLen, "\y1. \wВыдать всем \rТ^n");
	MENU_ITEM(szMenu, iLen, "\y2. \wВыдать всем \rКТ^n");
	MENU_ITEM(szMenu, iLen, "\y3. \wВыдать персонально");
	
	MENU_ITEM(szMenu, iLen, "^n^n\y0. \wВыход");
	
	const bitsKeys = KEY(0)|KEY(1)|KEY(2)|KEY(3);
	SHOW_MENU(pId, bitsKeys, szMenu, CHOOSE_MENU_ID);
}

public ShowMenu_Choose_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 1:
		{
			Player_SetItemChoose(pId, CHOOSE_PRISON);
			
			if(Player_GetMenuItemType(pId) == ITEM_TYPE_HELP && Player_GetMenuItem(pId) == ITEM_HELP_GLOW)
			{
				ShowMenu_ChooseGlow(pId); return;
			}
			
			if(Player_GetMenuItemType(pId) != ITEM_TYPE_OTHER)
			{
				for(new pIde = 1; pIde <= MaxClients; pIde++)
				{
					if(IsNotSetBit(g_iBitUserConnected, pIde)) continue;
					if(!IsTeam(pIde, TEAM_PRISON)) continue;
					
					Player_SetItemAbility(pId, pIde);
				}
				
				switch(Player_GetMenuItemType(pId))
				{
					case ITEM_TYPE_HELP:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_HELP_RESTORE: //Восстановить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 возродил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_HIDEWALL: //Скрыть стены
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 скрыл стены всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GODMODE: //Бессмертие
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бессмертие всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GRAVITY: //Гравитация
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал гравитацию всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_SPEED: //Скорость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал скорость всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_INVIS: //Невидимость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал невидимость всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_NOSTEPS: //Бесшумные шаги
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесшумные шаги всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_UNLIMAMMO: //Бесконечные патроны
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные патроны всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_UNLIMHE: //Бесконечные гранаты
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные гранаты (HE) всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GLOW: //Свечение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал свечение всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
					case ITEM_TYPE_PUNISH:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_PUNISH_KILL: //Убить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BURY: //Закопать
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 закопал всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_MUTE: //Вставить кляп
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вставил кляп всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BURN: //Поджечь
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 поджёг всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_POSION: //Отравить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отравил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_STRIP: //Лишить оружия
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 обезоружил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BLIND: //Ослепить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 ослепил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_GRUGS: //Наркотики
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 посадил на наркотики всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_SHAKE: //Землетрясение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выставил замлетрясение всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_FROST: //Заморозить игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 заморозил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
					case ITEM_TYPE_RESET:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_RESET_INVIS: //Убрать невидимость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил невидимость всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_FROST: //Разморозить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 разморозил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_SHAKE: //Убрать землетресение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил землетресение всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_DRUGS: //Убрать наркотики
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил наркотики всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BLIND: //Венуть зрение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вернул зрение всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_SPEED: //Убрать скорость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил скорость всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GRAVITY: //Убрать гравитацию
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил гравитацию всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_HIDEWALL: //Вернуть стены
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил скрытые стены всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GODMODE: //Убрать бессмертие
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бессмертие всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GLOW: //Убрать свечение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил свечение всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_UNLIMAMMO: //Убрать беск. патроны
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесконечные патроны всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_UNLIMHE: //Убрать беск. гранаты
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесконечные гранаты всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_NOSTEPS: //Убрать бесшумные шаги
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесшумные шаги всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_POSION: //Вылечить от яда
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вылечил от яда всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BURN: //Потушить игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 потушил всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_MUTE: //Убрать кляп
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил кляп всем заключённым !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BURY: //Откопать игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 откапал всех заключённых !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
				}
			
				ShowMenu_Oaio(pId);
			}
			else
			{
				/*switch(Player_GetMenuItem(pId))
				{
					case ITEM_OTHER_EDITHP:
					{
						client_cmd(pId, "messagemode ^"oaio^"");
					}
					default:
					{
						ShowMenu_Weapons(pId);
					}
				}*/
				ShowMenu_Weapons(pId);
			}
		}
		case 2:
		{
			Player_SetItemChoose(pId, CHOOSE_GUARD);
			
			if(Player_GetMenuItemType(pId) == ITEM_TYPE_HELP && Player_GetMenuItem(pId) == ITEM_HELP_GLOW)
			{
				ShowMenu_ChooseGlow(pId); return;
			}
			
			if(Player_GetMenuItemType(pId) != ITEM_TYPE_OTHER)
			{
				for(new pIde = 1; pIde <= MaxClients; pIde++)
				{
					if(IsNotSetBit(g_iBitUserConnected, pIde)) continue;
					if(!IsTeam(pIde, TEAM_GUARD)) continue;
					
					Player_SetItemAbility(pId, pIde);
				}
			
				switch(Player_GetMenuItemType(pId))
				{
					case ITEM_TYPE_HELP:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_HELP_RESTORE: //Восстановить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 возродил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_HIDEWALL: //Скрыть стены
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 скрыл стены всей охраны !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GODMODE: //Бессмертие
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бессмертие всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GRAVITY: //Гравитация
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал гравитацию всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_SPEED: //Скорость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал скорость всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_INVIS: //Невидимость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал невидимость всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_NOSTEPS: //Бесшумные шаги
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесшумные шаги всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_UNLIMAMMO: //Бесконечные патроны
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные патроны всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_UNLIMHE: //Бесконечные гранаты
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные гранаты (HE) всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_HELP_GLOW: //Свечение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал свечение всей охране !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
					case ITEM_TYPE_PUNISH:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_PUNISH_KILL: //Убить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BURY: //Закопать
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 закопал всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_MUTE: //Вставить кляп
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вставил кляп всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BURN: //Поджечь
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 поджёг всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_POSION: //Отравить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отравил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_STRIP: //Лишить оружия
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 обезоружил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_BLIND: //Ослепить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 ослепил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_GRUGS: //Наркотики
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 посадил на наркотики всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_SHAKE: //Землетрясение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выставил замлетрясение всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_PUNISH_FROST: //Заморозить игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 заморозил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
					case ITEM_TYPE_RESET:
					{
						switch(Player_GetMenuItem(pId))
						{
							case ITEM_RESET_INVIS: //Убрать невидимость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил невидимость всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_FROST: //Разморозить
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 разморозил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_SHAKE: //Убрать землетресение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил землетресение всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_DRUGS: //Убрать наркотики
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил наркотики всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BLIND: //Венуть зрение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вернул зрение всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_SPEED: //Убрать скорость
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил скорость всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GRAVITY: //Убрать гравитацию
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил гравитацию всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_HIDEWALL: //Вернуть стены
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил скрытые стены всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GODMODE: //Убрать бессмертие
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бессмертие всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_GLOW: //Убрать свечение
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил свечение всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_UNLIMAMMO: //Убрать беск. патроны
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесконечные патроны всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_UNLIMHE: //Убрать беск. гранаты
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесконечные гранаты всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_NOSTEPS: //Убрать бесшумные шаги
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил бесшумные шаги всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BURN: //Потушить игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 потушил всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_POSION: //Вылечить от яда
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 вылечил от яда всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_MUTE: //Убрать кляп
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отключил кляп всей охране !", PREFIX, Player_GetName(pId)
								);
							}
							case ITEM_RESET_BURY: //Откопать игрока
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 откапал всю охрану !", PREFIX, Player_GetName(pId)
								);
							}
						}
					}
				}
			
				ShowMenu_Oaio(pId);
			}
			else
			{
				/*switch(Player_GetMenuItem(pId))
				{
					case ITEM_OTHER_EDITHP:
					{
						client_cmd(pId, "messagemode ^"oaio^"");
					}
					default:
					{
						ShowMenu_Weapons(pId);
					}
				}*/
				ShowMenu_Weapons(pId);
			}
		}
		case 3:
		{
			Player_SetItemChoose(pId, CHOOSE_ID);
			
			switch(Player_GetMenuItemType(pId))
			{
				case ITEM_TYPE_HELP:
				{
					switch(Player_GetMenuItem(pId))
					{
						case ITEM_HELP_RESTORE:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 0;
						}
						case ITEM_HELP_HIDEWALL..ITEM_HELP_GLOW:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
					}
				}
				case ITEM_TYPE_PUNISH:
				{
					switch(Player_GetMenuItem(pId))
					{
						case ITEM_PUNISH_KILL, ITEM_PUNISH_BURY:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
						case ITEM_PUNISH_MUTE:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = -1;
						}
						case ITEM_PUNISH_BURN..ITEM_PUNISH_FROST:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
					}
				}
				case ITEM_TYPE_OTHER:
				{
					switch(Player_GetMenuItem(pId))
					{

						case ITEM_OTHER_EDITWPN:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
					}
				}
				case ITEM_TYPE_RESET:
				{
					switch(Player_GetMenuItem(pId))
					{
						case ITEM_RESET_INVIS..ITEM_RESET_POSION:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
						case ITEM_RESET_MUTE:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = -1;
						}
						case ITEM_RESET_BURY:
						{
							g_aPlayerType[pId][PL_TYPE_ME] = true;
							g_aPlayerType[pId][PL_TYPE_TEAM] = -1;
							g_aPlayerType[pId][PL_TYPE_ALIVE] = 1;
						}
					}
				}
			}
			
			_PLAYERS_MENU_CALLBACK(New, pId);
		}
	}
}

public ShowMenu_Players_Handler(pId, iKey)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	switch(KEY_HANDLER(iKey))
	{
		case 0: return;
		case 8: _PLAYERS_MENU_CALLBACK(Back, pId);
		case 9: _PLAYERS_MENU_CALLBACK(Next, pId);
		default:
		{
			new pIde = Player_GetMenuItemTarget(pId, iKey);
			
			if(IsNotSetBit(g_iBitUserConnected, pIde))
			{
				_PLAYERS_MENU_CALLBACK(Saved, pId); return;
			}
			
			Player_SetItemAbility(pId, pIde);
		}
	}
}

Player_GetPlayersMenu_Next(pId, &iPage, bool:bMe, iTeam, iType, const szTitle[], const szMenuId[])
{
	return Player_GetPlayersMenu(pId, ++iPage, bMe, iTeam, iType, szTitle, szMenuId);
}

Player_GetPlayersMenu_Back(pId, &iPage, bool:bMe, iTeam, iType, const szTitle[], const szMenuId[])
{
	return Player_GetPlayersMenu(pId, --iPage, bMe, iTeam, iType, szTitle, szMenuId);
}

Player_GetPlayersMenu_Saved(pId, &iPage, bool:bMe, iTeam, iType, const szTitle[], const szMenuId[])
{
	return Player_GetPlayersMenu(pId, iPage, bMe, iTeam, iType, szTitle, szMenuId);
}

Player_GetPlayersMenu_New(pId, &iPage, bool:bMe, iTeam, iType, const szTitle[], const szMenuId[])
{
	return Player_GetPlayersMenu(pId, iPage = 0, bMe, iTeam, iType, szTitle, szMenuId);
}

Player_GetPlayersMenu(pId, iPage, bool:bMe, iTeam, iType, const szTitle[], const szMenuId[])
{
	if(iPage < 0 || IsNotSetBit(g_iBitUserConnected, pId) || !iTeam || iTeam > TEAM_GUARD)
		return PLUGIN_HANDLED;
	
	new szPlayers[32], iPlayers;

	get_players(szPlayers, iPlayers, "ch");
	
	new i = min(iPage * 7, iPlayers);
	
	new iStart 	= i - (i % 7);
	new iEnd 	= min(iStart + 7, iPlayers);
	
	iPage = iStart / 7;

	g_iPlayerMenuPage[pId] = iPage;
	g_iPlayerMenuTarget[pId] = szPlayers;
	
	new szPlayersMenu[512], iLen;
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szPlayersMenu, iLen, "%s^n^n", szTitle);
	
	new iPlayerPages = ((iPlayers - 1) / 7) + 1;
	
	new bool:bAlive;
	new iItem, iPlayer;
	new bitsKeys = KEY(0);
	new szName[32];

	for(i = iStart; i < iEnd; i++)
	{
		iPlayer = szPlayers[i];
		
		get_user_name(iPlayer, szName, charsmax(szName));
		
		bAlive = IsAlive(iPlayer);
		switch(iTeam)
		{
			case -1:
			{
				switch(iType)
				{
					case -1:
					{
						if(iPlayer == pId)
						{
							switch(bMe)
							{
								case false:
								{
									bitsKeys &= ~KEY(++iItem);
									
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
								}
								case true:
								{
									bitsKeys |= KEY(++iItem);
									
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
								}
							}
						}
						else
						{
							bitsKeys |= KEY(++iItem);							
							MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
						}
					}
					case 0:
					{
						switch(bAlive)
						{
							case false:
							{
								if(iPlayer == pId)
								{
									switch(bMe)
									{
										case false:
										{
											bitsKeys &= ~KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
										}
										case true:
										{

											bitsKeys |= KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
										}
									}
								}
								else
								{
									bitsKeys |= KEY(++iItem);
									
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
								}
							}
							case true:
							{
								new id = szPlayers[i];
								if(jbe_is_user_ghost(id))
								{
								bitsKeys |= KEY(++iItem);
											
								MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s \r[Призрак]^n", iItem, szName);
								}
								else
								{
								bitsKeys &= ~KEY(++iItem);
								
								MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s \r[Жив]^n", iItem, szName);
								}
							}
						}
					}
					case 1:
					{
						switch(bAlive)
						{
							case false:
							{
								bitsKeys &= ~KEY(++iItem);
								
								MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s \r[Мертв]^n", iItem, szName);
							}
							case true:
							{
								if(iPlayer == pId)
								{
									switch(bMe)
									{
										case false:
										{
											bitsKeys &= ~KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
										}
										case true:
										{
											bitsKeys |= KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
										}
									}
								}
								else
								{
								
									new id = szPlayers[i];
									if(jbe_is_user_ghost(id))
									{
									bitsKeys &= ~KEY(++iItem);
											
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s \r[Призрак]^n", iItem, szName);
									}
									else
									{
									bitsKeys |= KEY(++iItem);
									
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
									}
								}
							}
						}
						
					}
				}
			}
			default:
			{
				new bool:bTeam = IsTeam(iPlayer, iTeam);
				switch(bTeam)
				{
					case false:
					{
						bitsKeys &= ~KEY(++iItem);
						
						MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);						
					}
					case true:
					{
						switch(iType)
						{
							case -1:
							{
								if(iPlayer == pId)
								{
									switch(bMe)
									{
										case false:
										{
											bitsKeys &= ~KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
										}
										case true:
										{
											bitsKeys |= KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
										}
									}
								}
								else
								{
									bitsKeys |= KEY(++iItem);
									
									MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
								}
							}
							case 0:
							{
								switch(bAlive)
								{
									case false:
									{
										if(iPlayer == pId)
										{
											switch(bMe)
											{
												case false:
												{
													bitsKeys &= ~KEY(++iItem);
													
													MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
												}
												case true:
												{
													bitsKeys |= KEY(++iItem);
													
													MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
												}
											}
										}
										else
										{
											bitsKeys |= KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
										}
									}
									case true:
									{
										
										bitsKeys &= ~KEY(++iItem);
										
										MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
									}
								}
							}
							case 1:
							{
								switch(bAlive)
								{
									case false:
									{
										
										bitsKeys &= ~KEY(++iItem);
										
										MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s^n", iItem, szName);
									}
									case true:
									{
										if(iPlayer == pId)
										{
											switch(bMe)
											{
												case false:
												{
													bitsKeys &= ~KEY(++iItem);
													
													MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s \r[Ты]^n", iItem, szName);
												}
												case true:
												{
													
													bitsKeys |= KEY(++iItem);
													
													MENU_ITEM(szPlayersMenu, iLen, "\y%d. \y%s^n", iItem, szName);
												}
											}
										}
										else
										{
											new id = szPlayers[i];
											if(jbe_is_user_ghost(id))
											

											{
											bitsKeys &= ~KEY(++iItem);
				
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \d%s \r[Призрак]^n", iItem, szName);
											}
											else
											{
											bitsKeys |= KEY(++iItem);
											
											MENU_ITEM(szPlayersMenu, iLen, "\y%d. \w%s^n", iItem, szName);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	if(iPage)
	{
		bitsKeys |= KEY(8);
		
		MENU_ITEM(szPlayersMenu, iLen, "^n\y8. \wНазад");
	}
	
	if(iPlayerPages > 1 && iPage + 1 < iPlayerPages)
	{
		bitsKeys |= KEY(9);
		
		MENU_ITEM(szPlayersMenu, iLen, "^n\y9. \wДалее");
	}
	
	MENU_ITEM(szPlayersMenu, iLen, "^n\y0. \wВыход");
	
	return SHOW_MENU(pId, bitsKeys, szPlayersMenu, szMenuId);
}

const XO_PLAYER = 5;
const m_rgpPlayerItems_Slot0 = 367;

Player_SetItemAbility(pId, pIde)
{
	g_iPlayerTarget[pId] = pIde;

	switch(Player_GetMenuItemType(pId))
	{
		case ITEM_TYPE_HELP:
		{
			switch(Player_GetMenuItem(pId))
			{
				case ITEM_HELP_RESTORE: //Восстановить
				{
					if(jbe_is_user_alive((pIde))) return;
					if(task_exists(pIde + TASK_PLAYER_RESPAWN))
					{
						remove_task(pIde + TASK_PLAYER_RESPAWN);
					}
					
					switch(Player_GetItemChoose(pId))
					{
						case CHOOSE_PRISON:
						{
							jbe_is_user_ghost_respawn(pIde);
							set_task(CVAR_RESPAWN_TIME2, "Task_PlayerRespawn", pIde + TASK_PLAYER_RESPAWN);
						}
						case CHOOSE_GUARD:
						{
							jbe_is_user_ghost_respawn(pIde);
							set_task(CVAR_RESPAWN_TIME2, "Task_PlayerRespawn", pIde + TASK_PLAYER_RESPAWN);
						}
						case CHOOSE_ID:
						{
							jbe_is_user_ghost_respawn(pIde);
							set_task(CVAR_RESPAWN_TIME, "Task_PlayerRespawn", pIde + TASK_PLAYER_RESPAWN);
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 возродил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 возродил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
					
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_HIDEWALL: //Скрыть стены
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsNoClip(pIde))
					{
						case false:
						{
							Player_SetNoClip(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе скрытые стены !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал скрытые стены ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь скрытые стены !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет скрытые стены !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_GODMODE: //Бессмертие
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsGodMode(pIde))
					{
						case false:
						{
							Player_SetGodMode(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе бессмертие !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бессмертие ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь бессмертие !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет бессмертие !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_GRAVITY: //Гравитация
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsGravity(pIde))
					{
						case false:
						{
							Player_SetGravity(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе гравитацию !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал гравитацию ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь гравитацию !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет гравитацию !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_SPEED: //Скорость
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsSpeed(pIde))
					{
						case false:
						{
							Player_SetSpeed(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе скорость !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал скорость ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь скорость !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет скорость !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_INVIS: //Невидимость
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsInvis(pIde))
					{
						case false:
						{
							Player_SetInvis(pIde);
							
							if(Player_GetItemChoose(pId) == CHOOSE_ID)
							{
								if(pId == pIde)
								{
									Player_SendTextInfo
									(
										ALL, "%s Администратор ^4%s^1 выдал себе невидимость !", PREFIX, Player_GetName(pId)
									);
								}
								else
								{
									Player_SendTextInfo
									(
										ALL, "%s Администратор ^4%s^1 выдал невидимость ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
									);
								}
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь невидимость !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет невидимость !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_NOSTEPS: //Бесшумные шаги
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsNoSteps(pIde))
					{
						case false:
						{
							g_bNoSteps[pId] = true;
							
							Player_SetNoSteps(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе бесшумные шаги !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесшумные шаги ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь бесшумные шаги !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет бесшумные шаги !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_UNLIMAMMO: //Бесконечные патроны
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsUnlimAmmo(pIde))
					{
						case false:
						{
							Player_SetUnlimAmmo(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе бесконечные патроны !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные патроны ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет бесконечные патроны !", PREFIX, Player_GetName(pIde)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет бесконечные патроны !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_UNLIMHE: //Бесконечные гранаты
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsUnlimHe(pIde))
					{
						case false:
						{
							Player_SetUnlimHe(pIde);
							//Player_SetWeaponHe(pIde);

							
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал себе бесконечные гранаты !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выдал бесконечные гранаты ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь бесконечные гранаты !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет бесконечные гранаты !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				
					g_bShowPlayers[pId] = true;
				}
				case ITEM_HELP_GLOW: //Свечение
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					ShowMenu_ChooseGlow(pId);
					
					g_bShowPlayers[pId] = false;
				}
			}
		}
		case ITEM_TYPE_PUNISH:
		{
			switch(Player_GetMenuItem(pId))
			{
				case ITEM_PUNISH_KILL: //Убить
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					Player_SetKill(pIde, pId, 2);
					
					if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
					
					if(pId == pIde)
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 убил себя !", PREFIX, Player_GetName(pId)
						);
					}
					else
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 убил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
						);
					}
				}
				case ITEM_PUNISH_BURY: //Закопать
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBury(pIde))
					{
						case false:
						{
							Player_SetBury(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 закопал себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 закопал ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже закопан !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже закопан !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_MUTE: //Вставить кляп
				{
					switch(IsMute(pIde))
					{
						case false:
						{
							Player_SetMute(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выставил себе кляп !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 выставил кляп ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь кляп !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет кляп !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_BURN: //Поджечь
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBurn(pIde))
					{
						case false:
						{
							Player_SetBurn(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 поджёг себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 поджёг ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже горишь !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже горит !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_POSION: //Отравить
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsPoison(pIde))
					{
						case false:
						{
							Player_SetPoison(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отравил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 отравил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже отравлен !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже отравлен !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_STRIP: //Лишить оружия
				{
					if(jbe_is_user_not_alive((pIde)) || !IsValidPev(pIde)) return;
					
					/*new iBitWeapons = get_entvar(pIde, var_weapons);

					if((iBitWeapons &= ~(1<<CSW_HEGRENADE|1<<CSW_SMOKEGRENADE|1<<CSW_FLASHBANG|1<<CSW_KNIFE|1<<31)) && Player_GetItemChoose(pId) == CHOOSE_ID)
					{
						
						if(pId == pIde)
						{
							Player_SendTextInfo
							(
								pId, "%s У тебя нет оружия !", PREFIX 
							)
						}
						else
						{
							Player_SendTextInfo
							(
								pId, "%s Игрок ^3%s^1 не имеет оружия !", PREFIX, Player_GetName(pIde)
							)
						}
						return;
					}*/
					
					
					rg_remove_items_by_slot(pIde, PRIMARY_WEAPON_SLOT);
					rg_remove_items_by_slot(pIde, PISTOL_SLOT);
					rg_remove_items_by_slot(pIde, GRENADE_SLOT);
					
					new iItem = rg_find_weapon_bpack_by_name(pIde, "weapon_knife");
	
					if(iItem)
					{
						iItem != get_member(pIde, m_pActiveItem) ? rg_switch_weapon(pIde, iItem) : ExecuteHamB(Ham_Item_Deploy, iItem);
					}
					
					
					if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
					
					if(pId == pIde)
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 лешил себя оружия !", PREFIX, Player_GetName(pId)
						);
					}
					else
					{
						Player_SendTextInfo
						(
							ALL, "%s Администратор ^4%s^1 лешил оружия ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
						);
					}
				}
				case ITEM_PUNISH_BLIND: //Ослепить
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBlind(pIde))
					{
						case false:
						{
							Player_SetBlind(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 ослепил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 ослепил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже ослеплён !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже ослеплён !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_GRUGS: //Наркотики
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsDrugs(pIde))
					{
						case false:
						{
							Player_SetDrugs(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 посадил себя на наркотики !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 посадил на наркотики ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже под наркотиками !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже под наркотиками !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_SHAKE: //Землетрясение
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsShake(pIde))
					{
						case false:
						{
							Player_SetShake(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 включил себе землетресение !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 включил землетресение ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь землетресение !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже имеет землетресение !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_PUNISH_FROST: //Заморозить игрока
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(get_frozen_status(pIde))
					{
						case false:
						{
							//Player_SetFrozen(pIde);
							
							set_frozen_status(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 заморозил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 заморозил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты уже имеешь заморожен !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 уже заморожен !", PREFIX, Player_GetName(pIde)
								);
							}
						}
					}
				}
			}
		
			g_bShowPlayers[pId] = true;
		}
		case ITEM_TYPE_OTHER:
		{
			switch(Player_GetMenuItem(pId))
			{

				case ITEM_OTHER_EDITWPN: //Редактировать оружие
				{
					ShowMenu_Weapons(pId);
				}
			}
			g_bShowPlayers[pId] = false;
		}
		case ITEM_TYPE_RESET:
		{
			switch(Player_GetMenuItem(pId))
			{
				case ITEM_RESET_INVIS: //Убрать невидимость
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsInvis(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты видим !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет невидимость !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetInvis(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе невидимость !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал невидимость ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_FROST: //Разморозить
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(get_frozen_status(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты не заморожен !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не заморожен !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							//Player_ResetFrozen(pIde);
							set_frozen_status(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 разморозил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 разморозил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_SHAKE: //Убрать землетресение
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsShake(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет землетресения !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет землетресение !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetShake(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе землетресение !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал землетресение ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_DRUGS: //Убрать наркотики
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsDrugs(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет наркотиков !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет наркотиков !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetDrugs(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал у себя наркотики !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
								ALL, "%s Администратор ^4%s^1 убрал наркотики ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_BLIND: //Венуть зрение
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBlind(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет ослеплённости !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет ослеплённости !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetBlind(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе ослеплённость !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал ослеплённость ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_SPEED: //Убрать скорость
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsSpeed(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет скорости !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет скорость !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetSpeed(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе скорость !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал скорость ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_GRAVITY: //Убрать гравитацию
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsGravity(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет гравитации !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет гравитацию !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetGravity(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе гравитацию !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал гравитацию ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_HIDEWALL: //Вернуть стены
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsNoClip(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет скрытых стен !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет скрытых стен !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetNoClip(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе скрытые стены !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал скрытые стены ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_GODMODE: //Убрать бессмертие
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsGodMode(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет бессмертия !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет бессмертия !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetGodMode(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе бессмертие !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал бессмертие ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_GLOW: //Убрать свечение
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsGlow(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет свечения !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет свечения !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetGlow(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе свечение !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал свечение ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_UNLIMAMMO: //Убрать беск. патроны
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsUnlimAmmo(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет бесконечных патронов !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет бесконечных патронов !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetUnlimAmmo(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе бесконечные патроны !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал бесконечные патроны ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_UNLIMHE: //Убрать беск. гранаты
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsUnlimHe(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет бесконечных гранат !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет бесконечных гранат !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetUnlimHe(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе бесконечные гранаты !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал бесконечные гранаты ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_NOSTEPS: //Убрать бесшумные шаги
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsNoSteps(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет бесшумных шагов !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет бесшумных шагов !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetNoSpeps(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе бесшумные шаги !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал бесшумные шаги ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_BURN: //Потушить игрока
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBurn(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет пламени !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет пламени !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetBurn(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 потушил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 потушил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_POSION: //Вылечить от яда
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsPoison(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет отравления !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет отравления !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetPoison(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 излечил себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 излечил ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_MUTE: //Убрать кляп
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsMute(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s У тебя нет кляпа !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не имеет кляпа !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetMute(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал себе кляп !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 убрал кляп ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
				case ITEM_RESET_BURY: //Откопать игрока
				{
					if(jbe_is_user_not_alive((pIde))) return;
					
					switch(IsBury(pIde))
					{
						case false:
						{
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									pId, "%s Ты не закопан !", PREFIX
								);
							}
							else
							{
								Player_SendTextInfo
								(
									pId, "%s Игрок ^4%s^1 не закопан !", PREFIX, Player_GetName(pIde)
								);
							}
						}
						case true:
						{
							Player_ResetBury(pIde);
							
							if(Player_GetItemChoose(pId) != CHOOSE_ID) return;
							
							if(pId == pIde)
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 откапал себя !", PREFIX, Player_GetName(pId)
								);
							}
							else
							{
								Player_SendTextInfo
								(
									ALL, "%s Администратор ^4%s^1 откапал ^3%s^1 !", PREFIX, Player_GetName(pId), Player_GetName(pIde)
								);
							}
						}
					}
				}
			}
		
			g_bShowPlayers[pId] = true;
		}
	}

	if(Player_GetItemChoose(pId) == CHOOSE_ID && g_bShowPlayers[pId])
	{
		_PLAYERS_MENU_CALLBACK(Saved, pId);
	}
}

public Task_PlayerRespawn(pId)
{
	pId -= TASK_PLAYER_RESPAWN;
	
	if(IsNotSetBit(g_iBitUserConnected, pId) || jbe_is_user_alive(pId) || is_user_hltv(pId)) return;
	
	Player_SetLife(pId);
}


Player_SetBury(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	g_bBury[pId] = true;
	
	new Float:vecOrigin[3];
	get_entvar(pId, var_origin, vecOrigin);
	
	vecOrigin[2] -= 30.0;
	
	set_entvar(pId, var_origin, vecOrigin);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetBury");
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
	write_byte(TE_BREAKMODEL); // TE_
	write_coord(floatround(vecOrigin[0])); // X
	write_coord(floatround(vecOrigin[1])); // Y
	write_coord(floatround(vecOrigin[2]) + 24); // Z
	write_coord(16); // size X
	write_coord(16); // size Y
	write_coord(16); // size Z
	write_coord(random_num(-50,50)); // velocity X
	write_coord(random_num(-50,50)); // velocity Y
	write_coord(25); // velocity Z
	write_byte(10); // random velocity
	write_short(g_iModelIndex_RockGibs); // sprite
	write_byte(9); // count
	write_byte(20); // life
	write_byte(0x08); // flags
	message_end();
}

Player_ResetBury(pId)
{
	g_bBury[pId] = false;
	
	new Float:vecOrigin[3];
	get_entvar(pId, var_origin, vecOrigin);
	
	vecOrigin[2] += 30.0;
	
	set_entvar(pId, var_origin, vecOrigin);
}

const MsgId_Demage = 71;
const MsgId_ScreenFade = 98;

Player_SetBurn(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	
	if(IsBlind(pId)) 	Player_ResetBlind(pId);
	if(IsPoison(pId)) 	Player_ResetPoison(pId);
	//if(IsFrozen(pId)) 	Player_ResetFrozen(pId);
	if(get_frozen_status(pId)) set_frozen_status(pId);
	
	g_bBurn[pId] = true;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetBurn");
	}

	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0); // duration
	write_short(1<<0); // hold time
	write_short(1<<2); // fade type
	write_byte(255); // r
	write_byte(44); // g
	write_byte(0); // b
	write_byte(100); // alpha
	message_end();
	
	set_task(1.0, "Task_PlayerFlame", pId + TASK_PLAYER_BURN, _, _, "b");
}

public Task_PlayerFlame(pId)
{
	pId -= TASK_PLAYER_BURN;
	
	if(!IsBurn(pId))
	{
		if(task_exists(pId + TASK_PLAYER_BURN))
		{
			remove_task(pId + TASK_PLAYER_BURN);
		}
		return;
	}
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Task_PlayerFlame");
	}
	
	new vecOrigin[3];
	get_user_origin(pId, vecOrigin);
	
	new iFlags = get_entvar(pId, var_flags);
	
	if(iFlags & FL_INWATER)
	{
		g_bBurn[pId] = false;
		
		if(!jbe_is_user_valid(pId)) return;
		
		
		
		message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
		write_short(1<<0);
		write_short(1<<0);
		write_short(1<<1);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		message_end();
		
		if(task_exists(pId + TASK_PLAYER_BURN))
		{
			remove_task(pId + TASK_PLAYER_BURN);
		}
		return;
	}
	
	// Fire slow down
	if(iFlags & FL_ONGROUND)
	{
		new Float:vecVelocity[3];
		get_entvar(pId, var_velocity, vecVelocity);
		
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		
		set_entvar(pId, var_velocity, vecVelocity);
	}
	
	if(random_num(1, 4) == 1)
	{
		new Float:iHealth = Player_GetHealth(pId);
		switch(floatround(iHealth))
		{
			case 1..5:
			{
				g_bBurn[pId] = false;
				
				if(!jbe_is_user_valid(pId)) return;
				
				
				
				message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
				write_byte(TE_SMOKE); // TE id
				write_coord(vecOrigin[0]); // x
				write_coord(vecOrigin[1]); // y
				write_coord(vecOrigin[2] - 50); // z
				write_short(g_iSpriteIndex_Smoke); // sprite
				write_byte(random_num(15, 20)); // scale
				write_byte(random_num(10, 20)); // framerate
				message_end();
				
				
				message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
				write_short(1<<0);
				write_short(1<<0);
				write_short(1<<1);
				write_byte(0);
				write_byte(0);
				write_byte(0);
				write_byte(0);
				message_end();
				
				if(task_exists(pId + TASK_PLAYER_BURN))
				{
					remove_task(pId + TASK_PLAYER_BURN);
				}
				return;
			}
			default:
			{
				if(!jbe_is_user_valid(pId)) return;
				
				message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
				write_byte(TE_SMOKE); // TE id
				write_coord(vecOrigin[0]); // x
				write_coord(vecOrigin[1]); // y
				write_coord(vecOrigin[2] - 50); // z
				write_short(g_iSpriteIndex_Smoke); // sprite
				write_byte(random_num(15, 20)); // scale
				write_byte(random_num(10, 20)); // framerate
				message_end();
				
				message_begin(MSG_ONE_UNRELIABLE, MsgId_Demage, _, pId);
				write_byte(0); // damage save
				write_byte(0); // damage take
				write_long(DMG_BURN); // damage type
				write_coord(0); // x
				write_coord(0); // y
				write_coord(0); // z
				message_end();
				
				Player_SetHealth(pId, iHealth - CVAR_BURN_DEMAGE);
			}
		}
	}
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE); // TE id
	write_coord(vecOrigin[0] + random_num(-5, 5)); // x
	write_coord(vecOrigin[1] + random_num(-5, 5)); // y
	write_coord(vecOrigin[2] + random_num(-10, 10)); // z
	write_short(g_iSpriteIndex_Flame); // sprite
	write_byte(random_num(5, 10)); // scale
	write_byte(200); // brightness
	message_end();
	
}

Player_ResetBurn(pId)
{
	g_bBurn[pId] = false;
	
	if(task_exists(pId + TASK_PLAYER_BURN))
	{
		remove_task(pId + TASK_PLAYER_BURN);
	}
	
	if(jbe_is_user_not_alive(pId)) return;
	
	new vecOrigin[3];
	get_user_origin(pId, vecOrigin);
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_ResetBurn");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0);
	write_short(1<<0);
	write_short(1<<1);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	message_end();
}

Player_SetPoison(pId)
{
	if(IsBurn(pId)) 	Player_ResetBurn(pId);
	if(IsBlind(pId)) 	Player_ResetBlind(pId);
	//if(IsFrozen(pId)) 	Player_ResetFrozen(pId);
	if(get_frozen_status(pId)) set_frozen_status(pId);
	
	g_bPoison[pId] = true;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetPoison");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0); // duration
	write_short(1<<0); // hold time
	write_short(1<<2); // fade type
	write_byte(0); // r
	write_byte(150); // g
	write_byte(0); // b
	write_byte(100); // alpha
	message_end();
	
	set_task(0.2, "Task_PlayerPoison", pId + TASK_PLAYER_POSION, _, _, "b");
}

public Task_PlayerPoison(pId)
{
	pId -= TASK_PLAYER_POSION;
	
	if(!IsPoison(pId))
	{
		if(task_exists(pId + TASK_PLAYER_POSION))
		{
			remove_task(pId + TASK_PLAYER_POSION);
		}
		return;
	}
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Task_PlayerPoison");
	}
	
	if(random_num(1, 4) == 1)
	{
		new Float:iHealth = Player_GetHealth(pId);
		switch(floatround(iHealth))
		{
			case 1..5:
			{
				g_bPoison[pId] = false;
				
				if(!jbe_is_user_valid(pId)) return;
				
				message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
				write_short(1<<0);
				write_short(1<<0);
				write_short(1<<1);
				write_byte(0);
				write_byte(0);
				write_byte(0);
				write_byte(0);
				message_end();
				
				if(task_exists(pId + TASK_PLAYER_POSION))
				{
					remove_task(pId + TASK_PLAYER_POSION);
				}
				return;
			}
			default:
			{
				if(!jbe_is_user_valid(pId)) return;
				
				message_begin(MSG_ONE_UNRELIABLE, MsgId_Demage, _, pId);
				write_byte(0); // damage save
				write_byte(0); // damage take
				write_long(DMG_NERVEGAS); // damage type - DMG_RADIATION
				write_coord(0); // x
				write_coord(0); // y
				write_coord(0); // z
				message_end();
				
				Player_SetHealth(pId, iHealth - CVAR_BURN_DEMAGE);
			}
		}
	}
}

Player_ResetPoison(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	
	g_bPoison[pId] = false;
	
	if(task_exists(pId + TASK_PLAYER_POSION))
	{
		remove_task(pId + TASK_PLAYER_POSION);
	}
	
	if(jbe_is_user_not_alive(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_ResetPoison");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0);
	write_short(1<<0);
	write_short(1<<1);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	message_end();
}

const MsgId_ScreenShake = 97;

Player_SetShake(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	
	g_bShake[pId] = true;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetShake");
	}

	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenShake, _, pId);
	write_short(1<<14);
	write_short(1<<14);
	write_short(1<<14);
	message_end();
	
	set_task(2.5, "Task_PlayerShake", pId + TASK_PLAYER_SHAKE, _, _, "b");
}

public Task_PlayerShake(pId)
{
	pId -= TASK_PLAYER_SHAKE;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(!IsShake(pId))
	{
		if(task_exists(pId + TASK_PLAYER_SHAKE))
		{
			remove_task(pId + TASK_PLAYER_SHAKE);
		}
		return;
	}
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Task_PlayerShake");
	}
	
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenShake, _, pId);
	write_short(1<<14);
	write_short(1<<14);
	write_short(1<<14);
	message_end();
}

Player_ResetShake(pId)
{
	g_bShake[pId] = false;
	
	if(task_exists(pId + TASK_PLAYER_SHAKE))
	{
		remove_task(pId + TASK_PLAYER_SHAKE);
	}
}

Player_SetFrozen(pId)
{
	if(IsBurn(pId)) 	Player_ResetBurn(pId);
	if(IsBlind(pId)) 	Player_ResetBlind(pId);
	if(IsPoison(pId)) 	Player_ResetPoison(pId);
	
	g_bFrozen[pId] = true;
	
	Player_SetNextAttack(pId, 99999.0);
	
	emit_sound(pId, CHAN_VOICE, SOUND_PLAYER_FROST, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_entvar(pId, var_renderfx, kRenderFxGlowShell);
	set_entvar(pId, var_rendercolor, {0.0, 100.0, 200.0});
	set_entvar(pId, var_rendermode, kRenderNormal);
	set_entvar(pId, var_renderamt, 18.0);
	
	new Float:vecOrigin[3];
	get_entvar(pId, var_origin, vecOrigin);
	
	set_entvar(pId, var_flags, get_entvar(pId, var_flags) | FL_FROZEN);
	set_entvar(pId, var_origin, vecOrigin);
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetFrozen");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_Demage, _, pId);
	write_byte(0); // damage save
	write_byte(0); // damage take
	write_long(DMG_DROWN); // damage type - DMG_FREEZE
	write_coord(0); // x
	write_coord(0); // y
	write_coord(0); // z
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0); // duration
	write_short(1<<0); // hold time
	write_short(1<<2); // fade type
	write_byte(0); // r
	write_byte(50); // g
	write_byte(200); // b
	write_byte(100); // alpha
	message_end();
}

Player_ResetFrozen(pId)
{
	if(IsBurn(pId)) 	Player_ResetBurn(pId);
	if(IsBlind(pId)) 	Player_ResetBlind(pId);
	if(IsPoison(pId)) 	Player_ResetPoison(pId);
	
	g_bFrozen[pId] = false;
	
	Player_SetNextAttack(pId, 0.0);
	
	emit_sound(pId, CHAN_VOICE, SOUND_PLAYER_DEFROST, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_entvar(pId, var_flags, get_entvar(pId, var_flags) & ~FL_FROZEN);
	
	new vecOrigin[3];
	get_user_origin(pId, vecOrigin);
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_ResetFrozen");
	}
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BREAKMODEL); // TE id
	write_coord(vecOrigin[0]); // x
	write_coord(vecOrigin[1]); // y
	write_coord(vecOrigin[2] + 24); // z
	write_coord(16); // size x
	write_coord(16); // size y
	write_coord(16); // size z
	write_coord(random_num(-50, 50)); // velocity x
	write_coord(random_num(-50, 50)); // velocity y
	write_coord(25); // velocity z
	write_byte(10); // random velocity
	write_short(g_iModelIndex_Frost); // model
	write_byte(10); // count
	write_byte(25); // life
	write_byte(0x01); // flags
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<0);
	write_short(1<<0);
	write_short(1<<1);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	message_end();
	
	set_entvar(pId, var_renderfx, kRenderFxNone);
	set_entvar(pId, var_rendercolor, {255.0, 255.0, 255.0});
	set_entvar(pId, var_rendermode, kRenderNormal);
	set_entvar(pId, var_renderamt, 18.0);
}

Player_GetName(pId)
{
	new szName[32];
	get_user_name(pId, szName, charsmax(szName));
	
	return szName;
}

Player_SetBlind(pId)
{
	if(IsBurn(pId)) 	Player_ResetBurn(pId);
	if(IsPoison(pId)) 	Player_ResetPoison(pId);
	//if(IsFrozen(pId)) 	Player_ResetFrozen(pId);
	if(get_frozen_status(pId)) set_frozen_status(pId);
	
	g_bBlind[pId] = true;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetBlind");
	}
	
	message_begin(MSG_ONE, MsgId_ScreenFade, _, pId);
	write_short(1<<0);
	write_short(1<<0);
	write_short(1<<2);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(255);
	message_end();
}

Player_ResetBlind(pId)
{
	g_bBlind[pId] = false;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_ResetBlind");
	}
	message_begin(MSG_ONE, MsgId_ScreenFade, _, pId);
	write_short(1<<0);
	write_short(1<<0);
	write_short(1<<1);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	message_end();
}

const MsgId_SetFOV = 95;

Player_SetDrugs(pId)
{
	g_bDrugs[pId] = true;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_SetDrugs");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, pId);
	write_byte(170);
	message_end();
}

Player_ResetDrugs(pId)
{
	g_bDrugs[pId] = false;
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[OAIOMENU] Player_ResetDrugs");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, pId);
	write_byte(0);
	message_end();
}

Player_GetMenu_Next(pId, &iPage, const szTitle[], const szMenuId[], const szItems[][], iItemsNum)
{
	return Player_GetMenu(pId, ++iPage, szTitle, szMenuId, szItems, iItemsNum);
}

Player_GetMenu_Back(pId, &iPage, const szTitle[], const szMenuId[], const szItems[][], iItemsNum)
{
	return Player_GetMenu(pId, --iPage, szTitle, szMenuId, szItems, iItemsNum);
}

stock Player_GetMenu_Saved(pId, &iPage, const szTitle[], const szMenuId[], const szItems[][], iItemsNum)
{
	return Player_GetMenu(pId, iPage, szTitle, szMenuId, szItems, iItemsNum);
}

Player_GetMenu_New(pId, &iPage, const szTitle[], const szMenuId[], const szItems[][], iItemsNum)
{
	return Player_GetMenu(pId, iPage = 0, szTitle, szMenuId, szItems, iItemsNum);
}

Player_GetMenu(pId, iPage, const szTitle[], const szMenuId[], const szItems[][], iItemsNum)
{
	if(iPage < 0) return PLUGIN_HANDLED;
	
	new i = min(iPage * 7, iItemsNum);
	
	new iStart 	= i - (i % 7);
	new iEnd 	= min(iStart + 7, iItemsNum);
	
	new iPlayerPages = ((iItemsNum - 1) / 7) + 1;
	
	iPage = iStart / 7;
	
	g_iPlayerMenuPage[pId] = iPage;
	
	new szMenu[512], iLen;
	//jbe_informer_offset_up(pId);
	MENU_TITLE(szMenu, iLen, "%s^n^n", szTitle);
	
	new iItem, iKey;
	new bitsKeys = KEY(0);
	
	for(i = iStart; i < iEnd; i++)
	{
		iKey = (iPage * 7) + iItem;
		g_iPlayerMenuTarget[pId][iKey] = iKey;
		
		bitsKeys |= KEY(++iItem);
		
		MENU_ITEM(szMenu, iLen, "\y%d. \w%s^n", iItem, szItems[iKey]);
	}
	
	if(iPage)
	{
		bitsKeys |= KEY(8);
	
		MENU_ITEM(szMenu, iLen, "^n\y8. \wНазад");
	}
	
	if(iPlayerPages > 1 && iPage + 1 < iPlayerPages)
	{
		bitsKeys |= KEY(9);
		
		MENU_ITEM(szMenu, iLen, "^n\y9. \wДалее");
	}
	
	MENU_ITEM(szMenu, iLen, "^n\y0. \wВыход");
	
	return SHOW_MENU(pId, bitsKeys, szMenu, szMenuId);
}

Player_SendTextInfo(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	
	
	switch(pPlayer)
	{
		case 0:
		{
			if(jbe_globalnyizapret())
			{
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				{
					if(IsNotSetBit(g_iBitUserConnected, iPlayer) || jbe_get_user_team(iPlayer) == 1) continue;
					
					engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
					write_byte(iPlayer);
					write_string(szBuffer);
					message_end();
				}
			}
			else
			{
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				{
					if(IsNotSetBit(g_iBitUserConnected, iPlayer)) continue;
					
					engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
					write_byte(iPlayer);
					write_string(szBuffer);
					message_end();
				}
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
}

Player_SetNextAttack(pId, Float:flBlockTime)
{
	set_member(pId, m_flNextAttack, flBlockTime);
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
	//SetBit(g_iBitUserNotAttacked, id);
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

new bool:BufferPushTeleport[MAX_PLAYERS + 1];

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		
		//new Float:fDamageOld = fDamage;
		if(jbe_get_user_team(iAttacker) == 1 && jbe_get_user_team(iVictim) == 2)
		{
			if(IsSetBit(g_iBitUserNotAttacked, iAttacker))
			{
				if(!BufferPushTeleport[iAttacker] && !task_exists(iAttacker + 45748))
				{

					CenterMsgFix_PrintMsg(iAttacker, print_center, "Запрещено бунт после с выданной оружие!");
					CenterMsgFix_PrintMsg(iVictim, print_center, "Вам не нанес урон игрок %n, поскольку у него был выдан оружие!", iAttacker);
					
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

public dontwanted(id)
{
	id -= 45748;

	BufferPushTeleport[id] = false;
}

stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}









Show_ResetMenu(id)
{
	new szMenu[512], iLen, iKeys = (1<<0|1<<1|1<<2|1<<9);
	
	FormatMain("\yМеню Сброса способности^n^n");
	
	FormatItem("\y1. \rСбросить у всех^n");
	FormatItem("\y2. \wСбросить определенных игроков^n");
	
	
	FormatItem("^n\y0. \wНазад^n");
	return show_menu(id, iKeys, szMenu, -1, "Show_ResetMenu");   
}

public Handle_ResetMenu(id, key)
{
	switch(key)
    {
		case 0: 
		{
			EventHook_RoundEnd();
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 сбросил все ^4премущество!", PREFIX, Player_GetName(id)
			);
		}
		case 1: return Cmd_ResetControlMenu(id);

		
		case 9: ShowMenu_Oaio(id);

	}
	return PLUGIN_HANDLED;
}

Cmd_ResetControlMenu(pId) return Show_ResetControlMenu(pId, g_iMenuPosition[pId] = 0);
Show_ResetControlMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i)) continue;
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
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yКому сбросить способности? \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
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
	return show_menu(pId, iKeys, szMenu, -1, "Show_ResetControlMenu");
}

public Handle_ResetControlMenu(pId, iKey)
{

	switch(iKey)
	{
		case 8: return Show_ResetControlMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_ResetControlMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			HC_CBasePlayer_PlayerKilled_Post(iTarget)
			Player_SendTextInfo
			(
				ALL, "%s Администратор ^4%s^1 сбросил ^4премущество ^1для ^4%s!", PREFIX, Player_GetName(pId), Player_GetName(iTarget)
			);
		}
	}
	return Show_ResetControlMenu(pId, g_iMenuPosition[pId]);
}

