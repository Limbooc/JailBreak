#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>
#include <hamsandwich>
#include <reapi>
new g_iGlobalDebug;
#include <util_saytext>

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define MUSIC "sound/jb_engine/frallion_djihad_music.mp3"
#define BULLET_GUN 10000


#define PLUGIN 				"[JBE] Global Djihad Game"
#define VERSION 					"DalgaPups"
#define AUTHOR 		"Version 0.9"

#define TASK_PLAYER_SHAKE 					255167267
#define TASK_PLAYER_BURN 					3737333514
#define TASK_SHOW_ROLE_DJIHAD 				673772276
#define TASK_TIME_DJIHAD_START 				363595959
#define TASK_PLAYER_REGENERATION 			658766458
#pragma semicolon 1
#define PLAYERS_PER_PAGE 8
#define vec_copy(%1,%2)        ( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

#define IsShake(%1) g_iShake[%1]
#define IsBurn(%1) g_iUserRolePlayDjihadBurn[%1]

#define Player_SetHealth(%1,%2) set_entvar(%1, var_health, float(%2))
#define Player_GetHealth(%1) get_entvar(%1, var_health)

#define is_user_valid(%0) (%0 && %0 <= MaxClients)
#define MsgId_ScreenFade 98

const MsgId_ScreenShake = 97;
const MsgId_SetFOV = 95;
const MsgId_Demage = 71;


native jbe_set_friendlyfire(iType);
native jbe_get_friendlyfire();
native jbe_hide_user_costumes(pId);
native jbe_set_user_model_ex(iTarget, iType);
native jbe_set_formatex_daymode(iType);
native jbe_global_games(pId, iType);
/** pId */
#define Player_SetGodMode(%1) set_entvar(%1, var_takedamage, DAMAGE_NO)

/** pId */
#define Player_ResetGodMode(%1) set_entvar(%1, var_takedamage, DAMAGE_YES)

#define rg_set_weapon_ammo(%0,%1) set_member(%0, m_Weapon_iClip, %1)

new const g_szDjihadRolePlayName[][] =
{
	"Нет роли", 		// 0
	"Кэмпер", 			// 1
	"Джабба", 			// 2
	"Марсианин", 		// 3
	"Флэш", 			// 4
	"Шпион", 			// 5
	"Контрабандист", 	// 6
	"Омоновец", 		// 7
	"Альтаир", 			// 8
	"Фея", 				// 9
	"Копатель", 		// 10
	"Хохол", 			// 11
	"Шахид" 			// 12
};

new Float:g_iUserSpeed[MAX_PLAYERS + 1], 
	g_iUserRolePlayDjihad[MAX_PLAYERS + 1], 
	g_iDjihadMenuType[MAX_PLAYERS + 1], 
	g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iMenuPlayers[MAX_PLAYERS + 1][MAX_NAME_LENGTH], 
	g_iStatusDjihad, 
	g_iSyncHudDjihadStatus, 
	g_iDjihadFootsteps[MAX_PLAYERS + 1],
	bool:g_iShake[MAX_PLAYERS + 1],  
	g_iUnAmmo[MAX_PLAYERS + 1], 
	g_iDrugs[MAX_PLAYERS + 1], 
	g_iUserRolePlayDjihadBury[MAX_PLAYERS + 1], 
	bool:g_iUserRolePlayDjihadBurn[MAX_PLAYERS + 1], 
	g_iModelDirt, 
	g_iSpriteFlash, 
	g_iSpriteSmoke,
	g_iSyncStatusTextDjihad, 
	g_iTimerDjihadStart, 
	g_iStatusMusicDjihad;
	

	
new HookChain:g_iHookChain_ResetMaxSpeed,
	HookChain:g_iHookChain_Spawn,
	HookChain:g_iHookChain_Killed;
	
new HamHook:g_iHamHookTrigger[2];
	
const MsgId_RadarMsg = 112;

new HamHook:g_iHamHookForwards[14];
/* -> Массивы для работы с событиями 'hamsandwich' -> */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"func_button", // Кнопка
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield", // Щит
	"trigger_push",
	"trigger_teleport"
	
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	
	RegisterMenu("Show_MainDjihadMenu", "Handle_MainDjihadMenu");
	RegisterMenu("Show_DjihadStartMenu", "Handle_DjihadStartMenu");
	
	RegisterMenu("Show_DjihadRolePlayMenu_1",  "Handle_DjihadRolePlayMenu_1");
	RegisterMenu("Show_DjihadRolePlayMenu_2", "Handle_DjihadRolePlayMenu_2");
	RegisterMenu("Show_GiveRolePlayDjihadMenu", "Handle_GiveRolePlayDjihadMenu");
	RegisterMenu("Show_GiveRolePlayDjihadBury" , "Handle_GiveRolePlayDjihadBury");
	RegisterMenu("Show_GiveRolePlayDjihadBurn" , "Handle_GiveRolePlayDjihadBurn");
	
	#undef RegisterMenu
	
	DisableHookChain(g_iHookChain_ResetMaxSpeed =  	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed,  			"HC_CBasePlayer_PlayerResetMaxSpeed_Post", true));
	DisableHookChain(g_iHookChain_Spawn =  			RegisterHookChain(RG_CBasePlayer_Spawn, 					"HC_CBasePlayer_PlayerSpawn_Post", 		true));
	DisableHookChain(g_iHookChain_Killed =  		RegisterHookChain(RG_CBasePlayer_Killed, 					"HC_CBasePlayer_PlayerKilled_Post", 	true));
	//register_event("CurWeapon", "Event_CurWeapon", "be", "3=1");
	register_event("CurWeapon", "ChangeCurWeapon", "be", "1=1", "2!29");
	
	register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
	register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
	
	register_clcmd("djihad", "OpenMainDjihadGameMenu");
	
	g_iSyncHudDjihadStatus = CreateHudSyncObj();
	g_iSyncStatusTextDjihad = CreateHudSyncObj();
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	register_clcmd("drop", "ClCmd_Drop");
	
	register_message(MsgId_RadarMsg, "message_radar"); 
	
	for(new i; i <= 8; i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) 
	{
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	}
	
	DisableHamForward(g_iHamHookTrigger[0] = RegisterHam(Ham_Touch, "trigger_push", "HamHook_PushTriggers", false));
	DisableHamForward(g_iHamHookTrigger[1] = RegisterHam(Ham_Touch, "trigger_teleport", "HamHook_TeleportsTriggers", false));
	
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");

}

