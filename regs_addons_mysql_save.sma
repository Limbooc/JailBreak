#include <amxmodx>
#include <sqlx>


#define RANK_TABLE 	"Regs_BlockUser"


#define    	PLUGIN_NAME         "MysqL Core"
#define    	PLUGIN_VERSION      "1.0"
#define    	PLUGIN_AUTHOR      	"DalgaPups"



#define CREATE_MULTIFORWARD


#if defined CREATE_MULTIFORWARD
forward RegsCoreApiLoaded(Handle:sqlTuple);
forward RegsCoreApiDisconnect();
#endif


const QUERY_LENGTH =	1472	// размер переменной sql запроса

enum _:STATS
{
	STATS_DATA_1,
	STATS_DATA_2,
	STATS_DATA_3,
	STATS_DATA_4,
	STATS_DATA_5,
	STATS_DATA_6[MAX_NAME_LENGTH],
	STATS_DATA_7,
	STATS_DATA_8,
	STATS_INFLICTOR_NAME[MAX_NAME_LENGTH],
	STATS_DATE[MAX_NAME_LENGTH]
};

enum _:sql_que_type	// тип sql запроса
{
	SQL_INITDB,
	SQL_IGNORE,
	SQL_LOAD,
	SQL_CHECK,
	SQL_UPDATE
}

enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX
}



new g_iStatsPlayers[MAX_PLAYERS + 1][STATS];

const SQL_CONNECTION_TIMEOUT = 10;

new bool:g_iSql = false, 
	Handle:g_hDBSaveOther;
#if !defined CREATE_MULTIFORWARD
new	Handle:g_MysqlConnect;
#endif





public plugin_init( )
{
	register_plugin
	( 
		PLUGIN_NAME, 
		PLUGIN_VERSION, 
		PLUGIN_AUTHOR 
	);

	new szPath[64], szPathFile[128];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	
	formatex(szPathFile, charsmax(szPathFile), "%s/jb_engine/mysql_regs.cfg", szPath);
	if(file_exists(szPathFile))
		RegisterMysqlSystems(szPathFile);

	#if !defined CREATE_MULTIFORWARD
	SqlInit();
	#endif

	//cvars_init();
}

