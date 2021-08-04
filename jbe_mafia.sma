#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <reapi>
#include <private_message>



#include <hamsandwich>
#include <fakemeta>
#include <jbe_core>
new g_iGlobalDebug;
#include <util_saytext>
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define TASK_RESTART_VOTE 645667876

#define ACCESS ADMIN_LEVEL_F

#define PLAYERS_PER_PAGE 7

#define TASK_SHOW_INFORMER 6585663

#define PLUGIN 			"[JBE] Mafia"
#define VERSION 		"1.0"
#define AUTHOR			"DalgaPups"

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


new RedRoles,
	BlackRoles;

const MsgId_ScreenFade		= 98;

const MsgId_RadarMsg = 112;

new g_iBitUserScreenFade;

new bool:g_iMafiaSleep[6];
new bool:g_iDayMafia;

new bool:g_MafiaStatus;
new bool:g_iMafiaChat;

new g_iDayVote;
new g_iBitUserVoting;
new g_iVoteMafia[MAX_PLAYERS + 1];

static const g_szMafiaRoleName[8][]=
{
	"Нет роли",
	"Житель",
	"Мафия",
	"Доктор",
	"Камиссар",
	"Куртизанка",
	"Маньяк",
	"Шпион"
};

new g_iSyncMafiaInformer;
new g_iSyncSecondInformer;

new g_iUserRoleMafia[MAX_PLAYERS + 1];
new g_iBitUserVoted;

#define NONE 		0
#define STANDART 	1
#define MAFIA 		2
#define DOCTOR 		3
#define COMISAR 	4
#define SHLUHA 		5 
#define MANIAC 		6
#define SHPION 		7


new g_iPlayerChosed[6][MAX_NAME_LENGTH];



// Построение меню из игроков
new g_iUserID[MAX_PLAYERS + 1][MAX_PLAYERS];			// Игроки в меню
new g_iMenuPosition[MAX_PLAYERS + 1]; 					// Страница в меню

new g_iMenuType[MAX_PLAYERS + 1];						// Тип задачи

new g_iBitUserCourtizan;

new g_iChiefName[MAX_NAME_LENGTH];


new HookChain:HookPlayer_PlayerSpawn,
	HookChain:HookPlayer_PlayerKilled,
	HookChain:HookPlayer_PlayerCanHearPlayer,
	HandleLogEventRoundEnd,
	HandleEventValueShow,
	HandleEventValueHide;

