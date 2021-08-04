//Based on plugin: https://dev-cs.ru/resources/984/ by GM-X Team

#include <amxmodx>
#include <sqlx>
#include <json>

public stock const PluginName[] = "Player preferences";
public stock const PluginVersion[] = "1.0.5";
public stock const PluginAuthor[] = "GM-X Team, cpctrl";
public stock const PluginURL[] = "https://goldsrc.ru/members/3085/";
const QUERY_LENGTH =	2048	// размер переменной sql запроса
#define CHECK_NATIVE_ARGS_NUM(%1,%2,%3) \
    if (%1 < %2) { \
    	log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
    	return %3; \
    }

#define CHECK_NATIVE_PLAYER(%1,%2) \
    if (!g_bConnected[%1]) { \
        log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
        return %2; \
    }

const MAX_KEY_LENGTH = 32;
const MAX_VALUE_STRING_LENGTH = 32;

enum sqlx_e {
    table[32],
    host[32],
    user[64],
    pass[64],
    db[32]
};

enum    {
    Load_Player
};

enum fwdStruct  {
    Fwd_Loaded,
    Fwd_KeyChanged
};

new g_eForwards[fwdStruct], fwReturn;

new Handle: g_hTuple;
new dbdata[sqlx_e];

new bool: g_bConnected[MAX_PLAYERS + 1];
new bool: g_bLoaded[MAX_PLAYERS + 1];
new Trie: g_tPlayerPreferences[MAX_PLAYERS + 1];
new JSON: g_jObject[MAX_PLAYERS + 1];

public plugin_init()    {
    g_eForwards[Fwd_Loaded] = CreateMultiForward("player_loaded", ET_IGNORE, FP_CELL);
    g_eForwards[Fwd_KeyChanged] = CreateMultiForward("player_key_changed", ET_IGNORE, FP_CELL, FP_STRING);

    read_json();
}

public read_json()   {
    new filePath[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", filePath, PLATFORM_MAX_PATH - 1);

    add(filePath, PLATFORM_MAX_PATH - 1, "/preferences.json");

    if (!file_exists(filePath)) {
        set_fail_state("Configuration file '%s' not found", filePath);
        return;
    }

    new JSON: config = json_parse(filePath, true);

    if (config == Invalid_JSON)    {
        set_fail_state("Configuration file '%s' read error", filePath);
        return;
    }

    new temp[64];

    json_object_get_string(config, "sql_table", temp, charsmax(temp));
    copy(dbdata[table], charsmax(dbdata[table]), temp);

    json_object_get_string(config, "sql_host", temp, charsmax(temp));
    copy(dbdata[host], charsmax(dbdata[host]), temp);

    json_object_get_string(config, "sql_user", temp, charsmax(temp));
    copy(dbdata[user], charsmax(dbdata[user]), temp);

    json_object_get_string(config, "sql_password", temp, charsmax(temp));
    copy(dbdata[pass], charsmax(dbdata[pass]), temp);

    json_object_get_string(config, "sql_db", temp, charsmax(temp));
    copy(dbdata[db], charsmax(dbdata[db]), temp);

    json_free(config);

    server_print("Preferences config has been loaded");

    sql_test_init();
}

new g_iConnections;

public sql_test_init() {
    if (++g_iConnections >= 2)   {
        if (task_exists(312))    {
            remove_task(312);
        }
    }

    new Handle: sConnection;

    g_hTuple = SQL_MakeDbTuple(
        dbdata[host],
        dbdata[user],
        dbdata[pass],
        dbdata[db]
    );

    new errCode, error[512];
    sConnection = SQL_Connect(g_hTuple, errCode, error, charsmax(error));

    if (sConnection == Empty_Handle)    {
        SQL_FreeHandle(g_hTuple);

        if (g_iConnections < 2)   {
            log_amx("[PP] Connection [%d/2] test error #%d: %s",
                g_iConnections, errCode, error
            );
            log_amx("[PP] Reconnect to db in 15 sec.");
            set_task(15.0, "sql_test_init", 312);
        }
        else    {
            log_amx("[PP] Error connecting to db '%s': #%d: %s", dbdata[db], errCode, error);
            g_iConnections = -1;
        }
        return;
    }

    if (task_exists(312)) {
        remove_task(312);
    }

    server_print("[PP] Connection [%d/2] to '%s' database success", g_iConnections, dbdata[db]);

    SQL_FreeHandle(sConnection);
}

public plugin_natives() {
    register_native("pp_has_key", "native_has_key");

    register_native("pp_get_number", "native_get_number");
    register_native("pp_get_float", "native_get_float");
    register_native("pp_get_bool", "native_get_bool");
    register_native("pp_get_string", "native_get_string");

    register_native("pp_set_number", "native_set_number");
    register_native("pp_set_float", "native_set_float");
    register_native("pp_set_bool", "native_set_bool");
    register_native("pp_set_string", "native_set_string");
}

public bool: native_has_key(plugin, argc) {
    enum    {
        arg_player = 1,
        arg_key
    };

    CHECK_NATIVE_ARGS_NUM(argc, 2, false)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, false)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, MAX_KEY_LENGTH - 1);

    return TrieKeyExists(g_tPlayerPreferences[id], key);
}