RegisterMysqlSystems(cfg[])
{
	register_cvar("jbe_mysql_sql_host", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_user", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_password", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_database",  "", FCVAR_PROTECTED);
	register_cvar("jbe_sql_prefixes_table",  "", FCVAR_PROTECTED);

	ExecCfg(cfg);
}

ExecCfg(const cfg[])
{
	server_cmd("exec %s", cfg);
	server_exec();
}


public plugin_natives() 
{
	register_native("jbe_is_user_data", "jbe_is_user_data", true);
	register_native("jbe_set_user_data", "jbe_set_user_data", true);
	register_native("jbe_block_reasons", "jbe_block_reasons");
	register_native("jbe_mysql_block_date", "jbe_mysql_block_date", false);
	register_native("jbe_mysql_block_inf_name", "jbe_mysql_block_inf_name", false);
	register_native("jbe_mysql_block_time", "jbe_mysql_block_time", true);
	register_native("jbe_mysql_block_reason", "jbe_mysql_block_reason", false);
	register_native("jbe_mysql_block_start_time", "jbe_mysql_block_start_time", true);
}

public jbe_mysql_block_date(plugin_id, num_params)
{
	new id;
	id=get_param(1);
	
	return set_string(2, g_iStatsPlayers[id][STATS_DATE], get_param(3));
}

public jbe_mysql_block_inf_name(plugin_id, num_params)
{
	new id;
	id=get_param(1);
	
	return set_string(2, g_iStatsPlayers[id][STATS_INFLICTOR_NAME], get_param(3));
}

public jbe_mysql_block_reason(plugin_id, num_params)
{
	new id;
	id=get_param(1);
	
	return set_string(2, g_iStatsPlayers[id][STATS_DATA_6], get_param(3));
}

public jbe_mysql_block_time(id) return g_iStatsPlayers[id][STATS_DATA_7];
public jbe_mysql_block_start_time(id) return g_iStatsPlayers[id][STATS_DATA_8];


public jbe_block_reasons(plugins_params, num_params)
{
	new id = get_param(1);

	new szTemp[32];
	get_string(2, szTemp, charsmax(szTemp));
	
	copy(g_iStatsPlayers[id][STATS_DATA_6], 31, szTemp);
	g_iStatsPlayers[id][STATS_DATA_7] = get_param(3);

	g_iStatsPlayers[id][STATS_DATA_8] = get_param(4);

	g_iStatsPlayers[id][STATS_INFLICTOR_NAME] = get_param(5);

	new szName[MAX_NAME_LENGTH];
	get_string(5, szName, MAX_NAME_LENGTH - 1);
	copy(g_iStatsPlayers[id][STATS_INFLICTOR_NAME], MAX_NAME_LENGTH - 1, szName);

	if(g_iSql)
	{
		new query[QUERY_LENGTH],que_len
		new szAuthID[MAX_AUTHID_LENGTH];

		get_user_authid(id, szAuthID, MAX_AUTHID_LENGTH - 1);

		que_len += formatex(query[que_len],charsmax(query) - que_len,"\
		UPDATE `%s` SET \
		\
		`DATA_1` = '%i',\
		`DATA_6` = '%s',\
		`DATA_7` = '%i',\
		`DATA_8` = '%i',\
		`DATA_INFLICTOR` = '%s',\
		`DATE_BLOCK` = NOW() \
		\
		WHERE `AUTH` = '%s'", 
		RANK_TABLE, 	

						g_iStatsPlayers[id][STATS_DATA_1], 
						g_iStatsPlayers[id][STATS_DATA_6],
						g_iStatsPlayers[id][STATS_DATA_7],
						g_iStatsPlayers[id][STATS_DATA_8],  
						g_iStatsPlayers[id][STATS_INFLICTOR_NAME],   

		szAuthID);

		
		SQL_ThreadQuery(g_hDBSaveOther, "IgnoreHandle", query);
	}
}
	
public jbe_is_user_data(player, iType)
{
	switch(iType)
	{
		case 1: return g_iStatsPlayers[player][STATS_DATA_1];
		case 2: return g_iStatsPlayers[player][STATS_DATA_2];
		case 3: return g_iStatsPlayers[player][STATS_DATA_3];
		case 4: return g_iStatsPlayers[player][STATS_DATA_4];
		case 5: return g_iStatsPlayers[player][STATS_DATA_5];
		case 7: return g_iStatsPlayers[player][STATS_DATA_7];
		case 8: return g_iStatsPlayers[player][STATS_DATA_8];
	}
	return PLUGIN_HANDLED;
}

public jbe_set_user_data(player, iType, iNum)
{
	switch(iType)
	{
		case 1: g_iStatsPlayers[player][STATS_DATA_1] = iNum;
		case 2: g_iStatsPlayers[player][STATS_DATA_2] = iNum;
		case 3: g_iStatsPlayers[player][STATS_DATA_3] = iNum;
		case 4: g_iStatsPlayers[player][STATS_DATA_4] = iNum;
		case 5: g_iStatsPlayers[player][STATS_DATA_5] = iNum;
	}
	return PLUGIN_HANDLED;
}

#if defined CREATE_MULTIFORWARD

public RegsCoreApiLoaded(Handle:sqlTuple)
{
	g_hDBSaveOther = sqlTuple;
	
	SQL_SetCharset(g_hDBSaveOther, "utf8");
	
	new query[QUERY_LENGTH],que_len
	que_len += formatex(query[que_len],charsmax(query) - que_len,"CREATE TABLE IF NOT EXISTS `%s`\
	(\
		`id`		int(11) NOT NULL AUTO_INCREMENT,\
		`AUTH`   	varchar(35) NOT NULL,\
		`DATA_1` 	int(11) NOT NULL, \
		`DATA_2` 	int(11) NOT NULL, \
		`DATA_3` 	int(11) NOT NULL, \
		`DATA_4` 	int(11) NOT NULL, \
		`DATA_5` 	int(11) NOT NULL, \
		`DATA_6`   	varchar(35) NOT NULL COLLATE 'utf8_general_ci',\
		`DATA_7` 	int(11) NOT NULL, \
		`DATA_8` 	int(11) NOT NULL, \
		`DATA_INFLICTOR` 	varchar(35) NOT NULL, \
		`DATE_BLOCK` DATETIME,\
		PRIMARY KEY (id)\
	)", RANK_TABLE);


	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_INITDB;
	SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
}

#else

public SqlInit() 
{
	new	g_szRankHost[128], 
		g_szRankUser[64], 
		g_szRankPassword[64], 
		g_szRankDataBase[64];

	get_cvar_string("jbe_mysql_sql_host", 			g_szRankHost, 		charsmax(g_szRankHost));
	get_cvar_string("jbe_mysql_sql_user", 			g_szRankUser, 		charsmax(g_szRankUser));
	get_cvar_string("jbe_mysql_sql_password", 		g_szRankPassword,	charsmax(g_szRankPassword));
	get_cvar_string("jbe_mysql_sql_database", 		g_szRankDataBase, 	charsmax(g_szRankDataBase));
	get_cvar_string("jbe_sql_prefixes_table",			RANK_TABLE, 		charsmax(RANK_TABLE));


	g_hDBSaveOther = SQL_MakeDbTuple
	(
		g_szRankHost, 
        g_szRankUser, 
        g_szRankPassword,
        g_szRankDataBase,
        SQL_CONNECTION_TIMEOUT
    );
	
	new error[32], errnum
	g_MysqlConnect = SQL_Connect(g_hDBSaveOther, errnum, error, 31)

	if(g_MysqlConnect == Empty_Handle)
	{
		new szText[128];
		formatex(szText, charsmax(szText), "%s", error);
		log_to_file("mysqlt.log", "[MYSQL_SAVE_BLOCK] MYSQL ERROR: #%d", errnum);
		log_to_file("mysqlt.log", "[MYSQL_SAVE_BLOCK] %s", szText);
		return;
	}
	
	SQL_FreeHandle(g_MysqlConnect);

	
	new query[QUERY_LENGTH],que_len
	que_len += formatex(query[que_len],charsmax(query) - que_len,"CREATE TABLE IF NOT EXISTS `%s`\
	(\
		`id`		int(11) NOT NULL AUTO_INCREMENT,\
		`AUTH`   	varchar(35) NOT NULL,\
		`DATA_1` 	int(11) NOT NULL, \
		`DATA_2` 	int(11) NOT NULL, \
		`DATA_3` 	int(11) NOT NULL, \
		`DATA_4` 	int(11) NOT NULL, \
		`DATA_5` 	int(11) NOT NULL, \
		`DATA_6`   	varchar(35) NOT NULL COLLATE 'utf8_general_ci',\
		`DATA_7` 	int(11) NOT NULL, \
		`DATA_8` 	int(11) NOT NULL, \
		`DATA_INFLICTOR` 	varchar(35) NOT NULL, \
		`DATE_BLOCK` DATETIME,\
		PRIMARY KEY (id)\
	)", RANK_TABLE);


	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_INITDB;
	SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
}

#endif


public client_disconnected(iPlayer) 
{
	g_iStatsPlayers[iPlayer][STATS_DATA_1] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_2] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_3] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_4] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_5] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_6] = "";
	g_iStatsPlayers[iPlayer][STATS_DATA_7] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_8] = 0;
	g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME] = "";
	g_iStatsPlayers[iPlayer][STATS_DATE] = "";
}

