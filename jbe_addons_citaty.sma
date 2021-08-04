#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <center_msg_fix>
#include <jbe_core>
//new g_iGlobalDebug;
//#include <util_saytext>
//#include <1colorchat>

#define MAX_COUNT			5
#define BLOCK_TIME			90
#define BLOCK_USER_TIME			6
#define COST_BUTT			30




#define PLAYERS_PER_PAGE 8
#define INDEX_PER_PAGE 6

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

new g_pSpriteBall;
static Float: fCurTime;
static Float: fCurPlayerTime;

native get_login(pId);
native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);

new g_iMenuPosition[MAX_PLAYERS + 1];
new g_iPlayerQuotes[MAX_PLAYERS + 1][64];
new Array:g_aQuotesArray;
new g_iQuotesListSize;

new g_iSaveUserQuotes[MAX_PLAYERS + 1][64];
new g_iCountUsed;
enum _:DATA_QUOTES_PRECACHE
{
	QUOTES_SOUND[32],
	QUOTES_INDEX,
	QUOTES_NAME[64]
}

public plugin_init()
{
	register_plugin("[JBE] Citaty", "1.0.0", "DalgaPups");
	//register_clcmd("say /quot", "OpenMainMenu");
	//register_clcmd("say /izb", "OpenFavoritesMenu");
	
	register_menucmd(register_menuid("Show_OsnovaMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_OsnovaMenu");
	register_menucmd(register_menuid("Show_MainMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainMenu");
	register_menucmd(register_menuid("Show_FavoritesMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_IzbMenu");
	register_menucmd(register_menuid("Show_EditMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_EditMenu");
	
	//g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	register_clcmd("radio1", "ClCmd_Radio1");
	
	//plugin_init_second();
}

public ClCmd_Radio1(pId)
{
	if(jbe_get_day_mode() < 3)
	{
		return Show_OsnovaMenu(pId);
	}
	return PLUGIN_HANDLED;
	
	
}

Show_OsnovaMenu(pId)
{
	new szMenu[512], iLen, iKey;
	
	FormatMain("\yЦитата^n^n");
	
	FormatItem("\y1. \wВесь список цитат^n"), iKey |= (1<<0);
	FormatItem("\y2. \wИзбранные цитаты^n"), iKey |= (1<<1);
	
	FormatItem("^n^n^n^n^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKey |= (1<<9);
	
	return show_menu(pId, iKey, szMenu, -1, "Show_OsnovaMenu");
}

public Handle_OsnovaMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: return OpenMainMenu(pId);
		case 1: return OpenFavoritesMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_OsnovaMenu(pId);
}

public plugin_precache()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/quotes/quotes.ini", szCfgDir);
	if(file_exists(szCfgFile))
	{
		new aDataQuotesRead[DATA_QUOTES_PRECACHE], szBuffer[256], iLine, iLen;
		g_aQuotesArray = ArrayCreate(DATA_QUOTES_PRECACHE);
		while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
		{
			if(!iLen || szBuffer[0] == ';') continue;
			parse
			(
				szBuffer, 
				aDataQuotesRead[QUOTES_SOUND], 		charsmax(aDataQuotesRead[QUOTES_SOUND]), 
				aDataQuotesRead[QUOTES_NAME],			charsmax(aDataQuotesRead[QUOTES_NAME])
			);
			aDataQuotesRead[QUOTES_INDEX]++;
			format(szBuffer, charsmax(szBuffer), "jb_engine/frallion/%s.wav", aDataQuotesRead[QUOTES_SOUND]);
			
			new szFile[256];
			formatex(szFile, charsmax(szFile), "sound/%s", szBuffer);
			if(file_exists(szFile)) 
			{
				engfunc(EngFunc_PrecacheSound, szBuffer);
				ArrayPushArray(g_aQuotesArray, aDataQuotesRead);
			}
			else
			{
				log_amx("ERROR!:Не найден звук: %s" , aDataQuotesRead[QUOTES_SOUND]);
			}
			
			
		}
		g_iQuotesListSize = ArraySize(g_aQuotesArray);
	}
	else
	{
		log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		set_fail_state("File ^"%s^" not found!", szCfgFile)
	}
	
	g_pSpriteBall = engfunc(EngFunc_PrecacheModel, "sprites/radio.spr");
}

public OpenMainMenu(pId) return Show_MainMenu(pId, g_iMenuPosition[pId] = 0);

Show_MainMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	if(!g_iQuotesListSize) return PLUGIN_HANDLED;
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iQuotesListSize) iStart = g_iQuotesListSize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iQuotesListSize) iEnd = g_iQuotesListSize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_iQuotesListSize / PLAYERS_PER_PAGE + ((g_iQuotesListSize % PLAYERS_PER_PAGE) ? 1 : 0));
	new aDataQuotes[DATA_QUOTES_PRECACHE];

	FormatMain("\yВыберите цитату \d[%d|%d]^nЦена: %d бчк.^n^n", iPos + 1, iPagesNum , jbe_is_user_alive(pId) ? COST_BUTT : 0);
	new iBitKeys = (1<<9), b;
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aQuotesArray, a, aDataQuotes);
		
		
		iBitKeys |= (1<<b);
		FormatItem("\y%d. \w%s^n" , ++b, aDataQuotes[QUOTES_NAME]);
		
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_iQuotesListSize)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_MainMenu");
}

