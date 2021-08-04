#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <sqlx>
#include <gamecms5>
#include <hamsandwich>

#if AMXX_VERSION_NUM < 183
new MaxClients
#endif

new const PLUGIN[] = "GameCMS_Digital_Store";
new const VERSION[] = "1.0.0";
new const AUTHOR[] = "DalgaPups";

new const PREFIX[] = "ПромоКод"

//#define DEBUG

#define MsgId_SayText 76

new g_iUserPromoKod[MAX_PLAYERS + 1][MAX_NAME_LENGTH];

const QUERY_LENGTH =	512	// размер переменной sql запроса

#define PROMO_TABLE	 	"digital_store__action"

new Handle:g_hSqlHandle;

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

new g_iFwdLoagPromo;
enum _:sql_que_type	// тип sql запроса
{
	SQL_PRELOAD,
	SQL_LOADPROMO
}


enum _:EXT_DATA_STRUCT {
	EXT_DATA__SQL,
	EXT_DATA__INDEX,
	EXT_DATA__PRODUCT_ID
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("promokod" , "clcmd_promokod");
	register_clcmd("say /promo", "clcmd_promomenu");
	
	
	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	
	RegisterMenu("Show_MainMenu",  				"Handle_MainMenu");
	
	#undef RegisterMenu
	
	
	g_iFwdLoagPromo = CreateMultiForward("gamecms_promo_load", ET_CONTINUE, FP_CELL, FP_STRING, FP_CELL);
	
	RegisterHam(Ham_Spawn, 			"Ham_PlayerSpawn_Post", true)
	
#if AMXX_VERSION_NUM < 183
	MaxClients = get_maxplayers();
#endif
}

