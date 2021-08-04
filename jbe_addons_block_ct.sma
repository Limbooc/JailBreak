#include <amxmodx>
#include <fakemeta>
#include <jbe_core>


new g_iGlobalDebug;
#include <util_saytext>

	/* [Макросы | начало] */
#define VERSION "1.0"
#define ACCESS ADMIN_BAN

#define cmax(%0) sizeof(%0) - 1
#define is_user_admin(%0) (get_user_flags(%0) > 0 && ~get_user_flags(%0) & ADMIN_USER)

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define TASK_INDEX_MYSQL 28819293

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

native jbe_block_reasons(id, reasons[], times, systime, Inflictor[]);


new g_iPlayerReason[MAX_PLAYERS + 1][32],
	g_iMenuTarget[MAX_PLAYERS + 1],
	g_iUserAuthTarget[MAX_PLAYERS + 1],
	g_iBlockTimes[MAX_PLAYERS + 1];

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


#if AMXX_VERSION_NUM < 183
	#include <colorchat>
	#define client_disconnected client_disconnect
#endif
	/* [Макросы | конец] */
	

new g_pCvarTimeUnit;


native jbe_set_user_data(player, iType, iNum);
native jbe_is_user_data(player, iType)

	/* [Нативы | конец] */
	
	/* [Переменные | начало] */

	
public plugin_init() {
	register_plugin("[JBE] Addons Guard block", VERSION, "DalgaPups");

	register_clcmd("Block_Reasons" , 		"clcmd_type_reasons")
	register_clcmd("Block_Time" , 		"clcmd_type_time")

	register_menucmd(register_menuid("Show_MainMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainMenu");

	g_pCvarTimeUnit     = register_cvar( "amx_gag_time_units",    "0"     );
	
	register_clcmd("block_guard", "ConCmd_SayBlock");
	register_clcmd("say /block", "ConCmd_SayBlock");
	register_clcmd("say_team /block", "ConCmd_SayBlock");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public clcmd_type_time(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);

	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		g_iBlockTimes[id] = 300;
		return Show_MainMenu(id);
	}
	/*if(str_to_num( Args1 ) < 300)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить меньше !g300 !yсекунд или !g5 !yминутам");
		g_iBlockTimes[id] = 300;
		return Show_MainMenu(id);
	}*/
	if(str_to_num( Args1 ) > 604800)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить больше !g604 800 !yсекунд или !gодной недели");
		g_iBlockTimes[id] = 0;
		return Show_MainMenu(id);

	}
	
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			g_iBlockTimes[id] = 300;
			return Show_MainMenu(id);
		}
	}
	g_iBlockTimes[id] = str_to_num( Args1 );
	return Show_MainMenu(id);
}

public clcmd_type_reasons(id) 
{

	
	read_argv(1, g_iPlayerReason[id], 31)

	replace(g_iPlayerReason[id], 31, "'", "")
	replace(g_iPlayerReason[id], 31, "#", "")
	mysql_escape_string(g_iPlayerReason[id], charsmax(g_iPlayerReason[]));
	return Show_MainMenu(id)
}

public client_disconnected(id)
{
	formatex(g_iPlayerReason[id], charsmax(g_iPlayerReason[]), "");
	g_iBlockTimes[id] = 300;
}

public client_putinserver(id)
{
	formatex(g_iPlayerReason[id], charsmax(g_iPlayerReason[]), "");
	g_iBlockTimes[id] = 300;
}

public ConCmd_SayBlock(id) {
	if(get_user_flags(id) & ACCESS) {
		return Open_BlockMenu(id);
	}
	
	UTIL_SayText(id, "!g* !yУ вас недостаточно прав!");
	return PLUGIN_HANDLED;
}

