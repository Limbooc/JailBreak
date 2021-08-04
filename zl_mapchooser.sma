//-----------
// [ZL] MapChooser
//
// Main Forum
// http://zombielite.Ru/
//--
// By Alexander.3
// http://Alexander3.Ru/

#include < amxmodx >
#include < engine >
#include < reapi>

#define NAME 			"[ZL] MapChooser"
#define VERSION			"1.1"
#define AUTHOR			"Alexander.3"

#define ONLYBOSS

new const map_list[] =		"addons/amxmodx/configs/maps2.ini"
new const map_sound[] =		"zl/gameplay/szTimer"
const map_soundsize =		6
new map_vote =			5
new map_vote_time =		20

new Array:g_MapList
new Array:g_MapRandom


new g_PlayerVote[33]
new g_MapVote[10]
new g_Timer
new g_CallBack

#if defined ONLYBOSS
native zl_boss_map()
#endif
native strip_user_weapons(index)

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)

	#if defined ONLYBOSS
	if (!zl_boss_map()) {
		pause("ad")
		return
	}
	#endif

	g_MapList 	= ArrayCreate(32)
	g_MapRandom 	= ArrayCreate(100)
	g_CallBack	= menu_makecallback("menu_callback")
	
	PluginPause()
	MapRead(map_list)
	RandomMassive(g_MapRandom, ArraySize(g_MapList))
	
	g_Timer = create_entity("info_target")
	entity_set_string(g_Timer, EV_SZ_classname, "TimerMessage")
	register_think("TimerMessage", "StartVote")
	

	register_dictionary("zl_mapshooser.txt")

}



public StartVote() {
	new szBuffer[192], szNone[24], Cell, Menu
	static MapVoteBuff, MapLider[32], bool:Prepare;
	
	
	
	if (!Prepare) {
		for(new id = 1; id <= get_maxplayers(); id++) {
			if (!is_user_alive(id))
				continue
				
			entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) | FL_FROZEN)
			strip_user_weapons(id)
		}
		ScreenFade(0, 1, 1, {0, 0, 0}, 255, 4)
		message_begin(MSG_BROADCAST, get_user_msgid("HideWeapon"))
		write_byte(59)
		message_end()
		Prepare = true
		client_cmd(0, "spk ^"%s/0.wav^"", map_sound) 
	}
	
	formatex(szNone, charsmax(szNone), "%L", LANG_PLAYER, "MENU_NOSELECT")
	g_MapVote[9] ? (MapLider = MapLider) : (MapLider = szNone)
	formatex(szBuffer, charsmax(szBuffer), "%L^n^n%L^n%L^n%L", LANG_PLAYER, "MENU_NAME", LANG_PLAYER, "MENU_LIDER", MapLider, LANG_PLAYER, "MENU_TIME", map_vote_time, LANG_PLAYER, "MENU_NUM", g_MapVote[9], get_playersnum())
	Menu = menu_create(szBuffer, "menu_func")
	
	if ( map_vote >= 9 ) map_vote = 9
	if ( ArraySize(g_MapList) < map_vote ) map_vote = ArraySize(g_MapList)
	
	for (new i = 0; i < map_vote; i++) {
		new MapName[32]
		Cell = ArrayGetCell(g_MapRandom, i)
		ArrayGetString(g_MapList, Cell, MapName, charsmax(MapName))
		
		if (g_MapVote[i] > MapVoteBuff) {
			MapLider = MapName
			MapVoteBuff = g_MapVote[i]
		}
		
		formatex(szBuffer, charsmax(szBuffer), "%s \r[%d \y(%d%%)\r]", MapName, g_MapVote[i], g_MapVote[9] ? floatround(floatmul(float(g_MapVote[i]) / float(g_MapVote[9]), 100.0)) : 0)
		menu_additem(Menu, szBuffer, MapName, _, g_CallBack)
	}
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER)
	for(new id = 1; id <= get_maxplayers(); id++) {
		if (!is_user_connected(id))
			continue
			
		menu_display(id, Menu, 0)
	}
	
	if (map_vote_time && map_vote_time < map_soundsize) {
		client_cmd(0, "spk ^"%s/%d.wav^"", map_sound, map_vote_time) 
		if (map_vote_time <= 0) {
			g_MapVote[9] ? server_cmd("changelevel ^"%s^"", MapLider) : server_cmd("reload")
			return
		}
	}
	entity_set_float(g_Timer, EV_FL_nextthink, get_gametime() + 1.0) 
	map_vote_time--
}