native jbe_global_games(pId, iType);
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("mafia", "Open_Mafia")

	register_menucmd(register_menuid("Show_MafiaMenu"), 			(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_MafiaMenu");
	register_menucmd(register_menuid("Show_RoleMenu"), 				(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_RoleMenu");
	register_menucmd(register_menuid("Show_GiveRole"), 				(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_GiveRole");
	register_menucmd(register_menuid("Show_DayNightMenu"), 			(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_DayNightMenu");

	register_menucmd(register_menuid("Show_ChoicePlayerMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_ChoicePlayerMenu");
	register_menucmd(register_menuid("Show_PlayerChoice"), 			(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_PlayerChoice");
	register_menucmd(register_menuid("Show_VotePlayerPlayerChoice"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_VotePlayerPlayerChoice");
	register_menucmd(register_menuid("Show_VoteMenu"), 				(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_VoteMenu");


	DisableHookChain(HookPlayer_PlayerSpawn = 	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true));
	DisableHookChain(HookPlayer_PlayerKilled = 	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true));
	DisableHookChain(HookPlayer_PlayerCanHearPlayer = 	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CanPlayerHearPlayer", false));
	 
	g_iSyncMafiaInformer = CreateHudSyncObj();
	g_iSyncSecondInformer = CreateHudSyncObj();

	HandleLogEventRoundEnd = register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");

	HandleEventValueShow = register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
	HandleEventValueHide = register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
	disable_event(HandleEventValueShow);
	disable_event(HandleEventValueHide);
	disable_logevent(HandleLogEventRoundEnd);

	register_message(MsgId_RadarMsg, "message_radar"); 
	
	register_clcmd("say", 				"Command_HookSay");
	register_clcmd("say_team", 			"Command_HookSay");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");

}

public Command_HookSay(id)
{
	if(!g_MafiaStatus) return PLUGIN_CONTINUE;
	
	new szBuffer[190];
	read_args(szBuffer, charsmax(szBuffer));
	remove_quotes(szBuffer);
	
	while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	
	if(jbe_get_user_team(id) == 2) return PLUGIN_CONTINUE;
	if(g_iUserRoleMafia[id] == MAFIA && equal(szBuffer, "!", 1))
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(!jbe_is_user_alive(i)) continue;
			
			if(g_iUserRoleMafia[i] == MAFIA || i == jbe_get_chief_id())
			{			
				UTIL_SayText(i, "!y[!gCHAT MAFIA!y] | !t%n !y: !g%s", id, szBuffer);
			}else if(g_iUserRoleMafia[i] == SHPION)  UTIL_SayText(i, "!y[!gCHAT MAFIA!y] | !tМафиози !y: !g%s", szBuffer);
		}
		return PLUGIN_HANDLED;
	}
	else if(g_iUserRoleMafia[id] != MAFIA && equal(szBuffer, "!", 1))
	{
		UTIL_SayText(id, "!y[!gMAFIA!y]!y Вы не имеете доступа к данному чату.");
		return PLUGIN_HANDLED;
	}
	if(jbe_is_user_alive(id) && equal(szBuffer, "*", 1))
	{
		UTIL_SayText(id, "!g[!yРоль: %s!g] !y| !t%n !y: %s", g_szMafiaRoleName[g_iUserRoleMafia[id]], id, szBuffer);
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(!jbe_is_user_alive(i) || i != jbe_get_chief_id()) continue;
			if(jbe_is_user_alive(i))
			{
				UTIL_SayText(i, "!g[!yРоль: %s!g] !y| !t%n !y: %s", g_szMafiaRoleName[g_iUserRoleMafia[id]], id, szBuffer);
			}
		}
		return PLUGIN_HANDLED;
	}
	if(!jbe_is_user_alive(id))
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(!jbe_is_user_connected(i)) continue;
				
			if(i == jbe_get_chief_id())
			{
				UTIL_SayText(i, "!y*!tDead chat!y* !t%n!y: %s", id, szBuffer);
			}
			if(jbe_is_user_alive(i)) continue;

			UTIL_SayText(i, "!y*!tDead chat!y* !t%n!y: %s", id, szBuffer);
		}
		return PLUGIN_HANDLED;
	}
	if(g_iMafiaChat) 
	{
		UTIL_SayText(id, "!y[!gMAFIA!y]!y Чат не доступен.");
		return PLUGIN_HANDLED;
	}
	
	if(IsSetBit(g_iBitUserCourtizan, id) && jbe_get_user_team(id) == 1)
	{
		UTIL_SayText(id, "!y[!gMAFIA!y]!y Вас охмурила проститутка, вы молчите");
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}


public Open_Mafia(pId)
{
	if(jbe_get_day_mode() == 3)
	{
		return PLUGIN_HANDLED;
	}

	if((get_user_flags(pId) & ACCESS) && pId == jbe_get_chief_id()) 
	{
		return Show_MafiaMenu(pId);
	}
	
	UTIL_SayText(pId, "!g* !yМафию могут включать только начальник!");
	return PLUGIN_HANDLED;
}

public message_radar()
{
	if(g_MafiaStatus)
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public disableMafiaGame()
{
	if(g_MafiaStatus)
	{
		if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
		if(task_exists(TASK_RESTART_VOTE)) remove_task(TASK_RESTART_VOTE);

		g_iBitUserVoting = 0;
		g_iBitUserVoted = 0;
		

		disable_logevent(HandleLogEventRoundEnd);

		disable_event(HandleEventValueShow);
		disable_event(HandleEventValueHide);

		DisableHookChain(HookPlayer_PlayerSpawn);
		DisableHookChain(HookPlayer_PlayerKilled);
		DisableHookChain(HookPlayer_PlayerCanHearPlayer);

		g_MafiaStatus = false;
		
		new bool:block = pm_is_chat_blocked();
		if(block)
			pm_block_use(false);
	}
}

public Event_StatusValueShow(pId)
{
	new iTarget = read_data(2);
	if(jbe_get_user_team(pId) == 2)
	{
		set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
		if(jbe_is_user_chief(pId))
			ShowSyncHudMsg(pId, g_iSyncSecondInformer, "%n^nРоль: %s", iTarget, g_szMafiaRoleName[g_iUserRoleMafia[iTarget]]);
		else ShowSyncHudMsg(pId, g_iSyncSecondInformer, "%n", iTarget);
	}
	else
	if(jbe_get_user_team(pId) == 1)
	{
		if(!is_day_sleep())
		{
			set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
			ShowSyncHudMsg(pId, g_iSyncSecondInformer, "%n", iTarget);
		}
	}

}

public Event_StatusValueHide(pId) ClearSyncHud(pId, g_iSyncSecondInformer);

public LogEvent_RoundEnd()
{
	if(g_MafiaStatus) disableMafiaGame()
}

public plugin_natives()
{
	register_native("jbe_get_status_mafia", "jbe_get_status_mafia", 1);
	register_native("jbe_mafia_off_chat", "jbe_mafia_off_chat", 1);
}


public jbe_mafia_off_chat() return g_iMafiaChat;
public jbe_get_status_mafia() return g_MafiaStatus;


public HC_CBasePlayer_PlayerSpawn_Post(id)
{
	if(jbe_get_user_team(id) == 1)
	{
		g_iUserRoleMafia[id] = STANDART;
	}
}
public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(g_MafiaStatus)
	{
		switch(jbe_get_user_team(iVictim))
		{
			case 1:		
			{


				UTIL_SayText(0, "!g[Mafia] !yИгрок !g%n !yбыл с ролью !g%s", iVictim, g_szMafiaRoleName[g_iUserRoleMafia[iVictim]]);

				g_iUserRoleMafia[iVictim] = STANDART;

			}
			case 2:
			{
				if(jbe_is_user_chief(iVictim))
				{
					disableMafiaGame();
				}
			}
		}

	}
}

public client_putinserver(id)
{
	if(g_MafiaStatus)
	{
		if(jbe_is_user_alive(id) && jbe_get_user_team(id) == 1)
		{
			//UTIL_SayText(0, "!g[Mafia] !yИгрок отключился, он был с ролью !g%s", g_szMafiaRoleName[g_iUserRoleMafia[id]]);
			g_iUserRoleMafia[id] = STANDART;
		}
	}
}

public client_disconnected(id)
{
	if(g_MafiaStatus)
	{
		if(jbe_is_user_chief(id))
		{
			disableMafiaGame();
		}
		if(jbe_is_user_alive(id) && jbe_get_user_team(id) == 1)
		{

			for(new i = 1; i <= MaxClients; i++) 
			{
				if(i != jbe_get_chief_id()) continue;
				
				UTIL_SayText(i, "!g[Mafia] !yИгрок %n отключился, он был с ролью !g%s. (видит только ведущий)", id, g_szMafiaRoleName[g_iUserRoleMafia[id]]);
			}
			g_iUserRoleMafia[id] = STANDART;
		}
	}
}

public Show_MafiaMenu(pId)
{
	static szMenu[512], iKeys = (1<<8|1<<9), iLen;

	FormatMain("\yМеню Мафии^n\dВызвать меню \r'mafia'^n^n");
	
	FormatItem("\y1. \w%s \yигру^n^n", g_MafiaStatus ? "Закончить":"Начать"), iKeys |= (1<<0);

	if(g_MafiaStatus)
	{
		FormatItem("\y2. \wВыдать \rРоли^n"), iKeys |= (1<<1);
		FormatItem("\y3. \wМеню Ночь/День^n^n"), iKeys |= (1<<2);

		FormatItem("\dНиже функции желательно^n");
		FormatItem("ознакомится заранее!^n");
		FormatItem("\y4. \wКто кого выбрал^n"), iKeys |= (1<<3);
		FormatItem("\y5. \wОбнулить кто кого выбрал^n^n"), iKeys |= (1<<4);

		FormatItem("\y6. \wВыставить на голосование^n"), iKeys |= (1<<5);
		FormatItem("\y7. \wНачать голосование^n"), iKeys |= (1<<6);
		
		FormatItem("^n\y8. \w%s чат^n", g_iMafiaChat ? "Включить" : "Выключить"), iKeys |= (1<<7);

	}
	FormatItem("\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys,szMenu, -1, "Show_MafiaMenu");
}

public Handle_MafiaMenu(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: 
		{
			g_MafiaStatus = !g_MafiaStatus;

			switch(g_MafiaStatus)
			{
				case true:
				{

					g_iBitUserCourtizan = 0;
					for(new iPlayer = 1; iPlayer <=  MaxClients; iPlayer++) 
					{
						if(!is_user_connected(iPlayer) || !jbe_is_user_alive(iPlayer)) continue;


						g_iUserRoleMafia[iPlayer] = STANDART;
					}
					
					set_task_ex(2.0, "main_informer", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);

					for(new i; i < 5; i++) g_iPlayerChosed[i] = "Не выбрано";

					new szName[MAX_NAME_LENGTH];
					get_user_name(pId, szName, MAX_NAME_LENGTH - 1);


					new  szChief[MAX_NAME_LENGTH];
					copy(szChief, charsmax(szChief), szName);

					g_iChiefName = szChief;

					g_iBitUserVoting = 0;
					g_iBitUserVoted = 0;
					g_iMafiaChat = false;

					if(task_exists(TASK_RESTART_VOTE)) remove_task(TASK_RESTART_VOTE);

					enable_logevent(HandleLogEventRoundEnd);
					enable_event(HandleEventValueShow);
					enable_event(HandleEventValueHide);
					EnableHookChain(HookPlayer_PlayerSpawn);
					EnableHookChain(HookPlayer_PlayerKilled);
					EnableHookChain(HookPlayer_PlayerCanHearPlayer);
					
					new bool:block = pm_is_chat_blocked();
					if(!block)
						pm_block_use(true);
				}
				case false:
				{
					if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
					if(task_exists(TASK_RESTART_VOTE)) remove_task(TASK_RESTART_VOTE);

					g_iBitUserVoting = 0;
					g_iBitUserVoted = 0;

					disable_logevent(HandleLogEventRoundEnd);
					DisableHookChain(HookPlayer_PlayerSpawn);
					DisableHookChain(HookPlayer_PlayerKilled);
					DisableHookChain(HookPlayer_PlayerCanHearPlayer);
					
					disable_event(HandleEventValueShow);
					disable_event(HandleEventValueHide);
					
					g_iMafiaChat = false;
					
					new bool:block = pm_is_chat_blocked();
					if(block)
						pm_block_use(false);
				}
			}
		}
		case 1: return Show_RoleMenu(pId);
		case 2: return Show_DayNightMenu(pId);

		case 3: return Show_ChoicePlayerMenu(pId);
		case 4: 
		{
			for(new i; i < 5; i++) g_iPlayerChosed[i] = "Не выбрано";
			
			g_iBitUserCourtizan = 0;
		}
		case 5: return Show_VoteMenu(pId, g_iMenuPosition[pId] = 0);
		case 6: 
		{
			if(!task_exists(TASK_RESTART_VOTE))
			{
				if(g_iBitUserVoted)
				{
					if(g_iBitUserVoted == 4)
					{
						UTIL_SayText(pId, "!g[Mafia] !yВыбран только один участник, в таком случая у него единогласное решение");
						return Show_MafiaMenu(pId);
					}
					else
					{
						g_iDayVote = 15;
						set_task_ex(1.0, "jbe_show_votemenu", TASK_RESTART_VOTE, _, _, SetTask_RepeatTimes, g_iDayVote);
						UTIL_SayText(0, "!g[Mafia] !yНачат голосование!");
					}
				}
				else
				{
					UTIL_SayText(pId, "!g[Mafia] !yНе выбран ни один из участников");
					return Show_MafiaMenu(pId);
				}
			}
			else 
			{
				UTIL_SayText(pId, "!g[Mafia] !yголосование уже запущено");
				return Show_MafiaMenu(pId);
			}
		}
		case 7:
		{
			g_iMafiaChat = !g_iMafiaChat
			
			switch(g_iMafiaChat)
			{
				case true: UTIL_SayText(pId, "!g[Mafia] !yНачальник выключил чат. Для мафии используйте !g!!y, Для общение с начальником !g*");
				case false: UTIL_SayText(pId, "!g[Mafia] !yНачальник включил чат");
			}
		}
		case 8: return jbe_global_games(pId, 0)
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MafiaMenu(pId);
}

public jbe_show_votemenu()
{
	if(--g_iDayVote)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || IsSetBit(g_iBitUserCourtizan, i)) continue;
			Public_VotePlayerPlayerChoice(i);
		}
	}else
	{
		new iVotesNum, iVoteEnd;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsNotSetBit(g_iBitUserVoted, i)) continue;

			if(g_iVoteMafia[i] >= iVotesNum)
			{
				iVotesNum = g_iVoteMafia[i];
				iVoteEnd = i;
			}

		}

		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || !jbe_is_user_alive(i)) continue;
			g_iVoteMafia[i] = 0;
			show_menu(i, 0, "^n");
		}
		if(iVotesNum)
		{
			UTIL_SayText(0, "!g[MafiaVoted] !yГолосование завершено.Наибольшее кол-во голосов набрал - !t%n !g(%d)", iVoteEnd, iVotesNum);
			g_iBitUserCourtizan = 0;
			g_iBitUserVoted = 0;
		}else  UTIL_SayText(0, "!g[MafiaVoted] !yНикто не за кого не голосовали, Повторите попытку");
		
		g_iBitUserVoting = 0;
	}

}


public Public_VotePlayerPlayerChoice(id) return Show_VotePlayerPlayerChoice(id, g_iMenuPosition[id] = 0);
Show_VotePlayerPlayerChoice(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || IsNotSetBit(g_iBitUserVoted, i)) continue;
		g_iUserID[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;

	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;

	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));

	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			if(task_exists(TASK_RESTART_VOTE)) remove_task(TASK_RESTART_VOTE);
			return Show_MafiaMenu(id);
		}
		case 1: FormatMain("\wКого выставляем?^nОсталось - \r%d \wсек^n^n", g_iDayVote);
		default: FormatMain("\wКого выставляем? \r[%d|%d]^nОсталось - \r%d \wсек^n^n", iPos + 1, iPagesNum, g_iDayVote);
	}
	new i, iBitKeys = (1<<9), b;

	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[id][a];

		if(IsNotSetBit(g_iBitUserVoting, id))
		{
			iBitKeys |= (1<<b);
			FormatItem("\y%d. \w%n^n", ++b, i);
		} else FormatItem("\y%d. \d%n - \r[%d]^n", ++b, i, g_iVoteMafia[i]);
		
		
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");

	if(iPos)
	{
		iBitKeys |= (1<<7);
		FormatItem("^n\y8. \w%L", id, "JBE_MENU_BACK");
	} 
	else FormatItem("^n\y8. \d%L", id, "JBE_MENU_BACK");

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", id, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", id, "JBE_MENU_NEXT");

	FormatItem("^n\y0. \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, iBitKeys, szMenu, -1, "Show_VotePlayerPlayerChoice");
}