public Handle_MainMenu(pId, iKey)
{

	switch(iKey)
	{
		case 8: return Show_MainMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_MainMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iSprites = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			
			if(jbe_is_user_alive(pId))
			{
				if(get_gametime() < fCurTime)
				{
					CenterMsgFix_PrintMsg(pId, print_center, "До следующего цитат: %.f секунд",fCurTime - get_gametime());
					return Show_MainMenu(pId , g_iMenuPosition[pId]);
				}
				if(get_gametime() < fCurPlayerTime)
				{
					CenterMsgFix_PrintMsg(pId, print_center, "Анти-Флуд цитат, ждите: %.f секунд",fCurPlayerTime - get_gametime());
					return Show_MainMenu(pId , g_iMenuPosition[pId]);
				}
				
				
				emit_startquotes(pId, iSprites);
			}
			else
			{
				emit_startquotes_dead(pId, iSprites);
			}
		}
	}
	return Show_MainMenu(pId, g_iMenuPosition[pId]);
}

public emit_startquotes(index, iSprites)
{
	if(!jbe_is_user_alive(index) || jbe_get_day_mode() == 3) return PLUGIN_HANDLED;
	
	if(!get_login(index))
	{
		client_print_color(index, print_team_default, "^x01Вы должны быть авторизованы (say /reg)");
		return PLUGIN_HANDLED;
	}
	
	if(jbe_get_butt(index) < COST_BUTT)
	{
		client_print_color(index, print_team_default, "^x01Недостаточно средств для воспроизвидение цитат");
		return PLUGIN_HANDLED;
	}
	new aDataSprites[DATA_QUOTES_PRECACHE];
	ArrayGetArray(g_aQuotesArray, iSprites, aDataSprites);
	new szBuffer[256];
	format(szBuffer, charsmax(szBuffer), "jb_engine/frallion/%s.wav", aDataSprites[QUOTES_SOUND]);

	rh_emit_sound2(index, 0, CHAN_AUTO, szBuffer, VOL_NORM, ATTN_NORM);
	jbe_set_butt(index, jbe_get_butt(index) - COST_BUTT);
	//UTIL_SayText(0, "!b%n: %s", index, aDataSprites[QUOTES_NAME]);
	client_print_color(0, print_team_grey, "^x04*^x03%n: %s", index, aDataSprites[QUOTES_NAME]);
	//colorchat(0, GREY, "!b%n: %s", index, aDataSprites[QUOTES_NAME]);
	g_iCountUsed++;
	fCurPlayerTime = get_gametime() + BLOCK_USER_TIME;
	if(g_iCountUsed > MAX_COUNT)
	{
		g_iCountUsed = 0;
		fCurTime = get_gametime() + BLOCK_TIME;
	}
	CREATE_PLAYERATTACHMENT(index, _, g_pSpriteBall, 30);
	//server_print("spk %s", szBuffer);
	return PLUGIN_HANDLED;
}

