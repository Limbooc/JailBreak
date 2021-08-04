/**
 * Credits: BlackRose, Ian Cammarata, PRoSToTeM@.
 */
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
//#include <gamecms5>
#define PLUGIN "Chat Manager"
#define VERSION "1.1.1-11"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define ADMIN_FLAG ADMIN_BAN


//Colors: DEFAULT, TEAM, GREEN
#define PRETEXT_COLOR			DEFAULT
#define PLAYER_CHAT_COLOR		DEFAULT
#define ADMIN_CHAT_COLOR		DEFAULT
#define PLAYER_NAME_COLOR		TEAM
#define ADMIN_NAME_COLOR		TEAM

#define FUNCTION_ALL_CHAT



#if defined FUNCTION_ALL_CHAT
//Flags: ALIVE_SEE_DEAD, DEAD_SEE_ALIVE, TEAM_SEE_TEAM
#define PLAYER_CHAT_FLAGS (ALIVE_SEE_DEAD|DEAD_SEE_ALIVE)
#define ADMIN_CHAT_FLAGS (ALIVE_SEE_DEAD|DEAD_SEE_ALIVE)
#endif

#define FUNCTION_PLAYER_PREFIX
//#define FUNCTION_ADD_TIME_CODE
//#define FUNCTION_LOG_MESSAGES
//#define FUNCTION_HIDE_SLASH
#define FUNCTION_TRANSLITE
//#define FUNCTION_AES_TAGS
#define FUNCTION_BETA_SUPPORT

#define FUNCTION_ADD_RANK_NAME 					//РАНК ДЖАЙЛ

//#define FUNCTION_ADD_STEAM_PREFIX

#if defined FUNCTION_ADD_STEAM_PREFIX
new const STEAM_PREFIX[] = "^1[^4Steam^1] ";
#endif

#define PREFIX_MAX_LENGTH 64
#define AES_MAX_LENGTH 32

//DONT CHANGE!!!
#define COLOR_BUFFER 6
#define TEXT_LENGTH 128
#define MESSAGE_LENGTH 189

#if defined FUNCTION_AES_TAGS
native aes_get_player_stats(id,data[4]);
native aes_get_level_name(lvlnum,level[],len,idLang = 0);
new const AES_TAG_FORMAT[] = "^1[^3%s^1] ";
#endif
native jbe_get_user_gangid(pId, const GangName[] = "", iLen = 0);
native get_login(id);
//native get_login_club(id, login[], len);
native jbe_mysql_stats_systems_get(id, iType);
native jbe_get_user_team(pId);
const ALIVE_SEE_DEAD = (1 << 0);
const DEAD_SEE_ALIVE = (1 << 1);
const TEAM_SEE_TEAM = (1 << 2);

#if defined FUNCTION_ADD_RANK_NAME
native jbe_get_user_ranks(id);
new const g_szRankName[16][]=
{
	"JBE_ID_HUD_RANK_NAME_1",
	"JBE_ID_HUD_RANK_NAME_2",
	"JBE_ID_HUD_RANK_NAME_3",
	"JBE_ID_HUD_RANK_NAME_4",
	"JBE_ID_HUD_RANK_NAME_5",
	"JBE_ID_HUD_RANK_NAME_6",
	"JBE_ID_HUD_RANK_NAME_7",
	"JBE_ID_HUD_RANK_NAME_8",
	"JBE_ID_HUD_RANK_NAME_9",
	"JBE_ID_HUD_RANK_NAME_10",
	"JBE_ID_HUD_RANK_NAME_11",
	"JBE_ID_HUD_RANK_NAME_12",
	"JBE_ID_HUD_RANK_NAME_13",
	"JBE_ID_HUD_RANK_NAME_14",
	"JBE_ID_HUD_RANK_NAME_15",
	"JBE_ID_HUD_RANK_NAME_16"
};