public Handle_VotePlayerPlayerChoice(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_VotePlayerPlayerChoice(id, --g_iMenuPosition[id]);
		case 8: return Show_VotePlayerPlayerChoice(id, ++g_iMenuPosition[id]);
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iUserID[id][g_iMenuPosition[id] * 7 + iKey];

			if(!jbe_is_user_alive(iTarget)) return Show_VotePlayerPlayerChoice(iTarget, g_iMenuPosition[iTarget] = 0);

			g_iVoteMafia[iTarget]++
			SetBit(g_iBitUserVoting, id);

			UTIL_SayText(0, "!g[MafiaVoted] !yИгрок !g%n !yпроголосовал за !g%n !g(%d)", id, iTarget, g_iVoteMafia[iTarget]);
		
		}
	}
	return Show_VotePlayerPlayerChoice(id, g_iMenuPosition[id]);
}


Show_ChoicePlayerMenu(pId)
{
	new szMenu[512], iKeys, iLen;

	FormatMain("Меню Кто кого выбрал^n^n");

	FormatItem("\y1. \wМафия - \r%s^n", g_iPlayerChosed[0]), iKeys |= (1<<0);
	FormatItem("\y2. \wДоктор - \r%s^n", g_iPlayerChosed[1]), iKeys |= (1<<1);
	FormatItem("\y3. \wКомиссар - \r%s^n", g_iPlayerChosed[2]), iKeys |= (1<<2);
	FormatItem("\y4. \wКуртизанка - \r%s^n", g_iPlayerChosed[3]), iKeys |= (1<<3);
	FormatItem("\y5. \wМаньяк - \r%s^n", g_iPlayerChosed[4]), iKeys |= (1<<4);

	FormatItem("^n\dфункция полезно тем что^nвы можете не запоминать в уме^nили записывать кто кого выбрал");


	FormatItem("^n^n\y9. \wВыход"), iKeys |= (1<<8);
	FormatItem("^n\y0. \wНазад"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChoicePlayerMenu");
}

public Handle_ChoicePlayerMenu(id, iKeys)
{
	switch(iKeys)
	{
		case 0: return Show_PlayerChoice(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 0, "Мафия выбрала" );
		case 1: return Show_PlayerChoice(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 1, "Доктор выбрала" );
		case 2: return Show_PlayerChoice(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 2, "Камиссар выбрал" );
		case 3: return Show_PlayerChoice(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 3, "Куртизанка выбр" );
		case 4: return Show_PlayerChoice(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 4, "Маньяк выбрал" );
		
		case 8: return PLUGIN_HANDLED;
		case 9: return Show_MafiaMenu(id);
	}
	return Show_ChoicePlayerMenu(id);
}

Show_PlayerChoice(id, iPos, iRole, title[32])
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum, g_iMenuTitle[32];
	copy(g_iMenuTitle, charsmax(g_iMenuTitle), title);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1) continue;
		g_iUserID[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;

	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;

	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));

	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_RoleMenu(id)
		}
		case 1: FormatMain("\w%s^n^n", g_iMenuTitle);
		default: FormatMain("\w%s \r[%d|%d]^n^n", g_iMenuTitle, iPos + 1, iPagesNum);
	}
	new i, iBitKeys = (1<<9), b;

	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[id][a];

		iBitKeys |= (1<<b);
		FormatItem("\y%d. \w%n^n", ++b, i);
		
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");

	if(iPos)
	{
		iBitKeys |= (1<<7);
		FormatItem("^n\y8. \w%L", id, "JBE_MENU_BACK");
	} 
	else FormatItem("^n\y8. \d%L", id, "JBE_MENU_BACK");

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", id, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", id, "JBE_MENU_NEXT");

	FormatItem("^n\y0. \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, iBitKeys, szMenu, -1, "Show_PlayerChoice");
}


