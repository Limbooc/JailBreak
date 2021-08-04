#include <amxmodx>
#include <amxmisc>
//#include <center_msg_fix>
#include <sqlx>
#include <fakemeta>
#include <reapi>
//#include <jbe_core>

native jbe_get_status_mafia();


//#define REGS_API


#if defined REGS_API

#define RANK_LEVELCREAT		7
native get_login_len(id, login[], iLen)
native get_login(id)
native jbe_get_user_ranks(pId);
forward jbe_load_stats(pId);
forward jbe_save_stats(pId);
#endif

#define TIMESTASK 10
#define BLOCK_USER_TIME 30

new g_iUserJoinInic[MAX_PLAYERS + 1] = 0;


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


#define TASK_JOININGPLAYER 		876964678
//#define DEBUG

#define PLAYERS_PER_PAGE 	8

//#define CREATE_MULTIFORWARD

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define GANG_MAIN		"Gang_Main"
#define GANG_PLAYER		"Gang_Players"
#define GANG_OTHER		"Gang_Other"

#if defined CREATE_MULTIFORWARD
forward RegsCoreApiLoaded(Handle:sqlTuple);
forward RegsCoreApiDisconnect();
#endif

#define TASK_LOAD_PLAYER 9098087
#define TASK_SHOW_MOTD		6786756


const MAX_BUFFER_LENGTH =      2047;
new g_sBuffer[MAX_PLAYERS + 1][MAX_BUFFER_LENGTH + 1];


#define STATSX_SHELL_DESIGN1_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#112233;font-family:Arial}th{background:#558866;color:#FFF;padding:10px 2px;text-align:left}td{padding:4px 3px}table{background:#EEEECC;font-size:16px;font-family:Arial}h2,h3{color:#FFF;font-family:Verdana}#c{background:#E2E2BC}img{height:10px;background:#09F;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#FFF;font-size:20px}</style>"



#if !defined CREATE_MULTIFORWARD
new	g_szRankHost[32], 
	g_szRankUser[32], 
	g_szRankPassword[32], 
	g_szRankDataBase[32];

#endif

new const szText[][] = 
{
	"",
	"пригласил игрока",
	"выгнал игрока",
	"повысил игрока",
	"понизил игрока",
	"покинул банду"
}
enum _:
{
	ACTION_NONE = 0,
	ACTION_INVITE,
	ACTION_LEAVE,
	ACTION_UPDATE,
	ACTION_DOWN,
	ACTION_LEAVE_ME
}

#define ARRAY_LEN_NULL  -1

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS];
	//g_iMenuTarget[MAX_PLAYERS + 1];


new g_iMenuPosition[MAX_PLAYERS + 1];
new g_iPrePareCreateGang[MAX_PLAYERS + 1][MAX_NAME_LENGTH];

//new g_iUserGangId[MAX_PLAYERS + 1];
//new g_iUserPlayerGangId[MAX_PLAYERS + 1];

new Array:g_aData,
	//Array:g_aPlayerData,
	Array:g_aAllPlayerData;
	//g_iGangLen = -1;
	//g_iGangPlayerLen = -1;
	
new g_iBitUserVoice,
	g_iBitUserBlockInvite;
	//g_iBitUserRendering;
	
new g_iFwdLoagGangs,
	g_iFwdEndGangs;
	

const QUERY_LENGTH =	512	// размер переменной sql запроса

enum _:TimeUnit
{
	TIMEUNIT_SECONDS = 0,
	TIMEUNIT_MINUTES,
	TIMEUNIT_HOURS,
	TIMEUNIT_DAYS,
	TIMEUNIT_WEEKS
};

new const g_szTimeUnitName[ TimeUnit ][ 2 ][ ] =
{
	{ "секунда", "секунд" },
	{ "минута", "минут" },
	{ "час",   "часа"   },
	{ "день",    "дней"    },
	{ "неделя",   "недель"   }
};

new const g_iTimeUnitMult[ TimeUnit ] =
{
	1,
	60,
	3600,
	86400,
	604800
};

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

enum eData_PlayerGang
{
	PlayerGang_ArrayIndex,
	PlayerGang_Id,
	PlayerGang_GangName[MAX_NAME_LENGTH],
	PlayerGang_Auth[MAX_AUTHID_LENGTH],
	PlayerGang_Name[MAX_NAME_LENGTH],
	PlayerGang_Login[MAX_NAME_LENGTH],
	PlayerGang_Status,
	PlayerGang_JoinGang
}

new g_iStatusGangPlayer[MAX_PLAYERS + 1][eData_PlayerGang];
new bool:g_iConnectedSQL;

enum _:sql_que_type	// тип sql запроса
{
	SQL_MAINCONNECT,
	SQL_PRELOAD,
	SQL_LOADGANG,
	SQL_PRECREATEGANG,
	SQL_ALREADYGANGNAME,
	SQL_FINDIDGANG,
	SQL_LEAVEGANG,
	SQL_PLAYERCONNECT,
	SQL_CHEKINGNAME,
	SQL_CHECKISUSERGANG,
	SQL_SELECTALLPLAYERS,
	SQL_MOTDHISTORY
}

enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX,
    EXT_DATA__AUTH[MAX_AUTHID_LENGTH],
	EXT_DATA__GANGID,
	EXT_DATA__GANGNAME[MAX_NAME_LENGTH],
	EXT_DATA__LEAVERPIDE,
	EXT_DATA__JOIN,
	EXT_DATA__STATUS
}

#define BANDIT		1
#define DOVERENNYI	2
#define ZAMLIDERA	3
#define LIDER		4
new const g_szStatusName[][] = {
	"Бандит",
	"Доверенный",
	"Правая рука",
	"Лидер"
};
public plugin_init() 
{
	register_plugin("[MYSQL] GangSystems", "1.0", "DalgaPups");
	
	
	g_aData = ArrayCreate(eData_Gang);
	//g_aPlayerData = ArrayCreate(eData_PlayerGang);
	g_aAllPlayerData = ArrayCreate(eData_PlayerGang);
	
	#if !defined CREATE_MULTIFORWARD
	SqlInit();
	#endif
	
	
	plugin_init_second();
	

	
	
	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CanPlayerHearPlayer", false);
	
	
	register_clcmd("+gangvoice", 		"ongangvoice");
	register_clcmd("-gangvoice", 		"offgangvoice");
	register_clcmd("say", 				"Command_HookSay");
	register_clcmd("say_team", 			"Command_HookSay");
	
	g_iFwdLoagGangs = CreateMultiForward("jbe_load_gangs", ET_CONTINUE, FP_CELL, FP_CELL, FP_STRING);
	g_iFwdEndGangs = CreateMultiForward("jbe_end_gangs", ET_CONTINUE, FP_CELL);
	
	//register_forward(FM_AddToFullPack, "add_to_full_pack", 1);
}

public plugin_natives()
{
	register_native("jbe_get_gang_id", "jbe_get_gang_id");
	register_native("jbe_get_user_gangid", "jbe_get_user_gangid");

}

