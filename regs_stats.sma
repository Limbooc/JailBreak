#include <amxmodx>
#include <sqlx>
#include <time_for_regs>
#include <fakemeta>
#include <jbe_core>



new g_iGlobalDebug;
#include <util_saytext>

#define RANK_TABLE		"Regs_Stats"

#define ENABLE_INGOREHANDLED
#define CLOSE_CONNECTION
#define CREATE_MULTIFORWARD


#if defined CREATE_MULTIFORWARD
forward RegsCoreApiLoaded(Handle:sqlTuple);
forward RegsCoreApiDisconnect();
#endif

native jbe_set_butt(id, iNum);

//#define DEBUG
//#define DEBUGCHECK_LOG
//#define SQL_TEST_PERFORMNACE		//Проверка производительности скорости работы запроса

#if defined SQL_TEST_PERFORMNACE
new g_count;
#endif


const MIN_SETTINGS = 1;
const MAX_SETTINGS = 70;

const MIN_QUEST_SETTINGS = 1;
const MAX_QUEST_SETTINGS = 15;

const MAX_TOTAL_SETTINGS = MAX_SETTINGS + MAX_QUEST_SETTINGS;

const SQL_CONNECTION_TIMEOUT = 10;
const TASK_SHOW_TOP = 364537;

const QUERY_LENGTH =	1472	// размер переменной sql запроса

native jbe_mysql_stats_systems_get(pId, iType)
native jbe_mysql_stats_systems_add(pId, iType, iNum) 
native jbe_set_informer_pos(pId, iType, Float:iNum) 
native Float:jbe_get_informer_pos(pId, iType) 
native jbe_set_informer_color(pId, iType, iNum) 
native jbe_get_informer_color(pId, iType) 

native jbe_reset_informer_pos(pId);

native get_login(id)
native get_login_len(id, login[], len)
native regs_main_menu(id)
native jbe_get_butt(id);


const MAX_BUFFER_LENGTH =      2047;
new g_sBuffer[MAX_BUFFER_LENGTH + 1],
	g_sBuffer1[MAX_BUFFER_LENGTH + 1],
	g_sBuffer2[MAX_BUFFER_LENGTH + 1],
	g_sBuffer3[MAX_BUFFER_LENGTH + 1]

enum _:sql_que_type	// тип sql запроса
{
	SQL_INITDB,
	SQL_IGNORE,
	SQL_STATS_LOAD,
	SQL_STATS_SAVE,
	SQL_STATS_ADD,
	SQL_TOP_1,
	SQL_TOP_2,
	SQL_TOP_3,
	SQL_TOP_4
}

#define STATSX_SHELL_DESIGN0_STYLE "<meta charset=UTF-8><style type=^"text/css^">table{color:#fff;}th{color:#e41032;}th,td{text-align:left;width:200px;}.p{text-align:right;width:45px;padding-right:15px;}</style>"
#define STATSX_SHELL_DESIGN1_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#112233;font-family:Arial}th{background:#558866;color:#FFF;padding:10px 2px;text-align:left}td{padding:4px 3px}table{background:#EEEECC;font-size:12px;font-family:Arial}h2,h3{color:#FFF;font-family:Verdana}#c{background:#E2E2BC}img{height:10px;background:#09F;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN2_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{font-family:Arial}th{background:#575757;color:#FFF;padding:5px;border-bottom:2px #BCE27F solid;text-align:left}td{padding:3px;border-bottom:1px #E7F0D0 solid}table{color:#3C9B4A;background:#FFF;font-size:5px}h2,h3{color:#333;font-family:Verdana}#c{background:#F0F7E2}img{height:20px;background:#62B054;margin:0 3px}#r{height:30px;background:#717171}#clr{background:none;color:#575757;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN3_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#E6E6E6;font-family:Verdana}th{background:#F5F5F5;color:#A70000;padding:6px;text-align:left}td{padding:2px 6px}table{color:#333;background:#E6E6E6;font-size:10px;font-family:Georgia;border:2px solid #D9D9D9}h2,h3{color:#333;}#c{background:#FFF}img{height:10px;background:#14CC00;margin:0 3px}#r{height:10px;background:#CC8A00}#clr{background:none;color:#A70000;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN4_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#E8EEF7;margin:2px;font-family:Tahoma}th{color:#0000CC;padding:3px}tr{text-align:left;background:#E8EEF7}td{padding:3px}table{background:#CCC;font-size:11px}h2,h3{font-family:Verdana}img{height:10px;background:#09F;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#000;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN5_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#555;font-family:Arial}th{border-left:1px solid #ADADAD;border-top:1px solid #ADADAD}table{background:#3C3C3C;font-size:11px;color:#FFF;border-right:1px solid #ADADAD;border-bottom:1px solid #ADADAD;padding:3px}h2,h3{color:#FFF}#c{background:#FF9B00;color:#000}img{height:10px;background:#00E930;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#FFF;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN6_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#FFF;font-family:Tahoma}th{background:#303B4A;color:#FFF}table{padding:6px 2px;background:#EFF1F3;font-size:12px;color:#222;border:1px solid #CCC}h2,h3{color:#222}#c{background:#E9EBEE}img{height:7px;background:#F8931F;margin:0 3px}#r{height:7px;background:#D2232A}#clr{background:none;color:#303B4A;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN7_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#FFF;font-family:Verdana}th{background:#2E2E2E;color:#FFF;text-align:left}table{padding:6px 2px;background:#FFF;font-size:11px;color:#333;border:1px solid #CCC}h2,h3{color:#333}#c{background:#F0F0F0}img{height:7px;background:#444;margin:0 3px}#r{height:7px;background:#999}#clr{background:none;color:#2E2E2E;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN8_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#242424;margin:20px;font-family:Tahoma}th{background:#2F3034;color:#BDB670;text-align:left} table{padding:4px;background:#4A4945;font-size:10px;color:#FFF}h2,h3{color:#D2D1CF}#c{background:#3B3C37}img{height:12px;background:#99CC00;margin:0 3px}#r{height:12px;background:#999900}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN9_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#FFF;font-family:Tahoma}th{background:#056B9E;color:#FFF;padding:3px;text-align:left;border-top:4px solid #3986AC}td{padding:2px 6px}table{color:#006699;background:#FFF;font-size:12px;border:2px solid #006699}h2,h3{color:#F69F1C;}#c{background:#EFEFEF}img{height:5px;background:#1578D3;margin:0 3px}#r{height:5px;background:#F49F1E}#clr{background:none;color:#056B9E;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN10_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#4C5844;font-family:Tahoma}th{background:#1E1E1E;color:#C0C0C0;padding:2px;text-align:left;}td{padding:2px 15px}table{color:#AAC0AA;background:#424242;font-size:13px}h2,h3{color:#C2C2C2;font-family:Tahoma}#c{background:#323232}img{height:3px;background:#B4DA45;margin:0 3px}#r{height:3px;background:#6F9FC8}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN11_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#F2F2F2;font-family:Arial}th{background:#175D8B;color:#FFF;padding:7px;text-align:left}td{padding:3px;border-bottom:1px #BFBDBD solid}table{color:#153B7C;background:#F4F4F4;font-size:11px;border:1px solid #BFBDBD}h2,h3{color:#153B7C}#c{background:#ECECEC}img{height:8px;background:#54D143;margin:0 3px}#r{height:8px;background:#C80B0F}#clr{background:none;color:#175D8B;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN12_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#283136;font-family:Arial}th{background:#323B40;color:#6ED5FF;padding:10px 2px;text-align:left}td{padding:4px 3px;border-bottom:1px solid #DCDCDC}table{background:#EDF1F2;font-size:10px;border:2px solid #505A62}h2,h3{color:#FFF}img{height:10px;background:#A7CC00;margin:0 3px}#r{height:10px;background:#CC3D00}#clr{background:none;color:#6ED5FF;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN13_STYLE "<meta charset=UTF-8><style type=^"text/css^">body{background:#220000;font-family:Tahoma}th{background:#3E0909;color:#FFF;padding:5px 2px;text-align:left;border-bottom:1px solid #DEDEDE}td{padding:2px 2px;}table{background:#FFF;font-size:11px;border:1px solid #791616}h2,h3{color:#FFF}#c{background:#F4F4F4;color:#7B0000}img{height:7px;background:#a00000;margin:0 3px}#r{height:7px;background:#181818}#clr{background:none;color:#CFCFCF;font-size:20px;border:0}</style>"

#define STATSX_SHELL_DEFAULT_STYLE "<meta charset=UTF-8><style>body{background:#000}tr{text-align:left}table{font-size:13px;color:#FFB000;padding:2px}h2,h3{color:#FFF;font-family:Verdana}img{height:5px;background:#0000FF;margin:0 3px}#r{height:5px;background:#FF0000}</style>"