public Handle_PlayerChoice(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_PlayerChoice(id, --g_iMenuPosition[id], g_iMenuType[id], "Кого выбираем");
		case 8: return Show_PlayerChoice(id, ++g_iMenuPosition[id], g_iMenuType[id], "Кого выбираем");
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iUserID[id][g_iMenuPosition[id] * 7 + iKey];

			if(!jbe_is_user_alive(iTarget)) return Show_ChoicePlayerMenu(id);

			new szName[MAX_NAME_LENGTH];
			get_user_name(iTarget, szName, MAX_NAME_LENGTH - 1);


			new  g_iMenuTitle[32];
			//copy(g_iMenuTitle, charsmax(g_iMenuTitle), szName);
			copy(g_iMenuTitle, charsmax(g_iMenuTitle), szName);

			g_iPlayerChosed[g_iMenuType[id]] = g_iMenuTitle;

			if(g_iMenuType[id] == 3)
			{
				SetBit(g_iBitUserCourtizan, iTarget);
			}

			set_hudmessage(0, 255, 255, -1.0, 0.45, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(id, g_iSyncSecondInformer, "Вы сохранили игрока %n^nкоторые выбрали Роллеры", iTarget);
		
		}
	}
	return Show_MafiaMenu(id);
}

Show_VoteMenu(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1) continue;
		g_iUserID[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;

	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;

	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));

	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_MafiaMenu(id)
		}
		case 1: FormatMain("\wКого выставляем?^n^n");
		default: FormatMain("\wКого выставляем? \r[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new i, iBitKeys = (1<<9), b;

	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[id][a];

		iBitKeys |= (1<<b);
		FormatItem("\y%d. \w%n %s^n", ++b, i, IsSetBit(g_iBitUserVoted, i) ? "\r- Выставлен" : "" );
		
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");

	if(iPos)
	{
		iBitKeys |= (1<<7);
		FormatItem("^n\y8. \w%L", id, "JBE_MENU_BACK");
	} 
	else FormatItem("^n\y8. \d%L", id, "JBE_MENU_BACK");

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", id, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", id, "JBE_MENU_NEXT");

	FormatItem("^n\y0. \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, iBitKeys, szMenu, -1, "Show_VoteMenu");
}


