#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <reapi>



#include <hamsandwich>
#include <fakemeta>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>

native jbe_global_games(pId, iType);

#define PLUGIN 			"[JBE] Crusader"
#define VERSION 		"1.0"
#define AUTHOR			"DalgaPups"

//#define DEBUG						// Для разработчика


#define SKILLS_TECHIES 		30.0	 	// Сколько секунд длится перезарядка способности минера ( С момента, нажатие на дроп )
#define SKILLS_FROST 		60.0 	// Сколько секунд длится перезарядка способности Фроста( С момента, нажатие на дроп )
#define SKILLS_VIPER 		30.0 	// Сколько секунд длится перезарядка способности Ядовитого плюща( С момента, нажатие на дроп )

#define SKILLS_PUDGE 		10.0 	// Сколько секунд длится перезарядка способности Мясника( С момента, нажатие на дроп )
#define CLASSNAME_DRAGONCLAW "dragonclaw_entity" // Класснейм энтити
#define TIME_HOOK_PLAYER	6.0 // Сколько секунд игрок может притягивать игрока
#define HOOK_FLY_SPEED 		1000.0 // Скорость хука в полете
#define HOOK_SPEED 			300.0


#define SKILLS_PALADINS 	40.0 	// Сколько секунд длится перезарядка способности Паладина( С момента, нажатие на дроп )
#define SKILLS_DEVA 		120.0	// Сколько секунд длится перезарядка способности Жрица( С момента, нажатие на дроп )
#define SKILLS_PALACH 		40.0		// Сколько секунд длится перезарядка способности Палача( С момента, нажатие на дроп )
#define SKILLS_GUNMAN 		30.0		// Сколько секунд длится перезарядка способности Оружейника( С момента, нажатие на дроп )
#define SKILLS_BAFFER 		20.0		// Сколько секунд длится перезарядка способности Баффера( С момента, нажатие на дроп )
#define SKILLS_ELECTROMAN 	30.0		// Сколько секунд длится перезарядка способности Электрошокера( С момента, нажатие на дроп )

#define HEALTS_TECHIES 		700.0	// Жизни Минера
#define HEALTS_FROST		700.0	// Жизни Фроста
#define HEALTS_VIPER		600.0	// Жизни Ядовитого плюща
#define HEALTS_PUDGE		1000.0	// Жизни Мясника

#define HEALTS_PALADINS		5000.0	// Жизни Паладина
#define HEALTS_DEVA			1000.0	// Жизни Жрицы
#define HEALTS_PALACH		1000.0	// Жизни Палача
#define HEALTS_GUNMAN		1500.0	// Жизни Оружейнника
#define HEALTS_BAFFER		1000.0	// Жизни Баффера
#define HEALTS_ELECTROMAN	700.0	// Жизни Электрошокера

#define SPEED_BAFFER		200.0	// Скорость Баффера
#define SPEED_MINER			500.0	// Скорость Минера при бафе
#define SPEED_MINER_RESET	400.0	// Скорость Минер по умолчание
#define SPEED_PUDGE			50.0		// Скорость Мясника	
#define SPEED_GUNMAN		400.0	// Скорость Оружейнника
#define SPEED_ELECTROMAN	550.0	// Скорость Электрошокера
#define SPEED_DEVA			310.0	// Скорость Жрицы

#define BULLET_GUN			9999		// Максимальное патроны при выдачи

#define TASKS_SKILLS_MINER			6.0
#define TASKS_SKILLS_FROST			10.0
#define TASKS_SKILLS_VIPER			10.0
#define TASKS_SKILLS_PALADIN 		5.0
#define TASKS_SKILLS_PALACH			5.0
#define TASKS_SKILLS_GUNMAN			5.0
#define TASKS_SKILLS_BAFFER			5.0
#define TASKS_SKILLS_ELECTROMAN		5.0

#define TASKS_SKILLS
	
#define MODEL_FROST				"models/glassgibs.mdl"
#define SOUND_PLAYER_FROST		"jb_engine/freeze_player.wav"
#define SOUND_PLAYER_DEFROST	"jb_engine/defrost_player.wav"
#define MODEL_GIBS				"models/rockgibs.mdl"
#define MODEL					"models/player/cso_model/cso_model.mdl"
#define SOUNDEFF				"jb_engine/use_skills.wav"
#define MODEL_GIRL				"models/player/jail_g1rlds_guard/jail_g1rlds_guard.mdl"

#define HOOKSPRITE				"sprites/jb_engine/dragonclaw_hook/bone_chain.spr"
#define SPRITE_LINE				"sprites/zbeam4.spr"

#define PRECACHE_MODEL(%0) engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0) engfunc(EngFunc_PrecacheSound, %0)

new const g_szHookModels[][] =
{
	"models/jb_engine/dragonclaw_hook/v_skeleton_hook.mdl",
	"models/jb_engine/dragonclaw_hook/p_skeleton_hook.mdl",
	"models/jb_engine/dragonclaw_hook/w_skeleton_hook.mdl"
};


enum _:(+= 100)
{	
	TASK_SHOW_INFORMER 	= 55000,
	TASK_SHOW_SKILLS,
	TASK_PLAYER_HOOKED ,
	TASK_SHOW_MENU,
	TASK_BOSSHEALT
}

#pragma semicolon 1


#define MsgId_Demage 							71
#define MsgId_SetFOV							95
#define MsgId_ScreenFade						98
#define MsgId_ScreenShake 						97


#define PLAYERS_PER_PAGE 7

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

/** pId */
#define IsValidPev(%1) (bool:(pev_valid(%1) == 2))

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

native jbe_mafia_end();
native jbe_mafia_start();
native jbe_set_friendlyfire(iType);
native jbe_set_global(iType);
native jbe_hide_user_costumes(pPlayer);
native jbe_set_user_model_ex(pId, iType);

new iCount,
	Float:HealtBoss;

new bool:g_bUnlimAmmo[33];
	
	/** pId */
	#define IsUnlimAmmo(%1) g_bUnlimAmmo[%1]
	#define Player_SetUnlimAmmo(%1) (g_bUnlimAmmo[%1] = true)
	#define Player_ResetUnlimAmmo(%1) (g_bUnlimAmmo[%1] = false)

new const szWeaponName[][] = //24 
{
	"weapon_p228",
	"weapon_scout",
	"weapon_xm1014",
	"weapon_mac10",
	"weapon_aug",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_p90"
};
	
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

static const g_szBossRoleName[5][]=
{
	"JBE_ROLE_NOT_CHOOSED",
	"JBE_ROLE_TECHIES",
	"JBE_ROLE_FROST",
	"JBE_ROLE_VIPER",
	"JBE_ROLE_PUDGE"
};


static const g_szBossSkillsName[5][]=
{
	"JBE_ROLE_SKILLS_NOT_CHOOSED",
	"JBE_ROLE_SKILLS_TECHIES",
	"JBE_ROLE_SKILLS_FROST",
	"JBE_ROLE_SKILLS_VIPER",
	"JBE_ROLE_SKILLS_PUDGE"
};

static const g_szHeroesRoleName[7][]=
{
	"JBE_ROLE_NOT_CHOOSED",
	"JBE_ROLE_PALADIN",
	"JBE_ROLE_DEVA",
	"JBE_ROLE_PALACH",
	"JBE_ROLE_GUNMAN",
	"JBE_ROLE_BAFFER",
	"JBE_ROLE_ELECTRO"
};
static const g_szHeroesSkillsName[7][]=
{
	"JBE_ROLE_SKILLS_NOT_CHOOSED",
	"JBE_ROLE_SKILLS_PALADIN",
	"JBE_ROLE_SKILLS_DEVA",
	"JBE_ROLE_SKILLS_PALACH",
	"JBE_ROLE_SKILLS_GUNMAN",
	"JBE_ROLE_SKILLS_BAFFER",
	"JBE_ROLE_SKILLS_ELECTRO"
};


new g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iUserID[MAX_PLAYERS + 1][MAX_PLAYERS],
	g_iMenuType[MAX_PLAYERS + 1];

new bool:g_iGameStart,
	bool:g_iStartBox,
	bool:g_iUserBoss[MAX_PLAYERS + 1],
	bool:g_iUserHeroes[MAX_PLAYERS + 1];

new g_iUserRoleBoss[MAX_PLAYERS + 1],
	g_iUserRoleHero[MAX_PLAYERS + 1];

new HookChain:HookPlayer_ResetMaxSpeed,
	HookChain:HookPlayer_PlayerTakeDamage,
	HookChain:HookPlayer_PlayerTraceAttack,
	HookChain:HookPlayer_PlayerRespawn,
	HookChain:HookPlayer_PlayerDropWeapons,
	HookChain:HookPlayer_PlayerKilled,
	HamHook:g_iHamHookPudge,
	HamHook:g_iHamHookUnlimAmmo[24];

new g_iSyncCrusInformer,
	g_iSyncSkillsInformer;

new g_iBitUserFrost,
	g_iBitUserBury,
	g_iBitUserDrugs;

new g_iModelIndex_Frost,
	g_iModelIndex_RockGibs;
	
new Float: g_flTimeReload[MAX_PLAYERS + 1],
	g_pPlayerId[MAX_PLAYERS + 1],
	g_iHookEntity,
	g_iSynStatusValue;
	
