
#include <amxmodx>
#include <amxmisc>

native zl_boss_map()
//#include <colorchat>

#define ACCESS_LEVEL ADMIN_IMMUNITY // админский доступ

enum
{
	TEAM_NONE = 0,
	TEAM_T,
	TEAM_CT,
	TEAM_SPEC,
	
	MAX_TEAMS
};
new const g_cTeamChars[MAX_TEAMS] =
{
	'U',
	'T',
	'C',
	'S'
};
new const g_sTeamNums[MAX_TEAMS][] =
{
	"0",
	"1",
	"2",
	"3"
};
new const g_sClassNums[MAX_TEAMS][] =
{
	"1",
	"2",
	"3",
	"4"
};

// Old Style Menus
stock const FIRST_JOIN_MSG[] =		"#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] =	"#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] =		"#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] =	"#IG_Team_Select_Spect";
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

// New VGUI Menus
stock const VGUI_JOIN_TEAM_NUM =		2;

new g_iTeam[33];
new g_iPlayers[MAX_TEAMS];

new tjm_join_team ;
new tjm_block_change;
new tjm_adm_immune;

public plugin_init()
{
	register_plugin("Team Join Management", "0.3fix", "Exolent&Alucard");
	
	if (!zl_boss_map()) {
		pause("ad")
		return
	}
	register_event("TeamInfo", "event_TeamInfo", "a");
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu");
	tjm_join_team = register_cvar("tjm_join_team", "2");
	tjm_adm_immune = register_cvar("tjm_adm_immune", "1");
	tjm_block_change = register_cvar("tjm_block_change", "1");
}

public plugin_cfg()
{
	if(!zl_boss_map()) return;
	if (get_pcvar_num(tjm_join_team) == 1 || get_pcvar_num(tjm_join_team) == 2 ) { //если надо кидать за КТ или Т, делаем больше лимиты по переводу игроков за одну из команд(например для DeathRun или KZ сервера)
		set_cvar_num("mp_limitteams", 32);
		set_cvar_num("sv_restart", 3);
	}
	server_cmd("exec addons/amxmodx/configs/amxx.cfg"); //фикс странного бага, который не давал сменить квар
}

public client_disconnected(id)
{
	if(!zl_boss_map()) return;
	remove_task(id);
}

public event_TeamInfo()
{
	new id = read_data(1);
	new sTeam[32], iTeam;
	read_data(2, sTeam, sizeof(sTeam) - 1);
	for(new i = 0; i < MAX_TEAMS; i++)
	{
		if(g_cTeamChars[i] == sTeam[0])
		{
			iTeam = i;
			break;
		}
	}
	
	if(g_iTeam[id] != iTeam)
	{
		g_iPlayers[g_iTeam[id]]--;
		g_iTeam[id] = iTeam;
		g_iPlayers[iTeam]++;
	}
}

public message_ShowMenu(iMsgid, iDest, id)
{
	if(get_pcvar_num(tjm_adm_immune) && access(id, ACCESS_LEVEL) ) {
		return PLUGIN_CONTINUE;
	}
	else {
		static sMenuCode[iMaxLen];
		get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
		if(equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC))
		{
			if(should_autojoin(id))
			{
				set_autojoin_task(id, iMsgid);
				return PLUGIN_HANDLED;
			}
		}
		else if(equal(sMenuCode, INGAME_JOIN_MSG) || equal(sMenuCode, INGAME_JOIN_MSG_SPEC))
		{
			if(get_pcvar_num(tjm_block_change))
			{
			new rnd_color = random_num(1,4);
			if (rnd_color == 2 && get_user_team(id) == TEAM_CT) {	
				UTIL_SayText(id, "!y Вы не можете сменить команду!");
			}
			else if (rnd_color == 2 && get_user_team(id) == TEAM_T) {	
				UTIL_SayText(id, "!y Вы не можете сменить команду!");
			}
			else {
				UTIL_SayText(id, "!y%s Вы не можете сменить команду!", rnd_color);
			}
			return PLUGIN_HANDLED;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public message_VGUIMenu(iMsgid, iDest, id)
{
	if(get_pcvar_num(tjm_adm_immune) && access(id, ACCESS_LEVEL)) {
		return PLUGIN_CONTINUE;
	}
	else {
		if(get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM)
		{
			return PLUGIN_CONTINUE;
		}
		
		if(should_autojoin(id))
		{
			set_autojoin_task(id, iMsgid);
			return PLUGIN_HANDLED;
		}
		else if((TEAM_NONE < g_iTeam[id] < TEAM_SPEC) && get_pcvar_num(tjm_block_change))
		{
			new rnd_color = random_num(1,4);
			if (rnd_color == 2 && get_user_team(id) == TEAM_CT) {	
				UTIL_SayText(id, "!y Вы не можете сменить команду!");
			}
			else if (rnd_color == 2 && get_user_team(id) == TEAM_T) {	
				UTIL_SayText(id, "!y Вы не можете сменить команду!");
			}
			else {
				UTIL_SayText(id, "!y%s Вы не можете сменить команду!", rnd_color);
			}
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

stock bool:should_autojoin(id)
{
	return ((5 > get_pcvar_num(tjm_join_team) > 0) && is_user_connected(id) && !(TEAM_NONE < g_iTeam[id] < TEAM_SPEC) && !task_exists(id));
}

stock set_autojoin_task(id, iMsgid)
{
	new iParam[2];
	iParam[0] = iMsgid;
	set_task(0.1, "task_Autojoin", id, iParam, sizeof(iParam));
}

public task_Autojoin(iParam[], id)
{
	new iTeam = get_team(get_cvar_num("tjm_join_team"));
	handle_join(id, iParam[0], iTeam);
}

public get_team(iTeam) {
	switch(iTeam)
	{
		case 1:
		{
			return TEAM_T;
		}
		case 2:
		{
			return TEAM_CT;
		}
		case 3:
		{
			return TEAM_SPEC;
		}
		case 4:
		{
			new iTCount = g_iPlayers[TEAM_T];
			new iCTCount = g_iPlayers[TEAM_CT];
			if(iTCount < iCTCount)
			{
				return TEAM_T;
			}
			else if(iTCount > iCTCount)
			{
				return TEAM_CT;
			}
			else
			{
				return random_num(TEAM_T, TEAM_CT);
			}
		}
	}
	return -1;
}


stock handle_join(id, iMsgid, iTeam)
{
	new iMsgBlock = get_msg_block(iMsgid);
	set_msg_block(iMsgid, BLOCK_SET);
	
	engclient_cmd(id, "jointeam", g_sTeamNums[iTeam]);
	
	new iClass = random_num(1, 4);
	if(1 <= iClass <= 4)
	{
		engclient_cmd(id, "joinclass", g_sClassNums[iClass - 1]);
	}
	set_msg_block(iMsgid, iMsgBlock);
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
}