public client_putinserver( iPlayer )
{
	g_iStatsPlayers[iPlayer][STATS_DATA_1] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_2] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_3] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_4] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_5] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_6] = "";
	g_iStatsPlayers[iPlayer][STATS_DATA_7] = 0;
	g_iStatsPlayers[iPlayer][STATS_DATA_8] = 0;
	g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME] = "";
	g_iStatsPlayers[iPlayer][STATS_DATE] = "";

	if(g_iSql)
	{
		new query[QUERY_LENGTH], que_len, szAuthID[MAX_AUTHID_LENGTH];
		
		get_user_authid(iPlayer, szAuthID, MAX_AUTHID_LENGTH - 1);

		que_len += formatex(query[que_len],charsmax(query) - que_len,"SELECT \
		DATA_1, DATA_2, DATA_3, DATA_4,\
		DATA_5, DATA_6, DATA_7, DATA_8,\
		DATA_INFLICTOR, DATE_BLOCK \
		FROM %s WHERE (`AUTH` = '%s')", RANK_TABLE, szAuthID);
			
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_LOAD;
		sData[EXT_DATA__INDEX] = iPlayer;
		sData[EXT_DATA__USERID] = get_user_userid(iPlayer);
		
		SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
	}
}

/*public plugin_end() 
{
	if(g_MysqlConnect != Empty_Handle) SQL_FreeHandle(g_MysqlConnect);
}*/



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
	
	SQL_FreeHandle(query);
	return PLUGIN_CONTINUE;
}