public Array:jbe_get_gang_id() return g_aData;
public jbe_get_user_gangid(nid, params)
{
	new pId = get_param(1);
	new iLen = get_param(2);
	if(iLen > 0)
		set_string(3, g_iStatusGangPlayer[pId][PlayerGang_Name], iLen);
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
		return false;
	else return g_iStatusGangPlayer[pId][PlayerGang_Id];
}
public Command_HookSay(id)
{
	if(jbe_get_status_mafia()) 
	{
		//UTIL_SayText(id, "!g* !yВключен режим мафии");
		return PLUGIN_CONTINUE;
	}
	
	new szBuffer[190];
	read_args(szBuffer, charsmax(szBuffer));
	remove_quotes(szBuffer);
	//while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	
	if(equal(szBuffer, "!", 1))
	{
		if(g_iStatusGangPlayer[id][PlayerGang_Id] == ARRAY_LEN_NULL)
		{
			UTIL_SayText(id, "!g* !yВы не состоите не в одном членов банды");
			return PLUGIN_HANDLED;
		}
		
		//replace(szBuffer, 5, "!", "")
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(!is_user_connected(i) || g_iStatusGangPlayer[i][PlayerGang_Id] != g_iStatusGangPlayer[id][PlayerGang_Id]) continue;

			UTIL_SayText(i, "!y[!gЧат Банды!y] | !t%n !y: !g%s", id, szBuffer);
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}


public ongangvoice(pId)
{
	client_cmd(pId, "+voicerecord");
	SetBit(g_iBitUserVoice, pId);
	return PLUGIN_HANDLED
}
public offgangvoice(pId)
{
	client_cmd(pId, "-voicerecord");
	ClearBit(g_iBitUserVoice, pId);
	return PLUGIN_HANDLED
}

public CanPlayerHearPlayer(iReceiver, iSender, bool:bListen)
{
	if(IsSetBit(g_iBitUserVoice, iReceiver) && (g_iStatusGangPlayer[iReceiver][PlayerGang_Id] == g_iStatusGangPlayer[iSender][PlayerGang_Id]))
	{
		return FnCanHearSender(iReceiver, iSender, true);
	}
	//return FnCanHearSender(iReceiver, iSender, false);
	return HC_CONTINUE
}

FnCanHearSender(Receiver, Sender, bool:status)
{
	#pragma unused Receiver, Sender
	SetHookChainReturn(ATYPE_BOOL, status);
	return HC_SUPERCEDE;
}
public plugin_end()
{
	ArrayDestroy(g_aData);
	ArrayDestroy(g_aAllPlayerData);
	DestroyForward(g_iFwdLoagGangs);
	DestroyForward(g_iFwdEndGangs);
}

new Handle:g_hDBGangHandle;



#if defined CREATE_MULTIFORWARD
public RegsCoreApiLoaded(Handle:sqlTuple)
{
	g_hDBGangHandle = sqlTuple;
	
	if(g_hDBGangHandle == Empty_Handle)
	{
		log_to_file("jbe_gangs.log","[MYSQL] RegsCoreApiLoaded - Error");
		return;
	}

	SQL_SetCharset(g_hDBGangHandle, "utf8");
	
	//server_print("%d", g_hDBGangHandle);
	new query[QUERY_LENGTH];
	
	

	formatex(query, charsmax(query) ,"\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL AUTO_INCREMENT, \
		    `GangName` VARCHAR(32) NOT NULL default '',\
			`Create_Date` int(16) NOT NULL, \
			`LeaderAuth` VARCHAR(35) NOT NULL default '', \
			`LeaderName` VARCHAR(32) NOT NULL default '', \
			`EXP` int(11) NOT NULL, \
			`BONUS` int(11) NOT NULL, \
			`HP` int(11) NOT NULL, \
			`MONEY` int(11) NOT NULL, \
			`SKILL` int(11) NOT NULL,\
			`ACTIVE` int(11) NOT NULL, \
			`LeaderLogin` VARCHAR(32) NOT NULL default '',\
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", GANG_MAIN
	);
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	
	formatex(query, charsmax(query), "\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL, \
			`PlayerGangName` VARCHAR(35) NOT NULL default '',\
			`PlayerAuth` VARCHAR(35) NOT NULL default '',\
		    `PlayerName` VARCHAR(32) NOT NULL default '',\
			`PlayerLogin` VARCHAR(32) NOT NULL default '',\
			`Player_Status` int(11) NOT NULL, \
			`Player_JoinGang` int(16) NOT NULL \
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", GANG_PLAYER
	);
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	formatex(query, charsmax(query), "\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL, \
			`PlayerNamepId` VARCHAR(35) NOT NULL default '',\
			`PlayerNameiTarget` VARCHAR(35) NOT NULL default '',\
			`szText` VARCHAR(128) NOT NULL default '',\
			`iValue` int(11) NOT NULL, \
			`iCount` int(11) NOT NULL, \
			`Player_TimeAction` int(16) NOT NULL \
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", GANG_OTHER
	);
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	g_iConnectedSQL = true;
	
	#if defined DEBUG
	server_print("SQL_MAINSTATUS: %s", g_iConnectedSQL ? "TRUE" : "FALSE")
	#endif
	
	set_task(1.0, "ConnectDBDate");
}
#else
public SqlInit() 
{


	get_cvar_string("jbe_mysql_sql_host", 					g_szRankHost, 		charsmax(g_szRankHost));
	get_cvar_string("jbe_mysql_sql_user", 					g_szRankUser, 		charsmax(g_szRankUser));
	get_cvar_string("jbe_mysql_sql_password", 				g_szRankPassword,	charsmax(g_szRankPassword));
	get_cvar_string("jbe_mysql_sql_database", 				g_szRankDataBase, 	charsmax(g_szRankDataBase));
	

	SQL_SetAffinity("mysql");
	g_hDBGangHandle = SQL_MakeDbTuple(g_szRankHost, g_szRankUser, g_szRankPassword, g_szRankDataBase, 1);

	new error[MAX_NAME_LENGTH], errnum
	new Handle:g_StatsHandle = SQL_Connect(g_hDBGangHandle, errnum, error, MAX_NAME_LENGTH - 1)
	
	if(g_StatsHandle == Empty_Handle)
	{
		new szText[128];
		formatex(szText, charsmax(szText), "%s", error);
		log_to_file("mysqlt.log", "[MYSQL_STATS] MYSQL ERROR: #%d", errnum);
		log_to_file("mysqlt.log", "[MYSQL_STATS] %s", szText);
		return;
	}
	
	SQL_FreeHandle(g_StatsHandle);
	
	//server_print("%d", g_hDBGangHandle);
	new query[QUERY_LENGTH];
	
	

	formatex(query, charsmax(query) ,"\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL AUTO_INCREMENT, \
		    `GangName` VARCHAR(32) NOT NULL default '',\
			`Create_Date` int(11) NOT NULL, \
			`LeaderAuth` VARCHAR(35) NOT NULL default '', \
			`LeaderName` VARCHAR(32) NOT NULL default '', \
			`EXP` int(11) NOT NULL, \
			`BONUS` int(11) NOT NULL, \
			`HP` int(11) NOT NULL, \
			`MONEY` int(11) NOT NULL, \
			`SKILL` int(11) NOT NULL,\
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", GANG_MAIN
	);
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	
	formatex(query, charsmax(query), "\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL, \
			`PlayerGangName` VARCHAR(35) NOT NULL default '',\
			`PlayerAuth` VARCHAR(35) NOT NULL default '',\
		    `PlayerName` VARCHAR(32) NOT NULL default '',\
			`PlayerLogin` VARCHAR(32) NOT NULL default '',\
			`Player_Status` int(11) NOT NULL, \
			`Player_JoinGang` int(11) NOT NULL \
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", GANG_PLAYER
	);
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	g_iConnectedSQL = true;
	
	ConnectDBDate();
}
#endif

Gang_UpgradePlayer(pId, iTarget, iLevel, bool:status)
{
	if(	iTarget == pId ||
		g_iStatusGangPlayer[iTarget][PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id] || 
		g_iStatusGangPlayer[iTarget][PlayerGang_Id] == ARRAY_LEN_NULL
	)
	{
		//server_print("Ошибка")
		UTIL_SayText(pId, "!g[GangSystems] !yПроизошла ошибка, повторите попытку");
		
		return Show_GangCreate(pId);
	}
	
	if(iLevel == LIDER)
	{
		UTIL_SayText(pId, "!g[GangSystems] !yНельзя повысить игрока до лидера");
		return Show_GangCreate(pId);
	}
	if(iLevel < BANDIT)
	{
		UTIL_SayText(pId, "!g[GangSystems] !yнельзя понизить игрока, игрок 1 Уровня (Бандит)");
		return Show_GangCreate(pId);
	}

	g_iStatusGangPlayer[iTarget][PlayerGang_Status] = iLevel;
	new HandleQuery[QUERY_LENGTH];
	
	#if defined REGS_API
	
	if(!get_login(iTarget))
		return PLUGIN_HANDLED;

	new login[MAX_NAME_LENGTH];
	get_login_len(iTarget, login, charsmax(login));
	
	formatex(HandleQuery,charsmax(HandleQuery), "UPDATE %s SET `Player_Status` = '%d' WHERE `PlayerLogin` = '%s';", GANG_PLAYER, g_iStatusGangPlayer[iTarget][PlayerGang_Status], login);
	#else
	new szAuth[MAX_AUTHID_LENGTH]
	get_user_authid(iTarget, szAuth, charsmax(szAuth));

	formatex(HandleQuery,charsmax(HandleQuery), "UPDATE %s SET `Player_Status` = '%d' WHERE `PlayerAuth` = '%s';", GANG_PLAYER, g_iStatusGangPlayer[iTarget][PlayerGang_Status], szAuth);
	#endif
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", HandleQuery);

	if(status)
	{
		GANG_ACTION(pId, iTarget, _ , ACTION_UPDATE, _ );
		//server_print("Повышен")
		UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n !t%s !yповысил игрока !g%n !yдо !g%s", pId,g_iStatusGangPlayer[pId][PlayerGang_GangName], iTarget, g_szStatusName[g_iStatusGangPlayer[iTarget][PlayerGang_Status] - 1]);
	
	}
	else
	{
		GANG_ACTION(pId, iTarget, _ , ACTION_DOWN, _ );
		//server_print("Понижен")
		UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n !t%s !yпонизил игрока !g%n !yдо !g%s", pId,g_iStatusGangPlayer[pId][PlayerGang_GangName], iTarget, g_szStatusName[g_iStatusGangPlayer[iTarget][PlayerGang_Status] - 1]);
	}
	
	//new g_iGangPlayerLen = ArraySize(g_aAllPlayerData) - 1;
	new aDataQuotes[eData_PlayerGang];
	
	

	for(new i, ArraiLen = ArraySize(g_aAllPlayerData) - 1; i < ArraiLen; i++)
	{
		ArrayGetArray(g_aAllPlayerData, i, aDataQuotes);
		
		if(g_iStatusGangPlayer[iTarget][PlayerGang_Id] == aDataQuotes[PlayerGang_Id])
		{
			ArraySetArray(g_aAllPlayerData, i, aDataQuotes);
		}
	}
	
	return Show_GangCreate(pId);
}


public UserForNulledArray(pId)
{
	g_iStatusGangPlayer[pId][PlayerGang_ArrayIndex] = ARRAY_LEN_NULL;
	g_iStatusGangPlayer[pId][PlayerGang_Id] = ARRAY_LEN_NULL;
	formatex(g_iStatusGangPlayer[pId][PlayerGang_GangName], 31, "");
	formatex(g_iStatusGangPlayer[pId][PlayerGang_Auth], 31, "");
	formatex(g_iStatusGangPlayer[pId][PlayerGang_Name], 31, "");
	formatex(g_iStatusGangPlayer[pId][PlayerGang_Login], 31, "");
	g_iStatusGangPlayer[pId][PlayerGang_Status] = ARRAY_LEN_NULL;
	g_iStatusGangPlayer[pId][PlayerGang_JoinGang] = ARRAY_LEN_NULL;
}
public ConnectDBDate()
{
	if(g_iConnectedSQL)
	{
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT * FROM %s", GANG_MAIN);
		
		new sData[EXT_DATA_STRUCT];
		
		sData[EXT_DATA__SQL] = SQL_MAINCONNECT;
		SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
		
		formatex(query,charsmax(query), "SELECT * FROM %s", GANG_PLAYER);
		sData[EXT_DATA__SQL] = SQL_PLAYERCONNECT;
		SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
		
	}
}

public is_gang_active(pId)
{
	if(g_iConnectedSQL)
	{
		new query[QUERY_LENGTH];

		formatex(query,charsmax(query),  "SELECT `GangName` FROM %s WHERE `GangName` = '%s'", GANG_MAIN, g_iPrePareCreateGang[pId]);
		
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_ALREADYGANGNAME;
		sData[EXT_DATA__INDEX] = pId;

		return SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_HANDLED;

}

#if defined REGS_API
public client_putinserver(pId) UserForNulledArray(pId)



public jbe_load_stats(pId)
#else
public client_putinserver(pId)
#endif
{
	UserForNulledArray(pId);
	if(g_iConnectedSQL)
	{
		
		new query[QUERY_LENGTH], que_len;
		
		#if defined REGS_API
		
		if(!get_login(pId))
			return PLUGIN_CONTINUE;
		
		new login[MAX_NAME_LENGTH];
		get_login_len(pId, login, charsmax(login));
		
		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT * FROM %s WHERE `PlayerLogin` = '%s'", GANG_PLAYER, login);
		#else
		new szAuth[MAX_AUTHID_LENGTH];
		get_user_authid(pId, szAuth, MAX_AUTHID_LENGTH - 1);
		
		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT * FROM %s WHERE `PlayerAuth` = '%s'", GANG_PLAYER, szAuth);
		#endif

		

		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_PRELOAD;
		sData[EXT_DATA__INDEX] = pId;
		sData[EXT_DATA__USERID] = get_user_userid(pId);

		SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_CONTINUE;
}
FullDeleteGang(pId)
{	
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] != LIDER)
		return PLUGIN_HANDLED;
		
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
		return PLUGIN_HANDLED;
		
	#if defined REGS_API
	if(!get_login(pId))
			return PLUGIN_CONTINUE;
		
	new login[MAX_NAME_LENGTH];
	get_login_len(pId, login, charsmax(login));
	log_to_file("jbe_gangs.log","[Распад банд] %s | %s | %n", g_iStatusGangPlayer[pId][PlayerGang_GangName], login, pId)
	#endif
	new szQuery[QUERY_LENGTH]
	formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE `id` = '%d'", GANG_MAIN, g_iStatusGangPlayer[pId][PlayerGang_Id]);

	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", szQuery);
	
	formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE `id` = '%d'", GANG_PLAYER, g_iStatusGangPlayer[pId][PlayerGang_Id]);

	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", szQuery);
	
	formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE `id` = '%d'", GANG_OTHER, g_iStatusGangPlayer[pId][PlayerGang_Id]);

	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", szQuery);
	
	
	//new g_iGangPlayerLen = ArraySize(g_aAllPlayerData) - 1;
	new aDataQuotes[eData_PlayerGang];
	
	
	UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n !t(Лидер) !yрасспустил банду !g%s", pId, g_iStatusGangPlayer[pId][PlayerGang_GangName]);
	
	for(new i, ArraiLen = ArraySize(g_aAllPlayerData) - 1; i < ArraiLen; i++)
	{
		ArrayGetArray(g_aAllPlayerData, i, aDataQuotes);
		
		if(g_iStatusGangPlayer[pId][PlayerGang_Id] == aDataQuotes[PlayerGang_Id])
		{
			ArrayDeleteItem(g_aAllPlayerData, i);
			//break;
		}
	}
	
	
	//Удаляем Аррай в Масиве g_aData
	ArrayDeleteItem(g_aData, g_iStatusGangPlayer[pId][PlayerGang_ArrayIndex]);
	
	new iRet;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || g_iStatusGangPlayer[i][PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
		
		ExecuteForward(g_iFwdEndGangs, iRet, i);
		UserForNulledArray(i)
	}
		
	

	return PLUGIN_HANDLED;
}


//Тут где то Iniciator выдает -1
Create_JoiningPlayerForGang(pId, Iniciator)
{
	new query[QUERY_LENGTH];
	
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] != ARRAY_LEN_NULL)
	{
		//server_print("Ошибка игрок уже в банде");
		UTIL_SayText( Iniciator, "!g[GangSystems] !yДанный игрок !g%n !yсостоит в другом(вашем) банде", pId);
		return PLUGIN_HANDLED;
	}
	if(task_exists((Iniciator + TASK_JOININGPLAYER))) 
		remove_task(Iniciator + TASK_JOININGPLAYER);
		
	if(g_iStatusGangPlayer[Iniciator][PlayerGang_Id] == ARRAY_LEN_NULL)
	{
		//server_print("Ошибка игрок уже в банде");
		UTIL_SayText( pId, "!g[GangSystems] !yПроизошла ошибка", pId);
		return PLUGIN_HANDLED;
	}
	new szLogin[MAX_NAME_LENGTH];
	
	new szAuth[MAX_AUTHID_LENGTH]
	get_user_authid(pId, szAuth, charsmax(szAuth));
	
	
	
	#if defined REGS_API
	
	if(!get_login(pId))
		return PLUGIN_HANDLED;
		
	get_login_len(pId, szLogin, charsmax(szLogin));
	
	
	#else
	//formatex(szLogin, charsmax(szLogin), "");
	get_user_authid(pId, szLogin, charsmax(szLogin));
	#endif
	new szName[MAX_NAME_LENGTH];
	get_user_name(pId, szName, charsmax(szName));
	
	
	formatex(query,charsmax(query), "INSERT INTO %s \
	(`id`, `PlayerGangName`, `PlayerAuth`, `PlayerName`, `PlayerLogin`, `Player_Status`, `Player_JoinGang`) \
	VALUES ('%d', '%s', '%s', '%s', '%s', '1', '%d')",GANG_PLAYER, g_iStatusGangPlayer[Iniciator][PlayerGang_Id], g_iStatusGangPlayer[Iniciator][PlayerGang_GangName], szAuth, szName, szLogin, get_systime());
	
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
	
	//server_print("игрок успешно присоединился к банде %s", g_iStatusGangPlayer[pId][PlayerGang_GangName]);
	UTIL_SayText(0, "!g[GangSystems] !yИгрок !g%n !yприсоединился к !g%s !tчленам банд", pId, g_iStatusGangPlayer[pId][PlayerGang_GangName]);
	
	GANG_ACTION(Iniciator, pId, _ , ACTION_INVITE, _ );
	
	
	new szQuery[QUERY_LENGTH];
	
	#if defined REGS_API
	formatex(szQuery,charsmax(szQuery),  "SELECT * FROM %s WHERE `PlayerLogin` = '%s'", GANG_PLAYER, szLogin);
	
	#else
	formatex(szQuery,charsmax(szQuery),  "SELECT * FROM %s WHERE `PlayerAuth` = '%s'", GANG_PLAYER, szAuth);
	#endif
	
	new aData[EXT_DATA_STRUCT];
	aData[EXT_DATA__SQL] = SQL_PRELOAD;
	aData[EXT_DATA__INDEX] = pId;
	aData[EXT_DATA__JOIN] = 1;
	aData[EXT_DATA__USERID] = get_user_userid(pId);

	SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", szQuery, aData, sizeof aData);
	//Show_GangCreate(iTarget);
	
	return PLUGIN_HANDLED;
}




