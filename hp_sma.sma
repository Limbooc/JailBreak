#include <amxmodx>
#include <fakemeta>
#include <reapi>


#define PLAYERS_PER_PAGE 8

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define MsgId_SayText 				76

native jbe_is_user_connected(iPlayer);
native jbe_get_user_team(id);
native jbe_is_user_alive(id);
native Open_Oaio(id);


/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iMenuTarget[MAX_PLAYERS + 1],
	iTarget;


public plugin_init()
{
	register_plugin("[JBE] Give HeatlPoint UAIO", "1.1.0", "DalgaPups");
	register_clcmd("hp_give_num_tt", "Hp_func_option_1");
	register_clcmd("hp_give_num_ct", "Hp_func_option_2");
	register_clcmd("target_hp_give", "Hp_func_3");
	register_menucmd(register_menuid("Show_HpMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_HpMenu");
	register_menucmd(register_menuid("Show_GiveHPPlayer"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GiveHpPlayer");
	
}

public plugin_natives() register_native("jbe_show_hpmenu", "jbe_show_hpmenu", 1);

public jbe_show_hpmenu(id) return Show_HpMenu(id)
Show_HpMenu(id)
{
	new szMenu[512], iLen, iKeys = (1<<0|1<<1|1<<2|1<<9);
	
	FormatMain("\yМеню Редактора жизни^n^n");
	
	FormatItem("\y1. \wВыставить всем зекам^n");
	FormatItem("\y2. \wВыставить всем охранникам^n");
	FormatItem("\y3. \wВыставить определенному игроку^n");
	
	
	FormatItem("^n\y0. \wНазад^n");
	//FormatItem("^n^n\y0. \wВыход^n");
	return show_menu(id, iKeys, szMenu, -1, "Show_HpMenu");   
}

public Handle_HpMenu(id, key)
{
	switch(key)
    {
		case 0: client_cmd(id, "messagemode hp_give_num_tt");
		case 1: client_cmd(id, "messagemode hp_give_num_ct");
		case 2: return Cmd_HpiTargetMenu(id)
		
		case 9: return Open_Oaio(id);
		//case 9: return PLUGIN_HANDLED;

	}
	return Show_HpMenu(id);
}


public Hp_func_option_1(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) >= 8)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:9999999!y]");
		return Show_HpMenu(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_HpMenu(id);
	}
	if(str_to_num( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение равно !g0!");
		return Show_HpMenu(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_HpMenu(id);
		}
	}
	new szAmount1 = str_to_num( Args1 );
	jbe_set_hp(id, 1, szAmount1, 1);
	return PLUGIN_HANDLED;
}
public Hp_func_option_2(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) >= 8)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:9999999!y]");
		return Show_HpMenu(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_HpMenu(id);
	}
	if(str_to_num( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение равно !g0!");
		return Show_HpMenu(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_HpMenu(id);
		}
	}
	new szAmount1 = str_to_num( Args1 );
	jbe_set_hp(id, 2, szAmount1, 1);
	return	PLUGIN_HANDLED;
}

public Hp_func_3(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) >= 8)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:9999999!y]");
		return Show_HpMenu(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_HpMenu(id);
	}
	if(str_to_num( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение равно !g0!");
		return Show_HpMenu(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_HpMenu(id);
		}
	}
	new szAmount1 = str_to_num( Args1 );
	jbe_set_hp(id, 3, szAmount1, iTarget);
	return	PLUGIN_HANDLED;
}


Cmd_HpiTargetMenu(pId) return Show_GiveHPPlayer(pId, g_iMenuPosition[pId] = 0);
Show_GiveHPPlayer(pId, iPos)
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
	
			UTIL_SayText(pId, "%L", LANG_PLAYER, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yВыдать Healt Point (HP) \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n - \r[%d HP]^n", ++b, i, get_user_health(i));
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_GiveHPPlayer");
}

public Handle_GiveHpPlayer(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_GiveHPPlayer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_GiveHPPlayer(pId, --g_iMenuPosition[pId]);
		default:
		{
			g_iMenuTarget[pId] = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			iTarget = g_iMenuTarget[pId];
			client_cmd(pId, "messagemode target_hp_give");
		}
	}
	return PLUGIN_HANDLED;
}

public jbe_set_hp(id, iTeam, hp, iTarget)
{
	new integr = hp
	
	new Float:float_num
	float_num = float ( integr )
	
	switch(iTeam)
	{
		case 1:
		{
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if(jbe_get_user_team(iPlayer) != 1 || !jbe_is_user_alive(iPlayer)) continue;
				set_entvar(iPlayer, var_health, float_num);
			}
			UTIL_SayText(0 , "!g* !y%n устанвоил всем заключенным !g%.1f ХП" ,id, float_num);
			set_dhudmessage(255, 50, 50, -1.0, 0.67, 1, 6.0, 5.0);
			show_dhudmessage(0, "Всем зекам было выставленно^n[%.1f] HP" , float_num);
		}
		case 2:
		{
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if(jbe_get_user_team(iPlayer) != 2 || !jbe_is_user_alive(iPlayer)) continue;
				set_entvar(iPlayer, var_health, float_num);
			}
			UTIL_SayText(0 , "!g* !y%n установил всем охранникам !g%.1f ХП" , id, float_num);
			set_dhudmessage(50, 50, 255, -1.0, 0.67, 1, 6.0, 5.0);
			show_dhudmessage(0, "Всем охранникам было выставленно^n[%.1f] HP" , float_num);
		}
		case 3:
		{
			if(jbe_is_user_alive(iTarget) && is_user_connected(iTarget))
			{
				set_entvar(iTarget, var_health, float_num);
				
				UTIL_SayText(0 , "!g* !y%n устанвоил игроку %n - !g%.1f ХП" ,id, iTarget, float_num);
				set_dhudmessage(255, 255, 255, -1.0, 0.67, 1, 6.0, 5.0);
				show_dhudmessage(0, "%n был выставлен^n[%.1f] HP" , iTarget, float_num);
			}
			iTarget = 0;
		}
	}
	return PLUGIN_HANDLED;
}



stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!i", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if(!jbe_is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
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