public HamHook_EntityBlock(iEntity, pId)
{
	if(jbe_is_user_valid(pId) && jbe_is_user_alive(pId) && jbe_get_user_team(pId) == 1) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

new bool:BufferPushTeleport[MAX_PLAYERS + 1];
//new Float:where[3];

public HamHook_PushTriggers(iEnt, id)
{
	if(!jbe_is_user_valid(id)) return HAM_IGNORED;
	
	if(!jbe_is_user_alive(id)) return HAM_IGNORED;


	if(!BufferPushTeleport[id] && !task_exists(id + 45748))
	{
		set_entvar(id, var_velocity, {0.0, 0.0, 0.0});
		set_task_ex(0.3, "returnpush", id + 45748);
		BufferPushTeleport[id] = true;
	}
	
	return HAM_IGNORED;
}

public returnpush(id)
{
	id -= 45748;

	set_entvar(id, var_velocity, {0.0, 0.0, 0.0});
	CenterMsgFix_PrintMsg(id, print_center, "Серфинг\Батут запрещен! Скорость сброшен!");

	BufferPushTeleport[id] = false;
}

public returnteleport(id)
{
	id -= 45749;
	CenterMsgFix_PrintMsg(id, print_center, "Телепорт запрещен!");

	BufferPushTeleport[id] = false;
}

public HamHook_TeleportsTriggers(iEnt, id)
{
	if(!jbe_is_user_valid(id)) return HAM_IGNORED;
	
	if(!jbe_is_user_alive(id)) return HAM_IGNORED;


	if(!BufferPushTeleport[id] && !task_exists(id + 45749))
	{
		set_task_ex(1.0, "returnteleport", id + 45749);
		BufferPushTeleport[id] = true;
	}
	return HAM_SUPERCEDE;
}

public ClCmd_Drop( pId ) <> { return PLUGIN_CONTINUE; }
public ClCmd_Drop( pId ) <dBlockCmd: Disabled> { return PLUGIN_CONTINUE; } 
public ClCmd_Drop( pId ) <dBlockCmd: Enabled> 
{
	if(jbe_get_user_team(pId) == 1)
		return PLUGIN_HANDLED; 
	return PLUGIN_CONTINUE;
} 

public plugin_precache()
{
	g_iModelDirt = engfunc(EngFunc_PrecacheModel, "models/rockgibs.mdl");
	
	g_iSpriteFlash = engfunc(EngFunc_PrecacheModel, "sprites/muzzleflash3.spr");
	g_iSpriteSmoke = engfunc(EngFunc_PrecacheModel, "sprites/smokepuff.spr");
	
	engfunc(EngFunc_PrecacheGeneric, MUSIC);
}

public OpenMainDjihadGameMenu(id) 
{
	if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2) && jbe_is_user_chief(id)) Show_MainDjihadMenu(id);
	else client_print(id, print_chat, "У вас не хватает прав.");
	return PLUGIN_HANDLED;
}

public message_radar()
{
	if(g_iStatusDjihad)
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public LogEvent_RoundEnd()
{
	if(g_iStatusDjihad)
	{
		DisableAllEvents();
		g_iStatusDjihad = false;
	}
}

public djihad_role_play_informer()
{

	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots);
	
	set_dhudmessage(255, 255, 255, -1.0, 0.0, 0, 0.1, 1.0, 0.1, 0.2); 
	
	for(new i; i < iPlayerCount; i++)
	{
		set_dhudmessage(255, 255, 255, -1.0, 0.0, 0, 0.1, 1.0, 0.1, 0.2); 
		if(jbe_get_user_team(iPlayers[i]) == 2)
		{
			show_dhudmessage(iPlayers[i], "БИТВА ЗА ДЖИХАД");
		}
		else show_dhudmessage(iPlayers[i], "БИТВА ЗА ДЖИХАД^n Роль: %s | ХП: %d", g_szDjihadRolePlayName[g_iUserRolePlayDjihad[iPlayers[i]]], floatround(get_entvar(iPlayers[i], var_health)));
	}
}

public Event_StatusValueShow(id)
{
	if(g_iStatusDjihad)
	{
		new iTarget = read_data(2);
		set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
		ShowSyncHudMsg(id, g_iSyncStatusTextDjihad, "Ник: %n^nРоль: %s", iTarget, g_szDjihadRolePlayName[g_iUserRolePlayDjihad[iTarget]]);
	}
}

public Event_StatusValueHide(id) ClearSyncHud(id, g_iSyncStatusTextDjihad);

Show_MainDjihadMenu(id)
{

	new szMenu[2024], iKeys = (1<<0|1<<8|1<<9), iLen;
	FormatMain("\yМеню Глобальной игры^nдля вызова: \rdjihad^n^n");
	
	FormatItem("\y1. \w%s Битву за Джихад^n^n", g_iStatusDjihad ? "Закончить" : "Начать");
	if(g_iStatusDjihad)
	{
		FormatItem("\y2. \wНазначить роли^n");
		FormatItem("\y3. \wУправление началом игры^n");
		FormatItem("\y4. \wУправление копателями^n");
		FormatItem("\y5. \wУправление шахидами^n");
		iKeys |= (1<<1|1<<2|1<<3|1<<4);
	}
	else
	{
		FormatItem("\y2. \dНазначить роли^n");
		FormatItem("\y3. \dУправлением началом игры^n");
		FormatItem("\y4. \dУправление копателями^n");
		FormatItem("\y5. \dУправление шахидами^n");
	}
	FormatItem("^n\y9. \wНазад");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_MainDjihadMenu");
}

public jbe_remove_user_chief_fwd(id, iType)
{
	if(!iType && g_iStatusDjihad)
	{
		g_iStatusDjihad = false;

		//set_user_godmode(id, 0);
		Player_ResetGodMode(id);
		
		
		DisableAllEvents();
	}
	
}