public Open_BlockMenu(id) {
	new sTemp[10], sDataString[128], iMenu = menu_create("Блокировка охраны", "Close_BlockMenu");
	

	
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) /*|| i == id || is_user_admin(i)*/)
			continue;
		
		get_user_name(i, sDataString, cmax(sDataString));
		
		num_to_str(i, sTemp, cmax(sTemp));
		formatex(sDataString, cmax(sDataString), "%s ^t%s^t^t- %s", sDataString, jbe_is_user_data(i, 1) ? "\r[BLOCK]" : "", (jbe_get_user_team(i) == 2) ? "\yОхрана" : "\rЗек");
		menu_additem(iMenu, sDataString, sTemp);
	}
	menu_setprop(iMenu, MPROP_BACKNAME, "Назад");
	menu_setprop(iMenu, MPROP_NEXTNAME, "Вперед");
	menu_setprop(iMenu, MPROP_EXITNAME, "Выход");
	
	return menu_display(id, iMenu, 0);
}

public Close_BlockMenu(id, iMenu, aItem) {

	if (aItem == MENU_EXIT)

    {
        menu_destroy(iMenu)
        return PLUGIN_HANDLED
    }
	new sData[30], sName[64], iAccess, iCallBack;
	menu_item_getinfo(iMenu, aItem, iAccess, sData, cmax(sData), sName, cmax(sName), iCallBack);
	
	new iPlayer = str_to_num(sData);

	g_iMenuTarget[id] = iPlayer;

	if(jbe_is_user_data(iPlayer, 1) == 0)
	{
		g_iUserAuthTarget[iPlayer] = get_user_userid(iPlayer);
		return Show_MainMenu(id);
	}
	else
	{
		//formatex(g_iPlayerReason[id], charsmax(g_iPlayerReason), "");
		g_iBlockTimes[iPlayer] = 0;
		new iSysTime = get_systime();
		//new szName[1] = ""
		jbe_set_user_data(iPlayer, 1, 0);
		//jbe_block_reasons(iPlayer, "", g_iBlockTimes[iPlayer], iSysTime, "");
		jbe_block_reasons(iPlayer, "", 0, iSysTime, "");
		
		UTIL_SayText(0,  "!g[БЛОК] !yАдминистратор !g%n !yразблокировал вход за охрану для игрока !g%n!y!", id , iPlayer);
		return PLUGIN_HANDLED;
	}
	//return PLUGIN_HANDLED;
}

Show_MainMenu(id)
{
	if(!jbe_is_user_connected(g_iMenuTarget[id]))
	{
		return PLUGIN_HANDLED;
	}
	new szMenu[512], iLen, iKeys;

	new szTime[ 128 ];
	GetTimeLength(g_iBlockTimes[id] * g_iTimeUnitMult[ GetTimeUnit( ) ], szTime, charsmax( szTime ) );



	FormatMain("\yБлокировать игрока?^n^n");

	FormatItem("\rИгрок - \y%n^n^n", g_iMenuTarget[id])
	if(strlen(g_iPlayerReason[id]) < 4)
		FormatItem("\y1. \wПричина: \yУказать причину^n"), iKeys |= (1<<0);
	else FormatItem("\y1. \wПричина: \y%s^n", g_iPlayerReason[id]), iKeys |= (1<<0);

	if(strlen(g_iPlayerReason[id]) < 4)
		FormatItem("\y2. \dБлокировать^n");
	else FormatItem("\y2. \rБлокировать^n"), iKeys |= (1<<1);

	if(g_iBlockTimes[id])
		FormatItem("\y3. \wСрок блока: \y%s^n", szTime ), iKeys |= (1<<2);
	else FormatItem("\y3. \wСрок блока: \yНавсегда^n"), iKeys |= (1<<2);

	FormatItem("^n^n\dСрок указывается в секундах^n");
	FormatItem("\d5 минут = 300^n");
	FormatItem("\d1 час = 3 600^n");
	FormatItem("\d1 неделя = 604 800^n");



	FormatItem("^n^n\y9. \wНазад^n"), iKeys |= (1<<8);
	FormatItem("\y0. \wВыход^n"), iKeys |= (1<<9);

	return show_menu(id, iKeys, szMenu, -1, "Show_MainMenu");

}