public gamecms_promo_load(pId, PromoString[], Product_Key)
{
	switch(Product_Key)
	{
		case 1:
		{
			//в Нашем случая прописываем услугу по нику
			new szName[32]; get_user_name(pId, szName, charsmax(szName));
			//Генерируем пароль в диапазоне от 100000 до 600000
			new Password[32]
			formatex(Password, charsmax(Password), "%d", random_num(100000, 600000));
			//copy(Password, 31, iNums);
			//Password = random_num(100000, 600000);
			
			//Выдаем услугу 43200 минут = 1 месяц
			/** 
			*	Добаление аккаунтов в базу данных
			*
			*	@iClient		Индекс игрока
			*	@szAuthType[]	Тип авторизации (смотри amxconst.inc: Admin authentication behavior flags)
			*	@szFlags[]		Флаги (уровни) доступа (смотри amxconst.inc: Admin level constants)
			*	@iTime			Время в минутах, 0- навсегда (если время не указано, значит 0)
			*	@szPasswd[]		Пароль доступа (если нужен)
			*	@iServiceId		Номер услуги на сайте (если известен)
			*	@check_params	Проверка введенных данных (true- включить). 
			*	
			*	@note			При отключеной функции check_params существует вероятность ошибок со стороны пользователя
			*
			*	@note			Пример:
			*					cmsapi_add_account(id, "a", "180", "parol", "prt", 0, false)
			*					игроку №id с его ником выданы флаги "prt" на 180 минут, пароль- "parol"
			*/
			server_print("%s", Password);
			cmsapi_add_account(pId, "a", 43200,  Password , "_access_skin",  0, false)

			
			//Уведомляем игроку что тот купил услугу, и выводим Ник и Пароль
			
			UTIL_SayText(pId, "!g[%s] !yУспешно активировал промокод %d", PREFIX, Product_Key);
			UTIL_SayText(pId, "!g[%s] !yВаш Ник к серверу: %s", PREFIX, szName);
			UTIL_SayText(pId, "!g[%s] !yВаш Пароль к серверу: %s", PREFIX, Password);
			UTIL_SayText(pId, "!g[%s] !yПароль можете сменить в личном кабинете на форуме", PREFIX);
		}
		case 2: return PLUGIN_HANDLED;
		case 3: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public Ham_PlayerSpawn_Post(pId)
{
	if(cmsapi_get_user_services(pId, "",  "_access_skin", 0))
    {
        cs_set_user_model(id, "vipmodel");

    }

}

public OnAPIPluginLoaded(Handle:sqlTuple) 
{
	g_hSqlHandle = sqlTuple;
	
	SQL_SetCharset(g_hSqlHandle, "utf8");
	
	new query[QUERY_LENGTH];
	
	formatex(query, charsmax(query) ,"\
		CREATE TABLE IF NOT EXISTS %s \
		( \
		    `id` int(11) NOT NULL AUTO_INCREMENT, \
		    `user_id` int(11) NOT NULL, \
			`product` VARCHAR(32) NOT NULL default '', \
			`product_id` int(11) NOT NULL, \
			PRIMARY KEY (`id`)\
		)\
		COLLATE='utf8_general_ci',\
		ENGINE=InnoDB;", PROMO_TABLE
	);
	
	SQL_ThreadQuery(g_hSqlHandle, "IgnoreHandle", query);
}

public plugin_end()
{
	DestroyForward(g_iFwdLoagPromo);
}

public client_disconnected(pId)
{
	if(strlen(g_iUserPromoKod[pId]) > 0) formatex(g_iUserPromoKod[pId], charsmax(g_iUserPromoKod[]), "")
}

public clcmd_promokod(id)
{
	read_argv(1, g_iUserPromoKod[id], charsmax(g_iUserPromoKod[]))
	
	if((strlen(g_iUserPromoKod[id]) < 1) || strlen(g_iUserPromoKod[id]) > 31)
	{
		formatex(g_iUserPromoKod[id], charsmax(g_iUserPromoKod[]), "")

		UTIL_SayText(id, "!g%s !yНекоректные данные, введите от 1 до 31 символов!", PREFIX);
		return Show_MainMenu(id);
	}
	return Show_MainMenu(id)
}

public clcmd_promomenu(pId) return Show_MainMenu(pId);

Show_MainMenu(pId)
{
	new szMenu[512], iKey = (1<<0|1<<9), iLen;
	
	FormatMain("\yПромо-код Онлайн^n^n");
	
	if(strlen(g_iUserPromoKod[pId]) > 0)
	{
		FormatItem("\y1. \wПромо-Код: \r%s^n", g_iUserPromoKod[pId]);
		iKey |= (1<<1);
	}
	else FormatItem("\y1. \wПромо-Код: \rвведите промокод^n");
	
	FormatItem("\y2. \wАктивировать^n");
	
	FormatItem("^n^n^n\y0. \wВыход");
	
	return show_menu(pId, iKey, szMenu, -1, "Show_MainMenu");
}


public Handle_MainMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			client_cmd(pId, "messagemode ^"promokod^"")  
			UTIL_SayText(pId, "!g[%s] !yВведите промокод который вы купили на форуме", PREFIX);
		}
		case 1:
		{
			if(cmsapi_is_user_member(pId))
			{
				HANDLE_user(pId);
			}
			else
			{
				UTIL_SayText(pId, "!g[%s] !yК сожелению вы не зарегитрированы на форуме или не указали STEAM ID", PREFIX);
				return PLUGIN_HANDLED;
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainMenu(pId);

}

HANDLE_user(pId)
{
	if(strlen(g_iUserPromoKod[pId]) < 1)
		return Show_MainMenu(pId);
			
	new queryData[QUERY_LENGTH];

	formatex(queryData, charsmax(queryData), "SELECT * FROM digital_store__keys WHERE `pay` != '0' AND `content` = '<p>%s</p>';",  g_iUserPromoKod[pId]);

	new sData[EXT_DATA_STRUCT];
	sData[EXT_DATA__SQL] = SQL_PRELOAD;
	sData[EXT_DATA__INDEX] = pId;

	#if defined DEBUG
	server_print("HANDLE_user | SQL_PRELOAD | %s", g_iUserPromoKod[pId]);
	#endif

	SQL_ThreadQuery(g_hSqlHandle, "selectQueryHandler", queryData, sData, sizeof(sData));
	
	return PLUGIN_HANDLED;
}

public selectQueryHandler(failstate, Handle:query, err[], errNum, data[], datalen, Float:queuetime) 
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
			
			
			if(failstate == TQUERY_QUERY_FAILED)
			{
				new lastQue[QUERY_LENGTH]

				SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
				log_to_file("mysqlt.log","[ SQL ] %s",lastQue)
			}
			return PLUGIN_CONTINUE;
		}
	}

	switch(data[EXT_DATA__SQL])
	{
		case SQL_PRELOAD:
		{
			new pId = data[EXT_DATA__INDEX];
			
			if(!is_user_connected(pId)) return PLUGIN_HANDLED;
			
			if(SQL_NumResults(query))
			{
				new product_id = SQL_ReadResult(query, SQL_FieldNameToNum(query,"product"));
				
				new queryData[QUERY_LENGTH];
			
				formatex(queryData, charsmax(queryData), "SELECT `product` FROM %s WHERE `product` = '<p>%s</p>'", PROMO_TABLE,  g_iUserPromoKod[pId]);
				
				new sData[EXT_DATA_STRUCT];
				sData[EXT_DATA__SQL] = SQL_LOADPROMO;
				sData[EXT_DATA__INDEX] = pId;
				sData[EXT_DATA__PRODUCT_ID] = product_id;
				
				#if defined DEBUG
				server_print("selectQueryHandler | SQL_LOADPROMO | %d | %s", product_id, g_iUserPromoKod[pId]);
				#endif
				SQL_ThreadQuery(g_hSqlHandle, "selectQueryHandler", queryData, sData, sizeof(sData));
			}
			else
			{
				formatex(g_iUserPromoKod[pId], charsmax(g_iUserPromoKod[]), "")
				UTIL_SayText(pId, "!g[%s] !yК сожелению данный промокод не найден/не активирован в нашей базе", PREFIX);
				return PLUGIN_HANDLED;
			}
		
		}
		case SQL_LOADPROMO:
		{
			new pId = data[EXT_DATA__INDEX];
				
			if(!is_user_connected(pId)) return PLUGIN_HANDLED;
			
			if(!SQL_NumResults(query))
			{
				new index_member_id = cmsapi_is_user_member(pId);
				
				if(index_member_id)
				{
					new queryData[QUERY_LENGTH];
					
					new product_id = data[EXT_DATA__PRODUCT_ID]
					
					#if defined DEBUG
					server_print("IgnoreHandle | SQL_IGORE | %d | %s | %d", product_id, g_iUserPromoKod[pId], index_member_id);
					#endif
					
					formatex(queryData, charsmax(queryData), "INSERT INTO %s \
					(`user_id`, `product`, `product_id`) \
					VALUES ('%d', '<p>%s</p>', '%d')",PROMO_TABLE, index_member_id, g_iUserPromoKod[pId], product_id);
					
					SQL_ThreadQuery(g_hSqlHandle, "IgnoreHandle", queryData);
					
					new iRet;
					ExecuteForward(g_iFwdLoagPromo, iRet, pId, g_iUserPromoKod[pId], product_id);
				}

			}
			else
			{
				formatex(g_iUserPromoKod[pId], charsmax(g_iUserPromoKod[]), "")
				UTIL_SayText(pId, "!g[%s] !yДанный промокод неактивный, т.к. его уже активировали", PREFIX);
				return Show_MainMenu(pId);
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
			
			if(failstate == TQUERY_QUERY_FAILED)
			{
				new lastQue[QUERY_LENGTH]

				SQL_GetQueryString(query, lastQue, charsmax(lastQue)) // узнаем последний SQL запрос
				log_to_file("mysqlt.log","[ SQL ] %s",lastQue)
			}
			return PLUGIN_CONTINUE;
		}
	}

	SQL_FreeHandle(query);
	return PLUGIN_CONTINUE;
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}

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

