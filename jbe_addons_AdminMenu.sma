#include <amxmodx>
#include <reapi>
#include <amxmisc>
#include <jbe_core>
#include <fakemeta>

//sv_maxvelocity 2000
//sv_maxspeed 2000

native zl_boss_valid(Ent)

new const szPrefix[] = "!g*"
#define 	MOD_PREFIX			"^4[FRALLION]^1"
native jbe_show_hpmenu(pId)

#define DEFAULT_SPEED    250.0
#define MAX_SPEED		5000
#define MIN_SPEED		1

#define MAX_HEALTH 1000000

native jbe_is_user_duel(pId)
native jbe_get_soccergame()
native zl_boss_map();

new const NULLED =	-1;


new Float:g_iSpeedUnit = DEFAULT_SPEED,
	Float:g_iUserSpeed[MAX_PLAYERS + 1],
	bool:g_iUserBoolSpeed[MAX_PLAYERS + 1];

#define DEFAULT_GRAVITY 1.0

new bool:g_iUserBoolGravity[MAX_PLAYERS + 1];
new g_iGravityUnit,
	Float:g_iUserGravity[MAX_PLAYERS + 1];

new const Float:fGravity[] = 
{
	1.0,
	0.01,
	0.1,
	0.2,
	0.3, 
	0.4, 
	0.5,
	0.6,
	0.7, 
	0.8,
	0.9,
	1.0
};

enum vars_struct { 
	bool:g_iUserGodMode = 0,
	bool:g_bInvis,
	g_bInvisPrecent,
	bool:g_bBHop,
	bool:g_bDoubleJump,
	bool:g_bUnlimAmmo,
	bool:g_bParachute,
	bool:g_bRegeneration,
	bool:g_bVampir,
	bool:g_bSpider,
	Float:g_iVampirDamage,
	g_iPlayerCountXJump,
	g_iPlayerCountXJumpSave,
	bool:g_bNoStep
}

enum _:UserInfo
{ 
	SPEED = 1,
	GRAVITY,
	GODMODE,
	INVISIBLE,
	BHOP,
	DDJUMP,
	UNLLIMAMMO,
	PARACHUTE,
	REGENERATION,
	VAMPIRE,
	SPIDER,
	NOSTEP
}
new s_PlayerSkillTime[MAX_PLAYERS + 1][UserInfo];
new g_iTypeMenuSelect[MAX_PLAYERS + 1];
new s_AdminChooseTime[MAX_PLAYERS + 1];
new s_SyncSkillInfo

new g_vars[MAX_PLAYERS + 1][vars_struct];

new g_iValuePrecentInvis;
new const Float:fTaskg_bInvisPresent[] = 
{
	0.0,
	10.0,
	20.0,
	30.0,
	40.0, 
	50.0, 
	60.0,
	70.0,
	80.0, 
	90.0
};


new g_iCountXJump = 2;
new bool:g_iXJumpReSave;
new Float:g_ValueXJump = 100.0;

new g_iRegeneration[3];
new const Float:fTaskRegeneration[] = 
{
	1.0,
	2.0,
	3.0,
	4.0,
	5.0, 
	10.0, 
	15.0,
	20.0,
	25.0, 
	30.0
};
new const Float:fHealthRegeneration[] = 
{
	1.0,
	5.0,
	10.0,
	15.0,
	20.0
};
new const Float:fMaxHealthRegeneration[] = 
{
	0.0,
	100.0,
	150.0,
	255.0,
	500.0,
	1000.0
};

new g_iVampir;
new g_MsgSync2;

new const Float:fHealthVampir[] = 
{
	1.0,
	2.0,
	3.0,
	4.0,
	5.0, 
	10.0, 
	15.0,
	20.0,
	25.0, 
	30.0
};







enum (+= 3)
{
	TASK_PLAYER_REGENERATION = 568758367,
	TASK_PLAYER_GRENADE,
	TASK_PLAYER_POSION,
	TASK_PLAYER_SHAKE,
	TASK_PLAYER_BURN,
	TASK_PLAYER_SKILL_TIME
};




#define PLAYERS_PER_PAGE 8
#define MAX_SZMENU 		512

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1];
	//g_iMenuTarget[MAX_PLAYERS + 1];
#define PLAYERS_PER_PAGE 8


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

