#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include < fakemeta_stocks >
#include <hamsandwich>
#include <reapi>
#include <jbe_core>
#include <xs>
new iEnt;
new g_iGlobalDebug;

//#define WANTED_FOR_GAME

#include <util_saytext>
//#define BEAMDUELS
#define TASK_SHOW_SOCCER_SCORE 7657456
#define TASK_SHCEKING 5758658768


new const BALL_MODELS[] = "models/jb_engine/soccer/ball.mdl";
new modelindex;

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

//#define ENABLE_DUCK
native jbe_set_formatex_daymode(iType);
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define MAX_SPEED 				5000
#define MIN_SPEED 				100
#define UNITS_OWNER				55.0		//расстояния между отбора мяча
#define UNITS_BALLS_PL			65.0		//Растояние между игроком и мяча (стандарт 55)

new g_iFwdFootball;

native jbe_box_menu(pId);
native jbe_open_main_menu(pId, iMenu);

new bool:g_bSoccerGame,
	g_iSoccerBall,
	bool:g_bSoccerBallTrail,
	Float:g_flSoccerBallOrigin[3],
	g_iSoccerBallOwner, 
	g_iSoccerKickOwner,
	g_iSoccerKickOwnerName,
	g_pSpriteBeam;
	
new g_iSoccerScore[2],
	g_iSoccerTeamName[2][MAX_NAME_LENGTH];
new g_iSyncSoccerScore,
	g_iSyncSoccerBallInformer;
new Float:eOrigin[3];
new g_iBallSpin,
	g_iBallControler;

new g_iBallCanTouch[33]

native jbe_box_status(status, pId = 0);

new bool:g_iRoundEnd;

new g_iSoccerBallTrail;
new g_iSoccerSpeedHit;
new g_iBallTrailRGB[3]

new HamHook:g_iHamHookSoccer[3];
new HookChain:g_iSoccerHook[2];

new s_TrailOrigin[33][3];

const linux_diff_animating = 4;
const m_flLastAttackTime = 220;

#define m_bloodColor 89
#define m_afButtonPressed 246
const linux_diff_player = 5;
#define ACT_RANGE_ATTACK1  28
#define m_flFrameRate  36
#define m_flGroundSpeed  37
#define m_flLastEventCheck  38
#define m_fSequenceFinished  39
#define m_fSequenceLoops  40
#define m_Activity 73
#define m_IdealActivity 74

#define TASK_TRAIL_BALL 756493
#define TASK_SOCCER_CONTROL 7696058
#define TASK_SHOW_OUTBALL	98574563

new const g_iSkinNumber[][] = 
{
	"Белой",
	"Синей",
	"Фиолетовой",
	"Желтой",
	"Серой",
	"Зеленой",
	"Красной"
};


native jbe_get_user_skin(pId);
native jbe_set_user_skin(pId, iNum);
native jbe_aliveplayersnum(iType);

