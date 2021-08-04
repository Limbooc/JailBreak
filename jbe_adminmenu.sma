#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>
new g_iGlobalDebug;
#include <util_saytext>
//#define GAMECMS


native jbe_set_butt(p,ps);
native jbe_get_butt(p);

#if defined GAMECMS
#include <gamecms5>
#endif

#define PLAYERS_PER_PAGE 8

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

native jbe_restartgame()
native jbe_aliveplayersnum(iType)
native jbe_daymodelistsize()
native jbe_show_mainmenu(id)
native jbe_get_soccergame();
native Open_Oaio(id)
native jbe_set_user_model_ex(pId, iType);
native jbe_show_teammenu(pId, iType);
native jbe_open_vipmenu(pId);
native jbe_open_infovip(pId);
native jbe_globalnyizapret();
native Cmd_VoiceControlMenu(pId);
native Cmd_FreeDayControlMenu(pId);

native jbe_is_user_vip(pId);

//native admin_expired(index);


new bool:g_iBlock[2];

new g_iBitUserBlock;

/* -> Битсуммы, переменные и массивы для работы с випа/админами -> */
new g_iVipRespawn[MAX_PLAYERS + 1], 
	g_iVipHealth[MAX_PLAYERS + 1], 
	g_iVipMoney[MAX_PLAYERS + 1], 
	g_iVipInvisible[MAX_PLAYERS + 1],
	g_iVipHpAp[MAX_PLAYERS + 1], 
	g_iVipVoice[MAX_PLAYERS + 1];

new g_iAdminRespawn[MAX_PLAYERS + 1], 
	g_iAdminHealth[MAX_PLAYERS + 1], 
	g_iAdminMoney[MAX_PLAYERS + 1], 
	g_iAdminGod[MAX_PLAYERS + 1],
	g_iAdminFootSteps[MAX_PLAYERS + 1];

new g_iBitUserVip, 
	g_iBitUserAdmin, 
	g_iBitUserSuperAdmin,
	g_iBitUserOAIO,
	g_iBitUserGirl,
	g_iBitUserImmunity;


/* -> Индексы общих настроек для кваров -> */
enum _:CVARS_COUNT
{
	VIP_RESPAWN_NUM = 0,
	VIP_HEALTH_NUM,
	VIP_MONEY_NUM,
	VIP_MONEY_ROUND,
	VIP_INVISIBLE,
	VIP_HP_AP_ROUND,
	VIP_VOICE_ROUND,
	VIP_DISCOUNT_SHOP,
	ADMIN_RESPAWN_NUM,
	ADMIN_HEALTH_NUM,
	ADMIN_MONEY_NUM,
	ADMIN_MONEY_ROUND,
	ADMIN_GOD_ROUND,
	ADMIN_FOOTSTEPS_ROUND,
	RESPAWN_PLAYER_NUM,
	ADMIN_DISCOUNT_SHOP,
	FLAGS_VIP,
	FLAGS_ADMIN,
	FLAGS_SUPER_ADMIN,
	FLAGS_UAIO,
	FLAGS_GIRL
}

new g_iAllCvars[CVARS_COUNT];

enum _: eData_Flags
{
	Flags_Vips = 0,
	Flags_Admins,
	Flags_SuperAdmins,
	Flags_UAIO,
	Flags_Girls
};
new g_iFlags[ eData_Flags ];

enum _:(+= 1)
{
	FLAGSVIP = 0,
	FLAGSADMIN,
	FLAGSSUPERADMIN,
	FLAGSUAIO,
	FLAGSGIRL,
	FLAGSENABLED,
	FLAGSIMMUNITY
}

