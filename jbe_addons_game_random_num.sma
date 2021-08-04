#include <amxmodx>
#include <amxmisc>
#include <jbe_core>

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))


new iRandomNum[2], iType[2];
new g_iSyncMainInformer;
native jbe_open_main_menu(pId, iMenu)
new szTypeTeam[][] =
{
	"Всем",
	"Заключенным",
	"Охранникам"

}


public plugin_init()
{
	
	register_clcmd("say /random", 		"random_public");
	register_clcmd("random", 			"random_public");
	
	register_clcmd("RandomNum" , "clcmd_type_num");
	
	
	g_iSyncMainInformer = CreateHudSyncObj();
	
	register_menucmd(register_menuid("Show_MainMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainMenu");
}

public random_public(pId)
{
	if(jbe_is_user_chief(pId))
	{
		iRandomNum[0] = 0;
		iRandomNum[1] = 10;
		return Show_MainMenu(pId);
	}
	return PLUGIN_HANDLED;
}


Show_MainMenu(id) 
{
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9), iLen;
	FormatMain("\yМеню случайнных чисел^n^n");
	
	FormatItem("\y1. \wМинимальное значение: \y%d^n", iRandomNum[0]);
	FormatItem("\y2. \wМаксимальное значение: \y%d^n", iRandomNum[1]);
	
	FormatItem("^n\y3. \yВывести на экран^n");
	
	FormatItem("^n\y4. \rПоказать: \y%s^n", szTypeTeam[iType[1]]);
	
	FormatItem("^n^n^n\y9. \wНазад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_MainMenu");
}

public Handle_MainMenu(pId, iKeys)
{
	if(!jbe_is_user_chief(pId)) return PLUGIN_HANDLED;
	switch(iKeys)
	{
		case 0:
		{
			client_cmd(pId, "messagemode ^"RandomNum^"") 
			iType[0] = 0;
			client_print_color(pId, print_team_default, "^x04********************************************************")
			client_print_color(pId, print_team_default, "^x04[RandomNum]^x01 Введите минимальное число для показа на экран");
		}
		case 1:
		{
			client_cmd(pId, "messagemode ^"RandomNum^"") 
			iType[0] = 1;
			client_print_color(pId, print_team_default, "^x04********************************************************")
			client_print_color(pId, print_team_default, "^x04[RandomNum]^x01 Введите максимальное число для показа на экран");
		}
		case 2:
		{
			if(iRandomNum[0] == iRandomNum[1])
			{
				client_print_color(pId, print_team_default, "^x04[RandomNum]^x01 Ошибка, внесите другое значение!!");
				return Show_MainMenu(pId);
			}
			else if(iRandomNum[0] > iRandomNum[1])
			{
				client_print_color(pId, print_team_default, "^x04[RandomNum]^x01 Ошибка, минимальное значение больше максимального!");
				return Show_MainMenu(pId);
			}
			else if(iRandomNum[1] < iRandomNum[0])
			{
				client_print_color(pId, print_team_default, "^x04[RandomNum]^x01 Ошибка, максимальное значение больше минимального!");
				return Show_MainMenu(pId);
			}
			show_randomnum(pId);
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			iType[1]++;
			if(iType[1] >2)
				iType[1] = 0;
		}
		case 8: return jbe_open_main_menu(pId, 2);
		case 9: return PLUGIN_HANDLED;
	
	}

	return Show_MainMenu(pId);
}


show_randomnum(pId)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount, player;
	new iResult = random_num(iRandomNum[0], iRandomNum[1])
	
	
	switch(iType[1])
	{
		case 0: get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);
		case 1: 
		{
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			ShowSyncHudMsg(pId, g_iSyncMainInformer, "Показать: %s^nМин. число: %d^nМакс. число: %d^n^n^nЧисло:^n[%d]", szTypeTeam[iType[1]], iRandomNum[0], iRandomNum[1], iResult);
			client_print_color(player, print_team_default, "^x04[RandomNum]^x01 Начальник %n запустил Игру ^x04Случайное число^x01. Выпало число - ^x04[%d] !", pId, iResult);
		}
		case 2: get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");
	}
	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 5.0, 5.0);
	
	for(new i; i < iPlayerCount; i++)
	{	
		player = iPlayers[i];
		
		ShowSyncHudMsg(player, g_iSyncMainInformer, "Показать: %s^nМин. число: %d^nМакс. число: %d^n^n^nЧисло:^n[%d]", szTypeTeam[iType[1]], iRandomNum[0], iRandomNum[1], iResult);
		client_print_color(player, print_team_default, "^x04[RandomNum]^x01 Начальник %n запустил Игру ^x04Случайное число^x01. Выпало число - ^x04[%d] !", pId, iResult);
	}
	return Show_MainMenu(pId);
}

public clcmd_type_num(pId)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	
	if(strlen( Args1 ) >= 8)
	{
		client_print_color(pId, print_team_default,"^x04[RandomNum]^x01 ^x01Вы ввели слишком ^x04большое число ^x01[^x04Max:9999999^x01]");
		return Show_MainMenu(pId);
	}
	if(strlen( Args1 ) == 0)
	{
		client_print_color(pId, print_team_default,"^x04[RandomNum]^x01 ^x01Пустое значение ^x04невозможно");
		return Show_MainMenu(pId);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			client_print_color(pId,print_team_default, "^x04[RandomNum]^x01 ^x01Значение должна быть только ^x04числом");
			return Show_MainMenu(pId);
		}
	}
	
	switch(iType[0])
	{
		case 0: iRandomNum[0] = str_to_num( Args1 );
		case 1: iRandomNum[1] = str_to_num( Args1 );
	}
	return Show_MainMenu(pId);
}