new const g_szRankNameCT[16][]=
{
	"JBE_ID_HUD_RANK_NAME_CT_1",
	"JBE_ID_HUD_RANK_NAME_CT_2",
	"JBE_ID_HUD_RANK_NAME_CT_3",
	"JBE_ID_HUD_RANK_NAME_CT_4",
	"JBE_ID_HUD_RANK_NAME_CT_5",
	"JBE_ID_HUD_RANK_NAME_CT_6",
	"JBE_ID_HUD_RANK_NAME_CT_7",
	"JBE_ID_HUD_RANK_NAME_CT_8",
	"JBE_ID_HUD_RANK_NAME_CT_9",
	"JBE_ID_HUD_RANK_NAME_CT_10",
	"JBE_ID_HUD_RANK_NAME_CT_11",
	"JBE_ID_HUD_RANK_NAME_CT_12",
	"JBE_ID_HUD_RANK_NAME_CT_13",
	"JBE_ID_HUD_RANK_NAME_CT_14",
	"JBE_ID_HUD_RANK_NAME_CT_15",
	"JBE_ID_HUD_RANK_NAME_CT_16"
};
#endif
enum
{
	DEFAULT = 1,
	TEAM = 3,
	GREEN = 4
};

enum _:FLAG_PREFIX_INFO
{
	m_Flag,
	m_Prefix[PREFIX_MAX_LENGTH]
};

new g_iRankPrefix[MAX_PLAYERS + 1][64];

new const g_TextChannels[][] =
{
	"#Cstrike_Chat_All",
	"#Cstrike_Chat_AllDead",
	"#Cstrike_Chat_T",
	"#Cstrike_Chat_T_Dead",
	"#Cstrike_Chat_CT",
	"#Cstrike_Chat_CT_Dead",
	"#Cstrike_Chat_Spec",
	"#Cstrike_Chat_AllSpec"
};

new g_SayText;
new g_sMessage[MESSAGE_LENGTH];

#if defined FUNCTION_PLAYER_PREFIX
new const FILE_PREFIXES[] = "chatmanager_prefixes.ini";

new g_bCustomPrefix[33], g_sPlayerPrefix[33][PREFIX_MAX_LENGTH];
new Trie:g_tSteamPrefixes, g_iTrieSteamSize;
new Trie:g_tNamePrefixes, g_iTrieNameSize;
new Array:g_aFlagPrefixes, g_iArrayFlagSize;
#endif

#if defined FUNCTION_LOG_MESSAGES
new g_szLogFile[128];
#endif

#if defined FUNCTION_TRANSLITE
new g_bTranslite[33];
#endif

#if defined FUNCTION_ADD_STEAM_PREFIX
new g_bSteamPlayer[33];
#endif

enum Forwards
{
	SEND_MESSAGE
};

enum _:MessageReturn
{
	MESSAGE_IGNORED,
	MESSAGE_CHANGED,
	MESSAGE_BLOCKED
};