public menu_func(id, menu, item) {
	if (item == MENU_EXIT)
		return PLUGIN_HANDLED
	
	menu_display(id, menu)
    
	if (g_PlayerVote[id] > 0)
		return PLUGIN_HANDLED
		
	g_PlayerVote[id] = (1 + item)
	g_MapVote[item]++
	g_MapVote[9]++
	return PLUGIN_HANDLED
}

public menu_callback(id, menu, item) {
	if ((g_PlayerVote[id] - 1) == item)
		return ITEM_DISABLED
	return ITEM_ENABLED
}

public plugin_precache() {
	if (zl_boss_map())
	{
		new szSoundBuff[64], i
		for (i = 0; i < map_soundsize; ++i) {
			formatex(szSoundBuff, charsmax(szSoundBuff), "%s/%d.wav", map_sound, i)
			precache_sound(szSoundBuff)
			//precache_sound("zl/gameplay/szTimer/vote_started.wav")
		}
	}
}

public plugin_natives()
	register_native("zl_vote_start", "StartVote", 1)

MapRead(const filename[]) {
	if (!file_exists(filename))
		return

	new file = fopen(filename, "rt")
	new buff[32], MapText[32], CurrentMap[32]
	get_mapname(CurrentMap, charsmax(CurrentMap))
	
	while (file && !feof(file)) {
		fgets(file, buff, charsmax(buff))
		replace(buff, charsmax(buff), "^n", "")
		
		if (!buff[0]) continue
		
		parse(buff, MapText, charsmax(MapText))
		replace(MapText, charsmax(MapText), ".bsp", "")
		
		if (MapText[0] == ';' || equali(MapText, CurrentMap) || !is_map_valid(MapText))
			continue

		ArrayPushString(g_MapList, MapText)
	}
	fclose(file)
}

public PluginPause() {
	if (pause("ac", "nextmap.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"nextmap.amxx^" paused")
	if (pause("ac", "timeleft.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"timeleft.amxx^" paused")
	if (pause("ac", "mapchooser.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"mapchooser.amxx^" paused")
	if (pause("ac", "galileo_RU_by_MastaMan.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"galileo_RU_by_MastaMan.amxx^" paused")
	if (pause("ac", "galileo.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"galileo.amxx^" paused")
	if (pause("ac", "deagsmapmanager.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"deagsmapmanager.amxx^" paused")
	if (pause("ac", "umm.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"umm.amxx^" paused")
	if (pause("ac", "mapmanager.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"mapmanager.amxx^" paused")
	if (pause("ac", "mapmanager_subplugin.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_core.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_scheduler.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_rtv.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_nomination.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_blocklist.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_online_sorter.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_effects.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "map_manager_informer.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	if (pause("ac", "focus_on_votemap.amxx")) log_amx( "[ZL] Mapchooser running, plugin ^"MapManager.amxx^" paused")
	
	
}

stock RandomMassive(Array:a, size) {
	new i, j, b
	for(i = 0; i < size; i++) {
		ArrayPushCell(a, i)
		ArraySetCell(a, i, i)
	}
     
	for(i = 0; i < size; i++) {		
		j = random(size - 1)
		b = ArrayGetCell(a, i)
		ArraySetCell(a, i, ArrayGetCell(a, j))
		ArraySetCell(a, j, b)
	}
}

stock ScreenFade(id, Timer, FadeTime, Colors[3], Alpha, type) {
	if (id) if(!is_user_connected(id)) return

	if (Timer > 0xFFFF) Timer = 0xFFFF
	if (FadeTime <= 0) FadeTime = 4
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short(Timer * 1 << 12)
	write_short(FadeTime * 1 << 12)
	switch (type) {
		case 1: write_short(0x0000)		// IN ( FFADE_IN )
		case 2: write_short(0x0001)		// OUT ( FFADE_OUT )
		case 3: write_short(0x0002)		// MODULATE ( FFADE_MODULATE )
		case 4: write_short(0x0004)		// STAYOUT ( FFADE_STAYOUT )
		default: write_short(0x0001)
	}
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
