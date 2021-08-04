#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>


#define CHATMANAGER
#define PLUGIN "Web Chat"
#define VERSION "1.3.11"
#define AUTHOR "BaHeK"

#pragma semicolon 1

new Handle:g_h_Sql;
new g_pCvarSQLHost, g_pCvarSQLUser, g_pCvarSQLPass, g_pCvarSQLDb, g_pCvar_ipfix, g_pCvar_sim, g_pCvar_reconnectmysql, g_pCvar_reconnecttime;
new g_pCvar_sendrcon, g_pCvar_colorchat_punish, g_pCvar_colorchat_exec;

new bool:is_connected_mysql, host[64], user[64], pass[64], db[64], _hostip[32], zapr[1024];


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_pCvarSQLHost = register_cvar("amx_webchat_host", "localhost");
	g_pCvarSQLUser = register_cvar("amx_webchat_user", "root");
	g_pCvarSQLPass = register_cvar("amx_webchat_pass", "");
	g_pCvarSQLDb = register_cvar("amx_webchat_db", "");
	g_pCvar_ipfix = register_cvar("amx_webchat_ipfix", "");
	g_pCvar_sim = register_cvar("amx_webchat_ignore_sim", "0");
	g_pCvar_reconnectmysql = register_cvar("amx_webchat_reconnectmysql", "1");
	g_pCvar_reconnecttime = register_cvar("amx_webchat_reconnecttime", "20");
	g_pCvar_sendrcon = register_cvar("amx_webchat_sendrcon", "0");
	g_pCvar_colorchat_punish = register_cvar("amx_webchat_cc_punish", "2");
	g_pCvar_colorchat_exec = register_cvar("amx_webchat_cc_exec", "addip 60 %ip%");
	register_srvcmd("webchat", "message_from_webchat");

	set_task(0.3, "connect_data_base");
}

