/* 
	MainPlugin
	
	www.ZombieLite.Ru
	www.Alexander3.Ru
*/

#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
//#include < nvault >
#include < reapi >
#include <jbe_core >

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

//#define TEMP_OFF

native jbe_aliveplayersnum(iType);
native jbe_totalalievplayers();
native jbe_totalplayers();

//#define DEBUG_ROUND


#define PLUGIN 			"[ZL] CoreFunction"
#define VERSION			"2.0.2"
#define AUTHOR			"Alexander.3"

/* ALL SETTING */
#define CMD_BOSS		"say /boss"

/* Macro */
#define MAPCHOOSER
//#define DEBUG

/* MAP SETTING */
#define MAP_DIONE		"boss_dione"
#define MAP_ANGRA		"boss_angra"
#define MAP_SCORPION		"zl_boss_scorpion_alpha"
#define MAP_REVENANT		"boss_revenant"
#define MAP_ALIEN		"zl_boss_alien"
#define MAP_OBERON		"zl_boss_oberon"
#define MAP_ENVYMASK		"megaololo"
#define MAP_ILLIDAN		"zl_boss_illidan_alpha"

#define MAP_P_REVENANT		"zl_boss_p_revenant_alpha"




////////////////////////
/*------- CODE -------*/
/*---- DONT CHANGE ---*/
////////////////////////

#define m_rgAmmoCBasePlayer	376

#define b_mNum			10
#define b_bmin			1
#define b_bmax			2
#define v_name			"boss_time"
#define f_config		"zl_core.ini"

#define MsgId_RoundTime 101

#if defined MAPCHOOSER
native zl_vote_start()
#endif

/* global */
static g_blood[2],
	g_cvar[4], Float:g_fcvar, g_cfg_cvar[3], Float:g_cfg_fcvar,
	g_cfg_szmap[24];
new g_timer_forward;

/* vote */
static bool:g_vote_true, g_voteid[33], g_vote[b_mNum], g_CallBack,
	g_vote_all, /*g_vote_vault, */g_vote_time, Array:BossMap

/* respawn */
static bool:g_respawn_preapre = true

new g_iSyncMain;