new g_iSyncXJumpCount;



public plugin_init()
{
	register_plugin("[JBE] AdminMenu New", "2.0", "DalgaPups");

	register_clcmd("say /adminka", 						"openmenu");
	register_clcmd("frallion_speedunits" , 				"clcmd_speedunits")
	register_clcmd("xcount_jump", "menuxcount_jump");
	register_clcmd("frallion_skilltime", "ClCmd_SetTime");
	
	

	g_MsgSync2 = 			CreateHudSyncObj();
	g_iSyncXJumpCount = 	CreateHudSyncObj();
	s_SyncSkillInfo = 		CreateHudSyncObj()


	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	RegisterMenu("Show_MainAdminMenu", 					"Handle_MainAdminMenu");
	RegisterMenu("Show_SpawnMenu", 						"Handle_SpawnMenu");
	RegisterMenu("Show_PlayerSpawnMenu",  				"Handle_PlayerSpawnMenu");

	RegisterMenu("Show_SkillsMenu",  					"Handle_SkillsMenu");

	RegisterMenu("Show_SkillsSpeedMenu",  				"Handle_SkillsSpeedMenu");
	RegisterMenu("Show_PlayerSpeedMenu",  				"Handle_PlayerSpeedMenu");

	RegisterMenu("Show_SkillsGravityMenu",  			"Handle_SkillsGravityMenu");
	RegisterMenu("Show_PlayerGravityMenu",  			"Handle_PlayerGravityMenu");

	RegisterMenu("Show_SkillsGodModeMenu",  			"Handle_SkillsGodModeMenu");
	RegisterMenu("Show_PlayerGodModeMenu",  			"Handle_PlayerGodModeMenu");

	RegisterMenu("Show_SkillsInvisibleMenu",  			"Handle_SkillsInvisibleMenu");
	RegisterMenu("Show_PlayerInvisibleMenu",  			"Handle_PlayerInvisibleMenu");

	RegisterMenu("Show_SkillsBunnyHopMenu",  			"Handle_SkillsBunnyHopMenu");
	RegisterMenu("Show_PlayerBunnyHopMenu",  			"Handle_PlayerBunnyHopMenu");

	RegisterMenu("Show_SkillsDoubleJumpMenu",  			"Handle_SkillsDoubleJumpMenu");
	RegisterMenu("Show_PlayerDoubleJumpMenu",  			"Handle_PlayerDoubleJumpMenu");

	RegisterMenu("Show_SkillsUnAmmoMenu",  				"Handle_SkillsUnAmmoMenu");
	RegisterMenu("Show_PlayerUnAmmoMenu",  				"Handle_PlayerUnAmmoMenu");

	RegisterMenu("Show_SkillsTwoMenu",  				"Handle_SkillsTwoMenu");

	RegisterMenu("Show_SkillsParachuteMenu",  			"Handle_SkillsParachuteMenu");
	RegisterMenu("Show_PlayerParachuteMenu",  			"Handle_PlayerParachuteMenu");

	RegisterMenu("Show_SkillsRegenerationMenu",  		"Handle_SkillsRegenerationMenu");
	RegisterMenu("Show_PlayerRegenerationMenu",  		"Handle_PlayerRegenerationMenu");

	RegisterMenu("Show_SkillsVampirMenu",  				"Handle_SkillsVampirMenu");
	RegisterMenu("Show_PlayerVampirMenu",  				"Handle_PlayerVampirMenu");
	
	RegisterMenu("Show_SkillsSpiderMenu",  				"Handle_SkillsSpiderMenu");
	RegisterMenu("Show_PlayerSpiderMenu",  				"Handle_PlayerSpiderMenu");
	
	RegisterMenu("Show_SkillsJetPackMenu",  				"Handle_SkillsJetPackMenu");
	RegisterMenu("Show_PlayerJetPackMenu",  				"Handle_PlayerJetPackMenu");
	
	RegisterMenu("Show_SkillsNoStepsMenu",					"Handle_SkillsNoStepsMenu");
	RegisterMenu("Show_PlayerNoStepMenu",					"Handle_PlayerNoStepMenu");
	
	
	#undef RegisterMenu
	
	
	

	
	
	
	main_init();

}


#include <global_ability_menu>
#include <global_func>