public Handle_VoteMenu(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_VoteMenu(id, --g_iMenuPosition[id]);
		case 8: return Show_VoteMenu(id, ++g_iMenuPosition[id]);
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iUserID[id][g_iMenuPosition[id] * 7 + iKey];

			if(!jbe_is_user_alive(iTarget)) return Show_ChoicePlayerMenu(id);

			InvertBit(g_iBitUserVoted, iTarget);
			
			UTIL_SayText(0, "!g[MafiaVoted] !yВедущий !g%s !yигрока !g%n !yс голосование", IsSetBit(g_iBitUserVoted, iTarget) ? "Выставил" : "Снял", iTarget);
		}
	}
	return Show_VoteMenu(id, g_iMenuPosition[id]);
}

public main_informer()
{
	static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);
	jbe_get_count_skin();
	set_hudmessage(255, 255, 0, 0.7, 0.05, 0, 0.0, 2.1, 2.2, 2.2, -1);
	
	for(new i; i < iPlayerCount; i++)
    {
    	Players = iPlayers[i];

    	switch(jbe_get_user_team(Players))
    	{
    		case 1:
    		{
				ShowSyncHudMsg(Players, g_iSyncMafiaInformer, "\
					\
					Ведущий - %s^n^n\
					Вы - %s^n\
					Черные игроки - %d^n\
					Красные игроки - %d\
					", g_iChiefName, g_szMafiaRoleName[g_iUserRoleMafia[Players]], BlackRoles, RedRoles);
    		}
    		case 2:
    		{
				if(Players == jbe_get_chief_id())
				{
					ShowSyncHudMsg(Players, g_iSyncMafiaInformer, "\
						\
						(ВИДИТЕ ТОЛЬКО ВЫ)^n^n\
						Игроки выбрали:^n\
						Мафия - %s^n\
						Доктор - %s^n\
						Камиссар - %s^n\
						Куртизанка - %s^n\
						Маньяк - %s^n^n\
						Черные игроки - %d^n\
						Красные игроки - %d\
						", g_iPlayerChosed[0], g_iPlayerChosed[1], g_iPlayerChosed[2] , g_iPlayerChosed[3], g_iPlayerChosed[4],  BlackRoles, RedRoles);
				}
				else
				{
					ShowSyncHudMsg(Players, g_iSyncMafiaInformer, "\
					\
					Ведущий - %s^n^n\
					Черные игроки - %d^n\
					Красные игроки - %d\
					", g_iChiefName,  BlackRoles, RedRoles);
				}
    		}
    	}
    }
}

