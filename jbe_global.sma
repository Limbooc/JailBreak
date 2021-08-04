#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <jbe_core>
#include <engine>

new g_iGlobalDebug;
#include <util_saytext>

#define ACCESS ADMIN_LEVEL_F

#pragma semicolon 1

native jbe_set_formatex_daymode(iDay);
//native find_sphere_class(aroundent, const _lookforclassname[], Float:radius, entlist[], maxents, const Float:origin[3] = {0.0, 0.0, 0.0});


#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

new bool:g_iSwitch[20];
new bool:g_iOtherSwitch[7];
new bool:g_iStatusGlboal;
new bool:g_iGlobal;
new bool:g_iEndRound;

new bool:plrSolid[MAX_PLAYERS + 1];
new bool:plrRestore[MAX_PLAYERS + 1];
new plrTeam[MAX_PLAYERS + 1];

new HookChain:HookPlayer_TakeDamageFall,
	HookChain:HookPlayer_PlayerTakeDamage,
	HookChain:HookPlayer_PlayerTraceAttack,
	HookChain:HookPlayer_TakeDamageVelocity[2];

new g_iFakeMetaEmitSound,
	g_iFakeMetaKillConsole;

native Open_Oaio(pId);
native jbe_remove_shop_pn(iPlayer);
native jbe_set_user_skin(pId, iNum);
native jbe_get_user_skin(pId);
native jbe_open_creator_boxes(pId);

native jbe_set_user_costumes(pId, iCostume);
native jbe_get_user_costumes(pId);
native jbe_hide_user_costumes(pId);

const MsgId_RadarMsg = 112;


new g_iFakeMetaPreThink,
    g_iFakeMetaPostThink,
    g_iFakeMetaFullPack;

new g_iFwdResetFlags;

new float:v_velocity[3];
//new g_iAddToFullPack;

/* -> Массивы для работы с событиями 'hamsandwich' -> */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"func_button", // Кнопка
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield", // Щит
	"trigger_push",
	"trigger_teleport"
	
};
new HamHook:g_iHamHookForwards[14];
new HookChain:g_iHookChainStartSound;

new const g_iButtonSwitchOn[][] =
{
	"управление над машинами",
	"управление над поездами",
	"управление над пушками",
	"нанесение повреждение при касание",
	"увелечение запаза бронежилета (Аптечки и тд)",
	"увелечение процента здоровье (Аптечки и тд)",
	"использование кнопок",
	"повреждение от касание объекта (Кнопки снимающие ХП)",
	"получение гравитации при касание",
	"поднятие объектов (броня , гранаты и тд)",
	"поднятие брошенной оружии",
	"использование щита",
	"касание батута",
	"касание телепорта",
	"от падение с высоты",
	"звук удара с кулака",
	"урон по всем = 0",
	"самоубиство",
	"проход сквозь игроков",
	"подниматься по лестнице",
	"радара",
	"удаление оружие после дропа",
	"видимость шапок",
	"видимость ник игрока",
	"замедление от пуль"
};