new g_iForwards[Forwards];
new g_sNewMessage[MESSAGE_LENGTH];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	#if defined FUNCTION_PLAYER_PREFIX
	register_concmd("cm_set_prefix", "Command_SetPrefix", ADMIN_RCON, "<name or #userid> <prefix>");
	#endif
	
	#if defined FUNCTION_TRANSLITE
	register_clcmd("say /rus", "Command_LangChange");
	register_clcmd("say /eng", "Command_LangChange");
	#endif
	
	register_clcmd("say", "Command_SayHandler");
	register_clcmd("say_team", "Command_SayHandler");
	
	register_message((g_SayText = get_user_msgid("SayText")), "Message_SayText");

	// cm_player_send_message(id, message[], team_chat);
	g_iForwards[SEND_MESSAGE] = CreateMultiForward("cm_player_send_message", ET_STOP, FP_CELL, FP_STRING, FP_CELL);
}
public plugin_cfg()
{
	#if defined FUNCTION_LOG_MESSAGES
	new szDir[] = "addons/amxmodx/logs/chatmanager";
	if(!dir_exists(szDir))
	{
		mkdir(szDir);
	}
	new szDate[16]; get_time("%Y%m%d", szDate, charsmax(szDate));
	formatex(g_szLogFile, charsmax(g_szLogFile), "%s/chatlog_%s.html", szDir, szDate);
	if(!file_exists(g_szLogFile))
	{
		write_file(g_szLogFile, "<meta charset=utf-8><title>ChatManager Log</title>");
	}
	#endif
	
	#if defined FUNCTION_PLAYER_PREFIX
	LoadPlayersPrefixes();
	#endif
	
	#if defined FUNCTION_AES_TAGS
	register_dictionary("aes.txt");
	#endif
}
#if defined FUNCTION_PLAYER_PREFIX
LoadPlayersPrefixes()
{
	new szDir[128]; get_localinfo("amxx_configsdir", szDir, charsmax(szDir));
	new szFile[128]; formatex(szFile, charsmax(szFile), "%s/%s", szDir, FILE_PREFIXES);
	
	if(!file_exists(szFile))
	{
		log_amx("Prefixes file doesn't exist!");
		return;
	}
	
	g_tSteamPrefixes = TrieCreate();
	g_tNamePrefixes = TrieCreate();
	g_aFlagPrefixes = ArrayCreate(FLAG_PREFIX_INFO);
	
	new file = fopen(szFile, "rt");
	
	if(file)
	{
		new szText[128], szType[6], szAuth[32], szPrefix[PREFIX_MAX_LENGTH + COLOR_BUFFER], eFlagPrefix[FLAG_PREFIX_INFO];
		while(!feof(file))
		{
			fgets(file, szText, charsmax(szText));
			parse(szText, szType, charsmax(szType), szAuth, charsmax(szAuth), szPrefix, charsmax(szPrefix));
			
			if(!szType[0] || szType[0] == ';' || !szAuth[0] || !szPrefix[0]) continue;
			
			replace_color_tag(szPrefix);
			
			switch(szType[0])
			{
				case 's'://steam
				{
					TrieSetString(g_tSteamPrefixes, szAuth, szPrefix);
					g_iTrieSteamSize++;
				}
				case 'n'://name
				{
					TrieSetString(g_tNamePrefixes, szAuth, szPrefix);
					g_iTrieNameSize++;
				}
				case 'f'://flag
				{
					eFlagPrefix[m_Flag] = read_flags(szAuth);
					copy(eFlagPrefix[m_Prefix], charsmax(eFlagPrefix[m_Prefix]), szPrefix);
					ArrayPushArray(g_aFlagPrefixes, eFlagPrefix);
					g_iArrayFlagSize++;
				}
			}
		}
		fclose(file);
	}
}
#endif
public plugin_natives()
{
	register_native("cm_set_player_message", "native_set_player_message");
}
public native_set_player_message(plugin, params)
{
	enum { arg_new_message = 1 };
	get_string(arg_new_message, g_sNewMessage, charsmax(g_sNewMessage));
}
public client_putinserver(id)
{
	#if defined FUNCTION_TRANSLITE
	g_bTranslite[id] = false;
	#endif
	
	#if defined FUNCTION_PLAYER_PREFIX
	g_sPlayerPrefix[id] = "";
	g_bCustomPrefix[id] = false;
	jbe_save_stats(id);
	
	new szSteam[32]; get_user_authid(id, szSteam, charsmax(szSteam));
	if(g_iTrieSteamSize && TrieKeyExists(g_tSteamPrefixes, szSteam))
	{
		g_bCustomPrefix[id] = true;
		TrieGetString(g_tSteamPrefixes, szSteam, g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]));
	}
	#endif
	
	#if defined FUNCTION_ADD_STEAM_PREFIX
	g_bSteamPlayer[id] = is_user_steam(id);
	#endif
}


