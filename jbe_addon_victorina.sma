#include <amxmodx>
#include <fakemeta>
#include <amxmisc>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define PLAYERS_PER_PAGE 	8
#define TASK_SHOW_INFORMER		67859098786

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1];
	
native jbe_open_main_menu(pId, iMenu);
new g_iPlayerToken[MAX_PLAYERS + 1]
new bool:g_iGameStart;
new  g_iSyncMainInformer;
public plugin_init()
{
	register_plugin("[JBE] Victorina", "1.0", "DalgaPups");
	
	
	register_clcmd("victorina", "open_victorinamenu");
	register_menucmd(register_menuid("Show_MainMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_MainMenu");
	register_menucmd(register_menuid("Show_ShowGiveToken"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_ShowGiveToken");
	register_menucmd(register_menuid("Show_ShowTakeToken"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_ShowTakeToken");
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	g_iSyncMainInformer = CreateHudSyncObj();
	
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
}

public open_victorinamenu(pId)
{
	if(jbe_is_user_chief(pId))
		return Show_MainMenu(pId);
	return PLUGIN_HANDLED;
}

public client_putinserver(pId)
{
	if(g_iGameStart)
	{
		g_iPlayerToken[pId] = 0;
	}

}
public client_disconnected(pId)
{
	if(g_iGameStart)
	{
		g_iPlayerToken[pId] = 0;
	}

}

public LogEvent_RoundEnd()
{
	if(g_iGameStart)
	{
		if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
		
		g_iGameStart = false;
	}
}

Show_MainMenu(pId)
{
	new szMenu[512], iLen, iKey;
	
	FormatMain("\yВикторина меню^n^n");
	
	FormatItem("\y1. \w%s игру^n^n", g_iGameStart ? "Выключить" : "Включить"), iKey |= (1<<0);
	
	if(g_iGameStart)
	{
		FormatItem("\y2. \wВыдать очко^n"), iKey |= (1<<1);
		FormatItem("\y3. \wЗабрать очко^n"), iKey |= (1<<2);
		
		FormatItem("\y4. \rОбнулить всем очко^n"), iKey |= (1<<3);
	}

	FormatItem("^n^n^n\y0. \wНазад"), iKey |= (1<<9);
	
	return show_menu(pId, iKey, szMenu, -1, "Show_MainMenu");
}

public Handle_MainMenu(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: 
		{
			g_iGameStart = !g_iGameStart;
			
			
			switch(g_iGameStart)
			{
				case true:
				{
					set_task_ex(1.0, "jbe_main_informer", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!jbe_is_user_connected(i)) continue;
						
						g_iPlayerToken[i] = 0;
					}
					
				}
				case false:
				{
					if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
				
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!jbe_is_user_connected(i)) continue;
						
						g_iPlayerToken[i] = 0;
					}
					UTIL_SayText(0, "!g* !yНачальник !g%n !yобнулил счет", pId);
				}
			}
			UTIL_SayText(0, "!g* !yНачальник !g%s !yВикторину", g_iGameStart ? "Включил" : "Выключил");
		}
		case 1: return Cmd_ShowGiveToken(pId);
		case 2: return Cmd_ShowTakeToken(pId);
		case 3:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_connected(i)) continue;
				
				g_iPlayerToken[i] = 0;
			}
		
		
		}
		case 9: return jbe_open_main_menu(pId, 3);
	}
	return Show_MainMenu(pId);
}

Cmd_ShowGiveToken(pId) return Show_ShowGiveToken(pId, g_iMenuPosition[pId] = 0);
Show_ShowGiveToken(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
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
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_FREE_DAY_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n - \r%d^n", ++b, i, g_iPlayerToken[i]);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ShowGiveToken");
}

public Handle_ShowGiveToken(pId, iKey)
{
	//if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_ShowGiveToken(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_ShowGiveToken(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			g_iPlayerToken[iTarget]++;
			
			UTIL_SayText(0, "!g* !yНачальник !g%n !yвыдал игроку !g%n !yодно очко, всего: !g%d", pId, iTarget, g_iPlayerToken[iTarget]);
		}
	}
	return Show_ShowGiveToken(pId, g_iMenuPosition[pId]);
}

Cmd_ShowTakeToken(pId) return Show_ShowTakeToken(pId, g_iMenuPosition[pId] = 0);
Show_ShowTakeToken(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
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
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_FREE_DAY_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n - \r%d^n", ++b, i, g_iPlayerToken[i]);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ShowTakeToken");
}

public Handle_ShowTakeToken(pId, iKey)
{
	//if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_ShowTakeToken(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_ShowTakeToken(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			if(g_iPlayerToken[iTarget]) 
			{
				g_iPlayerToken[iTarget]--;
				UTIL_SayText(0, "!g* !yНачальник !g%n !yотнял игроку !g%n !yодно очко, всего: !g%d", pId, iTarget, g_iPlayerToken[iTarget]);
			}
		}
	}
	return Show_ShowTakeToken(pId, g_iMenuPosition[pId]);
}
enum _:ePlayerData
{
	PLAYER_ID,
	DAMAGE,
	KILLS
};
new g_aData[MAX_PLAYERS + 1][ePlayerData]

public jbe_main_informer()
{
	new Message[512], s_Len;
	set_hudmessage(255, 255, 255, 0.10, 0.19, 0, 0.0, 1.1, 0.2, 0.2, -1);
	static iPlayers[MAX_PLAYERS], iPlayerCount, iPlayer;
	get_players_ex(iPlayers, iPlayerCount);
	//SortIntegers(g_iPlayerToken[iPlayers], iPlayerCount, Sort_Descending);
	g_aData[iPlayer][PLAYER_ID] = 0;
	g_aData[iPlayer][DAMAGE] = 0;
	new iTop = 8;
	for(new i; i < iPlayerCount; i++)
	{
		iPlayer = iPlayers[i];
		
		//if(!g_iPlayerToken[iPlayer]) continue;

		g_aData[iPlayer][PLAYER_ID] = iPlayer;
		g_aData[iPlayer][DAMAGE] = g_iPlayerToken[iPlayer];
	}
	SortCustom2D(g_aData, sizeof(g_aData), "SortRoundDamage");
	
	//s_Len += formatex(Message[s_Len], 511 - s_Len, "%n - %d^n", iPlayer, g_iPlayerToken[iPlayer])
		//GnomeSort()
	s_Len = formatex(Message[s_Len], 511 - s_Len, "Топ игроки по очкам^n^n");
		
	for (new i = 1; i < iTop; i++)
	{
		if (!g_aData[i][DAMAGE])
			continue;
		s_Len += formatex(Message[s_Len], 511 - s_Len, "%n | %d^n",g_aData[i][PLAYER_ID], g_aData[i][DAMAGE]);
	}

	ShowSyncHudMsg(0, g_iSyncMainInformer, Message);
}

public SortRoundDamage(const elem1[], const elem2[])
{
	return (elem1[DAMAGE] < elem2[DAMAGE]) ? 1 : (elem1[DAMAGE] > elem2[DAMAGE]) ? -1 : 0;
}