public plugin_init()
{
	register_plugin("[JBE] AdminMenu API", "1.0", "DalgaPups");

	//register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");
	//register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
	

	register_menucmd(register_menuid("Show_PrivMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_PrivMenu");
	register_menucmd(register_menuid("Show_VipMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_VipMenu");
	register_menucmd(register_menuid("Show_AdminMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_AdminMenu");
	register_menucmd(register_menuid("Show_ZapretMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ZapretMenu");
	register_menucmd(register_menuid("Show_SuperAdminMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_SuperAdminMenu");
	register_menucmd(register_menuid("Show_OtherUaio"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_OtherUaio");
	register_menucmd(register_menuid("Show_BanMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_BanMenu");
	
	
	register_menucmd(register_menuid("Show_AdvertMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_AdvertMenu");
	register_menucmd(register_menuid("Show_AdvertMenu_1"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_AdvertMenu_1");
	register_menucmd(register_menuid("Show_AdvertMenu_2"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_AdvertMenu_2");
	register_menucmd(register_menuid("Show_AdvertMenu_3"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), "Handle_AdvertMenu_3");
	


	jbe_get_cvars();
	
	register_clcmd("adminmenu", "openadminmenu");
	
	register_clcmd("sborkainfo", "sborkainfo");
	
	register_clcmd("amxmodmenu", "amxmodmenu");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}
public amxmodmenu(pId) return jbe_show_adminmenu(pId);
public sborkainfo(pId) return Show_AdvertMenu(pId);
public openadminmenu(pId) 
{
	if(IsSetBit(g_iBitUserAdmin, pId)) return Show_AdminMenu(pId); 
	return PLUGIN_HANDLED;
}
new szFlags[ 2 ];
jbe_get_cvars()
{
	new pcvar;
	
	
	pcvar = create_cvar("jbe_vip_respawn_num", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_RESPAWN_NUM]);
	
	pcvar = create_cvar("jbe_vip_health_num", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HEALTH_NUM]);
	
	pcvar = create_cvar("jbe_vip_money_num", "50", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_MONEY_NUM]); 
	
	pcvar = create_cvar("jbe_vip_money_round", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_MONEY_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_invisible_round", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_INVISIBLE]); 
	
	pcvar = create_cvar("jbe_vip_hp_ap_round", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_HP_AP_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_voice_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_VOICE_ROUND]); 
	
	pcvar = create_cvar("jbe_vip_discount_shop", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[VIP_DISCOUNT_SHOP]); 
	
	pcvar = create_cvar("jbe_admin_respawn_num", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_RESPAWN_NUM]); 
	
	pcvar = create_cvar("jbe_admin_health_num", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_HEALTH_NUM]); 
	
	pcvar = create_cvar("jbe_admin_money_num", "100", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_MONEY_NUM]); 
	
	pcvar = create_cvar("jbe_admin_money_round", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_MONEY_ROUND]); 
	
	pcvar = create_cvar("jbe_admin_god_round", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_GOD_ROUND]); 
	
	pcvar = create_cvar("jbe_admin_footsteps_round", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_FOOTSTEPS_ROUND]); 
	
	pcvar = create_cvar("jbe_respawn_player_num", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[RESPAWN_PLAYER_NUM]); 
	
	pcvar = create_cvar("jbe_admin_discount_shop", "40", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[ADMIN_DISCOUNT_SHOP]); 
	
	
	pcvar = create_cvar("jbe_access_flag_vip", "t", FCVAR_SERVER, "");
	bind_pcvar_string( pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ 0 ] = read_flags( szFlags );
	
	pcvar = create_cvar("jbe_access_flag_admin", "d", FCVAR_SERVER, "");
	bind_pcvar_string( pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ 1 ] = read_flags( szFlags );
	
	pcvar = create_cvar("jbe_access_flag_superadmin", "q", FCVAR_SERVER, "");
	bind_pcvar_string( pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ 2 ] = read_flags( szFlags );
	
	pcvar = create_cvar("jbe_access_flag_uaio", "r", FCVAR_SERVER, "");
	bind_pcvar_string( pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ 3 ] = read_flags( szFlags );
	
	pcvar = create_cvar("jbe_access_flag_girl", "n", FCVAR_SERVER, "");
	bind_pcvar_string( pcvar, szFlags, charsmax( szFlags ) ); 
	g_iFlags[ 4 ] = read_flags( szFlags );
	
	AutoExecConfig(true, "Jail_AdminMenu");
	
}

public plugin_natives()
{
	register_native("jbe_show_adminmenu", "jbe_show_adminmenu", 1);
	register_native("jbe_is_user_flags", "jbe_is_user_flags", 1);
	register_native("jbe_showmenuadmin", "jbe_showmenuadmin", 1);
	register_native("jbe_jbe_get_discount", "jbe_jbe_get_discount", 1);
	register_native("jbe_status_block", "jbe_status_block", 1);
}

public jbe_status_block(iType)
{
	switch(iType)
	{
		case 0: return g_iBlock[0];
		case 1: return g_iBlock[1];
	}
	return PLUGIN_HANDLED;
}

public jbe_jbe_get_discount(iType) 
{
	switch(iType)
	{
		case 0: return g_iAllCvars[VIP_DISCOUNT_SHOP];
		case 1: return g_iAllCvars[ADMIN_DISCOUNT_SHOP];
	}
	return PLUGIN_HANDLED;
}

public jbe_showmenuadmin(id, i_Flag) {
	switch(i_Flag) {
		case 0: return Show_VipMenu(id);
		case 1: return Show_AdminMenu(id);
		case 2: return Show_SuperAdminMenu(id);
		case 3: return Open_Oaio(id);
	}
	
	return 0;
}

public jbe_show_adminmenu(id) return Show_PrivMenu(id)

public client_putinserver(pId)
{
	new iFlags = get_user_flags(pId);
	
	OnAPIAdminDisconnected(pId);
	//server_print("%d | %s | %d | %d | %d", iFlags, iFlags, get_user_flags(pId), g_iFlags[ Flags_Admins ], read_flags(g_iFlags[ Flags_Admins ]));// new iFlags = get_user_flags(pId);
	if(iFlags & g_iFlags[ Flags_Admins ]) SetBit(g_iBitUserAdmin, pId);
	if(iFlags & g_iFlags[ Flags_UAIO ]) SetBit(g_iBitUserOAIO, pId);
	if(iFlags & g_iFlags[ Flags_Girls ]) SetBit(g_iBitUserGirl, pId);
	if(iFlags & ADMIN_IMMUNITY) SetBit(g_iBitUserImmunity, pId);
	
	//ClearBit(g_iBitUserVip, pId);
	//ClearBit(g_iBitUserOAIO, pId);
	//ClearBit(g_iBitUserAdmin, pId);
	//ClearBit(g_iBitUserGirl, pId);
}

public frallion_access_user(pId, szFlags[])
{
	new iFlags = read_flags(szFlags)
	
	if(iFlags & g_iFlags[ Flags_Admins ]) SetBit(g_iBitUserAdmin, pId);
	if(iFlags & g_iFlags[ Flags_UAIO ]) SetBit(g_iBitUserOAIO, pId);
	if(iFlags & g_iFlags[ Flags_Girls ]) SetBit(g_iBitUserGirl, pId);
	if(iFlags & ADMIN_IMMUNITY) SetBit(g_iBitUserImmunity, pId);
}

public client_disconnected(pId)
{
	if(!is_user_connected(pId)) return;
	#if !defined GAMECMS
	if(IsSetBit(g_iBitUserVip, pId))
	{
		
		g_iVipRespawn[pId] = 0;
		g_iVipHealth[pId] = 0;
		g_iVipMoney[pId] = 0;
		g_iVipInvisible[pId] = 0;
		g_iVipHpAp[pId] = 0;
		g_iVipVoice[pId] = 0;
	}
	if(IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		
		g_iAdminRespawn[pId] = 0;
		g_iAdminHealth[pId] = 0;
		g_iAdminMoney[pId] = 0;
		g_iAdminGod[pId] = 0;
		g_iAdminFootSteps[pId] = 0;
	}
	#endif
	
	ClearBit(g_iBitUserVip, pId);
	ClearBit(g_iBitUserSuperAdmin, pId);
	ClearBit(g_iBitUserAdmin, pId);
	ClearBit(g_iBitUserOAIO, pId);
	ClearBit(g_iBitUserGirl, pId);
	
	if(IsSetBit(g_iBitUserBlock, pId))
	{
		g_iBlock[0] = false;
		g_iBlock[1] = false;
	}
}

#if defined GAMECMS
public OnAPIAdminConnected(pId, const szName[], adminID, iFlags)
{
	OnAPIAdminDisconnected(pId);
	//server_print("%d | %s | %d | %d | %d", iFlags, iFlags, get_user_flags(pId), g_iFlags[ Flags_Admins ], read_flags(g_iFlags[ Flags_Admins ]));// new iFlags = get_user_flags(pId);
	if(iFlags & g_iFlags[ Flags_Admins ]) SetBit(g_iBitUserAdmin, pId);
	if(iFlags & g_iFlags[ Flags_UAIO ]) SetBit(g_iBitUserOAIO, pId);
	if(iFlags & g_iFlags[ Flags_Girls ]) SetBit(g_iBitUserGirl, pId);
	if(iFlags & ADMIN_IMMUNITY) SetBit(g_iBitUserImmunity, pId);
}
#endif

public OnAPIAdminDisconnected(pId)
{
	if(IsSetBit(g_iBitUserVip, pId))
	{
		
		g_iVipRespawn[pId] = 0;
		g_iVipHealth[pId] = 0;
		g_iVipMoney[pId] = 0;
		g_iVipInvisible[pId] = 0;
		g_iVipHpAp[pId] = 0;
		g_iVipVoice[pId] = 0;
	}
	if(IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		
		g_iAdminRespawn[pId] = 0;
		g_iAdminHealth[pId] = 0;
		g_iAdminMoney[pId] = 0;
		g_iAdminGod[pId] = 0;
		g_iAdminFootSteps[pId] = 0;
	}
	
	ClearBit(g_iBitUserVip, pId);
	ClearBit(g_iBitUserSuperAdmin, pId);
	ClearBit(g_iBitUserAdmin, pId);
	ClearBit(g_iBitUserOAIO, pId);
	ClearBit(g_iBitUserGirl, pId);
	ClearBit(g_iBitUserImmunity, pId)
	if(IsSetBit(g_iBitUserBlock, pId))
	{
		g_iBlock[0] = false;
		g_iBlock[1] = false;
	}
}


forward jbe_fwr_logevent_startround();
public jbe_fwr_logevent_startround()
{
	if(jbe_restartgame()) return;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_connected(i)) continue;
		if(IsSetBit(g_iBitUserVip, i))
		{
			g_iVipRespawn[i] = g_iAllCvars[VIP_RESPAWN_NUM];
			g_iVipHealth[i] = g_iAllCvars[VIP_HEALTH_NUM];
			g_iVipMoney[i]++;
			g_iVipInvisible[i]++;
			g_iVipHpAp[i]++;
			g_iVipVoice[i]++;
		}
		if(IsSetBit(g_iBitUserSuperAdmin, i))
		{
			g_iAdminRespawn[i] = g_iAllCvars[ADMIN_RESPAWN_NUM];
			g_iAdminHealth[i] = g_iAllCvars[ADMIN_HEALTH_NUM];
			g_iAdminMoney[i]++;
			g_iAdminGod[i]++;
			g_iAdminFootSteps[i]++;
		}
	}
	
}


Show_PrivMenu(pId)
{
	new szMenu[512], iKeys = (1<<1|1<<8|1<<9), iLen;

	new szPlayerAcces[64];
	#if defined GAMECMS
	new szData[32]
	new expired = cmsapi_service_timeleft(pId);
	if(jbe_is_user_flags(pId, FLAGSENABLED))
	{
		new sys = get_systime();
		if(expired == 0)
		{
			formatex(szPlayerAcces, charsmax(szPlayerAcces), "Срок ваших до: До скончание веков", szData);
		}
		else
		if((expired - sys) / 86400 > 0)
		{
			formatex(szPlayerAcces, charsmax(szPlayerAcces), "Права истекают через \y%d \rдн.",(expired - sys) / 86400);
		}
		else formatex(szPlayerAcces, charsmax(szPlayerAcces), "У вас последний день.");
	}
	else 
	if(jbe_is_user_vip(pId) == 1)
	{
		formatex(szPlayerAcces, charsmax(szPlayerAcces), "У вас FreeVip");
	}else formatex(szPlayerAcces, charsmax(szPlayerAcces), "Сайт для покупки: Frallion.ru");
	
	/*if(cmsapi_service_timeleft(pId, szData, 31) > 0)
	{
		if(strlen(szData) > 1)
		{
			formatex(szPlayerAcces, charsmax(szPlayerAcces), "Срок ваших услуг до: %s", szData);
		}else formatex(szPlayerAcces, charsmax(szPlayerAcces), "Сайт для покупки: Fraggers.ru");
	}else formatex(szPlayerAcces, charsmax(szPlayerAcces), "Срок ваших услуг до: скончание веков");
	*/
	#endif
	
	FormatMain("\yМеню привилегии^n\r%s^n^n",szPlayerAcces);
	
	if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2))
	{
		FormatItem("\y1. \wМеню Випа^n");
		iKeys |= (1<<0);
	}else FormatItem("\y1. \dМеню Випа^n");
	

	FormatItem("\y2. \wМеню Админа^n");

	
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		FormatItem("\y3. \wМеню Глобальное^n");
		iKeys |= (1<<2);
	}else FormatItem("\y3. \dМеню Глобальное^n");
	
	//FormatItem("\y4. \wМеню Скинов^n"),iKeys |= (1<<3);


	FormatItem("^n^n\y0. \wВыход");

	return show_menu(pId, iKeys, szMenu, -1, "Show_PrivMenu");
}