public native_get_number(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_default
    };

    CHECK_NATIVE_ARGS_NUM(argc, 2, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, MAX_KEY_LENGTH - 1);

    if (!TrieKeyExists(g_tPlayerPreferences[id], key))  {
        return argc >= arg_default ? get_param(arg_default) : 0;
    }

    new value;
    TrieGetCell(g_tPlayerPreferences[id], key, value);

    return value;
}

public Float: native_get_float(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_default
    };

    CHECK_NATIVE_ARGS_NUM(argc, 2, 0.0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0.0)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, MAX_KEY_LENGTH - 1);

    if (!TrieKeyExists(g_tPlayerPreferences[id], key))  {
        return argc >= arg_default ? get_param_f(arg_default) : 0.0;
    }

    new value;
    TrieGetCell(g_tPlayerPreferences[id], key, value);

    return float(value);
}

public bool: native_get_bool(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_default
    };

    CHECK_NATIVE_ARGS_NUM(argc, 2, false)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, false)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, MAX_KEY_LENGTH - 1);

    if (!TrieKeyExists(g_tPlayerPreferences[id], key))  {
        return bool: (argc >= arg_default ? get_param(arg_default) : 0);
    }

    new value;
    TrieGetCell(g_tPlayerPreferences[id], key, value);

    return bool: value;
}

public native_get_string(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_dest,
        arg_length,
        arg_default
    };

    CHECK_NATIVE_ARGS_NUM(argc, 2, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH], value[MAX_VALUE_STRING_LENGTH];

    get_string(arg_key, key, MAX_KEY_LENGTH - 1);

    if (TrieKeyExists(g_tPlayerPreferences[id], key))  {
        TrieGetString(g_tPlayerPreferences[id], key, value, MAX_VALUE_STRING_LENGTH - 1);
    }
    else if (argc >= arg_default)  {
        get_string(arg_default, value, MAX_VALUE_STRING_LENGTH - 1);
    }

    return set_string(arg_dest, value, get_param(arg_length));
}

public native_set_number(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_value
    };

    CHECK_NATIVE_ARGS_NUM(argc, 3, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, charsmax(key));

    new value = get_param(arg_value);
    TrieSetCell(g_tPlayerPreferences[id], key, value);

    return setValue(id, key, json_init_number(value));
}

public native_set_bool(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_value
    };

    CHECK_NATIVE_ARGS_NUM(argc, 3, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, charsmax(key));

    new bool: value = bool: get_param(arg_value);
    TrieSetCell(g_tPlayerPreferences[id], key, value ? 1 : 0);

    return setValue(id, key, json_init_bool(value));
}

public native_set_float(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_value
    };

    CHECK_NATIVE_ARGS_NUM(argc, 3, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH];
    get_string(arg_key, key, charsmax(key));

    new Float: value = get_param_f(arg_value);
    TrieSetCell(g_tPlayerPreferences[id], key, value);

    return setValue(id, key, json_init_number(cell: value));
}

public native_set_string(plugin, argc)  {
    enum    {
        arg_player = 1,
        arg_key,
        arg_value
    };

    CHECK_NATIVE_ARGS_NUM(argc, 3, 0)

    new id = get_param(arg_player);
    CHECK_NATIVE_PLAYER(id, 0)

    new key[MAX_KEY_LENGTH], value[MAX_VALUE_STRING_LENGTH];
    get_string(arg_key, key, charsmax(key));
    get_string(arg_value, key, charsmax(key));

    TrieSetString(g_tPlayerPreferences[id], key, value);

    return setValue(id, key, json_init_string(value));
}

stock setValue(const id, const key[], JSON: value)    {
    ExecuteForward(g_eForwards[Fwd_KeyChanged], fwReturn, id, key);

    if (fwReturn == PLUGIN_HANDLED) {
        return -1;
    }

    json_object_set_value(g_jObject[id], key, value);

    json_free(value);

    return 1;
}

public client_putinserver(id)   {
    load_player(id);
}

public client_disconnected(id)  {
    if (g_bConnected[id] && g_tPlayerPreferences[id] != Invalid_Trie)   {
        save_values(id);
    }
}