public plugin_precache() 
{
	//g_SpriteBeam = engfunc(EngFunc_PrecacheModel, "sprites/zbeam1.spr")
}


public client_putinserver(pId)
{
	s_AdminChooseTime[pId] = 0
	set_task(1.0, "jb_show_activ_skill", pId+TASK_PLAYER_SKILL_TIME, _, _, "b")
}

public openmenu(pId) return Show_MainAdminMenu(pId);

Show_MainAdminMenu(pId)
{
	new szMenu[MAX_SZMENU], iLen, iKeys;

	FormatMain("\yАдмин Меню^n^n");

	FormatItem("\y1. \wВозрадить^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wСпособности^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wРедактировать хп^n"), iKeys |= (1<<2);
	FormatItem("\y4. \wВыдать оружие^n"), iKeys |= (1<<3);
	FormatItem("\y5. \wНаказать^n"), iKeys |= (1<<4);
	
	FormatItem("\y8. \wСбросить у всех способности^n"), iKeys |= (1<<7);
	FormatItem("^n\y0. \wВыход"), iKeys |= (1<<9);

	return show_menu(pId, iKeys, szMenu, -1, "Show_MainAdminMenu");
}

public Handle_MainAdminMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: return Show_SpawnMenu(pId);
		case 1: return Show_SkillsMenu(pId);
		case 2: return jbe_show_hpmenu(pId);
		
		case 7:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!jbe_is_user_connected(i)) continue;
				
				Remove_Stock(i);
				
			}
			UTIL_SayText(0, "%s !yАдминистратор !g%n !yочистил все !gспособности !yу игроков", szPrefix, pId);
		}
		case 9: return PLUGIN_HANDLED;
	}

	return Show_MainAdminMenu(pId);
}






///////////////////////////////////////////////////////////////////////











public menuxcount_jump(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) >= 5)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:9999!y]");
		return Show_SkillsDoubleJumpMenu(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_SkillsDoubleJumpMenu(id);
	}
	if(str_to_num( Args1 ) <= 1)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение равно или меньше !g1!");
		return Show_SkillsDoubleJumpMenu(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_SkillsDoubleJumpMenu(id);
		}
	}
	
	g_iCountXJump = str_to_num( Args1 );
	UTIL_SayText(id, "!g* !yЗначение прыжка равен %d", g_iCountXJump);
	//g_iCountXJump = szAmount1;
	return Show_SkillsDoubleJumpMenu(id);
}

public ClCmd_SetTime(id)
{
	new szArg1[10];
	read_argv(1, szArg1, charsmax(szArg1));
	if(!is_str_num(szArg1))
	{
		UTIL_SayText(id, "%s ^1Вы ввели неверные значения.", MOD_PREFIX);

	}
	else
	{
		if(str_to_num(szArg1) < 0) UTIL_SayText(id, "%s Минимальное время -^3 1 сек^1.", MOD_PREFIX)
		else s_AdminChooseTime[id] = str_to_num(szArg1)
	}
	switch(g_iTypeMenuSelect[id])
	{
		case 1: return Show_SkillsSpeedMenu(id);
		case 2: return Show_SkillsGravityMenu(id);
		case 3: return Show_SkillsGodModeMenu(id);
		case 4: return Show_SkillsInvisibleMenu(id);
		case 5: return Show_SkillsBunnyHopMenu(id);
		case 6: return Show_SkillsDoubleJumpMenu(id);
		case 7: return Show_SkillsUnAmmoMenu(id);
		case 8: return Show_SkillsParachuteMenu(id);
		case 9: return Show_SkillsRegenerationMenu(id);
		case 10: return Show_SkillsVampirMenu(id);
		case 11: return Show_SkillsSpiderMenu(id);
		case 12: return Show_SkillsJetPackMenu(id);
		case 14: return Show_SkillsNoStepsMenu(id);
	}
	return PLUGIN_HANDLED
}