public plugin_init()
{
	register_plugin("[JBE] Footbal", "1.0", "DalgaPups");
	//register_clcmd("say /foot", "ClCmd_Football");

	register_menucmd(register_menuid("Show_FootBalMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_FootBalMenu");
	register_menucmd(register_menuid("Show_SettingTeam"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_SettingTeam");

	g_iSyncSoccerScore = CreateHudSyncObj();
	g_iSyncSoccerBallInformer = CreateHudSyncObj();

	DisableHamForward(g_iHamHookSoccer[0] = RegisterHam(Ham_ObjectCaps, 	"player", 		"Ham_ObjectCapg_iPost", true));
	DisableHamForward(g_iHamHookSoccer[1] = RegisterHam(Ham_Think, 			"func_wall", 	"Ham_WallThink_Post", true));
	DisableHamForward(g_iHamHookSoccer[2] = RegisterHam(Ham_Touch, 			"func_wall", 	"Ham_WallTouch_Post", true));

	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");

	DisableHookChain(g_iSoccerHook[0] = 	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true));
	
#if defined WANTED_FOR_GAME
	DisableHookChain(g_iSoccerHook[1] = 	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false));
#endif
	
	g_iFwdFootball = CreateMultiForward("jbe_soccer_start", ET_CONTINUE, FP_CELL);
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	register_clcmd("team_one", 			"Command_SoccerTeam_Red");
	register_clcmd("team_two", 			"Command_SoccerTeam_Blue");
}

public plugin_natives()
{
	register_native("jbe_get_soccergame", "jbe_get_soccergame", 1);
	register_native("jbe_open_soccer", "jbe_open_soccer", 1);
}

public jbe_get_soccergame() return g_bSoccerGame;
public jbe_open_soccer(pId) return Show_FootBalMenu(pId);

public plugin_precache()
{
	modelindex = precache_model(BALL_MODELS);
	g_pSpriteBeam = engfunc(EngFunc_PrecacheModel, "sprites/smoke.spr");
}

public plugin_end()
{
	DestroyForward(g_iFwdFootball);
}

public ClCmd_Football(pId)
{
	return Show_FootBalMenu(pId);
}

Show_FootBalMenu(pId)
{

	new szMenu[512],  iLen, iKeys;
	FormatMain("\yМеню Футбола^n^n");
	FormatItem("\y1. \w%s матч^n", g_bSoccerGame ? "Закончить" : "Начать" ), iKeys |= (1<<0);
	switch(g_bSoccerGame)
	{
		case true:
		{
			FormatItem("\y2. \w%s мяч^n^n", g_iSoccerBall ? "Убрать" : "Установить"), iKeys |= (1<<1);
			
			FormatItem("\y3. \wНастройка команд^n^n"), iKeys |= (1<<2);

			FormatItem("\y4. \wУвеличить скорость мяча^n"), iKeys |= (1<<3);
			FormatItem("\y5. \wУменьшить скорость мяча^n"), iKeys |= (1<<4);

			FormatItem("\y6. \wМеню сетки^n"), iKeys |= (1<<5);

		}
		case false:
		{
			FormatItem("\y2. \d%s мяч^n^n", g_iSoccerBall ? "Установить" : "Убрать");
			
			FormatItem("\y3. \yНастройка команд^n^n");

			FormatItem("\y4. \dУвеличить скорость мяча^n");
			FormatItem("\y5. \dУменьшить скорость мяча^n");

			FormatItem("\y6. \dМеню сетки^n");
		}
	}

	
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_FootBalMenu");
}



public Handle_FootBalMenu(pId, iKey)
{

	switch(iKey)
	{
		case 0: 
		{
			if(g_iRoundEnd)
			{
				UTIL_SayText(pId, "!g* !yЖдите окончание раунда");
				return PLUGIN_HANDLED;
			}
			g_bSoccerGame = !g_bSoccerGame;
			g_iSoccerSpeedHit = 600;
			if(g_bSoccerGame) 
			{
				set_task_ex(1.0, "jbe_soccer_score_informer", TASK_SHOW_SOCCER_SCORE, .flags = SetTask_Repeat);
				for(new i; i < 3; i++) EnableHamForward(g_iHamHookSoccer[i]);

				//EnableHamForward(g_iHamHookDeploy);
				EnableHookChain(g_iSoccerHook[0]);
#if defined WANTED_FOR_GAME
				EnableHookChain(g_iSoccerHook[1]);
#endif
				jbe_box_status(true, pId);
				jbe_set_formatex_daymode(5);
				
				formatex(g_iSoccerTeamName[0], 31, "1-ая Команда");
				formatex(g_iSoccerTeamName[1], 31, "2-ая Команда");
				
				if(iEnt) Soccer_Remove_Entity();
				if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
			}
			else 
			{
				jbe_soccer_disable_all();
			}
			new g_ForwardResult;
			ExecuteForward(g_iFwdFootball , g_ForwardResult , bool:g_bSoccerGame);
		}
		case 1:	
		{
			if(g_iSoccerBall) jbe_soccer_remove_ball();
			else jbe_soccer_create_ball(pId);
		}
		case 2: return Show_SettingTeam(pId);
		case 3:
		{
			if(g_iSoccerSpeedHit == MAX_SPEED) g_iSoccerSpeedHit = MIN_SPEED;
			
			g_iSoccerSpeedHit += 100;
				
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n увеличил скорость футбольного мяча до %i юнитов.", pId, g_iSoccerSpeedHit)
			#if defined ENABLE_DUCK
			UTIL_SayText(pId, "!g* !yСкорость мяча была увиличена !tСлабый - !g%dunits!y, !tСильный - !g%dunits !yудар", g_iSoccerSpeedHit, g_iSoccerSpeedHit + 400);
			#else
			UTIL_SayText(pId, "!g* !yСкорость мяча была увиличена !tдо !g%dunits !yза удар", g_iSoccerSpeedHit);
			#endif
		}

		case 4:
		{
			if(g_iSoccerSpeedHit == MIN_SPEED) g_iSoccerSpeedHit = MIN_SPEED + 100;
			
			g_iSoccerSpeedHit -= 100;
			
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n уменьшил скорость футбольного мяча до %i юнитов.", pId, g_iSoccerSpeedHit)
			#if defined ENABLE_DUCK
			UTIL_SayText(pId, "!g* !yСкорость мяча была уменьшена !tСлабый - !g%dunits!y, !tСильный - !g%dunits !yудар", g_iSoccerSpeedHit, g_iSoccerSpeedHit + 400);
			#else
			UTIL_SayText(pId, "!g* !yСкорость мяча была уменьшена !tдо !g%dunits !yза удар", g_iSoccerSpeedHit);
			#endif
		}
		case 5: return jbe_box_menu(pId);
		
		


		
		case 9: return jbe_open_main_menu(pId, 1);
	}
	return Show_FootBalMenu(pId);
}

Show_SettingTeam(pId)
{
	new szMenu[512], iLen, iKeys;
	
	FormatMain("\yНастройка команд^n^n");
	
	FormatItem("\y1. \w1-ая команда: \y%s^n", g_iSoccerTeamName[0]), iKeys |= (1<<0);
	FormatItem("\y2. \w2-ая команда: \y%s^n", g_iSoccerTeamName[1]), iKeys |= (1<<1);
	FormatItem("\y3. \wДобавить очко к 1-ой команде^n"), iKeys |= (1<<2);
	FormatItem("\y4. \wОтнять очко к 1-ой команде^n"), iKeys |= (1<<3);
	FormatItem("\y5. \wДобавить очко к 2-ой команде^n"), iKeys |= (1<<4);
	FormatItem("\y6. \wОтнять очко к 2-ой команде^n"), iKeys |= (1<<5);
	FormatItem("\y7. \wОбнулить счёт^n^n"), iKeys |= (1<<6);
	
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT"), iKeys |= (1<<9);
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_SettingTeam");

}

public Handle_SettingTeam(pId, iKey)
{
	switch(iKey)
	{
		case 0: client_cmd(pId, "messagemode team_one");
		case 1: client_cmd(pId, "messagemode team_two");
		case 2: g_iSoccerScore[0]++;
		case 3: if(g_iSoccerScore[0]) g_iSoccerScore[0]--;
		case 4: g_iSoccerScore[1]++;
		case 5: if(g_iSoccerScore[1])g_iSoccerScore[1]--;
		case 6: g_iSoccerScore = {0, 0};
		
		case 8: return Show_FootBalMenu(pId)
		case 9: return PLUGIN_HANDLED;
	}
	return Show_SettingTeam(pId);
}

public Command_SoccerTeam_Red(pId)
{
	if(!g_bSoccerGame && !jbe_is_user_chief(pId) && !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	new szArgs[32];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	re_mysql_escape_string(szArgs, MAX_NAME_LENGTH - 1);
	
	formatex(g_iSoccerTeamName[0], 31, "%s", szArgs);
	
	UTIL_SayText(0, "!g* !yНачальник %n, поменял название первой команды на: !g%s", pId, g_iSoccerTeamName[0]);
	return Show_SettingTeam(pId);
}

public Command_SoccerTeam_Blue(pId)
{
	if(!g_bSoccerGame && !jbe_is_user_chief(pId) && !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	new szBuffer[32]; 
	read_args(szBuffer, charsmax(szBuffer));
	remove_quotes(szBuffer);
	re_mysql_escape_string(szBuffer, MAX_NAME_LENGTH - 1);
	
	formatex(g_iSoccerTeamName[1], 31, "%s", szBuffer);
	
	UTIL_SayText(0, "!g* !yНачальник %n, поменял название второй команды на: !g%s", pId, g_iSoccerTeamName[1]);
	
	return Show_SettingTeam(pId);
}

jbe_soccer_create_ball(pPlayer)
{
	if(g_iSoccerBall) return g_iSoccerBall;
	static iszFuncWall = 0;
	if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_iSoccerBall = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
	if(is_entity(g_iSoccerBall))
	{
		set_entvar(g_iSoccerBall, var_classname, "ballsoccer");
		set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
		set_entvar(g_iSoccerBall, var_movetype, MOVETYPE_BOUNCE);
		
		set_entvar(g_iSoccerBall, var_modelindex, modelindex);
		set_entvar(g_iSoccerBall, var_model, BALL_MODELS);

		//engfunc(EngFunc_SetSize, g_iSoccerBall, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
		new Float:size[3];
		math_mins_maxs(Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0}, size);
		set_entvar(g_iSoccerBall, var_size, size);
		set_entvar(g_iSoccerBall, var_framerate, 1.0);
		set_entvar(g_iSoccerBall, var_sequence, 0);
		set_entvar(g_iSoccerBall, var_nextthink, get_gametime() + 0.04);
		set_entvar(g_iSoccerBall, var_gravity, 0.9)
		jbe_set_rendering(g_iSoccerBall, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 20)
		fm_get_aiming_position(pPlayer, g_flSoccerBallOrigin);
		set_entvar(g_iSoccerBall, var_origin, g_flSoccerBallOrigin);
		//engfunc(EngFunc_SetOrigin, g_iSoccerBall, g_flSoccerBallOrigin);
		engfunc(EngFunc_DropToFloor, g_iSoccerBall);
		set_entvar(g_iSoccerBall, var_iuser1, 0);
		g_iBallSpin = 1;
		return g_iSoccerBall;
	}
	jbe_soccer_remove_ball();
	return 0;
}

jbe_soccer_remove_ball()
{
	if(g_iSoccerBall)
	{
		if(g_bSoccerBallTrail)
		{
			g_bSoccerBallTrail = false;
			//CREATE_KILLBEAM(g_iSoccerBall);
		}
		if(g_iSoccerBallOwner)
		{
			//if(g_iSoccerBallOwner != jbe_get_chief_id()) jbe_set_hand_model(g_iSoccerBallOwner);
			//CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
		}
		if(is_entity(g_iSoccerBall)) engfunc(EngFunc_RemoveEntity, g_iSoccerBall);
		g_iSoccerBall = 0;
		g_iSoccerBallOwner = 0;
		g_iSoccerKickOwner = 0;
		g_iSoccerKickOwnerName = 0;
		g_iBallControler = 0
		g_iBallSpin = 1
	}
	if(iEnt) Soccer_Remove_Entity()
	if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
}

jbe_soccer_update_ball()
{
	if(g_iSoccerBall)
	{
		if(pev_valid(g_iSoccerBall))
		{
			if(g_bSoccerBallTrail)
			{
				g_bSoccerBallTrail = false;
				//CREATE_KILLBEAM(g_iSoccerBall);
			}
			if(g_iSoccerBallOwner)
			{
				//if(g_iSoccerBallOwner != jbe_get_chief_id()) jbe_set_hand_model(g_iSoccerBallOwner);
				//CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
			}
			set_entvar(g_iSoccerBall, var_velocity, {0.0, 0.0, 0.0});
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			set_entvar(g_iSoccerBall, var_modelindex, modelindex);
			set_entvar(g_iSoccerBall, var_model, BALL_MODELS);
			//engfunc(EngFunc_SetSize, g_iSoccerBall, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
			new Float:size[3];
			math_mins_maxs(Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0}, size);
			set_entvar(g_iSoccerBall, var_size, size);
			//engfunc(EngFunc_SetOrigin, g_iSoccerBall, g_flSoccerBallOrigin);
			set_entvar(g_iSoccerBall, var_origin, g_flSoccerBallOrigin);
			engfunc(EngFunc_DropToFloor, g_iSoccerBall);
			g_iSoccerBallOwner = 0;
			g_iSoccerKickOwner = 0;
			g_iSoccerKickOwnerName = 0;
			g_iBallControler = 0;
			g_iBallSpin = 1;
			//rg_set_entity_visibility(g_iSoccerBall, 1) ;
		}
		else jbe_soccer_remove_ball();
	}
	if(iEnt) Soccer_Remove_Entity();
	if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
}

jbe_soccer_update_ball_ex()
{
	if(g_iSoccerBall)
	{
		if(pev_valid(g_iSoccerBall))
		{
			if(g_bSoccerBallTrail)
			{
				g_bSoccerBallTrail = false;
				//CREATE_KILLBEAM(g_iSoccerBall);
			}
			if(g_iSoccerBallOwner)
			{
				//if(g_iSoccerBallOwner != jbe_get_chief_id()) jbe_set_hand_model(g_iSoccerBallOwner);
				//CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
			}
			set_entvar(g_iSoccerBall, var_velocity, {0.0, 0.0, 0.0});
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			set_entvar(g_iSoccerBall, var_modelindex, modelindex);
			set_entvar(g_iSoccerBall, var_model, BALL_MODELS);

			new Float:size[3];
			math_mins_maxs(Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0}, size);
			set_entvar(g_iSoccerBall, var_size, size);

			set_entvar(g_iSoccerBall, var_origin, g_flSoccerBallOrigin);
			engfunc(EngFunc_DropToFloor, g_iSoccerBall);
			
			g_iSoccerBallOwner = 0;
			g_iSoccerKickOwner = 0;
			g_iSoccerKickOwnerName = 0;
			g_iBallControler = 0;
			g_iBallSpin = 1;
			//rg_set_entity_visibility(g_iSoccerBall, 1) ;
		}
		else jbe_soccer_remove_ball();
	}
}

