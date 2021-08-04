#include <amxmodx>
#include <center_msg_fix>
#include <reapi>
#include <jbe_core>
//#include <gamecms5>


native jbe_is_user_vip(iSender);
native jbe_is_user_flags(iSender, flags);
native jbe_clear_user_voice(pid)
new const g_szSoundFilePath[] = "../valve/sound/buttons/blip2.wav";
/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

new g_iBitUserVoice;
new bool:g_iOnlyTalkSimon;
public plugin_init()
{
	register_plugin("[JBE] Jbe Addons Voice Systems", "1.0", "DalgaPups");
	
	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CanPlayerHearPlayer", false);
	
	//register_clcmd("+simonvoice", "simonvoiceon");
	//register_clcmd("-simonvoice", "simonvoiceoff");
	//register_clcmd("onlysimon", "onlysimon");
}

public plugin_precache()
{
	if(file_exists(g_szSoundFilePath))
		precache_sound(g_szSoundFilePath);
}
/*public onlysimon(pId) 
{
	g_iOnlyTalkSimon = !g_iOnlyTalkSimon;
	server_print("%s", g_iOnlyTalkSimon ? "ON" : "OFF");
}
public simonvoiceon(pId)
{
	if(jbe_is_user_alive(pId) && jbe_is_user_chief(pId))
	{
		SetBit(g_iBitUserVoice, pId);
	}
	if(g_iOnlyTalkSimon && jbe_get_user_team(pId) == 1)
	{
		CenterMsgFix_PrintMsg(pId, print_center, "Начальника нельзя перебить!");
	}
	CenterMsgFix_PrintMsg(pId, print_center, "Начальника нельзя перебить!");
	engclient_cmd(pId, "+voicerecord");
}

public simonvoiceoff(pId)
{
	if(IsSetBit(g_iBitUserVoice, pId))
		ClearBit(g_iBitUserVoice, pId);
	engclient_cmd(pId, "-voicerecord");
}*/

public client_disconnected(pId) ClearBit(g_iBitUserVoice, pId);

forward OnAPIAdminConnected(id, const szName[], adminID, Flags);

public client_putinserver(id)
{
	if(jbe_is_user_flags(id, 1) || jbe_is_user_vip(id) > 1)
	{
		jbe_set_user_voice(id);
	}
}
public OnAPIAdminConnected(id, const szName[], adminID, iFlags)
{
	if(jbe_is_user_flags(id, 1) || jbe_is_user_vip(id) > 1)
	{
		jbe_set_user_voice(id);
	}
	
}

public OnAPIAdminDisconnected(id)
{
	jbe_clear_user_voice(id);
}

/*public jbe_fwr_is_user_voice(pId)
{
	//if(g_szPlayerMuteType[pId] == BLOCK_STATUS_VOICE )
	if(cmsgag_is_user_blocked(pId) == BLOCK_STATUS_VOICE)
	{
		jbe_clear_user_voice(pId)
		server_print("Player muted");
	}
}
*/


public CanPlayerHearPlayer(iReceiver, iSender, bool:bListen)
{
	if(g_iOnlyTalkSimon && g_iBitUserVoice)
	{
		if(jbe_get_user_team(iSender) == 2 && IsSetBit(g_iBitUserVoice, iSender) && iSender != iReceiver)
		{
			return FnCanHearSender(iReceiver, iSender, true);
		}
		if(IsNotSetBit(g_iBitUserVoice, iSender))
			return FnCanHearSender(iReceiver, iSender, false);
	}
	if(jbe_is_user_alive(iSender))
	{
		if(jbe_get_user_team(iSender) == 2)
		{
			return FnCanHearSender(iReceiver, iSender, true);
		}
		if(jbe_get_user_voice(iSender))
		{
			return FnCanHearSender(iReceiver, iSender, true);
		}
		if(jbe_is_user_vip(iSender) > 1 /*LEVEL_ONE*/ )
		{
			return FnCanHearSender(iReceiver, iSender, true);
		}
	}
	if(jbe_is_user_flags(iSender, 1) && jbe_get_user_voice(iSender))
	{
		return FnCanHearSender(iReceiver, iSender, true);
	}

	return FnCanHearSender(iReceiver, iSender, false);
}

FnCanHearSender(Receiver, Sender, bool:status)
{
	#pragma unused Receiver, Sender
	SetHookChainReturn(ATYPE_BOOL, status);
	return HC_SUPERCEDE;
}


/*public VTC_OnClientStartSpeak(const iSender)
{
	if(cmsgag_is_user_blocked( iSender ) == BLOCK_STATUS_ALL || cmsgag_is_user_blocked( iSender ) == BLOCK_STATUS_VOICE )
	{
		
		CenterMsgFix_PrintMsg(iSender, print_center, "Ваш микрофон заблокирован!");
		client_cmd(iSender, "play %s", g_szSoundFilePath);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}*/



	