new g_iszBeamFollowLine,
	g_iBitDragonClawHook,
	g_iszBeamPointLine,
	g_iBitUserDamage,
	g_iBitUserElectro,
	g_iBitUserSpeed,
	g_iBitUserGravity,
	g_iBitUserGodMode;
	
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	menu_init();
	clcmd_init();
	reapi_init();
	event_init();
	hamsandwich_init();
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public plugin_natives()
{
	register_native("jbe_get_ff_crusader", "jbe_get_ff_crusader", true);
}

public jbe_get_ff_crusader() return g_iGameStart;

menu_init()
{
	register_menucmd(register_menuid("Show_Crusader"), 			(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_Crusader");
	register_menucmd(register_menuid("Show_BossGiveRole"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_BossGiveRole");
	register_menucmd(register_menuid("Show_GiveRoleBoss"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_GiveRoleBoss");
	register_menucmd(register_menuid("Show_HeroesGiveRole"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_HeroesGiveRole");
	register_menucmd(register_menuid("Show_GiveRoleHeroes"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_GiveRoleHeroes");
}
clcmd_init()
{
	register_clcmd("crusader", "ClCmd_Crusader");
	register_clcmd("drop", "ClCmd_Drop");
}

reapi_init()
{
	DisableHookChain(HookPlayer_ResetMaxSpeed 		= 	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 	"HC_CBasePlayer_ResetMaxSpeed", 		true));
	DisableHookChain(HookPlayer_PlayerRespawn 		=	RegisterHookChain(RG_CBasePlayer_Spawn, 			"HC_CBasePlayer_PlayerSpawn_Post", 		true));
	DisableHookChain(HookPlayer_PlayerTakeDamage	= 	RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Player", 	false));
	DisableHookChain(HookPlayer_PlayerTraceAttack	= 	RegisterHookChain(RG_CBasePlayer_TraceAttack,		"HC_CBasePlayer_TraceAttack_Player", 	false));
	DisableHookChain(HookPlayer_PlayerDropWeapons	= 	RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "CSGameRules_DeadPlayerWeapons"));
	DisableHookChain(HookPlayer_PlayerKilled		=	RegisterHookChain(RG_CBasePlayer_Killed, 			"HC_CBasePlayer_PlayerKilled_Post", true));
}
event_init()
{
	register_dictionary("jbe_crusader.txt");
	
	g_iSyncCrusInformer = CreateHudSyncObj();
	g_iSyncSkillsInformer = CreateHudSyncObj();
	g_iSynStatusValue = CreateHudSyncObj();
	
	register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
	register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	register_event("CurWeapon", "current_weapon_two", "be", "1=1");
}

hamsandwich_init()
{
	DisableHamForward(g_iHamHookPudge 				= 	RegisterHam(Ham_Touch, "info_target", "HamHook_EntityTouch_Post", 1));
	for(new i; i <= 8; i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	for(new i = 0; i < sizeof(szWeaponName); i++)
	{
		DisableHamForward(g_iHamHookUnlimAmmo[i] = RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName[i], "HamHook_PrimaryAttack_Post", true));
	}
}
public Event_StatusValueShow(pId)
{
	if(g_iGameStart)
	{
		new iTarget = read_data(2);

		set_hudmessage(0, 255, 255, -1.0, 0.8, 0, 0.0, 4.0, 0.0, 0.0, -1);
		if(g_iUserBoss[iTarget])
		{
			ShowSyncHudMsg(pId, g_iSynStatusValue, "Ник:[%n]^nХП: %d | Броня: %d^nРоль: %L", iTarget, get_user_health(iTarget), get_user_armor(iTarget), LANG_PLAYER, g_szBossRoleName[g_iUserRoleBoss[iTarget]]);
		}
		else 
		if(g_iUserHeroes[iTarget])
		{
			ShowSyncHudMsg(pId, g_iSynStatusValue, "Ник:[%n]^nХП: %d | Броня: %d^nРоль: %L", iTarget, get_user_health(iTarget), get_user_armor(iTarget), LANG_PLAYER, g_szHeroesRoleName[g_iUserRoleHero[iTarget]]);
		}
		else ShowSyncHudMsg(pId, g_iSynStatusValue, "Ник:[%n]^nХП: %d | Броня: %d", iTarget, get_user_health(iTarget), get_user_armor(iTarget));
	}
}

public Event_StatusValueHide(pId) 
{
	if(g_iGameStart)
	{
		ClearSyncHud(pId, g_iSynStatusValue);
	}
}
public LogEvent_RoundEnd()
{
	if(g_iGameStart)
	{
		
		DisableHookChain(HookPlayer_ResetMaxSpeed);
		DisableHookChain(HookPlayer_PlayerTakeDamage);
		DisableHookChain(HookPlayer_PlayerTraceAttack);
		DisableHookChain(HookPlayer_PlayerRespawn);
		DisableHookChain(HookPlayer_PlayerDropWeapons);
		DisableHookChain(HookPlayer_PlayerKilled);
		
		
		
		for(new i; i < charsmax(g_iHamHookUnlimAmmo); i++) DisableHamForward(g_iHamHookUnlimAmmo[i]);
		for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		
		DisableHamForward(g_iHamHookPudge);
		
		state dBlockCmd: Disabled;
		jbe_mafia_end();
		if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
		jbe_set_friendlyfire(0);
		jbe_set_global(0);
		g_iGameStart = false;
		
		g_iBitUserDamage = 0;
		g_iBitUserElectro = 0;
		g_iBitUserSpeed = 0;
		g_iBitUserGravity = 0;
		g_iBitUserGodMode = 0;
		
		new ent = -1;
		while((ent = rg_find_ent_by_class(ent, CLASSNAME_DRAGONCLAW)))
		if(is_entity(ent))
		{
			set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_KILLME);
			set_entvar(ent, var_nextthink, get_gametime());
		}
		
		static iPlayers[MAX_PLAYERS], iPlayerCount;
		get_players_ex(iPlayers, iPlayerCount, GetPlayers_None);
		
		for(new i; i < iPlayerCount; i++)
		{
			if(is_user_connected(iPlayers[i]))
			{
				g_iBitDragonClawHook = 0;
				if(IsSetBit(g_iBitUserBury, iPlayers[i])) Bury_off(iPlayers[i]);
				if(IsSetBit(g_iBitUserDrugs, iPlayers[i])) Player_ResetDrugs(iPlayers[i]);
				if(IsSetBit(g_iBitUserFrost, iPlayers[i])) Player_ResetFrozen(iPlayers[i]);
				
				g_iUserBoss[iPlayers[i]] = false;
				g_iUserHeroes[iPlayers[i]] = false;

				if(g_iUserRoleBoss[iPlayers[i]]) reset_values(iPlayers[i]);
					
				g_iUserRoleBoss[iPlayers[i]] = 0;
				//g_iUserRoleHero[iPlayers[i]] = 0;
				
				if(jbe_get_user_team(iPlayers[i]) == 1)
				{
					set_entvar(iPlayers[i], var_health, 100.0);
					set_entvar(iPlayers[i], var_gravity, 1.0);
					rg_reset_maxspeed(iPlayers[i]);
					rg_set_user_footsteps(iPlayers[i], false);
					rg_remove_all_items(iPlayers[i]);
					
					rg_give_item(iPlayers[i], "weapon_knife", GT_APPEND);
				}
			}
		}
	}
}



public plugin_precache()
{
	PRECACHE_SOUND(SOUND_PLAYER_FROST);
	PRECACHE_SOUND(SOUNDEFF);
	PRECACHE_MODEL(MODEL);
	PRECACHE_MODEL(MODEL_GIRL);
	
	g_iszBeamPointLine 		= PRECACHE_MODEL(SPRITE_LINE);
	g_iszBeamFollowLine 	= PRECACHE_MODEL(HOOKSPRITE);
	g_iModelIndex_Frost 	= PRECACHE_MODEL(MODEL_FROST);
	g_iModelIndex_RockGibs 	= PRECACHE_MODEL(MODEL_GIBS);
	
	for(new i = 0; i < sizeof g_szHookModels; i++)
		engfunc(EngFunc_PrecacheModel, g_szHookModels[i]);
		
		
	engfunc(EngFunc_PrecacheModel, "models/jb_engine/weapons/v_golden_ak47.mdl");
	engfunc(EngFunc_PrecacheModel, "models/jb_engine/weapons/v_electroweapons.mdl");
	engfunc(EngFunc_PrecacheModel, "models/jb_engine/weapons/p_golden_ak47.mdl");
}

public client_disconnected(pId)
{
	if(g_iGameStart)
	{
		if(pId == jbe_get_chief_id())
		{
			LogEvent_RoundEnd();
		}
		
		g_iUserBoss[pId] = false;
		g_iUserHeroes[pId] = false;
		g_iUserRoleHero[pId] = 0;
		g_iUserRoleBoss[pId] = 0;
		ClearBit(g_iBitUserDamage, pId);
		ClearBit(g_iBitUserElectro, pId);
		ClearBit(g_iBitUserSpeed, pId);
		ClearBit(g_iBitUserGravity, pId);
		ClearBit(g_iBitUserGodMode, pId);

		
		if(IsSetBit(g_iBitDragonClawHook, pId)) ClearBit(g_iBitDragonClawHook, pId);
	}
}

public current_weapon_two(id)
{
	if(g_iGameStart)
	{
		if(!is_user_alive(id))
			return PLUGIN_CONTINUE;
		new weapon = read_data(2);
		if(g_iUserRoleHero[id] == 3 && weapon == CSW_AK47)
		{
			set_entvar(id, var_viewmodel, "models/jb_engine/weapons/v_golden_ak47.mdl");
			set_entvar(id, var_weaponmodel, "models/jb_engine/weapons/p_golden_ak47.mdl");
		}
		if(g_iUserRoleHero[id] == 6 && weapon == CSW_MP5NAVY)
		{
			set_entvar(id, var_viewmodel, "models/jb_engine/weapons/v_electroweapons.mdl");
		}
	}
	return PLUGIN_CONTINUE;
}

public jbe_set_user_godmode(pId, bType) 
{
	switch(bType)
	{
		case 1: SetBit(g_iBitUserGodMode, pId);
		case 0: ClearBit(g_iBitUserGodMode, pId);
	}
	set_entvar( pId, var_takedamage, !bType ? DAMAGE_YES : DAMAGE_NO );
}
public bool: jbe_get_user_godmode(pId) return bool:( get_entvar(pId, var_takedamage) == DAMAGE_NO );

public ClCmd_Drop( pId ) <> { return PLUGIN_CONTINUE; }
public ClCmd_Drop( pId ) <dBlockCmd: Disabled> { return PLUGIN_CONTINUE; } 
public ClCmd_Drop( pId ) <dBlockCmd: Enabled> 
{ 
	if(jbe_is_user_alive(pId) && jbe_get_user_team(pId) == 1)
	{
	
		static Float: fCurTime, Float: fNextTime[MAX_PLAYERS + 1]; fCurTime = get_gametime();
		
		if(fNextTime[pId] >= fCurTime && g_iUserRoleBoss[pId] != 4)
		{
			set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 3.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Ваша способоность в кулдауне, ждите: %.f секунд", fNextTime[pId] - fCurTime);
			client_cmd(pId, "spk sound/buttons/button8.wav");
			
			
			return PLUGIN_HANDLED; 
		}
		
		if(g_iUserRoleBoss[pId])
		{
			if(g_iUserRoleBoss[pId] == 1)
			{
				jbe_set_user_godmode(pId, 1);
				
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && IsNotSetBit(g_iBitUserBury, i))
					{
						Bury(iPlayers[i]);
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}

				set_entvar(pId, var_maxspeed, SPEED_MINER);
				set_task_ex(TASKS_SKILLS_MINER , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				rg_send_bartime(pId, floatround(6.0), false);
				
				set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Минер активировал спасобность^nБосс бесмертен и очень быстрый на 6 секунд, Герои закопаны");
				
				UTIL_SayText(0, "!g* !yМинер активировал спасобность. Босс бесмертен и очень быстрый на !g6 секунд!, Герои закопаны");
				fNextTime[pId] = fCurTime + SKILLS_TECHIES;
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleBoss[pId] == 2)
			{
				
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && IsNotSetBit(g_iBitUserFrost, iPlayers[i]))
					{
						Player_SetFrozen(iPlayers[i]);
						
						
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
				set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Фрост активировал спасобность^nвсе герои замарожены на 10 секунд");
				UTIL_SayText(0, "!g* !yФрост активировал спасобность.Все герои замарожены на !g10 секунд!");
				
				set_task_ex(TASKS_SKILLS_FROST , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				fNextTime[pId] = fCurTime + SKILLS_FROST;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleBoss[pId] == 3)
			{
			
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && IsNotSetBit(g_iBitUserDrugs, iPlayers[i]))
					{
						Player_SetDrugs(iPlayers[i]);
						
						
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
				set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Ядовитый плющ активировал спасобность^nУ героев головокружение^nна 10 секунд");
				UTIL_SayText(0, "!g* !yЯдовитый плющ активировал спасобность.У героев !gголовокружение на 10 секунд");
				
				set_task_ex(TASKS_SKILLS_VIPER , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				fNextTime[pId] = fCurTime + SKILLS_VIPER;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleBoss[pId] == 4)
			{

				if(fm_is_aiming_at_sky(pId))
				{
					UTIL_SayText(pId, "!g* !yНельзя запускать хук в небо!");
					return PLUGIN_HANDLED; 
				}

				if(g_flTimeReload[pId] >= fCurTime)
				{
					UTIL_SayText(pId, "!g* !yПодождите! Хук перезаряжается: !g%1.f", g_flTimeReload[pId] - fCurTime);
					return PLUGIN_HANDLED; 
				}

				static iWeapon; iWeapon = get_pdata_cbase(pId, 373, 5);

				Create_HookEntity(pId);
				g_flTimeReload[pId] = fCurTime + SKILLS_PUDGE;
				set_pdata_float(iWeapon, 46, 12.0, 4);
				set_pdata_float(iWeapon, 47, 12.0, 4);
				set_pdata_float(iWeapon, 48, 12.0, 4);
				UTIL_WeaponAnimation(pId, 2);
			}
		}
		if(g_iUserRoleHero[pId])
		{
			if(g_iUserRoleHero[pId] == 1)
			{
				
				if(g_iBitUserGodMode)
				{
					set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 3.1, 0.2, 0.2, -1);
					ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Ваша способность уже активна");
					client_cmd(pId, "spk sound/buttons/button8.wav");
					return PLUGIN_HANDLED; 
				}
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && IsNotSetBit(g_iBitUserGodMode, iPlayers[i]))
					{
						jbe_set_user_godmode(iPlayers[i], 1);
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
				set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Паладин активировал способность, все герои бессмертны на 5 секунд");
				UTIL_SayText(0, "!g* !yПаладин активировал способность, все герои бессмертны на 5 секунд");
				
				set_task_ex(TASKS_SKILLS_PALADIN , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				fNextTime[pId] = fCurTime + SKILLS_PALADINS;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleHero[pId] == 2)
			{
				
				
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]])
					{
						if(g_iUserRoleHero[iPlayers[i]] == 1)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_PALADINS);
						}
						if(g_iUserRoleHero[iPlayers[i]] == 2)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_DEVA);
						}
						if(g_iUserRoleHero[iPlayers[i]] == 3)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_PALACH);
						}
						if(g_iUserRoleHero[iPlayers[i]] == 4)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_GUNMAN);
						}
						if(g_iUserRoleHero[iPlayers[i]] == 5)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_BAFFER);
						}
						if(g_iUserRoleHero[iPlayers[i]] == 6)
						{
							set_entvar(iPlayers[i], var_health, HEALTS_ELECTROMAN);
						}
					
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
				set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Жрица восстоновила ХП героев");
				UTIL_SayText(0, "!g* !yЖрица восстоновила ХП героев");
				
				
				fNextTime[pId] = fCurTime + SKILLS_DEVA;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleHero[pId] == 3)
			{
				if(g_iBitUserDamage)
				{
					set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 3.1, 0.2, 0.2, -1);
					ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Ваша способность уже активна");
					client_cmd(pId, "spk sound/buttons/button8.wav");
					return PLUGIN_HANDLED; 
				}
				if(IsNotSetBit(g_iBitUserDamage, pId)) 
				{
					SetBit(g_iBitUserDamage, pId);
					Effects_one(pId);
					client_cmd(pId, "spk jb_engine/use_skills.wav");
					UTIL_SayText(0, "!g* !yПалач активировал способность - Урон = 3х");
					
					set_task_ex(TASKS_SKILLS_PALACH , "reset_skills", pId + TASK_SHOW_SKILLS);
					
					fNextTime[pId] = fCurTime + SKILLS_PALACH;
				}
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleHero[pId] == 4)
			{
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && !IsUnlimAmmo(iPlayers[i]))
					{
						Player_SetUnlimAmmo(iPlayers[i]);
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
					
				UTIL_SayText(0, "!g* !yОружейнник активировал способность - Бессконечные патроны героям");
				
				set_task_ex(TASKS_SKILLS_GUNMAN , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				fNextTime[pId] = fCurTime + SKILLS_GUNMAN;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleHero[pId] == 5)
			{
				if(g_iBitUserGravity || g_iBitUserSpeed)
				{
					set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 3.1, 0.2, 0.2, -1);
					ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Ваша способность уже активна");
					client_cmd(pId, "spk sound/buttons/button8.wav");
					return PLUGIN_HANDLED; 
				}
				static iPlayers[MAX_PLAYERS], iPlayerCount;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				
				for(new i; i < iPlayerCount; i++)
				{
					if(g_iUserHeroes[iPlayers[i]] && (IsNotSetBit(g_iBitUserSpeed, iPlayers[i]) || IsNotSetBit(g_iBitUserGravity, iPlayers[i])))
					{
						Player_SetSpeed(iPlayers[i]);
						Player_SetGravity(iPlayers[i]);
					}
					Effects_one(iPlayers[i]);
					client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
				}
					
				UTIL_SayText(0, "!g* !yБаффер активировал способность - Скорость героям");
				
				set_task_ex(TASKS_SKILLS_BAFFER , "reset_skills", pId + TASK_SHOW_SKILLS);
				
				fNextTime[pId] = fCurTime + SKILLS_BAFFER;
				
				return PLUGIN_HANDLED; 
			}
			else
			if(g_iUserRoleHero[pId] == 6)
			{
				if(g_iBitUserElectro)
				{
					set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 3.1, 0.2, 0.2, -1);
					ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Ваша способность уже активна");
					client_cmd(pId, "spk sound/buttons/button8.wav");
					return PLUGIN_HANDLED; 
				}
				if(IsNotSetBit(g_iBitUserElectro, pId)) 
				{
					SetBit(g_iBitUserElectro, pId);
					set_entvar(pId, var_maxspeed, SPEED_ELECTROMAN);
					UTIL_SayText(0, "!g* !yЭлектрошокер активировал способность - Электрические пули");
					
					set_task_ex(TASKS_SKILLS_ELECTROMAN , "reset_skills", pId + TASK_SHOW_SKILLS);
					
					fNextTime[pId] = fCurTime + SKILLS_ELECTROMAN;
				}
				return PLUGIN_HANDLED; 
			}
		}
		return PLUGIN_HANDLED; 
	}
	return PLUGIN_CONTINUE; 
}

