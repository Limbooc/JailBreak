#include <amxmodx>
#include <reapi>
#include <jbe_core>
#include <amxmisc>
#include <reapi>

#define IsPlayer(%1) (1 <= %1 <= MaxClients)
#define ClearArr(%1) arrayset(_:%1, _:0.0, sizeof(%1))
#define TASK_SHOW_INFORMER 564578

enum _:ePlayerData
{
	PLAYER_ID,
	DAMAGE,
	KILLS
};

new g_iTopID;

new g_aData[MAX_PLAYERS + 1][ePlayerData],
	g_iPlayerDmg[MAX_PLAYERS + 1],
	g_iPlayerKills[MAX_PLAYERS + 1];
	
new szMenu[512];

//new g_iSyncTemp;

#define maxPlayers	32

new HookChain:HookPlayer_RestartRound,
	HookChain:HookPlayer_Killed,
	HookChain:HookPlayer_TakeDamage;


public plugin_init()
{
	register_plugin("[JBE] TOP Damage Addons", "1.0", "DalgaPups");
	
	DisableHookChain(HookPlayer_RestartRound = 		RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre", false));
	DisableHookChain(HookPlayer_Killed = 			RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true));
	DisableHookChain(HookPlayer_TakeDamage = 		RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage", true));
	
	//set_task_ex(1.0, "fnShowTopRound", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);
	
	//g_iSyncTemp = CreateHudSyncObj();

}

public plugin_natives()
{
	register_native("jbe_top_damaget_status", "jbe_top_damaget_status", true);
	register_native("jbe_is_user_top", "jbe_is_user_top", 1);
	register_native("native_hudmessage", "native_hudmessage");
	register_native("jbe_top_tasked", "jbe_top_tasked", 1);
}

public jbe_is_user_top() return g_iTopID;


public jbe_top_damaget_status(iType)
{

	switch(iType)
	{
		case 1:
		{

				EnableHookChain(HookPlayer_RestartRound);
				EnableHookChain(HookPlayer_Killed);
				EnableHookChain(HookPlayer_TakeDamage);
				
				set_task_ex(1.0, "fnShowTopRound", TASK_SHOW_INFORMER, .flags = SetTask_Repeat);

		}
		case 0:
		{

				DisableHookChain(HookPlayer_RestartRound);
				DisableHookChain(HookPlayer_Killed);
				DisableHookChain(HookPlayer_TakeDamage);
				
				if(task_exists(TASK_SHOW_INFORMER)) remove_task(TASK_SHOW_INFORMER);
				

			
				CSGameRules_RestartRound_Pre()
		
		
		}
	
	}
	


}

public CSGameRules_RestartRound_Pre()
{
	ClearArr(g_iPlayerDmg);
	ClearArr(g_iPlayerKills);
	
	for (new i = 1; i <= MaxClients; i++)
		arrayset(g_aData[i], 0, ePlayerData);
}

public CBasePlayer_TakeDamage(const pevVictim, pevInflictor, const pevAttacker, Float:flDamage, bitsDamageType)
{
	if (!IsPlayer(pevAttacker) || pevVictim == pevAttacker || (bitsDamageType & DMG_BLAST))
		return HC_CONTINUE;
	
	if (rg_is_player_can_takedamage(pevVictim, pevAttacker))
		g_iPlayerDmg[pevAttacker] += floatround(flDamage);
	
	return HC_CONTINUE;
}


public CBasePlayer_Killed(const pevVictim, pevAttacker)
{
	if (!is_user_connected(pevAttacker) || pevVictim == pevAttacker)
		return HC_CONTINUE;
	
	g_iPlayerKills[pevAttacker]++;
	
	return HC_CONTINUE;
}

public fnShowTopRound()
{
	new  pPlayer;
	new iLen, iTop = 3;

	
	static iPlayers[MAX_PLAYERS], iPlayerCount;

	get_players_ex(iPlayers, iPlayerCount/*, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST"*/);
	
	for(new i; i < iPlayerCount; i++)
	{
		pPlayer = iPlayers[i];
		
		g_aData[i][PLAYER_ID] = pPlayer;
		g_aData[i][DAMAGE] = _:g_iPlayerDmg[pPlayer];
		g_aData[i][KILLS] = _:g_iPlayerKills[pPlayer];
	}
	
	SortCustom2D(g_aData, sizeof(g_aData), "SortRoundDamage");
	
	iLen = formatex(szMenu, charsmax(szMenu), "Топ по урону | убийств^n");

	for (new i = 0; i < iTop; i++)
	{
		if (g_aData[i][DAMAGE] <= 0 || !jbe_is_user_connected(pPlayer))
			continue;
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%n | %dDMG | %dKILL^n",g_aData[i][PLAYER_ID], g_aData[i][DAMAGE], g_aData[i][KILLS]);
		g_iTopID = g_aData[0][PLAYER_ID];
	}
	//iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "...^n%n | %dDMG | %dKILL",g_aData[pPlayer][PLAYER_ID], g_aData[pPlayer][DAMAGE], g_aData[pPlayer][KILLS]);
	//Для топа 1
	//if(g_aData[0][DAMAGE]) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%n",TempID);
	
	//set_hudmessage(100, 100, 100, 0.10, 0.14, 0, 0.0, 0.8, 0.2, 0.2, -1);
	//ShowSyncHudMsg(0, g_iSyncTemp, "%s", szMenu);
}

public jbe_top_tasked() return task_exists(TASK_SHOW_INFORMER);

public native_hudmessage(plugin, params)
{
	enum {
        arg_str = 1,
        arg_len
    };
	if(!task_exists(TASK_SHOW_INFORMER))
	{
		//new szMenu[512];
		 set_string(arg_str, "", get_param(arg_len));
		 return;
	}

    set_string(arg_str, szMenu, get_param(arg_len));
}

public SortRoundDamage(const elem1[], const elem2[])
{
	return (elem1[DAMAGE] < elem2[DAMAGE]) ? 1 : (elem1[DAMAGE] > elem2[DAMAGE]) ? -1 : 0;
}