forward cm_player_send_message(id, msg[192], isteam);
public cm_player_send_message(id, msg[192], isteam)
{
	to_log(id, isteam, msg);
}
public to_log(id, teamchat, mes[192])
{
	if(!is_user_connected(id)||is_user_bot(id)||is_user_hltv(id)) return PLUGIN_HANDLED;
	new name[33], steam[33], ip[33], hostip[32], team, alive, msg[400], _hostip1[64], _name[66], message[192], quote_name[35], quote_steam[35];
	get_user_name(id, name, charsmax(name));
	get_user_ip(id, ip, charsmax(ip), 1);
	get_user_authid(id, steam, charsmax(steam));
	replace_all(name, charsmax(name), "^"", "");
	replace_all(steam, charsmax(steam), "^"", "");
	get_pcvar_string(g_pCvar_ipfix, _hostip, charsmax(_hostip));
	message = mes;	remove_quotes(message);
	trim(message);
	replace_all(message, charsmax(message), "%", "");
	replace_all(message, charsmax(message), "#", "");
	replace_all(name, charsmax(name), "#", "");
	if(!strlen(name))
	{
		server_cmd("kick #%d", get_user_userid(id));
		return PLUGIN_HANDLED;
	}
	if(!message[0]) return PLUGIN_HANDLED;
	if(contain(message, "")!=-1||contain(message, "")!=-1||contain(name, "")!=-1||contain(name, "")!=-1)
	{
		if(get_pcvar_num(g_pCvar_colorchat_punish)==1)
		{
			server_cmd("kick #%d ^"Баг с цветным чатом^"", get_user_userid(id));
			return PLUGIN_HANDLED_MAIN;
		}
		else if(get_pcvar_num(g_pCvar_colorchat_punish)==2)
		{
			new userid[8], cc_exec[128];
			formatex(userid, charsmax(userid), "#%d", get_user_userid(id));
			get_pcvar_string(g_pCvar_colorchat_exec, cc_exec, charsmax(cc_exec));
			replace_all(cc_exec, charsmax(cc_exec), "%ip%", ip);
			formatex(quote_name, charsmax(quote_name), "^"%s^"", name);
			replace_all(cc_exec, charsmax(cc_exec), "^"%name%^"", quote_name);
			replace_all(cc_exec, charsmax(cc_exec), "%name%", quote_name);
			formatex(quote_steam, charsmax(quote_steam), "^"%s^"", steam);
			replace_all(cc_exec, charsmax(cc_exec), "^"%authid%^"", quote_steam);
			replace_all(cc_exec, charsmax(cc_exec), "%authid%", quote_steam);
			replace_all(cc_exec, charsmax(cc_exec), "#%userid%", userid);
			replace_all(cc_exec, charsmax(cc_exec), "%userid%", userid);
			server_cmd("%s", cc_exec);
			return PLUGIN_HANDLED_MAIN;
		}
		replace_all(message, charsmax(message), "", "");
		replace_all(message, charsmax(message), "", "");
		replace_all(name, charsmax(name), "", "");
		replace_all(name, charsmax(name), "", "");
	}
	if(message[0]=='@'&&teamchat==1) return PLUGIN_HANDLED_MAIN;
	if(get_pcvar_num(g_pCvar_sim)&&message[0]=='/') return PLUGIN_HANDLED_MAIN;
	if(is_connected_mysql)
	{
		if(equali(_hostip, ""))
			get_user_ip(0, hostip, charsmax(hostip));
		else
			formatex(hostip, charsmax(hostip), "%s", _hostip);
		mysql_escape_string(msg, charsmax(msg), message);
		mysql_escape_string(_hostip1, charsmax(_hostip1), hostip);
		mysql_escape_string(_name, charsmax(_name), name);
		if(is_user_alive(id))
			alive = 1;
		else
			alive = 0;
		
		if(cs_get_user_team(id) == CS_TEAM_T)
			team = 1;
		else if(cs_get_user_team(id) == CS_TEAM_CT)
			team = 2;
		else
			team = 0;

		formatex(zapr, charsmax(zapr), "SET NAMES `utf8`;INSERT INTO `webchat` (`id`, `name`, `ip`, `steam`, `text`, `hostip`, `time`, `team`, `alive`, `teamchat`) VALUES (NULL, '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(NOW()), '%d', '%d', '%d')", _name, ip, steam, msg, hostip, team, alive, teamchat);
		new data[2];
		data[0] = 0;
		SQL_ThreadQuery(g_h_Sql, "say_sql", zapr, data, charsmax(data));
	}
	

	log_message("^"%s<%d><%s><%s>^" say%s ^"%s^"%s", name, get_user_userid(id), steam, team==1 ? "TERRORIST" : team==2 ? "CT" : "SPECTATOR", teamchat ? "_team" : "", message, !alive ? " (dead)" : "");


	return PLUGIN_CONTINUE;
}

public say_sql(iFailState, Handle:hQuery, error[], err, data[], size)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		new qstring[1024];
		SQL_GetQueryString(hQuery, qstring, charsmax(qstring));
		log_amx("sql query: %s", qstring);
		log_amx("sql error: %d (%s)", err, error);
		if(iFailState == TQUERY_CONNECT_FAILED)
		{
			if(get_pcvar_num(g_pCvar_reconnectmysql))
			{
				is_connected_mysql=false;
				new Float:reconnecttime = get_pcvar_float(g_pCvar_reconnecttime);
				if(reconnecttime<5.0) reconnecttime = 5.0;
				else if(reconnecttime>60.0) reconnecttime = 60.0;
				set_task(reconnecttime, "reconnect_to_mysql");
				log_amx("Reconnect to database...");
			}
			else
				pause("d");
		}
		return;
	}
	else
	{
		if(data[0]==1)
		{
			is_connected_mysql = true;
			new ndata[2];
			ndata[0] = 2;
			formatex(zapr, charsmax(zapr), "CREATE TABLE IF NOT EXISTS `host` ( `hostname` varchar(255) NOT NULL, `hostip` varchar(255) NOT NULL, `rcon` varchar(32) NOT NULL, PRIMARY KEY (`hostip`) ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");
			SQL_ThreadQuery(g_h_Sql, "say_sql", zapr, ndata, charsmax(ndata));
		}
		if(data[0]==2)
		{
			new _hostname[256], hostip[32], _hostip1[64], _hostname1[512], rcon[33], mysql_rcon[66];
			if(get_pcvar_num(g_pCvar_sendrcon))
				get_cvar_string("rcon_password", rcon, charsmax(rcon));
			get_pcvar_string(g_pCvar_ipfix, _hostip, charsmax(_hostip));
			get_cvar_string("hostname", _hostname, charsmax(_hostname));
			if(equali(_hostip, ""))
				get_user_ip(0, hostip, charsmax(hostip));
			else
				formatex(hostip, charsmax(hostip), "%s", _hostip);
				
			mysql_escape_string(_hostname1, charsmax(_hostname1), _hostname);
			mysql_escape_string(_hostip1, charsmax(_hostip1), hostip);
			if(get_pcvar_num(g_pCvar_sendrcon))
			{
				mysql_escape_string(mysql_rcon, charsmax(mysql_rcon), rcon);
				format(mysql_rcon, charsmax(mysql_rcon), ", rcon='%s'", mysql_rcon);
			}
			formatex(zapr, charsmax(zapr), "SET NAMES `utf8`;INSERT INTO `host` SET hostname='%s', hostip='%s'%s ON DUPLICATE KEY UPDATE hostname='%s'%s", _hostname1, _hostip1, mysql_rcon, _hostname1, mysql_rcon);
			new ndata[2];
			ndata[0] = 0;
			SQL_ThreadQuery(g_h_Sql, "say_sql", zapr, ndata, charsmax(ndata));
		}
	}
}