public reset_skills(pId)
{
	pId -= TASK_SHOW_SKILLS;
	
	if(g_iUserRoleBoss[pId])
	{
		if(g_iUserRoleBoss[pId] == 1)
		{	
			set_entvar(pId, var_maxspeed, SPEED_MINER_RESET);
			jbe_set_user_godmode(pId, 0);
			
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && IsSetBit(g_iBitUserBury, iPlayers[i]))
				{
					Bury_off(iPlayers[i]);
				}
				client_cmd(iPlayers[i], "spk jb_engine/use_skills.wav");
			}
		}
		else
		if(g_iUserRoleBoss[pId] == 2)
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && IsSetBit(g_iBitUserFrost, iPlayers[i]))
				{
					Player_ResetFrozen(iPlayers[i]);
				}
			}
		}
		else
		if(g_iUserRoleBoss[pId] == 3)
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && IsSetBit(g_iBitUserDrugs, iPlayers[i]))
				{
					Player_ResetDrugs(iPlayers[i]);
				}
			}
		}
	}
	if(g_iUserRoleHero[pId])
	{
		if(g_iUserRoleHero[pId] == 1)
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && IsSetBit(g_iBitUserGodMode, iPlayers[i]))
				{
					jbe_set_user_godmode(iPlayers[i], 0);

				}
			}
		}
		else
		if(g_iUserRoleHero[pId] == 3)
		{
			if(IsSetBit(g_iBitUserDamage, pId)) 
				ClearBit(g_iBitUserDamage, pId);
		}
		else
		if(g_iUserRoleHero[pId] == 4)
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && IsUnlimAmmo(iPlayers[i]))
				{
					Player_ResetUnlimAmmo(iPlayers[i]);
				}
			}
		}
		else
		if(g_iUserRoleHero[pId] == 5)
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && (IsSetBit(g_iBitUserSpeed, iPlayers[i]) || IsSetBit(g_iBitUserGravity, iPlayers[i])))
				{
					Player_ResetSpeed(iPlayers[i]);
					Player_ResetGravity(iPlayers[i]);
				}
			}
		}
		else
		if(g_iUserRoleHero[pId] == 6)
		{
			if(IsSetBit(g_iBitUserElectro, pId)) ClearBit(g_iBitUserElectro, pId);
			rg_reset_maxspeed(pId);
		}
	}
	set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
	ShowSyncHudMsg(pId, g_iSyncSkillsInformer, "Спасобность деактивирована");
}