new g_iBitUserStatsLoad;
const TOTAL_PLAYER_LEVELS =					16;
new const g_szRankName[TOTAL_PLAYER_LEVELS][]= 
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

new const g_szRankNameCT[TOTAL_PLAYER_LEVELS][]=
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

enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX,
    EXT_DATA__LOGIN[MAX_NAME_LENGTH],
    EXT_DATA__AUTH[MAX_AUTHID_LENGTH]
}



new g_sLastDate[MAX_PLAYERS + 1][MAX_NAME_LENGTH], g_sRegDate[MAX_PLAYERS + 1][MAX_NAME_LENGTH];


//new bool:ConnectDB

new g_iFwdLoadStats,
	g_iFwdSaveStats;
new Handle:g_hDBRegsStatsHandle;
new g_iLimitMoney;

new bool:g_iUserChangename[MAX_PLAYERS + 1];

#if !defined CREATE_MULTIFORWARD
new	g_szRankHost[32], 
	g_szRankUser[32], 
	g_szRankPassword[32], 
	g_szRankDataBase[32];

#endif
//new	RANK_TABLE[32];

#define IsSetBit(%1,%2) (%1 & (1 << (%2 & 31)))
#define IsSetBitBool(%1,%2) (IsSetBit(%1,%2) ? true : false)
#define SetBit(%1,%2) %1 |= (1 << (%2 & 31))
#define ClearBit(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin("[MYSQL] Regs Stats", "1.0a", "DalgaPups");
	g_iFwdLoadStats = CreateMultiForward("jbe_load_stats", ET_CONTINUE, FP_CELL) ;
	g_iFwdSaveStats = CreateMultiForward("jbe_save_stats", ET_CONTINUE, FP_CELL) ;
	
	

	register_dictionary("jbe_core.txt");
	
	
	
	
	
	new szPath[64], szPathFile[128];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	
	formatex(szPathFile, charsmax(szPathFile), "%s/jb_engine/mysql_regs.cfg", szPath);
	if(file_exists(szPathFile))
		RegisterMysqlSystems(szPathFile);
	else server_print("%s NOT FOUND", szPath);
	
	#if !defined CREATE_MULTIFORWARD
	SqlInit();
	#endif
	
	

	
	
	#if defined SQL_TEST_PERFORMNACE
	register_clcmd("stats_mysql3", "test3")
    register_clcmd("stats_mysql2", "test2")
	#endif
	
	
	new pcvar;
	pcvar = create_cvar("jbe_limit_money", "1000", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iLimitMoney); 
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	//cvars_init();
}



RegisterMysqlSystems(cfg[])
{
	register_cvar("jbe_mysql_sql_host", "localhost");
	register_cvar("jbe_mysql_sql_user", "root");
	register_cvar("jbe_mysql_sql_password", "55555");
	register_cvar("jbe_mysql_sql_database",  "test");
	register_cvar("jbe_mysql_sql_stats_table",  "awdsad");
	ExecCfg(cfg);
	
}

ExecCfg(const cfg[])
{
	server_cmd("exec %s", cfg);
	server_exec();
}
#if defined CREATE_MULTIFORWARD

public RegsCoreApiLoaded(Handle:sqlTuple)
{
	g_hDBRegsStatsHandle = sqlTuple;
	//get_cvar_string("jbe_mysql_sql_stats_table",			RANK_TABLE, 		charsmax(RANK_TABLE));
	SQL_SetCharset(g_hDBRegsStatsHandle, "utf8");
	
	//server_print("%d", g_hDBRegsStatsHandle);
	new query[QUERY_LENGTH * 2] = "", que_len;

	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL AUTO_INCREMENT, \
		    `Login` VARCHAR(32) NOT NULL default '',\
			`setting_1` int(11) NOT NULL, \
			`setting_2` int(11) NOT NULL, \
			`setting_3` int(11) NOT NULL, ", RANK_TABLE
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_4` int(11) NOT NULL, \
			`setting_5` int(11) NOT NULL, \
			`setting_6` int(11) NOT NULL, \
			`setting_7` int(11) NOT NULL, \
			`setting_8` int(11) NOT NULL, \
			`setting_9` int(11) NOT NULL, \
			`setting_10` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_11` int(11) NOT NULL, \
			`setting_12` int(11) NOT NULL, \
			`setting_13` int(11) NOT NULL, \
			`setting_14` int(11) NOT NULL, \
			`setting_15` int(11) NOT NULL, \
			`setting_16` int(11) NOT NULL, \
			`setting_17` int(11) NOT NULL, \
			`setting_18` int(11) NOT NULL, \
			`setting_19` int(11) NOT NULL, \
			`setting_20` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_21` int(11) NOT NULL, \
			`setting_22` int(11) NOT NULL, \
			`setting_23` int(11) NOT NULL, \
			`setting_24` int(11) NOT NULL, \
			`setting_25` int(11) NOT NULL, \
			`setting_26` int(11) NOT NULL, \
			`setting_27` int(11) NOT NULL, \
			`setting_28` int(11) NOT NULL, \
			`setting_29` int(11) NOT NULL, \
			`setting_30` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_31` int(11) NOT NULL, \
			`setting_32` int(11) NOT NULL, \
			`setting_33` int(11) NOT NULL, \
			`setting_34` int(11) NOT NULL, \
			`setting_35` int(11) NOT NULL, \
			`setting_36` int(11) NOT NULL, \
			`setting_37` int(11) NOT NULL, \
			`setting_38` int(11) NOT NULL, \
			`setting_39` int(11) NOT NULL, \
			`setting_40` int(11) NOT NULL , "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_41` int(11) NOT NULL , \
			`setting_42` int(11) NOT NULL , \
			`setting_43` FLOAT NOT NULL , \
			`setting_44` FLOAT NOT NULL , \
			`setting_45` int(11) NOT NULL, \
			`setting_46` int(11) NOT NULL, \
			`setting_47` int(11) NOT NULL, \
			`setting_48` int(11) NOT NULL, \
			`setting_49` int(11) NOT NULL, \
			`setting_50` int(11) NOT NULL,"
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_51` int(11) NOT NULL, \
			`setting_52` int(11) NOT NULL, \
			`setting_53` int(11) NOT NULL, \
			`setting_54` int(11) NOT NULL, \
			`setting_55` int(11) NOT NULL, \
			`setting_56` int(11) NOT NULL, \
			`setting_57` int(11) NOT NULL, \
			`setting_58` int(11) NOT NULL, \
			`setting_59` int(11) NOT NULL, \
			`setting_60` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_61` int(11) NOT NULL, \
			`setting_62` int(11) NOT NULL, \
			`setting_63` int(11) NOT NULL, \
			`setting_64` int(11) NOT NULL, \
			`setting_65` int(11) NOT NULL, \
			`setting_66` int(11) NOT NULL, \
			`setting_67` int(11) NOT NULL, \
			`setting_68` int(11) NOT NULL, \
			`setting_69` int(11) NOT NULL, \
			`setting_70` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`QUEST_1` int(11) NOT NULL, \
			`QUEST_2` int(11) NOT NULL, \
			`QUEST_3` int(11) NOT NULL, \
			`QUEST_4` int(11) NOT NULL, \
			`QUEST_5` int(11) NOT NULL, \
			`QUEST_6` int(11) NOT NULL, \
			`QUEST_7` int(11) NOT NULL, \
			`QUEST_8` int(11) NOT NULL, \
			`QUEST_9` int(11) NOT NULL, \
			`QUEST_10` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`QUEST_11` int(11) NOT NULL, \
			`QUEST_12` int(11) NOT NULL, \
			`QUEST_13` int(11) NOT NULL, \
			`QUEST_14` int(11) NOT NULL, \
			`QUEST_15` int(11) NOT NULL, \
			`EXP_T` INT(11) NOT NULL DEFAULT '0',\
			`EXP_CT` INT(11) NOT NULL DEFAULT '0',\
			`RegDate` DATETIME,\
			`LastDate` DATETIME,\
			`Name` VARCHAR(32)  NOT NULL, \
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB,\
		AUTO_INCREMENT=3;"
	);
	

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_INITDB;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
}