stock Remove_Stock(const pId)
{
	if(g_iUserBoolSpeed[pId]) 				Player_RemoveSpeed(pId);
	if(g_iUserBoolGravity[pId]) 			Player_RemoveGravity(pId);
	if(g_vars[pId][g_iUserGodMode]) 		Player_RemoveGodmode(pId);
	if(g_vars[pId][g_bInvis]) 				Player_ResetInvis(pId);
	if(g_vars[pId][g_bBHop])				Player_RemoveBhop(pId);
	if(g_vars[pId][g_bDoubleJump])			Player_RemoveDoubleJump(pId);
	if(g_vars[pId][g_bUnlimAmmo])			Player_RemoveUnlimAmmo(pId);
	if(g_vars[pId][g_bParachute])			Player_RemoveParachute(pId);
	if(g_vars[pId][g_bRegeneration])		Player_RemoveRegeneration(pId);
	if(g_vars[pId][g_bVampir])				Player_RemoveVampir(pId);
	if(g_vars[pId][g_bNoStep])				Player_RemoveNoStep(pId);
}




stock Player_SetSpeed(AdminIndex, pId, Float:Speed) {
	set_entvar(pId, var_maxspeed, Speed)
	g_iUserSpeed[pId] = Speed
	g_iUserBoolSpeed[pId] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][SPEED] = s_AdminChooseTime[AdminIndex]
	}
	
	client_cmd(pId,"cl_forwardspeed ^"%d^"", MAX_SPEED);
	client_cmd(pId,"cl_backspeed ^"%d^"", MAX_SPEED);
	client_cmd(pId,"cl_sidespeed ^"%d^"", MAX_SPEED * 2);
} 
stock Player_RemoveSpeed(pId) 
{
	rg_reset_maxspeed(pId)
	g_iUserSpeed[pId] = DEFAULT_SPEED
	s_PlayerSkillTime[pId][SPEED] = NULLED;
	g_iUserBoolSpeed[pId] = false;
	
	client_cmd(pId,"cl_forwardspeed ^"450^"");
	client_cmd(pId,"cl_backspeed ^"450^"");
	client_cmd(pId,"cl_sidespeed ^"450^"");
}


stock Player_SetGravity(AdminIndex, pId, Float:Gravity)
{
	g_iUserGravity[pId] = Gravity;
	set_entvar(pId, var_gravity, g_iUserGravity[pId])
	g_iUserBoolGravity[pId] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][GRAVITY] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][GRAVITY] = NULLED;
}
stock Player_RemoveGravity(pId) 
{
	set_entvar(pId, var_gravity, DEFAULT_GRAVITY)
	g_iUserBoolGravity[pId] = false;
	s_PlayerSkillTime[pId][GRAVITY] = NULLED;
}


stock Player_SetGodMode(AdminIndex, pId) {
	set_entvar(pId, var_takedamage, DAMAGE_NO)
	g_vars[pId][g_iUserGodMode] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][GODMODE] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertGodMode(AdminIndex, pId) 
{
	g_vars[pId][g_iUserGodMode] = !g_vars[pId][g_iUserGodMode]
	set_entvar(pId, var_takedamage, g_vars[pId][g_iUserGodMode] ? DAMAGE_NO : DAMAGE_YES)
	if(g_vars[pId][g_iUserGodMode] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][GODMODE] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][GODMODE] = NULLED;
}
stock Player_RemoveGodmode(pId) 
{
	set_entvar(pId, var_takedamage, DAMAGE_YES)
	g_vars[pId][g_iUserGodMode] = false
	s_PlayerSkillTime[pId][GODMODE] = NULLED;
}

stock Player_SetBhop(AdminIndex, pId) 
{
	g_vars[pId][g_bBHop] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][BHOP] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertBhop(AdminIndex, pId) 
{
	g_vars[pId][g_bBHop] = !g_vars[pId][g_bBHop]
	if(g_vars[pId][g_bBHop] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][BHOP] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][BHOP] = NULLED;
}
stock Player_RemoveBhop(pId) 
{
	g_vars[pId][g_bBHop] = false 
	s_PlayerSkillTime[pId][BHOP] = NULLED;
}

stock Player_SetDoubleHump(AdminIndex, pId) 
{
	g_vars[pId][g_bDoubleJump] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][DDJUMP] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertDoubleHump(AdminIndex, pId) 
{
	g_vars[pId][g_bDoubleJump] = !g_vars[pId][g_bDoubleJump]
	if(g_vars[pId][g_bDoubleJump] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][DDJUMP] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][DDJUMP] = NULLED;
}
stock Player_RemoveDoubleJump(pId) 
{
	g_vars[pId][g_bDoubleJump] = false
	g_vars[pId][g_iPlayerCountXJump] = 2
	s_PlayerSkillTime[pId][DDJUMP] = NULLED;
}

