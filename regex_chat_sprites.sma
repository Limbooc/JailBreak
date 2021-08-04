#include < amxmodx >
#include < amxmisc >
#include < regex >
#include < reapi >
#include < fakemeta >


new Regex:g_pPattern = REGEX_PATTERN_FAIL;
new Trie:g_iTriePattern;
new Array:g_aSpritesArray;
new g_aArraySize;

enum _:DATA_SPRITES
{
	MODEL_NAME[32],
	SUB_MODEL[4],
	SPRITE_NAME[32],
	SPRITE_DIR[64]
}

new const SpritesClass[] = "sprites_classname";
#define REMOVETIME			3.0

new bool:g_iUserSpites[MAX_PLAYERS + 1]

public plugin_precache()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	formatex(szCfgFile, charsmax(szCfgFile), "%s/pattern_chat.ini", szCfgDir);
	if(file_exists(szCfgFile))
	{
		new aDataTestPatternArray[DATA_SPRITES], szBuffer[256], iLine, iLen;
		g_aSpritesArray = ArrayCreate(DATA_SPRITES);
		g_iTriePattern = TrieCreate();
		new iReturn;
		new szFlags[ 5 ];
		
		new i;
		while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
		{
			if(!iLen || szBuffer[0] == ';') continue;
			parse
			(
				szBuffer, 
				aDataTestPatternArray[MODEL_NAME], 		charsmax(aDataTestPatternArray[MODEL_NAME]), 
				aDataTestPatternArray[SUB_MODEL], 		charsmax(aDataTestPatternArray[SUB_MODEL]),
				aDataTestPatternArray[SPRITE_NAME], 	charsmax(aDataTestPatternArray[SPRITE_NAME])
			);
			format(szBuffer, charsmax(szBuffer), "sprites/%s.spr", aDataTestPatternArray[SPRITE_NAME]);
			
			if(file_exists(szBuffer)) 
			{
				new szError[ 128 ];
				g_pPattern = regex_compile( aDataTestPatternArray[MODEL_NAME], iReturn, szError, charsmax( szError ), "^^\/(.*)\/([imsx]*)$" );

				copy(aDataTestPatternArray[SPRITE_DIR], charsmax(aDataTestPatternArray[SPRITE_DIR]), szBuffer);
				
				if( g_pPattern == REGEX_PATTERN_FAIL )
				{
					log_to_file("log_patern.txt", "Error with pattern: %s | %s", szError , aDataTestPatternArray[MODEL_NAME]);
				}
				else
				{
					
					engfunc(EngFunc_PrecacheModel, szBuffer);
					ArrayPushArray(g_aSpritesArray, aDataTestPatternArray);
					
					//new iDate[1];
					//iDate = g_aSpritesArray;
					TrieSetCell(g_iTriePattern, aDataTestPatternArray[MODEL_NAME], i);
					i++;
					
					//server_print("%d", g_pPattern);
				}
			}
			else
			{
				log_to_file("log_patern.txt", "[%s] - not found! ", szBuffer );
			}

		}
		g_aArraySize = ArraySize(g_aSpritesArray);
	}

}
public plugin_init( )
{
	register_clcmd("say","HookSay");
	register_clcmd("say_team","HookSay");
}

