#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>
//#include <gamecms5>
#include <reapi>
new g_iGlobalDebug;
#include <util_saytext>

#pragma semicolon						1


#define PLAYERS_PER_PAGE 8
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))


#define PLUGIN_NAME						"[JBE] Addons GAMECMS API SKIN"
#define PLUGIN_VERSION					"1.4"
#define PLUGIN_AUTHOR					"DalgaPups"



/* -> Массивы для меню из игроков -> */
new g_iMenuPosition[MAX_PLAYERS + 1];

//#define TASK_ID_PLAYER_MODEL_FIXED 		100
forward jbe_fwr_set_user_model(pId);
new const CONFIGNAME[] 					= "/jb_engine/players_models.ini";
new const MODELSDIR[]					= "models/player";


const MAX_SIZE_PL_MODEL_DIR				= 64;
const MAX_SIZE_PL_MODEL_NAME			= 64;

native jbe_set_user_model_ex(pId, iType);
native jbe_is_user_lastid();
native jbe_get_soccergame();
native jbe_get_friendlyfire();
new g_iBitUserModel;

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

native jbe_globalnyizapret();

enum _: ENUM_DATA_PL_MODELS_INFO	{
	PL_MDL_SERVICES[35],
	PL_MDL_MODEL[MAX_SIZE_PL_MODEL_NAME],
	PL_MDL_NAME[64],
	PL_MDL_BODY[4],
	PL_MDL_ACCESS[4]
};

new g_iArrayPlayerModelSize;
new g_iPlayerUserModel[MAX_PLAYERS + 1][2];

new gp_szPersonalModels[MAX_PLAYERS+1][MAX_SIZE_PL_MODEL_NAME];

new Array: g_aPlayerModel;

/*================================================================================
 [PLUGIN]
=================================================================================*/
public plugin_init()	{
	/* [PLUGIN] */
	register_plugin(PLUGIN_AUTHOR, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	RegisterMenu("Show_MainSkinMenu", 					"Handle_Maincmd_openskinmenu");
	#undef RegisterMenu
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	register_clcmd("say /skin", "cmd_openskinmenu");
}

public plugin_natives()
{
	register_native("jbe_skin_openmenu", "cmd_openskinmenu", 1);
	
}

public cmd_openskinmenu(pId) 
{
	Cmd_SpawnPlayer(pId);
	return PLUGIN_HANDLED;
}
public plugin_precache()	
{
	g_aPlayerModel = ArrayCreate(ENUM_DATA_PL_MODELS_INFO);
	new szConfigFile[64]; get_configsdir(szConfigFile, sizeof(szConfigFile));

	add(szConfigFile, charsmax(szConfigFile), CONFIGNAME);
	
	if(!dir_exists(MODELSDIR))
	{
		log_amx("[WARN] Directory '%s' not found! Will be created automatically!", MODELSDIR);
		mkdir(MODELSDIR);
	}

	new iFile = fopen(szConfigFile, "rt");
	if(iFile)
	{
		new szLineBuffer[6 + 35 + MAX_SIZE_PL_MODEL_NAME], 
			szPrecache[MAX_SIZE_PL_MODEL_DIR + MAX_SIZE_PL_MODEL_NAME * 2];
		
		new aData[ENUM_DATA_PL_MODELS_INFO];
		
		while(!(feof(iFile))){
			fgets(iFile, szLineBuffer, charsmax(szLineBuffer));
			
			trim(szLineBuffer);
			//strtolower(szLineBuffer);
			
			if(!(szLineBuffer[0]) || szLineBuffer[0] == ';' || szLineBuffer[0] == '#')
			{
				continue;
			}
			
			new parseArgsNum = parse(szLineBuffer, 
				aData[PL_MDL_SERVICES], charsmax(aData[PL_MDL_SERVICES]),
				aData[PL_MDL_MODEL], charsmax(aData[PL_MDL_MODEL]),
				aData[PL_MDL_NAME], charsmax(aData[PL_MDL_NAME]),
				aData[PL_MDL_BODY], charsmax(aData[PL_MDL_BODY]),
				aData[PL_MDL_ACCESS], charsmax(aData[PL_MDL_ACCESS])
			);
			//log_amx("^nFILE_READ^nSERVICES: '%s'^nMODEL: '%s'^nNAME: '%s'^nBODY: '%s'^n",aData[PL_MDL_SERVICES], aData[PL_MDL_MODEL], aData[PL_MDL_NAME], aData[PL_MDL_BODY]);
			
			if(parseArgsNum < 4)
			{
				log_amx("Line '%s' not valid, will be skipped.", szLineBuffer);
				continue;
			}
			
			formatex(szPrecache, charsmax(szPrecache), "%s/%s/%s.mdl", MODELSDIR, aData[PL_MDL_MODEL], aData[PL_MDL_MODEL]);
			
			if(file_exists(szPrecache))
			{
				
				precache_model(szPrecache);
				
				ArrayPushArray(g_aPlayerModel, aData);
			}
			else
			{
				log_amx("[WARN] Model '%s' not found!", szPrecache);
			}
		}
		g_iArrayPlayerModelSize = ArraySize(g_aPlayerModel);

	} else 
	{
		new const szInstructions[] = 
		{
			"\
				; Instruction for use:^n\
			"
		};

		if(!file_exists(szConfigFile))
		{ 	
			log_amx("[WARNING] Config file ^"%s^" not found! Will be created automatically!", szConfigFile);

			if(!write_file(szConfigFile, szInstructions))
			{
				set_fail_state("[ERROR] Config file ^"%s^" not created! No access to write!", szConfigFile);
			}else{
				log_amx("Config File '%s' was created!", szConfigFile);
			}
		}
	}
	
	fclose(iFile);
}

public plugin_end(){
	ArrayDestroy(g_aPlayerModel);
}


public client_disconnected(pId)	
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		gp_szPersonalModels[pId] = "";
		g_iPlayerUserModel[pId][0] = -1;
		g_iPlayerUserModel[pId][1] = 1;
		ClearBit(g_iBitUserModel, pId);
	}
}



