#include <amxmodx>
#include <amxmisc>
#include <sqlx>

const VERSION = 1;



const QUERY_LENGTH =	1472;	// размер переменной sql запроса
const SQL_CONNECTION_TIMEOUT = 10;

#define ALREADY_REG				//дает запрет на мультиаккаунт на один СтимАйди
//#define DEBUG_LOG					//логирование каждой действии в консоле при неудачной попытки подключение
//#define SQL_CHECKING_LOG			//Дополнительный лог
//#define SQL_TEST_PERFORMNACE		//Проверка производительности скорости работы запроса

#if defined SQL_TEST_PERFORMNACE
new g_count;
#endif


/*====Native====*/
/*====START====*/
native jbe_mysql_stats_add(login[], id);
native jbe_mysql_stats_save(login[], id);
native jbe_mysql_stats_load(login[], id);
native jbe_set_butt(p,fds);
native regs_main_menu(id);
native show_log_menu(id);
native show_reg_menu(id);
native register_clear_login(id);
native jbe_is_user_connected(pId);


/*====Native====*/
/*====END====*/


new g_sLogin[MAX_PLAYERS + 1][13], 
	g_sPassword[MAX_PLAYERS + 1][13],
	g_iUserID[MAX_PLAYERS + 1],
	bool:g_iSql,
	bool:g_iUserChangeAutoLog[MAX_PLAYERS + 1], 
	bool:g_iUserChangePass[MAX_PLAYERS + 1],
	Handle:g_hDBHandle,
	g_iFwdHandle,
	g_iFwdEndHandle,
	g_iSyncInformer;

new	g_szRankTable[32];
new g_iFwdUserLogOut,
	g_iFwdUserRegister,
	g_iFwdUserLoadUser;
enum _:sql_que_type	// тип sql запроса
{
	SQL_INIT,
	SQL_IGNORE,
	SQL_LOAD,
	SQL_SAVE,
	SQL_CHECK,
	SQL_RELOADDB,
	SQL_LOADPLAYERDB,
	SQL_RELOADSTEAMDB,
	SQL_AUTOLOADDB,
	SQL_LOGINCHECK,
	SQL_STARTRELOADSTDB,
	SQL_UPDATE,
	SQL_USER_CONNECT,
	SQL_ALEADYCONNECT
}

enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__USERID,
	EXT_DATA__INDEX,
    EXT_DATA__LOGIN[MAX_NAME_LENGTH],
    EXT_DATA__PASS[MAX_NAME_LENGTH],
    EXT_DATA__EMAIL[MAX_NAME_LENGTH],
	EXT_DATA__CHECKTYPE
}

#define TASK_PUTINSERVER		965783648
#define TASK_PUTINSERVER_TASK	798457698435
public plugin_init() 
{
	register_plugin("[MYSQL] Regs Core", "1.0a", "DalgaPups");

	g_iFwdUserLogOut = CreateMultiForward("jbe_regs_logout", ET_CONTINUE, FP_CELL, FP_STRING) ;
	g_iFwdUserRegister = CreateMultiForward("jbe_regs_register", ET_CONTINUE, FP_CELL, FP_STRING) ;
	g_iFwdUserLoadUser = CreateMultiForward("jbe_regs_load_user", ET_CONTINUE, FP_CELL, FP_STRING) ;

	g_iFwdHandle = CreateMultiForward("RegsCoreApiLoaded", ET_IGNORE, FP_CELL) ;
	g_iFwdEndHandle = CreateMultiForward("RegsCoreApiDisconnect", ET_IGNORE) ;

	//server_print("%d | %d", g_iFwdUserLogOut, g_iFwdUserRegister);

	new szPath[64], szPathFile[128];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	
	formatex(szPathFile, charsmax(szPathFile), "%s/jb_engine/mysql_regs.cfg", szPath);
	if(file_exists(szPathFile))
		RegisterMysqlSystems(szPathFile);
	else server_print("%s NOT FOUND", szPath);

	SqlInit();

	//cvars_init();
	#if defined SQL_TEST_PERFORMNACE
	register_clcmd("test_mysql", "test")
    register_clcmd("test_mysql2", "test2")
	#endif
	
	g_iSyncInformer = CreateHudSyncObj();
}

RegisterMysqlSystems(cfg[])
{

	register_cvar("jbe_mysql_sql_host", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_user", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_password", "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_database",  "", FCVAR_PROTECTED);
	register_cvar("jbe_mysql_sql_table",  "", FCVAR_PROTECTED);
	
	ExecCfg(cfg);
}