stock Player_SetUnlimAmmo(AdminIndex, pId) 
{
	g_vars[pId][g_bUnlimAmmo] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][UNLLIMAMMO] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertUnlimAmmo(AdminIndex, pId) 
{
	g_vars[pId][g_bUnlimAmmo] = !g_vars[pId][g_bUnlimAmmo]
	if(g_vars[pId][g_bUnlimAmmo] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][UNLLIMAMMO] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][UNLLIMAMMO] = NULLED;
}
stock Player_RemoveUnlimAmmo(pId) 
{
	g_vars[pId][g_bUnlimAmmo] = false
	s_PlayerSkillTime[pId][UNLLIMAMMO] = NULLED;
}

stock Player_SetParachute(AdminIndex, pId) 
{
	g_vars[pId][g_bParachute] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][PARACHUTE] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertParachute(AdminIndex, pId) 
{
	g_vars[pId][g_bParachute] = !g_vars[pId][g_bParachute]
	if(g_vars[pId][g_bParachute] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][PARACHUTE] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][PARACHUTE] = NULLED;
}
stock Player_RemoveParachute(pId) 
{
	g_vars[pId][g_bParachute] = false
	s_PlayerSkillTime[pId][PARACHUTE] = NULLED;
}

stock Player_SetVampir(AdminIndex, pId) 
{
	g_vars[pId][g_bVampir] = true, g_vars[pId][g_iVampirDamage] = fHealthVampir[g_iVampir]
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][VAMPIRE] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertVampir(AdminIndex, pId) 
{
	g_vars[pId][g_bVampir] = !g_vars[pId][g_bVampir], g_vars[pId][g_iVampirDamage] = fHealthVampir[g_iVampir]
	if(g_vars[pId][g_bVampir] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][VAMPIRE] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][VAMPIRE] = NULLED;
}
stock Player_RemoveVampir(pId) 
{
	g_vars[pId][g_bVampir] = false
	s_PlayerSkillTime[pId][VAMPIRE] = NULLED;
}

stock Player_SetSpider(AdminIndex, pId) 
{
	g_vars[pId][g_bSpider] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][SPIDER] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_InvertSpider(AdminIndex, pId) 
{
	g_vars[pId][g_bSpider] = !g_vars[pId][g_bSpider]
	if(g_vars[pId][g_bSpider] && s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][SPIDER] = s_AdminChooseTime[AdminIndex]
	}else s_PlayerSkillTime[pId][SPIDER] = NULLED;
}
stock Player_RemoveSpider(pId) 
{
	g_vars[pId][g_bSpider] = false
	s_PlayerSkillTime[pId][SPIDER] = NULLED;
}

stock Player_SetNoStep(AdminIndex, pId) 
{
	g_vars[pId][g_bNoStep] = true
	rg_set_user_footsteps(pId, true);
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][NOSTEP] = s_AdminChooseTime[AdminIndex]
	}
}
stock Player_RemoveNoStep(pId) 
{
	g_vars[pId][g_bNoStep] = false 
	rg_set_user_footsteps(pId, false);
	s_PlayerSkillTime[pId][NOSTEP] = NULLED;
}