public Cmd_SpawnPlayer(pId) return Show_MainSkinMenu(pId, g_iMenuPosition[pId] = 0);
Show_MainSkinMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iArrayPlayerModelSize) iStart = g_iArrayPlayerModelSize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd;

	if(!iPos)
	{
		if(g_iArrayPlayerModelSize < PLAYERS_PER_PAGE)
		{
			iEnd = iStart + g_iArrayPlayerModelSize;
		} else iEnd = iStart + PLAYERS_PER_PAGE;
	}
	else iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iArrayPlayerModelSize) iEnd = g_iArrayPlayerModelSize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_iArrayPlayerModelSize / PLAYERS_PER_PAGE + ((g_iArrayPlayerModelSize % PLAYERS_PER_PAGE) ? 1 : 0));
	new aDataSkin[ENUM_DATA_PL_MODELS_INFO];

	FormatMain("\wВыберите Скин \r[%d|%d]^n^n^n", iPos + 1, iPagesNum);
	new iBitKeys = (1<<9), b;

	//ArrayGetArray(found, 0, g_Data);
	new szModel[64];
	jbe_get_user_model(pId,  szModel, 63);
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aPlayerModel, a, aDataSkin);
		
		iBitKeys |= (1<<b);
		if(cmsapi_get_user_services(pId, "", aDataSkin[PL_MDL_SERVICES], 0))
		{
			
			if(!equal(szModel, aDataSkin[PL_MDL_MODEL]))
			{
				FormatItem("\y%d. \w%s %s^n", ++b, aDataSkin[PL_MDL_NAME], str_to_num(aDataSkin[PL_MDL_ACCESS]) ? "\rДля девушек" : "");
			}
			else
			{
				if((strlen(aDataSkin[PL_MDL_BODY]) == 0 && g_iPlayerUserModel[pId][0] == a) || g_iPlayerUserModel[pId][0] == a)
				{
					FormatItem("\y%d. \w%s \y[Снять]^n", ++b, aDataSkin[PL_MDL_NAME]);
				}
				else
				{
					FormatItem("\y%d. \w%s %s^n", ++b, aDataSkin[PL_MDL_NAME], str_to_num(aDataSkin[PL_MDL_ACCESS]) ? "\rДля девушек" : "");
				}
			}
		}
		else FormatItem("\y%d. \d%s %s^n", ++b, aDataSkin[PL_MDL_NAME], str_to_num(aDataSkin[PL_MDL_ACCESS]) ? "\rДля девушек" : "");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < g_iArrayPlayerModelSize)
	{
		iBitKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_MainSkinMenu");
}