public selectQueryHandler(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szPrefix[64];

			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			

			log_to_file("jbe_gangs.log","%s [%s]", szText, szPrefix)
			log_to_file("jbe_gangs.log","%s",err)


			if(failstate == TQUERY_QUERY_FAILED)
			{
				new lastQue[QUERY_LENGTH], szText2[128];
				formatex(szText2, charsmax(szText2), "======================================================");
				SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
				log_to_file("jbe_gangs.log","%s",szText2)
				log_to_file("jbe_gangs.log","[ SQL ] %s",lastQue)
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	
	switch(data[EXT_DATA__SQL])
	{
		case SQL_PLAYERCONNECT:
		{
			if(SQL_NumResults(query))
			{
				new aData[ eData_PlayerGang ];
				//
				while( SQL_MoreResults( query ) ) 
				{	
					aData[PlayerGang_Id] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"id") );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerAuth"), aData[PlayerGang_Auth], charsmax( aData[PlayerGang_Auth] ) );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerGangName"), aData[PlayerGang_GangName], charsmax( aData[PlayerGang_GangName] ) );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerName"), aData[PlayerGang_Name], charsmax( aData[PlayerGang_Name] ) );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerLogin"), aData[PlayerGang_Login], charsmax( aData[PlayerGang_Login] ) );
					aData[PlayerGang_Status] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_Status") );
					aData[PlayerGang_JoinGang] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_JoinGang") );
					
					ArrayPushArray( g_aAllPlayerData, aData );	
					
					
					//if(!task_exists(id + TASK_LOAD_PLAYER)) set_task(0.1, "gangs_loadplayers", id + TASK_LOAD_PLAYER);
					
					
					//set_task(5.9, "gangs_ex", id);
					
					
					SQL_NextRow( query ); 
				}
			}
		
		}
		case SQL_SELECTALLPLAYERS:
		{
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) 
				return PLUGIN_HANDLED;
			
			SHOW_PLAYERSMENU(id, query, data[EXT_DATA__STATUS])
		}
		case SQL_MOTDHISTORY:
		{
			new id = data[EXT_DATA__INDEX];
			if (!is_user_connected(id)) return PLUGIN_HANDLED;

			static playerName[32],targetName[32],szTempText[192],iTime,iValue, rank;

			rank = 0;
			
			if(SQL_NumResults(query))
			{
				
				new iLen;
				iLen = formatex( g_sBuffer[id][iLen], MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN1_STYLE )
				iLen += formatex( g_sBuffer[id][iLen],MAX_BUFFER_LENGTH - iLen, "<body bgcolor=#000000><table border=1 cellspacing=0 cellpadding=3px><tr><th class=p>#<td class=p><th>Инициатор<th>Действие<th>Игрока<th>Значение<th>Дата" )  
			
				new szTime[64];
				while (SQL_MoreResults(query)) 
				{
					rank++;

					SQL_ReadResult(query, SQL_FieldNameToNum(query,"PlayerNamepId"), playerName, charsmax(playerName));
					SQL_ReadResult(query, SQL_FieldNameToNum(query,"PlayerNameiTarget"), targetName, charsmax(targetName));
					SQL_ReadResult(query, SQL_FieldNameToNum(query,"szText"), szTempText, charsmax(szTempText));
					
					replace_all(playerName, charsmax(playerName), "<", "");
					replace_all(playerName,charsmax(playerName), ">", "");
					
					replace_all(targetName, charsmax(targetName), "<", "");
					replace_all(targetName,charsmax(targetName), ">", "");

					iTime = SQL_ReadResult(query, SQL_FieldNameToNum(query,"Player_TimeAction"));
					
					format_time( szTime , 64 , "%m/%d/%Y - %I:%M:%S" , iTime );
					iValue = SQL_ReadResult(query, SQL_FieldNameToNum(query,"iCount"));
					
					if(rank > 0) 
					{
						iLen += formatex( g_sBuffer[id][iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td class=p>%d<td class=p><td>%s<td>%s<td>%s<td>%d<td>%s", rank , playerName, szTempText, targetName, iValue, szTime);
					}
					SQL_NextRow(query);
				}
				
			}
			
		}
		case SQL_MAINCONNECT:
		{
			if(SQL_NumResults(query))
			{
				new aData[ eData_Gang ];
				
				while( SQL_MoreResults( query ) ) 
				{	
				
					//server_print("%d | %s", SQL_ReadResult( query, 0 ), SQL_ReadResult( query, 1 ));
					aData[Gang_Id] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"id") );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"GangName"), aData[Gang_Name], charsmax( aData[Gang_Name] ) );
					aData[Gang_CreateTime] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Create_Date") );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderAuth"), aData[Gang_LeaderAuth], charsmax( aData[Gang_LeaderAuth] ) );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderName"), aData[Gang_LeaderName], charsmax( aData[Gang_LeaderName] ) );
					aData[Gang_Exp] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"EXP") );
					aData[Gang_Bonus] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"BONUS") );
					aData[Gang_HP] 		= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"HP") );
					aData[Gang_Money] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"MONEY") );
					aData[Gang_Skill] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"SKILL") );
					aData[Gang_Active] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"ACTIVE") );
					SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderLogin"), aData[Gang_LoginLeader], charsmax( aData[Gang_LoginLeader] ) );
					
					//aData[Gang_CountPlayer] = 5;
					
					ArrayPushArray( g_aData, aData );	
					
					/*server_print("**********************************SQL_MAINCONNECT*************************************");
					server_print("GangID: %d^nGangName: %s^nGangCreateTime: %d^nGangLeaderAuth: %s^nLeaderName: %s^nGang_Exp: %d^nGang_Bonus: %d^nGang_HP: %d^nGang_Money: %d^nGang_Skill: %d", 
					aData[Gang_Id], aData[Gang_Name], 
					aData[Gang_CreateTime], aData[Gang_LeaderAuth], 
					aData[Gang_LeaderName], aData[Gang_Exp], 
					aData[Gang_Bonus], aData[Gang_HP], 
					aData[Gang_Money], aData[Gang_Skill]);*/
					
					SQL_NextRow( query ); 
				}
				//g_iGangLen = ArraySize( g_aData );
				
				//server_print("TotalGang: %d", g_iGangLen);
			}
		
		}
		case SQL_PRELOAD: 
		{
			
			
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				#if defined DEBUG
				server_print("SQL_PRELOAD")
				#endif
				if(SQL_NumResults(query))
				{
					#if defined DEBUG
					server_print("SQL_PRELOAD | SQL_NumResults")
					#endif
					
					//new aData[ eData_PlayerGang ];
					//new sData[ eData_Gang ];
					
					while( SQL_MoreResults( query ) ) 
					{	
						/*aData[PlayerGang_Id] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"id") );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerAuth"), aData[PlayerGang_Auth], charsmax( aData[PlayerGang_Auth] ) );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerGangName"), aData[PlayerGang_GangName], charsmax( aData[PlayerGang_GangName] ) );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerName"), aData[PlayerGang_Name], charsmax( aData[PlayerGang_Name] ) );
						aData[PlayerGang_Status] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_Status") );
						aData[PlayerGang_JoinGang] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_JoinGang") );
						
						ArrayPushArray( g_aPlayerData, aData );	*/
						
						//
						g_iStatusGangPlayer[id][PlayerGang_Id] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"id") );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerAuth"), g_iStatusGangPlayer[id][PlayerGang_Auth], MAX_AUTHID_LENGTH - 1 );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerGangName"), g_iStatusGangPlayer[id][PlayerGang_GangName], MAX_NAME_LENGTH - 1 );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerName"), g_iStatusGangPlayer[id][PlayerGang_Name], MAX_NAME_LENGTH - 1 );
						SQL_ReadResult( query, SQL_FieldNameToNum(query,"PlayerLogin"), g_iStatusGangPlayer[id][PlayerGang_Login], MAX_NAME_LENGTH - 1 );
						g_iStatusGangPlayer[id][PlayerGang_Status] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_Status") );
						g_iStatusGangPlayer[id][PlayerGang_JoinGang] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Player_JoinGang") );
						//
						
						//if(!task_exists(id + TASK_LOAD_PLAYER)) set_task(0.1, "gangs_loadplayers", id + TASK_LOAD_PLAYER);
						
						//g_iUserPlayerGangId[id] = g_iStatusGangPlayer[id][PlayerGang_Id];

						/*if(g_iStatusGangPlayer[id][PlayerGang_Id] != ARRAY_LEN_NULL)
						{
							for(new iPos; iPos < ArraySize(g_aData); iPos++) 
							{
								ArrayGetArray(g_aData, iPos, sData);
								
								if(sData[Gang_Id] == g_iStatusGangPlayer[id][PlayerGang_Id])
								{
								
									g_iUserGangId[id] = iPos;
									server_print("foundpos2");
								}
							}
						}*/
						g_iUserJoinInic[id] = 0;
						
						new iRet;
						ExecuteForward(g_iFwdLoagGangs, iRet, id, g_iStatusGangPlayer[id][PlayerGang_Id], g_iStatusGangPlayer[id][PlayerGang_GangName]);
						
						if(data[EXT_DATA__JOIN])
							ArrayPushArray(g_aAllPlayerData, g_iStatusGangPlayer[id]);
						
						g_iStatusGangPlayer[id][PlayerGang_ArrayIndex] = gang_array_index(id);
						
						
						
						//set_task(5.9, "gangs_ex", id);
						SQL_NextRow( query ); 
					}
				
				}
			}
		}
		case SQL_ALREADYGANGNAME:
		{
			new id = data[EXT_DATA__INDEX];
			
			
			if(!SQL_NumResults(query))
			{
			
				#if defined REGS_API
				if(!get_login(id)) return PLUGIN_HANDLED;
				
				if(jbe_get_user_ranks(id) >= RANK_LEVELCREAT && jbe_get_user_team(id) == 1)
				#endif
				{
					new HandleQuery[QUERY_LENGTH];
					
					#if defined REGS_API
					new szLogin[MAX_NAME_LENGTH]
					get_login_len(id, szLogin, charsmax(szLogin));
					
					formatex(HandleQuery,charsmax(HandleQuery),  "SELECT `LeaderLogin` FROM %s WHERE `LeaderLogin` = '%s'", GANG_MAIN, szLogin);
					#else
					new szAuth[MAX_AUTHID_LENGTH];
					get_user_authid(id, szAuth, charsmax(szAuth))
					formatex(HandleQuery,charsmax(HandleQuery),  "SELECT `LeaderLogin` FROM %s WHERE `LeaderAuth` = '%s'", GANG_MAIN, szAuth);
					#endif
					new sData[EXT_DATA_STRUCT];
					sData[EXT_DATA__SQL] = SQL_CHEKINGNAME;
					sData[EXT_DATA__INDEX] = id;

					return SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", HandleQuery, sData, sizeof sData);
				}

				//server_print("не занят")
			}
			else
			{
				formatex(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "");
				UTIL_SayText(id, "!g[GangSystems] !yОшибка, данная название член банд уже занят кем-то, выберите другое");
				#if defined DEBUG
				server_print("уже занят")
				#endif
				
				return Show_GangCreate(id);
			}
		}
		case SQL_CHEKINGNAME:
		{
			new id = data[EXT_DATA__INDEX];
				
				
			if(!SQL_NumResults(query))
			{
				#if defined REGS_API
				if(!get_login(id)) return PLUGIN_HANDLED;
				
				if(jbe_get_user_ranks(id) >= RANK_LEVELCREAT && jbe_get_user_team(id) == 1)
				#endif
				
				CreateGangName(id, g_iPrePareCreateGang[id]);
			}
			else 
			{
				formatex(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "");
				UTIL_SayText(id, "!g[GangSystems] !yОшибка, на ваш логин уже привязано один из банд");
				return Show_GangCreate(id);
			}
		}
		case SQL_PRECREATEGANG:
		{
			new id = data[EXT_DATA__INDEX];
			new query[QUERY_LENGTH];
			new NewGangName[32];
			
			copy(NewGangName, charsmax(NewGangName), data[EXT_DATA__GANGNAME]);
			formatex(query,charsmax(query),  "SELECT * FROM %s WHERE `GangName` = '%s'", GANG_MAIN, NewGangName);
			
			new sData[EXT_DATA_STRUCT];
			sData[EXT_DATA__SQL] = SQL_FINDIDGANG;
			sData[EXT_DATA__INDEX] = id;
			copy(sData[EXT_DATA__GANGNAME], charsmax(sData[EXT_DATA__GANGNAME]), NewGangName);
			
			SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
		
		}
		case SQL_CHECKISUSERGANG:
		{
			new pId = data[EXT_DATA__INDEX];
			new Iniciator = data[EXT_DATA__LEAVERPIDE];
			
			if(!SQL_NumResults(query)) 
			{
				if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
					Create_JoiningPlayerForGang(pId, Iniciator/*, pId*/);
					
				if(task_exists(g_iUserJoinInic[pId] + TASK_JOININGPLAYER)) 
					remove_task(g_iUserJoinInic[pId] + TASK_JOININGPLAYER);
			
				show_menu(pId, 0, "^n");
				g_iUserJoinInic[pId] = 0;
			}
			else
			{

				UTIL_SayText(Iniciator, "!g[GangSystems] !yИгрок !g%n !yуже состоит в каком либо банде", pId);
				UTIL_SayText(pId, "!g[GangSystems] !yОшибка, вы уже состоите где-то в банде");
				
				if(task_exists(g_iUserJoinInic[pId] + TASK_JOININGPLAYER)) 
					remove_task(g_iUserJoinInic[pId] + TASK_JOININGPLAYER);
			
				show_menu(pId, 0, "^n");
				g_iUserJoinInic[pId] = 0;
			}
		
		
		}
		case SQL_FINDIDGANG:
		{
			if(SQL_NumResults(query)) 
			{
				new id = data[EXT_DATA__INDEX];
				new NewGangName[32];
				
				new szAuth[MAX_AUTHID_LENGTH];
				get_user_authid(id, szAuth, charsmax(szAuth));
				
				new szName[MAX_NAME_LENGTH];
				get_user_name(id, szName, charsmax(szName));
				
				copy(NewGangName, charsmax(NewGangName), data[EXT_DATA__GANGNAME]);
				
				
				new ArrayData[ eData_Gang ];
				//server_print("%d | %s", SQL_ReadResult( query, 0 ), SQL_ReadResult( query, 1 ));
				ArrayData[Gang_Id] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"id") );
				//SQL_ReadResult( query, SQL_FieldNameToNum(query,"GangName"), ArrayData[Gang_Name], charsmax( ArrayData[Gang_Name] ) );
				copy(ArrayData[Gang_Name], charsmax(ArrayData[Gang_Name]), NewGangName);
				ArrayData[Gang_CreateTime] = SQL_ReadResult( query, SQL_FieldNameToNum(query,"Create_Date") );
				SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderAuth"), ArrayData[Gang_LeaderAuth], charsmax( ArrayData[Gang_LeaderAuth] ) );
				SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderName"), ArrayData[Gang_LeaderName], charsmax( ArrayData[Gang_LeaderName] ) );
				ArrayData[Gang_Exp] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"EXP") );
				ArrayData[Gang_Bonus] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"BONUS") );
				ArrayData[Gang_HP] 		= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"HP") );
				ArrayData[Gang_Money] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"MONEY") );
				ArrayData[Gang_Skill] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"SKILL") );
				ArrayData[Gang_Active] 	= 	SQL_ReadResult( query, SQL_FieldNameToNum(query,"ACTIVE") );
				SQL_ReadResult( query, SQL_FieldNameToNum(query,"LeaderLogin"), ArrayData[Gang_LoginLeader], charsmax( ArrayData[Gang_LoginLeader] ) );
				//new temp = ArrayGetCell( g_aData, ArrayData );
				ArrayPushArray( g_aData, ArrayData );	
				
				//g_iGangLen++;
				
				

				new query[QUERY_LENGTH];
				
				
				new szLogin[MAX_NAME_LENGTH];
	
				#if defined REGS_API
				
				if(!get_login(id))
					return PLUGIN_HANDLED;
					
				get_login_len(id, szLogin, charsmax(szLogin));
				
				#else
				//formatex(szLogin, charsmax(szLogin), "");
				get_user_authid(id, szLogin, charsmax(szLogin));
				#endif
				
				
				formatex(query,charsmax(query), "INSERT INTO %s \
				(`id`, `PlayerGangName`, `PlayerAuth`, `PlayerName`, `Player_Status`, `Player_JoinGang`, `PlayerLogin`) \
				VALUES ('%d', '%s', '%s', '%s', '4','%d', '%s' )",GANG_PLAYER, ArrayData[Gang_Id], NewGangName, szAuth, szName, get_systime(), szLogin);
				
				SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
				
				new szQuery[QUERY_LENGTH]
				#if defined REGS_API
				formatex(szQuery,charsmax(szQuery),  "SELECT * FROM %s WHERE `PlayerLogin` = '%s'", GANG_PLAYER, szLogin);
				#else
				formatex(szQuery,charsmax(szQuery),  "SELECT * FROM %s WHERE `PlayerAuth` = '%s'", GANG_PLAYER, szAuth);
				#endif
				new aData[EXT_DATA_STRUCT];
				aData[EXT_DATA__SQL] = SQL_PRELOAD;
				aData[EXT_DATA__INDEX] = id;
				aData[EXT_DATA__JOIN] = 1;
				aData[EXT_DATA__USERID] = get_user_userid(id);

				SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", szQuery, aData, sizeof aData);
			
			}
		
		}
	}
	
	return PLUGIN_HANDLED;
}