public plugin_init()
{
	register_plugin("[JBE] Global", "1.0", "DalgaPups");
	
	register_menucmd(register_menuid("Show_MainGlobalmenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_MainGlobalmenu");
	register_menucmd(register_menuid("Show_DisableEvent"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_DisableEvent");
	register_menucmd(register_menuid("Show_TWO_DisableEvent"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_TWO_DisableEvent");
	register_menucmd(register_menuid("Show_Three_DisableEvent"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_Three_DisableEvent");
	register_menucmd(register_menuid("Show_Four_DisableEvent"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_Four_DisableEvent");
	register_menucmd(register_menuid("Show_GlobalGame"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GlobalGame");
	
	
	for(new i; i <= 6; i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, 		g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
	for(new i = 7; i < sizeof(g_szHamHookEntityBlock); i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, 	g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
		
	DisableHookChain(HookPlayer_TakeDamageFall = 		RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Fall", false));
	DisableHookChain(HookPlayer_PlayerTakeDamage = 		RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_PlayerTakeDamage", false));
	DisableHookChain(HookPlayer_PlayerTraceAttack = 	RegisterHookChain(RG_CBasePlayer_TraceAttack, 		"HC_CBasePlayer_PlayerTraceAttack", false));
	
	DisableHookChain(HookPlayer_TakeDamageVelocity[0] = 		RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Velocity_Pre", false));
	DisableHookChain(HookPlayer_TakeDamageVelocity[1] = 		RegisterHookChain(RG_CBasePlayer_TakeDamage, 		"HC_CBasePlayer_TakeDamage_Velocity_Post", true));
		
	register_clcmd("globalka", "jbe_open_globalmenu");
	
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	g_iFakeMetaEmitSound = 		register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
	g_iFakeMetaKillConsole = 	register_forward( FM_ClientKill, "ClCmd_Kill" );
	g_iFakeMetaPreThink = 		register_forward(FM_PlayerPreThink, "preThink");
	g_iFakeMetaPostThink = 		register_forward(FM_PlayerPostThink, "postThink");
	g_iFakeMetaFullPack = 		register_forward(FM_AddToFullPack, "addToFullPack", 1);

	unregister_forward(FM_PlayerPreThink, g_iFakeMetaPreThink);
	unregister_forward(FM_PlayerPostThink, g_iFakeMetaPostThink);
	unregister_forward(FM_AddToFullPack, g_iFakeMetaFullPack, 1);

	unregister_forward(FM_ClientKill, g_iFakeMetaKillConsole, false);
	unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound);


	RegisterHookChain(RG_PM_Move, "Client_Func_Ladder", false);

	register_message(MsgId_RadarMsg, "message_radar"); 
	
	g_iFwdResetFlags = CreateMultiForward("jbe_reset_all_user_flags", ET_CONTINUE, FP_CELL) ;
	
	

	RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "refwd_PlayerImpulseCommands_Pre");
    RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "refwd_PlayerImpulseCommands_Post", true);
    DisableHookChain(g_iHookChainStartSound = RegisterHookChain(RH_SV_StartSound, "refwd_SV_StartSound_Pre", false));

	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	set_cvar_num("mp_unduck_method", 0);
}

public plugin_end()
{
	DestroyForward(g_iFwdResetFlags);

}
public jbe_open_globalgame(pId) return Show_GlobalGame(pId);

public message_radar()
{
	if(g_iOtherSwitch[5])
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public plugin_natives()
{
	register_native("jbe_global_status", "jbe_global_status", 1);
	register_native("jbe_global_get_switch", "jbe_global_get_switch", 1);
	register_native("jbe_open_globalmenu", "jbe_open_globalmenu", 1);
	register_native("jbe_globalnyizapret", "jbe_globalnyizapret", 1);
	register_native("jbe_global_games", "jbe_global_games", 1);
}

public jbe_global_games(pId, iType)
{
	switch(iType)
	{
		case 0: return Show_GlobalGame(pId);
		case 1: return Show_GlobalGame(pId);
	}
	return 0;

}
public jbe_globalnyizapret() return g_iStatusGlboal;

public jbe_global_status(iType) return g_iSwitch[iType];
public jbe_global_get_switch(iType) return g_iOtherSwitch[iType];

public FakeMeta_EmitSound(pId, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(jbe_is_user_valid(pId))
	{
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e' && g_iOtherSwitch[0])
		{
			emit_sound(pId, iChannel, "jb_engine/weapons/hand_hit3.wav", 0.0, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public LogEvent_RoundEnd() 
{
	if(g_iStatusGlboal)	
	{
		g_iStatusGlboal = false;
		jbe_set_formatex_daymode(1);
		set_cvar_num("mp_unduck_method", 0);
		
		new g_ForwardResult;
		ExecuteForward(g_iFwdResetFlags , g_ForwardResult, g_iStatusGlboal);
	}
	if(g_iGlobal) 
	{
		ExDisableEvent();
		g_iGlobal = false;
	}
	g_iEndRound = true;
}

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iEndRound = false;
}
	
public ClCmd_Kill(pId)
{
	if( !is_user_alive(pId) && is_user_connected(pId))
		return FMRES_IGNORED;

	client_print(pId, print_console, "Стоит глобальный запрет на самоубиство");
	return FMRES_SUPERCEDE;
}



public ExDisableEvent()
{

	
	for(new i; i < sizeof(g_iSwitch); i++) 
	{
		g_iSwitch[i] = false;
	}
	for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
	
	for(new i; i < sizeof(g_iOtherSwitch); i++) 
	{
		g_iOtherSwitch[i] = false;
	}
	
	DisableHookChain(HookPlayer_TakeDamageFall);
	DisableHookChain(HookPlayer_PlayerTakeDamage);
	DisableHookChain(HookPlayer_PlayerTraceAttack);
	DisableHookChain(HookPlayer_TakeDamageVelocity[0]);
	DisableHookChain(HookPlayer_TakeDamageVelocity[1]);
	unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound, true);
	unregister_forward(FM_ClientKill, g_iFakeMetaKillConsole, true);

	unregister_forward(FM_PlayerPreThink, g_iFakeMetaPreThink);
	unregister_forward(FM_PlayerPostThink, g_iFakeMetaPostThink);
	unregister_forward(FM_AddToFullPack, g_iFakeMetaFullPack, 1);
	
	
	//jbe_set_day_mode(1);
	
	
}

public HC_CBasePlayer_TakeDamage_Fall(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(iBitDamage == DMG_FALL && g_iSwitch[14])
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerTakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker) && jbe_get_user_team(iAttacker) && g_iOtherSwitch[1])
	{
		/*if(iBitDamage & (1<<24)) // DMG_HEGRENADE
		{
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}*/
		SetHookChainReturn(ATYPE_INTEGER, false);
	}
	return HC_CONTINUE;

}
public HC_CBasePlayer_PlayerTraceAttack(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker) && jbe_get_user_team(iAttacker) && g_iOtherSwitch[1])
	{
		SetHookChainArg(3, ATYPE_FLOAT, 0.0);
	}
	return HC_CONTINUE;
}


native zl_boss_map();

public jbe_open_globalmenu(pId)
{
	if(jbe_get_day_mode() == 3)
	{
		return PLUGIN_HANDLED;
	}
	if(zl_boss_map()) 
	{
		return PLUGIN_HANDLED;
	}
	if(get_user_flags(pId) & ACCESS /*&& pId == jbe_get_chief_id()*/) 
	{
		return Show_MainGlobalmenu(pId);
	}
	
	UTIL_SayText(pId, "!g* !yУ вас недостаточно прав!");
	return PLUGIN_HANDLED;
}
public HamHook_EntityBlock(iEntity, pId)
{
	if(jbe_is_user_valid(pId) && jbe_get_user_team(pId) == 1)
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

Show_GlobalGame(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yГлобальные Игры^n^n");
	
	FormatItem("\y1. \wКрестовый поход^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wМафия^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wБитва за Джихад^n"), iKeys |= (1<<2);

	
	FormatItem("^n^n\y9. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_GlobalGame");

}

public Handle_GlobalGame(pId, iKey)
{
	switch(iKey)
	{
		case 0: return client_cmd(pId, "crusader");
		case 1: return client_cmd(pId, "mafia");
		case 2: return client_cmd(pId, "djihad");
		
		case 8: return Show_MainGlobalmenu(pId);
		case 9: return PLUGIN_HANDLED;
	
	
	}

	return Show_GlobalGame(pId);
}


Show_MainGlobalmenu(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yГлобально меню^n\dв консоле ^"globalka^"^n^n");
	
	if(jbe_get_chief_id() == pId)
	{
		FormatItem("\y1. \wГлоабльный режим \r%s^n",g_iStatusGlboal ? "Включен": "Выключен"), iKeys |= (1<<0);
	}else FormatItem("\y1. \dГлоабльный режим - \rДоступен только ведущему^n");
	
	FormatItem("\y2. \r%s \wДоп.Функции^n^n",g_iGlobal ? "Активировать": "Выключен"), iKeys |= (1<<1);
	if(g_iGlobal)
	{
		FormatItem("\y3. \wВыкл игровых событие^n"), iKeys |= (1<<2);
		FormatItem("\y4. \wКастомный Спавн игроков^n"), iKeys |= (1<<3);
		FormatItem("\y5. \wСоздание объекта^n"), iKeys |= (1<<4);
		//FormatItem("\y6. \wОружейник^n"), iKeys |= (1<<4);
	}
	if(g_iStatusGlboal)
	{
		FormatItem("\y6. \wГлобальные игры^n"), iKeys |= (1<<5);
	}
	
	
	FormatItem("^n^n\y9. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_MainGlobalmenu");

}


	
public Handle_MainGlobalmenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			g_iStatusGlboal = !g_iStatusGlboal;
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s !gглобальный режим", pId, g_iStatusGlboal ? "активировал" : "деактивировал");
			
			//jbe_set_day_mode(6);
			
			switch(g_iStatusGlboal)
			{
				case true:
				{
					jbe_set_formatex_daymode(6);
					static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_None);
					
					
					
					set_cvar_num("mp_unduck_method", 1);
					UTIL_SayText(0, "!g[Глобальное] !yПри активация глобального режима !gSGS и DoubleDuck !yбудут заблокированы");
					for(new i; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						
						jbe_set_user_skin(Players, 0);
						set_entvar(Players, var_skin, 0);
						if(jbe_get_user_team(Players) == 1)
						{
							jbe_remove_shop_pn(Players);
							set_entvar(Players, var_gravity, 1.0);
							//set_entvar(Players, var_maxspeed, 250.0);
							rg_reset_maxspeed(Players);
							set_entvar(Players, var_health, 100.0);	
						}
					}
					
					
				}
				case false:
				{
					jbe_set_formatex_daymode(1);
					set_cvar_num("mp_unduck_method", 0);
				}
			}
			new g_ForwardResult;
			ExecuteForward(g_iFwdResetFlags , g_ForwardResult, g_iStatusGlboal);
		}
			
		case 1: 
		{
			if(g_iEndRound)
			{
				UTIL_SayText(pId, "!g[Глобальное] !yВ текущий момент нельзя использовать данное меню");
				return PLUGIN_HANDLED;
			}
			g_iGlobal = !g_iGlobal;
			if(g_iGlobal == false) 
			{

				ExDisableEvent();
			}
			
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s !gдополнительные функции", pId, g_iGlobal ? "активировал" : "деактивировал");
			return Show_MainGlobalmenu(pId);
		}
		case 2: return Show_DisableEvent(pId);

		case 3:
		{
			client_cmd(pId, "say /spawn");
		}
		case 4: return jbe_open_creator_boxes(pId);
		case 5: return Show_GlobalGame(pId);
		case 8: return Open_Oaio(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainGlobalmenu(pId);

}	




new const g_iTempMenu_One[][] =
	{
		"Машины",
		"Поезда",
		"Пушки от карты",
		"Повреждение от кнопок",
		"Аптечки от бронежилета",
		"Аптечки от жизни",
		"Нажатие кнопки"
	};



Show_DisableEvent(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yЗапрет меню \d[1/4]^n\dТо что можно нажать^n^n");
	
	
	
	new b;
	for(new i; i < sizeof(g_iTempMenu_One); i++) 
		FormatItem("\y%d. \w%s \r%s^n", b++ + 1, g_iTempMenu_One[i], g_iSwitch[i] ? "Вкл" : "Выкл"), iKeys |= (1<<i);
	
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_DisableEvent");
}


public Handle_DisableEvent(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_TWO_DisableEvent(pId);
		case 9: return Show_MainGlobalmenu(pId);
		default:
		{
			g_iSwitch[iKey] = !g_iSwitch[iKey];
			switch(g_iSwitch[iKey])
			{
				case true:
				{
					EnableHamForward(g_iHamHookForwards[iKey]);
				}
				case false:
				{
					DisableHamForward(g_iHamHookForwards[iKey]);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[iKey] ? "дал" : "убрал" ,g_iButtonSwitchOn[iKey]);
			
			
		}
		
		
	}
	return Show_DisableEvent(pId);

}	



Show_TWO_DisableEvent(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yЗапрет меню \d[2/4]^n\dто счем прикасается^n^n");
	
	FormatItem("\y1. \wПовреждение от касание \r%s^n", g_iSwitch[7] ? "Вкл" : "Выкл"), iKeys |= (1<<0);
	FormatItem("\y2. \wВыдачи гравитации при кас. \r%s^n", g_iSwitch[8] ? "Вкл" : "Выкл"), iKeys |= (1<<1);
	FormatItem("\y3. \wПоднятие объектов \r%s^n", g_iSwitch[9] ? "Вкл" : "Выкл"), iKeys |= (1<<2);
	FormatItem("\y4. \wПоднятие оружии \r%s^n", g_iSwitch[10] ? "Вкл" : "Выкл"), iKeys |= (1<<3);
	FormatItem("\y5. \wИспользование щита \r%s^n", g_iSwitch[11] ? "Вкл" : "Выкл"), iKeys |= (1<<4);
	FormatItem("\y6. \wБатут \r%s^n", g_iSwitch[12] ? "Вкл" : "Выкл"), iKeys |= (1<<5);
	FormatItem("\y7. \wТелепорт \r%s^n", g_iSwitch[13] ? "Вкл" : "Выкл"), iKeys |= (1<<6);



	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_TWO_DisableEvent");

}


public Handle_TWO_DisableEvent(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_Three_DisableEvent(pId);
		case 9: return Show_DisableEvent(pId);
		default:
		{
			g_iSwitch[iKey + 7] = !g_iSwitch[iKey + 7];
			switch(g_iSwitch[iKey + 7])
			{
				case true:
				{
					EnableHamForward(g_iHamHookForwards[iKey + 7]);
				}
				case false:
				{
					DisableHamForward(g_iHamHookForwards[iKey + 7]);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[iKey + 7] ? "дал" : "убрал" ,g_iButtonSwitchOn[iKey + 7]);
			
			
		}
		
		
	}
	return Show_TWO_DisableEvent(pId);

}	

Show_Three_DisableEvent(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yЗапрет меню \d[3/4]^n\dто счем прикасается^n^n");
	
	FormatItem("\y1. \wПадение с высоты \r%s^n", g_iSwitch[14] ? "Вкл" : "Выкл"), iKeys |= (1<<0);
	FormatItem("\y2. \wУдар кулака \r%s^n", g_iOtherSwitch[0] ? "Вкл" : "Выкл"), iKeys |= (1<<1);
	FormatItem("\y3. \wУрон = 0 \r%s^n", g_iOtherSwitch[1] ? "Вкл" : "Выкл"), iKeys |= (1<<2);
	FormatItem("\y4. \wСамоубиства \r%s^n", g_iOtherSwitch[2] ? "Вкл" : "Выкл"), iKeys |= (1<<3);
	FormatItem("\y5. \wПроход сквозь игроков \r%s^n", !g_iOtherSwitch[3] ? "Выкл" : "Вкл"), iKeys |= (1<<4);
	FormatItem("\y6. \wПользование лестниц \r%s^n", g_iOtherSwitch[4] ? "Вкл" : "Выкл"), iKeys |= (1<<5);
	FormatItem("\y7. \wРадар \r%s^n", g_iOtherSwitch[5] ? "Вкл" : "Выкл"), iKeys |= (1<<6);
	FormatItem("\y8. \wУдаление оружие после дропа \r%s^n", !g_iOtherSwitch[6] ? "Выкл" : "Вкл"), iKeys |= (1<<7);


	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_Three_DisableEvent");

}


public Handle_Three_DisableEvent(pId, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			//g_iSwitch[14] = !g_iSwitch[14];
			if(!g_iSwitch[14])
				g_iSwitch[14] = true;
			else
			if(g_iSwitch[14])
				g_iSwitch[14] = false;
			
			switch(g_iSwitch[14])
			{
				case true:
				{
					EnableHookChain(HookPlayer_TakeDamageFall);
				}
				case false:
				{
					DisableHookChain(HookPlayer_TakeDamageFall);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[14] ? "дал" : "убрал" ,g_iButtonSwitchOn[14]);
		}
		case 1:
		{

			if(!g_iOtherSwitch[0])
				g_iOtherSwitch[0] = true;
			else
			if(g_iOtherSwitch[0])
				g_iOtherSwitch[0] = false;

			
			switch(g_iOtherSwitch[0])
			{
				case true:
				{
					g_iFakeMetaEmitSound = register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
				}
				case false:
				{
					unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound, false);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[0] ? "дал" : "убрал" ,g_iButtonSwitchOn[15]);
		}
		case 2:
		{
			//g_iSwitch[14] = !g_iSwitch[14];
			if(!g_iOtherSwitch[1])
				g_iOtherSwitch[1] = true;
			else
			if(g_iOtherSwitch[1])
				g_iOtherSwitch[1] = false;
			
			switch(g_iOtherSwitch[1])
			{
				case true:
				{
					EnableHookChain(HookPlayer_PlayerTakeDamage);
					EnableHookChain(HookPlayer_PlayerTraceAttack);
				}
				case false:
				{
					DisableHookChain(HookPlayer_PlayerTakeDamage);
					DisableHookChain(HookPlayer_PlayerTraceAttack);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[1] ? "дал" : "убрал" ,g_iButtonSwitchOn[16]);
		}
		case 3:
		{

			if(!g_iOtherSwitch[2])
				g_iOtherSwitch[2] = true;
			else
			if(g_iOtherSwitch[2])
				g_iOtherSwitch[2] = false;

			
			switch(g_iOtherSwitch[2])
			{
				case true:
				{
					g_iFakeMetaKillConsole = register_forward( FM_ClientKill, "ClCmd_Kill" );
				}
				case false:
				{
					unregister_forward(FM_ClientKill, g_iFakeMetaKillConsole, true);
				}
			}
			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[2] ? "дал" : "убрал" ,g_iButtonSwitchOn[17]);
		}
		case 4:
		{
			if(!g_iOtherSwitch[3])
				g_iOtherSwitch[3] = true;
			else
			if(g_iOtherSwitch[3])
				g_iOtherSwitch[3] = false;
			jbe_set_status_semeclip();

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[3] ? "дал" : "убрал" ,g_iButtonSwitchOn[18]);
		}
		case 5:
		{
			/*if(!g_iOtherSwitch[4])
				g_iOtherSwitch[4] = true;
			else
			if(g_iOtherSwitch[4])
				g_iOtherSwitch[4] = false;

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[4] ? "дал" : "убрал" ,g_iButtonSwitchOn[19]);*/
			UTIL_SayText(pId, "!g[Глобальное] !yВ разработке");
		}
		case 6:
		{
			if(!g_iOtherSwitch[5])
				g_iOtherSwitch[5] = true;
			else
			if(g_iOtherSwitch[5])
				g_iOtherSwitch[5] = false;

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[5] ? "дал" : "убрал" ,g_iButtonSwitchOn[20]);
		}
		case 7:
		{
			if(!g_iOtherSwitch[6])
				g_iOtherSwitch[6] = true;
			else
			if(g_iOtherSwitch[6])
				g_iOtherSwitch[6] = false;

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iOtherSwitch[6] ? "включил" : "выключил" ,g_iButtonSwitchOn[21]);
		}
		case 8: return Show_Four_DisableEvent(pId);
		case 9: return PLUGIN_HANDLED;

		
		
	}
	return Show_Three_DisableEvent(pId);

}

Show_Four_DisableEvent(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yЗапрет меню \d[4/4]^n\dДополнительное^n^n");
	
	FormatItem("\y1. \wВидимость шапок \r%s^n", g_iSwitch[17] ? "Вкл" : "Выкл"), iKeys |= (1<<0);
	FormatItem("\y2. \wНик игрока при наведение \r%s^n", g_iSwitch[18] ? "Вкл" : "Выкл"), iKeys |= (1<<1);
	FormatItem("\y3. \wЗамедление от пуль \r%s^n", g_iSwitch[19] ? "Вкл" : "Выкл"), iKeys |= (1<<2);


	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_NEXT"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_Four_DisableEvent");

}


public Handle_Four_DisableEvent(pId, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(!g_iSwitch[17])
				g_iSwitch[17] = true;
			else
			if(g_iSwitch[17])
				g_iSwitch[17] = false;
			
			switch(g_iSwitch[17])
			{
				case true:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!jbe_is_user_connected(i) || jbe_get_user_team(i) != 1) continue;
						
						jbe_hide_user_costumes(i);
					}
				
				}
				case false:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!jbe_is_user_connected(i) || jbe_get_user_team(i) != 1) continue;
						
						jbe_set_user_costumes(i, jbe_get_user_costumes(i));
					}
				
				}
			}

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[17] ? "дал" : "убрал" ,g_iButtonSwitchOn[22]);
		}
		case 1:
		{
			if(!g_iSwitch[18])
				g_iSwitch[18] = true;
			else
			if(g_iSwitch[18])
				g_iSwitch[18] = false;
			

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[18] ? "дал" : "убрал" ,g_iButtonSwitchOn[23]);
		}
		case 2:
		{
			if(!g_iSwitch[19])
				g_iSwitch[19] = true;
			else
			if(g_iSwitch[19])
				g_iSwitch[19] = false;
				
			switch(g_iSwitch[19])
			{
				case true:
				{
					EnableHookChain(HookPlayer_TakeDamageVelocity[0]);
					EnableHookChain(HookPlayer_TakeDamageVelocity[1]);
				}
				case false:
				{
					DisableHookChain(HookPlayer_TakeDamageVelocity[0]);
					DisableHookChain(HookPlayer_TakeDamageVelocity[1]);
				}
			}
			

			UTIL_SayText(0, "!g[Глобальное] !yАдминистратор !g%n !y%s запрет на !g%s",pId, g_iSwitch[19] ? "дал" : "убрал" ,g_iButtonSwitchOn[24]);
		}
		case 8: return Show_DisableEvent(pId);
		case 9: return PLUGIN_HANDLED;

		
		
	}
	return Show_Four_DisableEvent(pId);
}
public Client_Func_Ladder(pId)
{
	if(!g_iOtherSwitch[4]) return;

	
	/*if(get_entvar( pId, var_movetype ) == MOVETYPE_FLY && !(get_entvar( pId, var_button) & IN_JUMP )) 
	{
		//server_print("Ladder");
		client_cmd( pId, "+jump;wait;-jump");
	}*/

}