public Handle_Maincmd_openskinmenu(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_MainSkinMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_MainSkinMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			if(jbe_globalnyizapret() && jbe_get_user_team(pId) == 1)
			{
				UTIL_SayText(pId, "!g* !yСтоит глобальный режим, скин недоступен!");
				return PLUGIN_HANDLED;
			}
			if(jbe_is_user_lastid() || jbe_get_soccergame() || jbe_get_friendlyfire())
			{
				UTIL_SayText(pId, "!g* !yСейчас идет режим дуэли/футбол/бокс");
				return PLUGIN_HANDLED;
			}
			new iSkin = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			
			new aDataSkin[ENUM_DATA_PL_MODELS_INFO];
			ArrayGetArray(g_aPlayerModel, iSkin, aDataSkin);
			
			if(cmsapi_get_user_services(pId, "", aDataSkin[PL_MDL_SERVICES], 0))
			{
				if(str_to_num(aDataSkin[PL_MDL_ACCESS]) == 1 && !is_user_girl(pId))
				{
					UTIL_SayText(pId, "!g* !yРазве вы девушка?. Данный тип скина предназначены только для !gдевушек");
					return Cmd_SpawnPlayer(pId);
				}
				new szModel[64];
				jbe_get_user_model(pId,  szModel, 63);
				
				if(!equal(szModel, aDataSkin[PL_MDL_MODEL]))
				{
					
					formatex(gp_szPersonalModels[pId], charsmax(gp_szPersonalModels[]), aDataSkin[PL_MDL_MODEL]);
					jbe_set_user_model(pId, aDataSkin[PL_MDL_MODEL]);
					//server_print("%s | %d", aDataSkin[PL_MDL_BODY], str_to_num(aDataSkin[PL_MDL_BODY]));
					
					if(strlen(aDataSkin[PL_MDL_BODY]))
					{
						set_entvar(pId, var_body, str_to_num(aDataSkin[PL_MDL_BODY]));
						g_iPlayerUserModel[pId][1] = str_to_num(aDataSkin[PL_MDL_BODY]);
					}
					g_iPlayerUserModel[pId][0] = iSkin;
					SetBit(g_iBitUserModel, pId);
					
					
					if(jbe_is_user_free(pId))
					{
						jbe_set_user_rendering(pId, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 0);
					}
					else 
					if(jbe_is_user_wanted(pId))
					{
						jbe_set_user_rendering(pId, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
					
					}
				}
				else
				{
					jbe_set_default_model(pId);
				}
			}
			else
			{
				UTIL_SayText(pId, "!g* !yВы не купили данный скин, для покупки скина зайдите на сайт: !gFRAGGERS.RU");
				return Cmd_SpawnPlayer(pId);
			}
		}
	}
	return Show_MainSkinMenu(pId, g_iMenuPosition[pId]);
}

stock is_user_girl(pId)
{
	new szGirl[32];
	cmsapi_get_user_group(pId, szGirl, charsmax(szGirl));
	if(equal(szGirl, "Девушка"))
		return true;
		
	return false;
}

public jbe_fwr_set_user_model(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if((jbe_is_user_lastid() || jbe_get_soccergame() || jbe_globalnyizapret() || jbe_get_friendlyfire()) && jbe_get_user_team(pId) == 1)
		{
			return 0;
		}
		if(strlen(gp_szPersonalModels[pId]) > 0)
		{
			jbe_set_user_model(pId, gp_szPersonalModels[pId]);
			if(g_iPlayerUserModel[pId][1])
			{
				set_entvar(pId, var_body, g_iPlayerUserModel[pId][1]);
			}
		}
		else
		{
			gp_szPersonalModels[pId] = "";
			g_iPlayerUserModel[pId][0] = -1;
			g_iPlayerUserModel[pId][1] = 1;
		}
	}
	return 0;
}


stock jbe_set_default_model(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if(jbe_is_user_alive(pId))
		{
			jbe_set_user_model_ex(pId, jbe_get_user_team(pId));
			if(get_entvar(pId, var_renderfx) != kRenderFxNone || get_entvar(pId, var_rendermode) != kRenderNormal)
			{
				jbe_set_user_rendering(pId, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
			}
		}
		gp_szPersonalModels[pId] = "";
		g_iPlayerUserModel[pId][0] = -1;
		g_iPlayerUserModel[pId][1] = 1;
		ClearBit(g_iBitUserModel, pId);
	}
}
stock jbe_temp_default_model(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if(jbe_is_user_alive(pId))
		{
			jbe_set_user_model_ex(pId, jbe_get_user_team(pId));
			if(get_entvar(pId, var_renderfx) != kRenderFxNone || get_entvar(pId, var_rendermode) != kRenderNormal)
			{
				jbe_set_user_rendering(pId, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
			}
		}
	}
}

