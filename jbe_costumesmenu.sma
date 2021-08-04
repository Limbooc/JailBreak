#include <amxmodx>
#include <fakemeta>
#include <amxmisc>
#include <reapi>
#include <jbe_core>
#include <sqlx>
#include <gamecms5>

#define RANK_TABLE		"Regs_Save_Addons"


#define COST_1			100
#define COST_2			250
#define COST_3			450

#define EMPTYCOSTUMES			-1

new g_iGlobalDebug;
#include <util_saytext>
#define PLAYERS_PER_PAGE 8

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))


#define ADDON_BACK_MENU

native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);
native zl_boss_map()

//#define REMOVE_KONFLICT // Включите эту функцию, если будут конфликты с GroupInfo
new bool:g_iUserEditCostume[MAX_PLAYERS + 1];
enum groups ( <<= 1 )
{
    GROUP_NONE,
    GROUP_COSTUME = 1
}

enum _:CountVars
{
    CHOOSEN_TYPE = 0,
    CHOOSEN_COSTUME,
	CHOOSEN_TIME
}
new g_iUserMenuKey[MAX_PLAYERS + 1];
new g_iUserChoosenHats[MAX_PLAYERS + 1][CountVars][PLAYERS_PER_PAGE + 1];
new g_iUserBuyHats[MAX_PLAYERS + 1];
//#define BETA_DEBUG

//#define ENT_DEBUG


enum _:UserInfo
{ 
	ArrayLogin[MAX_NAME_LENGTH],
	ArrayCostumeID, 
	ArrayCostumeType, 
	ArrayTime
}

//new g_sUser[UserInfo];
new Array:g_aUsers;

//static Trie:g_aUsers

const QUERY_LENGTH =	1472;	// размер переменной sql запроса
const SQL_CONNECTION_TIMEOUT = 10;

new Handle:g_hDQuery;
new mode_only=0;


enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX,
    EXT_DATA__LOGIN[MAX_NAME_LENGTH],
    EXT_DATA__AUTH[MAX_AUTHID_LENGTH]
}

enum _:sql_que_type	// тип sql запроса
{
	SQL_LOAD,
	SQL_LOGOUT
}

enum _:enum_cvars {
	TypeID,
	CostumesID
}

//new Array:g_aPaidCostumes;

native jbe_mysql_stats_systems_add(pId, i, iNum);
native jbe_mysql_stats_systems_get(pId, i);
native get_login(pPlayer);
native jbe_global_status(iType);

#if defined REMOVE_KONFLICT 
#define MaskEnt(%0)    (1<<((%0+33) & 31))
#else
#define MaskEnt(%0)    (1<<((%0) & 31))
#endif

native Array:jbe_get_gang_id();
native jbe_get_user_gangid(pId, const GangName[] = "", iLen = 0);

native jbe_is_user_duel(id);
native jbe_show_mainmenu(pId);
/* -> Переменные и массивы для костюмов -> */
enum _:DATA_COSTUMES_PRECACHE
{
	MODEL_NAME[32],
	SUB_MODEL[4],
	NAME_COSTUME[64],
	FLAG_COSTUME[32],
	WARNING_MSG[32],
	NAME_MSG[MAX_NAME_LENGTH],
	TYPE_NUM[10],
}

enum _:COSTUME_SIZE_LIST
{
	COSTUMES_FREE = 0,
	COSTUMES_PAID,
	COSTUMES_GIRLS,
	COSTUMES_VIP,
	COSTUMES_INDIVID,
	COSTUMES_KONKURS
}

new iCostumesIndex[MAX_PLAYERS + 1];

enum eData_Gang {
	Gang_Id, 
	Gang_Name[MAX_NAME_LENGTH],
	Gang_CreateTime,
	Gang_LeaderAuth[MAX_AUTHID_LENGTH],
	Gang_LeaderName[MAX_NAME_LENGTH],
	Gang_Exp,
	Gang_Bonus,
	Gang_HP,
	Gang_Money,
	Gang_Skill,
	Gang_Active,
	Gang_CountPlayer,
	Gang_LoginLeader[MAX_NAME_LENGTH]
}

new g_iCostumesListSize[COSTUME_SIZE_LIST];




enum _:DATA_COSTUMES
{
	COSTUMES,
	ENTITY,
	HIDE,
	TYPE,
	OLDCOSTUMES[32]
};

new bool:g_iUserSteam[MAX_PLAYERS + 1];

new bool:g_iStatudHatsVisible[MAX_PLAYERS + 1];
new Array:g_aCostumesList_Array1, 
	Array:g_aCostumesList_Array2, 
	/*Array:g_aCostumesList_Array3,
	Array:g_aCostumesList_Array4,
	Array:g_aCostumesList_Array5,
	Array:g_aCostumesList_Array6,*/
	g_eUserCostumes[MAX_PLAYERS + 1][DATA_COSTUMES];