stock Player_SetRegeneration(AdminIndex, pId)
{
	g_vars[pId][g_bRegeneration] = true;
	if(task_exists(pId + TASK_PLAYER_REGENERATION)) 
	{
		remove_task(pId + TASK_PLAYER_REGENERATION)
	}
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][REGENERATION] = s_AdminChooseTime[AdminIndex]
	}
	set_task_ex(fTaskRegeneration[g_iRegeneration[0]], "Task_PlayerRegeneration", pId + TASK_PLAYER_REGENERATION, .flags = SetTask_Repeat);
}
stock Player_InvertRegeneration(AdminIndex, pId) 
{
	g_vars[pId][g_bRegeneration] = !g_vars[pId][g_bRegeneration]
	switch(g_vars[pId][g_bRegeneration])
	{
		case true:
		{
			if(task_exists(pId + TASK_PLAYER_REGENERATION))
			{
				remove_task(pId + TASK_PLAYER_REGENERATION)
			}
			if(s_AdminChooseTime[AdminIndex] != 0)
			{
				s_PlayerSkillTime[pId][REGENERATION] = s_AdminChooseTime[AdminIndex]
			}
			set_task_ex(fTaskRegeneration[g_iRegeneration[0]], "Task_PlayerRegeneration", pId + TASK_PLAYER_REGENERATION, .flags = SetTask_Repeat);
		}
		case false:
		{
			if(task_exists(pId + TASK_PLAYER_REGENERATION))
			{
				remove_task(pId + TASK_PLAYER_REGENERATION);
			}
			s_PlayerSkillTime[pId][REGENERATION] = NULLED;
			
		}
	}
}
stock Player_RemoveRegeneration(pId) 
{
	g_vars[pId][g_bRegeneration] = false;

	if(task_exists(pId + TASK_PLAYER_REGENERATION))
	{
		remove_task(pId + TASK_PLAYER_REGENERATION);
	}
}

stock Task_PlayerRegeneration(pId)
{
	pId -= TASK_PLAYER_REGENERATION;

	if(!g_vars[pId][g_bRegeneration]) return;



	new Float:Health;
	get_entvar(pId, var_health, Health)
	set_entvar(pId, var_health, Health + fHealthRegeneration[g_iRegeneration[1]]);

	if(g_iRegeneration[2] && Health > fMaxHealthRegeneration[g_iRegeneration[2]])
	{
		set_entvar(pId, var_health, fMaxHealthRegeneration[g_iRegeneration[2]]);
	}

	if(Health > MAX_HEALTH )
	{
		if(task_exists(pId + TASK_PLAYER_REGENERATION))
		{
			remove_task(pId + TASK_PLAYER_REGENERATION);
			UTIL_SayText(pId, "%s !yрегенерация отключена, вы достигли максимального Здоровье");
		}
	}
}







stock Player_SetInvis(AdminIndex, pId) {
	set_entvar(pId, var_renderfx, kRenderFxGlowShell)
	set_entvar(pId, var_rendercolor, {0.0, 0.0, 0.0})
	set_entvar(pId, var_rendermode, kRenderTransAlpha)
	set_entvar(pId, var_renderamt, fTaskg_bInvisPresent[g_vars[pId][g_bInvisPrecent]])
	g_vars[pId][g_bInvis] = true
	if(s_AdminChooseTime[AdminIndex] != 0)
	{
		s_PlayerSkillTime[pId][INVISIBLE] = s_AdminChooseTime[AdminIndex]
	}
}
	
stock Player_ResetInvis(pId) 
{
	set_entvar(pId, var_renderfx, kRenderFxNone)
	set_entvar(pId, var_rendercolor, {255.0, 255.0, 255.0})
	set_entvar(pId, var_rendermode, kRenderNormal)
	set_entvar(pId, var_renderamt, 18.0)
	g_vars[pId][g_bInvis] = false
	s_PlayerSkillTime[pId][INVISIBLE] = NULLED;
}

stock Player_InvertInviz(AdminIndex, pPlayer) 
{
	switch(g_vars[pPlayer][g_bInvis])
	{
		case true:
		{
			set_entvar(pPlayer, var_renderfx, kRenderFxGlowShell), 
			set_entvar(pPlayer, var_rendercolor, {0.0, 0.0, 0.0}), 
			set_entvar(pPlayer, var_rendermode, kRenderTransAlpha), 
			set_entvar(pPlayer, var_renderamt, 0)
			
			if(s_AdminChooseTime[AdminIndex] != 0)
			{
				s_PlayerSkillTime[pPlayer][INVISIBLE] = s_AdminChooseTime[AdminIndex]
			}

		}
		case false:
		{
			set_entvar(pPlayer, var_renderfx, kRenderFxNone), 
			set_entvar(pPlayer, var_rendercolor, {255.0, 255.0, 255.0}), 
			set_entvar(pPlayer, var_rendermode, kRenderNormal), 
			set_entvar(pPlayer, var_renderamt, 18.0)
			
			s_PlayerSkillTime[pPlayer][INVISIBLE] = NULLED;
		}
	}
	g_vars[pPlayer][g_bInvis] = !g_vars[pPlayer][g_bInvis]
}

