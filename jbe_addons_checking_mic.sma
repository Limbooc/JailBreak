#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <jbe_core>

#pragma semicolon 1

#define TASK_CHECK_MIC 2435346

native jbe_is_user_flags(pId, iType);

new g_iBitUserMic;
new g_iCountDown[MAX_PLAYERS + 1];
new g_iSyncInf;

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))


public plugin_init()
{
	register_plugin("[JBE] Addons Checking Mic", "1.0", "DalgaPups");
	g_iSyncInf = CreateHudSyncObj();
}


public jbe_set_team_fwd(pId)
{
	if(jbe_get_user_team(pId) == 2 && !jbe_is_user_flags(pId, 5))
	{
		set_task_ex(1.0, "jbe_task_checking", pId + TASK_CHECK_MIC, _, _, SetTask_RepeatTimes, g_iCountDown[pId] = 11);
		SetBit(g_iBitUserMic, pId);
	}
	if(jbe_get_user_team(pId) == 1 && task_exists(pId+TASK_CHECK_MIC))
	{
		remove_task(pId+TASK_CHECK_MIC);
		ClearBit(g_iBitUserMic, pId);
	}
	
}

public client_disconnected(pId)
{
	if(task_exists(pId+TASK_CHECK_MIC))
	{
		remove_task(pId+TASK_CHECK_MIC);
		ClearBit(g_iBitUserMic, pId);
	}


}

public jbe_task_checking(pId)
{
	pId -= TASK_CHECK_MIC;
	
	if(--g_iCountDown[pId])
	{
		
		set_hudmessage(255, 0, 0, -1.0, 0.45, 0, 0.0, 1.0, 1.1, 1.1, -1);
		ShowSyncHudMsg(pId, g_iSyncInf, "Проверка микрофона^n-=ВКЛЮЧИТЕ МИКРОФОН=-^nосталось %d секунд", g_iCountDown[pId]);
	}
	else
	{
		jbe_set_user_team(pId, 1);
		UTIL_SayText(0, "!g[CHECKING MIC] !yИгрок - !g%n !yне прошел проверку на микрофона", pId);
		ClearBit(g_iBitUserMic, pId);
	}
}

public VTC_OnClientStartSpeak(const pId)
{
	if(task_exists(pId+TASK_CHECK_MIC))
	{
		if(IsSetBit(g_iBitUserMic, pId) && jbe_get_user_team(pId) == 2)
		{
			ClearBit(g_iBitUserMic, pId);
			set_hudmessage(0, 255, 0, -1.0, 0.45, 0, 1.0, 1.5, 1.1, 3.1, -1);
			ShowSyncHudMsg(pId, g_iSyncInf, "Вы успешно прошли проверку на наличии микро!");
			remove_task(pId+TASK_CHECK_MIC);
		}
	
	}


}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
}