/* -> Массивы для меню из игроков -> */
new g_iMenuPosition[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[JBE] Costumes", "1.0", "DalgaPups");

	register_menucmd(register_menuid("Show_MainCostumeMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainCostumeMenu");

	register_menucmd(register_menuid("Show_FirstCostumeMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_FirstCostumeMenu");
	register_menucmd(register_menuid("Show_ChoosenHats"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ChoosenHats");
	register_menucmd(register_menuid("Show_BuyCostumes"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_BuyCostumes");


	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true);
	
	//register_clcmd("say /trie", "Cmd_trie");
	
	register_cvar("jbe_mysql_sql_save_table",  "Regs_Save_Addons");
	
	#if defined ENT_DEBUG
	register_clcmd("say /allha", "esfsefserf");
	#endif
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	g_aUsers = ArrayCreate(UserInfo);
	
	

}
native get_login_len(id, login[], iLen)
/*public Cmd_trie(id)
{

	new g_sUser[UserInfo]
				

	for( new i = 0; i < ArraySize( g_aUsers ); i++ )
	{
		ArrayGetArray(g_aUsers, i, g_sUser);
		
		server_print("%s | %d", g_sUser[ArrayLogin], g_sUser[ArrayCostumeID]);
	}


}*/
public plugin_cfg()
{
	new szPath[64], szPathFile[128];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	
	formatex(szPathFile, charsmax(szPathFile), "%s/jb_engine/mysql_regs.cfg", szPath);
	if(file_exists(szPathFile))
		RegisterMysqlSystems(szPathFile);
	else server_print("%s NOT FOUND", szPath);
}

public plugin_end()
{

	//TrieDestroy(g_aUsers);
	
}
RegisterMysqlSystems(cfg[])
{
	register_cvar("jbe_mysql_sql_save_table",  "Regs_Save_Addons");
	ExecCfg(cfg);
	
}

ExecCfg(const cfg[])
{
	server_cmd("exec %s", cfg);
	server_exec();
}




public client_putinserver(pId)
{	
	set_pev(pId, pev_groupinfo, pev(pId, pev_groupinfo) | (MaskEnt(1) | MaskEnt(2)));
	g_iStatudHatsVisible[pId] = false;
	
	for(new i = 0; i < PLAYERS_PER_PAGE; i++)
	{
		g_iUserChoosenHats[pId][CHOOSEN_TYPE][i] = 0;
		g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] = EMPTYCOSTUMES;
	}
	g_iUserSteam[pId] = check_steam( pId );
}


public jbe_load_stats(pId)
{
	iCostumesIndex[pId] = jbe_mysql_stats_systems_get(pId, 20);
	g_eUserCostumes[pId][COSTUMES] = jbe_mysql_stats_systems_get(pId, 2);
	jbe_set_user_costumes(pId, g_eUserCostumes[pId][COSTUMES]);
}
public jbe_save_stats(pId)
{
	jbe_mysql_stats_systems_add(pId, 20, iCostumesIndex[pId]);
	jbe_mysql_stats_systems_add(pId, 2, g_eUserCostumes[pId][COSTUMES]);
	jbe_set_user_costumes(pId, EMPTYCOSTUMES);
}


public esfsefserf(pId)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_None);
	
	for(new i; i < iPlayerCount; i++)
	{
		jbe_set_user_costumes(iPlayers[i], random_num(2, 10));
	}
	
}


public plugin_natives()
{
	register_native("Cmd_CostumesMenu", "Cmd_CostumesMenu", 1);
	register_native("jbe_set_user_costumes", "jbe_set_user_costumes", 1);
	register_native("jbe_hide_user_costumes", "jbe_hide_user_costumes", 1);
	register_native("jbe_get_user_costumes", "jbe_get_user_costumes", 1);
	register_native("jbe_is_user_hide_true_cos", "jbe_is_user_hide_true_cos", 1);
	register_native("jbe_get_costumes_list", "jbe_get_costumes_list", 1);
	register_native("jbe_set_group_visiblecos", "jbe_set_group_visiblecos", 1);
	register_native("jbe_get_group_visiblecos", "jbe_get_group_visiblecos", 1);
	register_native("jbe_is_user_hide_costume","jbe_is_user_hide_costume",1);
}

public jbe_is_user_hide_costume(pPlayer) return g_eUserCostumes[pPlayer][HIDE];
public jbe_get_costumes_list(iType)
{
	switch(iType)
	{
		case 1: return g_iCostumesListSize[COSTUMES_FREE];


	}
	return 0;
} 
public jbe_get_user_costumes(id) return g_eUserCostumes[id][COSTUMES];
public jbe_is_user_hide_true_cos(id) return g_eUserCostumes[id][HIDE];



public jbe_set_group_visiblecos(pId, bool:visible)
{
	set_entvar(pId, var_groupinfo, visible == true ? MaskEnt(1) | MaskEnt(2) : ~MaskEnt(1) | MaskEnt(2));
	g_iStatudHatsVisible[pId] = !visible;
}

public jbe_get_group_visiblecos(pId) return g_iStatudHatsVisible[pId];




public plugin_precache()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/costumes/costume_free.ini", szCfgDir);
	if(file_exists(szCfgFile))
	{
		new aDataCostumesRead[DATA_COSTUMES_PRECACHE], szBuffer[256], iLine, iLen;
		g_aCostumesList_Array1 = ArrayCreate(DATA_COSTUMES_PRECACHE);
		g_aCostumesList_Array2 = ArrayCreate(DATA_COSTUMES_PRECACHE);
		
		//formatex(aDataCostumesRead[NAME_COSTUME], charsmax(aDataCostumesRead[NAME_COSTUME]), "Снять шапку");
		//ArrayPushArray(g_aCostumesList_Array1, aDataCostumesRead);
		//ArrayPushArray(g_aCostumesList_Array2, aDataCostumesRead);
		
		while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
		{
			if(!iLen || szBuffer[0] == ';') continue;
			parse
			(
				szBuffer, 
				aDataCostumesRead[MODEL_NAME], 		charsmax(aDataCostumesRead[MODEL_NAME]), 
				aDataCostumesRead[SUB_MODEL], 		charsmax(aDataCostumesRead[SUB_MODEL]),
				aDataCostumesRead[NAME_COSTUME],	charsmax(aDataCostumesRead[NAME_COSTUME]),
				aDataCostumesRead[FLAG_COSTUME],	charsmax(aDataCostumesRead[FLAG_COSTUME]),
				aDataCostumesRead[WARNING_MSG],		charsmax(aDataCostumesRead[WARNING_MSG]),
				aDataCostumesRead[NAME_MSG],		charsmax(aDataCostumesRead[NAME_MSG]),
				aDataCostumesRead[TYPE_NUM],		charsmax(aDataCostumesRead[TYPE_NUM])
			);
			
			//server_print("%s | %d", aDataCostumesRead[TYPE_NUM], str_to_num(aDataCostumesRead[TYPE_NUM]));
	
			format(szBuffer, charsmax(szBuffer), "models/jb_engine/costumes/%s.mdl", aDataCostumesRead[MODEL_NAME]);
			if(file_exists(szBuffer)) 
			{
				engfunc(EngFunc_PrecacheModel, szBuffer);
			
			
				switch(str_to_num(aDataCostumesRead[TYPE_NUM]))
				{
					case COSTUMES_FREE: ArrayPushArray(g_aCostumesList_Array1, aDataCostumesRead);
					case COSTUMES_PAID: ArrayPushArray(g_aCostumesList_Array2, aDataCostumesRead);
				}
			}
			else
			{
				log_amx("Шапка не найдена: %s | %s", aDataCostumesRead[MODEL_NAME], szBuffer)
			}
			
		}
		g_iCostumesListSize[COSTUMES_FREE] = ArraySize(g_aCostumesList_Array1);
		g_iCostumesListSize[COSTUMES_PAID] = ArraySize(g_aCostumesList_Array2);
		
		//server_print("%d %d", g_iCostumesListSize[COSTUMES_FREE], g_iCostumesListSize[COSTUMES_PAID]);
	}
	else
	{
		log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		set_fail_state("File ^"%s^" not found!", szCfgFile)
	}
	
}

public client_disconnected(pId)
{
	if(!get_login(pId))
	{
		jbe_set_user_costumes(pId, EMPTYCOSTUMES);
		g_eUserCostumes[pId][TYPE] = 0;
		g_eUserCostumes[pId][COSTUMES] = EMPTYCOSTUMES;
	}

	g_iStatudHatsVisible[pId] = false;

}

public HC_CBasePlayer_PlayerSpawn_Post(id)
{
	if(jbe_is_user_alive(id))
	{
		if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
		{
			if(jbe_global_status(17) && jbe_get_user_team(id) == 1) return HC_CONTINUE;
			
			jbe_set_user_costumes(id, g_eUserCostumes[id][COSTUMES]);
		}
	}
	return HC_CONTINUE;
}





public Cmd_CostumesMenu(pId) return Show_MainCostumeMenu(pId);

Show_MainCostumeMenu(pId)
{
	new szMenu[512], iBitKeys, iLen;

	FormatMain("\yВыберите тип шапок^n^n");

	if(g_iCostumesListSize[COSTUMES_FREE]) FormatItem("\y1. \wБесплатные^n"), iBitKeys |= (1<<0);
	else FormatItem("\y1. \dБесплатные^n");
	
	if(g_iCostumesListSize[COSTUMES_PAID]) FormatItem("\y2. \wПлатные^n"), iBitKeys |= (1<<1);
	else FormatItem("\y2. \dПлатные^n");
	
	FormatItem("^n\y4. \yИзбранные^n"), iBitKeys |= (1<<3);
	FormatItem("^n^n\y5. \rСнять шапку^n"), iBitKeys |= (1<<4);
	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_BACK"), iBitKeys |= (1<<9);

	return show_menu(pId, iBitKeys, szMenu, -1, "Show_MainCostumeMenu");
}

public Handle_MainCostumeMenu(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: return Cmd_FirstCostumeMenu(pId, COSTUMES_FREE);
		case 1: return Cmd_FirstCostumeMenu(pId, COSTUMES_PAID);
		case 3: return Show_ChoosenHats(pId);
		case 4: 
		{
			UTIL_SayText(pId, "!g[Hats]!y Вы успешно сняли шапку");
			jbe_set_user_costumes(pId, EMPTYCOSTUMES);
		}
	//	case 7: return client_cmd(pId, "camera");
		case 9: return jbe_show_mainmenu(pId);
	}
	return Show_MainCostumeMenu(pId);
}