public plugin_precache() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	
		
	g_cvar[0] = get_cvar_num("mp_autoteambalance")
	g_cvar[1] = get_cvar_num("mp_limitteams")
	g_cvar[2] = get_cvar_num("mp_startmoney")
	//g_cvar[3] = get_cvar_num("mp_friendlyfire")
	g_fcvar = get_cvar_float("mp_buytime")
	config_load()
	
	if (native_zl_map_boss() > 0) {
		RegisterHam(Ham_TraceAttack, "info_target", "Hook_TraceAttack")
		RegisterHam(Ham_Killed, "info_target", "Hook_Killed")
		RegisterHam(Ham_Killed, "player", "Hook_Killed", 1)
		register_message(get_user_msgid("AmmoX"), "MSG_AmmoX")
		
		g_blood[0] = precache_model("sprites/blood.spr")
		g_blood[1] = precache_model("sprites/bloodspray.spr")
		g_timer_forward = CreateMultiForward("zl_timer", ET_CONTINUE, FP_CELL, FP_CELL)
		new task = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall"))
		set_pev(task, pev_classname, "zl_classname_timer")
		set_pev(task, pev_nextthink, get_gametime() + 1.0)
		RegisterHamFromEntity(Ham_Think, task, "Hook_Think")
		//register_event ("Damage", "eDamage", "b", "2!0");
			
		set_cvar_num("mp_autoteambalance", 0)
		set_cvar_num("mp_limitteams", 0)
		set_cvar_num("mp_startmoney", 16000)
		//set_cvar_num("mp_friendlyfire", 0)
		set_cvar_float("mp_buytime", 99.99)
		//set_cvar_num("mp_round_infinite", 1)
		
		g_iSyncMain = CreateHudSyncObj()
		register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
	} else {
		
		
		BossMap = ArrayCreate(128)
		
		if(is_plugin_loaded("zl_dioneboss.amxx", true) != -1) ArrayPushString(BossMap, MAP_DIONE)
		if(is_plugin_loaded("zl_boss_scorpion.amxx", true) != -1) ArrayPushString(BossMap, MAP_SCORPION)
		if(is_plugin_loaded("zl_angraboss.amxx", true) != -1) ArrayPushString(BossMap, MAP_ANGRA)
		if(is_plugin_loaded("zl_revenantboss.amxx", true) != -1) ArrayPushString(BossMap, MAP_REVENANT)
		if(is_plugin_loaded("zl_alienboss.amxx", true) != -1) ArrayPushString(BossMap, MAP_ALIEN)
		if(is_plugin_loaded("zp_oberon_boss.amxx", true) != -1) ArrayPushString(BossMap, MAP_OBERON)
		if(is_plugin_loaded("zl_boss_envymask.amxx", true) != -1) ArrayPushString(BossMap, MAP_ENVYMASK)
		if(is_plugin_loaded("zl_boss_illidan.amxx", true) != -1) ArrayPushString(BossMap, MAP_ILLIDAN)	
		if(is_plugin_loaded("zl_boss_p_revenant.amxx", true) != -1) ArrayPushString(BossMap, MAP_P_REVENANT)
		
		register_logevent("RoundEnd", 2, "1=Round_End")
		#if !defined TEMP_OFF
		register_clcmd(CMD_BOSS, "vote_menu")
		#endif
		g_CallBack = menu_makecallback("vote_menu_callback")
		//g_vote_vault = nvault_open("zl_boss")
		//g_vote_time = nvault_get(g_vote_vault, v_name)
	
		set_cvar_num("mp_autoteambalance", g_cvar[0])
		set_cvar_num("mp_limitteams", g_cvar[1])
		set_cvar_num("mp_startmoney", g_cvar[2])
		//set_cvar_num("mp_friendlyfire", g_cvar[3])
		set_cvar_float("mp_buytime", g_fcvar)
		
	}
}

public FakeMeta_Voice_SetListening(iReceiver, iSender, bool:bListen)
{

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
	return FMRES_SUPERCEDE;
	

}

public RoundEnd() {
	if (!g_vote_true)
		return
	
	
	/*new szTime[16]
	formatex(szTime, charsmax(szTime), "%d", get_systime() + (g_cfg_cvar[1] * 60))
	nvault_pset(g_vote_vault, v_name, szTime)*/
	
	new szBossMap[32]; 
	ArrayGetString(BossMap, (zl_vote_winner() == -1) ? 0 : zl_vote_winner(), szBossMap, charsmax(szBossMap))
	log_amx(szBossMap)
	server_cmd("changelevel ^"%s^"", szBossMap)
}

public vote_menu(id) {
#if defined DEBUG_ROUND
	UTIL_SayText(id, "!g[Боссы] !yБоссы временно отключены!")
	return
#endif
	if (g_vote_true) {
		UTIL_SayText(id, "!g[Боссы] !yГолосование завершено!")
		return
	}
	
	if (zl_vote_time() > 0) {
		UTIL_SayText(id, "!g[Боссы] !yГолосование станет доступно через !g%d минут", ((zl_vote_time() / 60) > 0) ? (zl_vote_time() / 60) : 1)
		return
	}
		
	static menu
	
	if (!menu)menu = menu_create("^t", "vote_menu_handle")
	else { menu_display(id, menu); return; }
	
	formatex_title(menu)
	
	new i, BossNum = ArraySize(BossMap)
	
	for(i = 0; i < BossNum; ++i) menu_additem(menu, "", _, _, g_CallBack)
	menu_display(id, menu)
}