public ClCmd_Crusader(pId)
{
	#if defined DEBUG
	return Show_Crusader(pId);
	#else
	if((get_user_flags(pId) & ADMIN_LEVEL_F) && pId == jbe_get_chief_id())
	{
		return Show_Crusader(pId);
	}
	return PLUGIN_HANDLED;
	#endif
	
}

Show_Crusader(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;

	FormatMain("\rКрестовый поход^n^n");
	
	FormatItem("\y1. %s игру^n", !g_iGameStart ? "Начать" : "Завершить"), iKeys |= 1<<0;
	if(g_iGameStart)
	{
		FormatItem("\y2. \wВыдать роли Босса^n"), iKeys |= 1<<1;
		FormatItem("\y3. \wВыдать роли Героя^n"), iKeys |= 1<<2;
		FormatItem("\y4. \wВключить огонь \r[%s]^n", g_iStartBox ? "Включен" : "Выключен"), iKeys |= 1<<3;
		FormatItem("\y5. \wРеснуть Всех^n"), iKeys |= 1<<4;
		FormatItem("\y6. \wВыдать Боссу ХП^n"), iKeys |= 1<<5;
		FormatItem("\dВыдаем боссу ХП соотношение кол-во^nгероев к боссу^n\rВыдать перед началом игры^n^n");
	}
	else
	{
		FormatItem("\y2. \dВыдать роли Босса^n");
		FormatItem("\y3. \dВыдать роли Героя^n");
		FormatItem("\y4. \dВкючить огонь^n");
		FormatItem("\y5. \dРеснуть Всех^n");
		FormatItem("\y6. \dВыдать Боссу ХП^n");
	}
	FormatItem("^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_Crusader");
}

public Handle_Crusader(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			if(task_exists(TASK_SHOW_MENU))
			{
				UTIL_SayText(pId, "!g* !yПодождите 5 секунд для выполнение операции");
				return Show_Crusader(pId);
			}
			g_iGameStart = !g_iGameStart;
			
			set_task_ex(5.0 , "none", TASK_SHOW_MENU);

			switch(g_iGameStart)
			{
				case true:
				{
					EnableHookChain(HookPlayer_ResetMaxSpeed);
					EnableHookChain(HookPlayer_PlayerTakeDamage);
					EnableHookChain(HookPlayer_PlayerTraceAttack);
					EnableHookChain(HookPlayer_PlayerRespawn);
					EnableHookChain(HookPlayer_PlayerDropWeapons);
					EnableHookChain(HookPlayer_PlayerKilled);
					
					EnableHamForward(g_iHamHookPudge);
					for(new i; i < charsmax(g_iHamHookUnlimAmmo); i++) EnableHamForward(g_iHamHookUnlimAmmo[i]);
					
					for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
					
					state dBlockCmd: Enabled;
					
					set_task_ex(1.0, "main_informer", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);
					
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i; i < iPlayerCount; i++)
					{
						jbe_set_user_model(iPlayers[i], "cso_model");
						set_entvar(iPlayers[i], var_body, 0);
						reset_players_values(iPlayers[i]);
					}
					jbe_mafia_start();
					jbe_set_friendlyfire(3);
					jbe_set_global(4);
				}
				case false:
				{
					DisableHookChain(HookPlayer_ResetMaxSpeed);
					DisableHookChain(HookPlayer_PlayerTakeDamage);
					DisableHookChain(HookPlayer_PlayerTraceAttack);
					DisableHookChain(HookPlayer_PlayerRespawn);
					DisableHookChain(HookPlayer_PlayerDropWeapons);
					DisableHookChain(HookPlayer_PlayerKilled);
					DisableHamForward(g_iHamHookPudge);
					
					
					for(new i; i < charsmax(g_iHamHookUnlimAmmo); i++) DisableHamForward(g_iHamHookUnlimAmmo[i]);
					
					for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
					
					jbe_mafia_end();
					state dBlockCmd: Disabled;
					
					g_iBitUserDamage = 0;
					g_iBitUserElectro = 0;
					g_iBitUserSpeed = 0;
					g_iBitUserGravity = 0;
					g_iBitDragonClawHook = 0;
					g_iBitUserGodMode = 0;
					
					new ent = -1;
					while((ent = rg_find_ent_by_class(ent, CLASSNAME_DRAGONCLAW)))
					if(is_entity(ent))
					{
						set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_KILLME);
						set_entvar(ent, var_nextthink, get_gametime());
					}
					
					if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
					
					
					static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_None);
					
					jbe_set_friendlyfire(0);
					jbe_set_global(0);
					
					for(new i; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						if(is_user_connected(Players))
						{
							
							if(IsSetBit(g_iBitUserBury, Players)) Bury_off(Players);
							if(IsSetBit(g_iBitUserDrugs, Players)) Player_ResetDrugs(Players);
							if(IsSetBit(g_iBitUserFrost, Players)) Player_ResetFrozen(Players);
							
							g_iUserBoss[Players] = false;
							g_iUserHeroes[Players] = false;
							
							
							
							
							if(g_iUserRoleBoss[Players]) reset_values(Players);
								
							g_iUserRoleBoss[Players] = 0;
							//g_iUserRoleHero[iPlayers[i]] = 0;
							
							if(jbe_get_user_team(Players) == 1)
							{
								reset_players_values(Players);
							}
							
							jbe_set_user_model_ex(Players, jbe_get_user_team(Players));
						}
					}
				}
			}
		
		}
		
		case 1: return Show_BossGiveRole(pId);
		case 2: return Show_HeroesGiveRole(pId);
		case 3: 
		{
			g_iStartBox = !g_iStartBox;
			if(g_iStartBox)
			{
				set_dhudmessage(255, 255, 255, -1.0, 0.67, 0, 6.0, 5.0);
				show_dhudmessage(pId, "Огонь по боссам включен!");
			}
		}
		case 4:
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount,  GetPlayers_MatchTeam, "TERRORIST");

			for(new i; i < iPlayerCount; i++)
			{
				if(!jbe_is_user_alive(iPlayers[i]))
				{
					rg_round_respawn(iPlayers[i]);
				}
			}
					
		}
		case 5:
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			for(new i; i < iPlayerCount; i++)
			{
				if(g_iUserHeroes[iPlayers[i]] && jbe_is_user_alive(iPlayers[i]))
				{
					iCount++;
				}
			}
			UTIL_SayText(0, "!g* Обноруженно %d героев, ХП боссов распределенно. !tHealtBoss = !gХПБосса + (10000 * %d)", iCount, iCount);
			HealtBoss = (10000.0 * iCount);
			
			if(!task_exists(TASK_BOSSHEALT)) set_task_ex(1.0,"GiveHealt", TASK_BOSSHEALT);
		}
		case 8: return jbe_global_games(pId, 0);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_Crusader(pId);
}