public jbe_soccer_score_informer()
{
	static g_iType[128]
	static iPlayers[MAX_PLAYERS], iPlayerCount, pPlayer;
	
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots);
	
	//set_hudmessage(255, 255, 0, 0.7, 0.05, 0, 0.0, 1.1, 0.2, 0.2, -1);
	set_dhudmessage(102, 69, 0, -1.0, 0.01, 0, 0.0, 0.9, 0.1, 0.1);
	for(new i; i < iPlayerCount; i++)
    {
		pPlayer = iPlayers[i];

		switch(jbe_get_user_team(pPlayer))
		{
			case 1: 
			{
				if(jbe_is_user_alive(pPlayer))
				{
					if(jbe_get_user_skin(pPlayer) <= 6)
					{
						formatex(g_iType, charsmax(g_iType), "Вы в %s команде", g_iSkinNumber[jbe_get_user_skin(pPlayer)]);
					}else formatex(g_iType, charsmax(g_iType), "Вы не в команде");
				} else formatex(g_iType, charsmax(g_iType), "");
			}
			default: formatex(g_iType, charsmax(g_iType), "");
		}

		
		show_dhudmessage(pPlayer, "%s -  %d | %d - %s^n%s", g_iSoccerTeamName[0], g_iSoccerScore[0], g_iSoccerScore[1], g_iSoccerTeamName[1], g_iType);
	}
}