public vote_menu_handle(id, menu, key) {
/*	if (key == MENU_EXIT || g_vote_true) {
		//menu_destroy(menu)
		if (is_user_connected(id))
			menu_cancel(id)
			
		return PLUGIN_HANDLED
	}*/
	
	if (key == MENU_EXIT)
		return PLUGIN_HANDLED
  
	if (g_vote_true) {
		menu_cancel(id)
		return PLUGIN_HANDLED
	}
		
	if (g_voteid[id]) {
		g_vote[g_voteid[id]]--
		g_voteid[id] = key + 1
		g_vote[g_voteid[id]]++
	} else {
		static szName[32], szMap[32]
		get_user_name(id, szName, charsmax(szName))
		ArrayGetString(BossMap, key, szMap, charsmax(szMap))
		g_voteid[id] = key + 1
		g_vote[key + 1]++
		g_vote_all++
		UTIL_SayText(0, "!g[Боссы] !t%s !yПроголосовал за!g %s !yСделано !g[%d/%d] !yголосов. !g(say /boss)", szName, szMap, g_vote_all, zl_vote_count(g_cfg_fcvar)) 
	}
		
	if (g_vote_all >= zl_vote_count(g_cfg_fcvar)) {
		static szWinner[32]
		ArrayGetString(BossMap, zl_vote_winner(), szWinner, charsmax(szWinner))
		set_hudmessage(227, 177, 168, 0.12, 0.05, 2, 1.0, 7.0, 0.1, 0.1, -1)
		show_hudmessage(0, "Голосование завершено!^n\
			Следующий босс: %s^n^n\
			Последний раунд!", szWinner)
	
		g_vote_true = true
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	formatex_title(menu)
	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public vote_menu_callback(id, menu, key) 
{
	static szMap[64]
	ArrayGetString(BossMap, key, szMap, charsmax(szMap))
	
	if (g_voteid[id] == (key + 1) || g_vote_true) 
	{
		format(szMap, charsmax(szMap), "\d%s \r[%d \y(%d%%)\r]", szMap, g_vote[key + 1], zl_vote_proc(key))
		menu_item_setname(menu, key, szMap)
		return ITEM_DISABLED
	} else 
	{
		format(szMap, charsmax(szMap), "\w%s \r[%d \y(%d%%)\r]", szMap, g_vote[key + 1], zl_vote_proc(key))
		menu_item_setname(menu, key, szMap)
		return ITEM_ENABLED
	}
	return ITEM_IGNORE
}

public MSG_AmmoX(msg, dest, id) {
	if (dest != MSG_ONE || !is_user_alive(id)) 
		return PLUGIN_CONTINUE
		
	new AmmoIndex = get_msg_arg_int(1)
	
	if (AmmoIndex > 10) {
		set_pdata_int(id, m_rgAmmoCBasePlayer + AmmoIndex, 0, 5)
		return PLUGIN_CONTINUE
	}
	
	set_pdata_int(id, m_rgAmmoCBasePlayer + AmmoIndex, 250, 5)
	return PLUGIN_CONTINUE
}

public client_putinserver(id) 
{
	if(native_zl_map_boss() > 0)
	{
		set_task(3.0, "checking", id + 5764587)		
		//rg_round_respawn(id);
		//g_PlayerCount++
	}
}

public checking(id)
{
	id -= 5764587
	
	if (!g_respawn_preapre) {
		if (jbe_totalalievplayers() <= 0) {
			is_map_valid(g_cfg_szmap) ?  server_cmd("changelevel ^"%s^"", g_cfg_szmap) : server_cmd("restart")
			return
		}


		rg_round_respawn(id);
    }

}

public client_disconnected(id) {
	if (native_zl_map_boss() <= 0) {
		if (g_voteid[id]) {
			g_vote[g_voteid[id]] = 0
			g_voteid[id] = 0
			g_vote_all--
		}
	}
	//g_PlayerCount--	
}

public plugin_end() {
	if (native_zl_map_boss() > 0) 
	{
		set_cvar_num("mp_autoteambalance", g_cvar[0])
		set_cvar_num("mp_limitteams", g_cvar[1])
		set_cvar_num("mp_startmoney", g_cvar[2])
		set_cvar_float("mp_buytime", g_fcvar)
		//DestroyForward(g_timer_forward);
	} 
	/*else 
	{	
		if(!g_vote_true) 
		{
			new szTime[32]
			formatex(szTime, charsmax(szTime), "%d", (zl_vote_time() > 0) ? (get_systime() + zl_vote_time()) : (get_systime()))
			nvault_pset(g_vote_vault, v_name, szTime)
		}
		nvault_close(g_vote_vault)
	}*/
}



public plugin_natives() {
	register_native("zl_boss_map", "native_zl_map_boss", 1)
	register_native("zl_boss_valid", "native_zl_valid_boss", 1)
	register_native("zl_player_alive", "native_zl_player_alive", 1)
	register_native("zl_player_random", "native_zl_random_player", 1)
	register_native("zl_player_count", "native_zl_player_count", 1)
	register_native("zl_colorchat", "UTIL_SayText", 1)
}

public native_zl_map_boss() {
	static MapName[64], Map_Boss
	
	if (MapName[0])
		return Map_Boss
	
	get_mapname(MapName, 63)

	if (contain(MapName, MAP_OBERON) != -1) Map_Boss = 1
	if (contain(MapName, MAP_ALIEN) != -1) Map_Boss = 2
	if (contain(MapName, MAP_ANGRA) != -1) Map_Boss = 3
	if (contain(MapName, MAP_REVENANT) != -1) Map_Boss = 4
	if (contain(MapName, MAP_ENVYMASK) != -1) Map_Boss = 5
	if (contain(MapName, MAP_ILLIDAN) != -1) Map_Boss = 6
	if (contain(MapName, MAP_SCORPION) != -1) Map_Boss = 7
	if (contain(MapName, MAP_DIONE) != -1) Map_Boss = 8
	
	if (contain(MapName, MAP_P_REVENANT) != -1) Map_Boss = 50
	
	#if defined DEBUG
	log_amx("DEBUG: Map id: %d | Map Name: %s", Map_Boss, MapName)
	#endif
	
	return Map_Boss
}

public native_zl_valid_boss(index) {
	new ClassName[32]
	pev(index, pev_classname, ClassName, charsmax(ClassName))
	//OberonBoss
	//0123456789
	//AlienBoss
	//012345678
	
	if (ClassName[0] == 'O' && ClassName[5] == 'n' && ClassName[7] == 'o') return 1
	if (ClassName[0] == 'A' && ClassName[4] == 'n' && ClassName[6] == 'o') return 2
	if (ClassName[0] == 'A' && ClassName[4] == 'a' && ClassName[5] == 'B') return 3
	if (ClassName[0] == 'R' && ClassName[2] == 'v' && ClassName[8] == 'B') return 4
	if (ClassName[0] == 'b' && ClassName[5] == 'z' && ClassName[9] == 's' || ClassName[0] == 'b' && ClassName[5] == 'n' && ClassName[8] == 'd') return 5
	if (ClassName[0] == 'b' && ClassName[5] == 'i' && ClassName[9] == 'd') return 6
	if (ClassName[0] == 'b' && ClassName[5] == 's' && ClassName[9] == 'p') return 7
	if (ClassName[0] == 'b' && ClassName[5] == 'p' && ClassName[14] == 't') return 50
	return 0
}

public native_zl_random_player() {
	new Index
	Index = GetRandomAlive(random_num(1, jbe_totalalievplayers()))
	return Index
}

public native_zl_player_alive() return jbe_totalalievplayers()

GetRandomAlive(target_index) {
	new iAlive, id
	for (id = 1; id <= MaxClients; id++) 
	{
		if (!is_user_alive(id) /*|| is_user_bot(id)*/)
			continue
			

		if (jbe_get_user_team(id) == 3)
			continue
		
		
		iAlive++
		
		if (iAlive == target_index) 
			return id
	}
	return -1
}

public native_zl_player_count()
	return jbe_totalplayers()
	



formatex_title(menu) {
	static szTitle[64]
	formatex(szTitle, charsmax(szTitle), "\yБоссы^nГолоса: %d/%d [%d%%]", g_vote_all, zl_vote_count(g_cfg_fcvar), g_vote_all * 100 / zl_vote_count(g_cfg_fcvar))
	menu_setprop(menu, MPROP_TITLE, szTitle)
}

zl_vote_count(Float:procent)
	return floatround(procent / 100.0 * float(jbe_totalplayers()), floatround_ceil)
	
zl_vote_proc(key)
	return g_vote_all ? floatround(floatmul(float(g_vote[key + 1]) / float(g_vote_all), 100.0)) : 0
	
zl_vote_winner() {
	new buffer = 0, s = 0, i = 0, m = ArraySize(BossMap)
	for(i = 1; i <= m; ++i) {
		if (g_vote[i] > buffer) {
			buffer = g_vote[i]
			s = i
		}
	}
	return s - 1
}

zl_vote_time()
	return g_vote_time - get_systime()

public Hook_Think(ent) 
{
	static Float: fCurTime; fCurTime = get_gametime();
	if(native_zl_map_boss() != 8 && native_zl_map_boss() != 4 && !jbe_totalalievplayers()) 
	{
		set_pev(ent, pev_nextthink, fCurTime + 1.0)
		return
	}
	static szName[32]
	pev(ent, pev_classname, szName, charsmax(szName))
	
	if(szName[0] == 'z' && szName[1] == 'l' && szName[14] == 'i' && szName[17] == 'r') {
		static Prepare = 2, ret
		set_pev(ent, pev_nextthink, fCurTime + 1.0)
		switch(Prepare) 
		{
			case 2: 
			{
				g_cfg_cvar[0]--
				//client_print(0, print_center, "Закупайте оружие! Атака начнется через: [%d]", g_cfg_cvar[0])
				//UTIL_SayText(0,  "Закупайте оружие! Атака начнется через: [%d]", g_cfg_cvar[0])

				set_hudmessage(255, 0, 10, -1.0, 0.4, 0, 0.0, 0.8, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncMain, "Закупайте оружие!^nАтака начнется через: %d секунд!", g_cfg_cvar[0])
				
				if(g_cfg_cvar[0] <= 0) {
					Prepare--
					g_respawn_preapre = false
				}
			}
			case 1: {
				Prepare--
				g_cfg_cvar[0]++
			}
			case 0:g_cfg_cvar[0]++
			default: g_cfg_cvar[0]++
		}
				
		message_begin(MSG_ALL, MsgId_RoundTime)
		write_short(g_cfg_cvar[0])
		message_end()
		
		//server_print("call g_timer_forward zl-core");
		ExecuteForward(g_timer_forward, ret, g_cfg_cvar[0], Prepare)		
		if(ret) Prepare = ret
	}
}

config_load() {		
	static path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/zl/%s", path, f_config)
    
	if(!file_exists(path)) 
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	static linedata[1024], key[64], value[960]
	new file = fopen(path, "rt")
    
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
       
		if (!linedata[0] || linedata[0] == '/') continue;
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)
		
		if (equal(key, "PREPARE"))
			g_cfg_cvar[0] = str_to_num(value)
		else if (equal(key, "BOSS_COLOR"))
			g_cfg_cvar[2] = str_to_num(value)
		else if (equal(key, "SZ_MAP"))
			parse(value, g_cfg_szmap, charsmax(g_cfg_szmap))
		else if (equal(key, "VOTE_PROCENT"))
			g_cfg_fcvar = str_to_float(value)
		else if (equal(key, "VOTE_TIME"))
			g_cfg_cvar[1] = str_to_num(value)
	}
	if (file) fclose(file)
}