#else
public SqlInit() 
{


	get_cvar_string("jbe_mysql_sql_host", 					g_szRankHost, 		charsmax(g_szRankHost));
	get_cvar_string("jbe_mysql_sql_user", 					g_szRankUser, 		charsmax(g_szRankUser));
	get_cvar_string("jbe_mysql_sql_password", 				g_szRankPassword,	charsmax(g_szRankPassword));
	get_cvar_string("jbe_mysql_sql_database", 				g_szRankDataBase, 	charsmax(g_szRankDataBase));
	get_cvar_string("jbe_mysql_sql_stats_table",			RANK_TABLE, 		charsmax(RANK_TABLE));
	

	SQL_SetAffinity("mysql");
	g_hDBRegsStatsHandle = SQL_MakeDbTuple(g_szRankHost, g_szRankUser, g_szRankPassword, g_szRankDataBase, 1);

	new error[MAX_NAME_LENGTH], errnum
	new Handle:g_StatsHandle = SQL_Connect(g_hDBRegsStatsHandle, errnum, error, MAX_NAME_LENGTH - 1)
	
	if(g_StatsHandle == Empty_Handle)
	{
		new szText[128];
		formatex(szText, charsmax(szText), "%s", error);
		log_to_file("mysqlt.log", "[MYSQL_STATS] MYSQL ERROR: #%d", errnum);
		log_to_file("mysqlt.log", "[MYSQL_STATS] %s", szText);
		return;
	}
	
	SQL_FreeHandle(g_StatsHandle);

	new query[QUERY_LENGTH * 2], que_len;

	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL AUTO_INCREMENT, \
		    `Login` VARCHAR(32) NOT NULL default '',\
			`setting_1` int(11) NOT NULL, \
			`setting_2` int(11) NOT NULL, \
			`setting_3` int(11) NOT NULL, ", RANK_TABLE
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_4` int(11) NOT NULL, \
			`setting_5` int(11) NOT NULL, \
			`setting_6` int(11) NOT NULL, \
			`setting_7` int(11) NOT NULL, \
			`setting_8` int(11) NOT NULL, \
			`setting_9` int(11) NOT NULL, \
			`setting_10` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_11` int(11) NOT NULL, \
			`setting_12` int(11) NOT NULL, \
			`setting_13` int(11) NOT NULL, \
			`setting_14` int(11) NOT NULL, \
			`setting_15` int(11) NOT NULL, \
			`setting_16` int(11) NOT NULL, \
			`setting_17` int(11) NOT NULL, \
			`setting_18` int(11) NOT NULL, \
			`setting_19` int(11) NOT NULL, \
			`setting_20` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_21` int(11) NOT NULL, \
			`setting_22` int(11) NOT NULL, \
			`setting_23` int(11) NOT NULL, \
			`setting_24` int(11) NOT NULL, \
			`setting_25` int(11) NOT NULL, \
			`setting_26` int(11) NOT NULL, \
			`setting_27` int(11) NOT NULL, \
			`setting_28` int(11) NOT NULL, \
			`setting_29` int(11) NOT NULL, \
			`setting_30` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_31` int(11) NOT NULL, \
			`setting_32` int(11) NOT NULL, \
			`setting_33` int(11) NOT NULL, \
			`setting_34` int(11) NOT NULL, \
			`setting_35` int(11) NOT NULL, \
			`setting_36` int(11) NOT NULL, \
			`setting_37` int(11) NOT NULL, \
			`setting_38` int(11) NOT NULL, \
			`setting_39` int(11) NOT NULL, \
			`setting_40` int(11) NOT NULL , "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_41` int(11) NOT NULL , \
			`setting_42` int(11) NOT NULL , \
			`setting_43` FLOAT NOT NULL , \
			`setting_44` FLOAT NOT NULL , \
			`setting_45` int(11) NOT NULL, \
			`setting_46` int(11) NOT NULL, \
			`setting_47` int(11) NOT NULL, \
			`setting_48` int(11) NOT NULL, \
			`setting_49` int(11) NOT NULL, \
			`setting_50` int(11) NOT NULL,"
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_51` int(11) NOT NULL, \
			`setting_52` int(11) NOT NULL, \
			`setting_53` int(11) NOT NULL, \
			`setting_54` int(11) NOT NULL, \
			`setting_55` int(11) NOT NULL, \
			`setting_56` int(11) NOT NULL, \
			`setting_57` int(11) NOT NULL, \
			`setting_58` int(11) NOT NULL, \
			`setting_59` int(11) NOT NULL, \
			`setting_60` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`setting_61` int(11) NOT NULL, \
			`setting_62` int(11) NOT NULL, \
			`setting_63` int(11) NOT NULL, \
			`setting_64` int(11) NOT NULL, \
			`setting_65` int(11) NOT NULL, \
			`setting_66` int(11) NOT NULL, \
			`setting_67` int(11) NOT NULL, \
			`setting_68` int(11) NOT NULL, \
			`setting_69` int(11) NOT NULL, \
			`setting_70` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`QUEST_1` int(11) NOT NULL, \
			`QUEST_2` int(11) NOT NULL, \
			`QUEST_3` int(11) NOT NULL, \
			`QUEST_4` int(11) NOT NULL, \
			`QUEST_5` int(11) NOT NULL, \
			`QUEST_6` int(11) NOT NULL, \
			`QUEST_7` int(11) NOT NULL, \
			`QUEST_8` int(11) NOT NULL, \
			`QUEST_9` int(11) NOT NULL, \
			`QUEST_10` int(11) NOT NULL, "
	);
	que_len += formatex(query[que_len],charsmax(query) - que_len,"`QUEST_11` int(11) NOT NULL, \
			`QUEST_12` int(11) NOT NULL, \
			`QUEST_13` int(11) NOT NULL, \
			`QUEST_14` int(11) NOT NULL, \
			`QUEST_15` int(11) NOT NULL, \
			`EXP_T` INT(11) NOT NULL DEFAULT '0',\
			`EXP_CT` INT(11) NOT NULL DEFAULT '0',\
			`RegDate` DATETIME,\
			`LastDate` DATETIME,\
			`Name` VARCHAR(32)  NOT NULL, \
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB,\
		AUTO_INCREMENT=3;"
	);
	

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_INITDB;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
}

#endif


public plugin_natives() {
	register_native("jbe_mysql_stats_add", "jbe_mysql_stats_add")
	
	register_native("jbe_mysql_stats_save", "jbe_mysql_stats_save")
	register_native("jbe_mysql_stats_load", "jbe_mysql_stats_load")
	
	register_native("jbe_mysql_quest_get_reg", "jbe_mysql_quest_get_reg")
	register_native("jbe_mysql_quest_get_last", "jbe_mysql_quest_get_last")
	
	
	register_native("change_name", "change_name", 1);
	
	register_native("regs_show_motd", "regs_show_motd", 1);

}

public plugin_end() 
{

#if defined CLOSE_CONNECTION
//SQL_FreeHandle(g_hDBRegsStatsHandle);

#if !defined CREATE_MULTIFORWARD
	DestroyForward(g_iFwdLoadStats);
	DestroyForward(g_iFwdSaveStats);
#endif
#endif	
	
}
#if defined CREATE_MULTIFORWARD
public RegsCoreApiDisconnect()
{

	DestroyForward(g_iFwdLoadStats);
	DestroyForward(g_iFwdSaveStats);
}
#endif




public jbe_mysql_quest_get_last(plugin_id, num_params)
{
	new id;
	id=get_param(1);
	
	return set_string(2, g_sLastDate[id], get_param(3));
}

public jbe_mysql_quest_get_reg(plugin_id, num_params)
{
	new id;
	id=get_param(1);
	
	return set_string(2, g_sRegDate[id], get_param(3));
}




public jbe_mysql_stats_add(plugin_id, num_params) 
{
	new s_login[MAX_NAME_LENGTH ]; 
	get_string(1, s_login, MAX_NAME_LENGTH - 1)
	new id = get_param(2)

	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)

	new query[QUERY_LENGTH],que_len
	que_len += formatex(query[que_len],charsmax(query) - que_len, "SELECT * FROM `%s` WHERE `Login` = '%s'", RANK_TABLE, s_login)


	#if defined DEBUGCHECK_LOG
	server_print("stats_add => %s | %d", s_login, id);
	#endif



	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_STATS_ADD;
	sData[EXT_DATA__INDEX] = id;
	sData[EXT_DATA__USERID] = get_user_userid(id);
	copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, s_login);
	copy(sData[EXT_DATA__AUTH], MAX_NAME_LENGTH - 1, szAuth);
	
	mysql_escape_string(s_login, charsmax(s_login));

	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
}


#if defined DEBUG
public fsfefes(id)
{

	for(new i = MIN_SETTINGS; i <= MAX_TOTAL_SETTINGS + 2; i++) 
	{
		#if defined DEBUG
		//server_print("%s | %d/%d | %s",RANK_TABLE, jbe_mysql_stats_systems_get(id, i),i, s_login)
		server_print("[PRE] #SQL_ReadResult - %d/%d" , jbe_mysql_stats_systems_get(id,i) ,i);
		#endif
	}

}
#endif
public jbe_mysql_stats_save(plugin_id, num_params) 
{

	new s_login[MAX_NAME_LENGTH]; 
	get_string(1, s_login, MAX_NAME_LENGTH - 1)

	new id = get_param(2)
	
	if(!IsSetBitBool(g_iBitUserStatsLoad, id))
	{
		ClearBit(g_iBitUserStatsLoad, id);
		return PLUGIN_CONTINUE;
	}

	new iRet
	ExecuteForward(g_iFwdSaveStats , iRet , id);
	
	for(new i = MIN_SETTINGS; i <= MAX_TOTAL_SETTINGS + 2; i++) 
	{
		#if defined DEBUG
		//server_print("%s | %d/%d | %s",RANK_TABLE, jbe_mysql_stats_systems_get(id, i),i, s_login)
		server_print("[PRE] #SQL_ReadResult - %d/%d | %s" , jbe_mysql_stats_systems_get(id,i) ,i, s_login);
		#endif
	}


	new query[QUERY_LENGTH],que_len
	que_len = formatex(query[que_len],charsmax(query) - que_len, "\
		UPDATE `%s` SET \
			`setting_1` = '%d', \
			`setting_2` = '%d', \
			`setting_3` = '%d', \
			`setting_4` = '%d', \
			`setting_5` = '%d', \
			`setting_6` = '%d', \
			`setting_7` = '%d', \
			`setting_8` = '%d', \
			`setting_9` = '%d', \
			`setting_10` = '%d',", 

			RANK_TABLE,

			jbe_mysql_stats_systems_get(id, 1), 	
			jbe_mysql_stats_systems_get(id, 2), 	
			jbe_mysql_stats_systems_get(id, 3),	
			jbe_mysql_stats_systems_get(id, 4), 	
			jbe_mysql_stats_systems_get(id, 5),
			jbe_mysql_stats_systems_get(id, 6),		
			jbe_mysql_stats_systems_get(id, 7),		
			jbe_mysql_stats_systems_get(id, 8),	
			jbe_mysql_stats_systems_get(id, 9),		
			jbe_get_butt(id)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`setting_11` = '%d', \
			`setting_12` = '%d', \
			`setting_13` = '%d', \
			`setting_14` = '%d', \
			`setting_15` = '%d', \
			`setting_16` = '%d', \
			`setting_17` = '%d', \
			`setting_18` = '%d', \
			`setting_19` = '%d', \
			`setting_20` = '%d', ",
			
			jbe_mysql_stats_systems_get(id, 11), 	
			jbe_mysql_stats_systems_get(id, 12), 	
			jbe_mysql_stats_systems_get(id, 13),
			jbe_mysql_stats_systems_get(id, 14), 	
			jbe_mysql_stats_systems_get(id, 15),
			jbe_mysql_stats_systems_get(id, 16),	
			jbe_mysql_stats_systems_get(id, 17),	
			jbe_mysql_stats_systems_get(id, 18),
			jbe_mysql_stats_systems_get(id, 19),	
			jbe_mysql_stats_systems_get(id, 20)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
			`setting_21` = '%d', \
			`setting_22` = '%d', \
			`setting_23` = '%d', \
			`setting_24` = '%d', \
			`setting_25` = '%d', \
			`setting_26` = '%d', \
			`setting_27` = '%d', \
			`setting_28` = '%d', \
			`setting_29` = '%d', \
			`setting_30` = '%d', ",

			jbe_mysql_stats_systems_get(id, 21), 	
			jbe_mysql_stats_systems_get(id, 22), 	
			jbe_mysql_stats_systems_get(id, 23),
			jbe_mysql_stats_systems_get(id, 24), 	
			jbe_mysql_stats_systems_get(id, 25),
			jbe_mysql_stats_systems_get(id, 26),	
			jbe_mysql_stats_systems_get(id, 27),	
			jbe_mysql_stats_systems_get(id, 28),
			jbe_mysql_stats_systems_get(id, 29),	
			jbe_mysql_stats_systems_get(id, 30)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
			`setting_31` = '%d', \
			`setting_32` = '%d', \
			`setting_33` = '%d', \
			`setting_34` = '%d', \
			`setting_35` = '%d', \
			`setting_36` = '%d', \
			`setting_37` = '%d', \
			`setting_38` = '%d', \
			`setting_39` = '%d', \
			`setting_40` = '%d' \
			WHERE `Login` = '%s';",

			jbe_mysql_stats_systems_get(id, 31), 	
			jbe_mysql_stats_systems_get(id, 32), 	
			jbe_mysql_stats_systems_get(id, 33),
			jbe_mysql_stats_systems_get(id, 34), 	
			jbe_mysql_stats_systems_get(id, 35),
			jbe_mysql_stats_systems_get(id, 36),	
			jbe_mysql_stats_systems_get(id, 37),	
			jbe_mysql_stats_systems_get(id, 38),
			jbe_mysql_stats_systems_get(id, 39),	
			jbe_get_informer_color(id, 1),
			s_login
	)
	
	#if defined ENABLE_INGOREHANDLED
	{
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__SQL] = SQL_STATS_SAVE;
		SQL_ThreadQuery(g_hDBRegsStatsHandle, "IgnoreHandle", query, sData, sizeof sData);
		

		//server_print("Strlen #1: %d", jbe_get_butt(id));

	}
	#else
	{
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_IGNORE;
		sData[EXT_DATA__INDEX] = id;
		
		SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	#endif

	query = "";
	que_len = 0;
	
	que_len = formatex(query[que_len],charsmax(query) - que_len, "\
		UPDATE `%s` SET \
			`setting_41` = '%d', \
			`setting_42` = '%d', \
			`setting_43` = '%f', \
			`setting_44` = '%f', \
			`setting_45` = '%d', \
			`setting_46` = '%d', \
			`setting_47` = '%d', \
			`setting_48` = '%d', \
			`setting_49` = '%d', \
			`setting_50` = '%d', ",
			
			RANK_TABLE,

			jbe_get_informer_color(id, 2), 	
			jbe_get_informer_color(id, 3), 	
			jbe_get_informer_pos(id, 1),
			jbe_get_informer_pos(id, 2),
			jbe_mysql_stats_systems_get(id, 45),
			jbe_mysql_stats_systems_get(id, 46),	
			jbe_mysql_stats_systems_get(id, 47),	
			jbe_mysql_stats_systems_get(id, 48),
			jbe_mysql_stats_systems_get(id, 49),	
			jbe_mysql_stats_systems_get(id, 50)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
			`setting_51` = '%d', \
			`setting_52` = '%d', \
			`setting_53` = '%d', \
			`setting_54` = '%d', \
			`setting_55` = '%d', \
			`setting_56` = '%d', \
			`setting_57` = '%d', \
			`setting_58` = '%d', \
			`setting_59` = '%d', \
			`setting_60` = '%d', ",

			jbe_mysql_stats_systems_get(id, 51), 	
			jbe_mysql_stats_systems_get(id, 52), 	
			jbe_mysql_stats_systems_get(id, 53),
			jbe_mysql_stats_systems_get(id, 54), 	
			jbe_mysql_stats_systems_get(id, 55),
			jbe_mysql_stats_systems_get(id, 56),	
			jbe_mysql_stats_systems_get(id, 57),	
			jbe_mysql_stats_systems_get(id, 58),
			jbe_mysql_stats_systems_get(id, 59),	
			jbe_mysql_stats_systems_get(id, 60)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`setting_61` = '%d', \
			`setting_62` = '%d', \
			`setting_63` = '%d', \
			`setting_64` = '%d', \
			`setting_65` = '%d', \
			`setting_66` = '%d', \
			`setting_67` = '%d', \
			`setting_68` = '%d', \
			`setting_69` = '%d', \
			`setting_70` = '%d', ",

			jbe_mysql_stats_systems_get(id, 61), 	
			jbe_mysql_stats_systems_get(id, 62), 	
			jbe_mysql_stats_systems_get(id, 63),
			jbe_mysql_stats_systems_get(id, 64), 	
			jbe_mysql_stats_systems_get(id, 65),
			jbe_mysql_stats_systems_get(id, 66),	
			jbe_mysql_stats_systems_get(id, 67),	
			jbe_mysql_stats_systems_get(id, 68),
			jbe_mysql_stats_systems_get(id, 69),	
			jbe_mysql_stats_systems_get(id, 60)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`QUEST_1` = '%d',\
			`QUEST_2` = '%d',\
			`QUEST_3` = '%d',\
			`QUEST_4` = '%d',\
			`QUEST_5` = '%d', \
			`QUEST_6` = '%d',\
			`QUEST_7` = '%d',\
			`QUEST_8` = '%d',\
			`QUEST_9` = '%d',\
			`QUEST_10` = '%d', ",

			jbe_mysql_stats_systems_get(id, 71), 	
			jbe_mysql_stats_systems_get(id, 72), 	
			jbe_mysql_stats_systems_get(id, 73),
			jbe_mysql_stats_systems_get(id, 74), 	
			jbe_mysql_stats_systems_get(id, 75),
			jbe_mysql_stats_systems_get(id, 76),	
			jbe_mysql_stats_systems_get(id, 77),	
			jbe_mysql_stats_systems_get(id, 78),
			jbe_mysql_stats_systems_get(id, 79),	
			jbe_mysql_stats_systems_get(id, 70)
	)
	que_len += formatex(query[que_len],charsmax(query) - que_len, "`QUEST_11` = '%d',\
			`QUEST_12` = '%d',\
			`QUEST_13` = '%d',\
			`QUEST_14` = '%d',\
			`QUEST_15` = '%d',\
			`EXP_T` = '%d',\
			`EXP_CT` = '%d',\
			`LastDate` = NOW() \
			WHERE `Login` = '%s';",

			jbe_mysql_stats_systems_get(id, 81), 	
			jbe_mysql_stats_systems_get(id, 82), 	
			jbe_mysql_stats_systems_get(id, 83),
			jbe_mysql_stats_systems_get(id, 84), 	
			jbe_mysql_stats_systems_get(id, 85),
			jbe_mysql_stats_systems_get(id, 86),	
			jbe_mysql_stats_systems_get(id, 87),	
			s_login
	);

	#if defined DEBUGCHECK_LOG
	server_print("stats_save => %s | %d", s_login, id);
	#endif

	
	ClearBit(g_iBitUserStatsLoad, id);
	#if defined ENABLE_INGOREHANDLED
	{
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__INDEX] = id;
		SQL_ThreadQuery(g_hDBRegsStatsHandle, "IgnoreHandle", query, sData, sizeof sData);
		

		

	}
	#else
	{
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_IGNORE;
		sData[EXT_DATA__INDEX] = id;
		
		SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	#endif
	
	
	return PLUGIN_CONTINUE;
}

public jbe_mysql_stats_load(plugin_id, num_params) 
{
	new s_login[MAX_NAME_LENGTH]; 
	get_string(1, s_login, MAX_NAME_LENGTH - 1);
	new id = get_param(2)
	
	//player_all_reset(id);
	jbe_reset_informer_pos(id);
	

	new query_buffer[QUERY_LENGTH];
	formatex(query_buffer,charsmax(query_buffer), "SELECT * FROM `%s` WHERE `Login` = '%s'",RANK_TABLE, s_login)


	#if defined DEBUGCHECK_LOG
	server_print("stats_load => %s | %d", s_login, id);
	#endif

	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_STATS_LOAD;
	sData[EXT_DATA__INDEX] = id;
	sData[EXT_DATA__USERID] = get_user_userid(id);
	copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, s_login);
	copy(sData[EXT_DATA__AUTH], MAX_NAME_LENGTH - 1, szAuth);

	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);
}




public change_name(id) 
{	
	
	if(!get_login(id))
	{
		client_print_color(id, 0, "^x04[AuthSystems]^x01 Упс...Что-то пошло не так");
		return PLUGIN_CONTINUE;
	}
	if(g_iUserChangename[id])
	{
		client_print_color(id, 0, "^x04[AuthSystems]^x01 Имя можно менять раз за карту");
		return PLUGIN_CONTINUE;
	}
	new login[13];
	get_login_len(id, login, 12);
	
	new szName[MAX_NAME_LENGTH + 1];
	get_user_name(id, szName, MAX_NAME_LENGTH - 1);
	
	mysql_escape_string(szName, charsmax(szName));
	

	new query_buffer[QUERY_LENGTH],que_len
	que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "UPDATE `%s` SET `Name` = '%s' WHERE `Login` = '%s'",RANK_TABLE, szName, login);
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__INDEX] = id;
	sData[EXT_DATA__SQL] = SQL_IGNORE;

	SQL_ThreadQuery(g_hDBRegsStatsHandle, "IgnoreHandle", query_buffer, sData, sizeof sData);

	g_iUserChangename[id] = true;
	client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно сменили имя на: ^x04%n", id);
	client_print_color(id, 0, "^x04[AuthSystems]^x01 Это измениться в Топах,и различнах статах... изменение вступит после смены карт");

	return PLUGIN_CONTINUE;

}

public regs_show_motd(pId, iType)
{
	switch(iType)
	{
		case 1: show_motd(pId, g_sBuffer, "Статистика")
		case 2: show_motd(pId, g_sBuffer1, "Статистика")
		case 3: show_motd(pId, g_sBuffer2, "Статистика")
		case 4: show_motd(pId, g_sBuffer3, "Статистика")
	}

}

public fwTop(id) 
{
        show_motd(id, g_sBuffer, "Статистика")
        return PLUGIN_HANDLED
}

public fwTop1(id) 
{
        show_motd(id, g_sBuffer1, "Статистика")
        return PLUGIN_HANDLED
}
public fwTop2(id) 
{
        show_motd(id, g_sBuffer2, "Статистика")
        return PLUGIN_HANDLED
}

public fwTop3(id) 
{
        show_motd(id, g_sBuffer3, "Статистика")
        return PLUGIN_HANDLED
}

public dgrduyt()
{
	set_cvar_string("jbe_mysql_sql_password", "***hiden***");
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
			new lastQue[QUERY_LENGTH];
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_to_file("mysqlt.log","%s", lastQue)
			return PLUGIN_CONTINUE;
		}
	}
	switch(data[EXT_DATA__SQL])
	{
		case SQL_IGNORE: {}
		case SQL_STATS_SAVE: 
		{
			new id = data[EXT_DATA__INDEX];

			player_all_reset(id);
			jbe_reset_informer_pos(id);
			jbe_set_butt(id, 0);
			
		}
	}
	SQL_FreeHandle(query);
	return PLUGIN_CONTINUE;
}



public selectQueryHandler(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szPrefix[64];
			switch(data[EXT_DATA__SQL])
			{
				case SQL_INITDB: 	szPrefix = "Первичное подключение";
				case SQL_IGNORE: 	szPrefix = "Запрос пропуска";
				case SQL_STATS_LOAD: 		szPrefix = "Запрос загрузки";
				case SQL_STATS_SAVE: 		szPrefix = "Запрос сохранение";
				case SQL_TOP_1: 	szPrefix = "Запрос статистика - 1";
				case SQL_TOP_2: 	szPrefix = "Запрос статистика - 2";
				case SQL_TOP_3: 	szPrefix = "Запрос статистика - 2";
			}

			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			

			log_amx("%s [%s]", szText, szPrefix)
			log_amx("%s",err)



			new lastQue[QUERY_LENGTH], szText2[128];
			formatex(szText2, charsmax(szText2), "======================================================");
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_amx("%s",szText2)
			log_amx("[ SQL ] %s",lastQue)
			
			if(failstate == TQUERY_CONNECT_FAILED)
			{
				set_task(0.1, "dgrduyt");
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	
	switch(data[EXT_DATA__SQL])
	{
		case SQL_INITDB: 
		{
			//ConnectDB = true;
			#if !defined CREATE_MULTIFORWARD
			new szText[128];
			formatex(szText, charsmax(szText), "[MySql] Статистика игроков успешно загружено. DB delay: %.12f sec", queuetime);
			log_amx(szText);
			#endif
			set_task(2.0, "mySQL_STATS_LOAD_fwdTop", TASK_SHOW_TOP);
			set_task(0.1, "dgrduyt");

		}
		case SQL_STATS_ADD:
		{
			if(!SQL_NumResults(query))
			{
				new id = data[EXT_DATA__INDEX];
				if(!is_user_connected(id)) return PLUGIN_HANDLED;
				if(get_user_userid(id) == data[EXT_DATA__USERID])
				{

					new login[32], szAuthID[MAX_AUTHID_LENGTH];

					copy(login, charsmax(login), data[EXT_DATA__LOGIN]);
					copy(szAuthID, charsmax(szAuthID), data[EXT_DATA__AUTH]);

					new szName[MAX_NAME_LENGTH + 1];
					get_user_name(id, szName, charsmax(szName))

					

					#if defined DEBUGCHECK_LOG
					server_print("SQL_STATS_LOAD_0 => %s | %d | %s", login, id, szName);
					#endif

					new query_buffer[QUERY_LENGTH * 2], que_len
					que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "INSERT INTO %s (`Login`, ", RANK_TABLE)
					for(new i = MIN_SETTINGS; i <= MAX_SETTINGS; i++)
					{
						que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`setting_%i`, ", i)
					}
					for(new i = MIN_QUEST_SETTINGS; i <= MAX_QUEST_SETTINGS; i++)
					{
						que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`QUEST_%i`,", i)
					}
					que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`EXP_T`,\
						`EXP_CT`,	\
						`RegDate`,\
						`Name`) "
					)
					que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "VALUES \
						(\
						'%s',\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
						'0' ,'0' ,'0', '0' ,'0','0','0', NOW(), '%s')", login, szName
					)

					SetBit(g_iBitUserStatsLoad, id);
					
					new sData[EXT_DATA_STRUCT];
					sData[EXT_DATA__SQL] = SQL_IGNORE;
					SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);
				}
			}
		
		}
		case SQL_STATS_LOAD:
		{

		
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				if(SQL_NumResults(query))
				{
					//while(SQL_MoreResults(query))
					//{
						#if defined DEBUG
						new login[13];
						get_login_len(id, login, 12);
						#endif

						#if defined DEBUGCHECK_LOG
						server_print("SQL_STATS_LOAD_def => %d", id);
						#endif

						
						
						jbe_set_informer_color(id, 1, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_40"))); 
						jbe_set_informer_color(id, 2, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_41")));
						jbe_set_informer_color(id, 3, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_42")));
						
						new Float:iNum,
							Float:iNum2
						SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_43"), iNum);
						SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_44"), iNum2);
						
						jbe_set_informer_pos(id, 1, iNum);
						jbe_set_informer_pos(id, 2, iNum2);
						
						
						jbe_mysql_stats_systems_add(id, 1, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_1")));
						jbe_mysql_stats_systems_add(id, 2, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_2")));
						jbe_mysql_stats_systems_add(id, 3, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_3")));
						jbe_mysql_stats_systems_add(id, 4, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_4")));
						jbe_mysql_stats_systems_add(id, 5, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_5")));
						jbe_mysql_stats_systems_add(id, 6, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_6")));
						jbe_mysql_stats_systems_add(id, 7, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_7")));
						jbe_mysql_stats_systems_add(id, 8, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_8")));
						jbe_mysql_stats_systems_add(id, 9, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_9")));
						//jbe_mysql_stats_systems_add(id, 10, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_10")));
						
						new g_iUserButt = jbe_get_butt(id);
						new g_iLoadButt = SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_10"));
						new iResulMoney = g_iUserButt + g_iLoadButt;
						
						if(iResulMoney > g_iLimitMoney)
						{
							iResulMoney = g_iLimitMoney;
							UTIL_SayText(id, "!g[!yMoneySystems!g] !yУ вас превышен лимит денег на счет (%d), Устанавливаем значение - %d", g_iLoadButt, g_iLimitMoney);
						}
						jbe_set_butt(id, iResulMoney);

						jbe_mysql_stats_systems_add(id, 11, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_11")));
						jbe_mysql_stats_systems_add(id, 12, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_12")));
						jbe_mysql_stats_systems_add(id, 13, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_13")));
						jbe_mysql_stats_systems_add(id, 14, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_14")));
						jbe_mysql_stats_systems_add(id, 15, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_15")));
						jbe_mysql_stats_systems_add(id, 16, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_16")));
						jbe_mysql_stats_systems_add(id, 17, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_17")));
						jbe_mysql_stats_systems_add(id, 18, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_18")));
						jbe_mysql_stats_systems_add(id, 19, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_19")));
						jbe_mysql_stats_systems_add(id, 20, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_20")));

						jbe_mysql_stats_systems_add(id, 21, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_21")));
						jbe_mysql_stats_systems_add(id, 22, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_22")));
						jbe_mysql_stats_systems_add(id, 23, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_23")));
						jbe_mysql_stats_systems_add(id, 24, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_24")));
						jbe_mysql_stats_systems_add(id, 25, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_25")));
						jbe_mysql_stats_systems_add(id, 26, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_26")));
						jbe_mysql_stats_systems_add(id, 27, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_27")));
						jbe_mysql_stats_systems_add(id, 28, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_28")));
						jbe_mysql_stats_systems_add(id, 29, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_29")));

						jbe_mysql_stats_systems_add(id, 30, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_30")));
						jbe_mysql_stats_systems_add(id, 31, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_31")));
						jbe_mysql_stats_systems_add(id, 32, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_32")));
						jbe_mysql_stats_systems_add(id, 33, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_33")));
						jbe_mysql_stats_systems_add(id, 34, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_34")));
						jbe_mysql_stats_systems_add(id, 35, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_35")));
						jbe_mysql_stats_systems_add(id, 36, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_36")));
						jbe_mysql_stats_systems_add(id, 37, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_37")));
						jbe_mysql_stats_systems_add(id, 38, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_38")));
						jbe_mysql_stats_systems_add(id, 39, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_39")));
						
						jbe_set_informer_color(id, 1, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_40"))); 
						jbe_set_informer_color(id, 2, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_41")));
						jbe_set_informer_color(id, 3, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_42")));
						
						
						jbe_mysql_stats_systems_add(id, 45, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_45")));
						jbe_mysql_stats_systems_add(id, 46, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_46")));
						jbe_mysql_stats_systems_add(id, 47, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_47")));
						jbe_mysql_stats_systems_add(id, 48, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_48")));
						jbe_mysql_stats_systems_add(id, 49, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_49"))); 

						jbe_mysql_stats_systems_add(id, 40, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_50")));
						jbe_mysql_stats_systems_add(id, 51, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_51")));
						jbe_mysql_stats_systems_add(id, 52, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_52")));
						jbe_mysql_stats_systems_add(id, 53, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_53")));
						jbe_mysql_stats_systems_add(id, 54, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_54")));
						jbe_mysql_stats_systems_add(id, 55, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_55")));
						jbe_mysql_stats_systems_add(id, 56, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_56")));
						jbe_mysql_stats_systems_add(id, 57, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_57")));
						jbe_mysql_stats_systems_add(id, 58, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_58")));
						jbe_mysql_stats_systems_add(id, 59, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_59")));

						jbe_mysql_stats_systems_add(id, 60, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_60")));
						jbe_mysql_stats_systems_add(id, 61, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_61")));
						jbe_mysql_stats_systems_add(id, 62, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_62")));
						jbe_mysql_stats_systems_add(id, 63, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_63")));
						jbe_mysql_stats_systems_add(id, 64, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_64")));
						jbe_mysql_stats_systems_add(id, 65, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_65")));
						jbe_mysql_stats_systems_add(id, 66, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_66")));
						jbe_mysql_stats_systems_add(id, 67, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_67")));
						jbe_mysql_stats_systems_add(id, 68, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_68")));
						jbe_mysql_stats_systems_add(id, 69, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_69")));
						jbe_mysql_stats_systems_add(id, 70, SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_70")));

						jbe_mysql_stats_systems_add(id, 71, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_1")));
						jbe_mysql_stats_systems_add(id, 72, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_2")));
						jbe_mysql_stats_systems_add(id, 73, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_3")));
						jbe_mysql_stats_systems_add(id, 74, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_4")));
						jbe_mysql_stats_systems_add(id, 75, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_5")));
						jbe_mysql_stats_systems_add(id, 76, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_6")));
						jbe_mysql_stats_systems_add(id, 77, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_7")));
						jbe_mysql_stats_systems_add(id, 78, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_8")));
						jbe_mysql_stats_systems_add(id, 79, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_9")));
						jbe_mysql_stats_systems_add(id, 80, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_10")));
						jbe_mysql_stats_systems_add(id, 81, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_11")));
						jbe_mysql_stats_systems_add(id, 82, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_12")));
						jbe_mysql_stats_systems_add(id, 83, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_13")));
						jbe_mysql_stats_systems_add(id, 84, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_14")));
						jbe_mysql_stats_systems_add(id, 85, SQL_ReadResult(query, SQL_FieldNameToNum(query,"QUEST_15")));

						jbe_mysql_stats_systems_add(id, 86, SQL_ReadResult(query, SQL_FieldNameToNum(query,"EXP_T")));
						jbe_mysql_stats_systems_add(id, 87, SQL_ReadResult(query, SQL_FieldNameToNum(query,"EXP_CT")));
						
#if defined DEBUG
						for(new i = MIN_SETTINGS; i <= MAX_TOTAL_SETTINGS + 2; i++) 
						{

							
							//server_print("%s | %d/%d | %s",RANK_TABLE, jbe_mysql_stats_systems_get(id, i),i, s_login)
							server_print("[POST] #SQL_ReadResult - %d/%d" , jbe_mysql_stats_systems_get(id,i) ,i);
							
						}
						server_print("[POST] #SQL_ReadResult - %d/%d" , jbe_get_informer_color(id,1) ,1);
						server_print("[POST] #SQL_ReadResult - %d/%d" , jbe_get_informer_color(id,2) ,2);
						server_print("[POST] #SQL_ReadResult - %d/%d" , jbe_get_informer_color(id,3) ,3);
						server_print("[POST] #SQL_ReadResult - %f/%d" , jbe_get_informer_pos(id,1) ,1);
						server_print("[POST] #SQL_ReadResult - %f/%d" , jbe_get_informer_pos(id,2) ,2);
#endif
						
#if defined SQL_TEST_PERFORMNACE
						g_count++;
						server_print("#%d Time:[%.2f]", g_count, queuetime)
#endif

						SQL_ReadResult(query, SQL_FieldNameToNum(query, "RegDate"), g_sRegDate[id], charsmax(g_sRegDate[]));
						SQL_ReadResult(query, SQL_FieldNameToNum(query, "LastDate"), g_sLastDate[id], charsmax(g_sLastDate[]));

						//fields[0] = mysql_read_result2("id");
						
						new iRet
						ExecuteForward(g_iFwdLoadStats , iRet , id);
						
						SetBit(g_iBitUserStatsLoad, id);
						
					//	SQL_NextRow(query);
				//	}
					
				}
				else
				{

					if(get_user_userid(id) == data[EXT_DATA__USERID])
					{

						new login[32], szAuthID[MAX_AUTHID_LENGTH];

						copy(login, charsmax(login), data[EXT_DATA__LOGIN]);
						copy(szAuthID, charsmax(szAuthID), data[EXT_DATA__AUTH]);

						new szName[MAX_NAME_LENGTH + 1];
						get_user_name(id, szName, charsmax(szName))

						

						#if defined DEBUGCHECK_LOG
						server_print("SQL_STATS_LOAD_0 => %s | %d | %s", login, id, szName);
						#endif

						new query_buffer[QUERY_LENGTH * 2], que_len
						que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "INSERT INTO %s (`Login`, ", RANK_TABLE)
						for(new i = MIN_SETTINGS; i <= MAX_SETTINGS; i++)
						{
							que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`setting_%i`, ", i)
						}
						for(new i = MIN_QUEST_SETTINGS; i <= MAX_QUEST_SETTINGS; i++)
						{
							que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`QUEST_%i`,", i)
						}
						que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "`EXP_T`,\
							`EXP_CT`,	\
							`RegDate`,\
							`Name`) "
						)
						que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "VALUES \
							(\
							'%s',\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,'0' ,\
							'0' ,'0' ,'0', '0' ,'0','0','0', NOW(), '%s')", login, szName
						)
						SetBit(g_iBitUserStatsLoad, id);

						new sData[EXT_DATA_STRUCT];
						sData[EXT_DATA__SQL] = SQL_IGNORE;
						SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);
					}
				}


			}
			
		}
		case SQL_STATS_SAVE:
		{
			new id = data[EXT_DATA__INDEX];

			player_all_reset(id);
			jbe_reset_informer_pos(id);
		}
		case SQL_TOP_1:
		{

			new rows1 = SQL_NumResults(query)
			new iTotalTime[15], szName[15][MAX_NAME_LENGTH + 1], time_str[64]


			new iLen;
			iLen = format( g_sBuffer[iLen], MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN1_STYLE )
			iLen += format( g_sBuffer[iLen],MAX_BUFFER_LENGTH - iLen, "<body bgcolor=#000000><table border=1 cellspacing=0 cellpadding=3px><tr><th class=p>#<td class=p><th>NickName<th>Bpem9I B urpe" )     


			if( SQL_NumResults(query) ) 
			{
				//new fields;
				for(new i = 0 ; i < rows1 ; i++)
				{
						
						//fields = mysql_read_result2("Name");

						//mysql_read_result(fields, szName[i], charsmax(szName))

						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Name"), szName[i], charsmax(szName))
						iTotalTime[i] 	= SQL_ReadResult(query, SQL_FieldNameToNum(query, "setting_3"));
						
						//SQL_ReadResult(queryHandle, 91, szName[i], charsmax(szName) )
						//iTotalTime[i]  	= SQL_ReadResult(queryHandle, 4)

						if(rows1 > 0) 
						{
							replace_all( szName[i], MAX_NAME_LENGTH, "&", "&amp;" )
							replace_all( szName[i], MAX_NAME_LENGTH, "<", "&lt;" )
							replace_all( szName[i], MAX_NAME_LENGTH, ">", "&gt;" )

							get_time_length(0, iTotalTime[i], timeunit_minutes, time_str, charsmax(time_str))

							//Top Отыгранных
							iLen += format( g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td class=p>%d<td class=p><td>%s<td>%s", i + 1, szName[i], time_str)
					    }

						SQL_NextRow(query);
				}
			}
		}
			
		case SQL_TOP_2:
		{
			new rows1 = SQL_NumResults(query)
			new iTimeT[15], szName[15][MAX_NAME_LENGTH + 1],time_str1[64]

			new iLen;
			iLen = format( g_sBuffer1[iLen], MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN5_STYLE )
			iLen += format( g_sBuffer1[iLen],MAX_BUFFER_LENGTH - iLen, "<body bgcolor=#000000><table border=1 cellspacing=0 cellpadding=3px><tr><th class=p>#<td class=p><th>NickName<th>urpa9I 3a 3eka" )     


			if( SQL_MoreResults(query) ) 
			{
				//new fields;
				for(new i = 0 ; i < rows1 ; i++)
				{

						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Name"), szName[i], charsmax(szName))
						iTimeT[i]  		= SQL_ReadResult(query, SQL_FieldNameToNum(query, "setting_4"));

						
						if(rows1 > 0) 
						{
							replace_all( szName[i], MAX_NAME_LENGTH, "&", "&amp;" )
							replace_all( szName[i], MAX_NAME_LENGTH, "<", "&lt;" )
							replace_all( szName[i], MAX_NAME_LENGTH, ">", "&gt;" )

							get_time_length(0, iTimeT[i], timeunit_minutes, time_str1, charsmax(time_str1))

							
							
							//Online За зека и охрану
							iLen += format( g_sBuffer1[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td class=p>%d<td class=p><td>%s<td>%s", i + 1, szName[i], time_str1)
					    }

						SQL_NextRow(query);
				}
			}
		}
		case SQL_TOP_3:
		{
			new rows1 = SQL_NumResults(query)
			new iLevel[15],iLevelCT[15],iButt[15],szName[15][MAX_NAME_LENGTH + 1]

			new iLen;
			iLen = format( g_sBuffer2[iLen], MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN6_STYLE )
			iLen += format( g_sBuffer2[iLen],MAX_BUFFER_LENGTH - iLen, "<body bgcolor=#000000><table border=1 cellspacing=0 cellpadding=3px><tr><th class=p>#<td class=p><th>NickName<th>Бычки<th>Звание За зека<th>Звание За охрану" )     


			if( SQL_MoreResults(query) ) 
			{
				//new fields;
				for(new i = 0 ; i < rows1 ; i++)
				{
						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Name"), szName[i], charsmax(szName))
						iLevelCT[i]  		= SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_68"));
						iLevel[i]   		= SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_69"));
						iButt[i]   			= SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_10"));

						if(rows1 > 0) 
						{
							replace_all( szName[i], MAX_NAME_LENGTH, "&", "&amp;" )
							replace_all( szName[i], MAX_NAME_LENGTH, "<", "&lt;" )
							replace_all( szName[i], MAX_NAME_LENGTH, ">", "&gt;" )

							//Бычки, Звание
							iLen += format( g_sBuffer2[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td class=p>%d<td class=p><td>%s<td>%d<td>%L<td>%L", i + 1, szName[i], iButt[i], LANG_PLAYER, g_szRankName[iLevel[i]], LANG_PLAYER, g_szRankNameCT[iLevelCT[i]])
					    }

						SQL_NextRow(query);
				}
			}
		}
		case SQL_TOP_4:
		{
			new rows1 = SQL_NumResults(query)
			new iTimeCT[15], szName[15][MAX_NAME_LENGTH + 1], time_str2[64],szTimeCT[64]

			new iLen;
			iLen = format( g_sBuffer3[iLen], MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN5_STYLE )
			iLen += format( g_sBuffer3[iLen],MAX_BUFFER_LENGTH - iLen, "<body bgcolor=#000000><table border=1 cellspacing=0 cellpadding=3px><tr><th class=p>#<td class=p><th>NickName<th>urpa9I 3a oxpaHy" )     


			if( SQL_MoreResults(query) ) 
			{
				//new fields;
				for(new i = 0 ; i < rows1 ; i++)
				{
	
						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Name"), szName[i], charsmax(szName))
						iTimeCT[i]  	= SQL_ReadResult(query, SQL_FieldNameToNum(query,"setting_5"));
						
						if(rows1 > 0) 
						{
							replace_all( szName[i], MAX_NAME_LENGTH, "&", "&amp;" )
							replace_all( szName[i], MAX_NAME_LENGTH, "<", "&lt;" )
							replace_all( szName[i], MAX_NAME_LENGTH, ">", "&gt;" )


							get_time_length(0, iTimeCT[i], timeunit_minutes, time_str2, charsmax(time_str2))
							
							if(iTimeCT[i] == 0) formatex(szTimeCT, charsmax(szTimeCT), "Не играл");
							else formatex(szTimeCT, charsmax(szTimeCT), "%s", time_str2);
							
							
							//Online За зека и охрану
							iLen += format( g_sBuffer3[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td class=p>%d<td class=p><td>%s<td>%s", i + 1, szName[i], time_str2)
							
					    }

						SQL_NextRow(query);
				}
			}
		}
		//case SQL_IGNORE: {}
	}
	return PLUGIN_HANDLED
}

public mySQL_STATS_LOAD_fwdTop()
{
	new query_buffer[QUERY_LENGTH],que_len
	que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "SELECT * FROM %s ORDER BY `setting_3` DESC LIMIT 0,15", RANK_TABLE)

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_TOP_1;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);


	set_task(2.0, "mySQL_STATS_LOAD_2fwdTop", TASK_SHOW_TOP);
}

public mySQL_STATS_LOAD_2fwdTop()
{
	new query_buffer[QUERY_LENGTH],que_len
	que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "SELECT * FROM %s ORDER BY `setting_4` DESC LIMIT 0,15", RANK_TABLE)

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_TOP_2;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);


	set_task(2.0, "mySQL_STATS_LOAD_3fwdTop", TASK_SHOW_TOP);
}

public mySQL_STATS_LOAD_3fwdTop()
{
	new query_buffer[QUERY_LENGTH],que_len
	que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "SELECT * FROM %s ORDER BY `setting_10` DESC LIMIT 0,15", RANK_TABLE)

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_TOP_3;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);
	
	set_task(2.0, "mySQL_STATS_LOAD_4fwdTop", TASK_SHOW_TOP);
}

public mySQL_STATS_LOAD_4fwdTop()
{
	new query_buffer[QUERY_LENGTH],que_len
	que_len += formatex(query_buffer[que_len],charsmax(query_buffer) - que_len, "SELECT * FROM %s ORDER BY `setting_5` DESC LIMIT 0,15", RANK_TABLE)

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_TOP_4;
	SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query_buffer, sData, sizeof sData);


	
}

#if defined SQL_TEST_PERFORMNACE
public test3(id)
{
	new s_login[32];
	s_login = "DalgaPups"
	
    g_count=0
    for(new i; i < 90; i++)
    {

		new query[QUERY_LENGTH],que_len
		que_len += formatex(query[que_len],charsmax(query) - que_len, "SELECT * FROM `%s` WHERE `Login` = '%s'",RANK_TABLE, s_login)


		#if defined DEBUGCHECK_LOG
		server_print("stats_load => %s | %d", s_login, id);
		#endif

		new szAuth[MAX_AUTHID_LENGTH];
		get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)

		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_STATS_LOAD;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);
		copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, s_login);
		copy(sData[EXT_DATA__AUTH], MAX_NAME_LENGTH - 1, szAuth);

		SQL_ThreadQuery(g_hDBRegsStatsHandle, "selectQueryHandler", query, sData, sizeof sData);
    }
    
}



	
	


public test2()
{
    static active
    active = !active
    
    if(active)
    {
        server_print("mysql_config_thread speed")
        mysql_performance(50, 50, 6)
    }
    else {
        server_print("mysql_config_thread default")
        mysql_performance(100, 100, 1)
    }
}

#endif


stock player_all_reset(id)
{
	jbe_mysql_stats_systems_add(id, 1, 0);
	jbe_mysql_stats_systems_add(id, 2, 0);
	jbe_mysql_stats_systems_add(id, 3, 0);
	jbe_mysql_stats_systems_add(id, 4, 0);
	jbe_mysql_stats_systems_add(id, 5, 0);
	jbe_mysql_stats_systems_add(id, 6, 0);
	jbe_mysql_stats_systems_add(id, 7, 0);
	jbe_mysql_stats_systems_add(id, 8, 0);
	jbe_mysql_stats_systems_add(id, 9, 0);
	jbe_mysql_stats_systems_add(id, 10, 0);

	jbe_mysql_stats_systems_add(id, 11, 0);
	jbe_mysql_stats_systems_add(id, 12, 0);
	jbe_mysql_stats_systems_add(id, 13, 0);
	jbe_mysql_stats_systems_add(id, 14, 0);
	jbe_mysql_stats_systems_add(id, 15, 0);
	jbe_mysql_stats_systems_add(id, 16, 0);
	jbe_mysql_stats_systems_add(id, 17, 0);
	jbe_mysql_stats_systems_add(id, 18, 0);
	jbe_mysql_stats_systems_add(id, 19, 0);
	jbe_mysql_stats_systems_add(id, 20, 0);

	jbe_mysql_stats_systems_add(id, 21, 0);
	jbe_mysql_stats_systems_add(id, 22, 0);
	jbe_mysql_stats_systems_add(id, 23, 0);
	jbe_mysql_stats_systems_add(id, 24, 0);
	jbe_mysql_stats_systems_add(id, 25, 0);
	jbe_mysql_stats_systems_add(id, 26, 0);
	jbe_mysql_stats_systems_add(id, 27, 0);
	jbe_mysql_stats_systems_add(id, 28, 0);
	jbe_mysql_stats_systems_add(id, 29, 0);

	jbe_mysql_stats_systems_add(id, 30, 0);
	jbe_mysql_stats_systems_add(id, 31, 0);
	jbe_mysql_stats_systems_add(id, 32, 0);
	jbe_mysql_stats_systems_add(id, 33, 0);
	jbe_mysql_stats_systems_add(id, 34, 0);
	jbe_mysql_stats_systems_add(id, 35, 0);
	jbe_mysql_stats_systems_add(id, 36, 0);
	jbe_mysql_stats_systems_add(id, 37, 0);
	jbe_mysql_stats_systems_add(id, 38, 0);
	jbe_mysql_stats_systems_add(id, 39, 0);
	//jbe_mysql_stats_systems_add(id, 40, 0);

	//jbe_mysql_stats_systems_add(id, 41, 0);
	//jbe_mysql_stats_systems_add(id, 42, 0);
	//jbe_mysql_stats_systems_add(id, 43, 0);
	//jbe_mysql_stats_systems_add(id, 44, 0);
	jbe_mysql_stats_systems_add(id, 45, 0);
	jbe_mysql_stats_systems_add(id, 46, 0);
	jbe_mysql_stats_systems_add(id, 47, 0);
	jbe_mysql_stats_systems_add(id, 48, 0);
	jbe_mysql_stats_systems_add(id, 49, 0);

	jbe_mysql_stats_systems_add(id, 40, 0);
	jbe_mysql_stats_systems_add(id, 51, 0);
	jbe_mysql_stats_systems_add(id, 52, 0);
	jbe_mysql_stats_systems_add(id, 53, 0);
	jbe_mysql_stats_systems_add(id, 54, 0);
	jbe_mysql_stats_systems_add(id, 55, 0);
	jbe_mysql_stats_systems_add(id, 56, 0);
	jbe_mysql_stats_systems_add(id, 57, 0);
	jbe_mysql_stats_systems_add(id, 58, 0);
	jbe_mysql_stats_systems_add(id, 59, 0);

	jbe_mysql_stats_systems_add(id, 60, 0);
	jbe_mysql_stats_systems_add(id, 61, 0);
	jbe_mysql_stats_systems_add(id, 62, 0);
	jbe_mysql_stats_systems_add(id, 63, 0);
	jbe_mysql_stats_systems_add(id, 64, 0);
	jbe_mysql_stats_systems_add(id, 65, 0);
	jbe_mysql_stats_systems_add(id, 66, 0);
	jbe_mysql_stats_systems_add(id, 67, 0);
	jbe_mysql_stats_systems_add(id, 68, 0);
	jbe_mysql_stats_systems_add(id, 69, 0);
	jbe_mysql_stats_systems_add(id, 70, 0);

	jbe_mysql_stats_systems_add(id, 71, 0);
	jbe_mysql_stats_systems_add(id, 72, 0);
	jbe_mysql_stats_systems_add(id, 73, 0);
	jbe_mysql_stats_systems_add(id, 74, 0);
	jbe_mysql_stats_systems_add(id, 75, 0);
	jbe_mysql_stats_systems_add(id, 76, 0);
	jbe_mysql_stats_systems_add(id, 77, 0);
	jbe_mysql_stats_systems_add(id, 78, 0);
	jbe_mysql_stats_systems_add(id, 79, 0);
	jbe_mysql_stats_systems_add(id, 80, 0);
	jbe_mysql_stats_systems_add(id, 81, 0);
	jbe_mysql_stats_systems_add(id, 82, 0);
	jbe_mysql_stats_systems_add(id, 83, 0);
	jbe_mysql_stats_systems_add(id, 84, 0);
	jbe_mysql_stats_systems_add(id, 85, 0);

	jbe_mysql_stats_systems_add(id, 86, 0);
	jbe_mysql_stats_systems_add(id, 87, 0);
}



stock mysql_escape_string(output[], len)
{
	static const szReplaceIn[][] = { "\\", "\0", "\n", "\r", "\x1a", "'", "^"" };
	static const szReplaceOut[][] = { "\\\\", "\\0", "\\n", "\\r", "\Z", "\'", "\^"" };
	for(new i; i < sizeof szReplaceIn; i++)
		replace_string(output, len, szReplaceIn[i], szReplaceOut[i]);
}