public GiveHealt()
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
	//HealtBoss = (HealtBoss * iCount);
	for(new i; i < iPlayerCount; i++)
	{
		if(g_iUserBoss[iPlayers[i]] && jbe_is_user_alive(iPlayers[i]))
		{
			if(g_iUserRoleBoss[iPlayers[i]] == 1)
			{
				set_entvar(iPlayers[i], var_health, (HEALTS_TECHIES + HealtBoss));
			}
			if(g_iUserRoleBoss[iPlayers[i]] == 2)
			{
				set_entvar(iPlayers[i], var_health, (HEALTS_FROST + HealtBoss));
			}
			if(g_iUserRoleBoss[iPlayers[i]] == 3)
			{
				set_entvar(iPlayers[i], var_health, (HEALTS_VIPER + HealtBoss));
			}
			if(g_iUserRoleBoss[iPlayers[i]] == 4)
			{
				set_entvar(iPlayers[i], var_health, (HEALTS_PUDGE + HealtBoss));
			}
		}
	}
	iCount = 0;
	HealtBoss = 0.0;
}


public none() return PLUGIN_CONTINUE;
public main_informer()
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
	
	for(new i; i < iPlayerCount; i++)
    {
		if(g_iUserBoss[iPlayers[i]])
		{
			set_hudmessage(0, 255, 255, -1.0, 0.05, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(iPlayers[i], g_iSyncCrusInformer, "Ваша роль - %L^nСпособность - ^n%L^nHP - %d",LANG_PLAYER, g_szBossRoleName[g_iUserRoleBoss[iPlayers[i]]] ,LANG_PLAYER , g_szBossSkillsName[g_iUserRoleBoss[iPlayers[i]]], get_user_health(iPlayers[i]));
		}
		else
		if(g_iUserHeroes[iPlayers[i]])
		{
			set_hudmessage(0, 255, 255, -1.0, 0.05, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(iPlayers[i], g_iSyncCrusInformer, "Ваша роль - %L^nСпособность - ^n%L^nHP - %d",LANG_PLAYER, g_szHeroesRoleName[g_iUserRoleHero[iPlayers[i]]] ,LANG_PLAYER , g_szHeroesSkillsName[g_iUserRoleHero[iPlayers[i]]], get_user_health(iPlayers[i]));
		}
		else
		{
			set_hudmessage(0, 255, 255, -1.0, 0.05, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(iPlayers[i], g_iSyncCrusInformer, "Ваша роль - Без роли");
		}
    }
}

Show_BossGiveRole(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("Выдачи роли Босса^n^n");
	
	FormatItem("\y1. \wЗабрать роли^n^n"), iKeys |= 1<<0;

	FormatItem("\y2. \wВыдать Минера^n"), iKeys |= 1<<1;
	FormatItem("\y3. \wВыдать Фроста^n"), iKeys |= 1<<2;
	FormatItem("\y4. \wВыдать Ядовитого плюща^n"), iKeys |= 1<<3;
	FormatItem("\y5. \wВыдать Мясника^n"), iKeys |= 1<<4;
	

	FormatItem("^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_BossGiveRole");
}

public Handle_BossGiveRole(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: return Show_GiveRoleBoss(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 0, "Забрать роль");
		case 1: return Show_GiveRoleBoss(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 1, "Минер");
		case 2: return Show_GiveRoleBoss(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 2, "Фрост");
		case 3: return Show_GiveRoleBoss(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 3, "Ядовитый плющ");
		case 4: return Show_GiveRoleBoss(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 4, "Мясник");

		case 8: return Show_Crusader(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_BossGiveRole(pId);
}

public Show_GiveRoleBoss(pId, iPos, iRole, title[32])
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum, g_iMenuTitle[32];

	copy(g_iMenuTitle, charsmax(g_iMenuTitle), title);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i) || g_iUserHeroes[i]) continue;
		g_iUserID[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g* !y%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_BossGiveRole(pId);
		}
		case 1: FormatMain("\yВыдачи роли - %s^n^n", g_iMenuTitle);
		default: FormatMain("\w%s \r[%d|%d]^n^n", g_iMenuTitle, iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[pId][a];
		if(g_iUserRoleBoss[i] == iRole) FormatItem("\y%d. \d%n^n", ++b, i);
		else
		{
			iKeys |= (1<<b);
			if(g_iUserRoleBoss[i] != 0) FormatItem("\y%d \w%n \r(%L)^n", ++b, i, pId, g_szBossRoleName[g_iUserRoleBoss[i]]);
			else FormatItem("\y%d \w%n^n", ++b, i);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iPos)
	{
		iKeys |= (1<<7);
		FormatItem("^n\y8. \w%L", pId, "JBE_MENU_BACK");
	} 
	else FormatItem("^n\y8. \d%L", pId, "JBE_MENU_BACK");

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", pId, "JBE_MENU_NEXT");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_GiveRoleBoss");
}

public Handle_GiveRoleBoss(pId, iKey)
{
	switch(iKey)
	{
		case 7: return Show_GiveRoleBoss(pId, --g_iMenuPosition[pId], g_iMenuType[pId], "Выдача ролей");
		case 8: return Show_GiveRoleBoss(pId, ++g_iMenuPosition[pId], g_iMenuType[pId], "Выдача ролей");
		case 9: return Show_BossGiveRole(pId);
		default:
		{
			new iTarget = g_iUserID[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(!jbe_is_user_alive(iTarget) && g_iUserRoleBoss[iTarget] == g_iMenuType[pId]) Show_GiveRoleBoss(pId, g_iMenuPosition[pId], g_iMenuType[pId], "Выдать роль");
			
			
			
			g_iUserRoleBoss[iTarget] = g_iMenuType[pId];
			reset_players_values(iTarget);
			
			g_iUserHeroes[iTarget] = false;
			g_iUserRoleHero[iTarget] = 0;
			
			if(g_iMenuType[pId])
			{
				g_iUserBoss[iTarget] = true;
				set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Игроку %n был назначен роль Босса - %L^n%L", iTarget, LANG_PLAYER, g_szBossRoleName[g_iUserRoleBoss[iTarget]], LANG_PLAYER, g_szBossSkillsName[g_iUserRoleBoss[iTarget]]);
			}else g_iUserBoss[iTarget] = false;
			
			give_role(iTarget, g_iMenuType[pId]);
		}
	}
	return Show_BossGiveRole(pId);
}

Show_HeroesGiveRole(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("Выдачи роли Героя^n^n");
	
	FormatItem("\y1. \wЗабрать роли^n^n"), iKeys |= 1<<0;

	FormatItem("\y2. \wВыдать Паладина^n"), iKeys |= 1<<1;
	FormatItem("\y3. \wВыдать Жрицу^n"), iKeys |= 1<<2;
	FormatItem("\y4. \wВыдать Палача^n"), iKeys |= 1<<3;
	FormatItem("\y5. \wВыдать Оружейника^n"), iKeys |= 1<<4;
	FormatItem("\y6. \wВыдать Баффера^n"), iKeys |= 1<<5;
	FormatItem("\y7. \wВыдать Электрошокера^n"), iKeys |= 1<<6;
	
	FormatItem("\y0. \wВыход^n");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_HeroesGiveRole");
}

public Handle_HeroesGiveRole(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 0, "Забрать роль");
		case 1: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 1, "Паладин");
		case 2: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 2, "Жрица");
		case 3: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 3, "Палач");
		case 4: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 4, "Оружейник");
		case 5: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 5, "Баффер");
		case 6: return Show_GiveRoleHeroes(pId, g_iMenuPosition[pId] = 0, g_iMenuType[pId] = 6, "Электрошокер");

		case 9: return PLUGIN_HANDLED;
	}
	return Show_BossGiveRole(pId);
}

public Show_GiveRoleHeroes(pId, iPos, iRole, title[32])
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum, g_iMenuTitle[32];

	copy(g_iMenuTitle, charsmax(g_iMenuTitle), title);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || g_iUserBoss[i]) continue;
		g_iUserID[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g* !y%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_HeroesGiveRole(pId);
		}
		case 1: FormatMain("\yВыдачи роли - %s^n^n", g_iMenuTitle);
		default: FormatMain("\w%s \r[%d|%d]^n^n", g_iMenuTitle, iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[pId][a];
		if(g_iUserRoleHero[i] == iRole) FormatItem("\y%d. \d%n^n", ++b, i);
		else
		{
			iKeys |= (1<<b);
			if(g_iUserRoleHero[i] != 0) FormatItem("\y%d \w%n \r(%L)^n", ++b, i, pId, g_szHeroesRoleName[g_iUserRoleHero[i]]);
			else FormatItem("\y%d \w%n^n", ++b, i);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iPos)
	{
		iKeys |= (1<<7);
		FormatItem("^n\y8. \w%L", pId, "JBE_MENU_BACK");
	} 
	else FormatItem("^n\y8. \d%L", pId, "JBE_MENU_BACK");

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", pId, "JBE_MENU_NEXT");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_GiveRoleHeroes");
}