Show_ChoosenHats(pId)
{
	new szMenu[512], iBitKeys = (1<<8|1<<9), iLen, b;
	new aDataCostumes[DATA_COSTUMES_PRECACHE];
	
	

	FormatMain("\yИзбранные^n^n");
	
	for(new i = 0; i < PLAYERS_PER_PAGE; i++)
	{
		
		if(g_iUserEditCostume[pId])
		{
			iBitKeys |= (1<<b);
			if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] > EMPTYCOSTUMES)
			{
				switch(g_iUserChoosenHats[pId][CHOOSEN_TYPE][i])
				{
					case COSTUMES_FREE: 
					{
						if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] >= g_iCostumesListSize[COSTUMES_FREE])
						{
							g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] = EMPTYCOSTUMES;
						}
						ArrayGetArray(g_aCostumesList_Array1, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i], aDataCostumes);
					}
					case COSTUMES_PAID: 
					{
						if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] >= g_iCostumesListSize[COSTUMES_PAID])
						{
							g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] = EMPTYCOSTUMES;
						}
						ArrayGetArray(g_aCostumesList_Array2, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i], aDataCostumes);
					}
				}
				
				if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] > EMPTYCOSTUMES)
				{
					FormatItem("%s%d. \w%s^n", g_eUserCostumes[pId][TYPE] == iCostumesIndex[pId] ? "\y" : "\r", ++b, aDataCostumes[NAME_COSTUME]);
				}
				else FormatItem("\y%d. \d< Свободно >^n", ++b) ;
			}
			else
			FormatItem("\y%d. \d< Свободно >^n", ++b) ;
		}else 
		{
			if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] > EMPTYCOSTUMES)
			{
				switch(g_iUserChoosenHats[pId][CHOOSEN_TYPE][i])
				{
					case COSTUMES_FREE: 
					{
						if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] >= g_iCostumesListSize[COSTUMES_FREE])
						{
							g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] = EMPTYCOSTUMES;
						}
						ArrayGetArray(g_aCostumesList_Array1, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i], aDataCostumes);
					}
					case COSTUMES_PAID: 
					{
						if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] >= g_iCostumesListSize[COSTUMES_PAID])
						{
							g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] = EMPTYCOSTUMES;
						}
						ArrayGetArray(g_aCostumesList_Array2, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i], aDataCostumes);
					}
					
				}
				iBitKeys |= (1<<b);
				
				if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] > EMPTYCOSTUMES)
				{	
					FormatItem("%s%d. \w%s^n", g_eUserCostumes[pId][TYPE] == iCostumesIndex[pId] ? "\y" : "\r", ++b, aDataCostumes[NAME_COSTUME]);
				}else FormatItem("\y%d. \d< Свободно >^n", ++b) ;
			}
			else
			FormatItem("\y%d. \d< Свободно >^n", ++b) ;
		}

			
	}
	
	switch(g_iUserEditCostume[pId])
	{
		case false: FormatItem("^n\y9. \yРедактировать^n") ;
		case true: FormatItem("^n\y9. \yОтменить редактирование^n") ;
	}


	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_BACK"), iBitKeys |= (1<<9);

	return show_menu(pId, iBitKeys, szMenu, -1, "Show_ChoosenHats");
}