public Ham_ItemDeploy_Post(iEntity)
{
	if(g_bSoccerGame)
	{
		new pId = get_member(iEntity, m_pPlayer);
		if(jbe_get_user_team(pId) == 1 && !jbe_is_user_wanted(pId)) engclient_cmd(pId, "weapon_knife");
	}
}

public Ham_ObjectCapg_iPost(pId)
{
	if(g_iSoccerBall && g_iSoccerBallOwner == pId)
	{
		if(pev_valid(g_iSoccerBall))
		{
			new iButton = get_entvar(pId, var_button);
			
			if(iButton & IN_USE)
			{
				g_iBallControler = 0;
				new Float:vecOrigin[3];
				get_entvar(g_iSoccerBall, var_origin, vecOrigin);
				if(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_EMPTY) return;
				new Float:vecVelocity[3];
#if defined ENABLE_DUCK
				
				if(iButton & IN_DUCK)
				{
					if(pId != jbe_get_chief_id())
					{
						if(iButton & IN_FORWARD) UTIL_PlayerAnimation(pId, "soccer_crouchrun");
						else UTIL_PlayerAnimation(pId, "soccer_crouch_idle");
					}
					velocity_by_aim(pId, g_iSoccerSpeedHit + 400, vecVelocity);
					#if defined BEAMDUELS
					if(iEnt) Soccer_Remove_Entity();
					if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
					#endif
				}
				else
#endif
				{
					if(pId != jbe_get_chief_id())
					{
						if(iButton & IN_FORWARD)
						{
							
							if(iButton & IN_RUN) UTIL_PlayerAnimation(pId, "soccer_walk");
							else UTIL_PlayerAnimation(pId, "soccer_run");
							
						}
						else UTIL_PlayerAnimation(pId, "soccer_idle");
					}
					if(iButton & IN_RELOAD && g_iBallSpin)
					{
						g_iBallControler = pId
						set_task(0.1, "jbe_soccer_control_ball")
					}
					velocity_by_aim(pId, g_iSoccerSpeedHit, vecVelocity);
					
					#if defined BEAMDUELS
					if(iEnt) Soccer_Remove_Entity();
					if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
					#endif
				}
				g_iSoccerBallTrail = true;
				
				set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
				set_entvar(g_iSoccerBall, var_velocity, vecVelocity);
				g_iBallCanTouch[g_iSoccerBallOwner] = 0
				set_task(1.0, "jbe_soccer_can_touch", g_iSoccerBallOwner)
				remove_task(TASK_TRAIL_BALL)
				CREATE_KILLBEAM(g_iSoccerBall)
				jbe_set_ball_trail_color(pId)
				set_task(0.2, "trail_ball", pId + TASK_TRAIL_BALL)
				emit_sound(pId, CHAN_AUTO, "jb_engine/soccer/ball_kick.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				g_iSoccerBallOwner = 0;
				g_iSoccerKickOwner = pId;
				g_iSoccerKickOwnerName = pId;
				get_entvar(g_iSoccerKickOwner, var_origin, eOrigin);

			}
		}
		else jbe_soccer_remove_ball();
	}
}

public jbe_soccer_can_touch(pId) g_iBallCanTouch[pId] = 1

public jbe_soccer_control_ball()
{
	if( g_iBallControler > 0 && g_iSoccerBall)
	{
		new Float:NewVelocity[3], Float:OldVelocity[3]
		velocity_by_aim(g_iBallControler, floatround(g_iSoccerSpeedHit * 0.80), NewVelocity)
		entity_get_vector(g_iSoccerBall, EV_VEC_velocity, OldVelocity)
		NewVelocity[0] = (OldVelocity[0] + NewVelocity[0] * 0.3) * 0.85
		NewVelocity[1] = (OldVelocity[1] + NewVelocity[1] * 0.3) * 0.85
		NewVelocity[2] = OldVelocity[2] * 0.85
		entity_set_vector(g_iSoccerBall, EV_VEC_velocity, NewVelocity)
		set_task(0.1, "jbe_soccer_control_ball")
		//set_task(0.5, "jbe_soccer_control_ball")
		//static icount
		//server_print("%d", icount++);
	}
}

public jbe_soccer_rm_control_ball() g_iBallControler = 0

public client_PreThink(pId)
{
	if( g_iSoccerBall && jbe_is_user_alive(pId) )
	{
		if( pev_valid(g_iSoccerBall) )
		{
			if(g_iSoccerBallOwner)
			{
				new iButton = get_entvar(pId,var_button), 
				oldbutton = get_entvar(pId,var_oldbuttons);

				if(g_iSoccerBallOwner == pId && ((iButton & IN_RELOAD) && !(oldbutton & IN_RELOAD)))
				{
					g_iBallControler = 0;
					new Float:vecOrigin[3];
					get_entvar(g_iSoccerBall, var_origin, vecOrigin);
					if(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_EMPTY) return;
					new Float:vecVelocity[3];
#if defined ENABLE_DUCK
					
					if(iButton & IN_DUCK && !(oldbutton & IN_DUCK))
					{
						if(pId != jbe_get_chief_id())
						{
							if(iButton & IN_FORWARD) UTIL_PlayerAnimation(pId, "soccer_crouchrun");
							else UTIL_PlayerAnimation(pId, "soccer_crouch_idle");
						}
						velocity_by_aim(pId, g_iSoccerSpeedHit, vecVelocity);
						#if defined BEAMDUELS
						if(iEnt) Soccer_Remove_Entity();
						if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
						#endif
					}
					else
#endif
					{
						if(pId != jbe_get_chief_id())
						{
							if(iButton & IN_FORWARD && !(oldbutton & IN_FORWARD))
							{
								
								if(iButton & IN_RUN && !(oldbutton & IN_RUN)) UTIL_PlayerAnimation(pId, "soccer_walk");
								else UTIL_PlayerAnimation(pId, "soccer_run");
								
							}
							else UTIL_PlayerAnimation(pId, "soccer_idle");
						}

						g_iBallControler = pId
						if(task_exists(TASK_SOCCER_CONTROL)) remove_task(TASK_SOCCER_CONTROL);
						set_task(0.1, "jbe_soccer_control_ball", TASK_SOCCER_CONTROL)
						
						velocity_by_aim(pId, g_iSoccerSpeedHit, vecVelocity);
						#if defined BEAMDUELS
						if(iEnt) Soccer_Remove_Entity();
						if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
						#endif
					}
					g_iSoccerBallTrail = true;
					
					set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
					set_entvar(g_iSoccerBall, var_velocity, vecVelocity);
					g_iBallCanTouch[g_iSoccerBallOwner] = 0
					set_task(1.0, "jbe_soccer_can_touch", g_iSoccerBallOwner)
					remove_task(pId + TASK_TRAIL_BALL)
					CREATE_KILLBEAM(g_iSoccerBall)
					jbe_set_ball_trail_color(pId)
					set_task(0.2, "trail_ball", pId + TASK_TRAIL_BALL)
					emit_sound(pId, CHAN_AUTO, "jb_engine/soccer/ball_kick.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					g_iSoccerBallOwner = 0;
					g_iSoccerKickOwner = pId;
					g_iSoccerKickOwnerName = pId;
					get_entvar(g_iSoccerKickOwner, var_origin, eOrigin);
				
				}
				if(g_iSoccerBallOwner != pId && g_iBallCanTouch[pId] && jbe_get_user_skin(pId) != jbe_get_user_skin(g_iSoccerBallOwner))
				{

					new Float:g_ifEntityOrigin[3], Float:g_ifPlayerOrigin[3], Float:g_ifDistance
					get_entvar(g_iSoccerBall, var_origin, g_ifEntityOrigin)
					get_entvar(pId, var_origin, g_ifPlayerOrigin)
					g_ifDistance = get_distance_f(g_ifEntityOrigin, g_ifPlayerOrigin)
					if( g_ifDistance < UNITS_OWNER )
					{
						
						g_iBallCanTouch[g_iSoccerBallOwner] = 0
						set_task(1.0, "jbe_soccer_can_touch", g_iSoccerBallOwner)
						g_iSoccerBallOwner = pId
						g_iSoccerKickOwnerName = pId;
						g_iSoccerBallTrail = 0
						remove_task(TASK_TRAIL_BALL)
						CREATE_KILLBEAM(g_iSoccerBall)
						jbe_set_ball_trail_color(pId)
						set_task(0.2, "trail_ball", pId + TASK_TRAIL_BALL)
						emit_sound(pId, CHAN_AUTO, "jb_engine/soccer/grab_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					}
				}
			}
		}
	}
}

public Ham_WallThink_Post(iEntity)
{
	if(iEntity == g_iSoccerBall)
	{
		if(pev_valid(iEntity))
		{
			set_entvar(iEntity, var_nextthink, get_gametime() + 0.01);
			if(g_iSoccerBallOwner)
			{
				new Float:vecVelocity[3];
				get_entvar(g_iSoccerBallOwner, var_velocity, vecVelocity);
				if(vector_length(vecVelocity) > 20.0)
				{
					new Float:fAngles[3];
					vector_to_angle(vecVelocity, fAngles);
					fAngles[0] = 0.0;
					set_entvar(iEntity, var_angles, fAngles);
					set_entvar(iEntity, var_sequence, 1);
				}
				else set_entvar(iEntity, var_sequence, 0);
				
				
				new Float:vAngles[3], Float:vReturn[3];
				new const Float:vVelocity[3] = {1.0, 1.0, 0.0};
				get_entvar(g_iSoccerBallOwner, var_origin, vecVelocity);
				get_entvar(g_iSoccerBallOwner, var_v_angle, vAngles);
				vReturn[0] = (floatcos(vAngles[1], degrees) * UNITS_BALLS_PL) +  vecVelocity[0];
				vReturn[1] = (floatsin(vAngles[1], degrees) * UNITS_BALLS_PL) +  vecVelocity[1];
				vReturn[2] = vecVelocity[2];

				vReturn[2] -= (get_entvar(g_iSoccerBallOwner, var_flags) & FL_DUCKING) ? 10 : 30;

				set_entvar(iEntity, var_velocity, vVelocity);
				entity_set_origin(iEntity, vReturn);
			}
			else
			{
				new Float:vecVelocity[3], Float:fVectorLength;
				get_entvar(iEntity, var_velocity, vecVelocity);
				fVectorLength = vector_length(vecVelocity);
				if(g_bSoccerBallTrail && fVectorLength < 600.0)
				{
					g_bSoccerBallTrail = false;
					//CREATE_KILLBEAM(iEntity);
				}
				if(fVectorLength > 20.0)
				{
					new Float:fAngles[3];
					vector_to_angle(vecVelocity, fAngles);
					fAngles[0] = 0.0;
					set_entvar(iEntity, var_angles, fAngles);
					set_entvar(iEntity, var_sequence, 1);
				}
				else set_entvar(iEntity, var_sequence, 0);
				if(g_iSoccerKickOwner)
				{
					new Float:fBallOrigin[3], Float:fOwnerOrigin[3], Float:fDistance;
					get_entvar(g_iSoccerBall, var_origin, fBallOrigin);
					get_entvar(g_iSoccerKickOwner, var_origin, fOwnerOrigin);
					fBallOrigin[2] = 0.0;
					fOwnerOrigin[2] = 0.0;
					fDistance = get_distance_f(fBallOrigin, fOwnerOrigin);
					if(fDistance > 24.0) g_iSoccerKickOwner = 0;
				}
			}
		}
		else jbe_soccer_remove_ball();
	}
}

public Ham_WallTouch_Post(iTouched, iToucher)
{
	if(g_iSoccerBall && iTouched == g_iSoccerBall)
	{
		if(pev_valid(iTouched))
		{
			if(!g_iSoccerBallOwner && jbe_is_user_valid(iToucher))
			{
				if(g_iSoccerKickOwner == iToucher) return;
				//entity_set_int(iTouched, EV_INT_iuser2, iToucher);
				//g_iBallControler = 0;
				g_iSoccerBallOwner = iToucher;
				//set_entvar(iTouched, var_iuser2, g_iSoccerBallOwner);
				set_entvar(iTouched, var_solid, SOLID_TRIGGER);
				set_entvar(iTouched, var_velocity, Float:{0.0, 0.0, 0.0});
				g_iSoccerBallTrail = 0
				remove_task(TASK_TRAIL_BALL)
				CREATE_KILLBEAM(g_iSoccerBall)
				jbe_set_ball_trail_color(iToucher)
				set_task(0.2, "trail_ball", TASK_TRAIL_BALL, _, _, "b")
				emit_sound(iToucher, CHAN_AUTO, "jb_engine/soccer/grab_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				if(g_bSoccerBallTrail)
				{
					g_bSoccerBallTrail = false;
					//CREATE_KILLBEAM(iTouched);
				}
				//CREATE_PLAYERATTACHMENT(iToucher, _, g_pSpriteBall, 3000);
			}
			else
			{
				new Float:iDelay = get_gametime();
				static Float:iDelayOld;
				if((iDelayOld + 0.15) <= iDelay)
				{
					new Float:vecVelocity[3];
					get_entvar(iTouched, var_velocity, vecVelocity);
					if(vector_length(vecVelocity) > 20.0)
					{
						vecVelocity[0] *= 0.85;
						vecVelocity[1] *= 0.85;
						vecVelocity[2] *= 0.75;
						set_entvar(iTouched, var_velocity, vecVelocity);
						if((iDelayOld + 0.22) <= iDelay) emit_sound(iTouched, CHAN_AUTO, "jb_engine/soccer/ball_bounce.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						iDelayOld = iDelay;
					}
				}
			}
			g_iBallControler = 0;
		}
		else jbe_soccer_remove_ball();
	}
}

stock fm_get_aiming_position(pPlayer, Float:vecReturn[3])
{
	new Float:vecOrigin[3], Float:vecViewOfs[3], Float:vecAngle[3], Float:vecForward[3];
	get_entvar(pPlayer, var_origin, vecOrigin);
	get_entvar(pPlayer, var_view_ofs, vecViewOfs);
	xg_ivec_add(vecOrigin, vecViewOfs, vecOrigin);
	get_entvar(pPlayer, var_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	global_get(glb_v_forward, vecForward);
	xg_ivec_mul_scalar(vecForward, 8192.0, vecForward);
	xg_ivec_add(vecOrigin, vecForward, vecForward);
	engfunc(EngFunc_TraceLine, vecOrigin, vecForward, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecReturn);
}

stock xg_ivec_add(const Float:vec1[], const Float:vec2[], Float:out[])
{
	out[0] = vec1[0] + vec2[0];
	out[1] = vec1[1] + vec2[1];
	out[2] = vec1[2] + vec2[2];
}

stock xg_ivec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}

stock UTIL_PlayerAnimation(pPlayer, const szAnimation[]) // Спасибо большое KORD_12.7
{
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	new Float:flGametime = get_gametime();
	set_pev(pPlayer, pev_frame, 0.0);
	set_pev(pPlayer, pev_framerate, 1.0);
	set_pev(pPlayer, pev_animtime, flGametime);
	set_pev(pPlayer, pev_sequence, iAnimDesired);
	set_pdata_int(pPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(pPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	set_pdata_float(pPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(pPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(pPlayer, m_flLastEventCheck, flGametime, linux_diff_animating);
	set_pdata_int(pPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);   
	set_pdata_float(pPlayer, m_flLastAttackTime, flGametime, linux_diff_player);
}



isBall(ent)
{
	new szClass[32];
	get_entvar(ent, var_classname, szClass, charsmax(szClass));
	return equal(szClass, "ballsoccer");
}
new Float:GvecOrigin[3];
#if defined BEAMDUELS
new g_iUserSkinOut;
#endif
#define THIBKBEAM   0.3

public box_stop_touch(box, pId, const szClass[]) 
{ 
	if(isBall(pId)) 
	{
		if(equal(szClass, "OutBox") && g_iSoccerKickOwnerName)
		{
			if(is_entity(pId) && g_iSoccerBall  )
			{
				new Float:vecVelocity[3];
				get_entvar(g_iSoccerBall, var_velocity, vecVelocity);
				if(vector_length(vecVelocity) == 0.0) 
					return PLUGIN_HANDLED; 
				
				get_entvar(pId, var_origin, GvecOrigin);
				UTIL_SayText(0, "!g* !yМяч вышел от !t%n!y!", g_iSoccerKickOwnerName);
				if(jbe_is_user_connected(g_iSoccerKickOwnerName))
				{
					//jbe_set_ball_trail_color(id)
					set_hudmessage(g_iBallTrailRGB[0], g_iBallTrailRGB[1], g_iBallTrailRGB[2], -1.0, 0.5, 1, 5.0, 5.0, 0.2, 0.2, -1);
					if(jbe_get_user_team(g_iSoccerKickOwnerName) == 1)
					{
						ShowSyncHudMsg(0 , g_iSyncSoccerScore, "Мяч вышел за пределы поле^nот игрока %s команды^nмяч появиться через 3 секунды", g_iSkinNumber[jbe_get_user_skin(g_iSoccerKickOwnerName)]);
						
						//rg_set_entity_visibility(g_iSoccerBall, 0);
						//set_task_ex(3.0, "soccer_update", TASK_SHOW_OUTBALL, GvecOrigin, sizeof GvecOrigin);
						
						jbe_soccer_update_ball_ex();
						if(is_entity(g_iSoccerBall))
						{
							engfunc(EngFunc_SetOrigin, g_iSoccerBall, GvecOrigin);
							drop_to_floor ( g_iSoccerBall )
						}
						
#if defined BEAMDUELS
						if(iEnt) Soccer_Remove_Entity()
						
						
						iEnt = rg_create_entity("info_target", false);
						SetThink(iEnt, "think_step");
						set_entvar(iEnt, var_nextthink, get_gametime() + THIBKBEAM);
						g_iUserSkinOut = jbe_get_user_skin(g_iSoccerKickOwnerName);
#endif
					}
					else 
					{
						ShowSyncHudMsg(0 , g_iSyncSoccerScore, "Мяч вышел за пределы поле");	
						jbe_soccer_update_ball();
						if(is_entity(g_iSoccerBall))
						{
							engfunc(EngFunc_SetOrigin, g_iSoccerBall, GvecOrigin);
							drop_to_floor ( g_iSoccerBall )
						}
					}
				}
				//if(task_exists( TASK_SHOW_OUTBALL)
				
				emit_sound(0, CHAN_AUTO, "jb_engine/soccer/whitle_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				//CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 0, 255, 255, _); 
				return PLUGIN_HANDLED; 
			}
		}
	}
	return PLUGIN_CONTINUE; 
}

public soccer_update(Float:Art[])
{
	jbe_soccer_update_ball_ex();
	if(is_entity(g_iSoccerBall))
	{
		engfunc(EngFunc_SetOrigin, g_iSoccerBall, Art);
		drop_to_floor ( g_iSoccerBall )
	}
	
}

public Soccer_Remove_Entity()
{
	if(is_entity(iEnt))
	{
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
		set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
		iEnt = -1;
	}
	//if(task_exists(TASK_SHOW_OUTBALL)) remove_task(TASK_SHOW_OUTBALL);
}

stock rg_set_entity_visibility(entity, visible = 1) 
{
    set_entvar(entity, var_effects, visible == 1 ? get_entvar(entity, var_effects) & ~EF_NODRAW : get_entvar(entity, var_effects) | EF_NODRAW);
    return 1;
}

#if defined BEAMDUELS
public think_step(iEnt)
{
		static  pId;

		while((pId = engfunc(EngFunc_FindEntityInSphere, pId, GvecOrigin, 300.0)))
		{
			if(jbe_is_user_valid(pId) && jbe_is_user_alive(pId) && jbe_get_user_team(pId) == 1 && jbe_get_user_skin(pId) == g_iUserSkinOut)
			{
				new Float:ptd[3], 
					Float:push = 3.0;
	 
				get_entvar(pId, var_origin, ptd);

				ptd[0] -= GvecOrigin[0]; 
				ptd[1] -= GvecOrigin[1]; 
				ptd[2] -= GvecOrigin[2];
				
				ptd[0] *= push; 
				ptd[1] *= push; 
				ptd[2] *= push;
				
				set_entvar(pId, var_velocity, ptd);
				
				
				static Float:gCurTime, Float:g_iUserFloatTime[MAX_PLAYERS + 1]; gCurTime = get_gametime(); 
				
				if(g_iUserFloatTime[pId] <= gCurTime)
				{
					CenterMsgFix_PrintMsg(pId, print_center, "Зафиксирован Фол от вашей команды");
					g_iUserFloatTime[pId] = gCurTime + 3.0;
				}
			}
		}
		
	
	set_entvar(iEnt, var_nextthink, get_gametime() + THIBKBEAM);
}
#endif

public box_start_touch(box, pId, const szClass[])
{	
	if(isBall(pId)) 
	{
		if(is_entity(pId) && g_iSoccerBall)
		{
			if(equal(szClass, "Orange"))
			{
				new Float:vecOrigin[3];
				get_entvar(pId, var_origin, vecOrigin);

				new Float:distance = get_distance_f(vecOrigin,eOrigin);
				
				if(jbe_is_user_connected(g_iSoccerKickOwnerName) && jbe_get_user_team(g_iSoccerKickOwnerName) == 1)
				{
					
				}
				set_dhudmessage(g_iBallTrailRGB[0], g_iBallTrailRGB[1], g_iBallTrailRGB[2], -1.0, 0.5, 1, 5.0, 5.0);
				show_dhudmessage(0 , "Мяч забили в команду %s^nс расстояния %d метров!", g_iSoccerTeamName[0], floatround(distance * 0.025));
				g_iSoccerScore[1]++;
				
				jbe_soccer_update_ball();
				
				emit_sound(0, CHAN_AUTO, "jb_engine/soccer/jbe_goal.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				//CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 255, 0, 0, 255, _);
				return PLUGIN_HANDLED;
			}
			else
			if(equal(szClass, "Violet"))
			{
				new Float:vecOrigin[3];
				get_entvar(pId, var_origin, vecOrigin);
				new Float:distance = get_distance_f(vecOrigin,eOrigin);
				
				set_dhudmessage(g_iBallTrailRGB[0], g_iBallTrailRGB[1], g_iBallTrailRGB[2], -1.0, 0.5, 1, 5.0, 5.0);
				show_dhudmessage(0 , "Мяч забили в команду %s^nс расстояния %d метров!", g_iSoccerTeamName[1],  floatround(distance * 0.025));

				g_iSoccerScore[0]++;
				
				if(jbe_get_user_team(g_iSoccerKickOwner) == 1)
				{
					
				}
				
				jbe_soccer_update_ball();
				
				emit_sound(0, CHAN_AUTO, "jb_engine/soccer/jbe_goal.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				//CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 0, 255, 255, _);
				return PLUGIN_HANDLED;
			}
		}
		
	}
	return PLUGIN_CONTINUE;
}

jbe_soccer_disable_all()
{
	jbe_soccer_remove_ball();
	
	g_iSoccerScore = {0, 0};
	g_bSoccerGame = false;
	jbe_box_status(false, 0);

	g_iSoccerSpeedHit = 600;
	for(new i; i < 3; i++) DisableHamForward(g_iHamHookSoccer[i]);

	//DisableHamForward(g_iHamHookDeploy);
	DisableHookChain(g_iSoccerHook[0]);
#if defined WANTED_FOR_GAME
	DisableHookChain(g_iSoccerHook[1]);
#endif
	
	jbe_set_formatex_daymode(1);
	
	if(iEnt) Soccer_Remove_Entity();
	if(task_exists(TASK_SHOW_OUTBALL)) 		remove_task(TASK_SHOW_OUTBALL);
	if(task_exists(TASK_SHCEKING)) 			remove_task(TASK_SHCEKING);
	if(task_exists(TASK_SHOW_SOCCER_SCORE)) remove_task(TASK_SHOW_SOCCER_SCORE);
}

public jbe_day_mode_start(iDayMode, iAdmin)
{
	if(iAdmin)
	{
		if(g_bSoccerGame) jbe_soccer_disable_all();
	}
}

public client_disconnected(pId)
{
	if(jbe_is_user_alive( pId))
	{
		if(pId == jbe_get_chief_id())
		{
			if(g_bSoccerGame) jbe_soccer_disable_all();
		}
	}
}


forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iRoundEnd = false;
}
public LogEvent_RoundEnd()
{
	if(g_bSoccerGame) jbe_soccer_disable_all();
	
	g_iRoundEnd = true
}

public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(!is_user_alive(iVictim)) return;

	switch(jbe_get_day_mode())
	{
		case 1, 2:
		{
			if(g_bSoccerGame)
			{
				if(iVictim == g_iSoccerBallOwner)
				{
					//CREATE_KILLPLAYERATTACHMENTS(iVictim);
					set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
					set_entvar(g_iSoccerBall, var_velocity, {0.0, 0.0, 0.1});
					g_iSoccerBallOwner = 0;
					g_iBallControler = 0;
					g_iBallSpin = 1;
				}
				if(!task_exists(TASK_SHCEKING)) set_task_ex(1.0, "jbe_checkin_soccer_status", TASK_SHCEKING);
			}
			
		}
	}
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		if(jbe_get_user_team(iAttacker) == 1 /*&& jbe_get_user_skin(iAttacker) < 2*/)
		{
			
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}

	}
	return HC_CONTINUE;
}
public jbe_lr_duels()
{
	if(g_bSoccerGame)
		jbe_soccer_disable_all();
}
public jbe_checkin_soccer_status()
{
	if(jbe_aliveplayersnum(1) == 1)
	{
		jbe_soccer_disable_all();
	}
}
public jbe_set_ball_trail_color(id)
{
	if(jbe_get_user_team(id) == 1)
	{
		switch(get_entvar(id, var_skin))
		{
			case 0:
			{
				g_iBallTrailRGB[0] = 255
				g_iBallTrailRGB[1] = 255
				g_iBallTrailRGB[2] = 255
			}
			case 1:
			{
				g_iBallTrailRGB[0] = 47
				g_iBallTrailRGB[1] = 61
				g_iBallTrailRGB[2] = 255
			}
			case 2:
			{
				g_iBallTrailRGB[0] = 186
				g_iBallTrailRGB[1] = 54
				g_iBallTrailRGB[2] = 233
			}
			case 3:
			{
				g_iBallTrailRGB[0] = 240
				g_iBallTrailRGB[1] = 154
				g_iBallTrailRGB[2] = 4
			}
			case 4:
			{
				g_iBallTrailRGB[0] = 100
				g_iBallTrailRGB[1] = 100
				g_iBallTrailRGB[2] = 100
			}
			case 5:
			{
				g_iBallTrailRGB[0] = 0
				g_iBallTrailRGB[1] = 255
				g_iBallTrailRGB[2] = 0
			}
			case 6:
			{
				g_iBallTrailRGB[0] = 255
				g_iBallTrailRGB[1] = 0
				g_iBallTrailRGB[2] = 0
			}
		}
	}
	else
	{
		g_iBallTrailRGB[0] = 255
		g_iBallTrailRGB[1] = 255
		g_iBallTrailRGB[2] = 255
	}
	return PLUGIN_HANDLED
}

public trail_ball()
{
	if(!is_valid_ent(g_iSoccerBall))
	return	

	if(g_iSoccerBallOwner)
	{
		new vOrigin[3]
		get_user_origin(g_iSoccerBallOwner, vOrigin)
		if (s_TrailOrigin[g_iSoccerBallOwner][0] != vOrigin[0] || s_TrailOrigin[g_iSoccerBallOwner][1] != vOrigin[1])
		{
			s_TrailOrigin[g_iSoccerBallOwner][0] = vOrigin[0]
			s_TrailOrigin[g_iSoccerBallOwner][1] = vOrigin[1]
			s_TrailOrigin[g_iSoccerBallOwner][2] = vOrigin[2]
			if(!g_iSoccerBallTrail)
			{
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMFOLLOW)
				write_short(g_iSoccerBall)
				write_short(g_pSpriteBeam)
				write_byte(10)
				write_byte(8)
				write_byte(g_iBallTrailRGB[0])
				write_byte(g_iBallTrailRGB[1])
				write_byte(g_iBallTrailRGB[2])
				write_byte(255)
				message_end()
				g_iSoccerBallTrail = 1
			}
		}
		else
		{
			CREATE_KILLBEAM(g_iSoccerBall)
			g_iSoccerBallTrail = 0
		}
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(g_iSoccerBall)
		write_short(g_pSpriteBeam)
		write_byte(10)
		write_byte(8)
		write_byte(g_iBallTrailRGB[0])
		write_byte(g_iBallTrailRGB[1])
		write_byte(g_iBallTrailRGB[2])
		write_byte(255)
		message_end()
	}
}

stock CREATE_BEAMFOLLOW(pEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(pEntity);
	write_short(pSptite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_KILLBEAM(pEntity)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(pEntity)
	message_end()
}

public jbe_set_rendering(pId, s_RenderFx, s_Red, s_Green, s_Blue, s_RenderMode, s_RenderAmt)
{
	new Float:s_fRenderColor[3]
	s_fRenderColor[0] = float(s_Red)
	s_fRenderColor[1] = float(s_Green)
	s_fRenderColor[2] = float(s_Blue)
	set_entvar(pId, var_renderfx, s_RenderFx)
	set_entvar(pId, var_rendercolor, s_fRenderColor)
	set_entvar(pId, var_rendermode, s_RenderMode)
	set_entvar(pId, var_renderamt, float(s_RenderAmt))
}


stock re_mysql_escape_string(output[], len)
{
	//while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	while(replace(output, len, "\", "")) {}
	while(replace(output, len, "'", "")) {}
	while(replace(output, len, "^"", "")) {}
}

math_mins_maxs(const Float:mins[3], const Float:maxs[3], Float:size[3])
{
    size[0] = (xs_fsign(mins[0]) * mins[0]) + maxs[0]
    size[1] = (xs_fsign(mins[1]) * mins[1]) + maxs[1]
    size[2] = (xs_fsign(mins[2]) * mins[2]) + maxs[2]
}