public Handle_PrivMenu(pId, iKey)
{
	switch(iKey)
	{
		//case 0: if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)) return Show_VipMenu(pId);
		case 0: return jbe_open_vipmenu(pId);
		case 1: return Show_AdminMenu(pId);
		//case 2: if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)) return Show_SuperAdminMenu(pId);
		case 2: 
		{	
			if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)) 
			{
				if(IsSetBit(g_iBitUserOAIO, pId))
					return Open_Oaio(pId);
				else return Show_OtherUaio(pId);
			}
		}
		case 3: return client_cmd(pId, "say /skin");
		//case 5: return Show_AdvertMenu(pId);
		
		case 9: return PLUGIN_HANDLED;
	}
	return Show_PrivMenu(pId);
}

Show_OtherUaio(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yГлобальное меню^n^n");
	
	FormatItem("\y1. \dВспомогательные команды^n");
	FormatItem("\y2. \dНаказательные команды^n");
	FormatItem("\y3. \dРазные команды^n");
	FormatItem("\y4. \dВернуть к стандарту^n^n");
	FormatItem("\y5. \rСбросить все^n");
	FormatItem("\y6. \dРедактор жизни^n");
	FormatItem("\y7. \dДополнительно^n");
	FormatItem("\y8. \wГлобальные игры^n^n");
	
	FormatItem("\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_OtherUaio");
}