public Hook_TraceAttack(boss, player, Float:dmg, Float:direction[3], tr, damage_type) {
	if (!native_zl_valid_boss( boss ))
		return HAM_IGNORED
	
	static Float:End[3]
	get_tr2(tr, TR_vecEndPos, End)

	if (pev(boss, pev_euser2) == 1) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord, End[0])
		engfunc(EngFunc_WriteCoord, End[1])
		engfunc(EngFunc_WriteCoord, End[2])
		message_end()
		return HAM_IGNORED
	}	
	
	if (pev(boss, pev_deadflag) == DEAD_NO && pev(boss, pev_takedamage) == DAMAGE_NO) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord, End[0])
		engfunc(EngFunc_WriteCoord, End[1])
		engfunc(EngFunc_WriteCoord, End[2])
		message_end()
		return HAM_SUPERCEDE
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, End[0])
	engfunc(EngFunc_WriteCoord, End[1])
	engfunc(EngFunc_WriteCoord, End[2])
	write_short(g_blood[0])
	write_short(g_blood[1])
	write_byte(g_cfg_cvar[2])
	write_byte(random_num(b_bmin, b_bmax))
	message_end()
	return HAM_IGNORED
}


public Hook_Killed(victim, attacker, corpse) {
	if (jbe_totalalievplayers() <= 0){
		set_task(6.0, "changemap2")
		return HAM_IGNORED
	}
	
	
	if (!native_zl_valid_boss(victim))
		return HAM_IGNORED
		
	if (pev(victim, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED
	

	set_pev(victim, pev_solid, SOLID_NOT)
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})
	
	static e = -1
	while ( (e = engfunc(EngFunc_FindEntityByString, e, "classname", "classname_zombie")) )
		if(pev_valid(e)) engfunc(EngFunc_RemoveEntity, e)
		
	
	

	switch(native_zl_map_boss()) {
		case 1: zl_anim(victim, 16, 1.0)
		case 2: zl_anim(victim, 1, 1.0)
		case 5: { // Neid and Zavist
			new szBossType[32], g_Neid, g_Zavist
			pev(victim, pev_classname, szBossType, charsmax(szBossType))
			
			g_Neid = engfunc(EngFunc_FindEntityByString, g_Neid, "classname", "boss_neid")
			g_Zavist = engfunc(EngFunc_FindEntityByString, g_Zavist, "classname", "boss_zavist")
			
			if (pev(g_Neid, pev_deadflag) == DEAD_DYING && pev(g_Zavist, pev_deadflag) == DEAD_DYING) {
				set_task(20.0, "changemap")
				return HAM_SUPERCEDE
			}
			static Float: fCurTime; fCurTime = get_gametime();
			
			set_pev(victim, pev_deadflag, DEAD_DYING)
			if (equal(szBossType, "boss_neid")) {
				zl_anim(victim, 35, 1.0)
				set_pev(g_Neid, pev_nextthink, fCurTime + 7.4)
			}
			if (equal(szBossType, "boss_zavist")) {
				zl_anim(victim, 28, 1.0)
				set_pev(g_Zavist, pev_nextthink, fCurTime + 13.2)
			}
			return HAM_SUPERCEDE
		}
		case 6: zl_anim(victim, 15, 1.0)
		case 7: zl_anim(victim, 20, 1.0)
	}

	set_pev(victim, pev_deadflag, DEAD_DYING)
	set_task(20.0, "changemap")
	return HAM_SUPERCEDE
}

public changemap() {
	#if defined MAPCHOOSER
	zl_vote_start()
	#else
	is_map_valid(g_cfg_szmap) ? server_cmd("changelevel ^"%s^"", g_cfg_szmap) : server_cmd("restart")
	#endif
}

public changemap2()
{
	if(jbe_totalalievplayers() <= 0)
	{
		#if defined MAPCHOOSER
		zl_vote_start()
		#else
		is_map_valid(g_cfg_szmap) ? server_cmd("changelevel ^"%s^"", g_cfg_szmap) : server_cmd("restart")
		#endif
	}
}
stock zl_anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, speed)
}

public UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