public client_disconnected(iPlayer)
{
	if(g_iStatusDjihad)
	{
		if(jbe_get_user_team(iPlayer) == 1)
		{	
			Player_ResetBurn(iPlayer);
			Player_ResetDrugs(iPlayer);
			Player_ResetShake(iPlayer);
			g_iUserRolePlayDjihad[iPlayer] = 0;
			g_iUserRolePlayDjihadBury[iPlayer] = false;
			g_iUserRolePlayDjihadBurn[iPlayer] = false;
			g_iUserSpeed[iPlayer] = 0.0;
			if(g_iDjihadMenuType[iPlayer] == 5) jbe_set_user_model_ex(iPlayer, 1);
			
			if(task_exists(iPlayer + TASK_PLAYER_REGENERATION)) remove_task(iPlayer + TASK_PLAYER_REGENERATION);
		}
	
	
	}

}


DisableAllEvents()
{
	DisableHookChain(g_iHookChain_ResetMaxSpeed);
	DisableHookChain(g_iHookChain_Spawn);
	DisableHookChain(g_iHookChain_Killed);
	
	DisableHamForward(g_iHamHookTrigger[0]);
	DisableHamForward(g_iHamHookTrigger[1]);
		
	jbe_set_friendlyfire(0);
	if(task_exists(TASK_SHOW_ROLE_DJIHAD)) remove_task(TASK_SHOW_ROLE_DJIHAD);
	
	client_cmd(0, "mp3 stop");
	
	state dBlockCmd: Disabled;
	
	jbe_set_friendlyfire(0);
	jbe_set_formatex_daymode(1);
	
	for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
	
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!jbe_is_user_connected(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;
		Player_ResetBurn(iPlayer);
		Player_ResetDrugs(iPlayer);
		Player_ResetShake(iPlayer);
		if(g_iUserRolePlayDjihad[iPlayer] == 5) jbe_set_user_model_ex(iPlayer, 1);
		g_iUserRolePlayDjihad[iPlayer] = 0;
		g_iUserRolePlayDjihadBury[iPlayer] = false;
		g_iUserRolePlayDjihadBurn[iPlayer] = false;
		
		g_iUserSpeed[iPlayer] = 0.0;

		rg_reset_maxspeed(iPlayer);
		g_iDjihadFootsteps[iPlayer] = false;
		g_iUnAmmo[iPlayer] = false;
		if(task_exists(iPlayer + TASK_PLAYER_REGENERATION)) remove_task(iPlayer + TASK_PLAYER_REGENERATION);
		if(task_exists(iPlayer + TASK_PLAYER_SHAKE)) remove_task(iPlayer + TASK_PLAYER_SHAKE);
	}

}


public HC_CBasePlayer_PlayerSpawn_Post(iPlayer)
{
	g_iUserRolePlayDjihad[iPlayer] = 0;
	g_iUserRolePlayDjihadBury[iPlayer] = false;
	g_iUserRolePlayDjihadBurn[iPlayer] = false;
	
	if(task_exists(iPlayer + TASK_PLAYER_REGENERATION)) remove_task(iPlayer + TASK_PLAYER_REGENERATION);
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{

	if(jbe_is_user_valid(iKiller) && jbe_is_user_valid(iVictim) && jbe_get_user_team(iKiller) == 1 && jbe_get_user_team(iVictim) == 1 && g_iUserRolePlayDjihad[iVictim])
	{
		UTIL_SayText(0, "!g* !yИгрок !t%n !g(%s) !yубил игрока !t%n !g(%s)", iKiller, g_szDjihadRolePlayName[g_iUserRolePlayDjihad[iKiller]], iVictim, g_szDjihadRolePlayName[g_iUserRolePlayDjihad[iVictim]]);
		
		HC_CBasePlayer_PlayerSpawn_Post(iVictim);
		
		
	}
	
	return HC_CONTINUE;
}
public Handle_MainDjihadMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(g_iStatusDjihad)
			{
				g_iStatusDjihad = false;
				set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 18.0, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncHudDjihadStatus, "%n Закончил Глобальную игру^n'Битва за Джихад'", id);
				//set_user_godmode(id, 0);
				Player_ResetGodMode(id);
				
				
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				{
					if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;
					
					if(g_iUserRolePlayDjihad[iPlayer] == 5) jbe_set_user_model_ex(iPlayer, 1);
					
					Player_ResetBurn(iPlayer);
					Player_ResetDrugs(iPlayer);
					Player_ResetShake(iPlayer);
					g_iUserRolePlayDjihad[iPlayer] = 0;
					g_iUserRolePlayDjihadBury[iPlayer] = false;
					g_iUserRolePlayDjihadBurn[iPlayer] = false;
					g_iUserSpeed[iPlayer] = 0.0;
					rg_remove_all_items(iPlayer);
					rg_give_item(iPlayer, "weapon_knife");
					
					
			
					if(task_exists(iPlayer + TASK_PLAYER_REGENERATION)) remove_task(iPlayer + TASK_PLAYER_REGENERATION);

				}
				
				
				DisableAllEvents();
			}
			else
			{
				g_iStatusDjihad = true;
				set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 18.0, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncHudDjihadStatus, "%n Начал Глобальную игру^n'Битва за Джихад'", id);
				Player_SetGodMode(id);
				
				set_task(1.0, "djihad_role_play_informer", TASK_SHOW_ROLE_DJIHAD, _, _, "b");
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				{
					if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;
					g_iUserRolePlayDjihad[iPlayer] = 0;
					g_iUserRolePlayDjihadBury[iPlayer] = false;
					g_iUserRolePlayDjihadBurn[iPlayer] = false;

				}
				EnableHookChain(g_iHookChain_ResetMaxSpeed);
				EnableHookChain(g_iHookChain_Spawn);
				EnableHookChain(g_iHookChain_Killed);
				
				jbe_set_formatex_daymode(7);
				for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
				state dBlockCmd: Enabled;
				
				EnableHamForward(g_iHamHookTrigger[0]);
				EnableHamForward(g_iHamHookTrigger[1]);
				
			}
		}
		case 1: return Show_DjihadRolePlayMenu_1(id);
		case 2: return Show_DjihadStartMenu(id);
		case 3: return Show_GiveRolePlayDjihadBury(id, g_iMenuPosition[id] = 0);
		case 4: return Show_GiveRolePlayDjihadBurn(id, g_iMenuPosition[id] = 0);
		case 8: return jbe_global_games(id, 0);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainDjihadMenu(id);
}