public IgnoreHandle(failstate, Handle:query, err[], errNum, data[], datalen, Float:queuetime) 
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			if(datalen) log_to_file("mysqlt.log", "Query state: %d", data[0]);
			log_to_file("mysqlt.log","%s", szText)
			log_to_file("mysqlt.log","%s",err)
			
			new lastQue[QUERY_LENGTH]

			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_to_file("mysqlt.log","[ SQL ] %s",lastQue)
			return PLUGIN_CONTINUE;
		}
	}

	SQL_FreeHandle(query);
	return PLUGIN_CONTINUE;
}



CreateGangName(id, gangname[]="")
{

	new NewGangName[MAX_NAME_LENGTH];
	
	copy(NewGangName, charsmax(NewGangName), gangname);
	
	//server_print("%s", NewGangName);
	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuth, charsmax(szAuth));
	
	new szName[MAX_NAME_LENGTH];
	get_user_name(id, szName, charsmax(szName));
	
	
	if(g_iStatusGangPlayer[id][PlayerGang_Id] != ARRAY_LEN_NULL)
	{
		return Show_GangCreate(id);
	}
	new query[QUERY_LENGTH];
	
	//server_print("%s, %s, %s", NewGangName,szAuth ,szName)
	
	new szLogin[MAX_NAME_LENGTH]
	
	#if defined REGS_API
	
	if(!get_login(id))
		return PLUGIN_HANDLED;
		
	get_login_len(id, szLogin, charsmax(szLogin));
	
	#else
	//formatex(szLogin, charsmax(szLogin), "");
	get_user_authid(id, szLogin, charsmax(szLogin));
	#endif

	formatex(query,charsmax(query), "INSERT INTO %s \
	(`GangName`, `Create_Date`, `LeaderAuth`, `LeaderName`, `EXP`, `BONUS`, `HP`, `MONEY`, `SKILL`, `ACTIVE`, `LeaderLogin`) \
	VALUES ('%s', '%d', '%s', '%s', '0', '0', '0', '0', '0', '1', '%s')",GANG_MAIN, NewGangName, get_systime(), szAuth, szName, szLogin);
	
	UTIL_SayText(id, "!g[GangSystems] !yИгрок !g%n !yсоздал новую банду !g%s.", id, NewGangName);
	
	
	
	//server_print("банда успешно создана");
	if(strlen(g_iPrePareCreateGang[id])) formatex(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "");
	
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_PRECREATEGANG;
	sData[EXT_DATA__INDEX] = id;
	copy(sData[EXT_DATA__GANGNAME], charsmax(sData[EXT_DATA__GANGNAME]), NewGangName);
	SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", query, sData, sizeof sData);
	return PLUGIN_HANDLED;
}