public emit_startquotes_dead(index, iSprites)
{
	if(jbe_is_user_alive(index) || jbe_get_day_mode() == 3) return PLUGIN_HANDLED;
	
	new aDataSprites[DATA_QUOTES_PRECACHE];
	ArrayGetArray(g_aQuotesArray, iSprites, aDataSprites);
	new szBuffer[64];
	format(szBuffer, charsmax(szBuffer), "jb_engine/frallion/%s.wav", aDataSprites[QUOTES_SOUND]);
	rh_emit_sound2(index, index, CHAN_AUTO, szBuffer, VOL_NORM, ATTN_NORM, SND_STOP);
	rh_emit_sound2(index, index, CHAN_AUTO, szBuffer, VOL_NORM, ATTN_NORM);

	client_print_color(index, print_team_grey, "^x04*^x03%n: %s (слышите только вы сами)", index, aDataSprites[QUOTES_NAME]);
	return Show_MainMenu(index, g_iMenuPosition[index]);
}

public OpenFavoritesMenu(pId) return Show_FavoritesMenu(pId, g_iMenuPosition[pId] = 0);

Show_FavoritesMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	if(!g_iQuotesListSize) return PLUGIN_HANDLED;
	new iStart = iPos * INDEX_PER_PAGE;
	if(iStart > g_iQuotesListSize) iStart = g_iQuotesListSize;
	iStart = iStart - (iStart % INDEX_PER_PAGE);
	g_iMenuPosition[pId] = iStart / INDEX_PER_PAGE;
	new iEnd = iStart + INDEX_PER_PAGE;
	if(iEnd > g_iQuotesListSize) iEnd = g_iQuotesListSize + (iPos ? 0 : 1);
	new szMenu[512], iLen;
	new aDataQuotes[DATA_QUOTES_PRECACHE];
	new iBitKeys = (1<<7 | 1<<9), b;
	
	FormatMain("\yИзбранные цитаты^nЦена: %d бчк.^n^n", jbe_is_user_alive(pId) ? COST_BUTT : 0);
	
	for(new a = 0; a < g_iQuotesListSize; a++)
	{
		if(g_iPlayerQuotes[pId][a] == 0) continue;

		ArrayGetArray(g_aQuotesArray, a, aDataQuotes);
			
		
		if(g_iPlayerQuotes[pId][a] != str_to_num(aDataQuotes[QUOTES_INDEX])) continue;
		
		
		iBitKeys |= (1<<b);
		g_iSaveUserQuotes[pId][b] = g_iPlayerQuotes[pId][a];
		FormatItem("\y%d. \w%s^n", ++b, aDataQuotes[QUOTES_NAME]);
		
	}
	
	for(new i = b; i < INDEX_PER_PAGE; i++) FormatItem("^n");
	FormatItem("^n^n\y8. \wРедактировать^n");
	FormatItem("\y0. \w%L", pId, "JBE_MENU_EXIT");
	
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_FavoritesMenu");
}