public Handle_OtherUaio(pId, iKey) 
{
	switch(iKey)
	{
		case 8: return Show_PrivMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

Show_VipMenu(pId)
{
	if(jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2 || jbe_menu_blocked(pId)) return PLUGIN_HANDLED;
	
	if(jbe_globalnyizapret() && jbe_get_chief_id() != pId)
	{
		UTIL_SayText(pId, "!g* !yВо время глоабльного режима, привилегия запрещена");
		return PLUGIN_HANDLED;
	}
	
	new szMenu[512], iKeys = (1<<8|1<<9), iAlive = jbe_is_user_alive(pId),  iLen;
	
	FormatMain("\yВип меню^n^n");
	
	if(IsNotSetBit(g_iBitUserVip, pId))
	{
		FormatItem("\y1. \dВоскреснуть \r[%d]^n", g_iVipRespawn[pId]);
	}
	else
	if(iAlive)
	{
		FormatItem("\y1. \dВоскреснуть \r[Вы живы]^n");
	}
	else
	if(!g_iVipRespawn[pId])
	{
		FormatItem("\y1. \dВоскреснуть \r[Ждите 1 рнд.]^n");
	}
	else
	if(jbe_aliveplayersnum(jbe_get_user_team(pId)) <= g_iAllCvars[RESPAWN_PLAYER_NUM])
	{
		FormatItem("\y1. \dВоскреснуть \r[Мало игроков]^n");
	}
	else
	{
		FormatItem("\y1. \wВоскреснуть^n");
		iKeys |= (1<<0);
	}
	
	if(IsNotSetBit(g_iBitUserVip, pId))
	{
		FormatItem("\y2. \dПодлечиться \r[%d]^n", g_iVipHealth[pId]);
	}
	else
	if(!iAlive)
	{
		FormatItem("\y2. \dПодлечиться \r[Вы мертвы]^n");
	}
	else
	if(!g_iVipHealth[pId])
	{
		FormatItem("\y2. \dПодлечиться \r[Ждите 1 рнд.]^n");
	}
	else
	if(get_user_health(pId) >= 100)
	{
		FormatItem("\y2. \dПодлечиться \r[HP в норме]^n");
	}
	else
	{
		FormatItem("\y2. \wПодлечиться^n");
		iKeys |= (1<<1);
	}
	
	
	
	if(IsNotSetBit(g_iBitUserVip, pId))
	{
		FormatItem("\y3. \dПолучить - %d$^n" ,g_iAllCvars[VIP_MONEY_NUM]);
	}
	else
	if(g_iVipMoney[pId] <= g_iAllCvars[VIP_MONEY_ROUND])
	{
		new iCount = (g_iAllCvars[VIP_MONEY_ROUND] - g_iVipMoney[pId]);
		FormatItem("\y3. \dПолучить - %d$ \r[Ждите еще %d рнд.]^n" , g_iAllCvars[VIP_MONEY_NUM], iCount + 1);
	
	}
	else
	{
		FormatItem("\y3. \wПолучить - %d$^n", g_iAllCvars[VIP_MONEY_NUM]);
		iKeys |= (1<<2);
	}

	if(IsNotSetBit(g_iBitUserVip, pId))
	{
		FormatItem("\y4. \dФорма заключенного^n");
	}
	else
	if(jbe_get_user_team(pId) != 2)
	{
		FormatItem("\y4. \dПереодеть форму \r[Для охраны]^n");
	}
	else
	if(!iAlive)
	{
		FormatItem("\y4. \dФорма заключенного \r[Вы мертвы]^n");
	}
	else
	if(g_iVipInvisible[pId] <= g_iAllCvars[VIP_INVISIBLE])
	{
		new iCount = (g_iAllCvars[VIP_INVISIBLE] - g_iVipInvisible[pId]);
		FormatItem("\y4. \dФорма заключенного \r[Ждите %d рнд.]^n", iCount + 1);
	}
	else
	{
		FormatItem("\y4. \wФорма заключенного^n");
		iKeys |= (1<<3);
	}


	if(IsNotSetBit(g_iBitUserVip, pId))
	{
		FormatItem("\y5. \dДоп. Жизни - T|CT|CHIEF ^n");
	}
	else
	if(!iAlive)
	{
		FormatItem("\y5. \dДоп. Жизни - T|CT|CHIEF \r[Вы мертвы]^n");
	}
	else
	if(g_iVipHpAp[pId] <= g_iAllCvars[VIP_HP_AP_ROUND])
	{
		new iCount = (g_iAllCvars[VIP_HP_AP_ROUND] - g_iVipHpAp[pId]);
		FormatItem("\y5. \dДоп. Жизни - T|CT|CHIEF \r[Ждите еще %d рнд.]^n", iCount + 1);
	}
	else
	{
		switch(jbe_get_user_team(pId))
		{
			case 1: FormatItem("\y5. \wДля зека - 200HP^n");
			case 2:
			{
				if(jbe_is_user_chief(pId))
				{
					FormatItem("\y5. \wДля начальника - 500HP^n");
				}
				else
				FormatItem("\y5. \wДля охраны - 255HP^n");
			}
		}
		iKeys |= (1<<4);
	}
	
	
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_VipMenu");
}

public Handle_VipMenu(pId, iKey)
{
	if(iKey == 8)
		return Show_PrivMenu(pId);
		
	if(jbe_globalnyizapret() && jbe_get_chief_id() != pId)
	{
		UTIL_SayText(pId, "!g* !yВо время глоабльного режима, привилегия запрещена");
		return PLUGIN_HANDLED;
	}
		
	
	if((jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2) || IsNotSetBit(g_iBitUserVip, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			if(!jbe_is_user_alive(pId) && g_iVipRespawn[pId] && jbe_aliveplayersnum(jbe_get_user_team(pId)) >= g_iAllCvars[RESPAWN_PLAYER_NUM])
			{
				ExecuteHamB(Ham_CS_RoundRespawn, pId);
				g_iVipRespawn[pId]--;
				UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yвоскреснулся.", pId);
			}
		}
		case 1:
		{
			if(jbe_is_user_alive(pId) && g_iVipHealth[pId]  && get_user_health(pId) < 100)
			{
				set_pev(pId, pev_health, 100.0);
				g_iVipHealth[pId]--;
				UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yподлечился.", pId);
			}
		}
		case 2:
		{
			//jbe_set_user_money(pId, jbe_get_user_money(pId) + g_iAllCvars[VIP_MONEY_NUM], 1);
			jbe_set_butt(pId, jbe_get_butt(pId) + g_iAllCvars[VIP_MONEY_NUM]);
			g_iVipMoney[pId] = 0;
			UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yвзял !g%dбычков.", pId, g_iAllCvars[VIP_MONEY_NUM]);
		}
		case 3:
		{
			if(jbe_is_user_alive(pId) && jbe_get_user_team(pId) == 2)
			{
				jbe_set_user_model_ex(pId, 1);
				g_iVipInvisible[pId] = 0;
				
			}
		}
		case 4:
		{
			if(jbe_is_user_alive(pId))
			{
				switch(jbe_get_user_team(pId))
				{
					case 1: 
					{
						set_pev(pId, pev_health, 200.0);
						UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yвзял !g200HP$.", pId);
					}
					case 2:
					{
						if(jbe_is_user_chief(pId))
						{
							set_pev(pId, pev_health, 500.0);
							UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yвзял !g500HP$.", pId);
						}else 
						{
							set_pev(pId, pev_health, 255.0);
							UTIL_SayText(0, "!g[VIP] !yИгрок !g%n !yвзял !g255HP$.", pId);
						}
					}
				}
				g_iVipHpAp[pId] = 0;
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_VipMenu(pId);
}

Show_AdminMenu(pId)
{
	if(jbe_menu_blocked(pId)) return PLUGIN_HANDLED;
	
	new szMenu[512], iKeys = (1<<9),  iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_ADMIN_TITLE");
	
	FormatItem("\y1. %sКикнуть игрока^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y2. %sМеню блокировки^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y3. %sУбить игрока^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y4. %sПеревод игрока^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y5. %sГолосование за смену карт^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y6. %sВыдать голос^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
	FormatItem("\y7. %sВыдать Свободный день^n", IsSetBit(g_iBitUserAdmin, pId) ? "\w" : "\d");
		
	if(IsSetBit(g_iBitUserAdmin, pId))
	{
		iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4|1<<7);
	}

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_AdminMenu");
}

public Handle_AdminMenu(pId, iKey)
{
		
	if(IsNotSetBit(g_iBitUserAdmin, pId)) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0: return jbe_show_teammenu(pId, 4);
		case 1: return Show_BanMenu(pId);
		case 2: return jbe_show_teammenu(pId, 3);
		case 3: return jbe_show_teammenu(pId, 1);
		case 4: client_cmd(pId, "amx_votemapmenu");
		case 5: return Cmd_VoiceControlMenu(pId);
		case 6: return Cmd_FreeDayControlMenu(pId);
		
		case 9: return Show_PrivMenu(pId);
	}
	return PLUGIN_HANDLED;
}

Show_BanMenu(pId)
{
	if(jbe_menu_blocked(pId)) return PLUGIN_HANDLED;
	
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9),  iLen;
	
	FormatMain("\yВыберите типа бана^n^n");

	FormatItem("\y1. \wОнлайн бан^n");
	FormatItem("\y3. \wОффлайн бан^n");
	FormatItem("\y3. \wОнлайн мут^n");
	FormatItem("\y4. \wОффлайн мут^n");
	FormatItem("\y5. \yДополнительные Блоки^n^n");
	
	
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_BanMenu");
}

public Handle_BanMenu(pId, iKey)
{
		
	if(IsNotSetBit(g_iBitUserAdmin, pId)) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0: client_cmd(pId, "amx_banmenu");
		case 1: client_cmd(pId, "amx_disconnectmenu");
		case 2: client_cmd(pId, "amx_gagmenu");
		case 3: client_cmd(pId, "amx_ungagmenu");
		case 4: return Show_ZapretMenu(pId);
		//case 8: return Show_AdminMenu(pId);
		case 9: return Show_AdminMenu(pId);
	}
	return PLUGIN_HANDLED;
}


Show_SuperAdminMenu(pId)
{
	if(jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2 || jbe_menu_blocked(pId)) return PLUGIN_HANDLED;
	
	if(jbe_globalnyizapret() && jbe_get_chief_id() != pId)
	{
		UTIL_SayText(pId, "!g* !yВо время глоабльного режима, привилегия запрещена");
		return PLUGIN_HANDLED;
	}
	
	new szMenu[512], iKeys = (1<<8|1<<9), iAlive = jbe_is_user_alive(pId),  iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_SUPER_ADMIN_TITLE");
	if(!iAlive && g_iAdminRespawn[pId] && jbe_aliveplayersnum(jbe_get_user_team(pId)) >= g_iAllCvars[RESPAWN_PLAYER_NUM] && IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y1. \w%L^n", pId, "JBE_MENU_SUPER_ADMIN_RESPAWN");
		iKeys |= (1<<0);
	}
	else FormatItem("\y1. \d%L^n", pId, "JBE_MENU_SUPER_ADMIN_RESPAWN");
	if(iAlive && g_iAdminHealth[pId] && get_user_health(pId) < 100 && IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y2. \w%L^n", pId, "JBE_MENU_SUPER_ADMIN_HEALTH");
		iKeys |= (1<<1);
	}
	else FormatItem("\y2. \d%L^n", pId, "JBE_MENU_SUPER_ADMIN_HEALTH");
	if(g_iAdminMoney[pId] >= g_iAllCvars[ADMIN_MONEY_ROUND] && IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y3. \w%L^n", pId, "JBE_MENU_SUPER_ADMIN_MONEY", g_iAllCvars[ADMIN_MONEY_NUM]);
		iKeys |= (1<<2);
	}
	else FormatItem("\y3. \d%L^n", pId, "JBE_MENU_SUPER_ADMIN_MONEY", g_iAllCvars[ADMIN_MONEY_NUM]);
	if(iAlive && jbe_get_chief_id() == pId && g_iAdminGod[pId] >= g_iAllCvars[ADMIN_GOD_ROUND] && IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y4. \w%L^n", pId, "JBE_MENU_SUPER_ADMIN_GOD");
		iKeys |= (1<<3);
	}
	else FormatItem("\y4. \d%L^n", pId, "JBE_MENU_SUPER_ADMIN_GOD");
	if(iAlive && g_iAdminFootSteps[pId] >= g_iAllCvars[ADMIN_FOOTSTEPS_ROUND] && IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y5. \w%L^n", pId, "JBE_MENU_SUPER_ADMIN_FOOTSTEPS");
		iKeys |= (1<<4);
	}
	else FormatItem("\y5. \d%L^n", pId, "JBE_MENU_SUPER_ADMIN_FOOTSTEPS");
	
/*	if(IsSetBit(g_iBitUserSuperAdmin, pId))
	{
		FormatItem("\y6. \w%L^n^n^n", pId, "JBE_MENU_SUPER_ADMIN_BLOCKED_GUARD");
		iKeys |= (1<<5);
	}*/
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_SuperAdminMenu");
}

public Handle_SuperAdminMenu(pId, iKey)
{
	if(iKey == 8)
		return Show_PrivMenu(pId);
		
	if(jbe_globalnyizapret() && jbe_get_chief_id() != pId)
	{
		UTIL_SayText(pId, "!g* !yВо время глоабльного режима, привилегия запрещена");
		return PLUGIN_HANDLED;
	}
		
	if((jbe_get_day_mode() != 1 && jbe_get_day_mode() != 2) || IsNotSetBit(g_iBitUserSuperAdmin, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			if(!jbe_is_user_alive(pId) && g_iAdminRespawn[pId] && jbe_aliveplayersnum(jbe_get_user_team(pId)) >= g_iAllCvars[RESPAWN_PLAYER_NUM])
			{
				ExecuteHamB(Ham_CS_RoundRespawn, pId);
				g_iAdminRespawn[pId]--;
				UTIL_SayText(0, "!g[SuperAdmin] !yИгрок !g%n !gвоскресился.", pId);
			}
		}
		case 1:
		{
			if(jbe_is_user_alive(pId) && g_iAdminHealth[pId]  && get_user_health(pId) < 100)
			{
				set_pev(pId, pev_health, 100.0);
				g_iAdminHealth[pId]--;
				UTIL_SayText(0, "!g[SuperAdmin] !yИгрок !g%n !gподлечился.", pId);
			}
		}
		case 2:
		{
			//jbe_set_user_money(pId, jbe_get_user_money(pId) + g_iAllCvars[ADMIN_MONEY_NUM], 1);
			jbe_set_butt(pId, jbe_get_butt(pId) + g_iAllCvars[ADMIN_MONEY_NUM]);
			g_iAdminMoney[pId] = 0;
			UTIL_SayText(0, "!g[SuperAdmin] !yИгрок !g%n !yвзял !g%dбычков.", pId, g_iAllCvars[ADMIN_MONEY_NUM]);
		}
		case 3:
		{
			if(jbe_is_user_alive(pId) && jbe_get_chief_id() == pId)
			{
				set_user_godmode(pId, 1);
				g_iAdminGod[pId] = 0;
				UTIL_SayText(0, "!g[SuperAdmin] !yНачальника !g%n !yвзял !gбессмертие.", pId);
			}
		}
		case 4:
		{
			if(jbe_is_user_alive(pId))
			{
				set_user_footsteps(pId, 1);
				g_iAdminFootSteps[pId] = 0;
				UTIL_SayText(0, "!g[SuperAdmin] !yИгрок !g%n !yвзял !gбесшумные шаги.", pId);
			}
			
		}
		//case 5: return jbe_blockedguardmenu(pId);
		
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}




public jbe_is_user_flags(id, i_Flag) 
{
	switch(i_Flag) 
	{
		case FLAGSVIP: return IsSetBit(g_iBitUserVip, id);
		case FLAGSADMIN: return IsSetBit(g_iBitUserAdmin, id);
		case FLAGSSUPERADMIN: return IsSetBit(g_iBitUserSuperAdmin, id);
		case FLAGSUAIO: return IsSetBit(g_iBitUserOAIO, id);
		case FLAGSGIRL: return IsSetBit(g_iBitUserGirl, id);
		case FLAGSENABLED: 
		{
			if(	IsSetBit(g_iBitUserVip, id) || 
				IsSetBit(g_iBitUserAdmin, id) || 
				IsSetBit(g_iBitUserSuperAdmin, id) || 
				IsSetBit(g_iBitUserOAIO, id) || 
				IsSetBit(g_iBitUserGirl, id) || jbe_is_user_vip(id) > 1) 
					return 1;
			else return 0;
		}
		case FLAGSIMMUNITY: return IsSetBit(g_iBitUserImmunity, id);
	}
	return 0;
}

Show_ZapretMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yДополнительные Блоки^n^n");
	
	FormatItem("\y1. \wДоступ к магазину: \r[%s]^n", g_iBlock[0] ? "Заблокирован" : "Разблокирован"), iKeys |= (1<<0);
	FormatItem("\y2. \wДоступ за охрану: \r[%s]^n", g_iBlock[1] ? "Заблокирован" : "Разблокирован"), iKeys |= (1<<1);
	FormatItem("\y3. \wБлок чата+голос^n"), iKeys |= (1<<2);
	FormatItem("\y4. \wБлок за Кт^n"), iKeys |= (1<<3);
	
	//FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("^n^n^n\y0. \wНазад^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ZapretMenu");
}

public Handle_ZapretMenu(pId, iKey) 
{
	switch(iKey)
	{
		case 0: 
		{
			g_iBlock[0] = !g_iBlock[0];
			UTIL_SayText(0, "!g* !yАдминистратор %n !g%s !yмагазин", pId, g_iBlock[0] ? "Заблокирован" : "Разблокирован")
			
			switch(g_iBlock[0])
			{
				case true: SetBit(g_iBitUserBlock, pId)
				case false: ClearBit(g_iBitUserBlock, pId)
			}
		}
		case 1: 
		{
			g_iBlock[1] = !g_iBlock[1];
			UTIL_SayText(0, "!g* !yАдминистратор %n !g%s !yвход за охрану", pId, g_iBlock[1] ? "Заблокирован" : "Разблокирован")
			switch(g_iBlock[1])
			{
				case true: SetBit(g_iBitUserBlock, pId)
				case false: ClearBit(g_iBitUserBlock, pId)
			}
		}
		case 2: 
		{
			client_cmd(pId, "amx_gagmenu");
		}
		case 3:
		{
			client_cmd(pId, "block_guard");
		}
		
	//	case 8: return Show_AdminMenu(pId);
		case 9: return Show_BanMenu(pId);
	}
	return Show_ZapretMenu(pId);
}


Show_AdvertMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yО сервере^n^n");
	
	FormatItem("\y1. \wПокупка привилегии^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wИнфа о сервере^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wИнфа о сборке^n"), iKeys |= (1<<2);
	FormatItem("^n\y4. \wВывести в консоль^n"), iKeys |= (1<<3);
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_AdvertMenu");
}

public Handle_AdvertMenu(pId, iKey) 
{
	switch(iKey)
	{
		case 0: return Show_AdvertMenu_1(pId);
		case 1: return Show_AdvertMenu_2(pId);
		case 2: return Show_AdvertMenu_3(pId);
		case 3: Show_AdwertChat(pId);
		
		case 8: return client_cmd(pId, "rulesmenu");
		case 9: return PLUGIN_HANDLED;
	}
	return Show_AdvertMenu(pId);
}

Show_AdvertMenu_1(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yО сервере^n^n");
	
	FormatItem("\y1. \yПокупка привилегии^n\
					^t^t\dГл.Администратор: \rBaHek^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wИнфа о сервере^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wИнфа о сборке^n"), iKeys |= (1<<2);
	FormatItem("^n\y4. \wВывести в консоль^n"), iKeys |= (1<<3);
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_AdvertMenu_1");
}

public Handle_AdvertMenu_1(pId, iKey) 
{
	switch(iKey)
	{
		case 0: return Show_AdvertMenu_1(pId);
		case 1: return Show_AdvertMenu_2(pId);
		case 2: return Show_AdvertMenu_3(pId);
		case 3: Show_AdwertChat(pId);
		
		case 8: return Show_PrivMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_AdvertMenu(pId);
}

Show_AdvertMenu_2(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yО сервере^n^n");
	
	FormatItem("\y1. \wПокупка привилегии^n"), iKeys |= (1<<0);
	FormatItem("\y2. \yИнфа о сервере^n\
					^t^t\dIP Адресс: \r46.174.49.39:27331^n\
					^t^t\dWebSite Сервера: \rFrallion.ru^n"), iKeys |= (1<<1);

	FormatItem("\y3. \wИнфа о сборке^n"), iKeys |= (1<<2);
	FormatItem("^n\y4. \wВывести в консоль^n"), iKeys |= (1<<3);
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_AdvertMenu_2");
}

public Handle_AdvertMenu_2(pId, iKey) 
{
	switch(iKey)
	{
		case 0: return Show_AdvertMenu_1(pId);
		case 1: return Show_AdvertMenu_2(pId);
		case 2: return Show_AdvertMenu_3(pId);
		case 3: Show_AdwertChat(pId);
		
		case 8: return Show_PrivMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_AdvertMenu(pId);
}

Show_AdvertMenu_3(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	FormatMain("\yО сервере^n^n");
	
	FormatItem("\y1. \wПокупка привилегии^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wИнфа о сервере^n"), iKeys |= (1<<1);
	FormatItem("\y3. \yИнфа о сборке^n\
					^t^t\dАвтор сборки: \rДастан Такешев^n\
					^t^t\dNickName: \rDalgaPups^n\
					^t^t\dСвязь в ВК: \rtakeshev^n"), iKeys |= (1<<2);
	FormatItem("^n\y4. \wВывести в консоль^n"), iKeys |= (1<<3);
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	return show_menu(pId, iKeys, szMenu, -1, "Show_AdvertMenu_3");
}

public Handle_AdvertMenu_3(pId, iKey) 
{
	switch(iKey)
	{
		case 0: return Show_AdvertMenu_1(pId);
		case 1: return Show_AdvertMenu_2(pId);
		case 2: return Show_AdvertMenu_3(pId);
		
		case 3: Show_AdwertChat(pId);

		case 8: return client_cmd(pId, "rulesmenu");
		case 9: return PLUGIN_HANDLED;
	}
	return Show_AdvertMenu(pId);
}

public Show_AdwertChat(pId)
{
	UTIL_SayText(pId, "!g* !yВся необходимая информации выведено в консоль !g(` ~ Тильда)");
	client_print(pId,print_console,"*********IP Adress: 46.174.49.39:27331");  
	client_print(pId,print_console,"*********WebSite: Frallion.ru");  
}