enum _:EXT_DATA_STRUCT {
	EXT_DATA__INDEX,
    EXT_DATA__PREFIX[MAX_NAME_LENGTH],
    EXT_DATA__TYPE
}
/*
public OnAPISendChatPrefix(player, prefix[], type)
{
	new szData[EXT_DATA_STRUCT];
	copy(szData[EXT_DATA__PREFIX], MAX_NAME_LENGTH - 1, prefix);
	szData[EXT_DATA__TYPE] = type;
	szData[EXT_DATA__INDEX] = player;
	set_task(1.0, "ApiPrefix" , player + 56458756 , szData, sizeof szData);
}

public ApiPrefix(arg[],taskid)
{
	new prefix[MAX_NAME_LENGTH];
	new type = arg[EXT_DATA__TYPE];
	new player = arg[EXT_DATA__INDEX];
	copy(prefix, MAX_NAME_LENGTH - 1, arg[EXT_DATA__PREFIX]);
	
	if(strlen(prefix) > 0)
    {
		new g_UserId = cmsapi_get_user_group(player);
		
		if(	g_UserId != 2 && g_UserId != 25 && 
			g_UserId != 26 && g_UserId != 10 && 
			g_UserId != 12 && g_UserId != 13 &&
			g_UserId != 28 && g_UserId != 15)
		{
			g_sPlayerPrefix[player] = "";
			formatex(g_sPlayerPrefix[player], charsmax(g_sPlayerPrefix[]), "^1[^4%s^1]", prefix);
			g_bCustomPrefix[player] = true;
		}
		
		if(type != 1)
			return;
		
		if(cmsapi_get_user_services(player, "", "_nick_prefix", 0))
		{
			formatex(g_sPlayerPrefix[player], charsmax(g_sPlayerPrefix[]), "^1[^4%s^1]", prefix);
			g_bCustomPrefix[player] = true;
		}
    }
}*/