public plugin_cfg()
{
	new iCfgDir[32], iFile[192];
	
	get_configsdir(iCfgDir, charsmax(iCfgDir));
	formatex(iFile, charsmax(iFile), "%s/webchat.cfg", iCfgDir);

	if(!file_exists(iFile))
	{
		log_amx("Ошибка чтения файла webchat.cfg");
		pause("d");
	}
	else
		server_cmd("exec %s", iFile);
}

public reconnect_to_mysql()
{
	is_connected_mysql = false;
	connect_data_base();
}

public connect_data_base()
{	
	get_pcvar_string(g_pCvarSQLHost, host, charsmax(host));
	get_pcvar_string(g_pCvarSQLUser, user, charsmax(user));
	get_pcvar_string(g_pCvarSQLPass, pass, charsmax(pass));
	get_pcvar_string(g_pCvarSQLDb, db, charsmax(db));
	
	g_h_Sql = SQL_MakeDbTuple(host, user, pass, db);
		
	new data[2];
	formatex(zapr, charsmax(zapr), "CREATE TABLE IF NOT EXISTS `webchat` ( `id` int(8) NOT NULL AUTO_INCREMENT, `name` varchar(32) NOT NULL, `ip` varchar(32) NOT NULL, `steam` varchar(32) NOT NULL, `text` varchar(400) NOT NULL, `hostip` varchar(32) NOT NULL, `time` int(32) NOT NULL, `team` int(8) NOT NULL, `alive` int(8) NOT NULL, `teamchat` int(8) NOT NULL, PRIMARY KEY (`id`) ) ENGINE=MyISAM  DEFAULT CHARSET=utf8;");
	data[0] = 1;
	SQL_ThreadQuery(g_h_Sql, "say_sql", zapr, data, charsmax(data));
}

public plugin_end()
{
	is_connected_mysql = false;
}

public message_from_webchat()
{
	new arg[256];
	read_args(arg, charsmax(arg));
	replace_all(arg, charsmax(arg), "%", "");
	
	new name[32], message[192], mes[192];
	argbreak(arg, name, charsmax(name), message, charsmax(message));
	remove_quotes(name);
	remove_quotes(message);
	trim(name);
	trim(message);
	replace_all(message, charsmax(message), "", "");
	replace_all(message, charsmax(message), "", "");
	replace_all(name, charsmax(name), "", "");
	replace_all(name, charsmax(name), "", "");
	replace_all(message, charsmax(message), "%", "");
	replace_all(message, charsmax(message), "#", "");
	replace_all(name, charsmax(name), "%", "");
	replace_all(name, charsmax(name), "#", "");
	
	if(!name[0]||!message[0])
		return PLUGIN_HANDLED;
	
	format(mes, charsmax(mes), "^x04[WebChat] ^x03%s ^x04:  %s", name, message);
	client_print(0, print_notify, "[WebChat] %s :  %s", name, message);
	message_begin(MSG_ALL, 86);
	write_byte(33);
	write_string("SPECTATOR");
	message_end();
	message_begin(MSG_ALL, 76);
	write_byte(33);
	write_string(mes);
	message_end();
	
	return PLUGIN_HANDLED;
}

stock mysql_escape_string(dest[], len, src[])
{
	copy(dest, len, src);
	replace_all(dest, len, "\", "\\");
	replace_all(dest, len, "\0", "\\0");
	replace_all(dest, len, "\r", "\\r");
	replace_all(dest, len, "\n", "\\n");
	replace_all(dest, len, "\x1a", "\Z");
	replace_all(dest, len, "'", "\'");
	replace_all(dest, len, "^"", "\^"");

	return 1;
}