public Handle_GiveRoleHeroes(pId, iKey)
{
	switch(iKey)
	{
		case 7: return Show_GiveRoleHeroes(pId, --g_iMenuPosition[pId], g_iMenuType[pId], "Выдача ролей");
		case 8: return Show_GiveRoleHeroes(pId, ++g_iMenuPosition[pId], g_iMenuType[pId], "Выдача ролей");
		case 9: return Show_HeroesGiveRole(pId);
		default:
		{
			new iTarget = g_iUserID[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(!jbe_is_user_alive(iTarget) && g_iUserRoleBoss[iTarget] == g_iMenuType[pId]) Show_GiveRoleHeroes(pId, g_iMenuPosition[pId], g_iMenuType[pId], "Выдать роль");
			
			
			reset_players_values(iTarget);
			g_iUserRoleHero[iTarget] = g_iMenuType[pId];
			
			g_iUserBoss[iTarget] = false;
			g_iUserRoleBoss[iTarget] = 0;
			
			if(g_iMenuType[pId] != 0)
			{
				g_iUserHeroes[iTarget] = true;
				set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Игроку %n был назначен роль Героя - %L^n%L", iTarget, LANG_PLAYER, g_szHeroesRoleName[g_iUserRoleHero[iTarget]], LANG_PLAYER, g_szHeroesSkillsName[g_iUserRoleHero[iTarget]]);
			}
			else g_iUserHeroes[iTarget] = false;
			
			give_role(iTarget, g_iMenuType[pId]);
		}
	}
	return Show_HeroesGiveRole(pId);
}

reset_players_values(pId)
{
	jbe_hide_user_costumes(pId);
	set_entvar(pId, var_health, 100.0);
	set_entvar(pId, var_gravity, 1.0);
	rg_set_user_footsteps(pId, false);
	rg_remove_all_items(pId);
	rg_reset_maxspeed(pId);
	rg_give_item(pId, "weapon_knife", GT_APPEND);
	
	if(g_iUserRoleBoss[pId] == 1)
	{
		rg_remove_all_items(pId);
		rg_give_item_ex(pId, "weapon_hegrenade", GT_REPLACE, 9999);
	}
	
	jbe_set_user_rendering(pId, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}

stock give_role(iTarget, iType)
{
	if(g_iUserBoss[iTarget])
	{
		switch(iType)
		{
			case 1:
			{
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 4);
				
				set_entvar(iTarget, var_maxspeed, SPEED_MINER_RESET);
				//set_entvar(iTarget, var_health, HEALTS_TECHIES);
				
				jbe_set_user_rendering(iTarget, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
			}
			case 2:
			{
				//set_entvar(iTarget, var_health, HEALTS_FROST);
				rg_give_item_ex(iTarget, "weapon_m249", GT_REPLACE, BULLET_GUN);
				jbe_set_user_rendering(iTarget, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 5);
			}
			case 3:
			{
				jbe_set_user_rendering(iTarget, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
				//set_entvar(iTarget, var_health, HEALTS_VIPER);
				rg_give_item_ex(iTarget, "weapon_g3sg1", GT_REPLACE, BULLET_GUN);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 6);
			}
			case 4:
			{
				jbe_set_user_rendering(iTarget, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
				//set_entvar(iTarget, var_health, HEALTS_PUDGE);
				set_entvar(iTarget, var_maxspeed, SPEED_PUDGE);

				Hook_WeaponGive(iTarget);
				
				give_weapon_hook(iTarget);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 7);
			}
		}
		return PLUGIN_HANDLED;
	}
	else
	if(g_iUserHeroes[iTarget])
	{
		switch(iType)
		{

			case 1:
			{
				rg_give_item_ex(iTarget, "weapon_m249", GT_REPLACE, BULLET_GUN);
						
				set_entvar(iTarget, var_health, HEALTS_PALADINS);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 1);
			}
			case 2:
			{
				set_entvar(iTarget, var_health, HEALTS_DEVA);

				set_entvar(iTarget, var_maxspeed, SPEED_DEVA);
				rg_give_item_ex(iTarget, "weapon_mp5navy", GT_REPLACE, BULLET_GUN);
				
				jbe_set_user_model(iTarget, "jail_g1rlds_guard");
				set_entvar(iTarget, var_body, 5);
			}
			case 3:
			{
				rg_give_item_ex(iTarget, "weapon_ak47", GT_REPLACE, BULLET_GUN);
				set_entvar(iTarget, var_health, HEALTS_PALACH);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 3);
			}
			case 4:
			{
				set_entvar(iTarget, var_health, HEALTS_GUNMAN);
						
				rg_give_item_ex(iTarget, "weapon_ak47", GT_APPEND, BULLET_GUN);
				rg_give_item_ex(iTarget, "weapon_m4a1", GT_APPEND, BULLET_GUN);
				rg_give_item_ex(iTarget, "weapon_m249", GT_APPEND, BULLET_GUN);
				rg_give_item_ex(iTarget, "weapon_awp", GT_APPEND, BULLET_GUN);
				rg_give_item_ex(iTarget, "weapon_deagle", GT_APPEND, BULLET_GUN);
				rg_give_item_ex(iTarget, "weapon_aug", GT_APPEND, BULLET_GUN);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 1);
			}
			case 5:
			{
				set_entvar(iTarget, var_health, HEALTS_BAFFER);
				rg_give_item_ex(iTarget, "weapon_sg550", GT_APPEND, BULLET_GUN);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 2);
			}
			case 6:
			{
				rg_give_item_ex(iTarget, "weapon_mp5navy", GT_APPEND, BULLET_GUN);
				set_entvar(iTarget, var_health, HEALTS_ELECTROMAN);
				
				jbe_set_user_model(iTarget, "cso_model");
				set_entvar(iTarget, var_body, 3);
			}
		}
		return PLUGIN_HANDLED;
	}
	jbe_set_user_model(iTarget, "cso_model");
	set_entvar(iTarget, var_body, 0);
	
	reset_players_values(iTarget);
	if(IsSetBit(g_iBitDragonClawHook, iTarget)) ClearBit(g_iBitDragonClawHook, iTarget);
	jbe_set_user_rendering(iTarget, kRenderFxGlowShell,0,0,0,kRenderNormal,25);
	
	set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.1, 0.2, 0.2, -1);
	ShowSyncHudMsg(0, g_iSyncSkillsInformer, "Игроку %n забрали роли", iTarget);
	return PLUGIN_HANDLED;
}

stock give_weapon_hook(pId)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szHookModels[0])))
		set_pev_string(pId, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szHookModels[1])))
		set_pev_string(pId, pev_weaponmodel2, iszWeaponModel);
}

public HC_CBasePlayer_ResetMaxSpeed(pId)
{
	if(g_iUserBoss[pId])
	{
		if(g_iUserRoleBoss[pId] == 1)
		{
			if(task_exists(pId + TASK_SHOW_SKILLS))
			{
				set_entvar(pId, var_maxspeed, SPEED_MINER);
			}
			else set_entvar(pId, var_maxspeed, SPEED_MINER_RESET);
		}
		else if(g_iUserRoleBoss[pId] == 4)
			set_entvar(pId, var_maxspeed, SPEED_PUDGE);
	}
	else
	if(g_iUserHeroes[pId])
	{
		if(g_iUserRoleHero[pId] == 6)
		{
			if(IsSetBit(g_iBitUserElectro, pId))
			{
				set_entvar(pId, var_maxspeed, SPEED_ELECTROMAN);
			}
		}
	}
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		new Float:fDamageOld = fDamage;
		if(jbe_get_user_team(iAttacker) == 1)
		{
			if(jbe_get_user_team(iVictim) == 2)
			{
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE; 
			}
			if(!g_iStartBox)
			{
				if(jbe_is_user_valid(iVictim) && jbe_get_user_team(iVictim) == jbe_get_user_team(iAttacker))
				{
					SetHookChainArg(3, ATYPE_FLOAT, 0.0);
					return HC_SUPERCEDE;
				}
			}
			/*if(!g_iUserBoss[iAttacker] || !g_iUserHeroes[iAttacker])
			{
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE; 
			}*/
			if(g_iUserHeroes[iAttacker])
			{
				if(g_iUserRoleHero[iAttacker] == 6 || g_iUserRoleHero[iAttacker] == 3)
				{
					if(g_iUserRoleHero[iAttacker] == 6 && get_user_weapon(iAttacker) == CSW_MP5NAVY && IsSetBit(g_iBitUserElectro, iAttacker))
					{
						UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
						fDamage = ((fDamage * 2) + (fDamage / 2));
					}
					if(g_iUserRoleHero[iAttacker] == 3 && get_user_weapon(iAttacker) == CSW_AK47 && IsSetBit(g_iBitUserDamage, iAttacker))
					{
						fDamage = (fDamage * 3);
					}
				}
			}
			if(g_iUserBoss[iAttacker])
			{
				if(g_iUserRoleBoss[iAttacker] == 4 && get_user_weapon(iAttacker) == CSW_KNIFE)
				{
					fDamage = 999999.0;
					new iOwner;
					iOwner = get_entvar(g_iHookEntity, var_owner);
					UTIL_KillBeamPoint(iOwner);
				}
				if(g_iUserRoleBoss[iAttacker] == 1 && get_user_weapon(iAttacker) == CSW_KNIFE)
				{
					fDamage = (fDamage * 2.5);
				}
			}
			if(g_iUserBoss[iVictim] == g_iUserBoss[iAttacker])
			{
				SetHookChainArg(3, ATYPE_FLOAT, 0.0);
				return HC_SUPERCEDE;
			}
			if(g_iUserHeroes[iVictim] == g_iUserHeroes[iAttacker])
			{
				SetHookChainArg(3, ATYPE_FLOAT, 0.0);
				return HC_SUPERCEDE;
			}
			if(jbe_get_user_team(iVictim) == 2 && jbe_get_user_team(iAttacker) == jbe_get_user_team(iVictim))
			{
				SetHookChainArg(3, ATYPE_FLOAT, 0.0);
				return HC_SUPERCEDE;
			}
			if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
		}
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(is_user_alive(pId))
	{
		set_task_ex(1.0, "player_set_spawnsfix", pId + 34565477);
	}
}