#if defined FUNCTION_PLAYER_PREFIX
public Command_SetPrefix(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;

	new szArg[32]; read_argv(1, szArg, charsmax(szArg));
	new player = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF);
	
	if(!player) return PLUGIN_HANDLED;
	
	new szPrefix[PREFIX_MAX_LENGTH + COLOR_BUFFER]; read_argv(2, szPrefix, charsmax(szPrefix));
	replace_color_tag(szPrefix);
	
	console_print(id, "Ваш префикс был изменен с %s на %s.", g_sPlayerPrefix[player], szPrefix);
	
	copy(g_sPlayerPrefix[player], charsmax(g_sPlayerPrefix[]), szPrefix);
	g_bCustomPrefix[player] = true;
	
	return PLUGIN_HANDLED;
}
#endif
#if defined FUNCTION_TRANSLITE
public Command_LangChange(id)
{
	g_bTranslite[id] = !g_bTranslite[id];
	color_print(id, "^4[Чат]^1 Ваш язык чата изменен на: ^3%s^1.", g_bTranslite[id] ? "Русский" : "Английский");
	return PLUGIN_HANDLED;
}
#endif
public Command_SayHandler(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	new message[TEXT_LENGTH];
	
	read_argv(0, message, charsmax(message));
	new is_team_msg = (message[3] == '_');
	
	read_args(message, charsmax(message));
	remove_quotes(message);
	replace_wrong_simbols(message);
	trim(message);
	
	if(!message[0]) return PLUGIN_HANDLED;
	
	#if defined FUNCTION_HIDE_SLASH
	if(message[0] == '/') return PLUGIN_HANDLED_MAIN;
	#endif
	
	new flags = get_user_flags(id);
	
	new name[32]; get_user_name(id, name, charsmax(name));
	
	#if defined FUNCTION_PLAYER_PREFIX
	if(!g_bCustomPrefix[id])
	{
		if(g_iTrieNameSize && TrieKeyExists(g_tNamePrefixes, name))
		{
			TrieGetString(g_tNamePrefixes, name, g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]));
		}
		else if(g_iArrayFlagSize)
		{
			new eFlagPrefix[FLAG_PREFIX_INFO], bFoundPrefix = false;
			for(new i; i < g_iArrayFlagSize; i++)
			{
				ArrayGetArray(g_aFlagPrefixes, i, eFlagPrefix);
				if(check_flags(flags, eFlagPrefix[m_Flag]))
				{
					bFoundPrefix = true;
					copy(g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]), eFlagPrefix[m_Prefix]);
					break;
				}
			}
			
			if(!bFoundPrefix)
			{
				g_sPlayerPrefix[id] = "";
			}
		}
	}
	#endif
	
	#if defined FUNCTION_TRANSLITE
	if(g_bTranslite[id])
	{
		if(message[0] == '/')
		{
			copy(message, charsmax(message), message[1]);
		}
		else
		{
			new szTranslitedText[TEXT_LENGTH];
			translite_string(szTranslitedText, charsmax(szTranslitedText), message);
			copy(message, charsmax(message), szTranslitedText);
		}
	}
	#endif
	
	new ret; ExecuteForward(g_iForwards[SEND_MESSAGE], ret, id, message, is_team_msg);

	if(ret)
	{
		if(ret == MESSAGE_BLOCKED)
		{
			return PLUGIN_HANDLED;
		}
		copy(message, charsmax(message), g_sNewMessage);
	}

	if(!message[0])
	{
		return PLUGIN_HANDLED;
	}

	new name_color = flags & ADMIN_FLAG ? ADMIN_NAME_COLOR : PLAYER_NAME_COLOR;
	new chat_color = flags & ADMIN_FLAG ? ADMIN_CHAT_COLOR : PLAYER_CHAT_COLOR;
	
	new time_code[16]; get_time("[%H:%M:%S] ", time_code, charsmax(time_code));
	
	new is_sender_alive = is_user_alive(id);
	new CsTeams:sender_team = cs_get_user_team(id);
	
	new channel = get_user_text_channel(is_sender_alive, is_team_msg, sender_team);
	
	FormatMessage(id, sender_team, channel, name_color, chat_color, time_code, message);
	
	#if defined FUNCTION_ALL_CHAT
	new players[32], players_num; get_players(players, players_num, "ch");
	new player, is_player_alive, CsTeams:player_team, player_flags;
	for(new i; i < players_num; i++)
	{
		player = players[i];
		
		if(player == id) continue;
		
		is_player_alive = is_user_alive(player);
		player_team = cs_get_user_team(player);
		player_flags = get_user_flags(player) & ADMIN_FLAG ? ADMIN_CHAT_FLAGS : PLAYER_CHAT_FLAGS;
		
		if(player_flags & ALIVE_SEE_DEAD && !is_sender_alive && is_player_alive && (!is_team_msg || is_team_msg && sender_team == player_team) //flag ALIVE_SEE_DEAD
		|| player_flags & DEAD_SEE_ALIVE && is_sender_alive && !is_player_alive && (!is_team_msg || is_team_msg && sender_team == player_team) //flag DEAD_SEE_ALIVE
		|| player_flags & TEAM_SEE_TEAM && is_team_msg && sender_team != player_team) //flag TEAM_SEE_TEAM
		{
			emessage_begin(MSG_ONE, g_SayText, _, player);
			ewrite_byte(id);
			ewrite_string(g_TextChannels[channel]);
			ewrite_string("");
			ewrite_string("");
			emessage_end();
		}
	}

		
	#endif
	
	#if defined FUNCTION_LOG_MESSAGES
	static const szTeamColor[CsTeams][] = {"gray", "red", "blue", "gray"};
	new szLogMessage[256];
	formatex(szLogMessage, charsmax(szLogMessage), "<br><font color=black>%s %s %s <font color=%s><b>%s</b> </font>:</font><font color=%s> %s </font>", time_code, is_sender_alive ? "" : (_:sender_team == 1 || _:sender_team == 2 ? "*DEAD*" : "*SPEC*"), is_team_msg ? "(TEAM)" : "", szTeamColor[sender_team], name, chat_color == GREEN ? "green" : "#FFB41E", message);
	write_file(g_szLogFile, szLogMessage);
	#endif
	
	return PLUGIN_CONTINUE;
}
public FormatMessage(sender, CsTeams:sender_team, channel, name_color, chat_color, time_code[], message[])
{
	static const szTeamNames[CsTeams][] = {"(Спектор)", "(Зек)", "(Охрана)", "(Спектор)"};
	
	new szText[MESSAGE_LENGTH], len = 1;
	szText[0] = PRETEXT_COLOR;
	
	if(channel % 2)
	{
		len += formatex(szText[len], charsmax(szText) - len, "%s", channel != 7 ? "*Мертв*" : "*Спектор*");
	}
	
	if(channel > 1 && channel < 7)
	{
		len += formatex(szText[len], charsmax(szText) - len, "%s ", szTeamNames[sender_team]);
	}
	else if(channel)
	{
		len += formatex(szText[len], charsmax(szText) - len, " ");
	}
	#if defined FUNCTION_ADD_RANK_NAME
	if(get_login(sender))
	{
		if(!jbe_mysql_stats_systems_get(sender, 52))
		{
			len += formatex(szText[len], charsmax(szText) - len, "%s", g_iRankPrefix[sender]);
		}
		
	}//else len += formatex(szText[len], charsmax(szText) - len, "^1[no reg] ");
	//len += formatex(szText[len], charsmax(szText) - len, "%s", g_iRankPrefix[sender]);
	#endif
	#if defined FUNCTION_ADD_TIME_CODE
	len += formatex(szText[len], charsmax(szText) - len, "%s", time_code);
	#endif
	
	#if defined FUNCTION_ADD_STEAM_PREFIX
	if(g_bSteamPlayer[sender])
	{
		len += formatex(szText[len], charsmax(szText) - len, "%s", STEAM_PREFIX);
	}
	#endif
	
	#if defined FUNCTION_AES_TAGS
	new data[4], szAesTag[AES_MAX_LENGTH]; aes_get_player_stats(sender, data); aes_get_level_name(data[1], szAesTag, charsmax(szAesTag));
	len += formatex(szText[len], charsmax(szText) - len, AES_TAG_FORMAT, szAesTag);
	#endif
	
	
	
	#if defined FUNCTION_PLAYER_PREFIX
	if(get_login(sender)) 
	{

		/*if(!jbe_mysql_stats_systems_get(sender, 54))
		{
			new ClubName[32];
			get_login_club(sender, ClubName, 31);
			if(strlen(ClubName) > 0)
			{
				len += formatex(szText[len], charsmax(szText) - len, "^1[^3%s^1] ", ClubName);
			}
		}*/
		if(!jbe_mysql_stats_systems_get(sender, 53))
		{
			len += formatex(szText[len], charsmax(szText) - len, "%s ", g_sPlayerPrefix[sender]);
		}
	}
	//len += formatex(szText[len], charsmax(szText) - len, "%s ", g_sPlayerPrefix[sender]);
	#endif
	
	

	
	#if defined FUNCTION_BETA_SUPPORT
	new name[32]; get_user_name(sender, name, charsmax(name));
	len += formatex(szText[len], charsmax(szText) - len, "%c%s^1 :%c %s", name_color, name, chat_color, message);
	#else
	len += formatex(szText[len], charsmax(szText) - len, "%c%%s1^1 :%c %s", name_color, chat_color, message);
	#endif
	
	copy(g_sMessage, charsmax(g_sMessage), szText);
}
public Message_SayText(msgid, dest, receiver)
{
	if(get_msg_args() != 4) return PLUGIN_CONTINUE;
	
	new str2[22]; get_msg_arg_string(2, str2, charsmax(str2));
	
	new channel = get_msg_channel(str2);
	
	if(!channel) return PLUGIN_CONTINUE;
	
	new str3[2]; get_msg_arg_string(3, str3, charsmax(str3));
	
	if(str3[0]) return PLUGIN_CONTINUE;
	
	set_msg_arg_string(2, g_sMessage);
	set_msg_arg_string(4, "");
	
	return PLUGIN_CONTINUE;
}
public jbe_set_team_fwd(pId) 
{
	if(get_login(pId))
	{
		if(jbe_get_user_gangid(pId))
		{
			jbe_get_user_gangid(pId, g_iRankPrefix[pId], 31);
		}
		else update_rank(pId);
	}else formatex(g_iRankPrefix[pId], 31, "^1[no reg] ");
}