ExecCfg(const cfg[])
{
	server_cmd("exec %s", cfg);
	server_exec();
}




public plugin_natives() 
{
	register_native("is_login_using", "is_login_using");
	register_native("register_user", "register_user");
	register_native("login_user", "login_user");
	register_native("get_login", "get_login");
	register_native("get_login_len", "get_login_len");
	register_native("forgot_user", "forgot_user");
	register_native("get_pass_len", "get_pass_len");
	register_native("logout_user", "logout_user", 1);
	register_native("change_pass", "change_pass");
	register_native("mysql_get_connected", "mysql_get_connected");
	register_native("reload_steamid", "reload_steamid");
	register_native("ifchange_autologin" , "ifchange_autologin", 1);
	register_native("ifchange_pass" , "ifchange_pass", 1);
	register_native("jbe_mysql_quest_get_id", "jbe_mysql_quest_get_id", 1)
	//register_native("is_login_connect_inserver", "is_login_connect_inserver");
}
public jbe_mysql_quest_get_id(pId) return g_iUserID[pId];
public ifchange_pass(id) return g_iUserChangePass[id];
public ifchange_autologin(id) return g_iUserChangeAutoLog[id];


public mysql_get_connected() return g_iSql;

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
	get_cvar_string("jbe_mysql_sql_table",			g_szRankTable, 		charsmax(g_szRankTable));


	g_hDBHandle = SQL_MakeDbTuple(g_szRankHost, g_szRankUser, g_szRankPassword, g_szRankDataBase, 1);
	//server_print("%d", g_hDBHandle);
	new error[32], errnum
	new Handle:g_CoreHandle = SQL_Connect(g_hDBHandle, errnum, error, 31)
	//g_CoreHandle 

	if(g_CoreHandle == Empty_Handle)
	{
		new szText[128];
		formatex(szText, charsmax(szText), "%s", error);
		log_to_file("mysqlt.log", "[MYSQL_CORE] MYSQL ERROR: #%d", errnum);
		log_to_file("mysqlt.log", "[MYSQL_CORE] %s", szText);
		return;
	}
	SQL_FreeHandle(g_CoreHandle);
	
	new iRet;
	ExecuteForward(g_iFwdHandle, iRet, g_hDBHandle);	

	new query[QUERY_LENGTH], que_len;

	que_len += formatex(query[que_len],charsmax(query) - que_len, "CREATE TABLE IF NOT EXISTS `%s` (\
	`id` int(11) NOT NULL AUTO_INCREMENT,\
	`Login` VARCHAR(12) NOT NULL default '',\
	`Password` VARCHAR(12) NOT NULL default '',\
	`Email` VARCHAR(32) NOT NULL default '',\
	`Auth` VARCHAR(32) NOT NULL default '',\
	`OnlineStatus` int(11) NOT NULL,\
	PRIMARY KEY (`id`))", g_szRankTable);
	

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_INIT;
	
	

	SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	
	
	
}





stock UpdateDB(login[]="", pass[]="", email[]="", id) 
{	
	if(g_iSql)
	{
		re_mysql_escape_string(login, MAX_NAME_LENGTH - 1);
		re_mysql_escape_string(email, MAX_NAME_LENGTH - 1);
		re_mysql_escape_string(pass, MAX_NAME_LENGTH - 1);
		
		
		new szAuth[MAX_AUTHID_LENGTH];
		get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len, "SELECT `Login` FROM %s WHERE `Auth` = '%s'",g_szRankTable, szAuth);
		
		
		
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_CHECK;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);

		copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, login);
		copy(sData[EXT_DATA__PASS], MAX_NAME_LENGTH - 1, pass);
		copy(sData[EXT_DATA__EMAIL], MAX_NAME_LENGTH - 1, email);

		#if defined SQL_CHECKING_LOG
		server_print("SQL_CHECK | %s | %s | %s", login, pass, email);
		#endif

		SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_HANDLED;
}


stock LoadDB(login[]="", pass[]="", id) 
{
	if(g_iSql)
	{
		re_mysql_escape_string(login, MAX_NAME_LENGTH - 1);
		re_mysql_escape_string(pass, MAX_NAME_LENGTH - 1);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT OnlineStatus FROM %s WHERE `Login` = '%s'",g_szRankTable, login);

		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_ALEADYCONNECT;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);
		sData[EXT_DATA__CHECKTYPE] = 1;
		copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, login);
		copy(sData[EXT_DATA__PASS], MAX_NAME_LENGTH - 1, pass);
		
		SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_HANDLED;
}