forward cm_player_send_message(id, msg[192], isteam);
public cm_player_send_message(id, msg[192], isteam)
{
	HookSay(id)
}
public HookSay(iPlayer)
{
	new szData[ 192 ];
	read_args( szData, charsmax( szData ) );
	trim( szData );
	remove_quotes( szData );
	
	
	new iReturn;
	
	//if( regex_match_c( szData, g_pPattern, iReturn ) != -2 )
	{
		//server_print("found: %s",  szData);
		
		//new aDataTestPatternArray[DATA_SPRITES];
		new Regex:rgxMatch
						new nNumber, nError[128]
		
		for( new i = 0; i < iReturn; i++ )
		{
		
			regex_substr( g_pPattern, i, szData, charsmax( szData ) );
			
			for (new j = 0; j < g_aArraySize; j++)
			{
				server_print("array");
				
				ArrayGetArray(g_aSpritesArray, j, aDataTestPatternArray)
				rgxMatch = regex_match(szData, aDataTestPatternArray[MODEL_NAME], nNumber, nError, charsmax(nError), "/\W*(?:[a@4]|\/\\|\/-\\)+[s5z\$]{2,}\W*/i")
				if (rgxMatch >= REGEX_OK)
				{
					regex_free(rgxMatch)
					RegExFound(iPlayer, j);
					break;
				}
			}
		}
		
		if( regex_match_c( szData, g_pPattern, iReturn ) != -2 )
		{
			if(iReturn == 0)
				server_print("сопоставление не найдено")
				
			server_print("j: %s: %d matches",  szData, iReturn);
			new iNum;
			for( new i = 0; i < iReturn; i++ )
			{

				server_print("p %s",  szData);
				if( TrieGetCell( g_iTriePattern, szData, iNum ) )
				{
					server_print("s %s",  szData);
					new aDataTestPatternArray[DATA_SPRITES];
					ArrayGetArray(g_aSpritesArray, iNum, aDataTestPatternArray)
					new Regex:rgxMatch
					new nNumber, nError[128]
					rgxMatch = regex_match(szData, aDataTestPatternArray[MODEL_NAME], nNumber, nError, charsmax(nError), "^^\/(.*)\/([imsx]*)$")
					if (rgxMatch >= REGEX_OK)
					{
						regex_free(rgxMatch)
						RegExFound(iPlayer, iNum);
					}
				}
			}
		}
	}
}

RegExFound(pId, ArrayIndex)
{
	if(!is_user_alive(pId))
		return;
		
	if(g_iUserSpites[pId])
	{
		client_print(pId, print_center, "Дождитесь оканчание предыдущего Эмоджи")
		return;
	}
	new aDataTestPatternArray[DATA_SPRITES];
	ArrayGetArray(g_aSpritesArray, ArrayIndex, aDataTestPatternArray)

	new Float:vecOrigin[3];
	get_entvar(pId, var_origin, vecOrigin);
	vecOrigin[2] += 50.0;
	set_user_sprite(pId, vecOrigin, aDataTestPatternArray[SUB_MODEL], aDataTestPatternArray[SPRITE_DIR]);
}

/////////////////////////////////

public client_disconnected(pId)
{
	if(g_iUserSpites[pId])
		g_iUserSpites[pId] = false;
}


public set_user_sprite(id, Float:vecOrigin[3], iFrame[], Sprites[])
{
	new iEnt = rg_create_entity("info_target", true);
	if(!is_entity(iEnt))
		return PLUGIN_CONTINUE;
		
	set_entvar(iEnt, var_classname, SpritesClass);
	set_entvar(iEnt, var_scale, 0.35)
   	set_entvar(iEnt, var_framerate, 0.0)
	set_entvar(iEnt, var_frame, str_to_float(iFrame));
	set_entvar(iEnt, var_origin, vecOrigin);
	engfunc(EngFunc_SetModel, iEnt, Sprites);
	set_entvar(iEnt, var_solid, SOLID_NOT);
	set_entvar(iEnt, var_movetype, MOVETYPE_NONE);
	
	g_iUserSpites[id] = true;
	new iEntIndex[2];
	iEntIndex[0] = id;
	iEntIndex[1] = iEnt;
	SetThink(iEnt, "Think_Origin", iEntIndex, sizeof(iEntIndex));
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.01);
	
	
	new iTimeEnt = rg_create_entity("info_target", true);
	
	SetThink(iTimeEnt, "Think_RemoveEnt", iEntIndex, sizeof(iEntIndex));
	set_entvar(iTimeEnt, var_nextthink, get_gametime() + REMOVETIME);
	
	return PLUGIN_CONTINUE;
}


public Think_RemoveEnt(iEnt, iParam[])
{
	if(is_entity(iEnt))
	{
		new pId = iParam[0];
		new iSpritesEnt = iParam[1];
	
		if(is_user_connected(pId))
			g_iUserSpites[pId] = false;
		
		if(is_entity(iSpritesEnt))
		{
			set_entvar(iSpritesEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME)
			set_entvar(iSpritesEnt, var_nextthink, get_gametime() + 0.1);
		}
		
		
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME)
		set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
	}
}

public Think_Origin(iEnt, iParam[])
{
	if(is_entity(iEnt))
	{
		new Float:vecOrigin[3];
		new pId = iParam[0];
		
		get_entvar(pId, var_origin, vecOrigin);
		vecOrigin[2] += 50.0;
		set_entvar(iEnt, var_origin, vecOrigin);
		
		set_entvar(iEnt, var_nextthink, get_gametime() + 0.01);
	}
}