LeavePlayerGang(pId, Iniciator = 0)
{
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
	{
		return PLUGIN_HANDLED;
	}

	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(pId, szAuth, charsmax(szAuth));
	
	new szQuery[QUERY_LENGTH]
	if(is_user_connected(Iniciator))
	{
		if(g_iStatusGangPlayer[Iniciator][PlayerGang_Id] == ARRAY_LEN_NULL)
		{
			return PLUGIN_HANDLED;
		}
		if(Iniciator == pId)
		{
				UTIL_SayText(Iniciator, "!g* !yПроизошла ошибка, повторите попытку");
				return PLUGIN_HANDLED;
		}
		if(g_iStatusGangPlayer[pId][PlayerGang_Status] == LIDER)
		{
			UTIL_SayText(Iniciator, "!g[GangSystems] !yИгрок лидер, его нельзя выгнать");
			return PLUGIN_HANDLED;
		}
		#if defined REGS_API
		
		if(!get_login(Iniciator))
			return PLUGIN_HANDLED;
		
		
			
		new szLogin[MAX_NAME_LENGTH];
		get_login_len(pId, szLogin, charsmax(szLogin));
		formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE (`PlayerLogin` = '%s' AND `id` = '%d')", GANG_PLAYER, szLogin, g_iStatusGangPlayer[Iniciator][PlayerGang_Id]);
		
		#else
		formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE (`PlayerAuth` = '%s' AND `id` = '%d')", GANG_PLAYER, szAuth, g_iStatusGangPlayer[Iniciator][PlayerGang_Id]);
		#endif

		UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n  !yисключил игрока !g%n !yиз банды !g%s",Iniciator, pId, g_iStatusGangPlayer[Iniciator][PlayerGang_GangName]);
		
		GANG_ACTION(Iniciator, pId, _ , ACTION_LEAVE, _ );
	}
	else 
	{
		#if defined REGS_API
		
		if(!get_login(pId))
			return PLUGIN_HANDLED;
			
		if(g_iStatusGangPlayer[pId][PlayerGang_Status] == LIDER)
		{
			UTIL_SayText(pId, "!g[GangSystems] !yВы лидер данной банды, уйти нельзя, но можете расспустить банду");
			return PLUGIN_HANDLED;
		}
		
		new szLogin[MAX_NAME_LENGTH];
		get_login_len(pId, szLogin, charsmax(szLogin));
		formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE (`PlayerLogin` = '%s' AND `id` = '%d')", GANG_PLAYER, szLogin, g_iStatusGangPlayer[pId][PlayerGang_Id]);
		
		#else
		formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE (`PlayerAuth` = '%s' AND `id` = '%d')", GANG_PLAYER, szAuth, g_iStatusGangPlayer[pId][PlayerGang_Id]);
		#endif
		
		GANG_ACTION(pId, _, _ , ACTION_LEAVE_ME, _ );
	}
	
	
	
	/*new aDataQuotes[eData_PlayerGang];

	for(new ArrayIndex, g_iGangPlayerLen = ArraySize(g_aAllPlayerData) - 1; ArrayIndex < g_iGangPlayerLen; ArrayIndex++)
	{
		ArrayGetArray(g_aAllPlayerData, g_iStatusGangPlayer[Iniciator][PlayerGang_Id], aDataQuotes);
		if(aDataQuotes[PlayerGang_Id] == g_iStatusGangPlayer[pId][PlayerGang_Id])
		{
			ArrayDeleteItem(g_aAllPlayerData, ArrayIndex);
		}
	}*/
	new iRet;
	ExecuteForward(g_iFwdEndGangs, iRet, pId);
	ArrayDeleteItem(g_aAllPlayerData, g_iStatusGangPlayer[pId][PlayerGang_ArrayIndex]);
	
	UserForNulledArray(pId);
	
	

	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", szQuery);
	return PLUGIN_HANDLED;
}


#if defined REGS_API
public client_disconnected(id)
{
	ClearBit(g_iBitUserBlockInvite, id);
	

}
public jbe_save_stats(id)
#else
public client_disconnected(id)
#endif
{

	//g_iStatusGangPlayer[id][PlayerGang_Id] = ARRAY_LEN_NULL
	UserForNulledArray(id);
	if(strlen(g_iPrePareCreateGang[id])) formatex(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "");
	
	ClearBit(g_iBitUserVoice, id);
	
	if(task_exists(id + TASK_SHOW_MOTD)) remove_task(id + TASK_SHOW_MOTD)
}