public Handle_ChoosenHats(pId, iKey)
{
	switch(iKey)
	{	
		
		case 8: 
		{	
			g_iUserEditCostume[pId] = !g_iUserEditCostume[pId];
			switch(g_iUserEditCostume[pId])
			{
				case true: UTIL_SayText(pId, "!g[Hats]!y Режим редактирование избранных шапок активирован");
				case false: UTIL_SayText(pId, "!g[Hats]!y Режим редактирование избранных шапок отключен");
			}
		}
		case 9: return Show_MainCostumeMenu(pId);
		default: 
		{
			if(g_iUserEditCostume[pId])
			{
				g_iUserMenuKey[pId] = iKey;
				return Show_MainCostumeMenu(pId);
			}
			else
			{
				iCostumesIndex[pId] = g_iUserChoosenHats[pId][CHOOSEN_TYPE][iKey];
				
				if(iCostumesIndex[pId] == COSTUMES_PAID)
				{
						if(!get_login(pId))
						{
							UTIL_SayText(pId, "!g[Hats]!y Для доступа к платных шапках требуется вход в ЛК");
							return PLUGIN_HANDLED;
						}
						new login[MAX_NAME_LENGTH];
						get_login_len(pId, login, charsmax(login));
						
						new HatsInfo[UserInfo];
						new g_sUser[UserInfo]
			
						for( new i = 0; i < ArraySize( g_aUsers ); i++ )
						{
							ArrayGetArray(g_aUsers, i, g_sUser);
							if(equal(login, g_sUser[ArrayLogin]) )
							{
								if(g_sUser[ArrayCostumeID] == g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey])
								{
									if(get_systime() <= g_sUser[ArrayTime])
									{
										HatsInfo[ArrayCostumeID] = g_sUser[ArrayCostumeID];
										HatsInfo[ArrayTime] = g_sUser[ArrayTime];
									}
								}

							}
						}
						if(get_systime() <= HatsInfo[ArrayTime])
						{
							jbe_set_user_costumes(pId, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey]);
									
							new aDataCostumes[DATA_COSTUMES_PRECACHE];
							if(g_eUserCostumes[pId][COSTUMES] > EMPTYCOSTUMES) 
							{
								ArrayGetArray(g_aCostumesList_Array2, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey], aDataCostumes);
								
								if(strlen(g_eUserCostumes[pId][OLDCOSTUMES]) && (!equal(g_eUserCostumes[pId][OLDCOSTUMES], aDataCostumes[NAME_COSTUME])))
								UTIL_SayText(pId, "!g[Hats]!y Вы сняли шапку !g%s !yи надели !g%s", g_eUserCostumes[pId][OLDCOSTUMES], aDataCostumes[NAME_COSTUME]);
								else
								UTIL_SayText(pId, "!g[Hats]!y Выбрана шапка: !g%s", aDataCostumes[NAME_COSTUME]);
								
								formatex(g_eUserCostumes[pId][OLDCOSTUMES], charsmax(g_eUserCostumes[]), "%s", aDataCostumes[NAME_COSTUME]);
							}
						}
						else
						{
							new aDataCostumes[DATA_COSTUMES_PRECACHE];
							ArrayGetArray(g_aCostumesList_Array2, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey], aDataCostumes);
							UTIL_SayText(pId, "!g* !yШапка - !g%s !yплатная, хотите купить?", aDataCostumes[NAME_COSTUME]);
							g_iUserBuyHats[pId] = g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey];
							return Show_BuyCostumes(pId);
						}
						
						return Show_ChoosenHats(pId);
					
				}
				if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey] != iCostumesIndex[pId])
				{
					jbe_set_user_costumes(pId, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey]);
					new aDataCostumes[DATA_COSTUMES_PRECACHE];
					switch(g_iUserChoosenHats[pId][CHOOSEN_TYPE][iKey])
					{
						case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey], aDataCostumes);
						case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][iKey], aDataCostumes);
					}
					if(strlen(g_eUserCostumes[pId][OLDCOSTUMES]) && (!equal(g_eUserCostumes[pId][OLDCOSTUMES], aDataCostumes[NAME_COSTUME])))
					UTIL_SayText(pId, "!g[Hats]!y Вы сняли шапку !g%s !yи надели !g%s", g_eUserCostumes[pId][OLDCOSTUMES], aDataCostumes[NAME_COSTUME]);
					else
					UTIL_SayText(pId, "!g[Hats]!y Выбрана шапка: !g%s", aDataCostumes[NAME_COSTUME]);
					
					formatex(g_eUserCostumes[pId][OLDCOSTUMES], charsmax(g_eUserCostumes[]), "%s", aDataCostumes[NAME_COSTUME]);
				}else jbe_set_user_costumes(pId, EMPTYCOSTUMES);
				
			}
		}
	}
	return Show_ChoosenHats(pId);

}



