#include <amxmodx>
#include <amxmisc>
#include <jbe_core>
#include <fakemeta>
#include <reapi>


#define ID_IDLE_SOUNDS (id - TASK_SET_FLAGS)
#define TASK_SET_FLAGS 	5467457568

new g_iGlobalDebug;
#include <util_saytext>

#pragma semicolon 1

#define VERSION "1.0"
#define PREFIX "!t[!gVIP!t] "
#define TIME_FORMAT "%d.%m.%Y %H:%M:%S"

new cvar_amx_password_field;

enum _:database_items
{
    auth[50],
    password[34],
    flags[10],
    endTimeStamp[32],
    forumId[32],
	accessflags[10]
};
new vips_database[database_items];
new Array:database_holder;
new fwdUpdateVip;


public plugin_init() {
    register_plugin("VIP", VERSION, "BaHeK");
    
    register_concmd("amx_reloadvips", "reload_vips_cmd", ADMIN_RCON);
    reload_vips();
	
    fwdUpdateVip = CreateMultiForward("frallion_access_user", ET_IGNORE, FP_CELL, FP_STRING);
    

    cvar_amx_password_field = get_cvar_pointer("amx_password_field");
    if(!cvar_amx_password_field) {
        cvar_amx_password_field = register_cvar("amx_password_field", "_pw");
    }
    
    register_srvcmd("test", "testCmd");
    g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public reload_vips_cmd(id, level, cid)
{
    if(!cmd_access(id, level, cid, 1)) {
        return PLUGIN_HANDLED;
    }
    reload_vips();

    return PLUGIN_HANDLED;
}

public testCmd()
{
    new args[32];
    read_args(args, charsmax(args));
    remove_quotes(args);
    trim(args);
    log_amx("%s = %d", args, read_flags(args));

    return PLUGIN_HANDLED;
}


public vip_menu(id)
{
    
    return PLUGIN_HANDLED;
}
 
public vip_menu_handler(id, key)
{

    return PLUGIN_HANDLED;
}




public client_putinserver(id)
{
    set_task(1.0, "ex_set_flags", id + TASK_SET_FLAGS);
}

public client_disconnected(id)
{
    if(task_exists(id + TASK_SET_FLAGS)) remove_task(id + TASK_SET_FLAGS);
}

public plugin_end()
{
    if(database_holder) {
        ArrayDestroy(database_holder);
    }
}

public reload_vips() {
    
	if(database_holder) 
	{
		ArrayClear(database_holder);
	} else 
	{
		database_holder = ArrayCreate(database_items);
	}
	new configsDir[64];
	get_configsdir(configsDir, charsmax(configsDir));
	add(configsDir, charsmax(configsDir), "/vips.ini");
	
	new File = fopen(configsDir, "r");
	if (File) {
	new Text[512], Time[32], AuthData[50], Flags[10], Password[34], sProfileId[10],szAccesFlags[10], timestamp, num = 0;
	new sysTime = get_systime();
	
	while (!feof(File)) 
	{
		num++;
		fgets(File, Text, charsmax(Text));
		trim(Text);
		if (!Text[0] || Text[0] == ';' || Text[0] == '#' || contain(Text, "//") == 0) 
		{
			continue;
		}
	
	
		// not enough parameters
		parse(Text, AuthData, charsmax(AuthData), Password, charsmax(Password), Flags, charsmax(Flags), Time, charsmax(Time), sProfileId, charsmax(sProfileId), szAccesFlags, charsmax(szAccesFlags));
		
		timestamp = parseTime(Time);
		
		if(str_to_num(sProfileId) < 1) {
			log_amx("Неверно указан ID пользователя, строка № %d|%d", num, str_to_num(sProfileId));
			continue;
		}
		
		if(timestamp != 0 && timestamp < sysTime) {
			log_amx("Истекла VIP: %s до %s forumId: %d", AuthData, Time, str_to_num(sProfileId));
			continue;
		}
		
		vips_database[auth] = AuthData;
		vips_database[password] = Password;
		vips_database[endTimeStamp] = timestamp;
		vips_database[forumId] = str_to_num(sProfileId);
		copy(vips_database[accessflags], charsmax(vips_database[accessflags]), szAccesFlags);
		ArrayPushArray(database_holder, vips_database);
	}
	
	fclose(File);
	
	log_amx("Загружено %d VIP'ов из файла", ArraySize(database_holder));
	}
	else 
	{
		log_amx("Error: vips.ini file doesn't exist");
	}
	
	new players[32], pnum;
	get_players(players, pnum, "ch");
	for(new i = 0; i < pnum; i++) {
	set_flags(players[i]);
	}
}

public parseTime(sTime[])
{
    if(equal(sTime, "0")) {
        return 0;
    }
    return parse_time(sTime, TIME_FORMAT);
}

public timestampToTime(timestamp, string[], len)
{
    if(timestamp) {
        format_time(string, len, TIME_FORMAT, timestamp);
    } else {
        formatex(string, len, "навсегда");
    }
}
public ex_set_flags(id) {
	id -= TASK_SET_FLAGS;
	set_flags(id);
}
public set_flags(id) {
    if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) {
        return;
    }
	new bool:g_user_privileges;
    if(task_exists(id + TASK_SET_FLAGS)) remove_task(id + TASK_SET_FLAGS);
    new authid[31], ip[31], name[51], index, client_password[64], size, amx_password_field_string[32], client_md5[34];
    get_pcvar_string(cvar_amx_password_field, amx_password_field_string, charsmax(amx_password_field_string));
    get_user_authid(id, authid, charsmax(authid));
    get_user_ip(id, ip, charsmax(ip), 1);
    get_user_name(id, name, charsmax(name));
    get_user_info(id, amx_password_field_string, client_password, charsmax(client_password));
    //md5(client_password, client_md5);
    new fwdResult;
    hash_string(client_password, Hash_Md5, client_md5, charsmax(client_md5));
    
    g_user_privileges = false;
    size = ArraySize(database_holder);
    for(index=0; index < size ; index++) {
        ArrayGetArray(database_holder, index, vips_database);
        if(equal(vips_database[flags], "ip")) {
            if(equal(ip, vips_database[auth])) 
	    {
                g_user_privileges = true;
		ExecuteForward(fwdUpdateVip, fwdResult, id,  vips_database[accessflags]);
                break;
            }
        }
        else if(equal(vips_database[flags], "steam")) {
            if(equal(authid, vips_database[auth])) {
                if(equal(client_md5, vips_database[password])) {
                    g_user_privileges = true;
		    ExecuteForward(fwdUpdateVip, fwdResult, id,  vips_database[accessflags]);
                }
                else {
                    log_amx("Неверный пароль, %s = %s, pwd: %s; md5: %s", vips_database[flags], vips_database[auth], client_password, client_md5);
                    server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "INV_PAS");
                }
                break;
            }
        }
        else {
            formatex(vips_database[flags], charsmax(vips_database[flags]), "name");
            if(equali(name, vips_database[auth])) {
                if(equal(client_md5, vips_database[password])) {
                    g_user_privileges = true;
		    ExecuteForward(fwdUpdateVip, fwdResult, id,  vips_database[accessflags]);
                }
                else {
                    log_amx("Неверный пароль, %s = %s, pwd: %s; md5: %s", vips_database[flags], vips_database[auth], client_password, client_md5);
                    server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "INV_PAS");
                }
                break;
            }
        }
    }
    
    if(g_user_privileges) {
        new Time[32];
        timestampToTime(vips_database[endTimeStamp], Time, charsmax(Time));
        log_amx("User %d #%d: <%s><%s><%s> forumId: %d; end time: %s auth by %s", id, get_user_userid(id), name, authid, ip, vips_database[forumId], Time, vips_database[flags]);
    }
}