stock ReLoadDB(login[]="", email[]="", id) 
{
	if(g_iSql)
	{
		re_mysql_escape_string(login, 12);
		re_mysql_escape_string(email, MAX_NAME_LENGTH - 1);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `Password` FROM %s WHERE `Login` = '%s' AND `Email` = '%s'",g_szRankTable, login, email);
	
		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_RELOADDB;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);

		SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_HANDLED;
}

stock ReLoadSteamDB(login[]="", email[]="", id) 
{
	if(g_iSql)
	{
		re_mysql_escape_string(login, 12);
		re_mysql_escape_string(email, MAX_NAME_LENGTH - 1);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `Auth` FROM %s WHERE `Login` = '%s' AND `Email` = '%s'",g_szRankTable, login, email);

		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_RELOADSTEAMDB;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);

		SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
	return PLUGIN_HANDLED;
}


stock AutoLoadDB(id) 
{
	new szAuth[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1);
	new query[QUERY_LENGTH];

	formatex(query,charsmax(query),  "SELECT `id`, `Login`, `Password` FROM %s WHERE `Auth` = '%s'",g_szRankTable, szAuth);

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_AUTOLOADDB;
	sData[EXT_DATA__INDEX] = id;
	sData[EXT_DATA__USERID] = get_user_userid(id);

	SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
}

public is_login_using(plugin_id, num_params)
{
	if(g_iSql)
	{
		new login[13]; get_string(1, login, 12);
		new id = get_param(2);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `Login` FROM %s WHERE `Login` = '%s'",g_szRankTable, login);

		new sData[EXT_DATA_STRUCT];
		sData[EXT_DATA__SQL] = SQL_LOGINCHECK;
		sData[EXT_DATA__INDEX] = id;
		sData[EXT_DATA__USERID] = get_user_userid(id);

		SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
	}
}


public register_user(plugin_id, num_params)
{
	new login[13];
	get_string(1, login, 12);
	
	new pass[13];
	get_string(2, pass, 12);
	
	new email[MAX_NAME_LENGTH];
	get_string(3, email, MAX_NAME_LENGTH - 1);
	
	new id = get_param(4); 
	
	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
	UpdateDB(login, pass, email, id);
}

public login_user(plugin_id, num_params)
{
	new login[13];
	get_string(1, login, 12);
	
	new pass[13];
	get_string(2, pass, 12);
	
	new id;
	id = get_param(3);
	
	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
	LoadDB(login, pass, id);
	
}

public forgot_user(plugin_id, num_params)
{
	new login[13];
	get_string(1, login, 12);
	
	new email[MAX_NAME_LENGTH];
	get_string(2, email, MAX_NAME_LENGTH - 1);
	
	new id;
	id=get_param(3);
	
	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
	ReLoadDB(login, email, id);
}

public reload_steamid(plugin_id, num_params)
{
	new login[13];
	get_string(1, login, 12);
	
	new email[MAX_NAME_LENGTH];
	get_string(2, email, MAX_NAME_LENGTH - 1);
	
	new id;
	id=get_param(3);
	
	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
	ReLoadSteamDB(login, email, id);
}

public get_login(plugin_id, num_params)
{	
	new id = get_param(1);
	
	if(!jbe_is_user_connected(id)) return false;
	
	if(strlen(g_sLogin[id])>0) return true;
	return false;
}

public get_login_len(plugin_id, num_params)
{	
	new id = get_param(1);
	
	if(strlen(g_sLogin[id])>0) 
	{
		set_string(2, g_sLogin[id], get_param(3));
		return true;
	}
	return false;
}



public get_pass_len(plugin_id, num_params)
{	
	new id = get_param(1);
	
	if(strlen(g_sPassword[id])>4) 
	{
		set_string(2, g_sPassword[id], get_param(3));
		return true;
	}
	return false;
}

public change_pass(plugin_id, num_params)
{
	new pass[MAX_NAME_LENGTH];
	get_string(1, pass, MAX_NAME_LENGTH - 1);
	
	new id = get_param(2);
	
	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
	ChangeLoadDB(pass, id);
}
new g_iTimer[MAX_PLAYERS + 1];
public client_putinserver(id)
{
	if(g_iSql)
	{
		jbe_set_butt(id, 0);
		new Float:iRandom = random_float(5.0, 20.0);
		
		iRandom = iRandom + float(id);
		set_task_ex(iRandom, "LoadPutin", id + TASK_PUTINSERVER)
		g_iTimer[id] = floatround(iRandom);
		set_task_ex(1.0, "main_informer", id + TASK_PUTINSERVER_TASK, _, _, SetTask_RepeatTimes, g_iTimer[id]);
	}
}