save_values(const id)  {
    if (json_serial_size(g_jObject[id]) < 2)  {
        json_free(g_jObject[id]);
        return;
    }

    new buffer[QUERY_LENGTH], len;
    new auth[MAX_AUTHID_LENGTH];
    get_user_authid(id, auth, charsmax(auth));

    if (g_bLoaded[id])  {
        len = formatex(buffer, charsmax(buffer), "UPDATE `%s` SET `data` = '", dbdata[table]);
    }
    else    {
        len = formatex(buffer, charsmax(buffer), "INSERT INTO `%s` (`auth`, `data`) VALUES ('%s', '", dbdata[table], auth);
    }

    len += json_serial_to_string(g_jObject[id], buffer[len], charsmax(buffer) - len);

    if (g_bLoaded[id])  {
        formatex(buffer[len], charsmax(buffer) - len, "' WHERE `auth` = '%s';", auth);
    }
    else    {
        formatex(buffer[len], charsmax(buffer) - len, "');");
    }

    SQL_ThreadQuery(g_hTuple, "ThreadHandler", buffer);
	server_print("%d", charsmax(buffer));
	log_to_file("sadas.log", "%s", buffer);
    g_bConnected[id] = false;
    g_bLoaded[id] = false;
    json_free(g_jObject[id]);
    TrieDestroy(g_tPlayerPreferences[id]);
}

load_player(id)  {
    if (is_user_hltv(id) || is_user_bot(id))    {
        return;
    }

    g_bConnected[id] = true;
    g_tPlayerPreferences[id] = TrieCreate();
    g_jObject[id] = json_init_object();

    if (g_hTuple == Empty_Handle)   {
        return;
    }

    new buffer[128], szAuth[MAX_AUTHID_LENGTH];
    get_user_authid(id, szAuth, MAX_AUTHID_LENGTH - 1);
    formatex(buffer, charsmax(buffer), "SELECT `data` FROM `%s` WHERE `auth` = '%s'", dbdata[table], szAuth);

    new data[2];
    data[0] = id;
    data[1] = Load_Player;
    SQL_ThreadQuery(g_hTuple, "ThreadHandler", buffer, data, sizeof data);
}

public ThreadHandler(failstate, Handle: query, err[], errNum, data[], size, Float: queuetime)   {
    switch(failstate)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:  // ошибка соединения с mysql сервером
		{
			new szText[128];
			
			formatex(szText, charsmax(szText), "[Проблемы с БД. Код ошибки: #%d]", errNum);
			if(size) log_to_file("mysqlt.log", "Query state: %d", data[0]);
			log_to_file("mysqlt.log","%s", szText)
			log_to_file("mysqlt.log","%s",err)
			new lastQue[128];
			SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
			log_to_file("mysqlt.log","%s", lastQue)
			return PLUGIN_CONTINUE;
		}
	}

    switch (data[1])    {
        case Load_Player:   {
            new id = data[0];

            if (!g_bConnected[id])  {
                return PLUGIN_HANDLED;
            }

            if (SQL_NumResults(query))  {
                new preferences[QUERY_LENGTH];
                SQL_ReadResult(query, SQL_FieldNameToNum(query, "data"), preferences, charsmax(preferences));

                new JSON: jsonValue = json_parse(preferences);

                if (jsonValue == Invalid_JSON)   {
                    json_free(jsonValue);
                    log_error(AMX_ERR_NATIVE, "[PP] Bad format string");
                }

                new bool: bSomeBoolean, iSomeNumber;
                for (new i = 0, n = json_object_get_count(jsonValue), JSON: element, key[MAX_KEY_LENGTH], value[MAX_VALUE_STRING_LENGTH]; i < n; i++)  {
		            json_object_get_name(jsonValue, i, key, charsmax(key));
		            element = json_object_get_value_at(jsonValue, i);

                    switch  (json_get_type(element)) {
                        case JSONString:    {
                            json_get_string(element, value, MAX_VALUE_STRING_LENGTH - 1);
                            TrieSetString(g_tPlayerPreferences[id], key, value);

                            json_object_set_string(g_jObject[id], key, value);
                        }
                        case JSONNumber:    {
                            iSomeNumber = json_get_number(element);
                            TrieSetCell(g_tPlayerPreferences[id], key, iSomeNumber);
                            json_object_set_number(g_jObject[id], key, iSomeNumber);
                        }
                        case JSONBoolean:   {
                            bSomeBoolean = json_get_bool(element);
                            TrieSetCell(g_tPlayerPreferences[id], key, bSomeBoolean ? 1 : 0);
                            json_object_set_bool(g_jObject[id], key, bSomeBoolean);
                        }
                    }
                    json_free(element);
                }
                json_free(jsonValue);

                g_bLoaded[id] = true;
            }
            ExecuteForward(g_eForwards[Fwd_Loaded], fwReturn, id);
        }
    }

    return PLUGIN_HANDLED;
}

public plugin_end() {
    if (g_hTuple != Empty_Handle) {
        SQL_FreeHandle(g_hTuple);
    }
}