public Handle_IzbMenu(pId, iKey) 
{
	switch(iKey)
	{
		case 9: return Show_MainMenu(pId, g_iMenuPosition[pId] = 0);
		case 7: 
		{

			return Show_EditMenu(pId, g_iMenuPosition[pId] = 0);
		}
		default:
		{
			if(get_gametime() < fCurTime)
			{
				CenterMsgFix_PrintMsg(pId, print_center, "До следующего цитат: %.f секунд",fCurTime - get_gametime());
				return Show_FavoritesMenu(pId , g_iMenuPosition[pId]);
			}
			if(get_gametime() < fCurPlayerTime)
			{
				CenterMsgFix_PrintMsg(pId, print_center, "Анти-Флуд цитат, ждите: %.f секунд",fCurPlayerTime - get_gametime());
				return Show_FavoritesMenu(pId , g_iMenuPosition[pId]);
			}
			
			new index = g_iMenuPosition[pId] * INDEX_PER_PAGE + iKey;
	
			//new aDataQuotes[DATA_QUOTES_PRECACHE];
		//	ArrayGetArray(g_aQuotesArray, g_iSaveUserQuotes[pId][index], aDataQuotes);
				
			emit_startquotes(pId, g_iSaveUserQuotes[pId][index] - 1);

		}
	}
	
	
	return Show_FavoritesMenu(pId, g_iMenuPosition[pId]);
	
}

public OpenEditMenu(pId) return Show_EditMenu(pId, g_iMenuPosition[pId] = 0);

Show_EditMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iStart = iPos * INDEX_PER_PAGE;
	if(iStart > g_iQuotesListSize) iStart = g_iQuotesListSize;
	iStart = iStart - (iStart % INDEX_PER_PAGE);
	g_iMenuPosition[pId] = iStart / INDEX_PER_PAGE;
	new iEnd = iStart + INDEX_PER_PAGE;
	if(iEnd > g_iQuotesListSize) iEnd = g_iQuotesListSize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_iQuotesListSize / INDEX_PER_PAGE + ((g_iQuotesListSize % INDEX_PER_PAGE) ? 1 : 0));
	new aDataQuotes[DATA_QUOTES_PRECACHE];

	FormatMain("\yВыставить в избранные \d[%d|%d]^n^n", iPos + 1, iPagesNum );
	new iBitKeys = (1<<7|1<<9), b;
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aQuotesArray, a, aDataQuotes);
		
		
		if(g_iPlayerQuotes[pId][a] == str_to_num(aDataQuotes[QUOTES_INDEX]))
		{
			iBitKeys |= (1<<b);
			FormatItem("\y%d. \w%s \y(Изб.)^n" , ++b, aDataQuotes[QUOTES_NAME]);
		}
		else
		{
			iBitKeys |= (1<<b);
			FormatItem("\y%d. \w%s^n" , ++b, aDataQuotes[QUOTES_NAME]);
		}
	}

	FormatItem("^n^n\y8. \wВернуться к избранным^n");
	
	if(iEnd < g_iQuotesListSize)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_EditMenu");
}

public Handle_EditMenu(pId, iKey)
{

	switch(iKey)
	{
		case 7: return Show_FavoritesMenu(pId, g_iMenuPosition[pId] = 0);
		case 8: return Show_EditMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_EditMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iSprites = g_iMenuPosition[pId] * INDEX_PER_PAGE + iKey;
			
			if(!g_iPlayerQuotes[pId][iSprites])
			{
				new aDataQuotes[DATA_QUOTES_PRECACHE];
				new TempDataCostumes[DATA_QUOTES_PRECACHE];
				ArrayGetArray(g_aQuotesArray, iSprites, aDataQuotes);
				
				new iCount = 0;
				for(new a = 0; a < g_iQuotesListSize; a++)
				{
					if(g_iPlayerQuotes[pId][a] == 0) continue;

					ArrayGetArray(g_aQuotesArray, a, TempDataCostumes);
						
					
					if(g_iPlayerQuotes[pId][a] != str_to_num(TempDataCostumes[QUOTES_INDEX])) continue;
					
					iCount++;
				}
				
				if(iCount >= 6)
				{
					CenterMsgFix_PrintMsg(pId, print_center, "Максимально можно хронить до 6 звуков!");
					return Show_EditMenu(pId, g_iMenuPosition[pId]);
				}
				g_iPlayerQuotes[pId][iSprites] = str_to_num(aDataQuotes[QUOTES_INDEX]);
				g_iSaveUserQuotes[pId][iSprites] = str_to_num(aDataQuotes[QUOTES_INDEX]);

				//server_print("%d | %d | %d", iCount, g_iPlayerQuotes[pId][iSprites], iSprites);
				return Show_EditMenu(pId, g_iMenuPosition[pId]);
			}else
			{
				g_iPlayerQuotes[pId][iSprites] = 0;
			}
			
		}
	}
	return Show_EditMenu(pId, g_iMenuPosition[pId]);
}