Show_DjihadStartMenu(id)
{

	new szMenu[2024], iKeys = (1<<0|1<<1|1<<2|1<<8|1<<9), iLen;
	FormatMain("\yУправление началом игры^n^n");
	
	FormatItem("\y1. \wЗапустить таймер^n^n");
	FormatItem("\y2. \w%s огонь по своим^n", jbe_get_friendlyfire() ? "Выключить" : "Включить");
	FormatItem("\y3. \w%s музыку^n", g_iStatusMusicDjihad ? "Выключить" : "Включить");
	
	FormatItem("^n\y9. \wНазад");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_DjihadStartMenu");
}

public Handle_DjihadStartMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(task_exists(TASK_TIME_DJIHAD_START)) 
				remove_task(TASK_TIME_DJIHAD_START);
			g_iTimerDjihadStart = 60;
			timer_djihad_start();
			set_task(1.0, "timer_djihad_start", TASK_TIME_DJIHAD_START, _, _, "a", g_iTimerDjihadStart);
		}
		case 1: 
		{
			if(!jbe_get_friendlyfire())
			{
				jbe_set_friendlyfire(1);
				UTIL_SendAudio(0, _, "jb_engine/bell.wav");
				
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				{
					if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1 || g_iUserRolePlayDjihad[iPlayer] != 2) continue;
					
					g_iUserSpeed[iPlayer] = 50.0;
					set_entvar(iPlayer, var_maxspeed, g_iUserSpeed[iPlayer]);
				}
			}
			else jbe_set_friendlyfire(0);
		}
		case 2:
		{
			if(g_iStatusMusicDjihad)
			{
				g_iStatusMusicDjihad = false;
				client_cmd(0, "mp3 stop");
			}
			else 
			{
				g_iStatusMusicDjihad = true;
				client_cmd(0, "mp3 play %s", MUSIC);
			}
		}
		case 8: return Show_MainDjihadMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_DjihadStartMenu(id);
}

public timer_djihad_start()
{
	if(--g_iTimerDjihadStart)
	{
		set_hudmessage(102, 69, 0, -1.0, 0.3, 0, 0.0, 15.0, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncHudDjihadStatus, "До начала глобальной игры^n'Битва за Джихад'^nОсталось %d секунд!", g_iTimerDjihadStart);
	}
	else
	{
		set_hudmessage(102, 69, 0, -1.0, 0.3, 0, 0.0, 15.0, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncHudDjihadStatus, "Глобальная игра^n'Битва за Джихад'^nНачалась!");
		jbe_set_friendlyfire(1);
		UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1 || g_iUserRolePlayDjihad[iPlayer] != 2) continue;
			
			g_iUserSpeed[iPlayer] = 50.0;
			set_entvar(iPlayer, var_maxspeed, g_iUserSpeed[iPlayer]);
		}
	}
}

Show_DjihadRolePlayMenu_1(id)
{

	new szMenu[1024], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), iLen;
	FormatMain("\yВыдача ролей в игре 'Битва за Джихад' \w[1|2]^n^n");
	
	FormatItem("\y1. \wЗабрать роль^n^n");
	
	FormatItem("\y2. \wКэмпер^n");
	FormatItem("\y3. \wДжабба^n");
	FormatItem("\y4. \wМарсианин^n");
	FormatItem("\y5. \wФлэш^n");
	FormatItem("\y6. \wШпион^n");
	FormatItem("\y7. \wКонтрабандист^n");
	FormatItem("\y8. \wОмоновец^n");
	
	FormatItem("^n\y9. \wДалее");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_DjihadRolePlayMenu_1");
}

public Handle_DjihadRolePlayMenu_1(id, iKey)
{
	switch(iKey)
	{
		case 0: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 0, "Забрать роль");
		
		case 1: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 1, "Кэмпер");
		case 2: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 2, "Джабба");
		case 3: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 3, "Марсианин");
		case 4: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 4, "Флэш");
		case 5: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 5, "Шпион");
		case 6: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 6, "Контрабандист");
		case 7: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 7, "Омоновец");
		
		case 8: return Show_DjihadRolePlayMenu_2(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_DjihadRolePlayMenu_1(id);
}

Show_DjihadRolePlayMenu_2(id)
{

	new szMenu[1024], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), iLen;
	FormatMain("\yВыдача ролей в игре 'Битва за Джихад' \w[2|2]^n^n");
	
	FormatItem("\y1. \wАльтаир^n");
	FormatItem("\y2. \wФея^n");
	FormatItem("\y3. \wКопатель^n");
	FormatItem("\y4. \wХохол^n");
	FormatItem("\y5. \wШахид^n");
	
	FormatItem("^n\y9. \wНазад");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_DjihadRolePlayMenu_2");
}

public Handle_DjihadRolePlayMenu_2(id, iKey)
{
	switch(iKey)
	{
		
		case 0: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 8, "Альтаир");
		case 1: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 9, "Фея");
		case 2: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 10, "Копатель");
		case 3: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 11, "Хохол");
		case 4: return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id] = 0, g_iDjihadMenuType[id] = 12, "Шахид");
		
		
		case 8: return Show_DjihadRolePlayMenu_1(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_DjihadRolePlayMenu_2(id);
}

// Конструктор меню был частично взят у alexfiner
public Show_GiveRolePlayDjihadMenu(id, iPos, iRole, title[MAX_NAME_LENGTH])
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum, g_iMenuTitle[MAX_NAME_LENGTH];
	copy(g_iMenuTitle, charsmax(g_iMenuTitle), title);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 /*|| i == id*/) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			client_print(id, print_chat, "[Битва за Джихад] Нет подходящих игроков");
			return PLUGIN_HANDLED;
		}
		case 1: FormatMain("\y%s^n^n", g_iMenuTitle);
		default: FormatMain("\y%s \w[%d|%d]^n^n", g_iMenuTitle, iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a]; 
	
		if(g_iUserRolePlayDjihad[i] == iRole) 
		{
			if(g_iDjihadMenuType[id] == 0)
			{
				FormatItem("\y%d. \d%n^n", ++b, i);
			}
			else FormatItem("\y%d. \d%n \r[%s]^n", ++b, i, g_szDjihadRolePlayName[g_iUserRolePlayDjihad[i]]);
		}
		else
		{
			iKeys |= (1<<b);
			if(g_iUserRolePlayDjihad[i] != 0) FormatItem("\y%d. \w%n \r[%s]^n", ++b, i, g_szDjihadRolePlayName[g_iUserRolePlayDjihad[i]]);
			else FormatItem("\y%d. \w%n^n", ++b, i);
		}

		
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	}
	else FormatItem("^n^n\y0. \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_GiveRolePlayDjihadMenu");
}