plugin_init_second()
{
	register_clcmd("GangName" , "clcmd_gangname");
	
	register_menucmd(register_menuid("Show_GangCreate"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GangCreate");
	register_menucmd(register_menuid("Show_LeavePlayerGang"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_LeavePlayerGang");
	register_menucmd(register_menuid("Show_InfoForGang"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_InfoForGang");
	register_menucmd(register_menuid("Show_PlayersGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_PlayersGangs");
	register_menucmd(register_menuid("Show_JoinGangPlayer"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_JoinGangPlayer");
	
	register_menucmd(register_menuid("Show_SetupGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_SetupGangs");
	register_menucmd(register_menuid("Show_UpStatusPlayer"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_UpStatusPlayer");
	register_menucmd(register_menuid("Show_DownStatusPlayer"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_DownStatusPlayer");
	register_menucmd(register_menuid("Show_DeleteGang"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_DeleteGang");
	
	//register_menucmd(register_menuid("Show_LeavingPlayerGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_LeavingPlayerGangs");
	register_menucmd(register_menuid("Show_AcceptJoinGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_AcceptJoinGangs");
	register_menucmd(register_menuid("Show_LevelGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_LevelGangs");
	register_menucmd(register_menuid("Show_ShowAllGangs"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ShowAllGangs");
	
	
	register_clcmd("say /gang", "crgang");
}


public crgang(id) 
{
	#if defined REGS_API
	if(!get_login(id))
	{
		UTIL_SayText(id, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}else 
	#endif
	return Show_GangCreate(id);
}
public clcmd_gangname(id) 
{
	#if defined REGS_API
	if(!get_login(id))
	{
		UTIL_SayText(id, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	read_argv(1, g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]))
	
	if(strlen(g_iPrePareCreateGang[id]) > charsmax(g_iPrePareCreateGang[]) || strlen(g_iPrePareCreateGang[id]) < 1)
	{
		formatex(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "")
		client_print_color(id, print_team_default, "^x04[AuthSystems]^x01 Некоректные данные, введите от 1 до 31 символов!");
		return false;
	}
	/*if(!IsAllCharsValid(g_sLogin[id], false))
	{
		formatex(g_sLogin[id], charsmax(g_sLogin), "")
		client_print_color(id, print_team_default, "^x04[AuthSystems]^x01 Разрешены след.символы :^x04 1-9, A-Z");
		return false;
	}*/
	//replace(g_iPrePareCreateGang[id], charsmax(g_iPrePareCreateGang[]), "'", "")
	re_mysql_escape_string(g_iPrePareCreateGang[id], MAX_NAME_LENGTH - 1);
	
	return Show_GangCreate(id)
}


Show_GangCreate(id)
{
	#if defined REGS_API
	if(!get_login(id))
	{
		return PLUGIN_HANDLED;
	}
	#endif
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	

	if(g_iStatusGangPlayer[id][PlayerGang_Id] == ARRAY_LEN_NULL)
	{
		#if defined REGS_API
		FormatMain("\yСистема \rБанд^n\wТекущая Банда: \yНету^n^n");
		#else 
		FormatMain("\yБанда^n^n");
		#endif
		FormatItem("\y1. \wНазвание банды: \y%s^n", g_iPrePareCreateGang[id]), iKeys |= (1<<0);
		if(strlen(g_iPrePareCreateGang[id]) > 1)
		{
			#if defined REGS_API
			if(jbe_get_user_ranks(id) >= RANK_LEVELCREAT && jbe_get_user_team(id) == 1)
				FormatItem("\y2. \wСоздать банду^n"), iKeys |= (1<<1);
			else
			FormatItem("\y2. \dСоздать банду \r(Низкий уровень)^n");
			#else
			FormatItem("\y2. \wСоздать банду^n"), iKeys |= (1<<1);
			#endif
		}
		else FormatItem("\y2. \dСоздать банду^n");
		
		FormatItem("^n^n\y3. \yСписок всех банд^n"), iKeys |= (1<<2);
		
		
		
		FormatItem("^n^n^n\dСистема в стадии тестирование!^n");
	}
	else
	{
		if(g_iStatusGangPlayer[id][PlayerGang_Id] == ARRAY_LEN_NULL)
		{
			return PLUGIN_HANDLED;
		}
		new i = gangplayer_info_count(id);
		
		FormatMain("\yСистема \rБанд^n\yТекущая Банда: \r%s^nВсего игроков: \r%d^n\yВаш статус : \r%s^n^n", g_iStatusGangPlayer[id][PlayerGang_GangName], i, g_szStatusName[g_iStatusGangPlayer[id][PlayerGang_Status] - 1]);
		
		if(g_iStatusGangPlayer[id][PlayerGang_Status] >= ZAMLIDERA)
		{
			FormatItem("\y1. \wНастройка банды^n"), iKeys |= (1<<0);
		}else FormatItem("\y1. \dНастройка банды^n");
		if(g_iStatusGangPlayer[id][PlayerGang_Status] != LIDER)
		{
			FormatItem("\y2. \wПокинуть банду^n"), iKeys |= (1<<1);
		}else FormatItem("\y2. \dПокинуть банду \r(вы лидер)^n");
		if(g_iStatusGangPlayer[id][PlayerGang_Status] >= ZAMLIDERA)
		{
			FormatItem("\y3. \wПозвать игрока в банду^n"), iKeys |= (1<<2);
		}else FormatItem("\y3. \dПозвать игрока в банду^n");
		
		FormatItem("\y4. \wИнформации о банде^n"), iKeys |= (1<<3);
		
		FormatItem("^n^n\y5. \yСписок всех банд^n"), iKeys |= (1<<4);
		
		FormatItem("\y6. \wИстория действий банды^n"), iKeys |= (1<<5);
		
		//FormatItem("^n^n\y6. \y^n"), iKeys |= (1<<4);
		FormatItem("^n^n^n\dСистема в стадии тестирование!^n");
		
	}
	//FormatItem("^n^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_GangCreate");
}

public Handle_GangCreate(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
		
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
	{

		switch(iKey)
		{
			case 0:
			{
				client_cmd(pId, "messagemode ^"GangName^"")  
			}
			case 1:
			{
				if(strlen(g_iPrePareCreateGang[pId]) > 1)
					return is_gang_active(pId);
			}
			case 2: return Cmd_ShowAllGangs(pId);
			case 9: return PLUGIN_HANDLED;
		
		}
	}
	else
	{
		if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
		{
			return PLUGIN_HANDLED;
		}
		/*new aData[eData_PlayerGang];
		ArrayGetArray(g_aPlayerData, g_iUserPlayerGangId[pId], aData);*/
		switch(iKey)
		{
			case 0: 
			{
				if(g_iStatusGangPlayer[pId][PlayerGang_Status] < ZAMLIDERA)
				{
					return PLUGIN_HANDLED;
				}else return Show_SetupGangs(pId);
			}
			case 1: return Show_LeavePlayerGang(pId);
			case 2: 
			{
				if(g_iStatusGangPlayer[pId][PlayerGang_Status] < ZAMLIDERA)
				{
					return PLUGIN_HANDLED;
				}else return Cmd_JoinGangPlayer(pId);
			}
			case 3: return Show_InfoForGang(pId);
			case 4: return Cmd_ShowAllGangs(pId);
			case 5: 
			{
				if(task_exists(pId + TASK_SHOW_MOTD))
				{
					UTIL_SayText(pId, "!g[GangSystems] !yИдет запрос к Базе.Запрос обрабатывается..подождите 2 секунды");
					return Show_GangCreate(pId);
				}
				payments_list(pId);
				
			}
			case 9: return PLUGIN_HANDLED;
		
		}
	
	
	}

	return Show_GangCreate(pId);

}
Show_LeavePlayerGang(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yПокинуть банду?^n^n");
	
	FormatItem("^t^t\dВы уверены что хотите покинуть банду?^n");
	FormatItem("^t^t\dБанда: %s?^n", g_iStatusGangPlayer[pId][PlayerGang_GangName]);
	
	
	FormatItem("\y1. \wДа^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wНет^n"), iKeys |= (1<<1);


	FormatItem("^n^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_LeavePlayerGang");

}

public Handle_LeavePlayerGang(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
	{
		return Show_GangCreate(pId);
	}
	/*new aData[eData_PlayerGang];
	ArrayGetArray(g_aPlayerData, g_iUserPlayerGangId[pId], aData);*/
	
	switch(iKey)
	{
		case 0: 
		{
			if(strlen(g_iStatusGangPlayer[pId][PlayerGang_GangName]))
				return LeavePlayerGang(pId);
		}
		case 8: return Show_GangCreate(pId);
		case 9: return PLUGIN_HANDLED;
		default: return Show_GangCreate(pId);
	}
	return Show_GangCreate(pId);
}

Show_SetupGangs(pId)
{
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < ZAMLIDERA)
	{
		return PLUGIN_HANDLED;
	}
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yНастройки банды^n^n");
	
	FormatItem("\y1. \wПовысить игрока^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wПонизить игрока^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wВыгнать игрока из банды^n"), iKeys |= (1<<2);
	
	FormatItem("^n\y4. \wИнформации о правах^n"), iKeys |= (1<<3);
	
	
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] == LIDER)
	{
		FormatItem("^n^n\y6. \dПеременовать банду (разр)^n")/*, iKeys |= (1<<5)*/;
		FormatItem("\y7. \rРаспустить банду^n"), iKeys |= (1<<6);
	}
	else 
	{
		FormatItem("^n^n\y6. \dПеременовать банду \r(Лидер)^n");
		FormatItem("\y7. \dРаспустить банду \r(Лидер)^n");
	}

	FormatItem("^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_SetupGangs");


}

public Handle_SetupGangs(pId, iKey)
{
	switch(iKey)
	{
		case 0: return Cmd_UpStatusPlayer(pId);
		case 1: return Cmd_DownStatusPlayer(pId);
		case 2: return SQL_PlayerGangs(pId, true);//return Cmd_LeavingPlayerGangs(pId);
		case 3: return Show_LevelGangs(pId);
		
		case 6: return Show_DeleteGang(pId);
		case 8: return Show_GangCreate(pId);
		
		case 9: return PLUGIN_HANDLED;
	}

	return Show_SetupGangs(pId);
}

Show_LevelGangs(pId)
{

	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("");
	
	FormatItem("\yПрава лидера^n");
	FormatItem("^t\dПонижать/Повышать игрока,^n");
	FormatItem("^t\dВыганять/Приглашать игрока,^n");
	FormatItem("^t\dРасспукать банду^n");
	FormatItem("^t\dЗарабатывать очки^n");
	FormatItem("\yПрава Зам лидера^n");
	FormatItem("^t\dВыганять/Приглашать игрока^n");
	FormatItem("^t\dЗарабатывать очки^n");
	FormatItem("\yПрава Доверенный^n");
	FormatItem("^t\dЗарабатывать очки^n");
	FormatItem("\yПрава Бандита^n");
	FormatItem("^t\dНичего^n");
	
	FormatItem("^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_LevelGangs");

}

public Handle_LevelGangs(pId, iKey) 
{
	switch(iKey)
	{
		case 8: return Show_SetupGangs(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
Show_DeleteGang(pId)
{	
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yРасспустить банду?^n^n");
	
	FormatItem("^t^t\dВы уверены что хотите распустить банду??^n");
	FormatItem("^t^t\dПри удаление, \rУДАЛЯТСЯ \dвсе данные о банде^n");
	FormatItem("^t^t\dВключая достижение и игроков^n");
	
	FormatItem("\y1. \wДа^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wНет^n"), iKeys |= (1<<1);


	FormatItem("^n^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_DeleteGang");
}

public Handle_DeleteGang(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 0: 
		{
			if(g_iStatusGangPlayer[pId][PlayerGang_Status] == LIDER)
				return FullDeleteGang(pId);
		}
		case 1: return Show_SetupGangs(pId);
		
		case 9: return Show_SetupGangs(pId);
	}

	return Show_DeleteGang(pId);
}

Cmd_ShowAllGangs(pId) return Show_ShowAllGangs(pId, g_iMenuPosition[pId] = 0);
Show_ShowAllGangs(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	new g_ArraySize = ArraySize( g_aData );
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_ArraySize ) iStart = g_ArraySize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_ArraySize) iEnd = g_ArraySize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_ArraySize / PLAYERS_PER_PAGE + ((g_ArraySize % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g* !yАктивных Банд не обноружено");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yСписок Активных банд \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
	}

	new aDataQuotes[eData_Gang];
	new iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aData, a, aDataQuotes);
		iKeys |= (1<<b);
		new iCount = jbe_count_for_gang(aDataQuotes[Gang_Id]);
		FormatItem("\y%d. \w%s \y[%d]^n" , ++b, aDataQuotes[Gang_Name], iCount);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_ArraySize)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ShowAllGangs");
}

public Handle_ShowAllGangs(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_ShowAllGangs(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_ShowAllGangs(pId, --g_iMenuPosition[pId]);
		default:
		{
			
			new iGang = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;

			new aDataQuotes[eData_Gang];
			ArrayGetArray(g_aData, iGang, aDataQuotes);
			
			PlayerGangAllPlayer(pId, aDataQuotes[Gang_Id]);
		}
	}
	return PLUGIN_HANDLED;
}

/*Cmd_LeavingPlayerGangs(pId) return Show_LeavingPlayerGangs(pId, g_iMenuPosition[pId] = 0);
Show_LeavingPlayerGangs(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || g_iStatusGangPlayer[i][PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
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
			UTIL_SayText(pId, "%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yКого выгнать? \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		if(i == pId)
		{
			FormatItem("\y%d. \d%n - \y[это вы]^n" , ++b, i);
		}
		else
		if(g_iStatusGangPlayer[i][PlayerGang_Status] == LIDER)
		{
			FormatItem("\y%d. \d%n - \y[Лидер]^n" , ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n - \y[%s]^n" , ++b, i, g_szStatusName[g_iStatusGangPlayer[i][PlayerGang_Status] - 1]);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_LeavingPlayerGangs");
}

public Handle_LeavingPlayerGangs(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	switch(iKey)
	{
		case 8: return Show_LeavingPlayerGangs(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_LeavingPlayerGangs(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			LeavePlayerGang(iTarget, pId)
			//Gang_UpgradePlayer(pId, iTarget, g_iStatusGangPlayer[iTarget][PlayerGang_Status] + 1, true);
		}
	}
	return PLUGIN_HANDLED;
}*/


Cmd_UpStatusPlayer(pId) return Show_UpStatusPlayer(pId, g_iMenuPosition[pId] = 0);
Show_UpStatusPlayer(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || g_iStatusGangPlayer[i][PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
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
			UTIL_SayText(pId, "%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yКого повысить? \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		if(g_iStatusGangPlayer[i][PlayerGang_Status] == LIDER)
		{
			FormatItem("\y%d. \d%n - \y[Лидер]^n" , ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n - \y[%s]^n" , ++b, i, g_szStatusName[g_iStatusGangPlayer[i][PlayerGang_Status] - 1]);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_UpStatusPlayer");
}

public Handle_UpStatusPlayer(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 8: return Show_UpStatusPlayer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_UpStatusPlayer(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			Gang_UpgradePlayer(pId, iTarget, g_iStatusGangPlayer[iTarget][PlayerGang_Status] + 1, true);
		}
	}
	return PLUGIN_HANDLED;
}

Cmd_DownStatusPlayer(pId) return Show_DownStatusPlayer(pId, g_iMenuPosition[pId] = 0);
Show_DownStatusPlayer(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i) || g_iStatusGangPlayer[i][PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
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
			UTIL_SayText(pId, "%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\yКого понизить? \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		if(g_iStatusGangPlayer[i][PlayerGang_Status] == LIDER)
		{
			FormatItem("\y%d. \d%n - \y[Лидер]^n" , ++b, i);
		}
		else
		if(g_iStatusGangPlayer[i][PlayerGang_Status] == BANDIT)
		{
			FormatItem("\y%d. \d%n - \y[Бандит (1ур.)]^n" , ++b, i);
		}
		else
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n - \y[%s]^n" , ++b, i, g_szStatusName[g_iStatusGangPlayer[i][PlayerGang_Status] - 1]);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_DownStatusPlayer");
}

public Handle_DownStatusPlayer(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < LIDER)
	{
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 8: return Show_DownStatusPlayer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_DownStatusPlayer(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			Gang_UpgradePlayer(pId, iTarget, g_iStatusGangPlayer[iTarget][PlayerGang_Status] - 1, false);
		}
	}
	return PLUGIN_HANDLED;
}

Show_InfoForGang(pId)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	if(g_iStatusGangPlayer[pId][PlayerGang_Id] == ARRAY_LEN_NULL)
	{
		return Show_GangCreate(pId);
	}
	
	new i = gangplayer_info_count(pId);
	//new ArrayIndex = gang_array_index(pId);
	
	
	new sData[eData_Gang];
	ArrayGetArray(g_aData, g_iStatusGangPlayer[pId][PlayerGang_ArrayIndex], sData);
		
	//server_print("%d | %d", aDataQuotes[PlayerGang_Id], sData[PlayerGang_Id]);
	
	
	new szTime[ 128 ], szGetTime[64];
	GetTimeLength(get_systime() - sData[Gang_CreateTime] , szTime, charsmax( szTime ) );
	format_time( szGetTime , 63 , "%m/%d/%Y" , sData[Gang_CreateTime] );
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yИнформации о банде^n^n");
	
	FormatItem("^t^t\dБанда: \y%s (ID: %d)^n", sData[Gang_Name], sData[Gang_Id]);
	FormatItem("^t^t\dБанда создана: \y%s^n", szGetTime);
	FormatItem("^t^t\dБанда существует: \y%s^n", szTime);
	FormatItem("^t^t\dКол-во игроков в банде:\y %d^n", i);
	FormatItem("^t^t\dЛидер: \y%s^n^n", sData[Gang_LeaderName]);
	FormatItem("\y1. \wСписок игроков^n"), iKeys |= (1<<0);
	
	FormatItem("^n^n^n\y9. \wназад");
	FormatItem("^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_InfoForGang");
}

public Handle_InfoForGang(pId, iKey) 
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	switch(iKey)
	{
		case 0: return SQL_PlayerGangs(pId, false);
		case 8: return Show_GangCreate(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_InfoForGang(pId);
}

public PlayerGangAllPlayer(pId, GangId)
{
	new queryData[QUERY_LENGTH];
	formatex(queryData, charsmax(queryData), "SELECT * FROM %s WHERE `id` = '%d' ORDER BY `Player_Status` DESC", GANG_PLAYER, GangId);
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_SELECTALLPLAYERS;
	sData[EXT_DATA__INDEX] = pId;
	sData[EXT_DATA__STATUS] = 0;
	return SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", queryData, sData, sizeof sData);
}


public SQL_PlayerGangs(pId, iType)
{
	new queryData[QUERY_LENGTH];
	formatex(queryData, charsmax(queryData), "SELECT * FROM %s WHERE `id` = '%d' ORDER BY `Player_Status` DESC", GANG_PLAYER, g_iStatusGangPlayer[pId][PlayerGang_Id]);
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_SELECTALLPLAYERS;
	sData[EXT_DATA__INDEX] = pId;
	sData[EXT_DATA__STATUS] = iType;
	return SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", queryData, sData, sizeof sData);
}

public SHOW_PLAYERSMENU(const id, Handle:query, iType)
{
	if(SQL_NumResults(query))
	{
		new szMenu[512];
		if(iType == 1)
		{
			formatex(szMenu, charsmax(szMenu), "\yУправление  \rУчастниками:^n\wВыберите \yучастника\w, для управления.");
		}else formatex(szMenu, charsmax(szMenu), "\yСписок игроков");
		new itemData[512], userName[64],szLogin[32], status, menu = menu_create(szMenu, "member_menu_handle");

		while (SQL_MoreResults(query)) 
		{
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "PlayerName"), userName, charsmax(userName));
			#if defined REGS_API
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "PlayerLogin"), szLogin, charsmax(szLogin));
			#else
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "PlayerAuth"), szLogin, charsmax(szLogin));
			#endif
			status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "Player_Status"));

			formatex(itemData, charsmax(itemData), "%s#%s#%d#%d", userName, szLogin, status, iType);
			//server_print("%s", itemData);
			switch (status) {
				case BANDIT: add(userName, charsmax(userName), " \y[Бандит]");
				case DOVERENNYI: add(userName, charsmax(userName), " \y[Дов.]");
				case ZAMLIDERA: add(userName, charsmax(userName), " \y[Зам.]");
				case LIDER: add(userName, charsmax(userName), " \r[Лидер]");
			}
			
			menu_additem(menu, userName, itemData);

			SQL_NextRow(query);
		}

		menu_setprop(menu, MPROP_EXITNAME, "Выход");
		menu_setprop(menu, MPROP_BACKNAME, "Назад");
		menu_setprop(menu, MPROP_NEXTNAME, "Далее");

		menu_display(id, menu);
		
	}
	return PLUGIN_HANDLED;
}

public member_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	
	
	new itemData[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	new dataParts[4][64]
	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));
	menu_destroy(menu);
	//server_print("%s | %s | %s | %s | %d | %d", itemData, dataParts[0], dataParts[1], dataParts[2], str_to_num(dataParts[2]), str_to_num(dataParts[2]));
	if(str_to_num(dataParts[3]) == 0)
	{
		//server_print("Тут");
		return PLUGIN_HANDLED;
	}
	new datemenu = menu_create("\yВыберите \rПараметры:", "member_options_menu_handle");

	menu_additem(datemenu, "Выгнать \yИгрока", itemData);


	menu_setprop(datemenu, MPROP_EXITNAME, "Выход");

	menu_display(id, datemenu);
	return PLUGIN_HANDLED;
}

public member_options_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	if(g_iStatusGangPlayer[id][PlayerGang_Status] < ZAMLIDERA)
	{
		menu_destroy(menu);
		UTIL_SayText(id, "!g[GangSystems] !yУ вас недостаточно прав, доступен только Лидеру или Зам.Лидера");
		return PLUGIN_HANDLED;
	}

	new itemData[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	switch (item) {
		case 0: KickPlayerForGang(id, menu);
	}

	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}


KickPlayerForGang(pId, menu)
{
	if(g_iStatusGangPlayer[pId][PlayerGang_Status] < ZAMLIDERA)
	{
		menu_destroy(menu);
		UTIL_SayText(pId, "!g[GangSystems] !yУ вас недостаточно прав, доступен только Лидеру или Зам.Лидера");
		return PLUGIN_HANDLED;
	}
	new itemData[64];

	menu_item_getinfo(menu, 0, _, itemData, charsmax(itemData), _, _,_);
	new szLogin[2][32];
	new dataParts[4][32]
	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));
	
	//server_print("%s | %s | %s | %s | %d", itemData, dataParts[0], dataParts[1], dataParts[2], str_to_num(dataParts[2]));
	//dataParts[0] = name, dataParts[1] = login, dataParts[2] = status
	
	if(str_to_num(dataParts[2]) == LIDER)
	{
		//menu_destroy(menu);
		UTIL_SayText(pId, "!g[GangSystems] !yНельзя выгнать лидера");
		return PLUGIN_HANDLED;
	}
	
	#if defined REGS_API
	get_login_len(pId, szLogin[1], 31);
	if(equal(dataParts[1], szLogin[1]))
	{
		//menu_destroy(menu);
		UTIL_SayText(pId, "!g[GangSystems] !yНельзя выгнать себя");
		return PLUGIN_HANDLED;
	}
	#else
	get_user_authid(pId, szLogin[1], 31);
	if(equal(dataParts[1], szLogin[1]))
	{
		//menu_destroy(menu);
		UTIL_SayText(pId, "!g[GangSystems] !yНельзя выгнать себя");
		return PLUGIN_HANDLED;
	}
	#endif
	
	//server_print("%n | %s | %s", pId, dataParts[0], dataParts[1]);
	
	new szQuery[QUERY_LENGTH]
	formatex(szQuery,charsmax(szQuery),  "DELETE FROM %s WHERE `PlayerLogin` = '%s' AND `id` = '%d'", GANG_PLAYER, dataParts[1], g_iStatusGangPlayer[pId][PlayerGang_Id]);
	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", szQuery);
	
	UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n  !yисключил игрока !g%s !yиз банды !g%s",pId, dataParts[0], g_iStatusGangPlayer[pId][PlayerGang_GangName]);

	GANG_ACTION(pId, 0, dataParts[0] , ACTION_LEAVE, _ );
	
	
	
	
	new aDataQuotes[eData_PlayerGang];
	for(new i, ArraiLen = ArraySize(g_aAllPlayerData) - 1; i < ArraiLen; i++)
	{
		ArrayGetArray(g_aAllPlayerData, i, aDataQuotes);
		
		if(g_iStatusGangPlayer[pId][PlayerGang_Id] == aDataQuotes[PlayerGang_Id])
		{
			if(equal(aDataQuotes[PlayerGang_Name], dataParts[0]))
			{
				server_print("%s", aDataQuotes[PlayerGang_Name])
				ArrayDeleteItem(g_aAllPlayerData, i);
				break;
			}
		}
	}
	
	for(new i; i <= MaxClients; i++)
	{
		
		#if defined REGS_API
		if(!is_user_connected(i) || !get_login(i)) continue;
		get_login_len(i, szLogin[0], 31);
		#else
		if(!is_user_connected(i)) continue;
		get_user_authid(i, szLogin[0], 31);
		#endif
		if(equal(dataParts[1], szLogin[0]) && g_iStatusGangPlayer[pId][PlayerGang_Id] == g_iStatusGangPlayer[i][PlayerGang_Id])
		{
			new iRet;
			ExecuteForward(g_iFwdEndGangs, iRet, i);
			UserForNulledArray(i);
			break;
		}
	}
	return PLUGIN_HANDLED;
}

stock GANG_ACTION(pId, iTarget = 0, iTargetName[] = "" , iType = 0, iCount = 0)
{
	new szTempText[32];
	if(!iTarget)
		copy(szTempText, charsmax(szTempText), iTargetName);
	else formatex(szTempText, charsmax(szTempText), "%n" , iTarget);
	
	new query[QUERY_LENGTH], que_len;

	que_len += formatex(query[que_len],charsmax(query) - que_len, "INSERT INTO %s (`id`, `PlayerNamepId`, ", GANG_OTHER);
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`szText`, ");
	
	if(iTarget)
		que_len += formatex(query[que_len],charsmax(query) - que_len, "`PlayerNameiTarget`, ");
		
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`iValue`, ");
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`iCount`, ");
		
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`Player_TimeAction`) ");
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "VALUES ('%d', '%s', ", g_iStatusGangPlayer[pId][PlayerGang_Id],  g_iStatusGangPlayer[pId][PlayerGang_Name]);
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "'%s', ", szText[iType]);
	if(iTarget)
		que_len += formatex(query[que_len],charsmax(query) - que_len, "'%s', ", g_iStatusGangPlayer[iTarget][PlayerGang_Name]);

	que_len += formatex(query[que_len],charsmax(query) - que_len, "'%s', ", szTempText);
	que_len += formatex(query[que_len],charsmax(query) - que_len, "'%d', ", iType);
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "'%d', ", iCount);
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "'%d')", get_systime());
	

	SQL_ThreadQuery(g_hDBGangHandle, "IgnoreHandle", query);
}

public payments_list(id)
{
	new queryData[QUERY_LENGTH];

	new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_MOTDHISTORY;
		sData[EXT_DATA__INDEX] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM %s WHERE `id` = '%d' ORDER BY `Player_TimeAction` DESC", GANG_OTHER, g_iStatusGangPlayer[id][PlayerGang_Id]);

	SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", queryData, sData, sizeof(sData));
	
	set_task(3.0, "show_motd_buffer", id + TASK_SHOW_MOTD);
	

	return PLUGIN_HANDLED;
}


public show_motd_buffer(pId)
{
	pId -= TASK_SHOW_MOTD;
	
	if(!is_user_connected(pId))
		return PLUGIN_HANDLED;
	
	show_motd(pId, g_sBuffer[pId], "История");
	return PLUGIN_HANDLED;
}
public OpenPlayersGangs(pId) return Show_PlayersGangs(pId, g_iMenuPosition[pId] = 0);

Show_PlayersGangs(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	new g_iGangPlayerLen = ArraySize(g_aAllPlayerData) - 1;
	
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iGangPlayerLen ) iStart = g_iGangPlayerLen;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iGangPlayerLen) iEnd = g_iGangPlayerLen + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_iGangPlayerLen / PLAYERS_PER_PAGE + ((g_iGangPlayerLen % PLAYERS_PER_PAGE) ? 1 : 0));
	new aDataQuotes[eData_PlayerGang];
	
	//new sData[eData_PlayerGang];
	//ArrayGetArray(g_aData, g_iUserPlayerGangId[pId], sData);

	FormatMain("\yСписок игроков банды \d[%d|%d]^n^n", iPos + 1, iPagesNum);
	new iBitKeys = (1<<9), b;
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aAllPlayerData, a, aDataQuotes);
		
		//server_print("%d | %d", aDataQuotes[PlayerGang_Id], g_iStatusGangPlayer[pId][PlayerGang_Id]);
		if(aDataQuotes[PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
		
		FormatItem("\y%d. \w%s - \y[%s]^n" , ++b, aDataQuotes[PlayerGang_Name], g_szStatusName[aDataQuotes[PlayerGang_Status] - 1]);
		
		/*if(aDataQuotes[PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
		{
			//iBitKeys |= (1<<b);
			FormatItem("\y%d. \w%s - \y[%s]^n" , ++b, aDataQuotes[PlayerGang_Name], g_szStatusName[aDataQuotes[PlayerGang_Status] - 1]);
		}*/
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_iGangPlayerLen)
	{
		iBitKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iBitKeys, szMenu, -1, "Show_PlayersGangs");
}