native jbe_mysql_stats_systems_get(pId, iType);
native jbe_mysql_stats_systems_add(pId, Act, iType);

forward jbe_save_stats(pid)
forward jbe_load_stats(pId)
//БД Форвард получение данных при путин
public jbe_load_stats(pId)
{
	new TempDataCostumes[DATA_QUOTES_PRECACHE];
	g_iSaveUserQuotes[pId][0] = jbe_mysql_stats_systems_get(pId, 7);
	g_iSaveUserQuotes[pId][1] = jbe_mysql_stats_systems_get(pId, 8);
	g_iSaveUserQuotes[pId][2] = jbe_mysql_stats_systems_get(pId, 9);
	g_iSaveUserQuotes[pId][3] = jbe_mysql_stats_systems_get(pId, 55);
	g_iSaveUserQuotes[pId][4] = jbe_mysql_stats_systems_get(pId, 56);
	g_iSaveUserQuotes[pId][5] = jbe_mysql_stats_systems_get(pId, 57);
	
	for(new a = 0; a < g_iQuotesListSize; a++)
	{
		ArrayGetArray(g_aQuotesArray, a, TempDataCostumes);
		
		if(g_iSaveUserQuotes[pId][0] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][0] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][0];
		if(g_iSaveUserQuotes[pId][1] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][1] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][1];
		if(g_iSaveUserQuotes[pId][2] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][2] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][2];
		if(g_iSaveUserQuotes[pId][3] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][3] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][3];
		if(g_iSaveUserQuotes[pId][4] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][4] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][4];
		if(g_iSaveUserQuotes[pId][5] == str_to_num(TempDataCostumes[QUOTES_INDEX]) && g_iSaveUserQuotes[pId][5] < g_iQuotesListSize)
			g_iPlayerQuotes[pId][a] = g_iSaveUserQuotes[pId][5];
	}

}
//БД Форвард передачи данных при диск
public jbe_save_stats(pId)
{
	jbe_mysql_stats_systems_add(pId, 7, g_iSaveUserQuotes[pId][0]);
	jbe_mysql_stats_systems_add(pId, 8, g_iSaveUserQuotes[pId][1]);
	jbe_mysql_stats_systems_add(pId, 9, g_iSaveUserQuotes[pId][2]);
	jbe_mysql_stats_systems_add(pId, 55, g_iSaveUserQuotes[pId][3]);
	jbe_mysql_stats_systems_add(pId, 56, g_iSaveUserQuotes[pId][4]);
	jbe_mysql_stats_systems_add(pId, 57, g_iSaveUserQuotes[pId][5]);
	
	for(new a = 0; a < g_iQuotesListSize; a++)
	{
		if(g_iPlayerQuotes[pId][a] == 0) continue;
		g_iPlayerQuotes[pId][a] = 0;
	}
	for(new a = 0; a < 6; a++)
	{
		g_iSaveUserQuotes[pId][a] = 0;
	}
}

stock CREATE_PLAYERATTACHMENT(pPlayer, iHeight = 50, pSprite, iLife)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(pPlayer);
	write_coord(iHeight);
	write_short(pSprite);
	write_short(iLife); // 0.1's
	message_end();
}
stock CREATE_KILLPLAYERATTACHMENTS(pPlayer)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(pPlayer);
	message_end();
}