public jbe_set_status_semeclip()
{
    switch(g_iOtherSwitch[3])
    {
        case true:
        {
            g_iFakeMetaPreThink = register_forward(FM_PlayerPreThink, "preThink");
            g_iFakeMetaPostThink = register_forward(FM_PlayerPostThink, "postThink");
            g_iFakeMetaFullPack = register_forward(FM_AddToFullPack, "addToFullPack", 1);
        }
        case false:
        {
            unregister_forward(FM_PlayerPreThink, g_iFakeMetaPreThink);
            unregister_forward(FM_PlayerPostThink, g_iFakeMetaPostThink);
            unregister_forward(FM_AddToFullPack, g_iFakeMetaFullPack, 1);
        }
    }
}

/*public fw_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if(host == ent) 
        return FMRES_IGNORED;
		
	set_es(es_handle, ES_Solid, SOLID_TRIGGER);
	
	return FMRES_IGNORED; 

}*/



public addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
    if(player)
    {
        if(plrSolid[host] && plrSolid[ent] && plrTeam[host] == plrTeam[ent])
        {
            set_es(es, ES_Solid, SOLID_NOT);
           	//set_es(es, ES_RenderMode, kRenderTransAlpha);
           	//set_es(es, ES_RenderAmt, 230);
        }
    }
}