Show_DayNightMenu(pId)
{
	new szMenu[512], iKeys, iLen;

	FormatMain("Меню суток^n^n");

	FormatItem("\y1. \wСделать всем ночь^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wСделать всем день^n^n"), iKeys |= (1<<1);

	FormatItem("\y3. \wМафия - \y%s^n" , !g_iMafiaSleep[0] ? "Не Спит" : "Спит"), iKeys |= (1<<2);
	FormatItem("\y4. \wДоктор - \y%s^n", !g_iMafiaSleep[1] ? "Не Спит" : "Спит"), iKeys |= (1<<3);
	FormatItem("\y5. \wКомиссар - \y%s^n" , !g_iMafiaSleep[2] ? "Не Спит" : "Спит"), iKeys |= (1<<4);
	FormatItem("\y6. \wКуртизанка - \y%s^n", !g_iMafiaSleep[3] ? "Не Спит" : "Спит"), iKeys |= (1<<5);
	FormatItem("\y7. \wМаньяк - \y%s^n" , !g_iMafiaSleep[4] ? "Не Спит" : "Спит"), iKeys |= (1<<6);

	FormatItem("^n^n\y9. \wНазад"), iKeys |= (1<<8);
	FormatItem("^n\y0. \wВыход"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_DayNightMenu");
}



public Handle_DayNightMenu(pId, iKeys)
{
	switch(iKeys)
	{
		case 0: 
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) g_iMafiaSleep[i] = true;	
			
			g_iDayMafia = false;
			for(new iPlayer = 1; iPlayer <=  MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1 || IsSetBit(g_iBitUserScreenFade, iPlayer)) continue;
				
				
				UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
				SetBit(g_iBitUserScreenFade, iPlayer);

				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_FROZEN);
			}

			set_hudmessage(0, 255, 255, -1.0, 0.45, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Наступает ночь^nГород засыпает");
		}
		case 1:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) g_iMafiaSleep[i] = false;	
			g_iDayMafia = false;

			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;
				
				UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
				g_iBitUserScreenFade = 0;
				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_FROZEN);
			}

			set_hudmessage(0, 255, 255, -1.0, 0.45, 0, 0.0, 1.1, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Наступает день^nГород просыпает");

		}
		case 2:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) 
			{
				g_iMafiaSleep[i] = true;	
			}
			g_iMafiaSleep[0] = false;
			g_iDayMafia = true;
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;

				if(IsNotSetBit(g_iBitUserScreenFade, iPlayer))
				{
					UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
					SetBit(g_iBitUserScreenFade, iPlayer);


				}

				if(g_iUserRoleMafia[iPlayer] != MAFIA) continue;
				{
					UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
					ClearBit(g_iBitUserScreenFade, iPlayer);
				}
			}

			set_hudmessage(255, 0, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Просыпается Мафия^nВыбирают кого сегодня^nЗастрелить...");
				
		}
		case 3:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) 
			{
				g_iMafiaSleep[i] = true;	
			}
			g_iMafiaSleep[1] = false;
			g_iDayMafia = false;

			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;

				if(IsNotSetBit(g_iBitUserScreenFade, iPlayer))
				{
					UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
					SetBit(g_iBitUserScreenFade, iPlayer);

					
				}

				if(g_iUserRoleMafia[iPlayer] != DOCTOR) continue;
				{
	
					UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
					ClearBit(g_iBitUserScreenFade, iPlayer);
					
				}
			}
			set_hudmessage(0, 255, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Просыпается Доктор^nВыбирает кого лечить...");


		}
		case 4:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) 
			{
				g_iMafiaSleep[i] = true;	
			}
			g_iMafiaSleep[2] = false;
			g_iDayMafia = false;
			
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;

				if(IsNotSetBit(g_iBitUserScreenFade, iPlayer))
				{
					UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
					SetBit(g_iBitUserScreenFade, iPlayer);

	
				}

				if(g_iUserRoleMafia[iPlayer] != COMISAR) continue;
				{
				
					UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
					ClearBit(g_iBitUserScreenFade, iPlayer);

				}
			}
			set_hudmessage(0, 255, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Просыпается Камиссар^nВыбирает кого проверить этой ночью...");

		}
		case 5:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) 
			{
				g_iMafiaSleep[i] = true;	
			}
			g_iMafiaSleep[3] = false;
			g_iDayMafia = false;
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;

				if(IsNotSetBit(g_iBitUserScreenFade, iPlayer))
				{
					UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
					SetBit(g_iBitUserScreenFade, iPlayer);


				}

				if(g_iUserRoleMafia[iPlayer] != SHLUHA) continue;
				{

					UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
					ClearBit(g_iBitUserScreenFade, iPlayer);

				}
			}	

			set_hudmessage(0, 255, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Просыпается Куртизанка^nВыбирает кого охмурить...");

		}
		case 6:
		{
			for(new i; i < charsmax(g_iMafiaSleep); i++) 
			{
				g_iMafiaSleep[i] = true;	
			}
			g_iMafiaSleep[4] = false;
			g_iDayMafia = false;
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
			{
				if(!jbe_is_user_alive(iPlayer) || jbe_get_user_team(iPlayer) != 1) continue;

				if(IsNotSetBit(g_iBitUserScreenFade, iPlayer))
				{
					UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
					SetBit(g_iBitUserScreenFade, iPlayer);
				}

				if(g_iUserRoleMafia[iPlayer] != MANIAC) continue;
				{
					
					UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
					ClearBit(g_iBitUserScreenFade, iPlayer);

				}
			}	
			set_hudmessage(255, 0, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(0, g_iSyncSecondInformer, "Просыпается Маньяк^nВыбирает кого убить...");

		}
		case 8: return Show_MafiaMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_DayNightMenu(pId);
}