public Cmd_FirstCostumeMenu(id, CostumesTypes) 
{
	iCostumesIndex[id] = CostumesTypes;
	return Show_FirstCostumeMenu(id, g_iMenuPosition[id] = 0);
}
Show_FirstCostumeMenu(pId, iPos)
{
	#if defined ADDON_BACK_MENU
	if(iPos < 0) return Show_MainCostumeMenu(pId);
	#else
	if(iPos < 0) return PLUGIN_HANDLED;
	#endif
	
	if(jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2 || jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	
	new iSize;
	switch(iCostumesIndex[pId])
	{
		case COSTUMES_FREE: iSize = g_iCostumesListSize[COSTUMES_FREE];
		case COSTUMES_PAID: iSize = g_iCostumesListSize[COSTUMES_PAID];
	
	}
	
	if(!iSize)
	{
		UTIL_SayText(pId, "!g* !yДанный раздел шапок временно недоступны");
		return PLUGIN_HANDLED;

	}

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iSize) iStart = iSize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd;

	if(!iPos)
	{
		if(iSize < PLAYERS_PER_PAGE)
		{
			iEnd = iStart + iSize;
		} else iEnd = iStart + PLAYERS_PER_PAGE;
	}
	else iEnd = iStart + PLAYERS_PER_PAGE;

	if(iEnd > iSize) iEnd = iSize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (iSize / PLAYERS_PER_PAGE + ((iSize % PLAYERS_PER_PAGE) ? 1 : 0));
	new aDataCostumes[DATA_COSTUMES_PRECACHE];
	if(g_eUserCostumes[pId][COSTUMES] > EMPTYCOSTUMES && g_eUserCostumes[pId][TYPE] == iCostumesIndex[pId] ) 
	{
		if(g_eUserCostumes[pId][COSTUMES] > iSize)
		{
			//g_eUserCostumes[pId][COSTUMES] = iCostumesIndex[pId];
			return Cmd_FirstCostumeMenu(pId, iCostumesIndex[pId]);
		}
		switch(iCostumesIndex[pId])
		{
			case COSTUMES_FREE:ArrayGetArray(g_aCostumesList_Array1, g_eUserCostumes[pId][COSTUMES], aDataCostumes);
			case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_eUserCostumes[pId][COSTUMES], aDataCostumes);
		}
		FormatMain("\wВыберите костюм \r[%d|%d]^n\dНа вас сейчас: %s^n^n", iPos + 1, iPagesNum, aDataCostumes[NAME_COSTUME]);
	} else FormatMain("\wВыберите костюм \r[%d|%d]^n\dНа вас сейчас: Нет шапки^n^n", iPos + 1, iPagesNum);
	new iBitKeys = (1<<9), b;
	//new iFlags = get_user_flags(pId);
	new name[32]
	get_user_name(pId,name,charsmax(name));
	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(pId, szAuth, MAX_AUTHID_LENGTH - 1);
	new login[MAX_NAME_LENGTH];
	get_login_len(pId, login, charsmax(login));
	
	new g_sUser[UserInfo]
	for(new a = iStart; a < iEnd; a++)
	{
		switch(iCostumesIndex[pId])
		{
			case COSTUMES_FREE: ArrayGetArray(g_aCostumesList_Array1, a, aDataCostumes);
			case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, a, aDataCostumes);
		}

				
	
		
		
		switch(iCostumesIndex[pId])
		{
			case COSTUMES_FREE:
			{
				
				if(g_eUserCostumes[pId][COSTUMES] != a)
				{
					if(aDataCostumes[FLAG_COSTUME])
					{
						if(IsEnablePlayer(pId, 0, aDataCostumes[FLAG_COSTUME]))
						{
							iBitKeys |= (1<<b);
							FormatItem("\y%d. \w%s \r%s^n", ++b, aDataCostumes[NAME_COSTUME], aDataCostumes[WARNING_MSG]);
						}
						else FormatItem("\y%d. \d%s \r%s^n", ++b, aDataCostumes[NAME_COSTUME], aDataCostumes[WARNING_MSG]);
					}
					else
					{
						iBitKeys |= (1<<b);
						FormatItem("\y%d. \w%s^n", ++b, aDataCostumes[NAME_COSTUME]);
					}
				}
				else 
				{
					iBitKeys |= (1<<b);
					if(g_eUserCostumes[pId][TYPE] != iCostumesIndex[pId])
					{
						FormatItem("\y%d. \w%s^n", ++b, aDataCostumes[NAME_COSTUME]);
					}else FormatItem("\y%d. \w%s \r[\yВыбрана\r]^n", ++b, aDataCostumes[NAME_COSTUME]);
				}
			}
			case COSTUMES_PAID:
			{
				new bool:Itype;
				if(g_eUserCostumes[pId][COSTUMES] != a)
				{
					iBitKeys |= (1<<b);
					for( new i = 0; i < ArraySize( g_aUsers ); i++ )
					{
						ArrayGetArray(g_aUsers, i, g_sUser);
						if(g_sUser[ArrayCostumeID] == a)
						{
							if(equal(login, g_sUser[ArrayLogin]) && get_systime() <= g_sUser[ArrayTime])
							{
								Itype = true;
								break;
							}
						}
					}
					if(Itype)
					{
						FormatItem("\y%d. \w%s^n", ++b, aDataCostumes[NAME_COSTUME]);
					}
					else
					FormatItem("\y%d. \w%s \r$^n", ++b, aDataCostumes[NAME_COSTUME]);
				}
				else 
				{
					iBitKeys |= (1<<b);
					if(g_eUserCostumes[pId][TYPE] != iCostumesIndex[pId])
					{
						
						FormatItem("\y%d. \w%s^n", ++b, aDataCostumes[NAME_COSTUME]);
					}else FormatItem("\y%d. \w%s \r[\yВыбрана\r]^n", ++b, aDataCostumes[NAME_COSTUME]);
				}
				
				
			}
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iSize)
	{
		iBitKeys |= (1<<8);
		
		#if defined ADDON_BACK_MENU
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
		#else
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
		#endif
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_FirstCostumeMenu");
}

public Handle_FirstCostumeMenu(id, iKey)
{
	if(jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_FirstCostumeMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_FirstCostumeMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new iCostumes = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(g_iUserEditCostume[id])
			{
				g_iUserChoosenHats[id][CHOOSEN_COSTUME][g_iUserMenuKey[id]]  = iCostumes;
				g_iUserChoosenHats[id][CHOOSEN_TYPE][g_iUserMenuKey[id]]  = iCostumesIndex[id];
				
				new aDataCostumes[DATA_COSTUMES_PRECACHE];
				switch(iCostumesIndex[id])
				{
					case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, iCostumes, aDataCostumes);
					case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, iCostumes, aDataCostumes);
				}
				UTIL_SayText(id, "!g[Hats]!y Вы успешно сохранили шапку !g%s !yв меню избранного", aDataCostumes[NAME_COSTUME]);
				
				return Show_ChoosenHats(id);
			}
			if(iCostumesIndex[id] == COSTUMES_PAID && iCostumes != EMPTYCOSTUMES)
			{
				if(!get_login(id))
				{
					UTIL_SayText(id, "!g[Hats]!y Для доступа к платных шапках требуется вход в ЛК");
					return PLUGIN_HANDLED;
				}
				new login[MAX_NAME_LENGTH];
				get_login_len(id, login, charsmax(login));
				
				new HatsInfo[UserInfo];
				new g_sUser[UserInfo]
	
				for( new i = 0; i < ArraySize( g_aUsers ); i++ )
				{
					ArrayGetArray(g_aUsers, i, g_sUser);
					if(equal(login, g_sUser[ArrayLogin]) )
					{
						if(g_sUser[ArrayCostumeID] == iCostumes)
						{
							if(get_systime() <= g_sUser[ArrayTime])
							{
								HatsInfo[ArrayCostumeID] = g_sUser[ArrayCostumeID];
								HatsInfo[ArrayTime] = g_sUser[ArrayTime];
							}
						}

					}
				}
				if(get_systime() <= HatsInfo[ArrayTime])
				{
					if(g_eUserCostumes[id][COSTUMES] != iCostumes)
					{
						jbe_set_user_costumes(id, iCostumes);
								
						new aDataCostumes[DATA_COSTUMES_PRECACHE];
						if(g_eUserCostumes[id][COSTUMES] > EMPTYCOSTUMES) 
						{
							switch(iCostumesIndex[id])
							{
								case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, g_eUserCostumes[id][COSTUMES], aDataCostumes);
								case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_eUserCostumes[id][COSTUMES], aDataCostumes);
							}
							if(strlen(g_eUserCostumes[id][OLDCOSTUMES]) && (!equal(g_eUserCostumes[id][OLDCOSTUMES], aDataCostumes[NAME_COSTUME])))
							UTIL_SayText(id, "!g[Hats]!y Вы сняли шапку !g%s !yи надели !g%s", g_eUserCostumes[id][OLDCOSTUMES], aDataCostumes[NAME_COSTUME]);
							else
							UTIL_SayText(id, "!g[Hats]!y Выбрана шапка: !g%s", aDataCostumes[NAME_COSTUME]);
							
							formatex(g_eUserCostumes[id][OLDCOSTUMES], charsmax(g_eUserCostumes[]), "%s", aDataCostumes[NAME_COSTUME]);
						}
					}
					else jbe_set_user_costumes(id, EMPTYCOSTUMES);
				}
				else
				{
					g_iUserBuyHats[id] = iCostumes;
					return Show_BuyCostumes(id);
				}
				
				return Show_FirstCostumeMenu(id, g_iMenuPosition[id]);
			}
			if(g_eUserCostumes[id][COSTUMES] != iCostumes)
			{
				jbe_set_user_costumes(id, iCostumes);
						
				new aDataCostumes[DATA_COSTUMES_PRECACHE];
				if(g_eUserCostumes[id][COSTUMES] > EMPTYCOSTUMES) 
				{
					switch(iCostumesIndex[id])
					{
						case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, g_eUserCostumes[id][COSTUMES], aDataCostumes);
						case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_eUserCostumes[id][COSTUMES], aDataCostumes);
					}
					
					if(strlen(g_eUserCostumes[id][OLDCOSTUMES]) && (!equal(g_eUserCostumes[id][OLDCOSTUMES], aDataCostumes[NAME_COSTUME])))
					UTIL_SayText(id, "!g[Hats]!y Вы сняли шапку !g%s !yи надели !g%s", g_eUserCostumes[id][OLDCOSTUMES], aDataCostumes[NAME_COSTUME]);
					else
					UTIL_SayText(id, "!g[Hats]!y Выбрана шапка: !g%s", aDataCostumes[NAME_COSTUME]);
					
					formatex(g_eUserCostumes[id][OLDCOSTUMES], charsmax(g_eUserCostumes[]), "%s", aDataCostumes[NAME_COSTUME]);
				}
			}
			else jbe_set_user_costumes(id, EMPTYCOSTUMES);
			return Show_FirstCostumeMenu(id, g_iMenuPosition[id]);
		}
	}
	return PLUGIN_HANDLED;
}