public jbe_lr_duels()
{
	for(new i; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || !jbe_is_user_alive(i)) continue;
		
		jbe_temp_default_model(i);
		UTIL_SayText(i, "!g* !yВаш личный скин сброшен, поскольку включен дуэльный режим");
	}

}

public jbe_reset_all_user_flags(bool:status)
{
	if(status)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
			
			jbe_temp_default_model(i);
			UTIL_SayText(i, "!g* !yВаш личный скин сброшен, поскольку включен глобальный режим");
		}
	}
}

public jbe_fwd_add_user_free(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if((jbe_is_user_lastid() || jbe_get_soccergame() || jbe_globalnyizapret()) && jbe_get_user_team(pId) == 1)
		{
			return 0;
		}
		jbe_set_user_model(pId, gp_szPersonalModels[pId]);
		if(g_iPlayerUserModel[pId][1])
		{
			set_entvar(pId, var_body, g_iPlayerUserModel[pId][1]);
		}
		jbe_set_user_rendering(pId, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 0);
	}
	return 0;
}

public jbe_fwd_add_user_wanted(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if((jbe_is_user_lastid() || jbe_get_soccergame() || jbe_globalnyizapret()) && jbe_get_user_team(pId) == 1)
		{
			return 0;
		}
		jbe_set_user_model(pId, gp_szPersonalModels[pId]);
		if(g_iPlayerUserModel[pId][1])
		{
			set_entvar(pId, var_body, g_iPlayerUserModel[pId][1]);
		}
		jbe_set_user_rendering(pId, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
	}
	return 0;
}

public jbe_fwd_sub_free_wanted(pId, iType)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		if((jbe_is_user_lastid() || jbe_get_soccergame() || jbe_globalnyizapret()) && jbe_get_user_team(pId) == 1)
		{
			return 0;
		}
		jbe_set_user_model(pId, gp_szPersonalModels[pId]);
		if(g_iPlayerUserModel[pId][1])
		{
			set_entvar(pId, var_body, g_iPlayerUserModel[pId][1]);
		}
		if(get_entvar(pId, var_renderfx) != kRenderFxNone || get_entvar(pId, var_rendermode) != kRenderNormal)
		{
			jbe_set_user_rendering(pId, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		}
	}
	return 0;
}

public jbe_soccer_start(bool:status)
{
	if(status)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
			
			jbe_temp_default_model(i);
			UTIL_SayText(i, "!g* !yВаш личный скин сброшен, поскольку включен футбольный режим");
		}
	}
}

public jbe_set_user_chief_fwd(pId)
{
	if(IsSetBit(g_iBitUserModel, pId))
	{
		jbe_set_user_model(pId, gp_szPersonalModels[pId]);
		if(g_iPlayerUserModel[pId][1])
		{
			set_entvar(pId, var_body, g_iPlayerUserModel[pId][1]);
		}
	}
}



public jbe_fwr_status_box()
{

	for(new i; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
		
		if(jbe_get_friendlyfire())
		{
			jbe_temp_default_model(i);
			UTIL_SayText(i, "!g* !yВаш личный скин сброшен, поскольку включен бокс");
		}
		else
		{
			if(jbe_globalnyizapret() || jbe_is_user_lastid() || jbe_get_soccergame()) continue;
			
			jbe_set_user_model(i, gp_szPersonalModels[i]);
			if(g_iPlayerUserModel[i][1])
			{
				set_entvar(i, var_body, g_iPlayerUserModel[i][1]);
				UTIL_SayText(i, "!g* !yВаш личный скин восстоновлен по скольку бокс был выключен");
			}
		}
	}
	
	/*if(jbe_get_friendlyfire())
	{
		for(new i; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
			
			jbe_temp_default_model(i);
			UTIL_SayText(i, "!g* !yВаш личный скин сброшен, поскольку включен бокс");
		}
	}
	else
	{
		for(new i; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserModel, i) || jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
			
			jbe_set_user_model(i, gp_szPersonalModels[i]);
			if(g_iPlayerUserModel[i][1])
			{
				set_entvar(i, var_body, g_iPlayerUserModel[i][1]);
				UTIL_SayText(i, "!g* !yВаш личный скин восстоновлен по скольку бокс был выключен");
			}
		}
	}*/
}