Show_RoleMenu(pId)
{
	static szMenu[512], iLen;

	new iKeys;

	FormatMain("\yМеню \rВыдачи Роли^n^n");
	
	FormatItem("\y1. \wЗабрать роли^n^n"), iKeys |= (1<<0);

	FormatItem("\y2. \wМирный житель^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wМафиози^n"), iKeys |= (1<<2);
	FormatItem("\y4. \wДоктор^n"), iKeys |= (1<<3);
	FormatItem("\y5. \wКомиссар^n"), iKeys |= (1<<4);
	FormatItem("\y6. \wКуртизанка^n"), iKeys |= (1<<5);
	FormatItem("\y7. \wМаньяк^n"), iKeys |= (1<<6);
	FormatItem("\y8. \wШпион^n"), iKeys |= (1<<7);
	
	FormatItem("^n\y9. \wВыход"), iKeys |= (1<<8);
	FormatItem("^n\y0. \wНазад^n"), iKeys |= (1<<9);
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_RoleMenu");
}

public Handle_RoleMenu(id, iKeys)
{

	switch(iKeys)
	{
		case 0: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 0, "Забрать роль");
		case 1: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 1, "Мирный житель");
		case 2: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 2, "Мафиози");
		case 3: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 3, "Доктор");
		case 4: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 4, "Камиссар");
		case 5: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 5, "Куртизанка");
		case 6: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 6, "Маньяк");
		case 7: return Show_GiveRole(id, g_iMenuPosition[id] = 0, g_iMenuType[id] = 7, "Шпион");
		
		case 8: return PLUGIN_HANDLED;
		case 9: return Show_MafiaMenu(id);
	}
	return PLUGIN_HANDLED;
}

Show_GiveRole(id, iPos, iRole, title[32])
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iPlayersNum, g_iMenuTitle[32];
	copy(g_iMenuTitle, charsmax(g_iMenuTitle), title);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1) continue;
		g_iUserID[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;

	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;

	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));

	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_RoleMenu(id)
		}
		case 1: FormatMain("\w%s^n^n", g_iMenuTitle);
		default: FormatMain("\w%s \r[%d|%d]^n^n", g_iMenuTitle, iPos + 1, iPagesNum);
	}
	new i, iBitKeys = (1<<9), b;

	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iUserID[id][a];

		if(g_iUserRoleMafia[i] == iRole) FormatItem("\y%d. \d%n^n", ++b, i);
		else
		{
			iBitKeys |= (1<<b);
			if(g_iUserRoleMafia[i] != 0) FormatItem("\y%d. \w%n \r- %s^n",++b, i, g_szMafiaRoleName[g_iUserRoleMafia[i]]);
			else FormatItem("\y%d. \w%n^n", ++b, i);
		}
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");

	if(iPos)
	{
		FormatItem("^n\y8. \w%L", id, "JBE_MENU_BACK"), iBitKeys |= (1<<7);
	} 
	else 
	{
		if(g_iMenuType[id] > 1)
		{
			FormatItem("^n^n\y8. \rСлучайнный игрок"), iBitKeys |= (1<<7);
		}else FormatItem("^n\y8. \d%L", id, "JBE_MENU_BACK");
	}
	
	

	if(iPagesNum > 1 && iPos + 1 < iPagesNum)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L", id, "JBE_MENU_NEXT");
	}
	else FormatItem("^n\y9. \d%L", id, "JBE_MENU_NEXT");

	FormatItem("^n\y0. \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, iBitKeys, szMenu, -1, "Show_GiveRole");
}


