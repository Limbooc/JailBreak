#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>

new g_iGlobalDebug;
#include <util_saytext>


native jbe_is_user_flags(i, iType)
native jbe_is_user_data(player, iType)
native openadminmenu(pId);

#define PLAYERS_PER_PAGE 7

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1];
	
new g_UserID[MAX_PLAYERS + 1][MAX_PLAYERS + 1];



#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

public plugin_init() 
{
	register_plugin("[JBE] ReEdit PlMenu", "1.0a", "DalgaPups");
	
	register_menucmd(register_menuid("Show_TransferMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_TransferMenu");
	register_menucmd(register_menuid("Show_CTTransferMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_TransferMenuCT");
	
	register_menucmd(register_menuid("Show_SlapMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_SlapMenu");
	register_menucmd(register_menuid("Show_KickMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_KickMenu");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public plugin_natives()
{
	register_native("jbe_show_teammenu", "jbe_show_teammenu", 1);
}

public jbe_show_teammenu(pId, iType)
{
	switch(iType)
	{
		case 1: return Cmd_CTTransferMenu(pId);
		case 2: return Cmd_TransferMenu(pId);
		case 3: return Cmd_SlapMenu(pId);
		case 4: return Cmd_KickMenu(pId);
	}
	return PLUGIN_HANDLED;
}

public Cmd_TransferMenu(pId) return Show_TransferMenu(pId, g_iMenuPosition[pId] = 0);
Show_TransferMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || jbe_get_user_team(i) != 2 || is_user_hltv(i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED
			
		}
		default: FormatMain("\yПеревод за Зеков \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		if(jbe_is_user_flags(i, 6) && i != pId)
		{
			FormatItem("\y%d. \d%n \r*IMM^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 3))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*UAIO^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 1))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*Admin^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 0))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*VIP^n", ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n^n", ++b, i);
		}
	}
	FormatItem("^n\y8. \wПеревод за \rЗека"), iKeys |= (1<<7);
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_TransferMenu");
}

public Handle_TransferMenu(pId, iKey)
{
	switch(iKey)
	{
		case 7: return Cmd_CTTransferMenu(pId);
		case 8: return Show_TransferMenu(pId, ++g_iMenuPosition[pId]);
		case 9: 
		{
			if(!g_iMenuPosition[pId])
			{
				return client_cmd(pId, "adminmenu");
			}
			else
			return Show_TransferMenu(pId, --g_iMenuPosition[pId]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			jbe_set_user_team(iTarget, 1);
			UTIL_SayText(0, "!g* !yАдминистратор !g%n !yперевел охранника !g%n !yза !gЗаключенных", pId, iTarget);
			
			server_print("************************************************")
			server_print(" ***** [ Админ: %n  перевел игрока %n за зеков] ***** ^n",pId, iTarget)
			server_print("************************************************")
			
			log_to_file("AdminMenu.log", "Админ: %n  перевел игрока %n за зеков]", pId, iTarget);
		}
	}
	return Show_TransferMenu(pId, g_iMenuPosition[pId]);
}

public Cmd_CTTransferMenu(pId) return Show_CTTransferMenu(pId, g_iMenuPosition[pId] = 0);
Show_CTTransferMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || jbe_get_user_team(i) != 1 || is_user_hltv(i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED;
			
		}
		default: FormatMain("\yПеревод за Охрану \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		if(jbe_is_user_data(i, 1))
		{
			FormatItem("\y%d. \d%n \r[BLOCK]^n", ++b, i);
		}
		else
		{
			if(jbe_is_user_flags(i, 6) && i != pId)
			{
				FormatItem("\y%d. \d%n \r*IMM^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 3))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*UAIO^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 1))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*Admin^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 0))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*VIP^n", ++b, i);
			}
			else
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n^n", ++b, i);
			}
		}
	}
	FormatItem("^n\y8. \wПеревод за \rОхрану"), iKeys |= (1<<7);
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_CTTransferMenu");
}

public Handle_TransferMenuCT(pId, iKey)
{
	switch(iKey)
	{
		case 7: return Cmd_TransferMenu(pId)
		case 8: return Show_CTTransferMenu(pId, ++g_iMenuPosition[pId]);
		case 9: 
		{
			if(!g_iMenuPosition[pId])
			{
				return client_cmd(pId, "adminmenu");
			}
			else
			return Show_CTTransferMenu(pId, --g_iMenuPosition[pId]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			jbe_set_user_team(iTarget, 2);
			UTIL_SayText(0, "!g* !yАдминистратор !g%n !yперевел зека !g%n !yза !gОхранников", pId, iTarget);
			
			server_print("************************************************")
			server_print(" ***** [ Админ: %n  перевел игрока %n за охрану] ***** ^n",pId, iTarget)
			server_print("************************************************")
			
			log_to_file("AdminMenu.log", "Админ: %n  перевел игрока %n за охрану]", pId, iTarget);
		}
	}
	return Show_CTTransferMenu(pId, g_iMenuPosition[pId]);
}

public Cmd_SlapMenu(pId) return Show_SlapMenu(pId, g_iMenuPosition[pId] = 0);
Show_SlapMenu(const pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || jbe_get_user_team(i) == 3 || !jbe_is_user_alive(i) || is_user_hltv(i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED;
			
		}
		default: FormatMain("\yУбить игрока \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		g_UserID[pId][i] = get_user_userid(i);

		if(jbe_is_user_flags(i, 6) && i != pId)
		{
			FormatItem("\y%d. \d%n \r*IMM^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 3))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*UAIO^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 1))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*Admin^n", ++b, i);
		}
		else
		if(jbe_is_user_flags(i, 0))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r*VIP^n", ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n^n", ++b, i);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_SlapMenu");
}

public Handle_SlapMenu(const pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_SlapMenu(pId, ++g_iMenuPosition[pId]);
		case 9: 
		{
			if(!g_iMenuPosition[pId])
			{
				return client_cmd(pId, "adminmenu");
			}
			else
			return Show_SlapMenu(pId, --g_iMenuPosition[pId]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			
			if(get_user_userid(iTarget) == g_UserID[pId][iTarget]) {
                user_kill(iTarget)
				UTIL_SayText(0, "!g* !yАдминистратор !g%n !yубил !g%n !yчерез админ панель", pId, iTarget);
				
				server_print("************************************************")
				server_print(" ***** [ Админ: %n  убил %n через админ панель] ***** ^n",pId, iTarget)
				server_print("************************************************")
				
				log_to_file("AdminMenu.log", "Админ: %n  убил %n через админ панель]", pId, iTarget);
            } else UTIL_SayText(pId, "!g* !yВыбранный Вами игрок отключился от сервера");
		}
	}
	return Show_SlapMenu(pId, g_iMenuPosition[pId]);
}
//new szTargetName[MAX_PLAYERS + 1]
public Cmd_KickMenu(pId) return Show_KickMenu(pId, g_iMenuPosition[pId] = 0);
Show_KickMenu(const pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i) || is_user_hltv(i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
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
			UTIL_SayText(pId, "!g * !yПодхядщих игроков не найдено");
			return PLUGIN_HANDLED;
			
		}
		default: FormatMain("\yКикнуть игрока \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	//for(new a = iStart; a < iEnd; a++)
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		g_UserID[pId][i] = get_user_userid(i);
		//get_user_name(g_iMenuPlayers[pId][a], szTargetName, charsmax(szTargetName))
		
		if(i != pId)
		{
			if(jbe_is_user_flags(i, 6) && i != pId)
			{
				FormatItem("\y%d. \d%n \r*IMM^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 3))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*UAIO^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 1))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*Admin^n", ++b, i);
			}
			else
			if(jbe_is_user_flags(i, 0))
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n \r*VIP^n", ++b, i);
			}
			else
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n^n", ++b, i);
			}
		}else FormatItem("\y%d. \d%n \r[Вы]^n", ++b, i);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_KickMenu");
}

public Handle_KickMenu(const pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_KickMenu(pId, ++g_iMenuPosition[pId]);
		case 9: 
		{
			if(!g_iMenuPosition[pId])
			{
				return client_cmd(pId, "adminmenu");
			}
			else
			return Show_KickMenu(pId, --g_iMenuPosition[pId]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			
			
			if(jbe_is_user_connected(iTarget) && get_user_userid(iTarget) == g_UserID[pId][iTarget]) 
			{
                
				UTIL_SayText(0, "!g* !yАдминистратор !g%n !yкикнул !g%n !yчерез админ панель", pId, iTarget);
				

				log_to_file("kicklog.log", "Admin: %n kick player iTargetUserID: %d , iTargetName: %n", pId, get_user_userid(iTarget), iTarget);
				
				server_cmd("kick #%d", get_user_userid(iTarget))
				server_exec()
            } else UTIL_SayText(pId, "!g* !yВыбранный Вами игрок отключился от сервера");
		}
	}
	return Show_KickMenu(pId, g_iMenuPosition[pId]);
}