public Show_BuyCostumes(pId)
{
	new szMenu[512], iBitKeys, iLen;
	new aDataCostumes[DATA_COSTUMES_PRECACHE];
	switch(iCostumesIndex[pId])
	{
		case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, g_iUserBuyHats[pId], aDataCostumes);
		case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_iUserBuyHats[pId], aDataCostumes);
	}
	FormatMain("\yКупить шапку - %s?^n^n", aDataCostumes[NAME_COSTUME]);

	FormatItem("\y1. \w3 дня - \r%d$^n", COST_1), iBitKeys |= (1<<0);

	FormatItem("\y2. \w14 дней - \r%d$^n", COST_2), iBitKeys |= (1<<1);

	FormatItem("\y3. \w30 дней - \r%d$^n", COST_3), iBitKeys |= (1<<2);

	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iBitKeys |= (1<<9);

	return show_menu(pId, iBitKeys, szMenu, -1, "Show_BuyCostumes");
}

public Handle_BuyCostumes(pId, iKey)
{
	switch(iKey)
	{
		case 9: return PLUGIN_HANDLED;
		default:
		{
			if(!get_login(pId))
			{
				UTIL_SayText(pId, "!g[Hats]!y Для покупки авторизуйтеся!");
				return PLUGIN_HANDLED;
			}
			new iMoney;
			new iDays;
			switch(iKey)
			{
				case 0:
				{
					iMoney = COST_1;
					iDays = 3;
				}
				case 1:
				{
					iMoney = COST_2;
					iDays = 14;
				}
				case 2:
				{
					iMoney = COST_3;
					iDays = 31;
				}
			}
			
			if(jbe_get_butt(pId) < iMoney)
			{
				UTIL_SayText(pId, "!g[Hats]!y Недостаточно средств для покупки!");
				return PLUGIN_HANDLED;
			}
			jbe_set_butt(pId,jbe_get_butt(pId) - iMoney);
			new login[MAX_NAME_LENGTH];
			get_login_len(pId, login, charsmax(login));
			
			new BuyTime = (get_systime() + (iDays * 86400));
			new g_sUser[UserInfo], query[QUERY_LENGTH], que_len;
			new aDataCostumes[DATA_COSTUMES_PRECACHE];
			
			que_len += formatex(query[que_len], charsmax(query) - que_len, "INSERT INTO `%s` (`Login` , `TypeID`, `CostumesID`, `CostumesType`, `Time`) ", RANK_TABLE);
			que_len += formatex(query[que_len], charsmax(query) - que_len, "VALUES ('%s' , '8', '%d', '%d', '%d')", login, g_iUserBuyHats[pId], iCostumesIndex[pId], BuyTime);
			SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
			
			jbe_set_user_costumes(pId, g_iUserBuyHats[pId]);
			
			
			switch(iCostumesIndex[pId])
			{
				case COSTUMES_FREE:	ArrayGetArray(g_aCostumesList_Array1, g_iUserBuyHats[pId], aDataCostumes);
				case COSTUMES_PAID: ArrayGetArray(g_aCostumesList_Array2, g_iUserBuyHats[pId], aDataCostumes);
			}
			UTIL_SayText(pId, "!g[Hats]!y Вы успешно купили шапку: !g%s на %d дня(-ей)", aDataCostumes[NAME_COSTUME], iDays);
			
			g_sUser[ArrayCostumeID] = g_iUserBuyHats[pId];
			g_sUser[ArrayCostumeType] = iCostumesIndex[pId];
			g_sUser[ArrayTime] = BuyTime;
			
			copy(g_sUser[ArrayLogin], MAX_NAME_LENGTH - 1, login);
			ArrayPushArray(g_aUsers, g_sUser);
			return PLUGIN_HANDLED;
		}
	
	}

	return Show_BuyCostumes(pId);
}
public jbe_set_user_costumes(pPlayer, iCostumes)
{
	if(!zl_boss_map())
	{
		if(jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2) 
			return 0;
	}
	if(jbe_global_status(17) && jbe_get_user_team(pPlayer) == 1) 
	{
		UTIL_SayText(pPlayer, "!g[Hats]!y Включен глобальный запрет на шапки, шапка обнулена");
		return 0;
	}
	if(iCostumes > EMPTYCOSTUMES)
	{
		new aDataCostumes[DATA_COSTUMES_PRECACHE];

		switch(iCostumesIndex[pPlayer])
		{
			case COSTUMES_FREE: 
			{
				if(!g_iCostumesListSize[COSTUMES_FREE] || iCostumes >= g_iCostumesListSize[COSTUMES_FREE])
				{
					jbe_set_user_costumes(pPlayer, EMPTYCOSTUMES);
					return PLUGIN_HANDLED;
				}
				ArrayGetArray(g_aCostumesList_Array1, iCostumes, aDataCostumes);
			}
			case COSTUMES_PAID: 
			{
				if(!g_iCostumesListSize[COSTUMES_PAID] || iCostumes >= g_iCostumesListSize[COSTUMES_PAID])
				{
					jbe_set_user_costumes(pPlayer, EMPTYCOSTUMES);
					return PLUGIN_HANDLED;
				}
				ArrayGetArray(g_aCostumesList_Array2, iCostumes, aDataCostumes);
			}
		}

		if(!g_eUserCostumes[pPlayer][ENTITY])
		{
			if(strlen(aDataCostumes[MODEL_NAME]))
			{
				static iszFuncWall = 0;
				if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_eUserCostumes[pPlayer][ENTITY] = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_movetype, MOVETYPE_FOLLOW);
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_aiment, pPlayer);
				new szBuffer[128];
				format(szBuffer, charsmax(szBuffer), "models/jb_engine/costumes/%s.mdl", aDataCostumes[MODEL_NAME]);
				
				
				engfunc(EngFunc_SetModel, g_eUserCostumes[pPlayer][ENTITY], szBuffer);
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_body, str_to_num(aDataCostumes[SUB_MODEL]));
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 0);
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_animtime, get_gametime());
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_framerate, 1.0);
				
				

				#if defined ENT_DEBUG
				static szClassname[32];
				engfunc(EngFunc_SzFromIndex, g_eUserCostumes[pPlayer][ENTITY], szClassname, 31)
				server_print("************** CreateEntity: %s | %d *****", szClassname, g_eUserCostumes[pPlayer][ENTITY]);
				#endif
			}
			else
			{
				g_eUserCostumes[pPlayer][ENTITY] = 0;
				g_eUserCostumes[pPlayer][HIDE] = 0;
				g_eUserCostumes[pPlayer][COSTUMES] = EMPTYCOSTUMES;
				g_eUserCostumes[pPlayer][TYPE] = 0;
				g_eUserCostumes[pPlayer][OLDCOSTUMES] = EOS;
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo, get_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo) & ~MaskEnt(1));
			
			}
		}
		else 
		{
			if(strlen(aDataCostumes[MODEL_NAME]))
			{
				new szBuffer[128];
				format(szBuffer, charsmax(szBuffer), "models/jb_engine/costumes/%s.mdl", aDataCostumes[MODEL_NAME]);
				engfunc(EngFunc_SetModel, g_eUserCostumes[pPlayer][ENTITY], szBuffer);
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_body, str_to_num(aDataCostumes[SUB_MODEL]));

				#if defined ENT_DEBUG
				static szClassname[32];
				engfunc(EngFunc_SzFromIndex, g_eUserCostumes[pPlayer][ENTITY], szClassname, 31)
				server_print("************** CreateEntity: %s | %d *****", szClassname, g_eUserCostumes[pPlayer][ENTITY]);
				#endif
			}
			else
			{
				if(is_entity(g_eUserCostumes[pPlayer][ENTITY]))
					engfunc(EngFunc_RemoveEntity, g_eUserCostumes[pPlayer][ENTITY]);
				g_eUserCostumes[pPlayer][ENTITY] = 0;
				g_eUserCostumes[pPlayer][HIDE] = 0;
				g_eUserCostumes[pPlayer][COSTUMES] = EMPTYCOSTUMES;
				g_eUserCostumes[pPlayer][TYPE] = 0;
				g_eUserCostumes[pPlayer][OLDCOSTUMES] = EOS;
				set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo, get_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo) & ~MaskEnt(1));
				return 1;
			}
		}
		set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo, get_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo) | MaskEnt(1));
		g_eUserCostumes[pPlayer][HIDE] = 0;
		g_eUserCostumes[pPlayer][COSTUMES] = iCostumes;
		g_eUserCostumes[pPlayer][TYPE] = iCostumesIndex[pPlayer];
		
		
		
		//server_print("%d | %d", iCostumes, iCostumesIndex[pPlayer]);
		
		return 1;
		
	}
	else if(g_eUserCostumes[pPlayer][COSTUMES] > EMPTYCOSTUMES)
	{

		if(g_eUserCostumes[pPlayer][ENTITY]) engfunc(EngFunc_RemoveEntity, g_eUserCostumes[pPlayer][ENTITY]);
		g_eUserCostumes[pPlayer][ENTITY] = 0;
		g_eUserCostumes[pPlayer][HIDE] = 0;
		g_eUserCostumes[pPlayer][COSTUMES] = EMPTYCOSTUMES;
		g_eUserCostumes[pPlayer][TYPE] = 0;
		g_eUserCostumes[pPlayer][OLDCOSTUMES] = EOS;
		set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo, get_entvar(g_eUserCostumes[pPlayer][ENTITY], var_groupinfo) & ~MaskEnt(1));
		return 1;
	}
	
	return 0;
}