public jbe_update_rank(pId)
{
	if(get_login(pId))
	{
		if(jbe_get_user_gangid(pId))
		{
			jbe_get_user_gangid(pId, g_iRankPrefix[pId], 31);
		}
		else
		{
			update_rank(pId);
		}
	}else jbe_save_stats(pId);
}

stock update_rank(pId)
{
	switch(jbe_get_user_team(pId))
	{
		case 1: formatex(g_iRankPrefix[pId], 63, "^1[^3%L^1] ", pId, g_szRankName[jbe_get_user_ranks(pId)]);
		case 2: formatex(g_iRankPrefix[pId], 63, "^1[^3%L^1] ", pId, g_szRankNameCT[jbe_get_user_ranks(pId)]);
	}
}


public jbe_save_stats(pId)
{

	formatex(g_iRankPrefix[pId], 31, "^1[no reg] ");
}

public jbe_load_gangs(pId, GangId, GangName[])
{
	new szPrefix[32];
	
	copy(szPrefix, 63, GangName);
	//server_print("%s | %s", GangName , szPrefix);
	formatex(g_iRankPrefix[pId], 63, "^1[^3%s^1] ", szPrefix);
}

public jbe_end_gangs(pId) jbe_update_rank(pId);

get_msg_channel(str[])
{
	for(new i; i < sizeof(g_TextChannels); i++)
	{
		if(equal(str, g_TextChannels[i]))
		{
			return i + 1;
		}
	}
	return 0;
}
stock get_user_text_channel(is_sender_alive, is_team_msg, CsTeams:sender_team)
{
	if (is_team_msg)
	{
		switch(sender_team)
		{
			case CS_TEAM_T:
			{
				return is_sender_alive ? 2 : 3;
			}
			case CS_TEAM_CT:
			{
				return is_sender_alive ? 4 : 5;
			}
			default:
			{
				return 6;
			}
		}
	}
	return is_sender_alive ? 0 : (sender_team == CS_TEAM_SPECTATOR ? 7 : 1);
}
stock replace_wrong_simbols(string[])
{
	new len = 0;
	for(new i; string[i] != EOS; i++)
	{
		if(string[i] == '%' || string[i] == '#' || 0x01 <= string[i] <= 0x04) continue;
		string[len++] = string[i];
	}
	string[len] = EOS;
}
#if defined FUNCTION_PLAYER_PREFIX
replace_color_tag(string[])
{
	new len = 0;
	for (new i; string[i] != EOS; i++)
	{
		if (string[i] == '!')
		{
			switch (string[++i])
			{
				case 'd': string[len++] = 0x01;
				case 't': string[len++] = 0x03;
				case 'g': string[len++] = 0x04;
				case EOS: break;
				default: string[len++] = string[i];
			}
		}
		else
		{
			string[len++] = string[i];
		}
	}
	string[len] = EOS;
}
#endif