public main_informer(id)
{
	id -= TASK_PUTINSERVER_TASK;
	
	if(--g_iTimer[id])
	{
		set_hudmessage(255, 255, 255, 0.0, 0.13, 0, 1.5, 1.5);
		ShowSyncHudMsg(id, g_iSyncInformer, "Инициализация авто-входа в ЛК...^nзавершение через %d секунд", g_iTimer[id]);
	}

}
public LoadPutin(id)
{
	id -= TASK_PUTINSERVER;
	AutoLoadDB(id);
}
public logout_user(id) 
{

	if(task_exists(id + TASK_PUTINSERVER)) 
	{
		remove_task(id + TASK_PUTINSERVER);
		remove_task(id + TASK_PUTINSERVER_TASK);
	}
		
	jbe_mysql_stats_save(g_sLogin[id], id);
	
	new iRet;
	ExecuteForward(g_iFwdUserLogOut , iRet , id, g_sLogin[id]);
	
	new HanldeQuery[QUERY_LENGTH];
	formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '0' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);
	SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);

	/*new query[QUERY_LENGTH], que_len;
	que_len += formatex(query[que_len],charsmax(query) - que_len, "UPDATE `%s` SET `User_Used` = '0' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_IGNORE;

	SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);*/

	formatex(g_sLogin[id], charsmax(g_sLogin), "");
	formatex(g_sPassword[id], charsmax(g_sPassword), "");
	g_iUserID[id] = 0;
	
	
}

stock ChangeLoadDB(pass[]="", id) 
{	
	if(g_iSql)
	{
		re_mysql_escape_string(pass, MAX_NAME_LENGTH - 1);
		
		new query[QUERY_LENGTH], que_len;

		que_len += formatex(query[que_len],charsmax(query) - que_len,  "UPDATE `%s` SET `Password`= '%s' WHERE `Login` = '%s'",g_szRankTable, pass, g_sLogin[id]);

		client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно сменили пароль на: ^x04%s", pass);
		g_iUserChangePass[id] = true;
		
		SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", query);
		//SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
		return regs_main_menu(id);
	}
	return PLUGIN_HANDLED;
}

public plugin_end() 
{
	
	//if(g_hDBHandle != Empty_Handle) SQL_FreeHandle(g_hDBHandle);
	
	new iRet;
	ExecuteForward(g_iFwdEndHandle, iRet);	
	
	DestroyForward(g_iFwdUserLogOut);
	DestroyForward(g_iFwdUserRegister);
	DestroyForward(g_iFwdUserLoadUser);
}

public client_disconnected(id) 
{
	if(g_iSql)
	{
		if(task_exists(id + TASK_PUTINSERVER)) 
		{
			remove_task(id + TASK_PUTINSERVER);
			remove_task(id + TASK_PUTINSERVER_TASK);
		}
		if(strlen(g_sLogin[id]) > 0) 
		{
			jbe_mysql_stats_save(g_sLogin[id], id);
			
			new iRet;
			ExecuteForward(g_iFwdUserLogOut , iRet , id, g_sLogin[id]);
			
			new HanldeQuery[QUERY_LENGTH];				
			formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '0' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);
			SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);


			formatex(g_sLogin[id], charsmax(g_sLogin), "");
			formatex(g_sPassword[id], charsmax(g_sPassword), "");
			g_iUserID[id] = 0;
		}
	}
}


public dgrduyt()
{
	set_cvar_string("jbe_mysql_sql_password", "***hiden***");
}