public player_set_spawnsfix(pId)
{
	pId -= 34565477;
	if(!is_user_alive(pId)) return;
	
	reset_players_values(pId);
	if(g_iUserBoss[pId]) give_role(pId, g_iUserRoleBoss[pId]);
	else if(g_iUserHeroes[pId]) give_role(pId, g_iUserRoleHero[pId]);
}
public HC_CBasePlayer_TakeDamage_Player(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		
		if(iBitDamage & (1<<24)) // DMG_HEGRENADE
		{
			if(!g_iStartBox)
			{
				if(jbe_is_user_valid(iVictim) && jbe_get_user_team(iVictim) == jbe_get_user_team(iAttacker))
				{
					SetHookChainReturn(ATYPE_INTEGER, false);
					return HC_SUPERCEDE; 
				}
			}
			if(jbe_is_user_valid(iVictim) && g_iUserBoss[iVictim] == g_iUserBoss[iAttacker])
			{
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE; 
			}
			if(jbe_is_user_valid(iVictim) && g_iUserHeroes[iVictim] == g_iUserHeroes[iAttacker])
			{
				SetHookChainReturn(ATYPE_INTEGER, false);
				return HC_SUPERCEDE; 
			}
		}
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	ClearBit(g_iBitUserDamage, iVictim);
	ClearBit(g_iBitUserElectro, iVictim);
	ClearBit(g_iBitUserSpeed, iVictim);
	ClearBit(g_iBitUserGravity, iVictim);
	ClearBit(g_iBitUserGodMode, iVictim);
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}



public HamHook_EntityBlock(iEntity, pId)
{
	if(jbe_get_user_team(pId) == 1 && jbe_is_user_valid(pId) && jbe_is_user_alive(pId)) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}




Player_SetFrozen(pId)
{
	SetBit(g_iBitUserFrost, pId);
	
	Player_SetNextAttack(pId, 99999.0);
	
	emit_sound(pId, CHAN_VOICE, SOUND_PLAYER_FROST, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_entvar(pId, var_renderfx, kRenderFxGlowShell);
	set_entvar(pId, var_rendercolor, {0.0, 100.0, 200.0});
	set_entvar(pId, var_rendermode, kRenderNormal);
	set_entvar(pId, var_renderamt, 18.0);
	
	if(!jbe_is_user_valid(pId)) return;
	
	new Float:vecOrigin[3];
	get_entvar(pId, var_origin, vecOrigin);
	
	set_entvar(pId, var_flags, get_entvar(pId, var_flags) | FL_FROZEN);
	set_entvar(pId, var_origin, vecOrigin);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] Player_SetFrozen");
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
	ClearBit(g_iBitUserFrost, pId);
	
	Player_SetNextAttack(pId, 0.0);
	
	emit_sound(pId, CHAN_VOICE, SOUND_PLAYER_DEFROST, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_entvar(pId, var_flags, get_entvar(pId, var_flags) & ~FL_FROZEN);
	
	new vecOrigin[3];
	get_user_origin(pId, vecOrigin);
	
	if(!jbe_is_user_valid(pId)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] Player_ResetFrozen");
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

//PUDGE
public DragonClaw_HookedPlayer(pPlayer)
{
	pPlayer -= TASK_PLAYER_HOOKED;

	if(!task_exists(pPlayer+TASK_PLAYER_HOOKED))
		return;



	new Float: vecOrigin[3], Float: vecVictimOrigin[3], Float: vecVelocity[3];
	get_entvar(g_pPlayerId[pPlayer], var_origin, vecOrigin);
	get_entvar(pPlayer, var_origin, vecVictimOrigin);

	new Float: iDistance = get_distance_f(vecOrigin, vecVictimOrigin);

	if(iDistance > 1.0)
	{
		new Float: flTime = iDistance / HOOK_SPEED;

		vecVelocity[0] = (vecOrigin[0] - vecVictimOrigin[0]) / flTime;
		vecVelocity[1] = (vecOrigin[1] - vecVictimOrigin[1]) / flTime;
		vecVelocity[2] = (vecOrigin[2] - vecVictimOrigin[2]) / flTime;
	} 
	else 
	{
		vecVelocity[0] = 0.0;
		vecVelocity[1] = 0.0;
		vecVelocity[2] = 0.0;
	}

	set_entvar(pPlayer, var_velocity, vecVelocity);
}

public DragonClaw_HookedOff(pPlayer)
{
	pPlayer -= TASK_PLAYER_HOOKED;
	if(task_exists(pPlayer+TASK_PLAYER_HOOKED))
	{
		remove_task(pPlayer+TASK_PLAYER_HOOKED);
		UTIL_KillBeamPoint(pPlayer);
	}
}

public Create_HookEntity(iPlayer)
{
	static iReference;

	if(iReference || (iReference = engfunc(EngFunc_AllocString, "info_target")))
	{
		g_iHookEntity = engfunc(EngFunc_CreateNamedEntity, iReference);
		
		if(!is_entity(g_iHookEntity)) return;

		new Float: vecOrigin[3], Float: vecVelocity[3], Float: vecAngle[3];
		get_entvar(iPlayer, var_origin, vecOrigin);
		get_entvar(iPlayer, var_v_angle, vecAngle);

		set_entvar(g_iHookEntity, var_classname, CLASSNAME_DRAGONCLAW);
		set_entvar(g_iHookEntity, var_movetype, MOVETYPE_FLY);
		set_entvar(g_iHookEntity, var_solid, SOLID_BBOX);
		set_entvar(g_iHookEntity, var_owner, iPlayer);

		velocity_by_aim(iPlayer, floatround(HOOK_FLY_SPEED), vecVelocity); vecVelocity[2] += 25.0;
		set_entvar(g_iHookEntity, var_velocity, vecVelocity);
		set_entvar(g_iHookEntity, var_angles, vecAngle);

		engfunc(EngFunc_SetModel, g_iHookEntity, g_szHookModels[2]);
		engfunc(EngFunc_SetOrigin, g_iHookEntity, vecOrigin);

		CREATE_BEAMENTS(iPlayer, g_iHookEntity, g_iszBeamFollowLine, 0, 0, 120, 25, 0, 244, 244, 255, 120, 10);
	}
}

public Hook_WeaponGive(iPlayer)
{
	if(IsSetBit(g_iBitDragonClawHook, iPlayer))
		return;

	new iEntity = get_pdata_cbase(iPlayer, 373, 5);

	if(!is_entity(iEntity))
		return;

	SetBit(g_iBitDragonClawHook, iPlayer);
	g_flTimeReload[iPlayer] = 0.0;

}

public HamHook_EntityTouch_Post(iEntity, pPlayer)
{
	if(!is_entity(g_iHookEntity))
		return;

	new szClassName[64], iOwner, Float: vecOrigin[3];
	get_entvar(g_iHookEntity, var_origin, vecOrigin);
	get_entvar(g_iHookEntity, var_classname, szClassName, charsmax(szClassName));
	iOwner = get_entvar(g_iHookEntity, var_owner);
	//static Float: flGameTime; flGameTime = get_gametime();

	UTIL_KillBeamPoint(g_iHookEntity);

	if(equal(szClassName, CLASSNAME_DRAGONCLAW))
	{
		if(get_user_weapon(iOwner) == CSW_KNIFE)
		{
			static iWeapon; iWeapon = get_pdata_cbase(iOwner, 373, 5);
			set_pdata_float(iWeapon, 46, 0.9, 4);
			set_pdata_float(iWeapon, 47, 0.9, 4);
			set_pdata_float(iWeapon, 48, 0.9, 4);
			UTIL_WeaponAnimation(iOwner, 3);
		}
		
		if(is_user_alive(pPlayer))
		{
			if(task_exists(pPlayer+TASK_PLAYER_HOOKED))
			{
				CenterMsgFix_PrintMsg(iOwner, print_center, "Этот игрок уже хукнут!");
				UTIL_KillEntity(g_iHookEntity);
				UTIL_KillBeamPoint(iOwner);
				return;
			}

			g_pPlayerId[pPlayer] = iOwner;

			//emit_sound(iOwner, CHAN_AUTO, g_szHookSounds[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_task_ex(0.1, "DragonClaw_HookedPlayer", pPlayer+TASK_PLAYER_HOOKED, .flags = SetTask_Repeat);
			set_task_ex(TIME_HOOK_PLAYER, "DragonClaw_HookedOff", pPlayer+TASK_PLAYER_HOOKED);
			CREATE_BEAMENTS(iOwner, pPlayer, g_iszBeamPointLine, 0, 0, 120, 6, 0, 155, 155, 55, 90, 10);

			CenterMsgFix_PrintMsg(iOwner, print_center, "Хук удался!");
		}
		else
		{
			//emit_sound(iOwner, CHAN_AUTO, g_szHookSounds[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			CenterMsgFix_PrintMsg(iOwner, print_center, "Хук не удался!");
			UTIL_KillEntity(g_iHookEntity);
			UTIL_KillBeamPoint(iOwner);
			CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_iModelIndex_RockGibs, 10, 25, 0);
		}
		//emit_sound(iOwner, CHAN_AUTO, g_szHookSounds[4], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
		set_entvar(g_iHookEntity, var_flags, FL_KILLME);
	}
}

/////////////////////////////////


stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

stock Effects_one(pId)
{
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] Effects_one");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, pId);
	write_short(1<<12);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(75);
	write_byte(0);
	write_byte(255);
	write_byte(75);
	message_end();
}