public Handle_GiveRolePlayDjihadMenu(id, iKey)
{
	switch(iKey)
	{
		//case 7: return Show_MainDjihadMenu(id);
		case 8: return Show_GiveRolePlayDjihadMenu(id, ++g_iMenuPosition[id], g_iDjihadMenuType[id], "Выдача ролей");
		case 9: 
		{
			if(!g_iMenuPosition[id])
				return Show_DjihadRolePlayMenu_1(id);
			else
			return Show_GiveRolePlayDjihadMenu(id, --g_iMenuPosition[id], g_iDjihadMenuType[id], "Выдача ролей");
		}
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(!jbe_is_user_alive(iTarget) && g_iUserRolePlayDjihad[iTarget] == g_iDjihadMenuType[id]) Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id], "Выдать роль");
			
			jbe_hide_user_costumes(iTarget);
			rg_set_user_footsteps(iTarget, false);
			Player_SetHealth(iTarget, 100);
			//set_entvar(iTarget, var_health, 100.0);
			set_entvar(iTarget, var_gravity, 1.0);
			jbe_set_user_rendering(iTarget, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
			g_iDjihadFootsteps[iTarget] = false;
			g_iUnAmmo[iTarget] = false;
			Player_ResetShake(iTarget);
			Player_ResetDrugs(iTarget);
			Player_ResetBurn(iTarget);
			g_iUserRolePlayDjihadBury[iTarget] = false;
			
			rg_remove_all_items(iTarget);
			rg_give_item_ex(iTarget, "weapon_knife", GT_REPLACE);
			
			g_iUserRolePlayDjihad[iTarget] = g_iDjihadMenuType[id];
			g_iUserSpeed[iTarget] = 0.0;
			rg_reset_maxspeed( iTarget);
			
			new Float:vecOrigin[3];
			get_entvar(iTarget, var_origin, vecOrigin);
			vecOrigin[2] += 30.0;
			set_entvar(iTarget, var_origin, vecOrigin);
			//jbe_set_user_noclip(iTarget, 0);
			if(g_iUserRolePlayDjihad[iTarget] == 5) jbe_set_user_model_ex(iTarget, 1);
			
			if(task_exists(iTarget + TASK_PLAYER_REGENERATION)) remove_task(iTarget + TASK_PLAYER_REGENERATION);
			switch(g_iDjihadMenuType[id])
			{

				case 0:
				{
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "У вас забрали роль");
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 0, "Забрать роль");
				}
				case 1:
				{
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Кэмпер'");
					rg_give_item_ex(iTarget, "weapon_awp", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_usp", GT_REPLACE, BULLET_GUN);
					jbe_set_user_rendering(iTarget, kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 90);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gКэмпер!y.Способность: !gAWP, USP, Невидимость: 90%%", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 1, "Кэмпер");
				}
				case 2:
				{
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Джабба'");
					
					 
					Player_SetHealth(iTarget, 5000);
					
					rg_give_item_ex(iTarget, "weapon_m249", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
				
					//g_iUserSpeed[iTarget] = 50.0;
					//set_entvar(iTarget, var_maxspeed, g_iUserSpeed[iTarget]);
					
					jbe_set_user_rendering(iTarget, kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 90);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gДжабба!y.Способность: !g5000HP,Невидимость: 90%%,Скорость: 50 units", iTarget);
					UTIL_SayText(0, "!g* !gСкорость у Джаббы уменьшиться после началы игры");
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 2, "Джабба");
				}
				case 3:
				{
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Марсианина'");
					
					Player_SetHealth(iTarget, 500);
					
					g_iUnAmmo[iTarget] = true;
					
					rg_give_item_ex(iTarget, "weapon_usp", GT_REPLACE, BULLET_GUN);
					
					jbe_set_user_rendering(iTarget, kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 10);
					g_iUserSpeed[iTarget] = 500.0;
					
					set_entvar(iTarget, var_maxspeed, g_iUserSpeed[iTarget]);
					UTIL_SayText(0, "!g* !g%n !yтеперь !gМарсианин!y.Способность: !g500HP,Невидимость: 90%%, Скорость: 500 units", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 3, "Марсианин");
				}
				case 4:
				{
					
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Флэш'");
					
				
					Player_SetHealth(iTarget, 1000);
					set_entvar(iTarget, var_gravity, 1.0);

					Player_SetDrugs(iTarget);
					
					rg_give_item_ex(iTarget, "weapon_glock18", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_m3", GT_APPEND, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_xm1014", GT_APPEND, BULLET_GUN);
					
					g_iUserSpeed[iTarget] = 1000.0;
					set_entvar(iTarget, var_maxspeed, g_iUserSpeed[iTarget]);
					UTIL_SayText(0, "!g* !g%n !yтеперь !gФлэш!y.Способность: !g1000HP, Наркота, Скорость: 1000units", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 4, "Флэш");
				}
				case 5:
				{
					
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Шпион'");
					

					rg_set_user_footsteps(iTarget, true);
					Player_SetHealth(iTarget, 800);

				
					rg_give_item_ex(iTarget, "weapon_usp", GT_REPLACE, BULLET_GUN);
					//cs_set_user_bpammo(iTarget, CSW_USP, 10000);
					
					g_iUserSpeed[iTarget] = 600.0;
					set_entvar(iTarget, var_maxspeed, g_iUserSpeed[iTarget]);
					jbe_set_user_model_ex(iTarget, 2);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gШпион!y.Способность: !g800HP, Форма охраны, Скорость: 600units, Бесшумные шаги", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 5, "Шпион");
				}
				case 6:
				{
				
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Контрабандист'");
					
					Player_SetHealth(iTarget, 1000);
					set_entvar(iTarget, var_gravity, 1.0);
				
					g_iUnAmmo[iTarget] = true;
					
					rg_give_item_ex(iTarget, "weapon_scout", GT_APPEND, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_mp5navy", GT_APPEND, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_tmp", GT_APPEND, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_mac10", GT_APPEND, BULLET_GUN);
					
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gКонтрабандист!y.Способность: !g1000HP, Комплект оружие, Бесконечные патроны", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 6, "Контрабандист");
				}
				case 7:
				{
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Омоновец'");

					Player_SetHealth(iTarget, 2000);


					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_shield", GT_REPLACE);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gОмоновец!y.Способность: !g2000HP, Щит и дигл", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 7, "Омоновец");
				}
				case 8:
				{

					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Альтаир'");
					

					Player_SetHealth(iTarget, 1000);
					set_entvar(iTarget, var_gravity, 0.4);
					

					rg_give_item_ex(iTarget, "weapon_ak47", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gАльтаир!y.Способность: !g1000HP, Гравитация", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 8, "Альтаир");
				}
				case 9:
				{
					
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Фея'");
					
					
					Player_SetHealth(iTarget, 1000);
					set_entvar(iTarget, var_gravity, 1.0);
					g_iDjihadFootsteps[iTarget] = true;
					Player_SetShake(iTarget);
					
					
					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_g3sg1", GT_REPLACE, BULLET_GUN);
					
					g_iUserSpeed[iTarget] = 600.0;
					set_entvar(iTarget, var_maxspeed, g_iUserSpeed[iTarget]);

					UTIL_SayText(0, "!g* !g%n !yтеперь !gФея!y.Способность: !g1000HP, Тряска экрана, Скорость: 600units, След за игроком", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 9, "Фея");
				}
				case 10:
				{
					
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Копатель'");
					
				
					Player_SetHealth(iTarget, 10000);
					set_entvar(iTarget, var_gravity, 1.0);
					
					
					rg_give_item_ex(iTarget, "weapon_g3sg1", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !gКопатель!y.Способность: !g10000HP, Закопан", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 10, "Копатель");
				}
				case 11:
				{
				
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Хохол'");
					
				
					Player_SetHealth(iTarget, 500);
					

					rg_give_item_ex(iTarget, "weapon_m4a1", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_deagle", GT_REPLACE, BULLET_GUN);
					//jbe_set_user_noclip(iTarget, 1);
					
					set_task_ex(5.0, "Task_PlayerRegeneration", iTarget + TASK_PLAYER_REGENERATION, .flags = SetTask_Repeat);
					UTIL_SayText(0, "!g* !g%n !yтеперь !gХохол!y.Способность: !g500HP, Бесконечный реген каждый 5 секунд по 20ХП", iTarget);
					
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 11, "Хохол");
				}
				case 12:
				{
					
					set_hudmessage(238, 154, 0, -1.0, 0.3, 0, 0.0, 12.0, 0.2, 0.2, -1);
					ShowSyncHudMsg(iTarget, g_iSyncHudDjihadStatus, "Вам выдали роль 'Шахид'");
				
					Player_SetHealth(iTarget, 7000);
					set_entvar(iTarget, var_gravity, 1.0);
					
					g_iUnAmmo[iTarget] = true;
				
					
					rg_give_item_ex(iTarget, "weapon_glock18", GT_REPLACE, BULLET_GUN);
					rg_give_item_ex(iTarget, "weapon_mac10", GT_REPLACE, BULLET_GUN);
					
					UTIL_SayText(0, "!g* !g%n !yтеперь !Шахид!y.Способность: !g7000HP, Бесконечный патрон, поджигание игроков", iTarget);
					return Show_GiveRolePlayDjihadMenu(id, g_iMenuPosition[id], g_iDjihadMenuType[id] = 12, "Шахид");
				}
			}
		}
	}
	return PLUGIN_HANDLED;
}
public Task_PlayerRegeneration(pId)
{
	if(!jbe_get_friendlyfire()) return;
	
	pId -= TASK_PLAYER_REGENERATION;

	new Float:Health;
	get_entvar(pId, var_health, Health);
	set_entvar(pId, var_health, Health + 20.0);
}