public Handle_PlayersGangs(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	switch(iKey)
	{
		case 8: return Show_PlayersGangs(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_PlayersGangs(pId, --g_iMenuPosition[pId]);
		/*default:
		{
			new iSprites = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			emit_startquotes(pId, iSprites);
		}*/
	}
	return Show_PlayersGangs(pId, g_iMenuPosition[pId]);
}

Cmd_JoinGangPlayer(pId) return Show_JoinGangPlayer(pId, g_iMenuPosition[pId] = 0);
Show_JoinGangPlayer(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i)) continue;
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
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_TRANSFER_CHIEF_TITLE", iPos + 1, iPagesNum);
	}
	//new aDataQuotes[eData_PlayerGang];
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		if(g_iStatusGangPlayer[i][PlayerGang_Id] != ARRAY_LEN_NULL)
		{
			//ArrayGetArray(g_aAllPlayerData, a, aDataQuotes);
			if(i == pId)
			{
				FormatItem("\y%d. \d%n \y(Это вы)^n", ++b, i);
			}
			else
			if(g_iStatusGangPlayer[i][PlayerGang_Id] == g_iStatusGangPlayer[pId][PlayerGang_Id])
			{
				FormatItem("\y%d. \d%n \y(в вашей банде)^n", ++b, i);
			}
			else
			FormatItem("\y%d. \d%n \y(в другой банде)^n", ++b, i);
		}
		else
		{
			#if defined REGS_API
			if(!get_login(i))
			{
				FormatItem("\y%d. \d%n (не авторизован)^n", ++b, i);
			}
			else
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%n^n", ++b, i);
			}
			#else
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n^n", ++b, i);
			#endif
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_JoinGangPlayer");
}