public IgnoreHandle(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
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

public selectQueryHandler(failstate, Handle:query, const err[], errNum, const data[], datalen, Float:queuetime) 
{

	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szPrefix[64];
			switch(data[EXT_DATA__SQL])
			{
				case SQL_INIT: 	szPrefix = "Первичное подключение";
				case SQL_IGNORE: 	szPrefix = "Запрос пропуска";
				case SQL_LOAD: 		szPrefix = "Запрос загрузки";
				case SQL_SAVE: 		szPrefix = "Запрос сохранение";
				case SQL_CHECK: 	szPrefix = "Запрос регистрации";
				case SQL_RELOADDB: 	szPrefix = "Запрос восстоновление пароля";
				case SQL_LOADPLAYERDB: 	szPrefix = "Запрос входв в ЛК";
				case SQL_RELOADSTEAMDB: 	szPrefix = "Запрос перепривязки (1)";
				case SQL_AUTOLOADDB: 	szPrefix = "Запрос автовхода";
				case SQL_LOGINCHECK: 	szPrefix = "Первичное - занят логин";
				case SQL_STARTRELOADSTDB: 	szPrefix = "Запрос перепривязки (2)";
				case SQL_UPDATE: 	szPrefix = "Запрос пропуска";
			}


			new szText[128];
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			if(datalen) log_to_file("mysqlt.log", "Query state: %d", data[0]);
			log_to_file("mysqlt.log","%s [%s]", szText, szPrefix)
			log_to_file("mysqlt.log","%s",err)


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
		case SQL_INIT: 
		{
			g_iSql = true;
			new szText[128];
			formatex(szText, charsmax(szText), "[MySql] Регистрация игроков успешно загружено. DB delay: %.12f sec", datalen);
			log_amx(szText);
			//mysql_performance(50, 50, 6);
			set_task(0.1, "dgrduyt");
			
			new HanldeQuery[QUERY_LENGTH];
			formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '0' WHERE `OnlineStatus` = '1'",g_szRankTable);
			SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);
			
		}
		case SQL_LOAD:
		{
			if(!SQL_NumResults(query)) 
			{
				new id = data[EXT_DATA__INDEX];

				if(is_user_connected(id))
				{
					if(get_user_userid(id) == data[EXT_DATA__USERID])
					{
						new login[MAX_NAME_LENGTH], email[MAX_NAME_LENGTH], pass[MAX_NAME_LENGTH];

						copy(login, MAX_NAME_LENGTH - 1, data[EXT_DATA__LOGIN]);
						copy(email, MAX_NAME_LENGTH - 1, data[EXT_DATA__EMAIL]);
						copy(pass, MAX_NAME_LENGTH - 1, data[EXT_DATA__PASS]);

						#if defined SQL_CHECKING_LOG
						server_print("SQL_LOAD #2 | %s | %s | %s", login, pass, email)
						#endif

						new szAuth[MAX_AUTHID_LENGTH];
						get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)

						new query[QUERY_LENGTH], que_len;

						que_len += formatex(query[que_len],charsmax(query) - que_len, "INSERT INTO %s (`Login`, `Password`, `Email`, `Auth`, `OnlineStatus`) VALUES ('%s', '%s', '%s', '%s', '1')",g_szRankTable, login, pass, email, szAuth);
						
						formatex(g_sLogin[id], charsmax(g_sLogin), "%s", login);
						jbe_mysql_stats_add(login, id);
						g_iUserID[id] = 0;
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно зарегистрировались!");
						

						//new sData[EXT_DATA_STRUCT];
						//sData[EXT_DATA__SQL] = SQL_IGNORE;
						
						SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", query);
						//SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
						
						new iRet;
						ExecuteForward(g_iFwdUserRegister , iRet , id, login);
						return regs_main_menu(id);
					}
				}
			}
		}
		case SQL_LOADPLAYERDB:
		{
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				new login[MAX_NAME_LENGTH], pass[MAX_NAME_LENGTH];

				copy(login, MAX_NAME_LENGTH - 1, data[EXT_DATA__LOGIN]);
				copy(pass, MAX_NAME_LENGTH - 1, data[EXT_DATA__PASS]);

				switch(SQL_NumResults(query))
				{
					case 0:
					{
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Некоректно ввели ^x04Логин ^x01или ^x04Пароль^x01, повторите попытку");
						return show_log_menu(id);
					}
					default:
					{
						formatex(g_sLogin[id], charsmax(g_sLogin), "%s", login);
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно зашли в систему");
						
						//SQL_FreeHandle(queryHandle);
						//jbe_mysql_quest_load(g_sLogin[id], id);
						
						jbe_mysql_stats_load(g_sLogin[id], id);
						
						
						
						g_iUserID[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"id"));
						
						new iRet;
						ExecuteForward(g_iFwdUserLoadUser , iRet , id, g_sLogin[id]);

						new HanldeQuery[QUERY_LENGTH];
						
						formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '1' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);
						SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);
						
						

						return regs_main_menu(id);
					}
				}
			}
			
		}
		case SQL_RELOADDB:
		{
			new  id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{

				switch(SQL_NumResults(query))
				{
					case 0: 
					{
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Некоректно ввели ^x04Логин ^x01или ^x04Почта^x01, повторите попытку");
					}
					default:
					{
						//mysql_read_result2("Password", g_sPassword[id], charsmax(g_sPassword));
						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Password"), g_sPassword[id], charsmax(g_sPassword[]));
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Ваш пароль: ^x04%s", g_sPassword[id]);
					}
				}
			}
		}
		case SQL_AUTOLOADDB:
		{
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{

				if(SQL_NumResults(query))
				{

					//mysql_read_result2("Login", g_sLogin[id], charsmax(g_sLogin));
					SQL_ReadResult(query, SQL_FieldNameToNum(query, "Login"), g_sLogin[id], charsmax(g_sPassword[]));
					g_iUserID[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"id"));
					/*if(is_login_connect_inserver(g_sLogin[id], id))
					{
						formatex(g_sLogin[id], charsmax(g_sLogin), "");
						return 0;
					}*/

					
					//SQL_ReadResult(queryHandle, 1, g_sPassword[id], charsmax(g_sPassword));

					//jbe_mysql_quest_load(g_sLogin[id], id);
					jbe_mysql_stats_load(g_sLogin[id], id);
					
					new iRet;
					ExecuteForward(g_iFwdUserLoadUser , iRet , id, g_sLogin[id]);
					
					new HanldeQuery[QUERY_LENGTH];
						
					formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '1' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);
					SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);
					//prize_load(g_sLogin[id], id);

					/*new query[QUERY_LENGTH], que_len;

					que_len += formatex(query[que_len],charsmax(query) - que_len, "UPDATE `%s` SET `User_Used` = '1' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[id]);

					new sData[EXT_DATA_STRUCT];
					sData[EXT_DATA__SQL] = SQL_IGNORE;

					SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);*/
					
					#if defined SQL_TEST_PERFORMNACE
					g_count++;
					server_print("#%d -- Nick: [%n] Login: [%s] Time:[%.2f]", g_count,id,g_sLogin[id], queuetime)
					#endif
					
					client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно зашли в систему!");
					
					

				}

			}
		}
		case SQL_STARTRELOADSTDB:
		{
			new  id = data[EXT_DATA__INDEX];

			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				switch(SQL_NumResults(query))
				{
					case 0:
					{
						new query[QUERY_LENGTH], que_len;

						new szAuth[MAX_AUTHID_LENGTH];
						get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)


						que_len += formatex(query[que_len],charsmax(query) - que_len, "UPDATE `%s` SET `Auth`= '%s' WHERE `Login` = '%s'",g_szRankTable, szAuth, g_sLogin[id]);

						g_iUserChangeAutoLog[id] = true;
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Вы успешно перепривязали автологин на: ^x04%s", szAuth);

						//new sData[EXT_DATA_STRUCT];
						//sData[EXT_DATA__SQL] = SQL_IGNORE;

						SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", query);
						//SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
					}
					default:
					{
						new g_Temp[MAX_NAME_LENGTH];
						
						//mysql_read_result2("Login", g_Temp, charsmax(g_Temp));
						SQL_ReadResult(query, SQL_FieldNameToNum(query, "Login"), g_Temp, charsmax(g_Temp));
						client_print_color(id, 0, "^x04********************************************************");
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Под данный ^x04SteamID ^x01уже зарегистрирован аккаунт");
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Аккаунт: ^x04%s^x01 , для восстоновление используете вашу почту", g_Temp);
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Случая неполадки с почтой, просим обратиться администраторам");
						client_print_color(id, 0, "^x04********************************************************");
					}
				}
			}
		}
		case SQL_RELOADSTEAMDB:
		{
			new id = data[EXT_DATA__INDEX];

			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{

				switch(SQL_NumResults(query))
				{
					case  0:
					{
						client_print_color(id, 0, "^x04[AuthSystems]^x01 Некоректно ввели ^x04Логин ^x01или ^x04Почта^x01, повторите попытку");
					}
					default:
					{
						new szAuth[MAX_AUTHID_LENGTH];
						get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1)
						
						new query[QUERY_LENGTH], que_len;

						que_len += formatex(query[que_len],charsmax(query) - que_len, "SELECT `Login` FROM %s WHERE `Auth` = '%s'",g_szRankTable, szAuth);

						new sData[EXT_DATA_STRUCT];
						sData[EXT_DATA__SQL] = SQL_STARTRELOADSTDB;
						sData[EXT_DATA__INDEX] = id;
						sData[EXT_DATA__USERID] = get_user_userid(id);

						SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);

					}
				}
			}

		}
		case SQL_LOGINCHECK:
		{
			new id = data[EXT_DATA__INDEX];

			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				switch(SQL_NumResults(query))
				{
					case 0: 
					{
						return false;
					}
					default: 
					{
						client_print_color(id, print_team_default, "^x04********************************************************")
						client_print_color(id, print_team_default, "^x04[AuthSystems]^x01 Данный логин уже занят кем-то!")
						register_clear_login(id);
						return true;
					}
				}
			}
		}
		case SQL_ALEADYCONNECT:
		{
			new id = data[EXT_DATA__INDEX];

			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				//new iStatusPlayer = SQL_ReadResult(query, SQL_FieldNameToNum(query,"OnlineStatus"));
				
				if(!SQL_NumResults(query))
				{
					switch(data[EXT_DATA__CHECKTYPE])
					{
						case 1:
						{
							new login[MAX_NAME_LENGTH], pass[MAX_NAME_LENGTH];

							copy(login, MAX_NAME_LENGTH - 1, data[EXT_DATA__LOGIN]);
							copy(pass, MAX_NAME_LENGTH - 1, data[EXT_DATA__PASS]);
							
							new query[QUERY_LENGTH], que_len;

							que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `id`, `Login`, `Password` FROM %s WHERE `Login` = '%s' AND `Password` = '%s'",g_szRankTable, login, pass);

							new sData[EXT_DATA_STRUCT];
							sData[EXT_DATA__SQL] = SQL_LOADPLAYERDB;
							sData[EXT_DATA__INDEX] = id;
							sData[EXT_DATA__USERID] = get_user_userid(id);

							copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, login);
							copy(sData[EXT_DATA__PASS], MAX_NAME_LENGTH - 1, pass);

							#if defined SQL_CHECKING_LOG
							server_print("SQL_LOADPLAYERDB | %s | %s", login, pass);
							#endif

							SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
						}
						case 2:
						{
							new szAuth[MAX_AUTHID_LENGTH];
							get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1);
							new query[QUERY_LENGTH], que_len;

							que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `id`, `Login`, `Password` FROM %s WHERE `Auth` = '%s'",g_szRankTable, szAuth);

							new sData[EXT_DATA_STRUCT];
							sData[EXT_DATA__SQL] = SQL_AUTOLOADDB;
							sData[EXT_DATA__INDEX] = id;
							sData[EXT_DATA__USERID] = get_user_userid(id);

							SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
						}
					}
				}
				else
				{
					new iStatusPlayer = SQL_ReadResult(query, SQL_FieldNameToNum(query,"OnlineStatus"));
					if(!iStatusPlayer)
					{
						new login[MAX_NAME_LENGTH], pass[MAX_NAME_LENGTH];

						copy(login, MAX_NAME_LENGTH - 1, data[EXT_DATA__LOGIN]);
						copy(pass, MAX_NAME_LENGTH - 1, data[EXT_DATA__PASS]);
						
						new query[QUERY_LENGTH], que_len;

						que_len += formatex(query[que_len],charsmax(query) - que_len,  "SELECT `id`, `Login`, `Password` FROM %s WHERE `Login` = '%s' AND `Password` = '%s'",g_szRankTable, login, pass);

						new sData[EXT_DATA_STRUCT];
						sData[EXT_DATA__SQL] = SQL_LOADPLAYERDB;
						sData[EXT_DATA__INDEX] = id;
						sData[EXT_DATA__USERID] = get_user_userid(id);

						copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, login);
						copy(sData[EXT_DATA__PASS], MAX_NAME_LENGTH - 1, pass);

						#if defined SQL_CHECKING_LOG
						server_print("SQL_LOADPLAYERDB | %s | %s", login, pass);
						#endif

						SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
					}
					else
					{
						client_print_color(id, print_team_default, "^x04[AuthSystems]^x01 С этим логином на данный момент уже кто-то играет!")
					}
					return PLUGIN_HANDLED;
				}
			}
		}
		/*case SQL_USER_CONNECT:
		{
			new id = data[EXT_DATA__INDEX];

			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				new num = mysql_read_result2("User_Used")
				switch(num)
				{
					case 0:
					{
						return false;
					}
					default:
					{
						return true;
					}
				}
				
			}
		}*/
		case SQL_CHECK:
		{
			new id = data[EXT_DATA__INDEX];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			if(get_user_userid(id) == data[EXT_DATA__USERID])
			{
				
				new login[MAX_NAME_LENGTH], email[MAX_NAME_LENGTH], pass[MAX_NAME_LENGTH];

				copy(login, MAX_NAME_LENGTH - 1, data[EXT_DATA__LOGIN]);
				copy(email, MAX_NAME_LENGTH - 1, data[EXT_DATA__EMAIL]);
				copy(pass, MAX_NAME_LENGTH - 1, data[EXT_DATA__PASS]);

				#if defined SQL_CHECKING_LOG
				server_print("PRE SQL_LOAD #1 | %s | %s | %s", login, pass, email);
				#endif

				#if defined ALREADY_REG
				if(SQL_NumResults(query))
				{
					new szTemp[MAX_NAME_LENGTH];
					//SQL_ReadResult(query, SQL_FieldNameToNum(query, "Login", szTemp, charsmax(szTemp)));
					SQL_ReadResult(query, SQL_FieldNameToNum(query, "Login"), szTemp, charsmax(szTemp));
					
					client_print_color(id, 0, "^x04********************************************************");
					client_print_color(id, 0, "^x04[AuthSystems]^x01 Под данный ^x04SteamID ^x01уже зарегистрирован аккаунт");
					client_print_color(id, 0, "^x04[AuthSystems]^x01 Аккаунт: ^x04%s^x01 , для восстоновление используете вашу почту", szTemp);
					client_print_color(id, 0, "^x04[AuthSystems]^x01 Случая неполадки с почтой, просим обратиться администраторам");
					client_print_color(id, 0, "^x04********************************************************");
					//formatex(g_sLogin[id], charsmax(g_sLogin), "");
					

					//new sData[EXT_DATA_STRUCT];
					//sData[EXT_DATA__SQL] = SQL_IGNORE;

					//SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", query);
					//SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
					return show_reg_menu(id);
				}
				#endif


				new query[QUERY_LENGTH], que_len;

				que_len += formatex(query[que_len],charsmax(query) - que_len, "SELECT * FROM %s WHERE `Login` = '%s'",g_szRankTable, login);


				new sData[EXT_DATA_STRUCT];
				sData[EXT_DATA__SQL] = SQL_LOAD;
				sData[EXT_DATA__INDEX] = id;
				sData[EXT_DATA__USERID] = get_user_userid(id);

				copy(sData[EXT_DATA__LOGIN], MAX_NAME_LENGTH - 1, login);
				copy(sData[EXT_DATA__EMAIL], MAX_NAME_LENGTH - 1, email);
				copy(sData[EXT_DATA__PASS], MAX_NAME_LENGTH - 1, pass);

				#if defined SQL_CHECKING_LOG
				server_print(" POST SQL_LOAD #1 | %s | %s | %s", login, pass, email);
				#endif

				SQL_ThreadQuery(g_hDBHandle, "selectQueryHandler", query, sData, sizeof sData);
			}
		}
		case SQL_UPDATE:
		{
			new players[MAX_PLAYERS],pnum;
			get_players(players,pnum);

			for(new i,player ; i < pnum ; i++)
			{
				player = players[i];

				if(strlen(g_sLogin[player]) > 0) 
				{
					//jbe_mysql_quest_save(g_sLogin[id], id);
					jbe_mysql_stats_save(g_sLogin[player], player);
					
					new iRet;
					ExecuteForward(g_iFwdUserLogOut , iRet , player, g_sLogin[player]);
					
					new HanldeQuery[QUERY_LENGTH];
					formatex(HanldeQuery, charsmax(HanldeQuery), "UPDATE `%s` SET `OnlineStatus` = '0' WHERE `Login` = '%s'",g_szRankTable, g_sLogin[player]);
					SQL_ThreadQuery(g_hDBHandle, "IgnoreHandle", HanldeQuery);
					//prize_save(g_sLogin[id], id)

					formatex(g_sLogin[player], charsmax(g_sLogin), "");
					formatex(g_sPassword[player], charsmax(g_sPassword), "");
					
					
				}
			}
			#if defined SQL_CHECKING_LOG
			server_print("PLUGIN_END ")
			#endif
		}
		//case SQL_IGNORE: {}
	}

	return PLUGIN_HANDLED
}
#if defined SQL_TEST_PERFORMNACE
public test(iPlayer)
{
    g_count=0
    for(new i; i < 90; i++)
    {
		AutoLoadDB(iPlayer);
    }
    
}


public test2()
{
    static active
    active = !active
    
    if(active)
    {
        server_print("mysql_config_thread speed")
        //mysql_performance(50, 50, 6)
    }
    else {
        server_print("mysql_config_thread default")
       // mysql_performance(100, 100, 1)
    }
}

#endif





stock re_mysql_escape_string(output[], len)
{
	//while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	while(replace(output, len, "\", "")) {}
	while(replace(output, len, "'", "")) {}
	while(replace(output, len, "^"", "")) {}
}