public selectQueryHandler(failstate, Handle:query, err[], errNum, data[], datalen) 
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED:  // ошибка соединения с mysql сервером
		{
			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			log_amx("%s", szText)
			log_amx("%s",err)
			
			return PLUGIN_HANDLED
		}
		case TQUERY_QUERY_FAILED:  // ошибка SQL запроса
		{
			new lastQue[QUERY_LENGTH]
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос

			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			
			log_amx("%s", szText)
			log_amx("%s",err)
			log_amx("[ SQL ] %s",lastQue)
			
			return PLUGIN_HANDLED
		}
	}
	
	
	switch(data[EXT_DATA__SQL])
	{
		case SQL_INITDB: 
		{
			#if !defined CREATE_MULTIFORWARD
			new szText[128];
			formatex(szText, charsmax(szText), "[MySql] Дополнительное хранение об игроке успешно загружено. DB delay: %.12f sec", datalen);
			log_amx(szText);
			#endif
			g_iSql = true;
		}
		case SQL_CHECK:
		{
			new iPlayer = data[EXT_DATA__INDEX];
			if(!is_user_connected(iPlayer)) return PLUGIN_CONTINUE

			if(SQL_NumResults(query))
			{
				g_iStatsPlayers[iPlayer][STATS_DATA_1] = 0;
				g_iStatsPlayers[iPlayer][STATS_DATA_6] = "";
				g_iStatsPlayers[iPlayer][STATS_DATA_7] = 0;
				g_iStatsPlayers[iPlayer][STATS_DATA_8] = 0;
				g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME] = "";
				g_iStatsPlayers[iPlayer][STATS_DATE] = "";
				//server_print("RESUTL TRUE")
			}//else server_print("RESUTL false")
		}
		case SQL_UPDATE:
		{
			new players[MAX_PLAYERS],pnum
			get_players(players,pnum)
			new query[QUERY_LENGTH],que_len
			
			for(new i,iPlayer ; i < pnum ; i++)
			{
				iPlayer = players[i]
				
				
				new szAuthID[35];

				//server_print("Проверка - %s", g_iStatsPlayers[iPlayer][STATS_DATA_6])

				

				get_user_authid(iPlayer, szAuthID, charsmax(szAuthID));

				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
				UPDATE `%s` SET \
				`DATA_1` = '%i',\
				`DATA_2` = '%i',\
				`DATA_3` = '%i',\
				`DATA_4` = '%i',\
				`DATA_5`= '%i',\
				`DATA_6` = '%s',\
				`DATA_7`= '%i',\
				`DATA_8`= '%i',\
				`DATA_INFLICTOR` = '%s'\
				WHERE `AUTH` = '%s'",  
				RANK_TABLE, 	g_iStatsPlayers[iPlayer][STATS_DATA_1], 
								g_iStatsPlayers[iPlayer][STATS_DATA_2],
								g_iStatsPlayers[iPlayer][STATS_DATA_3],
								g_iStatsPlayers[iPlayer][STATS_DATA_4],
								g_iStatsPlayers[iPlayer][STATS_DATA_5], 
								g_iStatsPlayers[iPlayer][STATS_DATA_6],
								g_iStatsPlayers[iPlayer][STATS_DATA_7],
								g_iStatsPlayers[iPlayer][STATS_DATA_8],  
								g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME], 
								szAuthID);
				new sData[EXT_DATA_STRUCT];
				sData[EXT_DATA__SQL] = SQL_IGNORE;
				
				//DB_AddQuery(query,que_len)
				SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
		}
		
		}
		case SQL_LOAD:
		{
			new iPlayer = data[EXT_DATA__INDEX];
			if(!is_user_connected(iPlayer)) return PLUGIN_CONTINUE
			
			if(get_user_userid(iPlayer) == data[EXT_DATA__USERID])
			{

				
				
				switch(SQL_NumResults(query))
				{
					case 0:
					{
						new szAuthID[MAX_AUTHID_LENGTH];
						get_user_authid(iPlayer, szAuthID, MAX_AUTHID_LENGTH - 1);
						
						new query[QUERY_LENGTH], que_len
						que_len += formatex(query[que_len],charsmax(query) - que_len, "INSERT INTO %s \
							(\
							AUTH, \
							`DATA_1`,\
							`DATA_2`,\
							`DATA_3`,\
							`DATA_4`,\
							`DATA_5`,\
							`DATA_6`,\
							`DATA_7`,\
							`DATA_8`,\
							`DATA_INFLICTOR`,\
							`DATE_BLOCK`\
							) \
							\
							VALUES (\
							'%s', \
							0, \
							0,\
							0,\
							0,\
							0,\
							0,\
							0,\
							0,\
							0,\
							NOW()\
							);", RANK_TABLE, szAuthID);	
						new sData[EXT_DATA_STRUCT];
						sData[EXT_DATA__SQL] = SQL_IGNORE;
						SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
					}
					default:
					{
						if(SQL_NumResults(query))
						{
							//while(SQL_MoreResults(query))
							//{
								g_iStatsPlayers[iPlayer][STATS_DATA_1] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_1"));
								g_iStatsPlayers[iPlayer][STATS_DATA_2] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_2"));
								g_iStatsPlayers[iPlayer][STATS_DATA_3] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_3"));
								g_iStatsPlayers[iPlayer][STATS_DATA_4] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_4"));
								g_iStatsPlayers[iPlayer][STATS_DATA_5] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_5"));
								SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_6"), g_iStatsPlayers[iPlayer][STATS_DATA_6], 31)
								g_iStatsPlayers[iPlayer][STATS_DATA_7] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_7"));
								g_iStatsPlayers[iPlayer][STATS_DATA_8] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_8"));
								SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATA_INFLICTOR"), g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME], 31)
								SQL_ReadResult(query, SQL_FieldNameToNum(query, "DATE_BLOCK"), g_iStatsPlayers[iPlayer][STATS_DATE], 31);
								
								//SQL_NextRow(query);
							//}
						}
						
						/*while(mysql_more_results())
						{
							
							g_iStatsPlayers[iPlayer][STATS_DATA_1] = mysql_read_result2("DATA_1")
							g_iStatsPlayers[iPlayer][STATS_DATA_2] = mysql_read_result2("DATA_2")
							g_iStatsPlayers[iPlayer][STATS_DATA_3] = mysql_read_result2("DATA_3")
							g_iStatsPlayers[iPlayer][STATS_DATA_4] = mysql_read_result2("DATA_4")
							g_iStatsPlayers[iPlayer][STATS_DATA_5] = mysql_read_result2("DATA_5")
							mysql_read_result2("DATA_6", g_iStatsPlayers[iPlayer][STATS_DATA_6], 31)
							g_iStatsPlayers[iPlayer][STATS_DATA_7] = mysql_read_result2("DATA_7")
							g_iStatsPlayers[iPlayer][STATS_DATA_8] = mysql_read_result2("DATA_8")
							mysql_read_result2("DATA_INFLICTOR", g_iStatsPlayers[iPlayer][STATS_INFLICTOR_NAME], 31)
							mysql_read_result2("DATE_BLOCK", g_iStatsPlayers[iPlayer][STATS_DATE], 31)

							mysql_next_row();
						}*/
						
						/*if(g_iStatsPlayers[iPlayer][STATS_DATA_1])
						{
							new query[QUERY_LENGTH],que_len

							new szAuthID[MAX_AUTHID_LENGTH];
							get_user_authid(iPlayer, szAuthID, charsmax(szAuthID));

							que_len += formatex(query[que_len],charsmax(query) - que_len,"SELECT `DATA_1` FROM %s WHERE (`AUTH` = '%s' AND (`DATA_8` + `DATA_7`) < UNIX_TIMESTAMP(NOW()) AND `DATA_7` > '0')", RANK_TABLE, szAuthID);
					
							new sData[EXT_DATA_STRUCT];
							sData[EXT_DATA__SQL] = SQL_CHECK;
							sData[EXT_DATA__INDEX] = iPlayer;
							
							SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
						}*/
						
		
						//set_task(5.0 , "mysql_query_check", iPlayer + 12345);
					}
				}
			}
		}
		case SQL_IGNORE: {}
	}

	return PLUGIN_HANDLED
}

public mysql_query_check(iPlayer)
{
	iPlayer -= 12345;
	
	if(g_iStatsPlayers[iPlayer][STATS_DATA_1])
	{
		new query[QUERY_LENGTH],que_len

		new szAuthID[MAX_AUTHID_LENGTH];
		get_user_authid(iPlayer, szAuthID, charsmax(szAuthID));

		que_len += formatex(query[que_len],charsmax(query) - que_len,"SELECT `DATA_1` FROM %s WHERE (`AUTH` = '%s' AND (`DATA_8` + `DATA_7`) < UNIX_TIMESTAMP(NOW()) AND `DATA_7` > '0')", RANK_TABLE, szAuthID);
			
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_CHECK;
		sData[EXT_DATA__INDEX] = iPlayer;
		
		SQL_ThreadQuery(g_hDBSaveOther, "selectQueryHandler", query, sData, sizeof sData);
	}



}