public Bury(pId)
{
    if(is_entity(pId) && is_user_connected(pId))
	{
		new Float:vecOrigin[3]; 
		get_entvar(pId, var_origin, vecOrigin);
		vecOrigin[2] -= 30;
		set_entvar(pId, var_origin, vecOrigin);
		grab_eff_zd(pId);
		SetBit(g_iBitUserBury, pId);
    }
}

public Bury_off(pId)
{
    if(is_entity(pId) && is_user_connected(pId))
	{
		new Float:vecOrigin[3]; 
		get_entvar(pId, var_origin, vecOrigin);
		vecOrigin[2] += 30;
		set_entvar(pId, var_origin, vecOrigin);
		ClearBit(g_iBitUserBury, pId);
    }
}

public grab_eff_zd(id)
{
    new origin[3];
    get_user_origin(id, origin, 3);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] grab_eff_zd");
	}

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
    write_byte(TE_BREAKMODEL); // TE_
    write_coord(origin[0]); // X
    write_coord(origin[1]); // Y
    write_coord(origin[2] + 24); // Z
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

Player_SetSpeed(pId)
{
	SetBit(g_iBitUserSpeed, pId);
	new g_iSpeed = get_entvar(pId, var_maxspeed);
	set_entvar(pId, var_maxspeed, g_iSpeed + SPEED_BAFFER);
}

Player_ResetSpeed(pId)
{
	ClearBit(g_iBitUserSpeed, pId);
	
	if(g_iUserRoleHero[pId] == 2)
	{
		set_entvar(pId, var_maxspeed, SPEED_DEVA);
	}
	else if(IsNotSetBit(g_iBitUserSpeed, pId)) rg_reset_maxspeed(pId);
}

Player_SetGravity(pId)
{
	SetBit(g_iBitUserGravity, pId);
	set_entvar(pId, var_gravity, 0.5);
}

Player_ResetGravity(pId)
{
	ClearBit(g_iBitUserGravity, pId);
	set_entvar(pId, var_gravity, 1.0);
}

Player_SetDrugs(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] Player_SetDrugs");
	}
	
	SetBit(g_iBitUserDrugs, pId);
	message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, pId);
	write_byte(170);
	message_end();
}

Player_ResetDrugs(pId)
{
	if(!jbe_is_user_valid(pId)) return;
	ClearBit(g_iBitUserDrugs, pId);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] Player_ResetDrugs");
	}
	message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, pId);
	write_byte(0);
	message_end();
}

#define m_flNextAttack  83

Player_SetNextAttack(pId, Float:flBlockTime)
{
	set_member(pId, m_flNextAttack, flBlockTime);
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock CREATE_BEAMENTS(pPlayer, pVictim, pSprite, SFrame, EFrame, iLife, iWidth, iNoise, iRed, iGreen, iBlue, iBrightness, iSpeed)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] CREATE_BEAMENTS");
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS);    // TE_BEAMENTS
	write_short(pPlayer);
	write_short(pVictim);
	write_short(pSprite);    // sprite index
	write_byte(SFrame) ;   // start frame
	write_byte(EFrame);    // framerate
	write_byte(iLife);    // life
	write_byte(iWidth);    // width
	write_byte(iNoise);    // noise
	write_byte(iRed) ;   // r, g, b
	write_byte(iGreen);    // r, g, b
	write_byte(iBlue);    // r, g, b
	write_byte(iBrightness) ;   // brightness
	write_byte(iSpeed);    // speed
	message_end();
}

stock bool: fm_is_aiming_at_sky(pPlayer)
{
    new Float: vecOrigin[3];
    fm_get_aiming_position(pPlayer, vecOrigin);
    return engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY;
}

stock UTIL_KillBeamPoint(pPlayer)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[KRESTOVYU] UTIL_KillBeamPoint");
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(pPlayer);
	message_end();
}

stock UTIL_KillEntity(iEntity)
{
	if(!is_entity(iEntity)) return;
	//emit_sound(pPlayer, CHAN_AUTO, g_szHookSounds[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	//emit_sound(pPlayer, CHAN_AUTO, g_szHookSounds[4], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	set_entvar(iEntity, var_flags, FL_KILLME);
}

stock CREATE_BREAKMODEL(Float:vecOrigin[3], Float:vecSize[3] = {16.0, 16.0, 16.0}, Float:vecVelocity[3] = {25.0, 25.0, 25.0}, iRandomVelocity, pModel, iCount, iLife, iFlags)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 24);
	engfunc(EngFunc_WriteCoord, vecSize[0]);
	engfunc(EngFunc_WriteCoord, vecSize[1]);
	engfunc(EngFunc_WriteCoord, vecSize[2]);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(pModel);
	write_byte(iCount); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iFlags); // BREAK_GLASS 0x01, BREAK_METAL 0x02, BREAK_FLESH 0x04, BREAK_WOOD 0x08
	message_end();
}

stock fm_get_aiming_position(pPlayer, Float:vecReturn[3])
{
	new Float:vecOrigin[3], Float:vecViewOfs[3], Float:vecAngle[3], Float:vecForward[3];
	get_entvar(pPlayer, var_origin, vecOrigin);
	get_entvar(pPlayer, var_view_ofs, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	get_entvar(pPlayer, var_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, 8192.0, vecForward);
	xs_vec_add(vecOrigin, vecForward, vecForward);
	engfunc(EngFunc_TraceLine, vecOrigin, vecForward, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecReturn);
}

stock xs_vec_add(const Float:vec1[], const Float:vec2[], Float:out[])
{
	out[0] = vec1[0] + vec2[0];
	out[1] = vec1[1] + vec2[1];
	out[2] = vec1[2] + vec2[2];
}

stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}

public reset_values(iPlayer)
{
	if(IsNotSetBit(g_iBitDragonClawHook, iPlayer))
		return;	

	new iEntity = get_pdata_cbase(iPlayer, 373, 5);

	if(!is_entity(iEntity))
		return;

	ClearBit(g_iBitDragonClawHook, iPlayer);
	g_flTimeReload[iPlayer] = 0.0;

	if(is_entity(g_iHookEntity))
	{
		new iOwner; iOwner = get_entvar(g_iHookEntity, var_owner);
		UTIL_KillEntity(g_iHookEntity);
		UTIL_KillBeamPoint(iOwner);
	}

}

public HamHook_PrimaryAttack_Post(iEnt)
{
	static pId; pId = Player_GetId(iEnt);
	
	if(!IsUnlimAmmo(pId)) return;
	
	static iWeaponId; 	iWeaponId = Weapon_GetId(iEnt);
	static iMaxClip; 	iMaxClip = 	Weapon_GetMaxClipAmmount(iWeaponId);
	
	if(Weapon_GetClip(iEnt) != iMaxClip)
	{
		Weapon_SetClip(iEnt, iMaxClip);
	}
}

public CSGameRules_DeadPlayerWeapons(const index)
{
    SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);
    return HC_SUPERCEDE;
}

Player_GetId(iEnt)
{
	return IsValidPev(iEnt) ? get_member(iEnt, m_pPlayer) : 0;
}
Weapon_GetId(iEnt)
{
	return IsValidPev(iEnt) ? get_member(iEnt, m_iId) : 0;
}

Weapon_SetClip(iEnt, iAmmo)
{
	if(!IsValidPev(iEnt)) return;
	
	set_member(iEnt, m_Weapon_iClip, iAmmo);
}

Weapon_GetClip(iEnt)
{
	return !IsValidPev(iEnt) ? 0 : get_member(iEnt, m_Weapon_iClip);
}

Weapon_GetMaxClipAmmount(iWeaponId)
{
	switch(iWeaponId)
	{
		case CSW_P228: 			return 13;
		case CSW_SCOUT: 		return 10;
		case CSW_HEGRENADE: 	return 0;
		case CSW_XM1014: 		return 7;
		case CSW_C4: 			return 0;
		case CSW_MAC10: 		return 30;
		case CSW_AUG: 			return 30;
		case CSW_SMOKEGRENADE:	return 0;
		case CSW_ELITE: 		return 30;
		case CSW_FIVESEVEN: 	return 20;
		case CSW_UMP45: 		return 25;
		case CSW_SG550: 		return 30;
		case CSW_GALI: 			return 35;
		case CSW_FAMAS: 		return 25;
		case CSW_USP: 			return 12;
		case CSW_GLOCK18: 		return 20;
		case CSW_AWP: 			return 10;
		case CSW_MP5NAVY: 		return 30;
		case CSW_M249: 			return 100;
		case CSW_M3: 			return 8;
		case CSW_M4A1: 			return 30;
		case CSW_TMP: 			return 30;
		case CSW_G3SG1: 		return 20;
		case CSW_FLASHBANG: 	return 0;
		case CSW_DEAGLE: 		return 7;
		case CSW_SG552: 		return 30;
		case CSW_AK47: 			return 30;
		case CSW_P90: 			return 50;
	}
	return 0;
}