public jbe_hide_user_costumes(pPlayer)
{
	if(g_eUserCostumes[pPlayer][ENTITY])
	{
		if(is_entity(g_eUserCostumes[pPlayer][ENTITY]))
			engfunc(EngFunc_RemoveEntity, g_eUserCostumes[pPlayer][ENTITY]);
		g_eUserCostumes[pPlayer][ENTITY] = 0;
		g_eUserCostumes[pPlayer][HIDE] = true;
		return 1;
	}
	return 0;
}


public RegsCoreApiLoaded(Handle:sqlTuple)
{
	g_hDQuery = sqlTuple;
	//get_cvar_string("jbe_mysql_sql_save_table",			RANK_TABLE, 		charsmax(RANK_TABLE));
	
	SQL_SetCharset(g_hDQuery, "utf8");
	
	new query[QUERY_LENGTH * 2] = "", que_len;
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
		CREATE TABLE IF NOT EXISTS `%s` \
		(\
			`id` INT(11) NOT NULL AUTO_INCREMENT,\
			`Login` VARCHAR(32) NOT NULL DEFAULT '',\
			`TypeID` INT(11) NOT NULL,\
			`CostumesID` INT(11) NOT NULL,\
			`CostumesType` INT(11) NOT NULL,\
			`Time` INT(11) NOT NULL,\
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci'\
		ENGINE=InnoDB\
	;", RANK_TABLE
	);
	
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
}