public HC_CBasePlayer_PlayerResetMaxSpeed_Post(const id)
{
	if(g_iUserSpeed[id])
	{
		set_entvar(id, var_maxspeed, g_iUserSpeed[id]);
	}
}

public client_PostThink(id)
{     

	if(!g_iStatusDjihad || !g_iDjihadFootsteps[id] || !jbe_is_user_alive(id))
		 return PLUGIN_CONTINUE;
	if(!(get_entvar(id, var_flags) & FL_ONGROUND) || get_entvar(id, var_groundentity))
		return PLUGIN_CONTINUE;
	
    static Float:origin[3];
    static Float:last[3];                
    get_entvar(id, var_origin, origin);
   
   if(get_distance_f(origin, last) < MAX_NAME_LENGTH.0)
		return PLUGIN_CONTINUE;
    
    vec_copy(origin, last);
    if(get_entvar(id, var_bInDuck)) origin[2] -= 18.0;
    else origin[2] -= 36.0;
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0);
    write_byte(TE_WORLDDECAL);
    write_coord(floatround(origin[0]));
    write_coord(floatround(origin[1]));
    write_coord(floatround(origin[2]));
    write_byte(105);
    message_end();
   
   return PLUGIN_CONTINUE;
}

Player_SetShake(id) 
{ 
	g_iShake[id] = true; 
	
	if(jbe_is_user_connected(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenShake, _, id); 
		write_short(1<<15); 
		write_short(1<<15); 
		write_short(1<<15); 
		message_end(); 
	}
	
	set_task(0.1, "Task_PlayerShake", id + TASK_PLAYER_SHAKE, _, _, "b"); 
} 

public Task_PlayerShake(id) 
{ 
	id -= TASK_PLAYER_SHAKE; 
	if(!IsShake(id)) 
	{ 
		if(task_exists(id + TASK_PLAYER_SHAKE)) 
		{ 
			remove_task(id + TASK_PLAYER_SHAKE); 
		}			 
		return; 
	}
	Shake(id);
	//Shake(id);
	//Shake(id);
}

Shake(const id)
{
	if(jbe_is_user_connected(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenShake, _, id); 
		write_short(1<<15); 
		write_short(1<<15); 
		write_short(1<<15); 
		message_end(); 
	}
}

Player_ResetShake(id)
{
	g_iShake[id] = false;
	
	if(task_exists(id + TASK_PLAYER_SHAKE))
	{
		remove_task(id + TASK_PLAYER_SHAKE);
	}
}