public jb_show_activ_skill(id)
{
	id -= TASK_PLAYER_SKILL_TIME
	if(jbe_is_user_alive(id)) 
	{
		
		for(new i = 1; i <= sizeof(s_PlayerSkillTime[]) - 1; i++)
		{
			if(s_PlayerSkillTime[id][i]) s_PlayerSkillTime[id][i]--
		}

		if(s_PlayerSkillTime[id][SPEED] == 0) 			Player_RemoveSpeed(id);
		if(s_PlayerSkillTime[id][GRAVITY] == 0) 		Player_RemoveGravity(id);
		if(s_PlayerSkillTime[id][GODMODE] == 0) 		Player_RemoveGodmode(id);
		if(s_PlayerSkillTime[id][INVISIBLE] == 0) 		Player_ResetInvis(id);
		if(s_PlayerSkillTime[id][BHOP] == 0) 			Player_RemoveBhop(id);
		if(s_PlayerSkillTime[id][SPIDER] == 0) 			Player_RemoveSpider(id);//////////
		if(s_PlayerSkillTime[id][UNLLIMAMMO] == 0) 		Player_RemoveUnlimAmmo(id);
		if(s_PlayerSkillTime[id][PARACHUTE] == 0) 		Player_RemoveParachute(id);
		if(s_PlayerSkillTime[id][REGENERATION] == 0) 	Player_RemoveRegeneration(id);
		if(s_PlayerSkillTime[id][VAMPIRE] == 0) 		Player_RemoveVampir(id);
		if(s_PlayerSkillTime[id][NOSTEP] == 0) 			Player_RemoveNoStep(id);
		
		if(s_PlayerSkillTime[id][SPIDER] == 0) 			Player_RemoveSpider(id);//////////////////
		if(s_PlayerSkillTime[id][SPIDER] == 0) 			Player_RemoveSpider(id);///////////////////
		
		new Message[512], s_Len
		if(s_PlayerSkillTime[id][SPEED] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Скорость - %d c.^n", s_PlayerSkillTime[id][SPEED])
		if(s_PlayerSkillTime[id][GRAVITY] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Гравитация - %d c.^n", s_PlayerSkillTime[id][GRAVITY])
		if(s_PlayerSkillTime[id][GODMODE] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Бессмертие - %d c.^n", s_PlayerSkillTime[id][GODMODE])
		if(s_PlayerSkillTime[id][INVISIBLE] > 0) 			s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Рендеринг - %d c.^n", s_PlayerSkillTime[id][INVISIBLE])
		if(s_PlayerSkillTime[id][DDJUMP] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Двойной прыжок - %d c.^n", s_PlayerSkillTime[id][DDJUMP])
		if(s_PlayerSkillTime[id][BHOP] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Распрыжка - %d c.^n", s_PlayerSkillTime[id][BHOP])
		if(s_PlayerSkillTime[id][UNLLIMAMMO] > 0) 			s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Беск.патроны - %d c.^n", s_PlayerSkillTime[id][UNLLIMAMMO])
		if(s_PlayerSkillTime[id][PARACHUTE] > 0) 			s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Парашут - %d c.^n", s_PlayerSkillTime[id][PARACHUTE])
		if(s_PlayerSkillTime[id][REGENERATION] > 0) 		s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Регенерация - %d c.^n", s_PlayerSkillTime[id][REGENERATION])
		if(s_PlayerSkillTime[id][VAMPIRE] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Вампиризм - %d c.^n", s_PlayerSkillTime[id][VAMPIRE])
		if(s_PlayerSkillTime[id][SPIDER] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Спйадер - %d c.^n", s_PlayerSkillTime[id][SPIDER])
		if(s_PlayerSkillTime[id][NOSTEP] > 0) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, "Бесшумные шаги - %d c.^n", s_PlayerSkillTime[id][NOSTEP])
		//if(s_PlayerSkillTime[id][12]) 				s_Len += formatex(Message[s_Len], charsmax(Message) - s_Len, " - %d c.^n", s_PlayerSkillTime[id][8])
		set_hudmessage(150, 150, 150, 0.8, 0.1, 0, 1.0, 1.1, 1.0, 1.0, -1)
		ShowSyncHudMsg(id, s_SyncSkillInfo, Message)
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