public Handle_MainMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: 
		{

			client_cmd(id, "messagemode ^"Block_Reasons^"");
			UTIL_SayText(id,"!g********************************************************");
			UTIL_SayText(id, "!yУкажите причину");
			UTIL_SayText(id, "!g********************************************************");
		}
		case 1:
		{
			/*if(g_iBlockTimes[id] < 300)
			{
				UTIL_SayText(id, "!g[БЛОК] !yПовторите попытку, срок блока указано меньше !gпяти !yминут");
				g_iBlockTimes[id] = 300;
				return Show_MainMenu(id);
			}*/
			if(is_user_connected(g_iMenuTarget[id]))
			{
				if(get_user_userid(g_iMenuTarget[id]) == g_iUserAuthTarget[g_iMenuTarget[id]])
				{
					jbe_set_user_data(g_iMenuTarget[id], 1, 1);
					
					if(jbe_get_user_team(g_iMenuTarget[id]) == 2)
						jbe_set_user_team(g_iMenuTarget[id], 1);

					new iSysTime = get_systime();

					new szName[MAX_NAME_LENGTH];
					get_user_name(id, szName, MAX_NAME_LENGTH - 1);

					jbe_block_reasons(g_iMenuTarget[id], g_iPlayerReason[id], g_iBlockTimes[id], iSysTime, szName);
					
					
					UTIL_SayText(0,  "!g[БЛОК] !yАдминистратор !g%n !y%s вход за охрану для игрока !g%n!y!", id , jbe_is_user_data(g_iMenuTarget[id], 1) ? "заблокировал" : "разблокировал", g_iMenuTarget[id]);
					UTIL_SayText(0, "!g[БЛОК] !yПричина блока - !g%s", g_iPlayerReason[id]);

					new szTime[ 128 ];
					GetTimeLength(g_iBlockTimes[id] * g_iTimeUnitMult[ GetTimeUnit( ) ], szTime, charsmax( szTime ) );

					if(g_iBlockTimes[id]) UTIL_SayText(0, "!g[БЛОК] !yСрок блока - !g%s", szTime);
					else UTIL_SayText(0, "!g[БЛОК] !yСрок блока - !gНавсегда");
				}
				else
				{
					UTIL_SayText(id, "!g[БЛОК] !yПроизошла ошибка, игрок отсоединился");
					return Open_BlockMenu(id);
				}
				return PLUGIN_HANDLED;
			}
			else
			{
				UTIL_SayText(id, "!g[БЛОК] !yПроизошла ошибка, игрок отсоединился");
				return Open_BlockMenu(id);
			}
		}
		case 2:
		{
		

			client_cmd(id, "messagemode ^"Block_Time^"")  
		}
	}
	return Show_MainMenu(id);
}

stock mysql_escape_string(output[], len)
{
	static const szReplaceIn[][] = { 	
		"\\", 
		"\0", 
		"\n", 
		"\r", 
		"\x1a", 
		"'", 
		"^"" 
	};
	static const szReplaceOut[][] = { 
		"\\\\", 
		"\\0", 
		"\\n", 
		"\\r", 
		"\Z", 
		"\'", 
		"\^"" 
	};
	for(new i; i < sizeof szReplaceIn; i++)
	{
		replace_all(output, len, szReplaceIn[i], szReplaceOut[i]);
	}
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
	
	return iLen
}

GetTimeUnit( )
{
	new szTimeUnit[ 64 ], iTimeUnit;
	get_pcvar_string( g_pCvarTimeUnit, szTimeUnit, charsmax( szTimeUnit ) );
	
	if( is_str_num( szTimeUnit ) )
	{
		iTimeUnit = get_pcvar_num( g_pCvarTimeUnit );
		
		if( !( 0 <= iTimeUnit < TimeUnit ) )
		{
			iTimeUnit = -1;
		}
	}
	
	if( iTimeUnit == -1 )
	{
		iTimeUnit = TIMEUNIT_SECONDS;
		
		set_pcvar_num( g_pCvarTimeUnit, TIMEUNIT_SECONDS );
	}
	
	return iTimeUnit;
}