stock translite_string(string[], size, source[])
{
	static const table[][] =
	{
		"Э", "#", ";", "%", "?", "э", "(", ")", "*", "+", "б", "-", "ю", ".", "0", "1", "2", "3", "4",
		"5", "6", "7", "8", "9", "Ж", "ж", "Б", "=", "Ю", ",", "^"", "Ф", "И", "С", "В", "У", "А", "П",
		"Р", "Ш", "О", "Л", "Д", "Ь", "Т", "Щ", "З", "Й", "К", "Ы", "Е", "Г", "М", "Ц", "Ч", "Н", "Я",
		"х", "\", "ъ", ":", "_", "ё", "ф", "и", "с", "в", "у", "а", "п", "р", "ш", "о", "л", "д", "ь",
		"т", "щ", "з", "й", "к", "ы", "е", "г", "м", "ц", "ч", "н", "я", "Х", "/", "Ъ", "Ё"
	};
	
	new len = 0;
	for (new i = 0; source[i] != EOS && len < size; i++)
	{
		new ch = source[i];
		
		if ('"' <= ch <= '~')
		{
			ch -= '"';
			string[len++] = table[ch][0];
			if (table[ch][1] != EOS)
			{
				string[len++] = table[ch][1];
			}
		}
		else
		{
			string[len++] = ch;
		}
	}
	string[len] = EOS;
	
	return len;
}
stock color_print(id, text[], any:...)
{
	new formated[190]; vformat(formated, charsmax(formated), text, 3);
	message_begin(id ? MSG_ONE : MSG_ALL, g_SayText, _, id);
	write_byte(id);
	write_string(formated);
	message_end();
}
stock check_flags(flags, need_flags)
{
	return ((flags & need_flags) == need_flags) ? 1 : 0;
}
stock is_user_steam(id)
{
	static dp_pointer;
	if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id); server_exec();
		return (get_pcvar_num(dp_pointer) == 2) ? true : false;
	}
	return false;
}