FirstThink()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!jbe_is_user_alive(i))
        {
            plrSolid[i] = false;
            continue;
        }
        
        plrTeam[i] = jbe_get_user_team(i);
        plrSolid[i] = pev(i, pev_solid) == SOLID_SLIDEBOX ? true : false;
    }
}

public preThink(id)
{
    static i, LastThink;
    
    if(LastThink > id)
    {
        FirstThink();
    }
    LastThink = id;

    
    if(!plrSolid[id]) return;
    
    for(i = 1; i <= MaxClients; i++)
    {
        if(!plrSolid[i] || id == i) continue;
        
        if(plrTeam[i] == plrTeam[id])
        {
            set_pev(i, pev_solid, SOLID_NOT);
            plrRestore[i] = true;
        }
    }
}

public postThink(id)
{
    static i;
    
    for(i = 1; i <= MaxClients; i++)
    {
        if(plrRestore[i])
        {
            set_pev(i, pev_solid, SOLID_SLIDEBOX);
            plrRestore[i] = false;
        }
    }
}

//Linux extra offsets
#define pData_Player            5

//CBasePlayer
#define pDataKey_iPainShock     108

public HC_CBasePlayer_TakeDamage_Velocity_Pre(pID) get_entvar(pID, var_velocity, v_velocity);
public HC_CBasePlayer_TakeDamage_Velocity_Post(pID) 
{
	set_entvar(pID, var_velocity, v_velocity);
	set_pdata_float(pID, pDataKey_iPainShock, 1.0, pData_Player);
}

public refwd_PlayerImpulseCommands_Pre(id)
{
    if(get_member(id, m_afButtonPressed) & IN_USE/* && g_iOtherSwitch[0]*/)
        EnableHookChain(g_iHookChainStartSound);
}

public refwd_PlayerImpulseCommands_Post(id)
{
    DisableHookChain(g_iHookChainStartSound);
}

public refwd_SV_StartSound_Pre(const iRecipients, const iEntity, const iChannel, const szSample[], const flVolume, Float:flAttenuation, const fFlags, const iPitch)
{
    if(contain(szSample, "wpn_denyselect") != -1 || contain(szSample, "wpn_select") != -1)
        return HC_SUPERCEDE;
    return HC_CONTINUE;
}


