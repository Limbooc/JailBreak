#include <amxmodx>
#include <amxmisc>
#include <sqlx>


#define RANK_TABLE		"Regs_Save_Addons"


const QUERY_LENGTH =	1472;	// размер переменной sql запроса
const SQL_CONNECTION_TIMEOUT = 10;

new Handle:g_hDQuery;



enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX,
    EXT_DATA__LOGIN[MAX_NAME_LENGTH],
    EXT_DATA__AUTH[MAX_AUTHID_LENGTH]
}

enum _:sql_que_type	// тип sql запроса
{
	SQL_LOAD,
	SQL_LOGOUT
}

enum _:enum_cvars {
	TypeID,
	CostumesID
}
	

public plugin_init() 
{
	register_plugin("[MYSQL] Regs Save Addons", "1.0a", "DalgaPups");
	
	
	
	
	register_cvar("jbe_mysql_sql_save_table",  "Regs_Save_Addons");

}

public plugin_cfg()
{
	new szPath[64], szPathFile[128];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	
	formatex(szPathFile, charsmax(szPathFile), "%s/jb_engine/mysql_regs.cfg", szPath);
	if(file_exists(szPathFile))
		RegisterMysqlSystems(szPathFile);
	else server_print("%s NOT FOUND", szPath);
}

RegisterMysqlSystems(cfg[])
{
	register_cvar("jbe_mysql_sql_save_table",  "Regs_Save_Addons");
	ExecCfg(cfg);
	
}

ExecCfg(const cfg[])
{
	server_cmd("exec %s", cfg);
	server_exec();
}

public RegsCoreApiLoaded(Handle:sqlTuple)
{
	g_hDQuery = sqlTuple;
	//get_cvar_string("jbe_mysql_sql_save_table",			RANK_TABLE, 		charsmax(RANK_TABLE));
	
	SQL_SetCharset(g_hDQuery, "utf8");
	
	new query[QUERY_LENGTH * 2] = "", que_len;
	
	que_len += formatex(query[que_len],charsmax(query) - que_len, "\
		CREATE TABLE IF NOT EXISTS `%s` \
		(\
			`id` INT(11) NOT NULL AUTO_INCREMENT,\
			`Login` VARCHAR(32) NOT NULL DEFAULT '',\
			`TypeID` INT(11) NOT NULL,\
			`CostumesID` INT(11) NOT NULL,\
			`CostumesType` INT(11) NOT NULL,\
			`Time` INT(11) NOT NULL,\
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci'\
		ENGINE=InnoDB\
	;", RANK_TABLE
	);
	
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
}


public IgnoreHandle(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{
    switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szText[128];
			new lastQue[QUERY_LENGTH]
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			if(datalen) log_to_file("mysqlt.log", "Query state: %d", data[0]);
			log_to_file("mysqlt.log","[Regs_Save]  %s", szText)
			log_to_file("mysqlt.log","%s",err)
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_to_file("mysqlt.log","%s", lastQue)
			return PLUGIN_CONTINUE;
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

			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);

			new lastQue[QUERY_LENGTH], szText2[128];
			formatex(szText2, charsmax(szText2), "[Regs_Save]");
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_amx("%s",szText2)
			log_amx("[ SQL ] %s",lastQue)

			return;
		}
	}
	
	
	switch(data[EXT_DATA__SQL])
	{
		case SQL_LOAD: 
		{
			if(!SQL_NumResults(query)) 
			{
				new id = data[EXT_DATA__INDEX];
				
				if(is_user_connected(id))
				{
					if(get_user_userid(id) == data[EXT_DATA__USERID])
					{
						new query[QUERY_LENGTH], que_len;
						
						new Login[32];

						copy(Login, charsmax(Login), data[EXT_DATA__LOGIN]);
						que_len += formatex(query[que_len],charsmax(query) - que_len,"INSERT INTO `%s` (`Login`) VALUES ('%s');", RANK_TABLE, Login);
						
						SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
					}
				}
			}
			else
			{
				server_print("LOAD");
			
			
			}

		}
		case SQL_LOGOUT:
		{
		
		}
	}
	return;
}


public jbe_regs_logout(pId, Login[])
{
	new query[QUERY_LENGTH], que_len;
	que_len += formatex(query[que_len],charsmax(query) - que_len,"UPDATE `%s` SET `TypeID` = '%s'", RANK_TABLE, Login);
	que_len += formatex(query[que_len], charsmax(query) - que_len, ", `CostumesID` = '%s'", Login);
	que_len += formatex(query[que_len], charsmax(query) - que_len, " WHERE `Login` = '%s';", Login);	
	
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
}

public jbe_regs_register(pId, Login[])
{
	new query[QUERY_LENGTH], que_len;
	que_len += formatex(query[que_len],charsmax(query) - que_len,"INSERT INTO `%s` (`Login`) VALUES ('%s');", RANK_TABLE, Login);
	
	SQL_ThreadQuery(g_hDQuery, "IgnoreHandle", query);
}

public jbe_regs_load_user(pId, Login[])
{
	new query[QUERY_LENGTH];
	formatex(query,charsmax(query),"SELECT * FROM `%s` WHERE `Login` = '%s'", RANK_TABLE, Login);
	
	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_LOAD;
	sData[EXT_DATA__INDEX] = pId;
	sData[EXT_DATA__USERID] = get_user_userid(pId);
	copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, Login);
	SQL_ThreadQuery(g_hDQuery, "selectQueryHandler", query, sData, sizeof sData);
}