public Handle_GiveRole(id, iKey)
{
	switch(iKey)
	{
		case 7: 
		{
			if(g_iMenuPosition[id])
			{
				return Show_GiveRole(id, --g_iMenuPosition[id], g_iMenuType[id], "Выдача ролей");
			}
			else
			{

				if(g_iMenuType[id] > 1)
				{
					static iPlayersnum
					iPlayersnum = fnGetAlive();
					new RandomPlayer = fnGetRandomAlive(random_num(1, iPlayersnum))
					
					if(is_user_connected(RandomPlayer))
					{
						g_iUserRoleMafia[RandomPlayer] = g_iMenuType[id];
						

						
						set_hudmessage(255, 255, 0, -1.0, 0.45, 0, 0.0, 5.0, 0.2, 0.2, -1);
						ShowSyncHudMsg(0, g_iSyncSecondInformer, "Начальник выбрал случайнного игрока в роли - %s", g_szMafiaRoleName[g_iUserRoleMafia[RandomPlayer]]);
						UTIL_SayText(id, "!g* !yВы выбрали игрока !g%n !yв роли - !g%s",RandomPlayer, g_szMafiaRoleName[g_iUserRoleMafia[RandomPlayer]]);
					}
					else
					{
						UTIL_SayText(id, "!g* !yОшибка выбора случайного игрока,(рандомизирован не живой игрок) повторите попытку");
						return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Выдача ролей");
					}

				}else return Show_GiveRole(id, ++g_iMenuPosition[id], g_iMenuType[id], "Выдача ролей");
			}
		}
		case 8: return Show_GiveRole(id, ++g_iMenuPosition[id], g_iMenuType[id], "Выдача ролей");
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iUserID[id][g_iMenuPosition[id] * 7 + iKey];
			if(!jbe_is_user_alive(iTarget) && g_iUserRoleMafia[iTarget] == g_iMenuType[id]) Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Выдать роль");
			switch(g_iMenuType[id])
			{
				case 0: 
				{

					g_iUserRoleMafia[iTarget] = STANDART;
					
					//UTIL_SayText(0, "!g* !yВедущий забрал у игрока %n роль", iTarget);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Забрать роль");
				}
				case 1:  
				{	

					g_iUserRoleMafia[iTarget] = STANDART;
					//UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[STANDART]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Мирный житель");
				}
				case 2:
				{
					if(g_iUserRoleMafia[iTarget] != MAFIA)
					{
						g_iUserRoleMafia[iTarget] = MAFIA;

						UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[MAFIA]);
					}
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Мафия");
				}
				case 3: 
				{

					g_iUserRoleMafia[iTarget] = DOCTOR;
					UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[DOCTOR]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Доктор");
				}
				case 4: 
				{

					g_iUserRoleMafia[iTarget] = COMISAR;
					UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[COMISAR]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Комисар");
				}
				case 5: 
				{

					g_iUserRoleMafia[iTarget] = SHLUHA;
					UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[SHLUHA]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Куртизанка");
				}
				case 6: 
				{

					g_iUserRoleMafia[iTarget] = MANIAC;
					UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[MANIAC]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Маньяк");
				}
				case 7: 
				{

					g_iUserRoleMafia[iTarget] = SHPION;
					UTIL_SayText(0, "!g* !yВедущий выбрал игрока в качестве роли - !g%s", g_szMafiaRoleName[SHPION]);
					return Show_GiveRole(id, g_iMenuPosition[id], g_iMenuType[id], "Шпион");
				}
			}
		}
	}
	return PLUGIN_HANDLED;
}

public CanPlayerHearPlayer(iReceiver, iSender, bool:bListen)
{
	if(IsSetBit(g_iBitUserCourtizan, iSender) && jbe_get_user_team(iReceiver) == 1)
	{
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}
	
	if(g_iDayMafia && g_iUserRoleMafia[iSender] == MAFIA && (jbe_is_user_chief(iReceiver) || g_iUserRoleMafia[iReceiver] == MAFIA))
	{
		SetHookChainReturn(ATYPE_BOOL, true);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

/*public VTC_OnClientStartSpeak(const pId)
{
	if(IsSetBit(g_iBitUserCourtizan, pId) && jbe_get_user_team(pId) == 1)
	{
		CenterMsgFix_PrintMsg(pId, print_center, "Вас охмурили, этот день вы молчите");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}*/

stock is_day_sleep()
{
	if(g_iMafiaSleep[0] || g_iMafiaSleep[1] || g_iMafiaSleep[2] || g_iMafiaSleep[3] || g_iMafiaSleep[4])
		return true;
	return false;
}



stock ClearDHUDMessages(index, iClear = 8)
{
        for (new iDHUD = 0; iDHUD < iClear; iDHUD++)
                show_dhudmessage(index, ""); 
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[mafia] UTIL_ScreenFade");
	}
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



fnGetRandomAlive(n)
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= MaxClients; id++)
	{
		if(!jbe_is_user_alive(id) || jbe_get_user_team(id) != 1 || g_iUserRoleMafia[id] != STANDART) continue;

		iAlive++
		
		if (iAlive == n)
			return id;
	}
	
	return -1;
}

fnGetAlive()
{
	static iTs, id
	iTs = 0
	
	for (id = 1; id <= MaxClients; id++)
	{
		if(!jbe_is_user_alive(id) || jbe_get_user_team(id) != 1) continue;

		iTs++
	}
	
	return iTs;
}


stock jbe_get_count_skin()
{
	RedRoles = 0, 
	BlackRoles = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_alive(i) || jbe_get_user_team(i) != 1 || g_iUserRoleMafia[i] == MANIAC || g_iUserRoleMafia[i] == NONE) continue;

		if(g_iUserRoleMafia[i] != MAFIA)
			RedRoles++
		if(g_iUserRoleMafia[i] == MAFIA)
			BlackRoles++
	}
}