public IgnoreHandle(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{
    switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szText[128];
			new lastQue[QUERY_LENGTH]
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			if(datalen) log_to_file("mysqlt.log", "Query state: %d", data[0]);
			log_to_file("mysqlt.log","[Regs_Save]  %s", szText)
			log_to_file("mysqlt.log","%s",err)
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_to_file("mysqlt.log","%s", lastQue)
			return PLUGIN_CONTINUE;
		}
	}
	SQL_FreeHandle(query);
    return PLUGIN_CONTINUE;
}

public selectQueryHandler(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{

			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);

			new lastQue[QUERY_LENGTH], szText2[128];
			formatex(szText2, charsmax(szText2), "[Regs_Save]");
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_amx("%s",szText2)
			log_amx("[ SQL ] %s",lastQue)

			return;
		}
	}
	
	
	switch(data[EXT_DATA__SQL])
	{
		case SQL_LOAD: 
		{
			new id = data[EXT_DATA__INDEX];
			if(SQL_NumResults(query)) 
			{
				while (SQL_MoreResults(query)) 
				{
					new g_sUser[UserInfo]
					new iType = SQL_ReadResult(query, SQL_FieldNameToNum(query,"TypeID"));
					new iCostumeID = SQL_ReadResult(query, SQL_FieldNameToNum(query,"CostumesID"));
					new iCostumesType = SQL_ReadResult(query, SQL_FieldNameToNum(query,"CostumesType"));
					new iCostumeTime = SQL_ReadResult(query, SQL_FieldNameToNum(query,"Time"));
					if(iCostumeID > EMPTYCOSTUMES && iType <= 7)
					{
						g_iUserChoosenHats[id][CHOOSEN_COSTUME][iType] = iCostumeID;
						g_iUserChoosenHats[id][CHOOSEN_TYPE][iType] = iCostumesType;
						//g_iUserChoosenHats[id][CHOOSEN_TIME][iType] = iCostumeTime;
					}
					
					if(iType == 8)
					{
						SQL_ReadResult(query, SQL_FieldNameToNum(query,"Login"), g_sUser[ArrayLogin], charsmax(g_sUser[ArrayLogin]))
						g_sUser[ArrayCostumeID] = iCostumeID;
						g_sUser[ArrayCostumeType] = iCostumesType;
						g_sUser[ArrayTime] = iCostumeTime;
						
						//server_print("%s | %d", g_sUser[ArrayLogin], g_sUser[ArrayCostumeID]);
						//TrieSetString(g_aUsers,g_sUser[ArrayLogin], g_sUser)
						ArrayPushArray(g_aUsers, g_sUser);
						
						//server_print("%s | %d | Size: %d", g_sUser[ArrayLogin], g_sUser[ArrayCostumeID], ArraySize(g_aUsers));
						//ArrayPushArray(g_aUsers, g_sUser);
					}
					SQL_NextRow(query);
				}
			}
		}
	}
	return;
}


public jbe_regs_logout(pId, Login[])
{

	new query[QUERY_LENGTH], que_len;
	formatex(query,charsmax(query), "DELETE FROM `%s` WHERE `Login` = '%s' AND `TypeID` <= 7;", RANK_TABLE, Login);
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
	
	//formatex(query,charsmax(query), "");
	
	for(new i = 0; i < PLAYERS_PER_PAGE; i++)
	{
		if(g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i] > EMPTYCOSTUMES)
		{
			formatex(query,charsmax(query), "");
			que_len = 0;
			que_len += formatex(query[que_len], charsmax(query) - que_len, "INSERT INTO `%s` (`Login` , `TypeID`, `CostumesID`, `CostumesType`, `Time`) ", RANK_TABLE);
			que_len += formatex(query[que_len], charsmax(query) - que_len, "VALUES ('%s' , '%d', '%d', '%d', '%d')", Login, i, g_iUserChoosenHats[pId][CHOOSEN_COSTUME][i], g_iUserChoosenHats[pId][CHOOSEN_TYPE][i], g_iUserChoosenHats[pId][CHOOSEN_TIME][i]);
			SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
		}
	}
	new aData[ UserInfo ];
	
	for( new i = 0; i < ArraySize( g_aUsers ); i++ )
	{
		ArrayGetArray(g_aUsers, i, aData);
		if(equal(aData[ArrayLogin], Login))
		{
			ArrayDeleteItem( g_aUsers, i );
		}
	}
}

public jbe_regs_register(pId, Login[])
{
	new query[QUERY_LENGTH], que_len;
	que_len += formatex(query[que_len],charsmax(query) - que_len,"INSERT INTO `%s` (`Login`) VALUES ('%s');", RANK_TABLE, Login);
	
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
}

public jbe_regs_load_user(pId, Login[])
{
	new query[QUERY_LENGTH];
	formatex(query,charsmax(query),"SELECT * FROM `%s` WHERE `Login` = '%s'", RANK_TABLE, Login);
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_LOAD;
	sData[EXT_DATA__INDEX] = pId;
	sData[EXT_DATA__USERID] = get_user_userid(pId);
	copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, Login);
	SQL_ThreadQuery(g_hDQuery, "selectQueryHandler", query, sData, sizeof sData);
}


stock IsEnablePlayer(id,cms_mod,is_ACCESS[])
{
	mode_only=0;
	if(cms_mod == 1)
	{
		/*static Array:Services;
		Services = cmsapi_get_user_services(id, "", is_ACCESS);
		
		static AccessPass;
		AccessPass = cmsapi_check_service_password(id, is_ACCESS)
		

		if(Services && AccessPass)
		{
			return 1;
		}
		return 0;*/
	}
	if(get_user_flags(id) & read_flags(is_ACCESS) && !(strfind( is_ACCESS, "STEAM" ) != -1))
	{
		mode_only=1;
	}
	if(equal(is_ACCESS,"STEAM") && g_iUserSteam[id])
	{
		mode_only=1;
	} 
	return mode_only;
}
	
stock bool:check_steam( id )
{ 
	return has_reunion( ) ? ( REU_GetAuthtype( id ) == CA_TYPE_STEAM ) : true;
}