public Handle_JoinGangPlayer(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	switch(iKey)
	{
		case 8: return Show_JoinGangPlayer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_JoinGangPlayer(pId, --g_iMenuPosition[pId]);
		default:
		{
			if(task_exists(pId + TASK_JOININGPLAYER))
			{
				//server_print("уже запущен");
				UTIL_SayText(pId, "!g[GangSystems] !yНельзя одновременно приглашать несколько игроков.");
				return Show_JoinGangPlayer(pId, g_iMenuPosition[pId]);
			}
			
			static Float: fCurPlayerTime;
			
			if(get_gametime() < fCurPlayerTime)
			{
				client_print(pId, print_center, "До следующего приглашение ждите: %.f секунд",fCurPlayerTime - get_gametime());
				return Show_JoinGangPlayer(pId, g_iMenuPosition[pId]);
			}
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			#if defined REGS_API
			if(!get_login(iTarget))
			{
				UTIL_SayText(pId, "!g[GangSystems] !yДанный игрок не атворизован. !g(say /reg)");
				return PLUGIN_HANDLED;
			}
			#endif
			if(IsSetBit(g_iBitUserBlockInvite, iTarget))
			{
				UTIL_SayText(pId, "!g[GangSystems] !yДанный игрок включил блок приглашение !g(до смены карт)");
				return PLUGIN_HANDLED;
				
			}
			if(g_iStatusGangPlayer[iTarget][PlayerGang_Id] != ARRAY_LEN_NULL)
			{
				//server_print("уже в банде");
				UTIL_SayText(pId, "!g[GangSystems] !yДанный игрок уже состоит в другом(в вашей) банде");
				return Show_JoinGangPlayer(pId, g_iMenuPosition[pId]);
			}
			if(g_iUserJoinInic[iTarget])
			{
				//server_print("уже его кто то пригласил");
				UTIL_SayText(pId, "!g[GangSystems] !yЖдите своей очереди, игрок в стадии принятие в банду");
				return Show_JoinGangPlayer(pId, g_iMenuPosition[pId]);
			}

			fCurPlayerTime = get_gametime() + BLOCK_USER_TIME;
			Show_AcceptJoinGangs(iTarget, pId);
			
			new TaskTime = TIMESTASK;
			new Arg[3];
			Arg[0] = pId;
			Arg[1] = iTarget
			Arg[2] = TaskTime;
			set_task_ex(1.0, "ended_task", pId + TASK_JOININGPLAYER, Arg, sizeof Arg, SetTask_RepeatTimes, TaskTime);
			UTIL_SayText(0, "!g[GangSystems] !yЧлен банды !g%n !yиз !t%s !yотправил запрос на приглашение игроку !g%n", pId, g_iStatusGangPlayer[pId][PlayerGang_GangName], iTarget);
			UTIL_SayText(pId, "!g[GangSystems] !yВы отправили запрос на приглашение игрока %n, ждите ответа...", iTarget);
			return PLUGIN_HANDLED;
		}
	}
	return Show_JoinGangPlayer(pId, g_iMenuPosition[pId]);
}
public ended_task(Arg[])
{
	new IniciatorpId = Arg[0];
	new iTarget = Arg[1];
	new TaskTime = Arg[2];
	
	if(!g_iUserJoinInic[iTarget]) 
	{
		if(task_exists(iTarget + TASK_JOININGPLAYER))
			remove_task(iTarget + TASK_JOININGPLAYER);
		show_menu(iTarget, 0, "^n");
	}
	if(--TaskTime)
	{
		if(g_iStatusGangPlayer[iTarget][PlayerGang_Id] == ARRAY_LEN_NULL)
			Show_AcceptJoinGangs(iTarget, IniciatorpId);
	}
	else 
	{
		show_menu(iTarget, 0, "^n");
		//server_print("игрок не принял прглашение");
		if(is_user_connected(IniciatorpId))
			UTIL_SayText(IniciatorpId, "!g[GangSystems] !yИгрок !g%n !yне принял запрос в вступление в банду", iTarget);
	}
}
Show_AcceptJoinGangs(pId, IniciatorpId)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		//UTIL_SayText(pId, "!g[GangSystems] !yПросим вас авторизоваться. !g(say /reg)");
		return PLUGIN_HANDLED;
	}
	#endif
	new szMenu[512], iKeys, iLen;
	g_iUserJoinInic[pId] = IniciatorpId;
	FormatMain("\yСогласие вступление в Банду^n^n");
	
	FormatItem("^t^t\dИгрок %n^n", IniciatorpId);
	FormatItem("^t^t\dПросит вас присоединиться^n");
	FormatItem("^t^t\dК банде: \y%s^n^n^n", g_iStatusGangPlayer[IniciatorpId][PlayerGang_GangName]);


	FormatItem("\y1. \wПрисоединиться^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wОтказаться^n"), iKeys |= (1<<1);
	
	FormatItem("^n\y3. \yБлок приглашение на карту^n"), iKeys |= (1<<2);
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_AcceptJoinGangs");
}

public Handle_AcceptJoinGangs(pId, iKey)
{
	#if defined REGS_API
	if(!get_login(pId))
	{
		return PLUGIN_HANDLED;
	}
	#endif
	switch(iKey)
	{
		case 0: 
		{
			new szLogin[MAX_NAME_LENGTH];
			new queryData[QUERY_LENGTH];
			#if defined REGS_API
			get_login_len(pId, szLogin, charsmax(szLogin));
			formatex(queryData, charsmax(queryData), "SELECT * FROM %s WHERE `PlayerLogin` = '%s'", GANG_PLAYER, szLogin);
			#else
			get_user_authid(pId, szLogin, charsmax(szLogin));
			formatex(queryData, charsmax(queryData), "SELECT * FROM %s WHERE `PlayerAuth` = '%s'", GANG_PLAYER, szLogin);
			#endif
			new sData[EXT_DATA_STRUCT];
			sData[EXT_DATA__SQL] = SQL_CHECKISUSERGANG;
			sData[EXT_DATA__INDEX] = pId;
			sData[EXT_DATA__LEAVERPIDE] = g_iUserJoinInic[pId];
			return SQL_ThreadQuery(g_hDBGangHandle, "selectQueryHandler", queryData, sData, sizeof sData);
		}
		case 1: 
		{
			if(is_user_connected(g_iUserJoinInic[pId]))
				UTIL_SayText(g_iUserJoinInic[pId], "!g[GangSystems] !yИгрок !g%n !yотказал в принятие в вашу банду", pId);
				
			if(task_exists(g_iUserJoinInic[pId] + TASK_JOININGPLAYER)) remove_task(g_iUserJoinInic[pId] + TASK_JOININGPLAYER);
			show_menu(pId, 0, "^n");
			g_iUserJoinInic[pId] = 0;
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			if(is_user_connected(g_iUserJoinInic[pId]))
				UTIL_SayText(g_iUserJoinInic[pId], "!g[GangSystems] !yИгрок !g%n !yотказал в принятие в вашу банду", pId);
				
			if(task_exists(g_iUserJoinInic[pId] + TASK_JOININGPLAYER)) remove_task(g_iUserJoinInic[pId] + TASK_JOININGPLAYER);
			show_menu(pId, 0, "^n");
			g_iUserJoinInic[pId] = 0;
			
			SetBit(g_iBitUserBlockInvite, pId);
			UTIL_SayText(g_iUserJoinInic[pId], "!g[GangSystems] !yВы включили временный блок на приглашение в банду !g(до смены карт или до выхода с сервера)");
			return PLUGIN_HANDLED;
		
		}
	}
	return PLUGIN_HANDLED;
}

public add_to_full_pack(esHandle, e, ent, host, hostFlags, player, pSet)
{
	if(!player || host == ent) return FMRES_IGNORED
	if(!is_user_connected(host) || !is_user_connected(ent)) return FMRES_IGNORED
	if(g_iStatusGangPlayer[host][PlayerGang_Id] == ARRAY_LEN_NULL) return FMRES_IGNORED

	if(g_iStatusGangPlayer[host][PlayerGang_Id] != g_iStatusGangPlayer[ent][PlayerGang_Id]) return FMRES_IGNORED
	
	set_es(esHandle, ES_RenderFx, kRenderFxGlowShell);
	set_es(esHandle, ES_RenderColor, 255, 0, 0);
	set_es(esHandle, ES_RenderMode, kRenderNormal);
	set_es(esHandle, ES_RenderAmt, 20);
	
	return FMRES_IGNORED
}

GetTimeLength( iTime, szOutput[ ], iOutputLen )
{
	new szTimes[ TimeUnit ][ 32 ];
	new iUnit, iValue, iTotalDisplay;
	
	for( new i = TimeUnit - 1; i >= 0; i-- )
	{
		iUnit = g_iTimeUnitMult[ i ];
		iValue = iTime / iUnit;
		
		if( iValue )
		{
			formatex( szTimes[ i ], charsmax( szTimes[ ] ), "%d %s", iValue, g_szTimeUnitName[ i ][ iValue != 1 ] );
			
			iTime %= iUnit;
			
			iTotalDisplay++;
		}
	}
	
	new iLen, iTotalLeft = iTotalDisplay;
	szOutput[ 0 ] = 0;
	
	for( new i = TimeUnit - 1; i >= 0; i-- )
	{
		if( szTimes[ i ][ 0 ] )
		{
			iLen += formatex( szOutput[ iLen ], iOutputLen - iLen, "%s%s%s",
				( iTotalDisplay > 2 && iLen ) ? ", " : "",
				( iTotalDisplay > 1 && iTotalLeft == 1 ) ? ( ( iTotalDisplay > 2 ) ? "и " : " и " ) : "",
				szTimes[ i ]
			);
			
			iTotalLeft--;
		}
	}
	
	return iLen;
}


stock gangplayer_info_count(pId)
{

	new i;

	new aDataPlayer[eData_PlayerGang];
	for(new ArrayIndex,g_iGangPlayerLen = ArraySize(g_aAllPlayerData); ArrayIndex < g_iGangPlayerLen; ArrayIndex++)
	{
		ArrayGetArray(g_aAllPlayerData, ArrayIndex, aDataPlayer);
		if(aDataPlayer[PlayerGang_Id] != g_iStatusGangPlayer[pId][PlayerGang_Id]) continue;
		
		i++;
	}
	return i;
}

stock jbe_count_for_gang(ArrayCount)
{

	new i;

	new aDataPlayer[eData_PlayerGang];
	for(new ArrayIndex,g_iGangPlayerLen = ArraySize(g_aAllPlayerData); ArrayIndex < g_iGangPlayerLen; ArrayIndex++)
	{
		ArrayGetArray(g_aAllPlayerData, ArrayIndex, aDataPlayer);
		if(aDataPlayer[PlayerGang_Id] != ArrayCount) continue;
		
		i++;
	}
	return i;
}


stock gang_array_index(pId)
{
	new i;
	new aDataQuotes[eData_Gang];
	
	for(new ArrayIndex, g_ArraySize = ArraySize( g_aData ); ArrayIndex < g_ArraySize; ArrayIndex++)
	{
		ArrayGetArray(g_aData, ArrayIndex, aDataQuotes);
		if(aDataQuotes[Gang_Id] == g_iStatusGangPlayer[pId][PlayerGang_Id])
		{
			i = ArrayIndex;
			break;
		}
	}
	return i;
}

stock explode(const string[], const character, output[][], const maxParts, const maxLength)
{
	new currentPart = 0, stringLength = strlen(string), currentLength = 0;

	do {
		currentLength += (1 + copyc(output[currentPart++], maxLength, string[currentLength], character));
	} while(currentLength < stringLength && currentPart < maxParts);
}

stock re_mysql_escape_string(output[], len)
{
	//while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	while(replace(output, len, "\", "")) {}
	while(replace(output, len, "'", "")) {}
	while(replace(output, len, "^"", "")) {}
}



#define MsgId_SayText 76


stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	
	while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!b", "^0")) {}
	

	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				
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