public ChangeCurWeapon(pId)
{
	if(!g_iStatusDjihad)
		return PLUGIN_CONTINUE;
	
	/*if(g_iUserSpeed[pId])
	{
		set_entvar(pId, var_maxspeed, g_iUserSpeed[pId]);
	}*/
	
	if(!g_iUnAmmo[pId])
		return PLUGIN_CONTINUE;
	
	enum { weapon = 2 };

	new iWeapon = read_data(weapon);

	new iClip = rg_get_weapon_info(iWeapon, WI_GUN_CLIP_SIZE);

	if(iClip < 0)
		return PLUGIN_CONTINUE;

	rg_set_weapon_ammo(get_member(pId, m_pActiveItem), iClip + 1);
	
	return PLUGIN_CONTINUE;
	
}


Player_SetDrugs(id)
{
	if(jbe_is_user_alive(id))
	{
		
		
		if(!g_iDrugs[id])
		{
			UTIL_ScreenFade(id, 0, 0, 4, random_num(0, 255), random_num(0, 255), random_num(0, 255), 100, 1);
			message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, id);
			write_byte(170);
			message_end();
		}
		g_iDrugs[id] = true;
	}
	return PLUGIN_HANDLED;
}

Player_ResetDrugs(id)
{
	if(jbe_is_user_alive(id))
	{
		if(g_iDrugs[id])
		{
			UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
			message_begin(MSG_ONE_UNRELIABLE, MsgId_SetFOV, _, id);
			write_byte(0);
			message_end();
		}
		
		g_iDrugs[id] = false;
	}
	return PLUGIN_HANDLED;
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MsgId_ScreenFade);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
	}
}

// Конструктор меню был частично взят у alexfiner
public Show_GiveRolePlayDjihadBury(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || g_iUserRolePlayDjihad[i] != 10 /*|| i == id*/) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			client_print(id, print_chat, "[Битва за Джихад] Нет подходящих игроков");
			return PLUGIN_HANDLED;
		}
		case 1: FormatMain("\yУправление копателями^n^n");
		default: FormatMain("\yУправление копателями \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new szName[MAX_NAME_LENGTH], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a]; 
		get_user_name(i, szName, charsmax(szName));
		
		iKeys |= (1<<b);
		FormatItem("\y%d. \w%s \r[%s]^n", ++b, szName, g_iUserRolePlayDjihadBury[i] ? "Откапать" : "Закапать");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iPos)
	{
		iKeys |= (1<<7);
		FormatItem("^n\y8. \wНазад");
	} 
	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \wДалее");
	}
	else FormatItem("^n\y9. \dДалее");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_GiveRolePlayDjihadBury");
}

public Handle_GiveRolePlayDjihadBury(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_MainDjihadMenu(id);
		case 8: return Show_GiveRolePlayDjihadBury(id, ++g_iMenuPosition[id]);
		case 9: return Show_GiveRolePlayDjihadBury(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(jbe_get_user_team(iTarget) != 1 || !jbe_is_user_alive(iTarget) || g_iUserRolePlayDjihad[iTarget] != 10) return Show_GiveRolePlayDjihadBury(id, g_iMenuPosition[id]);
			if(g_iUserRolePlayDjihadBury[iTarget])
			{	
				g_iUserRolePlayDjihadBury[iTarget] = false;
				
				new Float:vecOrigin[3];
				get_entvar(iTarget, var_origin, vecOrigin);
				vecOrigin[2] += 30.0;
				set_entvar(iTarget, var_origin, vecOrigin);
				
				return Show_GiveRolePlayDjihadBury(id, g_iMenuPosition[id]);
			}
			else
			{
				g_iUserRolePlayDjihadBury[iTarget] = true;
				
				new Float:vecOrigin[3];
				get_entvar(iTarget, var_origin, vecOrigin);
						
				vecOrigin[2] -= 30.0;
					
				set_entvar(iTarget, var_origin, vecOrigin);
					
				if(jbe_is_user_connected(iTarget))
				{
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
					write_byte(TE_BREAKMODEL);
					write_coord(floatround(vecOrigin[0]));
					write_coord(floatround(vecOrigin[1]));
					write_coord(floatround(vecOrigin[2]) + 24);
					write_coord(16);
					write_coord(16);
					write_coord(16);
					write_coord(random_num(-50,50));
					write_coord(random_num(-50,50));
					write_coord(25);
					write_byte(10);
					write_short(g_iModelDirt);
					write_byte(9);
					write_byte(20);
					write_byte(0x08);
					message_end();
				}
				
				return Show_GiveRolePlayDjihadBury(id, g_iMenuPosition[id]);
			}
		}
	}
	return Show_GiveRolePlayDjihadBury(id, g_iMenuPosition[id] = 0);
}

// Конструктор меню был частично взят у alexfiner
public Show_GiveRolePlayDjihadBurn(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || g_iUserRolePlayDjihad[i] != 12 /*|| i == id*/) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			client_print(id, print_chat, "[Битва за Джихад] Нет подходящих игроков");
			return PLUGIN_HANDLED;
		}
		case 1: FormatMain("\yУправление шахидами^n^n");
		default: FormatMain("\yУправление шахидами \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new szName[MAX_NAME_LENGTH], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a]; 
		get_user_name(i, szName, charsmax(szName));
		
		iKeys |= (1<<b);
		FormatItem("\y%d. \w%s \r[%s]^n", ++b, szName, g_iUserRolePlayDjihadBurn[i] ? "Потушить" : "Поджеч");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iPos)
	{
		iKeys |= (1<<7);
		FormatItem("^n\y8. \wНазад");
	} 
	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \wДалее");
	}
	else FormatItem("^n\y9. \dДалее");
	FormatItem("^n\y0. \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_GiveRolePlayDjihadBurn");
}

