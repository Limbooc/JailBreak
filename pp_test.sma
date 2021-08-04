#include <amxmodx>
#include <reapi>
#include <player_preferences>

new const g_szKey[] = "";

new bool:g_bLoaded[MAX_PLAYERS + 1];

public plugin_init()
{
    RegisterHookChain(RG_CBasePlayer_AddAccount, "refwd_PlayerAddAccount_Post", true);
    RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);
}

public player_loaded(const id)
{
    g_bLoaded[id] = true;

	new buffer[1024], len;

    for(new i = 0; i <= 200; i++)
	{
		len += formatex(buffer, charsmax(buffer) - len, "%d", i);
		server_print("GET %d - %d", i , pp_get_number(id, buffer));
		//pp_set_number(id, buffer, i);
	}
}

public refwd_PlayerAddAccount_Post(const id, iAmount, RewardType:iType, bool:bTrackChange)
{
	if(g_bLoaded[id])
	{
		pp_set_number(id, g_szKey, get_member(id, m_iAccount));

		new buffer[1024];

		for(new i = 0; i <= 200; i++)
		{
			formatex(buffer, charsmax(buffer), "%d", i);
			server_print("SET %s - %d", i, i);
			pp_set_number(id, buffer, i);
		}
	}
}

public refwd_DropClient_Post(const id)
{
    g_bLoaded[id] = false;
}