public Handle_GiveRolePlayDjihadBurn(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_MainDjihadMenu(id);
		case 8: return Show_GiveRolePlayDjihadBurn(id, ++g_iMenuPosition[id]);
		case 9: return Show_GiveRolePlayDjihadBurn(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(jbe_get_user_team(iTarget) != 1 || !jbe_is_user_alive(iTarget) || g_iUserRolePlayDjihad[iTarget] != 12) return Show_GiveRolePlayDjihadBurn(id, g_iMenuPosition[id]);
			if(g_iUserRolePlayDjihadBurn[iTarget])
			{
				Player_ResetBurn(iTarget);
				return Show_GiveRolePlayDjihadBurn(id, g_iMenuPosition[id]);
			}
			else
			{
				Player_SetBurn(iTarget);
				return Show_GiveRolePlayDjihadBurn(id, g_iMenuPosition[id]);
			}
		}
	}
	return Show_GiveRolePlayDjihadBurn(id, g_iMenuPosition[id] = 0);
}

Player_SetBurn(id)
{
	g_iUserRolePlayDjihadBurn[id] = true;
	if(jbe_is_user_connected(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
		write_short(1<<0); // duration
		write_short(1<<0); // hold time
		write_short(1<<2); // fade type
		write_byte(255); // r
		write_byte(44); // g
		write_byte(0); // b
		write_byte(100); // alpha
		message_end();
	}
	set_task(0.2, "Task_PlayerFlame", id + TASK_PLAYER_BURN, _, _, "b");
}

public Task_PlayerFlame(id)
{
	id -= TASK_PLAYER_BURN;
	
	if(!IsBurn(id))
	{
		if(task_exists(id + TASK_PLAYER_BURN))
		{
			remove_task(id + TASK_PLAYER_BURN);
		}
		return;
	}
	
	new vecOrigin[3];
	get_user_origin(id, vecOrigin);
	
	new iFlags = get_entvar(id, var_flags);
	
	if(iFlags & FL_INWATER)
	{
		g_iUserRolePlayDjihadBurn[id] = false;
		
		// Smoke sprite
		if(jbe_is_user_connected(id))
		{
			message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
			write_byte(TE_SMOKE); // TE id
			write_coord(vecOrigin[0]); // x
			write_coord(vecOrigin[1]); // y
			write_coord(vecOrigin[2] - 50); // z
			write_short(g_iSpriteSmoke); // sprite
			write_byte(random_num(15, 20)); // scale
			write_byte(random_num(10, 20)); // framerate
			message_end();
			
			message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
			write_short(1<<0);
			write_short(1<<0);
			write_short(1<<1);
			write_byte(0);
			write_byte(0);
			write_byte(0);
			write_byte(0);
			message_end();
		}
		
		if(task_exists(id + TASK_PLAYER_BURN))
		{
			remove_task(id + TASK_PLAYER_BURN);
		}
		return;
	}
	
	// Fire slow down
	if(iFlags & FL_ONGROUND)
	{
		new Float:vecVelocity[3];
		get_entvar(id, var_velocity, vecVelocity);
		
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		
		set_entvar(id, var_velocity, vecVelocity);
	}
	
	if(random_num(1, 4) == 1)
	{
		new iHealth = floatround(get_entvar(id, var_health));
		switch(iHealth)
		{
			case 1..5:
			{
				g_iUserRolePlayDjihadBurn[id] = false;
				
				// Smoke sprite
				if(jbe_is_user_connected(id))
				{
					message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
					write_byte(TE_SMOKE); // TE id
					write_coord(vecOrigin[0]); // x
					write_coord(vecOrigin[1]); // y
					write_coord(vecOrigin[2] - 50); // z
					write_short(g_iSpriteSmoke); // sprite
					write_byte(random_num(15, 20)); // scale
					write_byte(random_num(10, 20)); // framerate
					message_end();
					
					message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
					write_short(1<<0);
					write_short(1<<0);
					write_short(1<<1);
					write_byte(0);
					write_byte(0);
					write_byte(0);
					write_byte(0);
					message_end();
				}
				
				if(task_exists(id + TASK_PLAYER_BURN))
				{
					remove_task(id + TASK_PLAYER_BURN);
				}
				return;
			}
			default:
			{
				if(jbe_is_user_connected(id))
				{
					message_begin(MSG_ONE_UNRELIABLE, MsgId_Demage, _, id);
					write_byte(0); // damage save
					write_byte(0); // damage take
					write_long(DMG_BURN); // damage type
					write_coord(0); // x
					write_coord(0); // y
					write_coord(0); // z
					message_end();
				}
				
				Player_SetHealth(id, iHealth - 2);
			}
		}
	}
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE); // TE id
	write_coord(vecOrigin[0] + random_num(-5, 5)); // x
	write_coord(vecOrigin[1] + random_num(-5, 5)); // y
	write_coord(vecOrigin[2] + random_num(-10, 10)); // z
	write_short(g_iSpriteFlash); // sprite
	write_byte(random_num(5, 10)); // scale
	write_byte(200); // brightness
	message_end();
}

Player_ResetBurn(id)
{
	
	if(g_iUserRolePlayDjihadBurn[id])
	{
	
		if(task_exists(id + TASK_PLAYER_BURN))
		{
			remove_task(id + TASK_PLAYER_BURN);
		}
		
		if(!jbe_is_user_alive(id)) return;
		
		new vecOrigin[3];
		get_user_origin(id, vecOrigin);
		
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		write_byte(TE_SMOKE); // TE id
		write_coord(vecOrigin[0]); // x
		write_coord(vecOrigin[1]); // y
		write_coord(vecOrigin[2] - 50); // z
		write_short(g_iSpriteSmoke); // sprite
		write_byte(random_num(15, 20)); // scale
		write_byte(random_num(10, 20)); // framerate
		message_end();
		if(jbe_is_user_connected(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
			write_short(1<<0);
			write_short(1<<0);
			write_short(1<<1);
			write_byte(0);
			write_byte(0);
			write_byte(0);
			write_byte(0);
			message_end();
		}
	}
	
	g_iUserRolePlayDjihadBurn[id] = false;
}

public xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

public plugin_natives() 
{
	register_native("jbe_global_djihad", "OpenMainDjihadGameMenu", 1);
	register_native("jbe_global_get_djihad", "jbe_global_get_djihad", 1);
}

public jbe_global_get_djihad() return g_iStatusDjihad;

#define MsgId_SendAudio 100
stock UTIL_SendAudio(pPlayer, iPitch = 100, const szPathSound[], any:...)
{
	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] UTIL_SendAudio");
	}
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(MSG_BROADCAST, MsgId_SendAudio);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SendAudio, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
	}
}