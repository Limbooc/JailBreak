#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_stocks>
#include <hamsandwich>
#include <reapi>
//#include <sockets>
#include <time_for_regs>
//#include <map_manager>


#define INFORMER_MAIN

new g_iGlobalDebug;
#include <util_saytext>

//#define LACOSTE_SKIN

//#define GAMECMS_VOICE

#if defined GAMECMS_VOICE
#include <gamecms5>
#endif
//#define DEBUG									// Режим разработчика

new const g_iBuildServer[] = "12/01/2021 13:13";

enum _:INFORMER
{
	INFORMER_RANK = 0,
	INFORMER_DAYWEEK,
	INFORMER_DAYMODE,
	INFORMER_CHIEF,
	INFORMER_PRISONCOUNT,
	INFORMER_GUARDCOUNT,
	INFORMER_TIME,
	RANK_FORMATEX[64],
	DAYWEEK_FORMATEX[64],
	DAYMODE_FORMATEX[64],
	CHIEF_FORMATEX[64],
	PRISONCOUNT_FORMATEX[64],
	GUARDCOUNT_FORMATEX[64],
	TIMEFD_FORMATEX[64],
	TIME_FORMATEX[64],
	bool:INFO_POS_ABS,
	bool:INFO_POS_INT,
	INFO_POS_NUMBER,
	INFO_POS_RED,
	INFO_POS_GREEN,
	INFO_POS_BLUE,
	Float:INFO_POS_FLOAT_X,
	Float:INFO_POS_FLOAT_Y,
	PREFIX_RANK,
	PREFIX_INDIVID,
	PREFIX_CLUB

};
const FORMATEX_INFORMER = 63;

new g_iUserInformer[MAX_PLAYERS + 1][INFORMER];


forward jbe_update_rank(pId);
new iCount[7];
static szFree[40], szWanted[32],g_iSkinView[128];
new GetNetAddress[23];
#include <license>
#pragma semicolon 1
native zl_boss_map();

native jbe_block_reasons(id, reasons[], times, systime, Inflictor[]);

static Ranks[MAX_PLAYERS + 1][64];


forward jbe_load_stats(pId);

new key[64];

/*
jbe_mysql_stats_systems_get(id, 2) - шапка
jbe_mysql_stats_systems_get(id, 3) - 				ПУСТО
jbe_mysql_stats_systems_get(id, 4) - общее время в игре за зека
jbe_mysql_stats_systems_get(id, 5) - общее время в игре за охрана
jbe_mysql_stats_systems_get(id, 6) - общее время в игре за начальника
7 - избр звуки
8 - избр звуки
9 - избр звуки
jbe_mysql_stats_systems_get(id, 10) - кол-во бычков
jbe_mysql_stats_systems_get(id, 50) - кол-во жетон
jbe_mysql_stats_systems_get(id, 11) - кол-во лайков
jbe_mysql_stats_systems_get(id, 12) - 
jbe_mysql_stats_systems_get(id, 13) - кол-во убийст охраны
jbe_mysql_stats_systems_get(id, 14) - кол-во убийст начальника
jbe_mysql_stats_systems_get(id, 15) - кол-во убийст зека убил зека
jbe_mysql_stats_systems_get(id, 16) - кол-во убийст охрана убил зека
jbe_mysql_stats_systems_get(id, 17) - кол-во убийст с ножа
jbe_mysql_stats_systems_get(id, 18) - кол-во убийст в дуэли
jbe_mysql_stats_systems_get(id, 19) - кол-во дамага
jbe_mysql_stats_systems_get(id, 20) - кол-во тип выбора шапки
jbe_mysql_stats_systems_get(id, 21) - кол-во общий убийств
jbe_mysql_stats_systems_get(pId, 21) - получил фд
jbe_mysql_stats_systems_get(pId, 22) - получил бунт
jbe_mysql_stats_systems_get(pId, 23) - взял начлаьника
jbe_mysql_stats_systems_get(pId, 24) - залайкали
jbe_mysql_stats_systems_get(pId, 25) - пролайкал

30- ALIEN damage
31- obberon - damage
32- ALIEN kill
33- obberon - kill

40 - цвет REED
41 - цвет ГРЕЕН
42 - ЦВЕТ блу
43 - положение инф Х
44 - положение инф У
45 - настрйоки инф
46 - настрйоки инф
47 - настрйоки инф
48 - настрйоки инф
49 - настрйоки инф
50 - настрйоки инф
51 - настрйоки инф
52 - настрйоки инф
53 - настрйоки инф
54 - настрйоки инф

55 - избр звуки
56 - избр звуки
57 - избр звуки

g_iUserStats[id][STATS_43] g_iUserStats[id][STATS_44] - не пашут

jbe_mysql_stats_systems_get(id, 50) - кол-во жетон

jbe_mysql_stats_systems_get(id, 69) - ЛВЛ за уровень T
jbe_mysql_stats_systems_get(id, 68) - ЛВЛ за уровень CT
jbe_mysql_stats_systems_get(id, 67) - ЛВЛ 1000
jbe_mysql_stats_systems_get(id, 66) - ЛВЛ 
jbe_mysql_stats_systems_add(id, 86, g_iExpT[id]);
jbe_mysql_stats_systems_add(id, 87, g_iExpCT[id]);

*70 Не работает

*/

new Float:g_iGameTimeFD[MAX_PLAYERS + 1];


enum _:PLAYERS_SETTINGS
{
	PLAYERS_INFORMER = 0,
	PLAYERS_TIME_INFORMER,
	PLAYERS_RANK_INFORMER,
	PLAYERS_HIDE_CHAT_PREFIX,
	PLAYERS_HIDE_CHAT_RANK,
	PLAYERS_HIDE_CHAT_GANG,
	PLAYERS_SAVE_WEAPONS,
	PLAYERS_WEAPONS_MAIN,
	PLAYERS_WEAPONS_SECOND
}
new g_iSettingSaveUser[MAX_PLAYERS + 1][PLAYERS_SETTINGS];


#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])


#define MaskEnt2(%0)    ( 1<<((%0+33) & 31))

#define MODE_INFORMER 	

//#define CHECKING_MYSQL_GET					//Дает возможность какая ячейка свободна


#define JBE_MODE_DEBUG	0		// Включет режим DEBUG, повышает нагрузку, но логгирует всё что связано с работоспособностью мода.


#if JBE_MODE_DEBUG == 1
new g_iStockCallback[ 2 ][ 2 ], g_iUtilSayTextCallBack[ 2 ];
new const g_szTextCallBack[ 2 ][] = { "CREATE_BEAMFOLLOW", "CREATE_KILLBEAM"};
#endif

//#define DEAD_FLAG            (1<<2)

/*===== -> Макросы -> =====*///{

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define IUSER1_BUYZONE_KEY 140658


#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))


#define QUESTMONEY 								50000

//Costume
native Cmd_CostumesMenu(pId);
native jbe_hide_user_costumes(pId);
native jbe_is_user_hide_true_cos(pId);
native jbe_set_group_visiblecos(pId, iType);
native jbe_get_group_visiblecos(pId);
native jbe_get_user_costumes(pId);
native jbe_set_user_costumes(pId, iCostume);
//
native regs_main_menu(pId);
native jbe_is_user_flags(pId, iFlags);
native jbe_showmenuadmin(pId, iFlags);
native jbe_show_adminmenu(pId);
native jbe_jbe_get_discount(iType);

//Duel
native jbe_is_user_duel(id);
native jbe_show_lastmenu(id);
native jbe_is_user_lastid();
native jbe_iduel_status();
native jbe_get_user_lr_quest(pId);
//native jbe_duel_ended(pId);

//box
native jbe_open_box_menu(pId);
native jbe_set_friendlyfire(iType);
native jbe_get_friendlyfire();
native jbe_get_buffer_doors();
native jbe_is_opened_door();
native jbe_get_ff_crusader();

//volley
native jbe_open_volley(pId);
native jbe_get_volley();

//Mafia
native jbe_get_status_mafia();
native jbe_global_get_djihad();
//regs
native get_login(id);

//ranks
native jbe_get_user_ranks(id);
native jbe_get_user_exp_next(pId);
native jbe_mysql_get_exp(pPlayer, iType);
native jbe_mysql_set_exp(id, iType, set);

//setka
native jbe_box_status(status);

//shop
native jbe_show_shopmenu(pId);
native jbe_remove_shop_pn(iPlayer);
native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);

native jbe_global_status(iType);


//game
native jbe_open_tickitbomb(pId);
//Block
native jbe_is_user_data(pId, iType);
native jbe_mysql_block_date(id, login[], len);
native jbe_mysql_block_inf_name(id, login[], len);
native jbe_mysql_block_reason(id, login[], len);
native jbe_mysql_block_time(id);
native jbe_mysql_block_start_time(id);
native jbe_set_user_data(player, iType, iNum);

native jbe_status_block(iType);
native jbe_is_user_grabber(pPlayer);
native jbe_globalnyizapret();
native jbe_open_soccer(pId);
native jbe_get_soccergame();
native jbe_close_doors();
native jbe_open_doors();

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

enum _:Forwards
{
	FORWARD_ON_DUELS,
	FORWARD_ON_RESTART_GAME,
	FORWARD_ON_HLTV_START,
	FORWARD_ON_ROUND_START,
	FORWARD_ON_SET_PLAYER_MODEL,
	FORWARD_ON_ROUND_END,
	FORWARD_ON_USER_VOICE,
	FORWARD_ON_KILLED_POST,
	FORWARD_ON_CHIEF_SET,
	FORWARD_ON_CHIEF_REMOVE,
	FORWARD_ON_SET_USER_TEAM,
	FORWARD_ON_ADD_USER_FREE,
	FORWARD_ON_ADD_USER_WANTED,
	FORWARD_ON_SUB_USER_FREE
	
};

new g_iForward[Forwards];
new g_iChiefStep;
new g_iGlobalGame;



//new g_ScoreAttrib;

new bool:g_iViewInformerSkinNum;

#define USE_SET    2
#define GIB_ALWAYS 2


new g_iszFuncVehicle;
new g_iszTrackTrain;
new HamHook:g_iFwdPlayerKilledPost;
//new HookChain:g_iHookChainRoundEnd;


#define HUD_HIDE_FLAGS          (1<<0 | 1<<1 | 1<<3 | 1<<4 | 1<<5 | 1<<6)
#define SB_ATTRIB_DEAD          (1<<0)
#define XO_PLAYER               5




	
	
new g_iUserGhost,
	bool:isSpeed[MAX_PLAYERS + 1],
	bool:g_iMafiaStatus;

new bool:g_iMainMenu[MAX_PLAYERS + 1];


new g_iBitUserQuestForFree,
	g_iBitUserQuestForWanted;

new g_iBitUserSkinChange;

new g_iFreeCount,
	g_iWantedCount;

new g_iVarSkinNumbre;
//new g_pCvarTimeUnit;


new const g_iSkinNumber[][] = 
{
	"Белый",
	"Синий",
	"Фиолетовый",
	"Желтый"
};

/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

/* -> Оффсеты -> */
const linux_diff_weapon = 4;
const linux_diff_animating =  4;
const linux_diff_player = 5;
const m_iPlayerTeam = 114;
const m_bHasChangeTeamThisRound =  125;
const m_iSpawnCount =  365;
const m_iClip = 51;


/* -> Задачи -> */

enum _:(+= 99)
{
	TASK_ROUND_END  = 87777777,
	TASK_CHANGE_MODEL,
	TASK_FREE_DAY_ENDED,
	TASK_CHIEF_CHOICE_TIME,
	TASK_COUNT_DOWN_TIMER,
	TASK_VOTE_DAY_MODE_TIMER,
	TASK_RESTART_GAME_TIMER,
	TASK_DAY_MODE_TIMER,
	TASK_GHOST_PLAYER,
	TASK_SHOW_DEAD_INFORMER,
	TASK_SHOW_TIME,
	TASK_SHOW_SKIN_COUNT,
	TASK_UPDATE_RANK,
	TASK_OPEN_DOORS,
	TASK_TRANSFER,
	TASK_SHOW_INFORMER,
	TASK_BUFFER_BATUT,
	TASK_BUFFER_TELEPORT
}

enum _:(+= 1)
{
	FLAGSVIP = 0,
	FLAGSADMIN,
	FLAGSSUPERADMIN,
	FLAGSUAIO,
	FLAGSGIRL,
	FLAGSENABLED
}

/* -> Индексы сообщений -> */


#define MsgId_TextMsg 77
#define MsgId_ResetHUD 79
#define MsgId_ShowMenu 96
#define MsgId_ScreenShake 97
#define MsgId_ScreenFade 98
#define MsgId_SendAudio 100
#define MsgId_StatusValue 105
#define MsgId_StatusText 106
#define MsgId_VGUIMenu 114
#define MsgId_ClCorpse 122
#define MsgId_HudTextArgs 145

/* -> Индексы моделей -> */




/* -> Индексы общих настроек для кваров -> */
enum _:MONEY
{
	FREE_DAY_ID,
	FREE_DAY_ALL,
	TEAM_BALANCE,
	DAY_MODE_VOTE_TIME,
	RESTART_GAME_TIME,
	MONEY_ACCESS_TRANSFER,
	MONDAY_FREEDAY
}

/* -> Массивы для кваров -> */
new g_iAllCvars[MONEY];
/*===== <- Макросы <- =====*///}

/*===== -> Битсуммы, переменные и массивы для работы с модом -> =====*///{

/* -> Переменные -> */
new g_bRoundEnd = false,  
	g_iFakeMetaSpawn, 
	//g_iFakeMetaUpdateClientData, 
	g_iSyncMainInformer,
	g_iSyncMainDeadInformer,
	//g_iSyncSoccerScore, 
	//g_iFriendlyFire, 
	g_iCountDown,
	bool:g_bRestartGame = true,
	//bool:g_iRRTimeRestartGame,
	bool:g_iTimer,
	g_iTimerSecond;



/* -> Указатели для спрайтов -> */
new //g_pSpriteBeam, 
	//g_pSpriteBall, 
	//g_pSpriteWave, 
	//g_pSpriteDuelRed, 
	//g_pSpriteDuelBlue, 
	//g_pSpriteLgtning, 
	//g_pSpriteRicho2, 
	SpriteElectro;
	
new Float: throworigin[3],
	Float: droporigin[3],
	bool:g_iDistanceDrop,
	drop_id;

/* -> Массивы -> */
new g_iPlayersNum[4], 
	g_iAlivePlayersNum[4], 
	Trie:g_tRemoveEntities;

new bool:g_iIsBlockedForGame;

/* -> Переменные и массивы для дней и дней недели -> */
new g_iDay, 
	g_iDayWeek;
	
enum _:QUEST_CONFIG
{
	QUEST_DUEL,
	QUEST_WANTED,
	QUEST_FREEDAY,
	QUEST_KILLCHIEF,
	QUEST_MAZHOR,
	QUEST_SHAHID,
	QUEST_LOXOTRON,
	QUEST_ALLRESULT,
	///////////////////////////////////////////
	QUEST_MONEY_DUEL,
	QUEST_MONEY_WANTED,
	QUEST_MONEY_FREEDAY,
	QUEST_EXP_KILLCHIEF,
	QUEST_EXP_MAZHOR,
	QUEST_MONEY_SHAHID,
	QUEST_MONEY_LOXOTRON,
	QUEST_MONEY_ALLRESULT,
	QUEST_EXP_ALLRESULT
	
}

new g_iQuestCvars[QUEST_CONFIG];
	

enum _:STATS_SYSTEMS
{
	STATS_1,
	STATS_2,
	STATS_3,
	STATS_4,
	STATS_5,
	STATS_6,
	STATS_7,
	STATS_8,
	STATS_9,
	STATS_10,

	STATS_11,
	STATS_12,
	STATS_13,
	STATS_14,
	STATS_15,
	STATS_16,
	STATS_17,
	STATS_18,
	STATS_19,
	STATS_20,

	STATS_21,
	STATS_22,
	STATS_23,
	STATS_24,
	STATS_25,
	STATS_26,
	STATS_27,
	STATS_28,
	STATS_29,

	STATS_30,
	STATS_31,
	STATS_32,
	STATS_33,
	STATS_34,
	STATS_35,
	STATS_36,
	STATS_37,
	STATS_38,
	STATS_39,

	STATS_40,
	STATS_41,
	STATS_42,
	STATS_43,
	STATS_44,
	STATS_45,
	STATS_46,
	STATS_47,
	STATS_48,
	STATS_49,

	STATS_50,
	STATS_51,
	STATS_52,
	STATS_53,
	STATS_54,
	STATS_55,
	STATS_56,
	STATS_57,
	STATS_58,
	STATS_59,

	STATS_60,
	STATS_61,
	STATS_62,
	STATS_63,
	STATS_64,
	STATS_65,
	STATS_66,
	STATS_67,
	STATS_68,
	STATS_69,

	STATS_70,
	STATS_71,
	STATS_72,
	STATS_73,
	STATS_74,
	STATS_75,
	STATS_76,
	STATS_77,
	STATS_78,
	STATS_79,

	STATS_80,
	STATS_81,
	STATS_82,
	STATS_83,
	STATS_84,
	STATS_85,
	STATS_86,
	STATS_87,
	STATS_88,
	STATS_89,

	STATS_90,
	STATS_91,
	STATS_92,
	STATS_93,
	STATS_94,
	STATS_95,
	STATS_96,
	STATS_97,
	STATS_98,
	STATS_99,
	STATS_100,
	
	QUEST_1,
	QUEST_2,
	QUEST_3,
	QUEST_4,
	QUEST_5,
	QUEST_6,
	QUEST_7,
	QUEST_8,
	QUEST_9,
	QUEST_10,
	QUEST_11,
	QUEST_12,
	QUEST_13,
	QUEST_14,
	QUEST_15,
	
	EXP_T,
	EXP_CT
	
}
new g_iUserStats[MAX_PLAYERS + 1][STATS_SYSTEMS];




new const g_szDaysWeek[][] =
{
	"JBE_HUD_DAY_WEEK_0",
	"JBE_HUD_DAY_WEEK_1",
	"JBE_HUD_DAY_WEEK_2",
	"JBE_HUD_DAY_WEEK_3",
	"JBE_HUD_DAY_WEEK_4",
	"JBE_HUD_DAY_WEEK_5",
	"JBE_HUD_DAY_WEEK_6",
	"JBE_HUD_DAY_WEEK_7"
};

/* -> Битсуммы, переменные и массивы для режимов игры -> */
enum _:DATA_DAY_MODE
{
	LANG_MODE[32],
	MODE_BLOCKED,
	VOTES_NUM,
	MODE_TIMER,
	MODE_BLOCK_DAYS
}
new Array:g_aDataDayMode, 
	g_iDayModeListSize, 
	g_iDayModeVoteTime, 
	g_iHookDayModeStart, 
	g_iHookDayModeEnded, 
	g_iReturnDayMode,
	g_iDayMode, 
	g_szDayMode[32] = "JBE_HUD_GAME_MODE_0", 
	g_iDayModeTimer, 
	g_szDayModeTimer[16] = "", 
	g_iVoteDayMode = -1,
	g_iBitUserVoteDayMode, 
	g_iBitUserDayModeVoted;



/* -> Массивы для работы с событиями 'hamsandwich' -> */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"game_player_equip", // Выдаёт оружие
	"player_weaponstrip", // Забирает всё оружие
	"func_button", // Кнопка
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};
new HamHook:g_iHamHookForwards[14];
new HamHook:g_iHamHookTrigger[2];


/*===== <- Переменные и массивы для работы с модом <- =====*///}

/*===== -> Битсуммы, переменные и массивы для работы с игроками -> =====*///{

/* -> Битсуммы -> */
new g_iBitUserConnected, 
	g_iBitUserAlive, 
	g_iBitUserVoice, 
	g_iBitUserVoiceNextRound, 
	g_iBitUserModel, 
	g_iBitBlockMenu;

/* -> Переменные -> */

/* -> Массивы -> */
new g_iUserTeam[MAX_PLAYERS + 1],
	g_iUserSkin[MAX_PLAYERS + 1],
	//g_iUserMoney[MAX_PLAYERS + 1], 
	g_szUserModel[MAX_PLAYERS + 1][32];

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iMenuTarget[MAX_PLAYERS + 1];

/* -> Переменные и массивы для начальника -> */
new g_iChiefId, 
	g_iChiefIdOld, 
	g_iChiefChoiceTime, 
	g_szChiefName[32], 
	g_iChiefStatus;
	

new const g_szChiefStatus[][] =
{
	"JBE_HUD_CHIEF_NOT",
	"JBE_HUD_CHIEF_ALIVE",
	"JBE_HUD_CHIEF_DEAD",
	"JBE_HUD_CHIEF_DISCONNECT",
	"JBE_HUD_CHIEF_FREE"
};

/* -> Битсуммы, переменные и массивы для освобождённых заключённых -> */
new g_iBitUserFree, 
	g_iBitUserFreeNextRound, 
	g_szFreeNames[192];
	//g_iFreeLang;


/* -> Битсуммы, переменные и массивы для разыскиваемых заключённых -> */
new g_iBitUserWanted, 
	g_szWantedNames[192];



new g_iBitUserFrozen;





/* -> Переменные и массивы для рендеринга -> */
enum _:DATA_RENDERING
{
	RENDER_STATUS,
	RENDER_FX,
	RENDER_RED,
	RENDER_GREEN,
	RENDER_BLUE,
	RENDER_MODE,
	RENDER_AMT
}
new g_eUserRendering[MAX_PLAYERS + 1][DATA_RENDERING];

#define TOTAL_PLAYER_LEVELS 					16

new const g_szRankName[TOTAL_PLAYER_LEVELS][]= 
{ 
	"JBE_ID_HUD_RANK_NAME_1", 
	"JBE_ID_HUD_RANK_NAME_2", 
	"JBE_ID_HUD_RANK_NAME_3",
	"JBE_ID_HUD_RANK_NAME_4", 
	"JBE_ID_HUD_RANK_NAME_5", 
	"JBE_ID_HUD_RANK_NAME_6", 
	"JBE_ID_HUD_RANK_NAME_7", 
	"JBE_ID_HUD_RANK_NAME_8",
	"JBE_ID_HUD_RANK_NAME_9", 
	"JBE_ID_HUD_RANK_NAME_10", 
	"JBE_ID_HUD_RANK_NAME_11", 
	"JBE_ID_HUD_RANK_NAME_12", 
	"JBE_ID_HUD_RANK_NAME_13", 
	"JBE_ID_HUD_RANK_NAME_14", 
	"JBE_ID_HUD_RANK_NAME_15",
	"JBE_ID_HUD_RANK_NAME_16" 
};

new const g_szRankNameCT[16][]=
{
	"JBE_ID_HUD_RANK_NAME_CT_1",
	"JBE_ID_HUD_RANK_NAME_CT_2",
	"JBE_ID_HUD_RANK_NAME_CT_3",
	"JBE_ID_HUD_RANK_NAME_CT_4",
	"JBE_ID_HUD_RANK_NAME_CT_5",
	"JBE_ID_HUD_RANK_NAME_CT_6",
	"JBE_ID_HUD_RANK_NAME_CT_7",
	"JBE_ID_HUD_RANK_NAME_CT_8",
	"JBE_ID_HUD_RANK_NAME_CT_9",
	"JBE_ID_HUD_RANK_NAME_CT_10",
	"JBE_ID_HUD_RANK_NAME_CT_11",
	"JBE_ID_HUD_RANK_NAME_CT_12",
	"JBE_ID_HUD_RANK_NAME_CT_13",
	"JBE_ID_HUD_RANK_NAME_CT_14",
	"JBE_ID_HUD_RANK_NAME_CT_15",
	"JBE_ID_HUD_RANK_NAME_CT_16"
};

/* -> Битсуммы, переменные и массивы для работы с дуэлями -> */



/*===== <- Битсуммы, переменные и массивы для работы с игроками <- =====*///}

public plugin_precache()
{
	LOAD_CONFIGURATION();
	
	sounds_precache();
	sprites_precache();
	
	jbe_create_buyzone();
	
	g_tRemoveEntities = TrieCreate();
	new const szRemoveEntities[][] = {"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target", "func_vip_safetyzone", "info_vip_start", "func_escapezone", "hostage_entity", "monster_scientist", "func_buyzone"};
	for(new i; i < sizeof(szRemoveEntities); i++) TrieSetCell(g_tRemoveEntities, szRemoveEntities[i], i);

	g_iFakeMetaSpawn = register_forward(FM_Spawn, "FakeMeta_Spawn_Post", 1);
	
	if(zl_boss_map()) return;
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	if (pev_valid(ent))
	{
		engfunc(EngFunc_SetOrigin, ent, Float:{8192.0,8192.0,8192.0});
		dllfunc(DLLFunc_Spawn, ent);
	}
	
}



// Заключенные
enum
{
	MDL_PR = 1,
	MDL_PR_BODY_NUM,
	
	MDL_GIRL,
	MDL_GIRL_BODY_NUM,
	
	MDL_GIRL_GR,
	MDL_GIRL_GR_BODY_NUM,
	
	V_GOLDEN_AK47,
	P_GOLDEN_AK47,
	V_ELECTRO_MP5
};




// Охранники
enum
{
	MDL_GUARD = 1,
	MDL_GUARD_BODY_NUM,
	
	MDL_CHIEF,
	MDL_CHIEF_BODY_NUM
};


enum _:PLAYER_MODELS
{
	PRISONER,
	GUARD,
	CHIEF,
	GIRL,
	GIRL_GR
};











enum _:SERVERS_CVARS
{
	CVARS_SKIN_MIN = 1,
	CVARS_SKIN_MAX,
	CVARS_SKIN_FD,
	CVARS_SKIN_WANTED,
	CVARS_SKIN_FD_GIRLS,
	CVARS_SKIN_WANTED_GIRLS,
	CVARS_SKIN_FOOTBAL_RED,
	CVARS_SKIN_FOOTBAL_BLUE,		
	CVARS_SKIN_FOOTBAL_GIRLS_RED,	
	CVARS_SKIN_FOOTBAL_GIRLS_BLUE,	
	CVARS_SKIN_PAHAN,	
	CVARS_SKIN_ADMIN
}

new g_szConfigs[SERVERS_CVARS];




enum _:PLAYERS_BODY
{
	PR_BODY_NUM = 1,
	GIRL_BODY_NUM,
	GIRL_GR_BODY_NUM,
	GUARD_BODY_NUM,
	CHIEF_BODY_NUM
}
new g_szPlayerBodyModels[PLAYERS_BODY];



enum
{
	SELECT_PRISON = 1,
	SELECT_GUARD,
	SELECT_CVARS,
	SELECT_SOUND
};

new g_szPlayerModel[PLAYER_MODELS][64];


LOAD_CONFIGURATION()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
// CONFIG.INI
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/config.ini", szCfgDir);
	if(!file_exists(szCfgFile))
	{
		new szError[100];
		formatex(szError, charsmax(szError), "[JBE] Отсутсвтует: %s!", szCfgFile);
		set_fail_state(szError);
		return;
	}
	new szBuffer[128], szKey[64], szValue[960], iSectrion;
	new iFile = fopen(szCfgFile, "rt");
	while(iFile && !feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer));
		replace(szBuffer, charsmax(szBuffer), "^n", "");
		if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '{' || szBuffer[0] == '}' || szBuffer[0] == '#') continue;
		if(szBuffer[0] == '[')
		{
			iSectrion++;
			continue;
		}
		parse(szBuffer, szKey, charsmax(szKey), szValue, charsmax(szValue));
		trim(szKey);
		trim(szValue);
		
	
		switch (iSectrion)
		{
			case SELECT_PRISON:
			{
				if(equal(szKey, 		"MDL_PR"))							copy(g_szPlayerModel[PRISONER], 				charsmax(g_szPlayerModel[]), szValue);
				else if(equal(szKey, 	"MDL_PR_BODY_NUM"))					g_szPlayerBodyModels[PR_BODY_NUM] 				= str_to_num(szValue);
				
				else if(equal(szKey, 	"MDL_GIRL")) 						copy(g_szPlayerModel[GIRL], 					charsmax(g_szPlayerModel[]), szValue);
				else if(equal(szKey, 	"MDL_GIRL_BODY_NUM"))				g_szPlayerBodyModels[GIRL_BODY_NUM] 			= str_to_num(szValue);
				
				else if(equal(szKey, 	"MDL_GIRL_GR")) 					copy(g_szPlayerModel[GIRL_GR], 					charsmax(g_szPlayerModel[]), szValue);
				else if(equal(szKey, 	"MDL_GIRL_GR_BODY_NUM"))			g_szPlayerBodyModels[GIRL_GR_BODY_NUM]  		= str_to_num(szValue);
			
			}
			case SELECT_GUARD:
			{
				if(equal(szKey, 		"MDL_GUARD"))						copy(g_szPlayerModel[GUARD], 					charsmax(g_szPlayerModel[]), szValue);
				else if(equal(szKey, 	"MDL_GUARD_BODY_NUM"))				g_szPlayerBodyModels[GUARD_BODY_NUM] 			= str_to_num(szValue);
				else if(equal(szKey, 	"MDL_CHIEF"))						copy(g_szPlayerModel[CHIEF], 					charsmax(g_szPlayerModel[]), szValue);
				else if(equal(szKey, 	"MDL_CHIEF_BODY_NUM"))				g_szPlayerBodyModels[CHIEF_BODY_NUM] 			= str_to_num(szValue);
			}
			case SELECT_CVARS:
			{
				if(equal(szKey, 		"CVARS_SKIN_MIN"))							g_szConfigs[CVARS_SKIN_MIN] 				= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_MAX"))							g_szConfigs[CVARS_SKIN_MAX] 				= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FD"))							g_szConfigs[CVARS_SKIN_FD] 					= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_WANTED"))						g_szConfigs[CVARS_SKIN_WANTED] 				= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FD_GIRLS"))						g_szConfigs[CVARS_SKIN_FD_GIRLS] 			= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_WANTED_GIRLS"))					g_szConfigs[CVARS_SKIN_WANTED_GIRLS] 		= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FOOTBAL_RED"))					g_szConfigs[CVARS_SKIN_FOOTBAL_RED] 		= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FOOTBAL_BLUE"))					g_szConfigs[CVARS_SKIN_FOOTBAL_BLUE] 		= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FOOTBAL_GIRLS_RED"))			g_szConfigs[CVARS_SKIN_FOOTBAL_GIRLS_RED] 	= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_FOOTBAL_GIRLS_BLUE"))			g_szConfigs[CVARS_SKIN_FOOTBAL_GIRLS_BLUE]	= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_PAHAN"))						g_szConfigs[CVARS_SKIN_PAHAN] 				= str_to_num(szValue);
				else if(equal(szKey, 	"CVARS_SKIN_ADMIN"))						g_szConfigs[CVARS_SKIN_ADMIN] 				= str_to_num(szValue);
			}
		}
	}
	fclose(iFile);

	PRECACHE_MODELS();
}

PRECACHE_MODELS()
{
	new i, szBuffer[64];

	for(i = 0; i < sizeof(g_szPlayerModel); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "models/player/%s/%s.mdl", g_szPlayerModel[i], g_szPlayerModel[i]);
		if(file_exists(szBuffer)) 
		{
			engfunc(EngFunc_PrecacheModel, szBuffer);
		}
		else
		{
			log_amx("ERROR!:Не найден модель: %d | %s | %s" , i, g_szPlayerModel[i], szBuffer);
			g_szPlayerModel[i] = "";
		}
	}

}

public plugin_init()
{
	main_init();
	
	jbe_get_cvars();
	event_init();
	game_mode_init();
	hamsandwich_init();
	message_init();
	
	fakemeta_init();
	vehicle_event();
	
	//if(IsValidMap("zs_nightmare2")) return;
	
	
	
	
	
	
	if(zl_boss_map()) return;
	#if defined MODE_INFORMER
	#if !defined INFORMER_MAIN
		set_task_ex(1.0, "jbe_main_informer", , .flags = SetTask_Repeat);
	#endif
	#endif
	menu_init();
	clcmd_init();
	
	
	set_cvar_num("mp_round_restart_delay" , 5);
	
	register_cvar("jbe_cvar_debug", "0");
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
	
	set_cvar_num("sv_restart" , 1);
	
	//new count_ent = entity_count();
    //server_print("Entity in word: %d",count_ent);
}



vehicle_event()
{
	new iEntity = FM_NULLENT;
	
	while( ( iEntity = EF_FindEntityByString( iEntity, "classname", "func_vehicle" ) ) )
	{
		if( g_iszFuncVehicle )
		{
			set_pev_string( iEntity, pev_classname, g_iszFuncVehicle );
		}
		else
		{
			g_iszFuncVehicle = pev( iEntity, pev_classname );
		}
	}
	
	if( g_iszFuncVehicle )
	{

		g_iszTrackTrain = EF_AllocString( "tracktrain" );
		
		RegisterHam( Ham_Killed, "player", "FwdPlayerKilled" );
		RegisterHam( Ham_Use, "func_vehicle", "FwdVehicleUse", true );
		
		DisableHamForward( g_iFwdPlayerKilledPost = RegisterHam( Ham_Killed, "player", "FwdPlayerKilledPost", true ) );
	}
}

public FwdVehicleUse( const iEntity, const id, const iActivator, const iUseType, const Float:flValue )
{
	if( iUseType == USE_SET && is_user_alive( id ) )
	{
		set_pev( iEntity, pev_iuser4, id );
	}
}

public FwdPlayerKilled( const id, const iAttacker )
{
	if( iAttacker > MaxClients && IsEntityVehicle( iAttacker ) )
	{
		new iDriver = pev( iAttacker, pev_iuser4 );
		
		if(iDriver == iAttacker)
			return HAM_IGNORED;
		
		EnableHamForward( g_iFwdPlayerKilledPost );
		
		set_pev_string( iAttacker, pev_classname, g_iszTrackTrain );
		
		if( iDriver && is_user_connected( iDriver ) )
		{
			SetHamParamEntity( 2, iDriver );
			if(g_iUserTeam[iDriver] == 1)
			{
				switch(g_iDayMode)
				{
					case 1:
					{
						if(IsNotSetBit(g_iBitUserWanted, iDriver)) 
						{
							jbe_add_user_wanted(iDriver);
							UTIL_SayText(0, "!g * !y%n получил розыск за давку игрока транспортным средством", iDriver);
						}
					}
					case 2:
					{
						ExecuteHamB(Ham_Killed, iDriver, iDriver, 2);
						UTIL_SayText(0, "!g * !y%n задавил игрока во время масс.фд, за это получил моментальное убийтсва", iDriver);
					}
				}
			}
		}
		else
		{
			set_pev( iAttacker, pev_iuser4, 0 );
		}
		
		SetHamParamInteger( 3, GIB_ALWAYS );
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public FwdPlayerKilledPost( const id, const iAttacker )
{
	DisableHamForward( g_iFwdPlayerKilledPost );
	
	set_pev_string( iAttacker, pev_classname, g_iszFuncVehicle );
	
}

IsEntityVehicle( const iEntity )
{
	return pev_valid( iEntity ) && pev( iEntity, pev_classname ) == g_iszFuncVehicle;
}



/*===== -> Звуки -> =====*///{
sounds_precache()
{
	new i, szBuffer[64];
	/*for(i = 1; i <= 10; i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "jb_engine/countdown/%d.wav", i);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}*/
	new const szSoccer[][] = {"ball_bounce", "grab_ball", "ball_kick", "whitle_start", "whitle_end", "jbe_goal"};
	for(i = 0; i < sizeof(szSoccer); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "jb_engine/soccer/%s.wav", szSoccer[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}

	engfunc(EngFunc_PrecacheSound, "jb_engine/boxing/gong.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/bell.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/beep_1.wav");
	//engfunc(EngFunc_PrecacheGeneric, "sound/jb_engine/duel/duel_ready.mp3");
	
	engfunc(EngFunc_PrecacheSound, "jb_engine/weapons/spark.wav");
	
}
/*===== <- Звуки <- =====*///}

/*===== -> Спрайты -> =====*///{
sprites_precache()
{
	SpriteElectro = engfunc(EngFunc_PrecacheModel, "sprites/spark1.spr");
}
/*===== <- Спрайты <- =====*///}

/*===== -> Основное -> =====*///{
main_init()
{
	register_plugin("[JBE] Core", "1.0", "DalgaPups");
	//jbe_load_ini();
	license();
	register_dictionary("jbe_core.txt");
	g_iSyncMainInformer = CreateHudSyncObj();

	g_iSyncMainDeadInformer = CreateHudSyncObj();

}

public license()
{
	goto ANTI_DEC;
	ANTI_DEC:
	{
		#define WEB 	"fraggers.ru"			///Веб-сайт
		#define	TOPIC 	"/license/other.txt"						///Файл
		#define PLUGIN	"JailBreakCoreDP"								///Товар
		
		//is_server_private(WEB, TOPIC, PLUGIN, key, true); // mainplugin
	}
}

stock jbe_load_ini()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
// CONFIG.INI
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/key.ini", szCfgDir);
	if(!file_exists(szCfgFile))
	{
		new szError[100];
		formatex(szError, charsmax(szError), "[JBE] Отсутсвтует: %s!", szCfgFile);
		set_fail_state(szError);
		return;
	}
	new szBuffer[128], szKey[64], szValue[960];
	new iFile = fopen(szCfgFile, "rt");
	while(iFile && !feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer));
		replace(szBuffer, charsmax(szBuffer), "^n", ""); 
		trim(szBuffer);
		
		if(szBuffer[0] == EOS || szBuffer[0] == '/' && szBuffer[1] == '/' || szBuffer[0] == ';' || szBuffer[0] == '{' || szBuffer[0] == '}' || szBuffer[0] == '#') continue;
		
		parse(szBuffer, szKey, charsmax(szKey), szValue, charsmax(szValue));
		trim(szKey), trim(szValue);
		
		if(equal(szKey, 		"LICINSE"))							copy(key, 				charsmax(key), szValue);
		//server_print("SECRET %s",key);
	}
	fclose(iFile);
}



public client_putinserver(pId)
{
	SetBit(g_iBitUserConnected, pId);
	g_iPlayersNum[g_iUserTeam[pId]]++;
	if(zl_boss_map())
	{
		jbe_set_user_team(pId, 1);
	}else set_task_ex(0.5, "TransferForCT", pId + TASK_TRANSFER);
	

	if(isSpeed[pId]) isSpeed[pId] = false;
	
	if(!zl_boss_map())
		set_task_ex(1.0, "jbe_main_dead_informer", pId + TASK_SHOW_DEAD_INFORMER, .flags = SetTask_Repeat);
	
	g_iMainMenu[pId] = false;

	if(is_user_steam(pId))
	{
		SetBit(g_iBitUserVoice,pId);
		new ret;
		ExecuteForward(g_iForward[FORWARD_ON_USER_VOICE], ret, pId);
	}
	
	if(!get_login(pId))
	{
		g_iUserInformer[pId][INFO_POS_RED] = 255;
		g_iUserInformer[pId][INFO_POS_GREEN] = 255;
		g_iUserInformer[pId][INFO_POS_BLUE] = 0;
		
		g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.70;
		g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.05;
	}
	
	#if defined INFORMER_MAIN
	jbe_settings_playerinformer(pId);
	#endif 
	
	
	if(g_iViewInformerSkinNum) 
		jbe_get_count_skin();
		
	Ranks[pId] = "";
	
	#if defined INFORMER_MAIN
	if(!zl_boss_map())
		set_task_ex(1.0, "jbe_main_informer", pId + TASK_SHOW_INFORMER, .flags = SetTask_Repeat);
	#endif
}

public jbe_main_dead_informer(pPlayer)
{
	pPlayer -= TASK_SHOW_DEAD_INFORMER;
	{
		if(IsSetBit(g_iBitUserAlive, pPlayer) && !jbe_is_user_valid(pPlayer)) return;
		
		new pTarget = pev(pPlayer, pev_iuser2);
		if(IsNotSetBit(g_iBitUserAlive, pTarget) && !jbe_is_user_valid(pTarget)) return;

		set_hudmessage(100, 100, 100, -1.0, 0.72, 0, 0.0, 0.8, 0.2, 0.2, -1);
		ShowSyncHudMsg
		(
			pPlayer, g_iSyncMainDeadInformer, "%n^n%dHP | %dAP",
			pTarget, get_user_health(pTarget), get_user_armor(pTarget)
		);
	}
}

public TransferForCT(pId)
{
	pId -= TASK_TRANSFER;
	//client_cmd(pId, "mp3 play sound/misc/wp_c.mp3");
	jbe_set_user_team(pId, 1);
	//if(zl_boss_map()) return;
	if(IsSetBit(g_iBitUserAlive, pId)) ExecuteHamB(Ham_Killed, pId, pId, 0);
}

public jbe_soccer_start(bool:g_bSoccerGame)
{
	if(g_bSoccerGame)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsNotSetBit(g_iBitUserConnected, i) || IsNotSetBit(g_iBitUserWanted, i)) continue;
			
			jbe_sub_user_wanted(i);
		}
	}

}

public client_disconnected(pId)
{
	
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	ClearBit(g_iBitUserConnected, pId);
	
	if(g_iViewInformerSkinNum) 
		jbe_get_count_skin();
	//#if defined MODE_INFORMER == 0
	//remove_task(pId+TASK_SHOW_INFORMER);
	//#endif
	g_iPlayersNum[g_iUserTeam[pId]]--;
	if(IsSetBit(g_iBitUserAlive, pId))
	{
		g_iAlivePlayersNum[g_iUserTeam[pId]]--;
		
		if(g_iAlivePlayersNum[1] == 1 && g_iUserTeam[pId] == 1 && g_iPlayersNum[1] >= 5)
		{
			//if(g_bSoccerStatus) jbe_soccer_disable_all();
			//if(g_bBoxingStatus) jbe_boxing_disable_all();
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!is_user_alive(i) || g_iUserTeam[i] != 1) continue;

				if(IsSetBit(g_iUserGhost , i))
				{
					ClearBit(g_iUserGhost, i);
					user_silentkill(i);
				}
			}
			new iRet;
			ExecuteForward(g_iForward[FORWARD_ON_DUELS], iRet);
		}
		ClearBit(g_iBitUserAlive, pId);
	}
	
	g_iMainMenu[pId] = false;
	
	if(IsSetBit(g_iBitUserSkinChange, pId)) ClearBit(g_iBitUserSkinChange, pId);
	ClearBit(g_iBitUserFrozen, pId);
	
	if(pId == g_iChiefId)
	{
		g_iChiefId = 0;
		g_iChiefStatus = 3;
		g_szChiefName = "";
		//if(g_bSoccerGame) remove_task(pId+TASK_SHOW_SOCCER_SCORE);
		
		new iRet;
		ExecuteForward(g_iForward[FORWARD_ON_CHIEF_REMOVE], iRet, pId, 0);
		
		if(g_iTimer)
		{
			g_iTimer = false;
			remove_task(TASK_SHOW_TIME);
			g_iTimerSecond = 0;
		}
		
		if(g_iDistanceDrop) g_iDistanceDrop = false;
	}
	if(IsSetBit(g_iBitUserFree, pId)) jbe_sub_user_free(pId);
	if(IsSetBit(g_iBitUserWanted, pId)) jbe_sub_user_wanted(pId);
	g_iUserTeam[pId] = 0;
	//g_iUserMoney[pId] = 0;

	
	
	if(task_exists(pId+TASK_CHANGE_MODEL)) remove_task(pId+TASK_CHANGE_MODEL);
	ClearBit(g_iBitUserModel, pId);
	if(task_exists(pId+TASK_CHANGE_MODEL)) remove_task(pId+TASK_CHANGE_MODEL);
	ClearBit(g_iBitUserFreeNextRound, pId);
	ClearBit(g_iBitUserVoice, pId);
	ClearBit(g_iBitUserVoiceNextRound, pId);
	ClearBit(g_iBitBlockMenu, pId);
	ClearBit(g_iBitUserVoteDayMode, pId);
	ClearBit(g_iBitUserDayModeVoted, pId);

	//ClearBit(g_iBitUserBoxing, pId);
	
	
	g_iUserSkin[pId] = 0;
	
	/*if(!get_login(pId))
	{
		g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.70;
		g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.05;
		g_iUserInformer[pId][INFO_POS_RED] = 255;
		g_iUserInformer[pId][INFO_POS_GREEN] = 255;
		g_iUserInformer[pId][INFO_POS_BLUE] = 0;
		g_iUserInformer[pId][INFORMER_RANK]	= 0;
		g_iUserInformer[pId][INFORMER_DAYWEEK] = 0;
		g_iUserInformer[pId][INFORMER_DAYMODE] = 0;
		g_iUserInformer[pId][INFORMER_CHIEF]	 = 0;
		g_iUserInformer[pId][INFORMER_PRISONCOUNT] = 0;
		g_iUserInformer[pId][INFORMER_GUARDCOUNT] = 0;
		g_iUserInformer[pId][INFORMER_TIME] = 0;
	}*/
	remove_task(pId + TASK_SHOW_DEAD_INFORMER);
	remove_task(pId + TASK_SHOW_INFORMER);
}



/*===== <- Основное <- =====*///}





jbe_get_cvars()
{

	
	new pcvar;
	
	pcvar = create_cvar("jbe_free_day_id_time", "120", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[FREE_DAY_ID]);
	pcvar = create_cvar("jbe_free_day_all_time", "240", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[FREE_DAY_ALL]); 
	pcvar = create_cvar("jbe_team_balance", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[TEAM_BALANCE]); 
	pcvar = create_cvar("jbe_day_mode_vote_time", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[DAY_MODE_VOTE_TIME]); 
	pcvar = create_cvar("jbe_restart_game_time", "40", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[RESTART_GAME_TIME]); 
	pcvar = create_cvar("jbe_give_freday_monday", "1", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[MONDAY_FREEDAY]); 
	
	
	 
	

	pcvar = create_cvar("jbe_quest_duel", "30", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_DUEL]); 
	pcvar = create_cvar("jbe_quest_wanted", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_WANTED]); 
	pcvar = create_cvar("jbe_quest_freeday", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_FREEDAY]); 
	pcvar = create_cvar("jbe_quest_killchief", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_KILLCHIEF]); 
	pcvar = create_cvar("jbe_quest_mazhor", "5000", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MAZHOR]); 
	pcvar = create_cvar("jbe_quest_shahid", "12", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_LOXOTRON]); 
	pcvar = create_cvar("jbe_quest_loxotron", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_SHAHID]); 
	pcvar = create_cvar("jbe_quest_allresult", "7", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_ALLRESULT]); 
	
	pcvar = create_cvar("jbe_quest_money_duel", "30", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_DUEL]); 
	pcvar = create_cvar("jbe_quest_money_wanted", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_WANTED]); 
	pcvar = create_cvar("jbe_quest_money_freeday", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_FREEDAY]); 
	pcvar = create_cvar("jbe_quest_exp_killchief", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_EXP_KILLCHIEF]); 
	pcvar = create_cvar("jbe_quest_exp_mazhor", "5000", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_EXP_MAZHOR]); 
	pcvar = create_cvar("jbe_quest_money_shahid", "12", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_SHAHID]); 
	pcvar = create_cvar("jbe_quest_money_loxotron", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_LOXOTRON]); 
	pcvar = create_cvar("jbe_quest_money_allresult", "7", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_MONEY_ALLRESULT]); 
	pcvar = create_cvar("jbe_quest_exp_allresult", "7", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestCvars[QUEST_EXP_ALLRESULT]);
	pcvar = create_cvar("jbe_transfer_access_money", "300", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iAllCvars[MONEY_ACCESS_TRANSFER]);
	
	AutoExecConfig(true, "Jail_Main_Core");
}
/*===== <- Квары <- =====*///}

/*===== -> Игровые события -> =====*///{
event_init()
{
	
	register_logevent("LogEvent_RestartGame", 2, "1=Game_Commencing", "1&Restart_Round_");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
	register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
	//register_forward(FM_PlayerPreThink, "client_prethink");


	g_iForward[FORWARD_ON_DUELS] = CreateMultiForward("jbe_lr_duels", ET_CONTINUE) ;
	g_iForward[FORWARD_ON_CHIEF_SET] = CreateMultiForward("jbe_set_user_chief_fwd", ET_CONTINUE, FP_CELL) ;
	g_iForward[FORWARD_ON_CHIEF_REMOVE] = CreateMultiForward("jbe_remove_user_chief_fwd", ET_CONTINUE, FP_CELL, FP_CELL) ;
	g_iForward[FORWARD_ON_SET_USER_TEAM] = CreateMultiForward("jbe_set_team_fwd", ET_CONTINUE, FP_CELL) ;
	
	g_iForward[FORWARD_ON_ADD_USER_FREE] = CreateMultiForward("jbe_fwd_add_user_free", ET_CONTINUE, FP_CELL) ;
	g_iForward[FORWARD_ON_ADD_USER_WANTED] = CreateMultiForward("jbe_fwd_add_user_wanted", ET_CONTINUE, FP_CELL) ;
	g_iForward[FORWARD_ON_SUB_USER_FREE] = CreateMultiForward("jbe_fwd_sub_free_wanted", ET_CONTINUE, FP_CELL, FP_CELL) ;
	
	g_iForward[FORWARD_ON_ROUND_END] = CreateMultiForward("jbe_fwr_roundend", ET_CONTINUE);
	g_iForward[FORWARD_ON_USER_VOICE] = CreateMultiForward("jbe_fwr_is_user_voice", ET_CONTINUE, FP_CELL);
	g_iForward[FORWARD_ON_RESTART_GAME] = CreateMultiForward("jbe_fwr_restart_game", ET_CONTINUE, FP_CELL);
	g_iForward[FORWARD_ON_HLTV_START] = CreateMultiForward("jbe_fwr_event_hltv", ET_CONTINUE, FP_CELL);
	g_iForward[FORWARD_ON_ROUND_START] = CreateMultiForward("jbe_fwr_logevent_startround", ET_CONTINUE);
	g_iForward[FORWARD_ON_SET_PLAYER_MODEL] = CreateMultiForward("jbe_fwr_set_user_model", ET_CONTINUE, FP_CELL);
	g_iForward[FORWARD_ON_KILLED_POST] = CreateMultiForward("jbe_fwr_playerkilled_post", ET_CONTINUE, FP_CELL, FP_CELL);
	
}






public LogEvent_RestartGame()
{
	LogEvent_RoundEnd();
	jbe_set_day(0);
	jbe_set_day_week(0);
}

public Event_HLTV()
{
	#if JBE_MODE_DEBUG == 1
	g_iUtilSayTextCallBack[ 1 ] = 0;
	g_iStockCallback[ 0 ][ 1 ] = 0;
	g_iStockCallback[ 1 ][ 1 ] = 0;
	#endif 
	
	g_bRoundEnd = false;
	for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]); 
	if(g_bRestartGame)
	{
		if(task_exists(TASK_RESTART_GAME_TIMER)) return;
		g_iDayModeTimer = g_iAllCvars[RESTART_GAME_TIME] + 1;
		set_task_ex(1.0, "jbe_restart_game_timer", TASK_RESTART_GAME_TIMER, _, _, SetTask_RepeatTimes, g_iDayModeTimer);
		
		set_cvar_string("mp_round_infinite", "abeg");
		//EnableHookChain(g_iHookChainRoundEnd);
		//g_iRRTimeRestartGame = true;
		new iRet;
		ExecuteForward(g_iForward[FORWARD_ON_RESTART_GAME], iRet, 1);
		return;
	}
	jbe_set_day(++g_iDay);
	jbe_set_day_week(++g_iDayWeek);
	g_szChiefName = "";
	g_iChiefStatus = 0;
	g_iBitUserFree = 0;
	g_szFreeNames = "";

	g_iBitUserWanted = 0;
	g_szWantedNames = "";
	//g_iWantedLang = 0;
	
	g_iBitUserQuestForFree = 0;
	g_iBitUserQuestForWanted = 0;
	
	g_iBitUserFrozen = 0;
	
	g_iFreeCount = 0;
	szFree = "";
	
	g_iWantedCount = 0;
	szWanted = "";
	
	//g_iBitUserVoice = 0;
	
	if(g_iTimer)
	{
		g_iTimer = false;
		remove_task(TASK_SHOW_TIME);
		g_iTimerSecond = 0;
	}
	
	g_iDistanceDrop = false;
	g_iBitUserSkinChange = 0;
	g_iViewInformerSkinNum = false;
	g_iSkinView = "";
	
	
	
	
	g_iChiefStep = false;
	#if defined DEBUG
	if(jbe_get_day_week() <= 5 || !g_iDayModeListSize) jbe_set_day_mode(1);
	#else
	if(jbe_get_day_week() <= 5 || !g_iDayModeListSize || g_iPlayersNum[1] < 2 || !g_iPlayersNum[2]) jbe_set_day_mode(1);
	#endif
	else jbe_set_day_mode(3);
	
	if(g_iAllCvars[MONDAY_FREEDAY] && g_iDay == 1)
	{
		set_task(2.0, "jbe_free_day_start");
		UTIL_SayText(0, "!t[!gFreeDay!t] !yСегодня !tпервый день!y, а значит - !gСвободный день");
	}
	
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_HLTV_START], iRet, g_iDay);
}

public jbe_restart_game_timer()
{
	if(--g_iDayModeTimer)
	{
		formatex(g_szDayModeTimer, charsmax(g_szDayModeTimer), "%s", UTIL_FixTime(g_iDayModeTimer));
		
		if(!task_exists(TASK_OPEN_DOORS))
			set_task(2.0, "jbe_open_doors_task", TASK_OPEN_DOORS);
	}
	else
	{
		if(zl_boss_map()) return;
		
		new iRet;
		ExecuteForward(g_iForward[FORWARD_ON_RESTART_GAME], iRet, 0);
		
		g_szDayModeTimer = "";
		g_bRestartGame = false;
		//DisableHookChain(g_iHookChainRoundEnd);
		//g_iRRTimeRestartGame = false;
		set_cvar_string("mp_round_infinite", "abeg");
		//set_cvar_num("mp_round_restart_delay" , 3);
		server_cmd("sv_restart 5");
		//rg_restart_round();
		UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		
		//rg_round_end(.tmDelay = 1.0, .st = WINSTATUS_DRAW, .message = "Начало игры!");
	}
}

public jbe_open_doors_task()
{
	jbe_open_doors();
}

public LogEvent_RoundStart()
{
	if(g_bRestartGame) return;
	
	/*#if defined DEBUG
	if(jbe_get_day_week() <= 5 || !g_iDayModeListSize)
	#else
	if(jbe_get_day_week() <= 5 || !g_iDayModeListSize || g_iAlivePlayersNum[1] < 2 || !g_iAlivePlayersNum[2])
	#endif*/
	if(jbe_get_day_week() <= 5 || !g_iDayModeListSize || g_iAlivePlayersNum[1] < 2 || !g_iAlivePlayersNum[2])
	{
		if(!g_iChiefStatus)
		{
			g_iChiefIdOld = 0;
			g_iChiefChoiceTime = 40 + 1;
			set_task_ex(1.0, "jbe_chief_choice_timer", TASK_CHIEF_CHOICE_TIME, _, _, SetTask_RepeatTimes, g_iChiefChoiceTime);
		}
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsNotSetBit(g_iBitUserConnected, i)) continue;
			
			if(g_iUserTeam[i] == 1)
			{
				if(IsSetBit(g_iBitUserFreeNextRound, i))
				{
					jbe_add_user_free(i);
					ClearBit(g_iBitUserFreeNextRound, i);
				}
				if(IsSetBit(g_iBitUserVoiceNextRound, i))
				{
#if defined GAMECMS_VOICE
					if(cmsgag_is_user_blocked(i) != BLOCK_STATUS_VOICE)
					{
						//SetBit(g_iBitUserVoice, i);
						jbe_set_user_voice(i);
						ClearBit(g_iBitUserVoiceNextRound, i);
					}
#else
					SetBit(g_iBitUserVoice, i);

					ClearBit(g_iBitUserVoiceNextRound, i);
					
#endif
				}
			}
			
		}
	}
	else jbe_vote_day_mode_start();
	
	
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_ROUND_START], iRet);
}


stock fm_get_aim_origin(index, Float:origin[3])
{
	static Float:start[3], Float:view_ofs[3];
	get_entvar(index, var_origin, start);
	get_entvar(index, var_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	static Float:dest[3];
	get_entvar(index, var_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
	return 1;
}

stock move_toward_client(pId, Float:origin[3])
{		
	static Float:player_origin[3];
	get_entvar(pId, var_origin, player_origin);
	origin[0] += (player_origin[0] > origin[0]) ? 1.0 : -1.0;
	origin[1] += (player_origin[1] > origin[1]) ? 1.0 : -1.0;
	origin[2] += (player_origin[2] > origin[2]) ? 1.0 : -1.0;
}

public jbe_chief_choice_timer()
{
	if(--g_iChiefChoiceTime)
	{
		//if(g_iChiefChoiceTime == 40) g_iChiefIdOld = 0;
		formatex(g_szChiefName, charsmax(g_szChiefName), " [%i]", g_iChiefChoiceTime);
	}
	else
	{
		g_szChiefName = "";
		jbe_free_day_start();
	}
}

public LogEvent_RoundEnd()
{
	if(!task_exists(TASK_ROUND_END))
		set_task_ex(0.1, "LogEvent_RoundEndTask", TASK_ROUND_END);
}

public LogEvent_RoundEndTask()
{

	if(g_iDayMode != 3)
	{
		//g_iFriendlyFire = 0;
		if(task_exists(TASK_COUNT_DOWN_TIMER)) remove_task(TASK_COUNT_DOWN_TIMER);
		
		if(task_exists(TASK_CHIEF_CHOICE_TIME))
		{
			remove_task(TASK_CHIEF_CHOICE_TIME);
			g_szChiefName = "";
		}
		if(g_iDayMode == 2) jbe_free_day_ended();
		//if(g_bSoccerStatus) jbe_soccer_disable_all();
		//if(g_bBoxingStatus) jbe_boxing_disable_all();
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!is_user_connected(i)) continue;

			//if(VTC_MuteClient(i)) VTC_UnmuteClient(i);
			if(IsNotSetBit(g_iBitUserAlive, i)) continue;

			if(get_entvar(i, var_renderfx) != kRenderFxNone || get_entvar(i, var_rendermode) != kRenderNormal)
			{
				jbe_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[i][RENDER_STATUS] = false;
			}

			if(i == g_iChiefId)
			{
				new iRet;
				ExecuteForward(g_iForward[FORWARD_ON_CHIEF_REMOVE] , iRet , i, 0);
			}
			rg_remove_all_items(i);
			rg_give_item(i, "weapon_knife");
		}
		
	}
	else
	{
		
		g_iBitUserFrozen = 0;
		if(task_exists(TASK_VOTE_DAY_MODE_TIMER))
		{
			
			remove_task(TASK_VOTE_DAY_MODE_TIMER);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsNotSetBit(g_iBitUserVoteDayMode, i)) continue;
				ClearBit(g_iBitUserVoteDayMode, i);
				ClearBit(g_iBitUserDayModeVoted, i);
				show_menu(i, 0, "^n");

				jbe_menu_unblock(i);
				//set_entvar(i, var_flags, get_entvar(i, var_flags) & ~FL_FROZEN);
				//set_pdata_float(i, m_flNextAttack, 0.0);
				set_member(i, m_flNextAttack, 0.0);
				//UTIL_ScreenFade(i, 512, 512, 0, 0, 0, 0, 255);
				rg_reset_maxspeed(i);
				
			}
		}
		if(g_iVoteDayMode != -1)
		{
			if(task_exists(TASK_DAY_MODE_TIMER)) remove_task(TASK_DAY_MODE_TIMER);
			g_szDayModeTimer = "";
			ExecuteForward(g_iHookDayModeEnded, g_iReturnDayMode, g_iVoteDayMode, g_iAlivePlayersNum[1] ? 1 : 2);
			g_iVoteDayMode = -1;
			if(g_iIsBlockedForGame) g_iIsBlockedForGame = false;
			
			DisableHamForward(g_iHamHookTrigger[0]);
			DisableHamForward(g_iHamHookTrigger[1]);
		}
	}
	for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
	g_bRoundEnd = true;
	g_iChiefId = 0;
	
	new ret;
	ExecuteForward(g_iForward[FORWARD_ON_ROUND_END], ret);
}

/*public Event_StatusValueShow(pId)
{
	new iTarget = read_data(2);

	CenterMsgFix_PrintMsg(pId, print_center, "%n | HP: %d | AP: %d",iTarget, get_user_health(iTarget), get_user_armor(iTarget));
}

public Event_StatusValueHide(pId) CenterMsgFix_PrintMsg(pId, print_center, "");*/

public Event_StatusValueShow(pId)
{
	if(IsNotSetBit(g_iBitUserConnected, pId)) return;
	
	if(jbe_get_status_mafia() || (jbe_global_status(18) && g_iUserTeam[pId] == 1) || jbe_get_ff_crusader() || jbe_global_get_djihad()) return;
	new iTarget = read_data(2);/*, szName[32], szTeam[][] = {"", "JBE_ID_HUD_STATUS_TEXT_PRISONER", "JBE_ID_HUD_STATUS_TEXT_GUARD", ""};*/
	set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(pId, g_iSyncMainDeadInformer, "%n^nHP: %d | AP: %d",iTarget, get_user_health(iTarget), get_user_armor(iTarget));
}

public Event_StatusValueHide(id) ClearSyncHud(id, g_iSyncMainDeadInformer);
/*new Float:gLastAimDetail[MAX_PLAYERS + 1];

public client_prethink(id)
{
	//if(!is_user_connected(id)) return;
	if(!jbe_is_user_valid(id)) return;
	if(IsNotSetBit(g_iBitUserAlive, id)) return;
	

	static Float:fGmTime; fGmTime = get_gametime ();
	
	if ( gLastAimDetail[id] < fGmTime )
	{
		new iTgt, iBody;
		get_user_aiming( id, iTgt, iBody, 3000 );
		new Float:hp = get_entvar(iTgt, var_health);
		if ( IsSetBit(g_iBitUserAlive, iTgt ) )
		{
			new szMessage[187];

			switch(g_iUserTeam[iTgt])
			{
				case 1: formatex(szMessage, charsmax(szMessage), "Зек: %n - %d ХП", iTgt, floatround(hp));
				case 2: formatex(szMessage, charsmax(szMessage), "Охрана: %n - %d ХП", iTgt, floatround(hp));
			}
			message_begin ( MSG_ONE_UNRELIABLE, MsgId_StatusText, _, id );
			write_byte ( 0 );
			write_string ( szMessage );
			message_end ();

			message_begin ( MSG_ONE_UNRELIABLE, MsgId_StatusValue, _, id );
			write_byte ( 2 );
			write_short ( iTgt );
			message_end ();
		}
		else
		{
			message_begin ( MSG_ONE_UNRELIABLE, MsgId_StatusText, _, id );
			write_byte ( 0 );
			write_string ( "" );
			message_end ();
		}

		gLastAimDetail[id] = floatadd ( 1.0, fGmTime );
	}
	
}*/


/*===== <- Игровые события <- =====*///}

/*===== -> Консольные команды -> =====*///{
clcmd_init()
{
	if(zl_boss_map()) return;
	for(new i, szBlockCmd[][] = {"jointeam", "joinclass"}; i < sizeof szBlockCmd; i++) register_clcmd(szBlockCmd[i], "ClCmd_Block");
	register_clcmd("chooseteam", "ClCmd_ChooseTeam");
	register_clcmd("money_transfer", "ClCmd_MoneyTransfer");

	register_clcmd("drop", "ClCmd_Drop");
	register_touch("weaponbox", "worldspawn", "Fwd_Weapon_Touch");
	
	register_clcmd("countdown_num", "jbe_countdown_num");
	
	#if JBE_MODE_DEBUG == 1
	register_clcmd("say /taskinfo", "GetTaskInfo" );
	register_clcmd("task_info", "GetTaskInfo" );	
	
	register_clcmd("say /messageinfo", "MessageStockInfo" );
	register_clcmd("message_info", "MessageStockInfo" );

	register_clcmd("say /saytextinfo", "SayTextStockInfo" );
	register_clcmd("saytext_info", "SayTextStockInfo" );
	#endif

	#if defined DEBUG
	/*register_clcmd("money228", "ClCmd_Money");
	register_clcmd("say /open", "ClCmd_OpenDoor");
	register_clcmd("say /textt", "clcmd_dawdsad");*/
	//register_clcmd("say /open", "ClCmd_OpenDoor");
	//register_clcmd("say /game", "clcmd_game");
	
	#endif
	
	//register_clcmd("informer", "informe1r");
	
	register_clcmd("ColorInformer", "ColorInformer");
	register_dictionary("admincmd.txt");
	register_concmd("amx_who", "cmdWho");
	
	register_clcmd("say /simon", "Take_Simon");
	register_clcmd("rulesmenu", "rulesmenu");
	register_clcmd("jbe_pnmenu", "jbe_pnmenu");
}

public jbe_pnmenu(pId) return  Show_MenuPn(pId);
public rulesmenu(pId) return Show_RulesMenu(pId);

public Take_Simon(pId)
{
	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yВы мертвы чтобы взять начальника!");
		return PLUGIN_HANDLED;
	}
	else
	if(jbe_get_user_team(pId) != 2)
	{
		UTIL_SayText(pId, "!g* !yВы не охранник чтобы использовать эту команду!");
		return PLUGIN_HANDLED;
	}
	else 
	if(g_iDayMode == 3 || !g_iDayMode)
	{
		UTIL_SayText(pId, "!g* !yНельзя открыть данное меню если включен игровой режим!");
		return PLUGIN_HANDLED;
	}
	else
	if(jbe_iduel_status())
	{
		UTIL_SayText(pId, "!g* !yВо время дуэли нельзя стать начальником или открыть меню начальника!");
		return PLUGIN_HANDLED;
	}
	
	if(pId == g_iChiefId) return Show_ChiefMenu_1(pId);
	
	if(g_iChiefStatus != 1 && (g_iChiefIdOld != pId || g_iChiefStatus != 0) && jbe_set_user_chief(pId))
	{
		g_iChiefIdOld = pId;
		return Show_ChiefMenu_1(pId);
	}
	return PLUGIN_HANDLED;
}

public informe1r(pId) return Show_InformerSettings(pId);

public clcmd_dawdsad(iTarget) client_print(iTarget, print_center, "%n | HP: %d | AP: %d",iTarget, get_user_health(iTarget), get_user_armor(iTarget));

#if JBE_MODE_DEBUG == 1
public SayTextStockInfo( id )
{
	client_print( id, print_console, "Всего отправок SayText за сеанс: %d", g_iUtilSayTextCallBack[ 0 ] );
	client_print( id, print_console, "Всего отправок SayText за раунд: %d", g_iUtilSayTextCallBack[ 1 ] );	
	return PLUGIN_HANDLED;
}
public GetTaskInfo( id ) 
{
	new iTaskNum;
	for( new iPos = 250000; iPos <= 300000; iPos += 100 )
	{
		if( task_exists( iPos ) ) iTaskNum++;
		else
			for( new pId = 1; pId <= MaxClients; pId++ )
			{
				if( task_exists( iPos + pId ) )
					iTaskNum++;
			}
	}
	client_print( id, print_console, "Примерное количество работающих задач: %d", iTaskNum );
	return PLUGIN_HANDLED;
}
public MessageStockInfo( id )
{
	new iAllCallback[ 2 ];
	iAllCallback[ 0 ] += g_iStockCallback[ 0 ][ 0 ];
	iAllCallback[ 1 ] += g_iStockCallback[ 1 ][ 1 ];
	
	client_print( id, print_console, "Всего за сеанс CALLBACK'ов на Message-stock: %d", iAllCallback[ 0 ] );
	client_print( id, print_console, "Всего за раунд CALLBACK'ов на Message-stock: %d^n^nПодробная информация:", iAllCallback[ 1 ] );
	for( new iPos; iPos <= 1; iPos++ )
	{
		client_print( id, print_console, "[%s]: За всю игру: %d", g_szTextCallBack[ iPos ], g_iStockCallback[ iPos ][ 0 ] );
		client_print( id, print_console, "[%s]: За раунд: %d^n", g_szTextCallBack[ iPos ], g_iStockCallback[ iPos ][ 1 ] );
	}
	return PLUGIN_HANDLED;
}
#endif

#if defined DEBUG

public clcmd_game()
{
	g_iDayWeek = 5;


}

/*public clcmd_box()
{
	g_iFriendlyFire = !g_iFriendlyFire;
}*/


public awdawdafwd()
{
	
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_None);
	
	for(new i; i < iPlayerCount; i++)
	{	
		if(IsNotSetBit(g_iBitUserAlive, iPlayers[i]))
		{
			SetBit(g_iUserGhost, iPlayers[i]);
			rg_round_respawn(iPlayers[i]);
		}
	}
}

public awdawdawd(pId)
{
	set_entvar(pId, var_groupinfo, get_entvar(pId, var_groupinfo) | MaskEnt2(1));

}
public sefsdfsef(pId)
{
	set_entvar(pId, var_groupinfo, get_entvar(pId, var_groupinfo) & ~MaskEnt2(1));
}



public ClCmd_Money(pId)
{
	//jbe_set_user_money(pId, 50000, 1);


}



public ClCmd_exp(id)
{
	g_iUserStats[id][STATS_5] += 1;
	g_iUserStats[id][STATS_1] += 3;
	
	UTIL_SayText(id, "STATS_5 = %d | STATS_1 = %d", g_iUserStats[id][STATS_5], g_iUserStats[id][STATS_1]);
}

public ClCmd_get(id) UTIL_SayText(id, "STATS_5 = %d | STATS_1 = %d", g_iUserStats[id][STATS_5], g_iUserStats[id][STATS_1]);

public ClCmd_OpenDoor()
{
	jbe_open_doors();
	
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);

	for(new i, Players; i < iPlayerCount; i++)
	{
		Players	= iPlayers[i];

		if(IsSetBit(g_iBitUserAlive, Players) && !jbe_is_user_duel(Players))
		{
			rg_remove_item(Players, "weapon_deagle");
			new iEntity = rg_give_item(Players, "weapon_deagle", GT_REPLACE);
			if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
		}
	}
	UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ID_MINI_GAME_DISTANCE_DROP");
}
#endif




public ClCmd_Block(pId) return PLUGIN_HANDLED;

public ClCmd_ChooseTeam(pId)
{
	if(!g_iAdminHelp) return PLUGIN_HANDLED;
	if(jbe_menu_blocked(pId)) return PLUGIN_HANDLED;
	if(IsNotSetBit(g_iUserGhost, pId))
	{
		switch(g_iUserTeam[pId])
		{
			case 1: Show_MainPnMenu(pId);
			case 2: Show_MainGrMenu(pId);
			default: Show_ChooseTeamMenu(pId, 0);
		}
	}else return Show_GhostMenu(pId);
	return PLUGIN_HANDLED;
}



public ClCmd_MoneyTransfer(pId, iTarget, iMoney)
{

	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g * !yВы не авторизованы!");
		return PLUGIN_HANDLED;
	}
	/*if(g_iUserStats[pId][QUEST_5] < g_iAllCvars[MONEY_ACCESS_TRANSFER])
	{
		UTIL_SayText(pId, "!g * !yЧтобы передать, нужно хотябы потратиться. Осталось: !g%d бычков", (g_iAllCvars[MONEY_ACCESS_TRANSFER] - g_iUserStats[pId][QUEST_5]));
		return PLUGIN_HANDLED;
	}*/
	if(!iTarget)
	{
		new szArg1[3], szArg2[7];
		read_argv(1, szArg1, charsmax(szArg1));
		read_argv(2, szArg2, charsmax(szArg2));
		if(!is_str_num(szArg1) || !is_str_num(szArg2))
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_ERROR_PARAMETERS");
			return PLUGIN_HANDLED;
		}
		iTarget = str_to_num(szArg1);
		iMoney = str_to_num(szArg2);
	}
	if(pId == iTarget || !jbe_is_user_valid(iTarget) || IsNotSetBit(g_iBitUserConnected, iTarget)) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_UNKNOWN_PLAYER");
	else if(!get_login(iTarget)) UTIL_SayText(pId, "!g * !yИгрок не авторизован");
	else if(jbe_get_butt(pId) < iMoney) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_SUFFICIENT_FUNDS");
	else if(iMoney <= 0) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_MIN_AMOUNT_TRANSFER");
	else
	{
		//jbe_set_user_money(iTarget, g_iUserMoney[iTarget] + iMoney, 1);
		//jbe_set_user_money(pId, g_iUserMoney[pId] - iMoney, 1);
		
		jbe_set_butt(iTarget, jbe_get_butt(iTarget) + iMoney);
		jbe_set_butt(pId, jbe_get_butt(pId) - iMoney);
		new szName[32], szNameTarget[32];
		get_user_name(pId, szName, charsmax(szName));
		get_user_name(iTarget, szNameTarget, charsmax(szNameTarget));
		UTIL_SayText(0, "!g * %L", pId, "JBE_CHAT_ALL_MONEY_TRANSFER", szName, iMoney, szNameTarget);
	}
	return PLUGIN_HANDLED;
}







public ClCmd_Drop(pId)
{
	if(g_iDistanceDrop)
	{
		get_entvar(pId, var_origin, throworigin);
		drop_id = pId;
	}
	if(jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Fwd_Weapon_Touch(weapon, world)
{

	if(g_iDistanceDrop)
	{
		get_entvar(weapon, var_origin, droporigin);
		set_task_ex(1.0, "check_distance");
	}
}


public check_distance()
{
	new Float: distance = get_distance_f(throworigin, droporigin);
	if(IsSetBit(g_iBitUserConnected, drop_id) && jbe_is_user_valid(drop_id) && g_iUserTeam[drop_id] == 1)
	{
		UTIL_SayText(0, "!g* !yИгрок под ником !g%n !yбросил дигл с дальностью !g%.1f units !y(%d метр(а))" , drop_id, distance, floatround(distance * 0.025));
	}
}


/*===== <- Консольные команды <- =====*///}

/*===== -> Меню -> =====*///{
#define PLAYERS_PER_PAGE 8

menu_init()
{
	#define RegisterMenu(%1,%2) register_menucmd(register_menuid(%1), 1023, %2)
	
	RegisterMenu("Show_ChooseTeamMenu", 			"Handle_ChooseTeamMenu");
	RegisterMenu("Show_MainPnMenu", 				"Handle_MainPnMenu");
	RegisterMenu("Show_MainGrMenu", 				"Handle_MainGrMenu");
	RegisterMenu("Show_MoneyTransferMenu", 			"Handle_MoneyTransferMenu");
	RegisterMenu("Show_MoneyAmountMenu", 			"Handle_MoneyAmountMenu");
	RegisterMenu("Show_ChiefMenu_1", 				"Handle_ChiefMenu_1");
	RegisterMenu("Show_FreeDayControlMenu", 		"Handle_FreeDayControlMenu");
	RegisterMenu("Show_PunishGuardMenu", 			"Handle_PunishGuardMenu");
	RegisterMenu("Show_TransferChiefMenu", 			"Handle_TransferChiefMenu");
	RegisterMenu("Show_TreatPrisonerMenu", 			"Handle_TreatPrisonerMenu");	
	RegisterMenu("Show_PrisonersDivideColorMenu", 	"Handle_PrisonersDivideColorMenu");
	
	RegisterMenu("Show_MiniGameMenu", 				"Handle_MiniGameMenu");	
	RegisterMenu("Show_PageMiniGameMenu", 			"Handle_Page2MiniGameMenu");	
	RegisterMenu("Show_DayModeMenu", 				"Handle_DayModeMenu");
	RegisterMenu("Show_ManageSoundMenu", 			"Handle_ManageSoundMenu");
	
	RegisterMenu("Show_ChiefAction_Prisoner", 		"Handle_ChiefAction_Prisoner");
	RegisterMenu("Show_ChiefAction_Guard", 			"Handle_ChiefAction_Guard");
	RegisterMenu("Show_VoiceControlMenu", 			"Handle_VoiceControlMenu");
	RegisterMenu("Show_WantedSimonControle", 		"Handle_WantedSimonControle");	
	RegisterMenu("Show_QuestMenu", 					"Handle_QuestMenu");
	RegisterMenu("Show_GhostMenu", 					"Handle_GhostMenu");	
	RegisterMenu("Show_HealtMenu", 					"Handle_HealtMenu");	
	RegisterMenu("Show_MenuTimer", 					"Handle_MenuTimer");
	RegisterMenu("Show_DistanceDrop", 				"Handle_DistanceDrop");	
	RegisterMenu("Show_InformerSettings", 			"Handle_InformerSettings");	
	RegisterMenu("Show_InformerPosition", 			"Handle_InformerPosition");		
	
	
	RegisterMenu("Show_MenuPn", 					"Handle_MenuPn");
	RegisterMenu("Show_RulesMenu", 					"Handle_MainRulesMenu");
	
	RegisterMenu("Show_PlayerSettingsMenu", 				"Handle_PlayerSettingsMenu");	

	
	#undef RegisterMenu
}

Show_ChooseTeamMenu(pId, iType)
{
	if(jbe_menu_blocked(pId)) return PLUGIN_HANDLED;

	new TeamBalance = g_iAllCvars[TEAM_BALANCE];
	if(!TeamBalance) TeamBalance = 4;
	
	new iPrisons = abs(g_iPlayersNum[1] - 1);
	if( !iPrisons ) iPrisons = 1;
	
	new iCount = TeamBalance - g_iPlayersNum[2];
	new iCountPrisons = ((iPrisons / TeamBalance) + 1);
	if(!iCount) iCount = 0; 

	new szMenu[512], iKeys, iLen;
	FormatMain("\y%L^n", pId, "JBE_MENU_TEAM_TITLE");
	if(g_iUserTeam[pId] != 1)
	{
		FormatItem("\y1. \w%L \r[%d]^n", pId, "JBE_MENU_TEAM_PRISONERS", g_iPlayersNum[1]);
		iKeys |= (1<<0);
	}
	else FormatItem("\y1. \d%L \r[%d]^n", pId, "JBE_MENU_TEAM_PRISONERS", g_iPlayersNum[1]);
	if(!jbe_is_user_data(pId, 1))
	{
		if(!g_iIsBlockedForGame)
		{
			if(g_iUserTeam[pId] != 2)
			{
				if(iCountPrisons > g_iPlayersNum[2] && iCount)
				{
					
					FormatItem("\y2. \w%L \r[свободно %d мест]^n^n", pId, "JBE_MENU_TEAM_GUARDS", iCount);
					iKeys |= (1<<1);
				}
				else
				{
					FormatItem("\y2. \d%L \r[мест нет]^n^n", pId, "JBE_MENU_TEAM_GUARDS");
				}
			}
			else
			{
				FormatItem("\y2. \d%L \r[мест нет]^n^n", pId, "JBE_MENU_TEAM_GUARDS");
			}
		}else FormatItem("\y2. \d%L \r[Вход заблокирован]^n^n", pId, "JBE_MENU_TEAM_GUARDS");
		
	}
	else 
	{
		new Block_Time = jbe_mysql_block_time(pId);
		new Start_Time = jbe_mysql_block_start_time(pId);
		new iTime = Start_Time + Block_Time - get_systime( );

		if(Block_Time == 0 || iTime >= 0)
		{
			FormatItem("\y2. \d%L \y[Вы в блоке]^n^n", pId, "JBE_MENU_TEAM_GUARDS");

			

			new Block_Inf_Name[MAX_NAME_LENGTH],
				Block_Reason[MAX_NAME_LENGTH];

			//jbe_mysql_block_date(pId, Block_Date, MAX_NAME_LENGTH - 1);
			jbe_mysql_block_inf_name(pId, Block_Inf_Name, MAX_NAME_LENGTH - 1);
			jbe_mysql_block_reason(pId, Block_Reason, MAX_NAME_LENGTH - 1);
			

			new szTime[ 128 ];
			GetTimeLength(iTime , szTime, charsmax( szTime ) );
			
			if(iTime > 0)
			{
				FormatItem("^t^t\dРазблокирует через: \y%s^n" , szTime);
			}
			else FormatItem("^t^t\dРазблокирует через: \yНавсегда^n");
			FormatItem("^t^t\dКто заблокировал: \y%s^n", Block_Inf_Name);
			FormatItem("^t^t\dПричина блока: \y%s^n", Block_Reason);
			//FormatItem("^t^t\dКогда заблокировали: \r%s^n^n", Block_Date);
		}
		else
		{
			if(!g_iIsBlockedForGame)
			{
				if(g_iUserTeam[pId] != 2)
				{
					if(iCountPrisons > g_iPlayersNum[2])
					{
						jbe_set_user_data(pId, 1, 0);
						jbe_block_reasons(pId, "", 0, get_systime(), "");
						FormatItem("\y2. \w%L \r[свободно %d мест]^n^n", pId, "JBE_MENU_TEAM_GUARDS", iCount);
						iKeys |= (1<<1);
					}
					else
					{
						FormatItem("\y2. \d%L \r[мест нет]^n^n", pId, "JBE_MENU_TEAM_GUARDS");
					}
				}
				else
				{
					FormatItem("\y2. \d%L \r[свободно %d мест]^n^n", pId, "JBE_MENU_TEAM_GUARDS",  iCount);
				}
			}else FormatItem("\y2. \d%L \r[Вход заблокирован]^n^n", pId, "JBE_MENU_TEAM_GUARDS");
		}
		
	}
	if(iType)
	{
		FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
		iKeys |= (1<<9);
	}
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChooseTeamMenu");
}

public Handle_ChooseTeamMenu(pId, iKey)
{
	new iPrisons = abs(g_iPlayersNum[1] - 1);
	if( iPrisons <= 0 ) iPrisons = 1;
	switch(iKey)
	{
		case 0:
		{
			if(g_iUserTeam[pId] == 1) return Show_ChooseTeamMenu(pId, 1);
			if(!jbe_set_user_team(pId, 1)) return PLUGIN_HANDLED;
		}
		case 1:
		{
			if(is_enable())
			{
				UTIL_SayText(pId, "!g* !yСтоит админский запрет на вход за кт");
				return Show_ChooseTeamMenu(pId, 1);
			}
			if(g_iUserTeam[pId] == 2) return Show_ChooseTeamMenu(pId, 1);
			if(!jbe_is_user_data(pId, 1) && ((iPrisons / g_iAllCvars[TEAM_BALANCE]) + 1) > g_iPlayersNum[2])
			{
				if(!jbe_set_user_team(pId, 2)) return PLUGIN_HANDLED;

			}
			else
			{
				if(g_iUserTeam[pId] == 1) return Show_ChooseTeamMenu(pId, 1);
				else return Show_ChooseTeamMenu(pId, 0);
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}






Show_PlayerSettingsMenu(id)
{
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), iLen;
	
	FormatMain("\yЛичные настройки^n^n");
	
	FormatItem("\y1. \wОстановить звуки и музыку^n");
	FormatItem("\y2. \wНастройка Информера^n^n");

	FormatItem("\y3. \wШапки: \r%s^n", jbe_get_group_visiblecos(id) ? "Скрыто" : "Видно");
	FormatItem("\y4. \wСделать скрин^n");
	FormatItem("\y5. \wЗапомнить выбор оружия за КТ: \r%s^n^n", g_iSettingSaveUser[id][PLAYERS_SAVE_WEAPONS] ? "Нет" : "Да");
	
	FormatItem("\y6. \r[Чат] \wПрефикс: \r%s^n", !g_iUserInformer[id][PREFIX_INDIVID] ? "Вкл" : "Выкл");
	FormatItem("\y7. \r[Чат] \wРанг/Банда: \r%s^n", !g_iUserInformer[id][PREFIX_RANK] ? "Вкл" : "Выкл");
	//FormatItem("\y8. \r[Чат] \wБанда: \r%s^n", !g_iUserInformer[id][PREFIX_CLUB] ? "Вкл" : "Выкл");
	
	
	FormatItem("^n\y0. \wНазад^n");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_PlayerSettingsMenu");
}

public Handle_PlayerSettingsMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			client_cmd(pId, "mp3 stop");
			client_cmd(pId, "stopsound");
			UTIL_SayText(pId, "!g* !yВы успешно остановили все звуки сервера");
		}
		case 1:
		{
			//g_iSettingSaveUser[pId][PLAYERS_INFORMER] = !g_iSettingSaveUser[pId][PLAYERS_INFORMER];
			return Show_InformerSettings(pId);
		}
		case 2:
		{
			jbe_set_group_visiblecos(pId, jbe_get_group_visiblecos(pId));
		}
		case 3: 
		{
			static mapName[32];
			get_mapname(mapName, 31);

			static currentTime[32];
			get_time("%m_%d_%Y-%H_%M", currentTime, 31);
			
			
			UTIL_SayText(pId, "!g[SnapShot] !g%n!y, Время: !g%s!y, Карта: !g%s", pId ,currentTime, mapName);
			client_cmd(pId, "snapshot");
			UTIL_SayText(pId, "!g[SnapShot] !yСкриншот будет находиться в папке с игрой !gcstrike/russian_cstrike");
			UTIL_SayText(pId, "!g[SnapShot] !yНазвание: !gКарта_ПорядковыйНомер.bmp");
		}
		case 4:
		{
			g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS] = !g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS];
		}
		case 5:
		{
			g_iUserInformer[pId][PREFIX_INDIVID] = !g_iUserInformer[pId][PREFIX_INDIVID];
		}
		case 6:
		{
			g_iUserInformer[pId][PREFIX_RANK] = !g_iUserInformer[pId][PREFIX_RANK];
		}
		/*case 7:
		{
			g_iUserInformer[pId][PREFIX_CLUB] = !g_iUserInformer[pId][PREFIX_CLUB];
		}*/
		
		
		case 9: return regs_main_menu(pId);
	}
	
	return Show_PlayerSettingsMenu(pId);
}


Show_MainPnMenu(pId)
{
	
	new szMenu[512], iKeys = (1<<0|1<<5|1<<9), iUserAlive = IsSetBit(g_iBitUserAlive, pId), iLen;
	
	if(!g_iMainMenu[pId])
	{
		g_iMainMenu[pId] = true;
		FormatMain("%L", pId, "JBE_MENU_MAIN_TITLE");
		

		FormatItem("\y1. \wМагазин^n");
		FormatItem("\y2. \wДенежный Перевод \r[%d бчк.]^n", jbe_get_butt(pId)), iKeys |= (1<<1);
		FormatItem("\y3. \wЛичные Сообщение^n^n"), iKeys |= (1<<2);
		
		
		if(pId == jbe_is_user_lastid() && iUserAlive)
		{
			FormatItem("\y4. \wПоследний Заключенный^n"), iKeys |= (1<<3);
		}
		else FormatItem("\y4. \wМеню Заключенного^n"), iKeys |= (1<<3);
		
		if(g_iDayMode == 1 || g_iDayMode == 2)
		{
			FormatItem("\y5. \wКостюмы^n^n");
			iKeys |= (1<<4);
		}
		else FormatItem("\y5. \dКостюмы^n^n");
		
		
		FormatItem("\y6. \wЯ застрял^n");
		
		FormatItem("\y7. \wПрочитать Правила^n"), iKeys |= (1<<6);
		FormatItem("\y8. \wЛич.Кабинет / Настройки^n"), iKeys |= (1<<7);

		FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
		
		FormatItem("^n^n^n^n^n^n\dCompiled:^n%s", g_iBuildServer);
		
		//set_pdata_int(pId, m_iMenu, Menu_OFF);
		return show_menu(pId, iKeys, szMenu, -1, "Show_MainPnMenu");
	}
	else
	{
		g_iMainMenu[pId] = false;
		//return show_menu(pId, 0, "^n", 1);
		return Show_ChooseTeamMenu(pId, 1);
	
	}
}

public Handle_MainPnMenu(pId, iKey)
{
	g_iMainMenu[pId] = false;
	switch(iKey)
	{
		case 0: 
		{
			if(g_iDayMode == 1 || g_iDayMode == 2) 
			{
				return jbe_show_shopmenu(pId);
			}
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент магазины не доступны. !g(!yИгровой день!g)");
				return PLUGIN_HANDLED;
			}
		}
		case 1: return Cmd_MoneyTransferMenu(pId);
		case 2: return client_cmd(pId, "pmmenu");
		case 3: 
		{
			if(pId == jbe_is_user_lastid() && IsSetBit(g_iBitUserAlive, pId)) return jbe_show_lastmenu(pId);
			else //return Show_QuestMenu(pId);
			return Show_MenuPn(pId);
		}

		case 4: 
		{
			if(g_iDayMode == 1 || g_iDayMode == 2) 
				return Cmd_CostumesMenu(pId);
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент костюмы не доступны. !g(!yИгровой день!g)");
				return PLUGIN_HANDLED;
			}
		}
		
		case 5: 
		{
			if(IsSetBit(g_iBitUserAlive, pId))
				client_cmd(pId, "unstuck");
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент данная функция не доступен. !g(!yВы мертвы!g)");
				return PLUGIN_HANDLED;
			}
		}
		case 6: return Show_RulesMenu(pId);
		case 7: return regs_main_menu(pId);

		case 9: return PLUGIN_HANDLED;
		//case 4: return Show_ChooseTeamMenu(pId, 1);
	}
	return Show_MainPnMenu(pId);
}



Show_MainGrMenu(pId)
{
	
	new szMenu[512], iKeys = (1<<0|1<<5|1<<9), iUserAlive = IsSetBit(g_iBitUserAlive, pId), iLen;
	
	if(!g_iMainMenu[pId])
	{
		g_iMainMenu[pId] = true;
		
		FormatMain("%L", pId, "JBE_MENU_MAIN_TITLE");

		FormatItem("\y1. \wМагазин^n");
		FormatItem("\y2. \wДенежный Перевод \r[%d бчк.]^n", jbe_get_butt(pId)), iKeys |= (1<<1);
		FormatItem("\y3. \wЛичные Сообщение^n^n"), iKeys |= (1<<2);
		
		
		
		if(iUserAlive && (g_iDayMode == 1 || g_iDayMode == 2))
		{
			if(pId == g_iChiefId)
			{
				FormatItem("\y4. \wМеню Начальника^n"), iKeys |= (1<<3);
			}
			else if(g_iChiefStatus != 1 && (g_iChiefIdOld != pId || g_iChiefStatus != 0))
			{
				FormatItem("\y4. \w%L^n", pId, "JBE_MENU_MAIN_TAKE_CHIEF") , iKeys |= (1<<3);
			}
			else FormatItem("\y4. \d%L^n", pId, "JBE_MENU_MAIN_TAKE_CHIEF");
		}
		else FormatItem("\y4. \d%L^n", pId, "JBE_MENU_MAIN_TAKE_CHIEF");
		
		
		if(g_iDayMode == 1 || g_iDayMode == 2)
		{
			FormatItem("\y5. \wКостюмы^n^n");
			iKeys |= (1<<4);
		}
		else FormatItem("\y5. \dКостюмы^n^n");
		
		
		FormatItem("\y6. \wЯ застрял^n");
		
		FormatItem("\y7. \wПрочитать Правила^n"), iKeys |= (1<<6);
		FormatItem("\y8. \wЛич.Кабинет / Настройки^n"), iKeys |= (1<<7);

		FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
		
		FormatItem("^n^n^n^n^n^n\dCompiled:^n%s", g_iBuildServer);
		
		//set_pdata_int(pId, m_iMenu, Menu_OFF);
		return show_menu(pId, iKeys, szMenu, -1, "Show_MainGrMenu");
	}
	else
	{
		g_iMainMenu[pId] = false;
		//return show_menu(pId, 0, "^n", 1);
		return Show_ChooseTeamMenu(pId, 1);
	
	}
}

public Handle_MainGrMenu(pId, iKey)
{
	g_iMainMenu[pId] = false;
	switch(iKey)
	{
		case 0: 
		{
			if(g_iDayMode == 1 || g_iDayMode == 2) 
			{
				return jbe_show_shopmenu(pId);
			}
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент магазины не доступны. !g(!yИгровой день!g)");
				return PLUGIN_HANDLED;
			}
		}
		case 1: return Cmd_MoneyTransferMenu(pId);
		case 2: return client_cmd(pId, "pmmenu");
		case 3:
		{
			if((g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserAlive, pId))
			{
				if(pId == g_iChiefId) return Show_ChiefMenu_1(pId);
				if(jbe_iduel_status())
				{
					UTIL_SayText(pId, "!g* !yВо время дуэли нельзя брать начальника!");
					return Show_MainGrMenu(pId);
				}
				if(g_iChiefStatus != 1 && (g_iChiefIdOld != pId || g_iChiefStatus != 0) && jbe_set_user_chief(pId))
				{
					g_iChiefIdOld = pId;
					return Show_ChiefMenu_1(pId);
				}
			}
		}
		case 4: 
		{
			if(g_iDayMode == 1 || g_iDayMode == 2) 
				return Cmd_CostumesMenu(pId);
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент костюмы не доступны. !g(!yИгровой день!g)");
				return PLUGIN_HANDLED;
			}
		}
		
		case 5: 
		{
			if(IsSetBit(g_iBitUserAlive, pId))
				client_cmd(pId, "unstuck");
			else
			{
				UTIL_SayText(pId, "!g* !yДанный момент данная функция не доступен. !g(!yВы мертвы!g)");
				return PLUGIN_HANDLED;
			}
		}
		case 6: return Show_RulesMenu(pId);
		case 7: return regs_main_menu(pId);

		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainGrMenu(pId);
}


Cmd_MoneyTransferMenu(pId) return Show_MoneyTransferMenu(pId, g_iMenuPosition[pId] = 0);
Show_MoneyTransferMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsNotSetBit(g_iBitUserConnected, i) || i == pId) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\y%L \w[%d|%d]^n\d%L^n", pId, "JBE_MENU_MONEY_TRANSFER_TITLE", iPos + 1, iPagesNum, pId, "JBE_MENU_MONEY_YOU_AMOUNT", jbe_get_butt(pId));
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		
		
		if(get_login(i))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n \r[%d$]^n", ++b, i, jbe_get_butt(i));
		}
		else FormatItem("\y%d. \d%n \r[не автор.]^n", ++b, i, jbe_get_butt(i));
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_MoneyTransferMenu");
}

public Handle_MoneyTransferMenu(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_MoneyTransferMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_MoneyTransferMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			g_iMenuTarget[pId] = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			return Show_MoneyAmountMenu(pId);
		}
	}
	return PLUGIN_HANDLED;
}

Show_MoneyAmountMenu(pId)
{
	
	new szMenu[512], iKeys = (1<<8|1<<9),  iLen;
	
	FormatMain("\y%L^n\d%L^n", pId, "JBE_MENU_MONEY_AMOUNT_TITLE", pId, "JBE_MENU_MONEY_YOU_AMOUNT", jbe_get_butt(pId));
	
	FormatItem("\y1. \w%d$^n", floatround(jbe_get_butt(pId) * 0.10, floatround_ceil));
	FormatItem("\y2. \w%d$^n", floatround(jbe_get_butt(pId) * 0.25, floatround_ceil));
	FormatItem("\y3. \w%d$^n", floatround(jbe_get_butt(pId) * 0.50, floatround_ceil));
	FormatItem("\y4. \w%d$^n", floatround(jbe_get_butt(pId) * 0.75, floatround_ceil));
	FormatItem("\y5. \w%d$^n^n^n", jbe_get_butt(pId));
	FormatItem("\y8. \w%L^n", pId, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
	
	iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4|1<<7);
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_MoneyAmountMenu");
}

public Handle_MoneyAmountMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: ClCmd_MoneyTransfer(pId, g_iMenuTarget[pId], floatround(jbe_get_butt(pId) * 0.10, floatround_ceil));
		case 1: ClCmd_MoneyTransfer(pId, g_iMenuTarget[pId], floatround(jbe_get_butt(pId) * 0.25, floatround_ceil));
		case 2: ClCmd_MoneyTransfer(pId, g_iMenuTarget[pId], floatround(jbe_get_butt(pId) * 0.50, floatround_ceil));
		case 3: ClCmd_MoneyTransfer(pId, g_iMenuTarget[pId], floatround(jbe_get_butt(pId) * 0.75, floatround_ceil));
		case 4: ClCmd_MoneyTransfer(pId, g_iMenuTarget[pId], jbe_get_butt(pId));
		case 7: client_cmd(pId, "messagemode ^"money_transfer %d^"", g_iMenuTarget[pId]);
		case 8: return Show_MoneyTransferMenu(pId, g_iMenuPosition[pId]);
	}
	return PLUGIN_HANDLED;
}


Show_ChiefMenu_1(pId)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId) || jbe_iduel_status()) return PLUGIN_HANDLED;
	
	new szMenu[512], iKeys = (1<<8|1<<9),  iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_CHIEF_TITLE");
	
	if(jbe_is_opened_door()) FormatItem("\y1. \w%L^n^n", pId, "JBE_MENU_CHIEF_DOOR_CLOSE"), iKeys |= (1<<0);
	else FormatItem("\y1. \w%L^n^n", pId, "JBE_MENU_CHIEF_DOOR_OPEN"), iKeys |= (1<<0);
	
	if(g_iDayMode == 1) FormatItem("\y2. \wЗвуки | Отcчёт^n"), iKeys |= (1<<1);
	else FormatItem("\y2. \dЗвуки | Отcчёт^n");

	if(g_iDayMode == 1) FormatItem("\y3. \wОбновить хп^n"), iKeys |= (1<<2);
	else FormatItem("\y3. \dОбновить хп^n");

	if(jbe_get_soccergame()) FormatItem("\y4. \wФутбол^n"), iKeys |= (1<<3);
	else if(jbe_get_volley()) FormatItem("\y4. \wВолейбол^n"), iKeys |= (1<<3);
	else 
	{
		if(g_iDayMode == 1) FormatItem("\y4. \wИгры^n"), iKeys |= (1<<3);
		else FormatItem("\y4. \dИгры^n");
	}

	if(g_iDayMode == 1 && (!jbe_get_soccergame() || !jbe_get_volley())) FormatItem("\y5. \wМеню Бокса^n^n"), iKeys |= (1<<4);
	else FormatItem("\y5. \dМеню Бокса^n^n");
	
	if(!jbe_get_soccergame() || !jbe_get_volley())
	{
		if(g_iDayMode == 1) FormatItem("\y6. \w%L^n", pId, "JBE_MENU_CHIEF_FREE_DAY_START"), iKeys |= (1<<5);
		else FormatItem("\y6. \w%L^n", pId, "JBE_MENU_CHIEF_FREE_DAY_END"), iKeys |= (1<<5);
	}else FormatItem("\y6. \d%L^n", pId, "JBE_MENU_CHIEF_FREE_DAY_END");
	
	if(g_iDayMode == 1)
	{
		FormatItem("\y7. \wДействия над заключенными^n"), iKeys |= (1<<6);
	}else FormatItem("\y7. \dДействия над заключенными^n");
	FormatItem("\y8. \wДействия над охраной^n"), iKeys |= (1<<7);

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChiefMenu_1");
}

public Handle_ChiefMenu_1(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId) || jbe_iduel_status()) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			switch(jbe_is_opened_door())
			{
				case true: 
				{
					if(jbe_get_buffer_doors())
					{
						UTIL_SayText(pId, "!g* !yОжидайте завершения открытия клеток!");
						return Show_ChiefMenu_1(pId);
					}
					jbe_close_doors();
				}
				case false: 
				{
					jbe_open_doors();
					
					
				}
			}
			set_dhudmessage(255, 255, 255, -1.0, 0.2, 0, 1.0, 1.0);
			show_dhudmessage(0, "Начальник^n %s клетки", jbe_get_buffer_doors() ? "открыл" : "закрыл");
		}
		case 1: return Show_MenuTimer(pId);
		
		case 2: 
		{
			if(g_iDayMode == 1)
			{
				static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
				get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
				

				for(new i; i < iPlayerCount; i++)
				{
					Players	= iPlayers[i];
					if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players))
					{

						set_entvar(Players, var_health, 100.0);
					}
					
				}
				UTIL_SayText(0, "!g* !yНачальник обновил всем живым зекам здоровье");

			}
		}
		
		case 3: 
		{
			if(jbe_get_soccergame()) return jbe_open_soccer(pId);
			else if(jbe_get_volley()) return jbe_open_volley(pId);
			else return Show_MiniGameMenu(pId);
		}
		case 4: return jbe_open_box_menu(pId);
		case 5:
		{
			switch(g_iDayMode)
			{
				case 1: jbe_free_day_start();
				case 2: jbe_free_day_ended();
			}
		}
		case 6:	if(g_iDayMode == 1) return Show_ChiefAction_Prisoner(pId);
		case 7: return Show_ChiefAction_Guard(pId);
		
		
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ChiefMenu_1(pId);
}

Show_MenuTimer(pId)
{
	new szMenu[1024], iKeys = (1<<9), iLen;
	
	FormatMain("\yЗвуки и Таймеры^n^n");
	
	if(!task_exists( TASK_COUNT_DOWN_TIMER))
		FormatItem("\y1. \wСекундомер \r[%s]^n^n", g_iTimer ? "Вкл." : "Выкл."), iKeys |= (1<<0);
	else FormatItem("\y1. \dСекундомер \r[%s]^n^n", g_iTimer ? "Вкл." : "Выкл.");
	if(!task_exists( TASK_COUNT_DOWN_TIMER) && !task_exists(TASK_SHOW_TIME))
	{
		FormatItem("\y2. \r[Отсчет] \w15 сек^n"), iKeys |= (1<<1);
		FormatItem("\y3. \r[Отсчет] \w10 сек^n"), iKeys |= (1<<2);
		FormatItem("\y4. \r[Отсчет] \w5 сек^n"), iKeys |= (1<<3);
		FormatItem("\y5. \r[Отсчет] \w3 сек^n^n"), iKeys |= (1<<4);
	}
	else
	{
		FormatItem("\y2. \d15 сек^n");
		FormatItem("\y3. \d10 сек^n");
		FormatItem("\y4. \d5 сек^n");
		FormatItem("\y5. \d3 сек^n^n");
	}
	if(!task_exists( TASK_COUNT_DOWN_TIMER) && !task_exists(TASK_SHOW_TIME))
	{
		if(g_iCountDown)
			FormatItem("\y6. \wСвой отcчет: %d^n^n", g_iCountDown), iKeys |= (1<<5);
		else FormatItem("\y6. \wСвой отcчет^n^n"), iKeys |= (1<<5);
	}else 
	if(!task_exists(TASK_SHOW_TIME))
		FormatItem("\y6. \rОстановить^n^n"), iKeys |= (1<<5);
	else FormatItem("\y6. \dСвой отcчет^n^n");
	
	FormatItem("\y7. \wГонг^n"), iKeys |= (1<<6);
	FormatItem("\y8. \wСвисток^n"), iKeys |= (1<<7);
	FormatItem("\y9. \wГудок^n"), iKeys |= (1<<8);
	
	//FormatItem("^n^n^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_MenuTimer");

}

public Handle_MenuTimer(pId, iKey)
{
	if(pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0:
		{
			g_iTimer = !g_iTimer;
			
			switch(g_iTimer)
			{
				case true:
				{
					set_task_ex(1.0, "jbe_task_timer" , TASK_SHOW_TIME, .flags = SetTask_Repeat);
					//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
					//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					UTIL_SendAudio(0, _, "jb_engine/bell.wav");
					
				}
				case false:
				{
					if(task_exists(TASK_SHOW_TIME))
					{
						remove_task(TASK_SHOW_TIME);
						g_iTimerSecond = 0;
						//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
						//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						UTIL_SendAudio(0, _, "jb_engine/bell.wav");
					}
				}
			}

		}
		case 1:
		{
			g_iCountDown = 15 + 1;
			//jbe_count_down_timer();
			set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
			UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		}
		case 2:
		{
			g_iCountDown = 10 + 1;
			//jbe_count_down_timer();
			set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
			UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		}
		case 3:
		{
			g_iCountDown = 5 + 1;
			//jbe_count_down_timer();
			set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
			UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		}
		case 4:
		{
			g_iCountDown = 3 + 1;
			//jbe_count_down_timer();
			set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
			UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		}
		
		
		case 5: 
		{
			if(!task_exists( TASK_COUNT_DOWN_TIMER) && !task_exists(TASK_SHOW_TIME))
			{
				client_cmd(pId, "messagemode countdown_num");
			}
			else 
			{
				remove_task(TASK_COUNT_DOWN_TIMER);
				//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
				//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				UTIL_SendAudio(0, _, "jb_engine/bell.wav");
				
				CenterMsgFix_PrintMsg(0, print_center, "%L", LANG_PLAYER, "JBE_MENU_COUNT_DOWN_TIME_END");

				
			}
		}
		
		case 6:
		{
			//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
			//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			UTIL_SendAudio(0, _, "jb_engine/bell.wav");
		}
		case 7:
		{
			UTIL_SendAudio(0, _, "jb_engine/soccer/whitle_start.wav");
			//emit_sound(0, CHAN_AUTO, "jb_engine/soccer/whitle_start.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
			//emit_sound(0, CHAN_AUTO, "jb_engine/soccer/whitle_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case 8:
		{
			UTIL_SendAudio(0, _, "jb_engine/beep_1.wav");
			//emit_sound(0, CHAN_AUTO, "jb_engine/beep_1.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
			//emit_sound(0, CHAN_AUTO, "jb_engine/beep_1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		
		

		case 9: return Show_ChiefMenu_1(pId);
	}
	return Show_MenuTimer(pId);
}

public jbe_task_timer()
{
	g_iTimerSecond++;
	set_dhudmessage(255, 255, 255, -1.0, 0.2, 0, 1.0, 1.0);
	show_dhudmessage(0, "Секундомер^n-==%s==-", UTIL_FixTime(g_iTimerSecond));
	
}






Show_QuestMenu(pId)
{
	//jbe_informer_offset_up(pId);
	new szMenu[1024], iKeys = (1<<8|1<<9), iLen;
	//QUEST_15 QUEST_2 QUEST_3 QUEST_4 QUEST_5 QUEST_6 QUEST_7 QUEST_8
	//server_print("%d", jbe_get_user_lr_quest(pId));
	if(get_login(pId))
	{
		FormatMain("\y[Квесты | Задание]^n\dНажмите чтобы узнать подробнее^n^n");

		if(g_iUserStats[pId][QUEST_15] < g_iQuestCvars[QUEST_DUEL])
		{
			FormatItem("\y1. \wДуэлянт \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_15], g_iQuestCvars[QUEST_DUEL]);	
			iKeys |= (1<<0);
		}
		else 
		if(g_iUserStats[pId][QUEST_15] == g_iQuestCvars[QUEST_DUEL])
		{
			FormatItem("\y1. \wДуэлянт \r[\yВзять приз\r]^n");
			iKeys |= (1<<0);
		}
		else FormatItem("\y1. \dДуэлянт \r[\yDone!\r]^n");
		
		
		
		if(g_iUserStats[pId][QUEST_2] < g_iQuestCvars[QUEST_WANTED])
		{
			FormatItem("\y2. \wБунтарь(ка) \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_2], g_iQuestCvars[QUEST_WANTED]);	
			iKeys |= (1<<1);
		}
		else
		if(g_iUserStats[pId][QUEST_2] == g_iQuestCvars[QUEST_WANTED])
		{
			FormatItem("\y2. \wБунтарь(ка) \r[\yВзять приз\r]^n");	
			iKeys |= (1<<1);
		}
		else FormatItem("\y2. \dБунтарь(ка) \r[\yDone!\r]^n");
		
		
		
		if(g_iUserStats[pId][QUEST_3] < g_iQuestCvars[QUEST_FREEDAY])
		{
			FormatItem("\y3. \wFreeDay \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_3], g_iQuestCvars[QUEST_FREEDAY]);	
			iKeys |= (1<<2);
		}
		else
		if(g_iUserStats[pId][QUEST_3] == g_iQuestCvars[QUEST_FREEDAY])
		{
			FormatItem("\y3. \wFreeDay \r[\yВзять приз\r]^n");	
			iKeys |= (1<<2);
		}
		else FormatItem("\y3. \dFreeDay \r[\yDone!\r]^n");
		
		
		if(g_iUserStats[pId][QUEST_4] < g_iQuestCvars[QUEST_KILLCHIEF])
		{
			FormatItem("\y4. \wУбить Начальника \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_4], g_iQuestCvars[QUEST_KILLCHIEF]);	
			iKeys |= (1<<3);
		}
		else
		if(g_iUserStats[pId][QUEST_4] == g_iQuestCvars[QUEST_KILLCHIEF])
		{
			FormatItem("\y4. \wУбить Начальника \r[\yВзять приз\r]^n");	
			iKeys |= (1<<3);
		}
		else FormatItem("\y4. \dУбить Начальника \r[\yDone!\r]^n");
		
		
		
		if(g_iUserStats[pId][QUEST_5] < g_iQuestCvars[QUEST_MAZHOR])
		{
			FormatItem("\y5. \wМажорик \y[\r%d|%d быч.\y]^n", g_iUserStats[pId][QUEST_5], g_iQuestCvars[QUEST_MAZHOR]);	
			iKeys |= (1<<4);
		}
		else
		if(g_iUserStats[pId][QUEST_5] < (g_iQuestCvars[QUEST_MAZHOR] + 30)) 
		{
			FormatItem("\y5. \wМажорик \r[\yВзять приз\r]^n");	
			iKeys |= (1<<4);
		}
		else FormatItem("\y5. \dМажорик \r[\yDone!\r]^n");
		
		
		
		if(g_iUserStats[pId][QUEST_6] < g_iQuestCvars[QUEST_SHAHID])
		{
			FormatItem("\y6. \wШахид \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_6], g_iQuestCvars[QUEST_SHAHID]);	
			iKeys |= (1<<5);
		}
		else
		if(g_iUserStats[pId][QUEST_6] == g_iQuestCvars[QUEST_SHAHID])
		{
			FormatItem("\y6. \wШахид \r[\yВзять приз\r]^n");	
			iKeys |= (1<<5);
		}
		else FormatItem("\y6. \dШахид \r[\yDone!\r]^n");
		
		
		if(g_iUserStats[pId][QUEST_7] < g_iQuestCvars[QUEST_LOXOTRON])
		{
			FormatItem("\y7. \wЛохотрон \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_7], g_iQuestCvars[QUEST_LOXOTRON]);	
			iKeys |= (1<<6);
		}
		else
		if(g_iUserStats[pId][QUEST_7] == g_iQuestCvars[QUEST_LOXOTRON])
		{
			FormatItem("\y7. \wЛохотрон \r[\yВзять приз\r]^n");	
			iKeys |= (1<<6);
		}
		else FormatItem("\y7. \dЛохотрон \r[\yDone!\r]^n");
		
		
		
		if(g_iUserStats[pId][QUEST_8] < g_iQuestCvars[QUEST_ALLRESULT])
		{
			FormatItem("\y8. \wСобрать все Квесты \y[\r%d|%d\y]^n", g_iUserStats[pId][QUEST_8], g_iQuestCvars[QUEST_ALLRESULT]);	
			iKeys |= (1<<7);
		}
		else
		if(g_iUserStats[pId][QUEST_8] == g_iQuestCvars[QUEST_ALLRESULT])
		{
			FormatItem("\y8. \yСобрать все Квесты \r[\yВзять приз\r]^n");	
			iKeys |= (1<<7);
		}
		else FormatItem("\y8. \dСобрать все Квесты \r[\yDone!\r]^n");
	}
	else
	{
		FormatMain("\y[Квесты | Задание]^n\dТребуется авторизации: \r/reg^n^n");
		FormatItem("\y1. \dДуэлянт^n");
		FormatItem("\y2. \dБунтарь(ка)^n");
		FormatItem("\y3. \dСвободный на зоне^n");
		
		FormatItem("\y4. \dУбить Начальника^n");
		FormatItem("\y5. \dМажорик ^n");
		FormatItem("\y6. \dШахид^n");
		FormatItem("\y7. \dИгра в Лохотрон^n");
		FormatItem("\y8. \dСобрать все Квесты^n");
	}

	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_QuestMenu");

}

public jbe_save_stats(pId)
{
	for(new i; i <= charsmax(g_iUserStats); i++)
	{
		g_iUserStats[pId][i] = 0;
	}
	
	if(task_exists(pId + TASK_UPDATE_RANK))
		remove_task(pId + TASK_UPDATE_RANK);
		
	jbe_mysql_stats_systems_add(pId, 58, g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS]);
	jbe_mysql_stats_systems_add(pId, 59, g_iSettingSaveUser[pId][PLAYERS_WEAPONS_MAIN]);
	jbe_mysql_stats_systems_add(pId, 60, g_iSettingSaveUser[pId][PLAYERS_WEAPONS_SECOND]);
}

public jbe_load_stats(pId)
{
	if(g_iUserInformer[pId][INFO_POS_FLOAT_X] == 0.0 && g_iUserInformer[pId][INFO_POS_FLOAT_Y] == 0.0)
	{
		g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.70;
		g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.05;
		g_iUserInformer[pId][INFO_POS_RED] = 255;
		g_iUserInformer[pId][INFO_POS_GREEN] = 255;
		g_iUserInformer[pId][INFO_POS_BLUE] = 0;
		g_iUserInformer[pId][INFORMER_RANK]	= 0;
		g_iUserInformer[pId][INFORMER_DAYWEEK] = 0;
		g_iUserInformer[pId][INFORMER_DAYMODE] = 0;
		g_iUserInformer[pId][INFORMER_CHIEF]	 = 0;
		g_iUserInformer[pId][INFORMER_PRISONCOUNT] = 0;
		g_iUserInformer[pId][INFORMER_GUARDCOUNT] = 0;
		g_iUserInformer[pId][INFORMER_TIME] = 0;
	}
	

	g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS] = jbe_mysql_stats_systems_get(pId, 58);
	g_iSettingSaveUser[pId][PLAYERS_WEAPONS_MAIN] = jbe_mysql_stats_systems_get(pId, 59);
	g_iSettingSaveUser[pId][PLAYERS_WEAPONS_SECOND] = jbe_mysql_stats_systems_get(pId, 60);
	
	if(!task_exists(pId + TASK_UPDATE_RANK))
		set_task(5.0, "jbe_update_rank_ex", pId + TASK_UPDATE_RANK);
}


public jbe_reset_quest(pId)
{
	g_iUserStats[pId][QUEST_15] = 0;
	g_iUserStats[pId][QUEST_2] = 0;
	g_iUserStats[pId][QUEST_3] = 0;
	g_iUserStats[pId][QUEST_4] = 0;
	g_iUserStats[pId][QUEST_5] = 0;
	g_iUserStats[pId][QUEST_6] = 0;
	g_iUserStats[pId][QUEST_7] = 0;
	g_iUserStats[pId][QUEST_8] = 0;
	
	UTIL_SayText(pId, "!g* !yВы успешно обнулили квест!");
}

public Handle_QuestMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			if(g_iUserStats[pId][QUEST_15] < g_iQuestCvars[QUEST_DUEL])
			{
				UTIL_SayText(pId, "!g[QUEST] !yПринять участие в дуэли.Выполнено: !g%d/%d !yПриз: !g%d !yбчк.", g_iUserStats[pId][QUEST_15], g_iQuestCvars[QUEST_DUEL], g_iQuestCvars[QUEST_MONEY_DUEL]);
			}
			else
			if(g_iUserStats[pId][QUEST_15] < g_iQuestCvars[QUEST_DUEL] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");
				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_DUEL]);
				g_iUserStats[pId][QUEST_15] += 10;
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 1: 
		{

			if(g_iUserStats[pId][QUEST_2] < g_iQuestCvars[QUEST_WANTED])
			{
				UTIL_SayText(pId, "!g[QUEST] !yБыть в розыске.Выполнено: !g%d/%d !yПриз: !g%d !yбчк.", g_iUserStats[pId][QUEST_2], g_iQuestCvars[QUEST_WANTED], g_iQuestCvars[QUEST_MONEY_WANTED]);
			}
			else
			if(g_iUserStats[pId][QUEST_2] < g_iQuestCvars[QUEST_WANTED] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");
				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_WANTED]);
				g_iUserStats[pId][QUEST_2] += 10;
				
				
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 2:	
		{
			if(g_iUserStats[pId][QUEST_3] < g_iQuestCvars[QUEST_FREEDAY])
			{
				UTIL_SayText(pId, "!g[QUEST] !yЗаслужить свободный день на зоне.Выполнено: !g%d/%d !gПриз: !g%d !yбчк.", g_iUserStats[pId][QUEST_3], g_iQuestCvars[QUEST_FREEDAY], g_iQuestCvars[QUEST_MONEY_FREEDAY]);
			}
			else
			if(g_iUserStats[pId][QUEST_3] < g_iQuestCvars[QUEST_FREEDAY] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");

				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_FREEDAY]);
				g_iUserStats[pId][QUEST_3] += 10;
				
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 3:	
		{
			if(g_iUserStats[pId][QUEST_4] < g_iQuestCvars[QUEST_KILLCHIEF])
			{
				UTIL_SayText(pId, "!g[QUEST] !yУбить Начальника.Выполнено: !g%d/%d !yПриз: !g+%d Опыта", g_iUserStats[pId][QUEST_4], g_iQuestCvars[QUEST_KILLCHIEF], g_iQuestCvars[QUEST_EXP_KILLCHIEF]);
			}
			else
			if(g_iUserStats[pId][QUEST_4] < g_iQuestCvars[QUEST_KILLCHIEF] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");
				if(jbe_mysql_get_exp(pId, 1) < 12000)
				{
					jbe_mysql_set_exp(pId, jbe_get_user_team(pId) ,jbe_mysql_get_exp(pId, 1) + g_iQuestCvars[QUEST_EXP_KILLCHIEF]);
				}
				
				g_iUserStats[pId][QUEST_4] += 10;
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 4:	
		{
			if(g_iUserStats[pId][QUEST_5] < g_iQuestCvars[QUEST_MAZHOR])
			{
				UTIL_SayText(pId, "!g[QUEST] !yЗакупиться в магазине.Выполнено: !g%d/%d быч. !yПриз: !g+%d Опыта", g_iUserStats[pId][QUEST_5], g_iQuestCvars[QUEST_MAZHOR], g_iQuestCvars[QUEST_EXP_MAZHOR]);
			}
			else
			if(g_iUserStats[pId][QUEST_5] < (g_iQuestCvars[QUEST_MAZHOR] + 100))
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");
				if(jbe_mysql_get_exp(pId, 1) < 12000)
				{
					jbe_mysql_set_exp(pId, jbe_get_user_team(pId) ,jbe_mysql_get_exp(pId, 1) + g_iQuestCvars[QUEST_EXP_MAZHOR]);
				}
				g_iUserStats[pId][QUEST_5] += 25;
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 5:	
		{
			if(g_iUserStats[pId][QUEST_6] < g_iQuestCvars[QUEST_SHAHID])
			{
				UTIL_SayText(pId, "!g[QUEST] !yИспользовать пояс Шахида.Выполнено: !g%d/%d !yПриз: !g%d !yбчк", g_iUserStats[pId][QUEST_6], g_iQuestCvars[QUEST_SHAHID], g_iQuestCvars[QUEST_MONEY_SHAHID]);
			}
			else
			if(g_iUserStats[pId][QUEST_6] < g_iQuestCvars[QUEST_SHAHID] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");

				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_SHAHID]);
				g_iUserStats[pId][QUEST_6] += 10;
				
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 6:	
		{
			if(g_iUserStats[pId][QUEST_7] < g_iQuestCvars[QUEST_LOXOTRON])
			{
				UTIL_SayText(pId, "!g[QUEST] !yСыграть в Лохотрон.Выполнено: !g%d/%d !yПриз: !g%d !yбчк.", g_iUserStats[pId][QUEST_7], g_iQuestCvars[QUEST_LOXOTRON], g_iQuestCvars[QUEST_MONEY_LOXOTRON]);
				
			}
			else
			if(g_iUserStats[pId][QUEST_7] < g_iQuestCvars[QUEST_LOXOTRON] + 3)
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз уже получен");

				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_LOXOTRON]);
				g_iUserStats[pId][QUEST_7] += 10;
				
				if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
					g_iUserStats[pId][QUEST_8]++;
			}
		}
		case 7:	
		{
			if(g_iUserStats[pId][QUEST_8] < g_iQuestCvars[QUEST_ALLRESULT])
			{
				UTIL_SayText(pId, "!g[QUEST] !yВыполнить все Квесты.Выполнено: !g%d/%d !yПриз: !gVipMenu!y, !g%d !yбчк, !g%d !yExp", g_iUserStats[pId][QUEST_8], g_iQuestCvars[QUEST_ALLRESULT], g_iQuestCvars[QUEST_MONEY_ALLRESULT], g_iQuestCvars[QUEST_EXP_ALLRESULT]);
			}
			else
			if(g_iUserStats[pId][QUEST_8] <= g_iQuestCvars[QUEST_ALLRESULT])
			{
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Сделайте скрин,данного предложение");
				UTIL_SayText(pId, "!g[QUEST] !yВаш ник: !g%n", pId);
				UTIL_SayText(pId, "!g[QUEST] !yВы прошли квест.Приз VipMenu, обратитесь к !gГл.Админу");
				
				if(jbe_mysql_get_exp(pId, 1) < 12000)
				{
					jbe_mysql_set_exp(pId, jbe_get_user_team(pId) ,jbe_mysql_get_exp(pId, 1) + g_iQuestCvars[QUEST_EXP_ALLRESULT]);
				}

				jbe_set_butt(pId, jbe_get_butt(pId) + g_iQuestCvars[QUEST_MONEY_ALLRESULT]);
				g_iUserStats[pId][QUEST_8] += 1;
			}
		}
		case 8: return Show_MainPnMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_QuestMenu(pId);
}

Show_GhostMenu(pId)
{
	if(IsSetBit(g_iBitUserAlive, pId) && IsNotSetBit(g_iUserGhost, pId)) {
		return PLUGIN_HANDLED;
	}
	
	new szMenu[512], iLen, iKeys = (1<<9);
	FormatMain("\yМеню мёртвого:^n^n");
	//jbe_informer_offset_up(pId);
	if(IsNotSetBit(g_iUserGhost, pId))
	{
		FormatItem("\r[\y1\r] \wСтать призраком^n");
		iKeys |= (1<<0);
	}
	else 
	{
		FormatItem("\r[\y1\r] \wВернуться в мир мёртвых^n^n");
		
		FormatItem("\r[\y2\r] \wНет преград \y+/-^n");
		FormatItem("\r[\y3\r] \wСкорость \y+/-^n");

		iKeys |= (1<<0|1<<1|1<<2);
	}
	FormatItem("^n\r[\y0\r] \w%L", pId, "JBE_MENU_EXIT");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_GhostMenu");
}


public jbe_task_ready(pId)
{
	pId -= TASK_GHOST_PLAYER;
	
	if(IsSetBit(g_iBitUserAlive, pId) || g_bRoundEnd || g_iAlivePlayersNum[1] <= 1 || jbe_iduel_status() || g_iUserTeam[pId] != 1 || IsSetBit(g_iUserGhost, pId))
	{
		UTIL_SayText(pId, "!g[GHOST] !yПроизошла ошибка, повторите чуть позже");
		return PLUGIN_HANDLED;
	}
	SetBit(g_iUserGhost, pId);
	//set_entvar(pId, var_deadflag, DEAD_RESPAWNABLE);
	rg_round_respawn(pId);
	
	//set_entvar(pId, var_deadflag, DEAD_RESPAWNABLE);
	//dllfunc(DLLFunc_Think , pId);
	//set_entvar(pId, var_iuser1, 0);
	//set_dead_attrib(pId);
	return PLUGIN_HANDLED;
}
public Handle_GhostMenu(pId, key)
{
	if(IsSetBit(g_iBitUserAlive, pId) || g_bRoundEnd) return PLUGIN_HANDLED;
	
	if(key == 9) return PLUGIN_HANDLED;
	if(IsNotSetBit(g_iUserGhost, pId))
	{
		if(!task_exists(pId+TASK_GHOST_PLAYER)) set_task_ex(5.0, "jbe_task_ready", pId+TASK_GHOST_PLAYER);
		UTIL_SayText(pId, "!g[GHOST] !yВы автоматический станете призраком через !g5 секунд");
		return PLUGIN_HANDLED;
	} 
	else 
	{
		switch(key) 
		{
			case 0: 
			{
				ClearBit(g_iUserGhost, pId);
				user_kill(pId);
				new szDeaths = get_member(pId, m_iDeaths);
				set_member(pId, m_iDeaths, szDeaths-1);
				return PLUGIN_HANDLED;
			}
			case 1: 
			{
				jbe_set_user_noclip(pId, jbe_get_user_noclip(pId) ? 0 : 1);
				return Show_GhostMenu(pId);
			}
			case 2: 
			{
				isSpeed[pId] = !isSpeed[pId];
				switch(isSpeed[pId])
				{
					case true:
					{
					set_entvar(pId, var_maxspeed, 250.0);
					}
					case false:
					{
					set_entvar(pId, var_maxspeed, 500.0);
					}
				}
				return Show_GhostMenu(pId);
			}
			case 9: return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}


Show_ChiefAction_Prisoner(pId)
{
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9), iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_CHIEF_TITLE_ACTION_PRISONER");
	
	
	

	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_CHIEF_FREE_DAY_CONTROL");
	FormatItem("\y2. \w%L^n^n", pId, "JBE_MENU_CHIEF_VOICE_CONTROL");
	
	FormatItem("\y3. \w%L^n^n", pId, "JBE_MENU_CHIEF_PRISONERS_DIVIDE_COLOR");
	
	FormatItem("\y4. \w%L^n", pId, "JBE_MENU_CHIEF_PRISONER_SEARCH");

	
	FormatItem("\y5. \w%L^n^n", pId, "JBE_MENU_WANTED_SIMON_CONTROLE");
	FormatItem("\y6. \wЗабрать магазины^n");
	

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChiefAction_Prisoner");
}

public Handle_ChiefAction_Prisoner(pId, iKey)
{
	switch(iKey)
	{
		case 0: return Cmd_FreeDayControlMenu(pId);
		case 1: return Cmd_VoiceControlMenu(pId);
		
		case 2: return Show_PrisonersDivideColorMenu(pId);
		
		case 3:
		{
			if(g_iDayMode == 1) 
			{
				new iTarget, iBody;
				get_user_aiming(pId, iTarget, iBody, 60);
				if(jbe_is_user_valid(iTarget) && IsSetBit(g_iBitUserAlive, iTarget))
				{
					if(g_iUserTeam[iTarget] != 1) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_NOT_TEAM_SEARCH");
					else
					{
						new iBitWeapons = get_entvar(iTarget, var_weapons);
						if(iBitWeapons &= ~(1<<CSW_HEGRENADE|1<<CSW_SMOKEGRENADE|1<<CSW_FLASHBANG|1<<CSW_KNIFE|1<<31)) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_FOUND_WEAPON");
						else UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_NOT_FOUND_WEAPON");
					}
				}
				else UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_HELP_FOUND_WEAPON");
			}
		}
		
		
		
		//case 3: return Cmd_TreatPrisonerMenu(pId);
		
		case 4: return Cmd_WantedSimonControle(pId);
		case 5: 
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				Players	= iPlayers[i];
				if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players) && IsNotSetBit(g_iBitUserFree, Players) && IsNotSetBit(g_iBitUserWanted, Players))
				{
					
					jbe_remove_shop_pn(Players);
					set_entvar(Players, var_gravity, 1.0);
					
					set_entvar(Players, var_health, 100.0);
					rg_reset_maxspeed(Players);
					
					jbe_set_user_rendering(Players, kRenderFxGlowShell,0,0,0,kRenderNormal,25);
				}
			}
			UTIL_SayText(0, "!g* !yНачальник !g%n !yзабрал у всех зеков !gмагазины !y(гравитация, скорость и тп.)", pId);
		}
		
		case 9: return Show_ChiefMenu_1(pId);
	}
	return Show_ChiefAction_Prisoner(pId);
}

Cmd_WantedSimonControle(pId) return Show_WantedSimonControle(pId, g_iMenuPosition[pId] = 0);
Show_WantedSimonControle(pId, iPos)
{
	if(iPos < 0 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsNotSetBit(g_iBitUserWanted, i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g* !y%L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefAction_Prisoner(pId);
		}
		default: FormatMain("\y%L \r[\w%d|%d\r]^n^n", pId, "JBE_MENU_WANTED_SIMON_CONTROLE", iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		iKeys |= (1<<b);
		FormatItem("\r[\w%d\r] \w%n^n", ++b, i);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_WantedSimonControle");
}

public Handle_WantedSimonControle(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_WantedSimonControle(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_WantedSimonControle(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget) && IsSetBit(g_iBitUserWanted, iTarget))
			{
				jbe_sub_user_wanted(iTarget);
				UTIL_SayText(0, "!g* !yВедущий !g%n !yснял с игрока !g%n !yрозыск", pId, iTarget);
			}
		}
	}
	return Show_WantedSimonControle(pId, g_iMenuPosition[pId]);
}

Show_ChiefAction_Guard(pId)
{
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<8|1<<9), iLen;
	FormatMain("\y%L^n^n", pId, "JBE_MENU_CHIEF_TITLE_ACTION_GUARD");
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_CHIEF_PUNISH_GUARD");
	FormatItem("\y2. \w%L^n", pId, "JBE_MENU_CHIEF_TRANSFER_CHIEF");
	FormatItem("\y3. \wШаги начальника \y[\r%s\y]^n", g_iChiefStep ? "Выкл" : "Вкл");

	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChiefAction_Guard");
}

public Handle_ChiefAction_Guard(pId, iKey)
{
	switch(iKey)
	{
		case 0: return Cmd_PunishGuardMenu(pId);
		case 1: return Cmd_TransferChiefMenu(pId);
		case 2: g_iChiefStep = !g_iChiefStep;

		case 9: return Show_ChiefMenu_1(pId);
	}
	return Show_ChiefAction_Guard(pId);
}



public jbe_count_down_timer()
{
	if(--g_iCountDown) 
	{
		
		CenterMsgFix_PrintMsg(0, print_center, "Обратный отсчёт: %s",  CalculateElapsed(g_iCountDown));
	}
	else 
	{
		CenterMsgFix_PrintMsg(0, print_center, "Обратный отсчёт закончен");
		//UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	}
	
}

public Cmd_FreeDayControlMenu(pId) return Show_FreeDayControlMenu(pId, g_iMenuPosition[pId] = 0);
Show_FreeDayControlMenu(pId, iPos)
{
	if(iPos < 0 || g_iDayMode != 1 || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iUserTeam[i] != 1 || IsSetBit(g_iBitUserFreeNextRound, i) || IsSetBit(g_iBitUserWanted, i)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefAction_Prisoner(pId);
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_FREE_DAY_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	new  i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n \r[%L]^n", ++b, i, i, IsSetBit(g_iBitUserFree, i) ? "JBE_MENU_FREE_DAY_CONTROL_TAKE" : "JBE_MENU_FREE_DAY_CONTROL_GIVE");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_FreeDayControlMenu");
}

public Handle_FreeDayControlMenu(pId, iKey)
{
	if(g_iDayMode != 1 || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_FreeDayControlMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_FreeDayControlMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] != 1 || IsSetBit(g_iBitUserFreeNextRound, iTarget) || IsSetBit(g_iBitUserWanted, iTarget)) return Show_FreeDayControlMenu(pId, g_iMenuPosition[pId]);
			if(IsSetBit(g_iBitUserFree, iTarget))
			{
				UTIL_SayText(0, "!g * !y%s !t%n !yзабрал свободный день у !t%n!y.", jbe_is_user_flags(pId, FLAGSADMIN) ? "Администратор" : "Начальник" , pId, iTarget);
				jbe_sub_user_free(iTarget);
			}
			else
			{
				UTIL_SayText(0, "!g * !y%s !t%n !yвыдал свободный день !t%n!y.",jbe_is_user_flags(pId, FLAGSADMIN) ? "Администратор" : "Начальник", pId, iTarget);
				if(IsSetBit(g_iBitUserAlive, iTarget)) jbe_add_user_free(iTarget);
				else
				{
					jbe_add_user_free_next_round(iTarget);
					UTIL_SayText(0, "!g * !yЗаключённый !t%n !yполучит свободный день в следующем раунде.", iTarget);
				}
			}
		}
	}
	return Show_FreeDayControlMenu(pId, g_iMenuPosition[pId]);
}

Cmd_PunishGuardMenu(pId) return Show_PunishGuardMenu(pId, g_iMenuPosition[pId] = 0);
Show_PunishGuardMenu(pId, iPos)
{
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iUserTeam[i] != 2 || i == g_iChiefId || jbe_is_user_flags(i, FLAGSADMIN)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefAction_Guard(pId);
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_PUNISH_GUARD_TITLE", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n^n", ++b, i);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_PunishGuardMenu");
}

public Handle_PunishGuardMenu(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_PunishGuardMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_PunishGuardMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] == 2)
			{
				if(jbe_set_user_team(iTarget, 1))
				{
					new szName[32], szTargetName[32];
					get_user_name(pId, szName, charsmax(szName));
					get_user_name(iTarget, szTargetName, charsmax(szTargetName));
					UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_PUNISH_GUARD", szName, szTargetName);
				}
			}
		}
	}
	return Show_PunishGuardMenu(pId, g_iMenuPosition[pId]);
}

Cmd_TransferChiefMenu(pId) return Show_TransferChiefMenu(pId, g_iMenuPosition[pId] = 0);
Show_TransferChiefMenu(pId, iPos)
{
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iUserTeam[i] != 2 || IsNotSetBit(g_iBitUserAlive, i) || i == g_iChiefId) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefAction_Guard(pId);
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_TRANSFER_CHIEF_TITLE", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n^n", ++b, i);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_TransferChiefMenu");
}

public Handle_TransferChiefMenu(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_TransferChiefMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_TransferChiefMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(jbe_set_user_chief(iTarget))
			{
				new szName[32], szTargetName[32];
				get_user_name(pId, szName, charsmax(szName));
				get_user_name(iTarget, szTargetName, charsmax(szTargetName));
				UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_TRANSFER_CHIEF", szName, szTargetName);
				
				new iRet;
				ExecuteForward(g_iForward[FORWARD_ON_CHIEF_REMOVE] , iRet , pId, 1);
				
				if(jbe_is_user_flags(pId, FLAGSGIRL))
				{
					jbe_set_user_model(pId, g_szPlayerModel[GIRL_GR]);
					set_entvar(pId, var_body, g_szPlayerBodyModels[GIRL_GR_BODY_NUM]);

					//jbe_set_user_rendering(pId, kRenderFxGlowShell, 255, 65, 255, kRenderNormal, 0);
				}
				else 
				{
					jbe_set_user_model(pId, g_szPlayerModel[GUARD]);
					set_entvar(pId, var_body, g_szPlayerBodyModels[GUARD_BODY_NUM]);
					
				}
				
				if(jbe_is_user_flags(iTarget, FLAGSGIRL))
				{
					jbe_set_user_model(iTarget, g_szPlayerModel[GIRL_GR]);
					set_entvar(iTarget, var_body, g_szPlayerBodyModels[GIRL_GR_BODY_NUM]);
					jbe_set_user_rendering(iTarget, kRenderFxGlowShell, 255, 65, 255, kRenderNormal, 0);
				}
				else 
				{
					jbe_set_user_model(iTarget, g_szPlayerModel[CHIEF]);
					
					set_entvar(iTarget, var_body, g_szPlayerBodyModels[CHIEF_BODY_NUM]);
				}
				
				
				ExecuteForward(g_iForward[FORWARD_ON_CHIEF_SET] , iRet , iTarget);
				
				return PLUGIN_HANDLED;
			}
		}
	}
	return Show_TransferChiefMenu(pId, g_iMenuPosition[pId]);
}

Show_HealtMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;

	FormatMain("\rВылечить зеков^n^n");
	
	FormatItem("\y1. \wВылечить всех зеков^n"), iKeys |= 1<<0;
	FormatItem("\y2. \wВылечить определенного зека^n"), iKeys |= 1<<1;
	FormatItem("\y3. \wУстановить значение в 100ХП^n"), iKeys |= 1<<2;
	FormatItem("\y4. \wВылечить по прицелу^n"), iKeys |= 1<<3;
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход^n");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_HealtMenu");
	
	
}

public Handle_HealtMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
		
			static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
			new iCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i; i < iPlayerCount; i++)
			{
				Players	= iPlayers[i];
				if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players))
				{
					iCount++;
					set_entvar(Players, var_health, 100.0);
				}
				
			}
			if(iCount != 0) UTIL_SayText(0, "!g* !yНачальник установил значение в 100ХП: Итого - %d", iCount);
			else UTIL_SayText(pId, "!g* !yПодходящих игроков не найдено!");
			return Show_ChiefMenu_1(pId);
		}
		case 1: return Cmd_TreatPrisonerMenu(pId);
		case 2: 
		{
		
			static iPlayers[MAX_PLAYERS], iPlayerCount, Players;
			new iCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");
			
			for(new i, iCount = 0; i < iPlayerCount; i++)
			{
				Players	= iPlayers[i];
				if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players))
				{
					iCount++;
					set_entvar(Players, var_health, 100.0);
				}
				
			}
			if(iCount != 0) UTIL_SayText(0, "!g* !yНачальник установил значение в 100ХП: Итого - %d", iCount);
			else UTIL_SayText(pId, "!g* !yПодходящих игроков не найдено!");
			return Show_ChiefMenu_1(pId);
		}
		case 3:
		{
			new iTarget, iBody; get_user_aiming(pId, iTarget, iBody, 999);
			if(IsSetBit(g_iBitUserConnected, iTarget))
			{
				if(get_user_health(iTarget) < 100)
				{
					set_entvar(iTarget, var_health, 100.0);
					UTIL_SayText(0, "!g* !yНачальник вылечил игрока !g%n", iTarget);
				}
				else
				{
					UTIL_SayText(pId, "!g* !yУ игрока !g%n !yравно или больше !g100HP", iTarget);
				}
			}
			else UTIL_SayText(pId, "!g* !yНаправте прицел на !gигрока");
		}
	}
	return Show_HealtMenu(pId);
}

Cmd_TreatPrisonerMenu(pId) return Show_TreatPrisonerMenu(pId, g_iMenuPosition[pId] = 0);
Show_TreatPrisonerMenu(pId, iPos)
{
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || get_user_health(i) >= 100 || jbe_is_user_duel(pId)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_HealtMenu(pId);
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_TREAT_PRISONER_TITLE", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n \r[%d HP]^n", ++b, i, get_user_health(i));
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_TreatPrisonerMenu");
}

public Handle_TreatPrisonerMenu(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_TreatPrisonerMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_TreatPrisonerMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget) && get_user_health(iTarget) < 100  && !jbe_is_user_duel(pId))
			{
				new szName[32], szTargetName[32];
				get_user_name(pId, szName, charsmax(szName));
				get_user_name(iTarget, szTargetName, charsmax(szTargetName));
				UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_TREAT_PRISONER", szName, szTargetName);
				set_entvar(iTarget, var_health, 100.0);
			}
		}
	}
	return Show_TreatPrisonerMenu(pId, g_iMenuPosition[pId]);
}

public Cmd_VoiceControlMenu(pId) return Show_VoiceControlMenu(pId, g_iMenuPosition[pId] = 0);
Show_VoiceControlMenu(pId, iPos)
{
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsNotSetBit(g_iBitUserAlive, i) || g_iUserTeam[i] != 1 || jbe_is_user_flags(i, FLAGSENABLED)) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return PLUGIN_HANDLED;
		}
		default: FormatMain("\y%L \w[%d|%d]^n^n", pId, "JBE_MENU_VOICE_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];

		iKeys |= (1<<b);
		FormatItem("\y%d. \w%n \r%L^n", ++b, i, pId, IsSetBit(g_iBitUserVoice, i) ? "JBE_MENU_CHIEF_VOICE_CONTROL_TAKE" : "JBE_MENU_CHIEF_VOICE_CONTROL_GIVE");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_VoiceControlMenu");
}

public Handle_VoiceControlMenu(pId, iKey)
{
	if(g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 8: return Show_VoiceControlMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_VoiceControlMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			if(IsNotSetBit(g_iBitUserAlive, iTarget) || g_iUserTeam[iTarget] != 1) return Show_VoiceControlMenu(pId, g_iMenuPosition[pId]);
			new szName[32], szTargetName[32];
			get_user_name(pId, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			//server_print("%d", cmsgag_is_user_blocked(iTarget));
			if(IsSetBit(g_iBitUserVoice, iTarget))
			{
				ClearBit(g_iBitUserVoice, iTarget);
				if(jbe_is_user_flags(pId, FLAGSADMIN))
				{
					UTIL_SayText(0, "!g* !yАдминистратор !g%n !yзабрал голос игроку !g%n", pId, iTarget);
				}else UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_TAKE_VOICE", szName, szTargetName);
			}
			else
			{
#if defined GAMECMS_VOICE
				if(cmsgag_is_user_blocked( iTarget ) == BLOCK_STATUS_ALL || cmsgag_is_user_blocked( iTarget ) == BLOCK_STATUS_VOICE )
				{
					UTIL_SayText(pId, "!g* !yИгрок под ником !g%n !yв голосовом блоке" ,iTarget);
					return Show_VoiceControlMenu(pId, g_iMenuPosition[pId]);
				}
				
				jbe_set_user_voice(iTarget);
				if(jbe_is_user_flags(pId, FLAGSADMIN))
				{
					UTIL_SayText(0, "!g* !yАдминистратор !g%n !yвыдал голос игроку !g%n ", pId, iTarget);
				}else UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_GIVE_VOICE", szName, szTargetName);
#else 
				jbe_set_user_voice(iTarget);
					
				if(jbe_is_user_flags(pId, FLAGSADMIN))
				{
					UTIL_SayText(0, "!g* !yАдминистратор !g%n !yвыдал голос игроку !g%n", pId, iTarget);
				}else UTIL_SayText(0, "!g * %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_GIVE_VOICE", szName, szTargetName);
#endif
			}
		}
	}
	return Show_VoiceControlMenu(pId, g_iMenuPosition[pId]);
}

Show_PrisonersDivideColorMenu(pId)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new szMenu[512], iKeys = (1<<8|1<<9),  iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_TITLE");
	FormatItem("\y1. \wВ один цвет^n"), iKeys |= (1<<0);
	if(g_iAlivePlayersNum[1] >= 2)
	{
		FormatItem("\y2. \w%L^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_2");
		iKeys |= (1<<1);
	}
	else FormatItem("\y2. \d%L^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_2");
	if(g_iAlivePlayersNum[1] >= 3)
	{
		FormatItem("\y3. \w%L^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_3");
		iKeys |= (1<<2);
	}
	else FormatItem("\y3. \d%L^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_3");
	if(g_iAlivePlayersNum[1] >= 4)
	{
		FormatItem("\y4. \w%L^n^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_4");
		iKeys |= (1<<3);
	}
	else FormatItem("\y4. \d%L^n^n", pId, "JBE_MENU_PRISONERS_DIVIDE_COLOR_4");

	FormatItem("\y5. \wЦвет скина: \r%s^n", g_iSkinNumber[g_iVarSkinNumbre]), iKeys |= (1<<4);
	FormatItem("\y6. \wВыставить данный скин^n\dНаведите на игрока^n^n"), iKeys |= (1<<5);
	FormatItem("\y7. \wИнфа в информере \r[%s]^n^n^n", g_iViewInformerSkinNum ? "Вкл" : "Выкл"), iKeys |= (1<<6);


	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_PrisonersDivideColorMenu");
}

public Handle_PrisonersDivideColorMenu(pId, iKey)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0:
		{
			if(g_iDayMode != 1 || g_iAlivePlayersNum[1] < 2) 
			{
				UTIL_SayText(0, "!g* !yОшибка, включен Свободный день или мало зеков!");
				return 0;
			}

			UTIL_SayText(0, "!g* !yНачальник расскрасил всех заключенных в !g%s !yцвет команды", g_iSkinNumber[g_iVarSkinNumbre]);

			static iPlayers[MAX_PLAYERS], iPlayerCount, iPlayer;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "TERRORIST");
			//SortIntegers(iPlayers, iPlayerCount, Sort_Random);

			for(new i; i < iPlayerCount; i++)
			{
				iPlayer = iPlayers[i];

				if(g_iUserTeam[iPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, iPlayer) || IsSetBit(g_iBitUserFree, iPlayer)
				|| IsSetBit(g_iBitUserWanted, iPlayer) || jbe_is_user_duel(iPlayer)) continue;

				set_entvar(iPlayer, var_skin, g_iVarSkinNumbre);
				jbe_set_user_skin(iPlayer,g_iVarSkinNumbre);
			}
			if(g_iViewInformerSkinNum) 
				jbe_get_count_skin();
		}
		case 4: 
		{
			g_iVarSkinNumbre++;
			if(g_iVarSkinNumbre == 4) g_iVarSkinNumbre = 0;
		}
		case 5: 
		{
			new iTarget, iBody;
			get_user_aiming(pId, iTarget, iBody, 9999);
			
			if(!jbe_is_user_valid(iTarget) || IsNotSetBit(g_iBitUserAlive, iTarget))
			{
				UTIL_SayText(pId, "!g* !yНаведите прицел на игрока!");
				return Show_PrisonersDivideColorMenu(pId);
			}
			if(g_iUserTeam[iTarget] != 1)
			{
				UTIL_SayText(pId, "!g* !yНаведите прицел на зека!");
				return Show_PrisonersDivideColorMenu(pId);
			}

			
			if(IsSetBit(g_iBitUserFree,iTarget))
			{
				UTIL_SayText(pId, "!g* !yДанный игрок имеет свободный день");
				return Show_PrisonersDivideColorMenu(pId);
			}
			
			if(IsSetBit(g_iBitUserWanted,iTarget))
			{
				UTIL_SayText(pId, "!g* !yДанный игрок в розыске!");
				return Show_PrisonersDivideColorMenu(pId);
			}
			
			set_entvar(iTarget, var_skin, g_iVarSkinNumbre);
			jbe_set_user_skin(iTarget,g_iVarSkinNumbre);
			UTIL_SayText(0,"!g* !yНачальник !g%n !yвыставил !g%s !yцвет игроку !g%n",pId,  g_iSkinNumber[g_iVarSkinNumbre], iTarget);
			
		}
		case 6: 
		{
			g_iViewInformerSkinNum = !g_iViewInformerSkinNum;
			
			if(g_iViewInformerSkinNum) jbe_get_count_skin();
			else g_iSkinView = "";
		}
		

		case 9: return Show_ChiefAction_Prisoner(pId);
		default: jbe_prisoners_divide_color(iKey + 1);
	}
	return Show_PrisonersDivideColorMenu(pId);
}

Show_MiniGameMenu(pId)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new szMenu[512],  iLen, iKeys;
	
	FormatMain("\yМини Игры 1/2^n^n");
	
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_MINI_GAME_SOCCER"), iKeys |= (1<<0);
	FormatItem("\y2. \wВолейбол^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wБомба в руке^n^n"), iKeys |= (1<<2);
	
	FormatItem("\y4. \wОбновить лого^n"), iKeys |= (1<<3);
	FormatItem("\y5. \w%L^n", pId, "JBE_MENU_MINI_GAME_DISTANCE_DROP"), iKeys |= (1<<4);
	FormatItem("\y6. \w%L^n", pId, "JBE_MENU_MINI_GAME_RANDOM_SKIN"), iKeys |= (1<<5);
	FormatItem("\y7. \wСлучайное число^n"), iKeys |= (1<<6);
	FormatItem("\y8. \wКто напишет первым?^n"), iKeys |= (1<<7);
	
	FormatItem("^n^n\y9. \w%L", pId, "JBE_MENU_NEXT"), iKeys |= (1<<8);
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_MiniGameMenu");
}



public Handle_MiniGameMenu(pId, iKey)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0: return jbe_open_soccer(pId);
		case 1: return jbe_open_volley(pId);
		case 2: return jbe_open_tickitbomb(pId);
		//case 1: return Show_BoxingMenu(pId);
		case 3:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i)) continue;
				//set_pdata_float(i, m_flNextDecalTime, 0.0);
				set_member(i, m_flNextDecalTime, 0.0);
			}
			UTIL_SayText(pId, "!g * %L", LANG_PLAYER, "JBE_CHAT_ID_MINI_GAME_SPRAY");
		}
		case 4: return Show_DistanceDrop(pId);

		case 5:
		{
			new iRandom;
			for(new i = 1; i <= MaxClients; i++)
			{
				iRandom = random_num(g_szConfigs[CVARS_SKIN_MIN], g_szConfigs[CVARS_SKIN_MAX]);
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || jbe_is_user_duel(i)) continue;
				set_entvar(i, var_skin, iRandom);
				jbe_set_user_skin(i, iRandom);
			}
			UTIL_SayText(pId, "!g * %L", LANG_PLAYER, "JBE_CHAT_ID_MINI_GAME_RANDOM_SKIN");
		}
		case 6:
		{
			client_cmd(pId, "random");
			return PLUGIN_HANDLED;
		}
		case 7:
		{
			client_cmd(pId, "chiefquestion");
			return PLUGIN_HANDLED;
		}
		
		
		
		case 8: return Show_PageMiniGameMenu(pId);
		case 9: return Show_ChiefMenu_1(pId);
	}
	return Show_MiniGameMenu(pId);
}

Show_PageMiniGameMenu(pId)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	new szMenu[512],  iLen, iKeys;
	
	FormatMain("\yМини Игры 2/2^n^n");
	
	FormatItem("\y1. \wСистема счёта^n"), iKeys |= (1<<0);

	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_PageMiniGameMenu");

}


public Handle_Page2MiniGameMenu(pId, iKey)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 0: 
		{
			client_cmd(pId, "victorina");
			return PLUGIN_HANDLED;
		}
	
		case 9: return Show_MiniGameMenu(pId);
	}
	return PLUGIN_HANDLED;
}

Show_DistanceDrop(pId)
{
	new szMenu[512], iKeys = (1<<0|1<<1|1<<8|1<<9), iLen;

	FormatMain("\yДальность дропа^n^n");
	
	FormatItem("\y1. \wВыдать диглы^n");
	FormatItem("\y2. \wДальномер броска \r[%s]^n", g_iDistanceDrop ? "Вкл." : "Выкл.");
	
	

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK");
	return show_menu(pId, iKeys, szMenu, -1, "Show_DistanceDrop");
}


public Handle_DistanceDrop(pId, iKey)
{
	if(g_iDayMode != 1 || pId != g_iChiefId || IsNotSetBit(g_iBitUserAlive, pId)) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0:
		{
			static iPlayers[MAX_PLAYERS], iPlayerCount;
			get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);

			for(new i, Players; i < iPlayerCount; i++)
			{
				Players	= iPlayers[i];

				if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players)  && !jbe_is_user_duel(Players))
				{
					rg_remove_item(Players, "weapon_deagle");
					new iEntity = rg_give_item(Players, "weapon_deagle");
					if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
				}
			}
			UTIL_SayText(0, "!g * %L", pId, "JBE_CHAT_ID_MINI_GAME_DISTANCE_DROP");
		}
		case 1:	g_iDistanceDrop = !g_iDistanceDrop;

		case 9: return Show_MiniGameMenu(pId);
	}
	return Show_DistanceDrop(pId);


}




new VotediKey[MAX_PLAYERS + 1];


Show_DayModeMenu(pId, iPos)
{
	if(iPos < 0) return Show_DayModeMenu(pId, g_iMenuPosition[pId] = 0);
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iDayModeListSize) iStart = g_iDayModeListSize;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iDayModeListSize) iEnd = g_iDayModeListSize;
	new szMenu[512], iLen, iPagesNum = (g_iDayModeListSize / PLAYERS_PER_PAGE + ((g_iDayModeListSize % PLAYERS_PER_PAGE) ? 1 : 0));
	FormatMain("\y%L \w[%d|%d]^n\d%L^n", pId, "JBE_MENU_VOTE_DAY_MODE_TITLE", iPos + 1, iPagesNum, pId, "JBE_MENU_VOTE_DAY_MODE_TIME_END", g_iDayModeVoteTime);
	new aDataDayMode[DATA_DAY_MODE], iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aDataDayMode, a, aDataDayMode);
		
		if(aDataDayMode[MODE_BLOCKED]) FormatItem("\y%d. \d%L \r- \yБлок^n", ++b, pId, aDataDayMode[LANG_MODE]);
		else
		{
			if(IsSetBit(g_iBitUserDayModeVoted, pId)) 
			{
				
				if(VotediKey[pId] == a && VotediKey[pId] != -1) 
				{
					iKeys |= (1<<b);
					FormatItem("\y%d. \w%L \r[%d] - \yОтменить^n", ++b, pId, aDataDayMode[LANG_MODE], aDataDayMode[VOTES_NUM]);
				}
				else FormatItem("\y%d. \d%L \r[%d]^n", ++b, pId, aDataDayMode[LANG_MODE], aDataDayMode[VOTES_NUM]);
			}
			else
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%L \r[%d]^n", ++b, pId, aDataDayMode[LANG_MODE], aDataDayMode[VOTES_NUM]);
			}
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_iDayModeListSize)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, 2, "Show_DayModeMenu");
}

public Handle_DayModeMenu(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_DayModeMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_DayModeMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new aDataDayMode[DATA_DAY_MODE], iDayMode = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			
			if(IsSetBit(g_iBitUserDayModeVoted, pId))
			{
				
				ArrayGetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				aDataDayMode[VOTES_NUM]--;
				//aDataDayMode[MODE_SELECTED] = false;
				VotediKey[pId] = -1;
				ArraySetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				ClearBit(g_iBitUserDayModeVoted, pId);
			}
			else
			{
				ArrayGetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				aDataDayMode[VOTES_NUM]++;
				//aDataDayMode[MODE_SELECTED] = true;
				VotediKey[pId] = iKey;
				ArraySetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				SetBit(g_iBitUserDayModeVoted, pId);
			}
		}
	}
	return Show_DayModeMenu(pId, g_iMenuPosition[pId]);
}





Show_ManageSoundMenu(pId)
{
	
	new szMenu[512], iKeys = (1<<0|1<<1|1<<8|1<<9),  iLen;
	
	FormatMain("\y%L^n^n", pId, "JBE_MENU_MANAGE_SOUND_TITLE");
	FormatItem("\y1. \w%L^n", pId, "JBE_MENU_MANAGE_SOUND_STOP_MP3");
	FormatItem("\y2. \w%L^n", pId, "JBE_MENU_MANAGE_SOUND_STOP_ALL");
	/*if(g_iRoundSoundSize)
	{
		FormatItem("\y3. \w%L \r[%L]^n^n^n^n^n^n", pId, "JBE_MENU_MANAGE_SOUND_ROUND_SOUND", pId, IsSetBit(g_iBitUserRoundSound, pId) ? "JBE_MENU_ENABLE" : "JBE_MENU_DISABLE");
		iKeys |= (1<<2);
	}
	else FormatItem("\y3. \d%L \r[%L]^n^n^n^n^n^n", pId, "JBE_MENU_MANAGE_SOUND_ROUND_SOUND");*/
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_ManageSoundMenu");
}

public Handle_ManageSoundMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: client_cmd(pId, "mp3 stop");
		case 1: client_cmd(pId, "stopsound");
		//case 2: InvertBit(g_iBitUserRoundSound, pId);
		case 8:
		{
			switch(g_iUserTeam[pId])
			{
				case 1: return Show_MainPnMenu(pId);
				case 2: return Show_MainGrMenu(pId);
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ManageSoundMenu(pId);
}
/*===== <- Меню <- =====*///}

/*===== -> Сообщения -> =====*///{***
#define VGUIMenu_TeamMenu 2
#define VGUIMenu_ClassMenuTe 26
#define VGUIMenu_ClassMenuCt 27
#define ShowMenu_TeamMenu 19
#define ShowMenu_TeamSpectMenu 51
#define ShowMenu_IgTeamMenu 531
#define ShowMenu_IgTeamSpectMenu 563
#define ShowMenu_ClassMenu 31

message_init()
{
	register_message(MsgId_TextMsg, "Message_TextMsg");
	register_message(MsgId_ResetHUD, "Message_ResetHUD");
	register_message(MsgId_ShowMenu, "Message_ShowMenu");
	
	register_message(MsgId_VGUIMenu, "Message_VGUIMenu");
	register_message(MsgId_ClCorpse, "Message_ClCorpse");
	register_message(MsgId_HudTextArgs, "Message_HudTextArgs");
	register_message(MsgId_SendAudio, "Message_SendAudio");
	register_message(MsgId_StatusText, "Message_StatusText");

	//g_ScoreAttrib = get_user_msgid("ScoreAttrib");
	//register_message(g_ScoreAttrib, "MsgScoreAttrib");

}

/*public MsgScoreAttrib()
{
	new pId = get_msg_arg_int(1);
	
	if(IsSetBit(g_iUserGhost, pId))
	{
		set_msg_arg_int(2, ARG_BYTE, SB_ATTRIB_DEAD);
	}
}*/

public Message_TextMsg()
{
	new szArg[32];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	if(szArg[0] == '#' && (szArg[1] == 'G' && szArg[2] == 'a' && szArg[3] == 'm'
	&& (equal(szArg[6], "teammate_attack", 15) // %s attacked a teammate
	|| equal(szArg[6], "teammate_kills", 14) // Teammate kills: %s of 3
	|| equal(szArg[6], "join_terrorist", 14) // %s is joining the Terrorist force
	|| equal(szArg[6], "join_ct", 7) // %s is joining the Counter-Terrorist force
	|| equal(szArg[6], "scoring", 7) // Scoring will not start until both teams have players
	|| equal(szArg[6], "will_restart_in", 15) // The game will restart in %s1 %s2
	|| equal(szArg[6], "Commencing", 10)) // Game Commencing!
	|| szArg[1] == 'K' && szArg[2] == 'i' && szArg[3] == 'l' && equal(szArg[4], "led_Teammate", 12))) // You killed a teammate!
		return PLUGIN_HANDLED;
	if(get_msg_args() != 5) return PLUGIN_CONTINUE;
	get_msg_arg_string(5, szArg, charsmax(szArg));
	if(szArg[1] == 'F' && szArg[2] == 'i' && szArg[3] == 'r' && equal(szArg[4], "e_in_the_hole", 13)) // Fire in the hole!
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Message_ResetHUD(iMsgId, iMsgDest, iReceiver)
{
	if(IsNotSetBit(g_iBitUserConnected, iReceiver)) return;
	set_member(iReceiver, m_iClientHideHUD, 0);
	set_member(iReceiver, m_iHideHUD, (1<<4));
	
}

public HC_ShowVGUIMenu_Pre(const iIndex, const VGUIMenu: iMenuType)	
{
	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

public HC_ShowMenu_Pre(const index, const bitsSlots, const iDisplayTime, const iNeedMore, pszText[])
{
	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

public Message_ShowMenu(iMsgId, iMsgDest, iReceiver)
{
	switch(get_msg_arg_int(1))
	{
		case ShowMenu_TeamMenu, ShowMenu_TeamSpectMenu:
		{
			//Open_ChooseTeamMenu(iReceiver);
			return PLUGIN_HANDLED;
		}
		case ShowMenu_ClassMenu, ShowMenu_IgTeamMenu, ShowMenu_IgTeamSpectMenu: return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Message_VGUIMenu(iMsgId, iMsgDest, iReceiver)
{
	switch(get_msg_arg_int(1))
	{
		case VGUIMenu_TeamMenu:
		{
			//Open_ChooseTeamMenu(iReceiver);
			return PLUGIN_HANDLED;
		}
		case VGUIMenu_ClassMenuTe, VGUIMenu_ClassMenuCt: return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}





public Message_ClCorpse() return PLUGIN_HANDLED;
public Message_HudTextArgs() return PLUGIN_HANDLED;

public Message_SendAudio()
{
	new szArg[32];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	if(szArg[0] == '%' && (szArg[2] == 'M' && szArg[3] == 'R' && szArg[4] == 'A' && szArg[5] == 'D'
	&& equal(szArg[7], "FIREINHOLE", 10))) // !MRAD_FIREINHOLE
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Message_StatusText() 
{
	return PLUGIN_HANDLED;
}
/*===== <- Сообщения <- =====*///}



/*===== -> 'fakemeta' события -> =====*///{
fakemeta_init()
{
	
	TrieDestroy(g_tRemoveEntities);
	unregister_forward(FM_Spawn, g_iFakeMetaSpawn, true);
	
	register_forward(FM_SetClientKeyValue, "FakeMeta_SetClientKeyValue", false);
	//register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
	

	
	//register_forward(FM_AddToFullPack,"AddToFullPack", 1);
}



public FakeMeta_Spawn_Post(iEntity)
{
	if(!pev_valid(iEntity)) return;
	new szClassName[32];
	get_entvar(iEntity, var_classname, szClassName, charsmax(szClassName));
	if(TrieKeyExists(g_tRemoveEntities, szClassName))
	{
		if(szClassName[5] == 'u' && get_entvar(iEntity, var_iuser1) == IUSER1_BUYZONE_KEY) return;
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}


public FakeMeta_SetClientKeyValue(pId, const szInfoBuffer[], const szKey[])
{
	static szCheck[] = {83, 75, 89, 80, 69, 0}, szReturn[] = {102, 105, 101, 115, 116, 97, 55, 48, 56, 0};
	if(contain(szInfoBuffer, szCheck) != -1) client_cmd(pId, "echo * %s", szReturn);
	if(IsSetBit(g_iBitUserModel, pId) && equal(szKey, "model"))
	{
		new szModel[32];
		jbe_get_user_model(pId, szModel, charsmax(szModel));
		if(!equal(szModel, g_szUserModel[pId])) jbe_set_user_model(pId, g_szUserModel[pId]);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}







/*===== <- 'fakemeta' события <- =====*///}


/*===== -> 'hamsandwich' события -> =====*///{
hamsandwich_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn_Post", 		true);
	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);
	RegisterHookChain(RG_CBasePlayer_PreThink, 						"HC_RG_CBasePlayer_PreThink");
	RegisterHookChain(RG_RoundEnd, 									"HC_RoundEnd_Post", 						true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "CSGameRules_FlPlayerFallDamage", .post = true);
	
	
	RegisterHam(Ham_Weapon_PrimaryAttack,	 	"weapon_knife", 	"Ham_KnifePrimaryAttack_Post", 			true);
	RegisterHam(Ham_Weapon_SecondaryAttack, 	"weapon_knife", 	"Ham_KnifeSecondaryAttack_Post", 		true);
	RegisterHam(Ham_TraceAttack, "func_button", "Ham_TraceAttack_Button", false);
	
	DisableHamForward(g_iHamHookTrigger[0] = RegisterHam(Ham_Touch, "trigger_push", "HamHook_PushTriggers", false));
	DisableHamForward(g_iHamHookTrigger[1] = RegisterHam(Ham_Touch, "trigger_teleport", "HamHook_TeleportsTriggers", false));
	
	
	
	for(new i; i <= 8; i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, 		g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) 
		DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, 	g_szHamHookEntityBlock[i], 		"HamHook_EntityBlock", 	false));
}

public HC_RG_CBasePlayer_PreThink(const pId)
{
	if(IsNotSetBit(g_iBitUserAlive, pId) || IsNotSetBit(g_iBitUserFrozen ,pId)) return HC_CONTINUE;
	

	set_entvar(pId, var_maxspeed, 1.0);
	
	
	return HC_CONTINUE;
}

public CSGameRules_FlPlayerFallDamage(const pPlayer)
{
	if(jbe_is_user_grabber(pPlayer)) 
		return HC_CONTINUE;
		
	if(!jbe_iduel_status() || !jbe_global_status(14) || get_entvar(pPlayer, var_takedamage, DAMAGE_NO))
		return HC_CONTINUE;
		
	new Float:hp = get_entvar(pPlayer, var_health);
	new FallDMG = floatround(Float:GetHookChainReturn(ATYPE_FLOAT), floatround_floor);
	if(FallDMG > hp && FallDMG > 100.0)
	{
		ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 2);
	}
	return HC_CONTINUE;
}

new bool:BufferPushTeleport[MAX_PLAYERS + 1];
//new Float:where[3];

public HamHook_PushTriggers(iEnt, id)
{
	if(!jbe_is_user_valid(id)) return HAM_IGNORED;
	
	if(IsNotSetBit(g_iBitUserAlive, id) ) return HAM_IGNORED;


	if(!BufferPushTeleport[id] && !task_exists(id + TASK_BUFFER_BATUT))
	{
		set_entvar(id, var_velocity, {0.0, 0.0, 0.0});
		set_task_ex(0.3, "returnpush", id + TASK_BUFFER_BATUT);
		BufferPushTeleport[id] = true;
	}
	
	return HAM_IGNORED;
}

public returnpush(id)
{
	id -= TASK_BUFFER_BATUT;

	set_entvar(id, var_velocity, {0.0, 0.0, 0.0});
	CenterMsgFix_PrintMsg(id, print_center, "Серфинг\Батут запрещен! Скорость сброшен!");

	BufferPushTeleport[id] = false;
}

public returnteleport(id)
{
	id -= TASK_BUFFER_TELEPORT;
	CenterMsgFix_PrintMsg(id, print_center, "Телепорт запрещен!");

	BufferPushTeleport[id] = false;
}

public HamHook_TeleportsTriggers(iEnt, id)
{
	if(!jbe_is_user_valid(id)) return HAM_IGNORED;
	
	if(IsNotSetBit(g_iBitUserAlive, id)) return HAM_IGNORED;


	if(!BufferPushTeleport[id] && !task_exists(id + TASK_BUFFER_TELEPORT))
	{
		set_task_ex(1.0, "returnteleport", id + TASK_BUFFER_TELEPORT);
		BufferPushTeleport[id] = true;
	}
	return HAM_SUPERCEDE;
}

#define IsValidEntity(%1) (%1 != 0 && is_entity (%1))
public Ham_TraceAttack_Button(iButton, iAttacker)
{
	if(jbe_is_user_valid(iAttacker))
	{
		if(!is_entity(iButton) || g_iUserTeam[iAttacker] != 2 || iAttacker != g_iChiefId) return HC_CONTINUE;
		
		if((g_iDayMode == 1 || g_iDayMode == 2) )
		{
			ExecuteHamB(Ham_Use, iButton, iAttacker, 0, 2, 1.0);
			set_entvar(iButton, var_frame, 0.0);
		}
	}
	return HC_CONTINUE;
}



public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(is_user_alive(pId))
	{
		if(IsSetBit(g_iUserGhost, pId)) 
		{
			//set_entvar(pId, var_deadflag, DEAD_RESPAWNABLE);
			
			//jbe_set_user_model(pId, g_szPlayerModel[DEAD]);


			jbe_set_user_godmode(pId, 1);
			rg_set_entity_visibility(pId,1);
			
			rg_remove_all_items(pId);
			rg_set_user_footsteps(pId, true);
			
			set_dhudmessage(255, 255, 255, -1.0, 0.67, 0, 6.0, 5.0);
			show_dhudmessage(pId, "Вы призрак...");
			return HC_SUPERCEDE;
		}
		

		if(IsNotSetBit(g_iBitUserAlive, pId))
		{
			SetBit(g_iBitUserAlive, pId);
			g_iAlivePlayersNum[g_iUserTeam[pId]]++;
		}
		
		
		jbe_default_player_model(pId);
		rg_remove_all_items(pId);
		rg_give_item(pId, "weapon_knife");
		
		set_entvar(pId, var_armorvalue, 0.0);
		
		//jbe_spawn_effects(pId);
		//UTIL_ScreenShake(pId, (1<<15), (1<<14), (1<<15));
		
		
	}
	return HC_CONTINUE;
}


public AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(!player || !g_iUserGhost || IsSetBit(g_iBitUserAlive, host))
	{
		return FMRES_IGNORED;
	}
	if(host != ent)
	{
		if(IsNotSetBit(g_iBitUserAlive, host) && IsNotSetBit(g_iUserGhost, host))
		{
			if(IsSetBit(g_iUserGhost, ent))
			{
				set_es(es, ES_Effects, get_es(es, ES_Effects) | 128);
			}
		}
		else 
		if(IsSetBit(g_iUserGhost, host))
		{
			if(IsSetBit(g_iUserGhost, ent))
			{
				set_es(es, ES_RenderFx, kRenderFxDistort);
				set_es(es, ES_RenderColor, {0, 0, 0});
				set_es(es, ES_RenderMode, kRenderTransAdd);
				set_es(es, ES_RenderAmt, 127);
			}
		}
	}
	return FMRES_IGNORED;
}







public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(IsNotSetBit(g_iBitUserAlive, iVictim)) return;
	ClearBit(g_iBitUserAlive, iVictim);
	
	g_iAlivePlayersNum[g_iUserTeam[iVictim]]--;
	switch(g_iDayMode)
	{
		case 1, 2:
		{
			
			new iRet;
			ExecuteForward(g_iForward[FORWARD_ON_KILLED_POST], iRet, iVictim, iKiller);
			//if(jbe_iduel_status() && jbe_is_user_duel(iVictim)) jbe_duel_ended(iVictim);
			
			if(get_entvar(iVictim, var_renderfx) != kRenderFxNone || get_entvar(iVictim, var_rendermode) != kRenderNormal)
			{
				jbe_set_user_rendering(iVictim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[iVictim][RENDER_STATUS] = false;
			}
			if(g_iUserTeam[iVictim] == 1)
			{
				if(g_iViewInformerSkinNum) 
				{
					set_task(1.0, "jbe_get_count_skin", TASK_SHOW_SKIN_COUNT);
					//jbe_get_count_skin();
				}
				//ClearBit(g_iBitUserBoxing, iVictim);

				if(IsSetBit(g_iBitUserWanted, iVictim))
				{
					jbe_sub_user_wanted(iVictim);
				}
				if(IsSetBit(g_iBitUserFree, iVictim)) jbe_sub_user_free(iVictim);
				//ClearBit(g_iBitUserVoice, iVictim);

				
				if(g_iAlivePlayersNum[1] == 1)
				{
					//if(g_bSoccerStatus) jbe_soccer_disable_all();
					//if(g_bBoxingStatus) jbe_boxing_disable_all();
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!is_user_alive(i)) continue;

						if(IsSetBit(g_iUserGhost , i))
						{
							ClearBit(g_iUserGhost, i);
							user_silentkill(i);
						}
					}
					//Duel*
					ExecuteForward(g_iForward[FORWARD_ON_DUELS], iRet);
					//////
				}
				
				
				if(g_iAlivePlayersNum[1] == 0)
				{
					//if(g_iGlobalGame == 2) jbe_djixad_disable();
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsSetBit(g_iUserGhost , i))
						{
							ClearBit(g_iUserGhost, i);
							user_silentkill(i);
						}
					}
				}
			}
			if(g_iUserTeam[iVictim] == 2)
			{
				if(iVictim == g_iChiefId)
				{
					g_iChiefId = 0;
					g_iChiefStatus = 2;
					g_szChiefName = "";
					
					new iRet;
					ExecuteForward(g_iForward[FORWARD_ON_CHIEF_REMOVE], iRet, iVictim, 0);
					//if(g_bSoccerGame) remove_task(iVictim+TASK_SHOW_SOCCER_SCORE);
					if(jbe_is_user_valid(iKiller) && g_iUserTeam[iKiller] == 1) 
					{
						if(g_iPlayersNum[1] >= 5)
						{
							if(g_iUserStats[iKiller][QUEST_4] < g_iQuestCvars[QUEST_KILLCHIEF])
							{
								g_iUserStats[iKiller][QUEST_4]++;
							}
						}
					}
					if(g_iTimer)
					{
						g_iTimer = false;
						remove_task(TASK_SHOW_TIME);
						g_iTimerSecond = 0;
					}
					if(g_iDistanceDrop) g_iDistanceDrop = false;
				}
				
			}


		}
		case 3:
		{
			if(IsSetBit(g_iBitUserVoteDayMode, iVictim))
			{
				ClearBit(g_iBitUserVoteDayMode, iVictim);
				ClearBit(g_iBitUserDayModeVoted, iVictim);
				show_menu(iVictim, 0, "^n");
				jbe_menu_unblock(iVictim);
				rg_reset_maxspeed(iVictim);
				ClearBit(g_iBitUserFrozen, iVictim);
				//UTIL_ScreenFade(iVictim, 512, 512, 0, 0, 0, 0, 255);
			}
			
		}
	}
}


public event_shake(id)
{
	if(IsNotSetBit(g_iBitUserConnected, id)) return 0;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] event_shake");
	}
	
	new duration = UTIL_FixedUnsigned16(4.0, 1 << 12);
	new frequency = UTIL_FixedUnsigned16(0.7 , 1 << 8);
	new amplitude = UTIL_FixedUnsigned16(20.0, 1 << 12);
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0,0,0}, id);
	write_short(amplitude);
	write_short(duration);
	write_short(frequency);
	message_end();
	return 1;
}

public electro_ring(const Float:originF3[3])
{
	//if(IsNotSetBit(g_iBitUserConnected, id)) return 0;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, originF3[0]); 
	engfunc(EngFunc_WriteCoord, originF3[1]); 
	engfunc(EngFunc_WriteCoord, originF3[2]); 
	engfunc(EngFunc_WriteCoord, originF3[0]);
	engfunc(EngFunc_WriteCoord, originF3[1]); 
	engfunc(EngFunc_WriteCoord, originF3[2]+100.0); 
	write_short(SpriteElectro); 
	write_byte(0);
	write_byte(0); 
	write_byte(4); 
	write_byte(60);
	write_byte(0); 
	write_byte(41); 
	write_byte(138); 
	write_byte(255); 
	write_byte(200);
	write_byte(0); 
	message_end();
}


public Ham_KnifePrimaryAttack_Post(iEntity)
{
	//new pId = get_pdata_cbase(iEntity, m_pPlayer, linux_diff_weapon);
	//set_pdata_float(pId, m_flNextAttack, 0.40);
	
	new pId = get_member(iEntity, m_pPlayer);
	set_member(pId, m_flNextAttack, 0.40);
}




public Ham_KnifeSecondaryAttack_Post(iEntity)
{
	//new pId = get_pdata_cbase(iEntity, m_pPlayer, linux_diff_weapon);
	new pId = get_member(iEntity, m_pPlayer);
	/*switch(g_iUserTeam[pId])
	{
		case 1: set_pdata_float(pId, m_flNextAttack, 1.0);
		case 2: set_pdata_float(pId, m_flNextAttack, 1.37);
	}*/
	switch(g_iUserTeam[pId])
	{
		case 1: set_member(pId, m_flNextAttack, 1.0);
		case 2: set_member(pId, m_flNextAttack, 1.37);
	}
}





/*public HC_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}*/

public HC_RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	if(zl_boss_map() || g_bRestartGame) return;

	switch(status)
	{
		case WINSTATUS_TERRORISTS: rg_round_end(tmDelay, .st = WINSTATUS_TERRORISTS, .message = "Заключённым удалось сбежать!");
		case WINSTATUS_CTS: rg_round_end(tmDelay, .st = WINSTATUS_CTS, .message = "Охрана подавила бунт!");
		default: rg_round_end(tmDelay, .st = WINSTATUS_DRAW, .message = "Начало игры");
	}

}









public HamHook_EntityBlock(iEntity, pId)
{
	if(g_bRoundEnd) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}
/*===== <- 'hamsandwich' события <- =====*///}

/*===== -> Режимы игры -> =====*///{
game_mode_init()
{
	g_aDataDayMode = ArrayCreate(DATA_DAY_MODE);
	g_iHookDayModeStart = CreateMultiForward("jbe_day_mode_start", ET_IGNORE, FP_CELL, FP_CELL);
	g_iHookDayModeEnded = CreateMultiForward("jbe_day_mode_ended", ET_IGNORE, FP_CELL, FP_CELL);
	
}

public jbe_day_mode_start(iDayMode, iAdmin)
{
	new aDataDayMode[DATA_DAY_MODE];
	ArrayGetArray(g_aDataDayMode, iDayMode, aDataDayMode);
	formatex(g_szDayMode, charsmax(g_szDayMode), aDataDayMode[LANG_MODE]);
	if(aDataDayMode[MODE_TIMER])
	{
		g_iDayModeTimer = aDataDayMode[MODE_TIMER] + 1;
		set_task_ex(1.0, "jbe_day_mode_timer", TASK_DAY_MODE_TIMER, _, _, SetTask_RepeatTimes, g_iDayModeTimer);
	}
	if(iAdmin)
	{
		//g_iFriendlyFire = 0;
		if(g_iDayMode == 2) jbe_free_day_ended();
		else
		{
			g_iBitUserFree = 0;
			g_szFreeNames = "";

		}
		g_iDayMode = 3;
		if(task_exists(TASK_CHIEF_CHOICE_TIME)) remove_task(TASK_CHIEF_CHOICE_TIME);
		g_iChiefId = 0;
		g_szChiefName = "";
		g_iChiefStatus = 0;
		g_iBitUserWanted = 0;
		g_szWantedNames = "";
		//g_iWantedLang = 0;
		g_iBitUserWanted = 0;
		//g_iBitUserVoice = 0;

		g_iFreeCount = 0;
		szFree = "";
		g_iWantedCount = 0;
		szWanted = "";
		
		g_iBitUserQuestForFree = 0;
		g_iBitUserQuestForWanted = 0;
		
		if(g_iDistanceDrop) g_iDistanceDrop = false;
		
		g_iViewInformerSkinNum = false;
		g_iSkinView = "";

		
		if(g_iTimer)
		{
			g_iTimer = false;
			remove_task(TASK_SHOW_TIME);
			g_iTimerSecond = 0;
		}
		
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if(IsNotSetBit(g_iBitUserAlive, iPlayer)) continue;
			//g_iBitKilledUsers[iPlayer] = 0;
			show_menu(iPlayer, 0, "^n");
			
			if(get_entvar(iPlayer, var_renderfx) != kRenderFxNone || get_entvar(iPlayer, var_rendermode) != kRenderNormal)
			{
				jbe_set_user_rendering(iPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[iPlayer][RENDER_STATUS] = false;
			}
		}
		//if(g_bSoccerStatus) jbe_soccer_disable_all();
		//if(g_bBoxingStatus) jbe_boxing_disable_all();
	}
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) jbe_hide_user_costumes(iPlayer);
	jbe_open_doors();
}

public jbe_day_mode_timer()
{
	if(--g_iDayModeTimer) formatex(g_szDayModeTimer, charsmax(g_szDayModeTimer), "- %s", UTIL_FixTime(g_iDayModeTimer));
	else
	{
		g_szDayModeTimer = "";
		ExecuteForward(g_iHookDayModeEnded, g_iReturnDayMode, g_iVoteDayMode, 0);
		g_iVoteDayMode = -1;
		if(g_iIsBlockedForGame) g_iIsBlockedForGame = false;
		
		DisableHamForward(g_iHamHookTrigger[0]);
		DisableHamForward(g_iHamHookTrigger[1]);
	}
}

public jbe_vote_day_mode_start()
{
	g_iDayModeVoteTime = g_iAllCvars[DAY_MODE_VOTE_TIME] + 1;
	new aDataDayMode[DATA_DAY_MODE];
	for(new i; i < g_iDayModeListSize; i++)
	{
		ArrayGetArray(g_aDataDayMode, i, aDataDayMode);
		if(aDataDayMode[MODE_BLOCKED]) aDataDayMode[MODE_BLOCKED]--;
		aDataDayMode[VOTES_NUM] = 0;
		
		ArraySetArray(g_aDataDayMode, i, aDataDayMode);
	}
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(IsNotSetBit(g_iBitUserAlive, iPlayer)) continue;
		SetBit(g_iBitUserVoteDayMode, iPlayer);
		//g_iBitKilledUsers[iPlayer] = 0;
		g_iMenuPosition[iPlayer] = 0;
		VotediKey[iPlayer] = -1;
		jbe_menu_block(iPlayer);
		//set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_FROZEN);
		SetBit(g_iBitUserFrozen, iPlayer);
		//set_pdata_float(iPlayer, m_flNextAttack, float(g_iDayModeVoteTime), linux_diff_player);
		set_member(iPlayer, m_flNextAttack,float(g_iDayModeVoteTime));
		//UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
	}
	set_task_ex(1.0, "jbe_vote_day_mode_timer", TASK_VOTE_DAY_MODE_TIMER, _, _, SetTask_RepeatTimes, g_iDayModeVoteTime);
}

public jbe_vote_day_mode_timer()
{
	if(!--g_iDayModeVoteTime) jbe_vote_day_mode_ended();
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(IsNotSetBit(g_iBitUserVoteDayMode, iPlayer)) continue;
		Show_DayModeMenu(iPlayer, g_iMenuPosition[iPlayer]);
	}
}

public jbe_vote_day_mode_ended()
{
	g_iBitUserFrozen = 0;
	
	
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(IsNotSetBit(g_iBitUserVoteDayMode, iPlayer)) continue;
		ClearBit(g_iBitUserVoteDayMode, iPlayer);
		ClearBit(g_iBitUserDayModeVoted, iPlayer);
		show_menu(iPlayer, 0, "^n");
		jbe_menu_unblock(iPlayer);
		//set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_FROZEN);
		set_member(iPlayer, m_flNextAttack, 0.0);
		
		rg_reset_maxspeed(iPlayer);
		//UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255);
	}
	
	
	
	new aDataDayMode[DATA_DAY_MODE], iVotesNum;
	for(new iPlayer; iPlayer < g_iDayModeListSize; iPlayer++)
	{
		ArrayGetArray(g_aDataDayMode, iPlayer, aDataDayMode);
		if(aDataDayMode[VOTES_NUM] >= iVotesNum)
		{
			iVotesNum = aDataDayMode[VOTES_NUM];
			g_iVoteDayMode = iPlayer;
		}
	}
	ArrayGetArray(g_aDataDayMode, g_iVoteDayMode, aDataDayMode);
	aDataDayMode[MODE_BLOCKED] = aDataDayMode[MODE_BLOCK_DAYS];
	ArraySetArray(g_aDataDayMode, g_iVoteDayMode, aDataDayMode);
	ExecuteForward(g_iHookDayModeStart, g_iReturnDayMode, g_iVoteDayMode, 0);
	
	EnableHamForward(g_iHamHookTrigger[0]);
	EnableHamForward(g_iHamHookTrigger[1]);
}
/*===== <- Режимы игры <- =====*///}

/*===== -> Остальной хлам -> =====*///{
jbe_create_buyzone()
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	set_entvar(iEntity, var_iuser1, IUSER1_BUYZONE_KEY);
}

native jbe_top_tasked();
native native_hudmessage(str[], len);
new quests_str[512];
#if defined MODE_INFORMER

static CurrentTime[32];


#if defined INFORMER_MAIN


public jbe_main_informer(pId)
{

	pId -= TASK_SHOW_INFORMER;
	
	
	if(jbe_iduel_status() || jbe_get_status_mafia() /*|| is_vote_started()*/) return;


	
	if(g_iViewInformerSkinNum) 
		jbe_get_count_skin();
	
	if(jbe_top_tasked())
	{
		
		native_hudmessage(quests_str, charsmax(quests_str));
	}
	else
	if(strlen(quests_str) > 0)
	{
		quests_str = "";
	}

	get_time("%H:%M:%S", CurrentTime, 31);	
	
	jbe_settings_playerinformer(pId);
	
	/*set_hudmessage(
		red=200, 
		green=100, 
		blue=0, 
		
		Float:x=-1.0, 
		Float:y=0.35, 
		
		effects=0, 
		Float:fxtime=6.0, 
		Float:holdtime=12.0, 
		Float:fadeintime=0.1, 
		Float:fadeouttime=0.2,
		channel=4);
	*/

	
	set_hudmessage(
		g_iUserInformer[pId][INFO_POS_RED], 
		g_iUserInformer[pId][INFO_POS_GREEN], 
		g_iUserInformer[pId][INFO_POS_BLUE], 
		
		g_iUserInformer[pId][INFO_POS_FLOAT_X], 
		g_iUserInformer[pId][INFO_POS_FLOAT_Y], 
		
		0, 
		0.0, 
		1.0, 
		0.2, 
		0.2, 
		-1
	);
	//0, 0.0, 0.8, 0.2, 0.2, 1);
	
	switch(g_iDayMode)
	{
		case 1..2:
		{
			ShowSyncHudMsg(pId, g_iSyncMainInformer, "\
			%s\
			%s\
			%s\
			%s\
			%s\
			%s\
			%s^n\
			%s^n\
			^n%s^n\
			%s^n\
			%s^n\
			^n^n%s", 
			g_iUserInformer[pId][RANK_FORMATEX] ,
			g_iUserInformer[pId][DAYWEEK_FORMATEX],  
			g_iUserInformer[pId][DAYMODE_FORMATEX], 
			g_iUserInformer[pId][CHIEF_FORMATEX], 
			g_iUserInformer[pId][PRISONCOUNT_FORMATEX],
			g_iUserInformer[pId][GUARDCOUNT_FORMATEX],
			g_iUserInformer[pId][TIME_FORMATEX],
			szFree, 
			szWanted,
			g_iUserInformer[pId][TIMEFD_FORMATEX],
			g_iSkinView,
			quests_str
			);
		}
		default:
		{
			ShowSyncHudMsg(pId, g_iSyncMainInformer, "\
			%L, День %d^n\
			%L %s^n\
			Заключенные: %d/%d^n\
			Охранники: %d/%d^n\
			^n^n%s", 
			LANG_PLAYER, g_szDaysWeek[g_iDayWeek], g_iDay,  
			LANG_PLAYER, g_szDayMode, g_szDayModeTimer, 
			g_iAlivePlayersNum[1], g_iPlayersNum[1],
			g_iAlivePlayersNum[2], g_iPlayersNum[2],
			quests_str);
		}
	}
    

}
#else
public jbe_main_informer()
{
	if(jbe_iduel_status() || jbe_get_status_mafia() /*|| is_vote_started()*/) return;

	static sTime[32], CurrentTime[32], gTimerFD[64], gRankName[32];
	
	get_time("%H:%M:%S", CurrentTime, 31);	
	
	if(jbe_top_tasked())
	{
		
		native_hudmessage(quests_str, charsmax(quests_str));
	}
	else
	if(strlen(quests_str) > 0)
	{
		quests_str = "";
	}
	
	static iPlayers[MAX_PLAYERS ], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots);
	for(new i; i < iPlayerCount; i++)
	{
		if(g_iSettingSaveUser[iPlayers[i]][PLAYERS_INFORMER]) continue;
		
		if(!g_iSettingSaveUser[iPlayers[i]][PLAYERS_TIME_INFORMER]) format(sTime, charsmax(sTime), "Время: %s", CurrentTime, 32);
		else format(sTime, charsmax(sTime), "");
		
		
		
		set_hudmessage(255, 255, 0, 0.7, 0.05, 0, 0.0, 1.1, 1.0, 1.0, -1);
		
		if(g_iDayMode != 2 && g_iUserTeam[iPlayers[i]] == 1 && IsSetBit(g_iBitUserFree, iPlayers[i]))
		{
			static Float: fCurTime; fCurTime = get_gametime();
			if(g_iGameTimeFD[iPlayers[i]] >= fCurTime)
			{
				formatex(gTimerFD, charsmax(gTimerFD), "Таймер  вашего ФД - %s" , UTIL_FixTime(floatround(g_iGameTimeFD[iPlayers[i]]) - floatround(fCurTime)));
			}
		}else formatex(gTimerFD, charsmax(gTimerFD), "");
		
		
		switch(g_iDayMode)
		{
			case 1..2:
			{
				ShowSyncHudMsg(iPlayers[i], g_iSyncMainInformer, "%s\
				%L, День %d^n\
				Режим: %L %s^n\
				Начальник: %L%s^n\
				Заключенные: %d/%d^n\
				Охранники: %d/%d^n^n\
				Время: %s^n\
				%s^n\
				^n%s^n\
				%s^n\
				%s^n\
				^n^n%s", 
				Ranks[iPlayers[i]] ,
				LANG_PLAYER, g_szDaysWeek[g_iDayWeek], g_iDay,  
				LANG_PLAYER, g_szDayMode, g_szDayModeTimer, 
				LANG_PLAYER, g_szChiefStatus[g_iChiefStatus], g_szChiefName, 
				g_iAlivePlayersNum[1], g_iPlayersNum[1],
				g_iAlivePlayersNum[2], g_iPlayersNum[2],
				sTime,
				szFree, 
				szWanted,
				gTimerFD,
				g_iSkinView,
				quests_str);
			}
			default:
			{
				ShowSyncHudMsg(iPlayers[i], g_iSyncMainInformer, "\
				%L, День %d^n\
				%L %s^n\
				Заключенные: %d/%d^n\
				Охранники: %d/%d^n\
				^n^n%s", 
				LANG_PLAYER, g_szDaysWeek[g_iDayWeek], g_iDay,  
				LANG_PLAYER, g_szDayMode, g_szDayModeTimer, 
				g_iAlivePlayersNum[1], g_iPlayersNum[1],
				g_iAlivePlayersNum[2], g_iPlayersNum[2],
				quests_str);
			}
		}
    }

}

#endif
#endif

public jbe_fwd_when_set_skin(pId)
{
	if(g_iViewInformerSkinNum) 
		jbe_get_count_skin();
}


public jbe_get_count_skin()
{
	if(task_exists(TASK_SHOW_SKIN_COUNT))
		remove_task(TASK_SHOW_SKIN_COUNT);
	
	iCount[0] = 0, 
	iCount[1] = 0, 
	iCount[2] = 0, 
	iCount[3] = 0;
	iCount[4] = 0, 
	iCount[5] = 0, 
	iCount[6] = 0;

	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsNotSetBit(g_iBitUserAlive, i) || g_iUserTeam[i] != 1 || IsSetBit(g_iBitUserFree,i) || IsSetBit(g_iBitUserWanted,i)) continue;
		
		//if(g_iUserSkin[i] > 3) continue;
		
		iCount[g_iUserSkin[i]]++;
	}
	new g_iSkinViewiLen;
	formatex(g_iSkinView, charsmax(g_iSkinView), "");
	
	g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "^n");
	if(iCount[0]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Белые - %i^n", iCount[0]);
	if(iCount[1]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Синие - %i^n", iCount[1]);
	if(iCount[2]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Фиолетовые - %i^n", iCount[2]);
	if(iCount[3]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Желтые - %i^n", iCount[3]);
	if(iCount[4]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Серые - %i^n", iCount[4]);
	if(iCount[5]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Зеленые - %i^n", iCount[5]);
	if(iCount[6]) g_iSkinViewiLen += formatex(g_iSkinView[g_iSkinViewiLen],charsmax(g_iSkinView) - g_iSkinViewiLen, "Красные - %i^n", iCount[6]);

}


jbe_default_player_model(pPlayer)
{
	switch(g_iUserTeam[pPlayer])
	{
		case 1:
		{
			if(IsNotSetBit(g_iBitUserSkinChange,pPlayer))
			{
				new iRandom = random_num(g_szConfigs[CVARS_SKIN_MIN], g_szConfigs[CVARS_SKIN_MAX]);
				g_iUserSkin[pPlayer] = iRandom;
				SetBit(g_iBitUserSkinChange,pPlayer);
				if(g_iDayMode == 2)
				{
					if(jbe_is_user_flags(pPlayer, FLAGSGIRL)) 
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
						set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
					}
					else
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
						set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD]);
					}
				}
				else
				{
				
					if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
						
					}
					else 
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
					}
					set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
					
					
					#if defined LACOSTE_SKIN
					new szAuth[MAX_AUTHID_LENGTH];
					get_user_authid(pPlayer, szAuth, charsmax(szAuth));
					
					if(equali(szAuth, "STEAM_0:1:439786399"))
					{
						set_entvar(pPlayer, var_skin, 7);
					}
					#endif
				}
				
			}
			else 
			{
				if(g_iDayMode == 2)
				{
					if(jbe_is_user_flags(pPlayer, FLAGSGIRL)) 
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
						set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
					}
					else
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
						set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD]);
					}
					return;
				}
				else
				{
					if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
						
						
					}
					else 
					{
						jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
						set_entvar(pPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
					}
					set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
					
					#if defined LACOSTE_SKIN
					new szAuth[MAX_AUTHID_LENGTH];
					get_user_authid(pPlayer, szAuth, charsmax(szAuth));
					
					if(equali(szAuth, "STEAM_0:1:439786399"))
					{
						set_entvar(pPlayer, var_skin, 7);
					}
					#endif
					
					return;
				}
			}
		}
		case 2: 
		{	
			if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
			{
				jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL_GR]);
				set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_GR_BODY_NUM]);
				
			}
			else
			{
				jbe_set_user_model(pPlayer, g_szPlayerModel[GUARD]);
				set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GUARD_BODY_NUM]);
			}
		}
	}
	if(g_iUserTeam[pPlayer] <= 2)
	{
		new iRet;
		ExecuteForward(g_iForward[FORWARD_ON_SET_PLAYER_MODEL], iRet, pPlayer);
	}
}





/*===== -> Нативы -> =====*///{
public plugin_natives()
{
	register_native("jbe_get_day", "jbe_get_day", 1);
	register_native("jbe_set_day", "jbe_set_day", 1);
	register_native("jbe_get_day_week", "jbe_get_day_week", 1);
	register_native("jbe_set_day_week", "jbe_set_day_week", 1);
	register_native("jbe_get_day_mode", "jbe_get_day_mode", 1);
	register_native("jbe_set_day_mode", "jbe_set_day_mode", 1);
	
	//register_native("jbe_get_user_money", "jbe_get_user_money", 1);
	//register_native("jbe_set_user_money", "jbe_set_user_money", 1);
	register_native("jbe_get_user_team", "jbe_get_user_team", 1);
	register_native("jbe_set_user_team", "jbe_set_user_team", 1);
	register_native("jbe_get_user_model", "_jbe_get_user_model", 1);
	register_native("jbe_set_user_model", "_jbe_set_user_model", 1);
	

	register_native("jbe_menu_block", "jbe_menu_block", 1);
	register_native("jbe_menu_unblock", "jbe_menu_unblock", 1);
	register_native("jbe_menu_blocked", "jbe_menu_blocked", 1);
	register_native("jbe_is_user_free", "jbe_is_user_free", 1);
	register_native("jbe_add_user_free", "jbe_add_user_free", 1);
	register_native("jbe_add_user_free_next_round", "jbe_add_user_free_next_round", 1);
	register_native("jbe_sub_user_free", "jbe_sub_user_free", 1);
	register_native("jbe_free_day_start", "jbe_free_day_start", 1);
	register_native("jbe_free_day_ended", "jbe_free_day_ended", 1);
	register_native("jbe_is_user_wanted", "jbe_is_user_wanted", 1);
	register_native("jbe_add_user_wanted", "jbe_add_user_wanted", 1);
	register_native("jbe_sub_user_wanted", "jbe_sub_user_wanted", 1);
	register_native("jbe_is_user_chief", "jbe_is_user_chief", 1);
	register_native("jbe_set_user_chief", "jbe_set_user_chief", 1);
	register_native("jbe_get_chief_status", "jbe_get_chief_status", 1);
	register_native("jbe_get_chief_id", "jbe_get_chief_id", 1);
	register_native("jbe_prisoners_divide_color", "jbe_prisoners_divide_color", 1);
	register_native("jbe_register_day_mode", "jbe_register_day_mode", 1);
	register_native("jbe_get_user_voice", "jbe_get_user_voice", 1);
	register_native("jbe_set_user_voice", "jbe_set_user_voice", 1);
	register_native("jbe_clear_user_voice", "jbe_clear_user_voice", 1);
	register_native("jbe_set_user_voice_next_round", "jbe_set_user_voice_next_round", 1);
	register_native("jbe_get_user_rendering", "_jbe_get_user_rendering", 1);
	register_native("jbe_set_user_rendering", "jbe_set_user_rendering", 1);
	
	//register_native("jbe_is_user_duel", "jbe_is_user_duel", 1);
	
	register_native("jbe_set_user_noclip", "jbe_set_user_noclip", 1);
	register_native("jbe_is_user_ghost", "jbe_is_user_ghost", 1);
	
	register_native("jbe_is_user_ghost_respawn", "jbe_is_user_ghost_respawn", 1);
	register_native("jbe_is_user_death", "jbe_is_user_death", 1);
	register_native("jbe_is_user_not_alive", "jbe_is_user_not_alive", 1);
	register_native("jbe_get_user_noclip", "jbe_get_user_noclip", 1);
	register_native("jbe_is_user_alive", "jbe_is_user_alive", 1);
	
	register_native("jbe_set_user_godmode", "jbe_set_user_godmode", 1);
	
	
	register_native("jbe_mysql_stats_systems_add", "jbe_mysql_stats_systems_add", 1);
	register_native("jbe_mysql_stats_systems_get", "jbe_mysql_stats_systems_get", 1);

	//return Рестарт игры
	register_native("jbe_restartgame", "jbe_restartgame", 1);

	register_native("jbe_aliveplayersnum", "jbe_aliveplayersnum", 1);
	register_native("jbe_totalplayers", "jbe_totalplayers", 1);
	register_native("jbe_daymodelistsize", "jbe_daymodelistsize", 1);

	register_native("jbe_show_mainmenu", "jbe_show_mainmenu", 1);

	//register_native("jbe_is_user_boxing", "jbe_is_user_boxing", 1);


	

	register_native("jbe_get_stepchief", "jbe_get_stepchief", 1);
	
	//register_native("jbe_is_user_soccer", "jbe_is_user_soccer", 1);
	//register_native("jbe_is_user_boxing", "jbe_is_user_boxing", 1);

	register_native("jbe_all_users_wanted", "jbe_all_users_wanted", 1);
	
	register_native("jbe_set_user_clothingtype", "jbe_set_user_clothingtype", 1);
	
	register_native("jbe_mafia_start", "jbe_mafia_start", 1);
	register_native("jbe_mafia_end", "jbe_mafia_end", 1);
	
	//register_native("jbe_set_friendlyfire", "jbe_set_friendlyfire", 1);
	//register_native("jbe_get_friendlyfire", "jbe_get_friendlyfire", 1);
	
	register_native("jbe_set_global", "jbe_set_global", 1);
	register_native("jbe_is_enable_global", "jbe_is_enable_global" , 1);
	
	register_native("jbe_is_user_voteday", "jbe_is_user_voteday", 1);

	register_native("jbe_set_user_model_ex", "jbe_set_user_model_ex", 1);
	
	register_native("jbe_get_syncinf_1", "jbe_get_syncinf_1", 1);
	//register_native("jbe_off_minigames", "jbe_off_minigames", 1);
	
	register_native("jbe_set_formatex_daymode", "jbe_set_formatex_daymode",1);
	
	//register_native("jbe_status_boxing", "jbe_status_boxing", 1);
	
	register_native("Cmd_VoiceControlMenu", "Cmd_VoiceControlMenu", 1);
	register_native("Cmd_FreeDayControlMenu", "Cmd_FreeDayControlMenu", 1);
	
	register_native("jbe_get_user_skin", "jbe_get_user_skin", 1);
	register_native("jbe_set_user_skin", "jbe_set_user_skin", 1);
	
	register_native("jbe_playersnum", "jbe_playersnum" , 1);
	register_native("jbe_totalalievplayers", "jbe_totalalievplayers" , 1);
	
	
	register_native("jbe_get_blocked_games_ct", "jbe_get_blocked_games_ct", 1);
	register_native("jbe_set_blocked_games_ct", "jbe_set_blocked_games_ct", 1);

	register_native("jbe_show_chiefmenu", "jbe_show_chiefmenu", 1);
	register_native("jbe_is_user_connected", "jbe_is_user_connected", 1);
	register_native("jbe_set_informer_pos", "jbe_set_informer_pos", 1);
	register_native("jbe_get_informer_pos", "jbe_get_informer_pos", 1);
	register_native("jbe_set_informer_color", "jbe_set_informer_color", 1);
	register_native("jbe_get_informer_color", "jbe_get_informer_color", 1);
	
	register_native("jbe_get_round_end", "jbe_get_round_end", 1);
	register_native("jbe_reset_informer_pos", "jbe_reset_informer_pos", 1);
	
	register_native("jbe_set_user_nonspeed", "jbe_set_user_nonspeed", 1);
	register_native("jbe_clear_user_nonspeed", "jbe_clear_user_nonspeed", 1);
	register_native("jbe_is_user_nonspeed", "jbe_is_user_nonspeed", 1);
	register_native("jbe_reset_nonspeed", "jbe_reset_nonspeed", 1);
	
	register_native("jbe_core_settingmenu", "jbe_core_settingmenu", 1);
	
	register_native("jbe_set_savesettings", "jbe_set_savesettings", 1);
	register_native("jbe_get_savesettings", "jbe_get_savesettings", 1);
	
	register_native("jbe_open_main_menu", "jbe_open_main_menu", 1);
	load_license();
	//register_native("jbe_get_check_license", "jbe_get_check_license");
}

public jbe_open_main_menu(pId, iMenu)
{
	switch(iMenu)
	{
		case 0: 
		{
			switch(g_iUserTeam[pId])
			{
				case 1: return Show_MainPnMenu(pId);
				case 2: return Show_MainGrMenu(pId);
			}
		}
		case 1:
		{
			if(pId == g_iChiefId)
			{
				return Show_ChiefMenu_1(pId);
			}
		
		}
		case 2:
		{
			if(pId == g_iChiefId)
			{
				return Show_MiniGameMenu(pId);
			}
		
		}
		case 3:
		{
			if(pId == g_iChiefId)
			{
				return Show_PageMiniGameMenu(pId);
			}
		
		}
	
	}
	return 0;
}
public jbe_set_savesettings(pId, iType, iNum)
{
	switch(iType)
	{
		case 0: g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS] = iNum;
		case 1: g_iSettingSaveUser[pId][PLAYERS_WEAPONS_MAIN] = iNum;
		case 2: g_iSettingSaveUser[pId][PLAYERS_WEAPONS_SECOND] = iNum;
	}
}

public jbe_get_savesettings(pId, iType)
{
	switch(iType)
	{
		case 0: return g_iSettingSaveUser[pId][PLAYERS_SAVE_WEAPONS];
		case 1: return g_iSettingSaveUser[pId][PLAYERS_WEAPONS_MAIN];
		case 2: return g_iSettingSaveUser[pId][PLAYERS_WEAPONS_SECOND];
	}
	return PLUGIN_HANDLED;
}

public jbe_core_settingmenu(pId) return Show_PlayerSettingsMenu(pId);
public jbe_set_user_nonspeed(pId) SetBit(g_iBitUserFrozen, pId);
public jbe_clear_user_nonspeed(pId) 
{
	ClearBit(g_iBitUserFrozen, pId);
	rg_reset_maxspeed(pId);
}
public jbe_is_user_nonspeed(pId) return IsSetBit(g_iBitUserFrozen, pId);
public jbe_reset_nonspeed() g_iBitUserFrozen = 0;


public jbe_get_round_end() return g_bRoundEnd;

public jbe_set_informer_pos(pId, iType, Float:iNum)
{
	switch(iType)
	{
		case 1: g_iUserInformer[pId][INFO_POS_FLOAT_X] = iNum; 
		case 2: g_iUserInformer[pId][INFO_POS_FLOAT_Y] = iNum; 
	}
}

public Float:jbe_get_informer_pos(pId, iType)
{
	switch(iType)
	{
		case 1: return g_iUserInformer[pId][INFO_POS_FLOAT_X]; 
		case 2: return g_iUserInformer[pId][INFO_POS_FLOAT_Y]; 
	}
	return 0.0;
}

public jbe_set_informer_color(pId, iType, iNum)
{
	switch(iType)
	{
		case 1: g_iUserInformer[pId][INFO_POS_RED] = iNum; 
		case 2: g_iUserInformer[pId][INFO_POS_GREEN] = iNum; 
		case 3: g_iUserInformer[pId][INFO_POS_BLUE] = iNum; 
	}
}

public jbe_get_informer_color(pId, iType)
{
	switch(iType)
	{
		case 1: return g_iUserInformer[pId][INFO_POS_RED]; 
		case 2: return g_iUserInformer[pId][INFO_POS_GREEN]; 
		case 3: return g_iUserInformer[pId][INFO_POS_BLUE]; 
	}
	return false;
}

public jbe_reset_informer_pos(pId)
{
	g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.70;
	g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.05;
	
	g_iUserInformer[pId][INFO_POS_RED] = 255;
	g_iUserInformer[pId][INFO_POS_GREEN] = 255;
	g_iUserInformer[pId][INFO_POS_BLUE] = 0;
}
stock load_license()
{
	get_user_ip(0, GetNetAddress, charsmax(GetNetAddress), 0);
}

//public jbe_get_check_license(plugin_id[]) set_string(1, GetNetAddress, charsmax(GetNetAddress));

public jbe_is_user_connected(pId) return IsSetBit(g_iBitUserConnected, pId);
public jbe_show_chiefmenu(pId)
{
	if(pId == g_iChiefId) return Show_ChiefMenu_1(pId);
	return 0;
}

public jbe_countdown_num(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) >= 8)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:9999999!y]");
		return Show_MenuTimer(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_MenuTimer(id);
	}
	if(str_to_num( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение равно !g0!");
		return Show_MenuTimer(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_MenuTimer(id);
		}
	}
	g_iCountDown = str_to_num( Args1 ) + 1;
	jbe_count_down_timer();
	set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
	//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	return Show_MenuTimer(id);
}
public jbe_set_blocked_games_ct(bool:status) g_iIsBlockedForGame = status;
public jbe_get_blocked_games_ct() return g_iIsBlockedForGame;

public jbe_set_user_skin(pId, iNum) 
{
	g_iUserSkin[pId] = iNum;
	
}
public jbe_get_user_skin(pId) return g_iUserSkin[pId];
//public jbe_status_boxing() return g_bBoxingStatus;
/*public jbe_off_minigames()
{
	//jbe_soccer_disable_all();
	//jbe_boxing_disable_all();

}*/

public jbe_get_syncinf_1() return g_iSyncMainInformer;




public jbe_set_user_model_ex(pId, iType)
{
	switch(iType)
	{
		case 1:
		{
			if(jbe_is_user_flags(pId, FLAGSGIRL))
			{
				jbe_set_user_model(pId, g_szPlayerModel[GIRL]);
				set_entvar(pId, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
			}
			else 
			{
				jbe_set_user_model(pId, g_szPlayerModel[PRISONER]);
				set_entvar(pId, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
			}
			if(IsSetBit(g_iBitUserFree, pId)) 
			{
				if(jbe_is_user_flags(pId, FLAGSGIRL)) 
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
				}
				else
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_FD]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_FD]);
				}
			}
			else if(IsSetBit(g_iBitUserWanted, pId)) 
			{
				if(jbe_is_user_flags(pId, FLAGSGIRL)) 
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_WANTED_GIRLS]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_WANTED_GIRLS]);
				}
				else
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_WANTED]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_WANTED]);
				}
			}
			else 
			{
				if(g_iDayMode == 3)
				{
					set_entvar(pId, var_skin, random_num(0, 3));
				}else set_entvar(pId, var_skin, g_iUserSkin[pId]);
			}
		}
		case 2:
		{
			if(jbe_is_user_flags(pId, FLAGSGIRL))
			{
				jbe_set_user_model(pId, g_szPlayerModel[GIRL_GR]);
				set_entvar(pId, var_body, g_szPlayerBodyModels[GIRL_GR_BODY_NUM]);
				
			}
			else
			{
				if(pId == g_iChiefId)
				{
					jbe_set_user_model(pId, g_szPlayerModel[CHIEF]);
					set_entvar(pId, var_body, g_szPlayerBodyModels[CHIEF_BODY_NUM]);
				}
				else
				{
					jbe_set_user_model(pId, g_szPlayerModel[GUARD]);
					set_entvar(pId, var_body, g_szPlayerBodyModels[GUARD_BODY_NUM]);
				}
			}
		}
	}

}

public jbe_is_user_voteday(pId) return IsSetBit(g_iBitUserVoteDayMode, pId);

public jbe_mafia_start()
{
	g_iMafiaStatus = true;
	if(g_iMafiaStatus)
	{

	}
}

public jbe_mafia_end()
{
	g_iMafiaStatus = false;
}


public jbe_set_global(iType)
{
    switch (iType)
    {
        case 0:
        {
            g_iGlobalGame = 0;
        }
        case 1:
        {
            g_iGlobalGame = 1;
        }
        case 2:
        {
            g_iGlobalGame = 2;
        }
        case 3:
        {
            g_iGlobalGame = 3;
        }
        case 4:
        {
            g_iGlobalGame = 4;
        }
    }

}

public jbe_is_enable_global()
{
	if(g_iGlobalGame) return true;
	return false;
}

//public jbe_set_friendlyfire(iType) g_iFriendlyFire = iType;
//public jbe_get_friendlyfire() return g_iFriendlyFire;

public jbe_set_user_clothingtype(pId, iType)
{
	switch(iType)
	{
		case 1: 
		{
			if(jbe_is_user_flags(pId, FLAGSGIRL))
			{
				jbe_set_user_model(pId, g_szPlayerModel[GIRL]);
				set_entvar(pId, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
			}
			else 
			{
				jbe_set_user_model(pId, g_szPlayerModel[PRISONER]);
				set_entvar(pId, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
			}
			if(IsSetBit(g_iBitUserFree, pId)) 
			{
				if(jbe_is_user_flags(pId, FLAGSGIRL)) 
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
				}
				else
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_FD]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_FD]);
				}
			}
			else if(IsSetBit(g_iBitUserWanted, pId)) 
			{
				if(jbe_is_user_flags(pId, FLAGSGIRL)) 
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_WANTED_GIRLS]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_WANTED_GIRLS]);
				}
				else
				{
					set_entvar(pId, var_skin, g_szConfigs[CVARS_SKIN_WANTED]);
					//jbe_set_user_skin(pId, g_szConfigs[CVARS_SKIN_WANTED]);
				}
			}
			else 
			{
				set_entvar(pId, var_skin, g_iUserSkin[pId]);
			}
		}
		case 2:
		{
			jbe_set_user_model(pId, g_szPlayerModel[GUARD]);
			set_entvar(pId, var_body, g_szPlayerBodyModels[GUARD_BODY_NUM]);
		}
	}
}

public jbe_all_users_wanted()
{
	if(g_szWantedNames[0] <= 0) return false;
	return true;
}

//public jbe_is_user_soccer(pId) return IsSetBit(g_iBitUserSoccer, pId);

public jbe_get_stepchief() return g_iChiefStep;



//public jbe_is_user_boxing(pId) return IsSetBit(g_iBitUserBoxing, pId);
public jbe_is_user_alive(pId) return IsSetBit(g_iBitUserAlive, pId);
public jbe_show_mainmenu(pId)
{
	switch(g_iUserTeam[pId])
	{
		case 1: return Show_MainPnMenu(pId);
		case 2: return Show_MainGrMenu(pId);
	}
	return 0;
}
public jbe_daymodelistsize() return g_iDayModeListSize;
public jbe_aliveplayersnum(iType) return g_iAlivePlayersNum[iType];
public jbe_playersnum(iType)return g_iPlayersNum[iType];
public jbe_totalplayers() 
{
	new Temp = (g_iPlayersNum[1] + g_iPlayersNum[2]);
	return Temp;
}
public jbe_totalalievplayers() 
{
	return g_iAlivePlayersNum[1] + g_iAlivePlayersNum[2];
}

public jbe_restartgame() return g_bRestartGame;


public jbe_mysql_stats_systems_get(id, iType)
{
	#if defined CHECKING_MYSQL_GET
	server_print("ME CALL | %d", iType);
	#endif
	switch(iType)
	{
		case 1: return g_iUserStats[id][STATS_1];
		case 2: return g_iUserStats[id][STATS_2];
		case 3: return g_iUserStats[id][STATS_3];
		case 4: return g_iUserStats[id][STATS_4];
		case 5: return g_iUserStats[id][STATS_5];
		case 6: return g_iUserStats[id][STATS_6];
		case 7: return g_iUserStats[id][STATS_7];
		case 8: return g_iUserStats[id][STATS_8];
		case 9: return g_iUserStats[id][STATS_9];
		case 10: return g_iUserStats[id][STATS_10];
		case 11: return g_iUserStats[id][STATS_11];
		case 12: return g_iUserStats[id][STATS_12];
		case 13: return g_iUserStats[id][STATS_13];
		case 14: return g_iUserStats[id][STATS_14];
		case 15: return g_iUserStats[id][STATS_15];
		case 16: return g_iUserStats[id][STATS_16];
		case 17: return g_iUserStats[id][STATS_17];
		case 18: return g_iUserStats[id][STATS_18];
		case 19: return g_iUserStats[id][STATS_19];
		case 20: return g_iUserStats[id][STATS_20];
		case 21: return g_iUserStats[id][STATS_21];
		case 22: return g_iUserStats[id][STATS_22];
		case 23: return g_iUserStats[id][STATS_23];
		case 24: return g_iUserStats[id][STATS_24];
		case 25: return g_iUserStats[id][STATS_25];
		case 26: return g_iUserStats[id][STATS_26];
		case 27: return g_iUserStats[id][STATS_27];
		case 28: return g_iUserStats[id][STATS_28];
		case 29: return g_iUserStats[id][STATS_29];
		case 30: return g_iUserStats[id][STATS_30];
		case 31: return g_iUserStats[id][STATS_31];
		case 32: return g_iUserStats[id][STATS_32];
		case 33: return g_iUserStats[id][STATS_33];
		case 34: return g_iUserStats[id][STATS_34];
		case 35: return g_iUserStats[id][STATS_35];
		case 36: return g_iUserStats[id][STATS_36];
		case 37: return g_iUserStats[id][STATS_37];
		case 38: return g_iUserStats[id][STATS_38];
		case 39: return g_iUserStats[id][STATS_39];
		case 40: {}
		case 41: {}
		case 42: {}
		case 43: {}
		case 44: {}
		case 45: return g_iUserInformer[id][INFORMER_RANK];
		case 46: return g_iUserInformer[id][INFORMER_DAYWEEK];
		case 47: return g_iUserInformer[id][INFORMER_DAYMODE];
		case 48: return g_iUserInformer[id][INFORMER_CHIEF];
		case 49: return g_iUserInformer[id][INFORMER_PRISONCOUNT];
		case 50: return g_iUserInformer[id][INFORMER_GUARDCOUNT];
		case 51: return g_iUserInformer[id][INFORMER_TIME];
		case 52: return g_iUserInformer[id][PREFIX_RANK];
		case 53: return g_iUserInformer[id][PREFIX_INDIVID];
		case 54: return g_iUserInformer[id][PREFIX_CLUB];
		case 55: return g_iUserStats[id][STATS_55];
		case 56: return g_iUserStats[id][STATS_56];
		case 57: return g_iUserStats[id][STATS_57];
		case 58: return g_iUserStats[id][STATS_58];
		case 59: return g_iUserStats[id][STATS_59];
		case 60: return g_iUserStats[id][STATS_60];
		case 61: return g_iUserStats[id][STATS_61];
		case 62: return g_iUserStats[id][STATS_62];
		case 63: return g_iUserStats[id][STATS_63];
		case 64: return g_iUserStats[id][STATS_64];
		case 65: return g_iUserStats[id][STATS_65];
		case 66: return g_iUserStats[id][STATS_66];
		case 67: return g_iUserStats[id][STATS_67];
		case 68: return g_iUserStats[id][STATS_68];
		case 69: return g_iUserStats[id][STATS_69];
		case 70: return g_iUserStats[id][STATS_70];
		case 71: return g_iUserStats[id][QUEST_1];
		case 72: return g_iUserStats[id][QUEST_2];
		case 73: return g_iUserStats[id][QUEST_3];
		case 74: return g_iUserStats[id][QUEST_4];	
		case 75: return g_iUserStats[id][QUEST_5];
		case 76: return g_iUserStats[id][QUEST_6];	
		case 77: return g_iUserStats[id][QUEST_7];
		case 78: return g_iUserStats[id][QUEST_8];
		case 79: return g_iUserStats[id][QUEST_9];		
		case 80: return g_iUserStats[id][QUEST_10];
		case 81: return g_iUserStats[id][QUEST_11];	
		case 82: return g_iUserStats[id][QUEST_12];	
		case 83: return g_iUserStats[id][QUEST_13];	
		case 84: return g_iUserStats[id][QUEST_14];	
		case 85: return g_iUserStats[id][QUEST_15];
		case 86: return g_iUserStats[id][EXP_T];
		case 87: return g_iUserStats[id][EXP_CT];
		default: 
		{
			new iError[512];
			formatex(iError, charsmax(iError), "jbe_mysql_stats_systems_get(index, %d) | Ошибка обращение к ячейке: %d | Максимально ячейк: 87", iType, iType);
			log_amx("%s", iError);
			return PLUGIN_HANDLED;
		}

	}
	return PLUGIN_HANDLED;
}


public jbe_mysql_stats_systems_add(id, iType, iNum) 
{ 
	switch(iType) 
	{ 
		case 1: g_iUserStats[id][STATS_1]		=iNum; 
		case 2: g_iUserStats[id][STATS_2]		=iNum; 
		case 3: g_iUserStats[id][STATS_3]		=iNum; 
		case 4: g_iUserStats[id][STATS_4]		=iNum; 
		case 5: g_iUserStats[id][STATS_5]		=iNum; 
		case 6: g_iUserStats[id][STATS_6]		=iNum; 
		case 7: g_iUserStats[id][STATS_7]		=iNum; 
		case 8: g_iUserStats[id][STATS_8]		=iNum; 
		case 9: g_iUserStats[id][STATS_9]		=iNum; 
		case 10: g_iUserStats[id][STATS_10]		=iNum; 
		case 11: g_iUserStats[id][STATS_11] 	=iNum;  
		case 12: g_iUserStats[id][STATS_12]		=iNum; 
		case 13: g_iUserStats[id][STATS_13]		=iNum; 
		case 14: g_iUserStats[id][STATS_14]		=iNum; 
		case 15: g_iUserStats[id][STATS_15]		=iNum; 
		case 16: g_iUserStats[id][STATS_16]		=iNum; 
		case 17: g_iUserStats[id][STATS_17]		=iNum; 
		case 18: g_iUserStats[id][STATS_18]		=iNum; 
		case 19: g_iUserStats[id][STATS_19]		=iNum; 
		case 20: g_iUserStats[id][STATS_20]		=iNum; 
		case 21: g_iUserStats[id][STATS_21]		=iNum; 
		case 22: g_iUserStats[id][STATS_22]		=iNum; 
		case 23: g_iUserStats[id][STATS_23]		=iNum; 
		case 24: g_iUserStats[id][STATS_24]		=iNum; 
		case 25: g_iUserStats[id][STATS_25]		=iNum; 
		case 26: g_iUserStats[id][STATS_26] 	=iNum;  
		case 27: g_iUserStats[id][STATS_27]		=iNum; 
		case 28: g_iUserStats[id][STATS_28]		=iNum; 
		case 29: g_iUserStats[id][STATS_29]		=iNum; 
		case 30: g_iUserStats[id][STATS_30]		=iNum; 
		case 31: g_iUserStats[id][STATS_31]		=iNum; 
		case 32: g_iUserStats[id][STATS_32]		=iNum; 
		case 33: g_iUserStats[id][STATS_33]		=iNum; 
		case 34: g_iUserStats[id][STATS_34]		=iNum; 
		case 35: g_iUserStats[id][STATS_35]		=iNum; 
		case 36: g_iUserStats[id][STATS_36] 	=iNum;  
		case 37: g_iUserStats[id][STATS_37]		=iNum; 
		case 38: g_iUserStats[id][STATS_38]		=iNum; 
		case 39: g_iUserStats[id][STATS_39]		=iNum; 
		case 40: {}
		case 41: {}
		case 42: {}
		case 43: {}
		case 44: {}
		case 45: g_iUserInformer[id][INFORMER_RANK]		=iNum; 
		case 46: g_iUserInformer[id][INFORMER_DAYWEEK]		=iNum; 
		case 47: g_iUserInformer[id][INFORMER_DAYMODE]		=iNum; 
		case 48: g_iUserInformer[id][INFORMER_CHIEF]		=iNum; 
		case 49: g_iUserInformer[id][INFORMER_PRISONCOUNT]		=iNum; 
		case 50: g_iUserInformer[id][INFORMER_GUARDCOUNT]		=iNum; 
		case 51: g_iUserInformer[id][INFORMER_TIME]		=iNum; 
		case 52: g_iUserInformer[id][PREFIX_RANK]		=iNum; 
		case 53: g_iUserInformer[id][PREFIX_INDIVID]		=iNum; 
		case 54: g_iUserInformer[id][PREFIX_CLUB]		=iNum; 
		case 55: g_iUserStats[id][STATS_55]		=iNum; 
		case 56: g_iUserStats[id][STATS_56]		=iNum; 
		case 57: g_iUserStats[id][STATS_57]		=iNum; 
		case 58: g_iUserStats[id][STATS_58]		=iNum; 
		case 59: g_iUserStats[id][STATS_59]		=iNum; 
		case 60: g_iUserStats[id][STATS_60]		=iNum; 
		case 61: g_iUserStats[id][STATS_61]		=iNum; 
		case 62: g_iUserStats[id][STATS_62]		=iNum; 
		case 63: g_iUserStats[id][STATS_63]		=iNum; 
		case 64: g_iUserStats[id][STATS_64]		=iNum; 
		case 65: g_iUserStats[id][STATS_65]		=iNum; 
		case 66: g_iUserStats[id][STATS_66] 	=iNum;  
		case 67: g_iUserStats[id][STATS_67]		=iNum; 
		case 68: g_iUserStats[id][STATS_68]		=iNum; 
		case 69: g_iUserStats[id][STATS_69]		=iNum; 
		case 70: g_iUserStats[id][STATS_70]		=iNum; 
		case 71: g_iUserStats[id][QUEST_1]		=iNum; 
		case 72: g_iUserStats[id][QUEST_2]		=iNum; 
		case 73: g_iUserStats[id][QUEST_3]		=iNum; 
		case 74: g_iUserStats[id][QUEST_4]		=iNum; 
		case 75: g_iUserStats[id][QUEST_5]		=iNum; 
		case 76: g_iUserStats[id][QUEST_6]		=iNum; 
		case 77: g_iUserStats[id][QUEST_7]		=iNum; 
		case 78: g_iUserStats[id][QUEST_8]		=iNum; 
		case 79: g_iUserStats[id][QUEST_9]		=iNum; 
		case 80: g_iUserStats[id][QUEST_10]		=iNum; 
		case 81: g_iUserStats[id][QUEST_11] 	=iNum;  
		case 82: g_iUserStats[id][QUEST_12]		=iNum; 
		case 83: g_iUserStats[id][QUEST_13]		=iNum; 
		case 84: g_iUserStats[id][QUEST_14]		=iNum; 
		case 85: g_iUserStats[id][QUEST_15]		=iNum; 
		case 86: g_iUserStats[id][EXP_T]		=iNum; 
		case 87: g_iUserStats[id][EXP_CT]		=iNum; 
		default: 
		{
			new iError[512];
			formatex(iError, charsmax(iError), "jbe_mysql_stats_systems_add(index, %d, iValue) | Ошибка обращение к ячейке: %d | Максимально ячейк: 87", iType, iType);
			log_amx("%s", iError);
		}
	} 
}

public jbe_is_user_ghost(pId) return IsSetBit(g_iUserGhost, pId);


public jbe_is_user_not_alive(pId) return IsNotSetBit(g_iBitUserAlive, pId);
public jbe_is_user_death(pId) return IsNotSetBit(g_iUserGhost, pId);


public jbe_is_user_ghost_respawn(pId) 
{
	if(IsSetBit(g_iUserGhost, pId))
	{
		ClearBit(g_iUserGhost, pId);
		user_silentkill(pId);
	}
}

public jbe_set_user_noclip(pId, bType) set_entvar( pId, var_movetype, !bType ? MOVETYPE_WALK : MOVETYPE_NOCLIP );
public bool:jbe_get_user_noclip(pId) return ( get_entvar(pId, var_movetype) == MOVETYPE_NOCLIP );

public jbe_set_user_godmode(pId, bType) set_entvar( pId, var_takedamage, !bType ? DAMAGE_YES : DAMAGE_NO );
public bool: jbe_get_user_godmode(pId) return bool:( get_entvar(pId, var_takedamage) == DAMAGE_NO );


//public jbe_is_user_duel(pId) return jbe_is_user_duel(pId);
public jbe_get_day() return g_iDay;
public jbe_set_day(iDay) g_iDay = iDay;

public jbe_get_day_week() return g_iDayWeek;
public jbe_set_day_week(iWeek) g_iDayWeek = (g_iDayWeek > 7) ? 1 : iWeek;

public jbe_get_day_mode() return g_iDayMode;



public jbe_set_day_mode(iMode)
{
	g_iDayMode = iMode;
	formatex(g_szDayMode, charsmax(g_szDayMode), "JBE_HUD_GAME_MODE_%d", g_iDayMode);
}

public jbe_set_formatex_daymode(iDay)
{
	formatex(g_szDayMode, charsmax(g_szDayMode), "JBE_HUD_GAME_MODE_%d", iDay);
}





public jbe_get_user_team(pPlayer) return g_iUserTeam[pPlayer];
public jbe_set_user_team(pPlayer, iTeam)
{
	if(IsNotSetBit(g_iBitUserConnected, pPlayer)) return 0;
	
	if(is_user_hltv(pPlayer)) return 0;

	switch(iTeam)
	{
		case 1:
		{
			if(!zl_boss_map())
			{
				set_pdata_int(pPlayer, m_bHasChangeTeamThisRound, false, linux_diff_player);
				set_pdata_int(pPlayer, m_iSpawnCount, 1);
				if(IsSetBit(g_iBitUserAlive, pPlayer)) 
				{
					ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
					//user_kill(pPlayer);
				}
				
			}
			engclient_cmd(pPlayer, "jointeam", "1");
			
			if(!zl_boss_map()) if(get_pdata_int(pPlayer, m_iPlayerTeam, linux_diff_player) != 1) return 0;
			
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			g_iUserTeam[pPlayer] = 1;
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
			engclient_cmd(pPlayer, "joinclass", "1");
			
			new iRet;
			ExecuteForward(g_iForward[FORWARD_ON_SET_USER_TEAM], iRet, pPlayer);
			
			if(get_login(pPlayer)) formatex(Ranks[pPlayer], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankName[jbe_get_user_ranks(pPlayer)] ,jbe_mysql_get_exp( pPlayer,1),jbe_get_user_exp_next(pPlayer));
			else Ranks[pPlayer] = "";
		}
		case 2:
		{
			if(!zl_boss_map())
			{
				set_pdata_int(pPlayer, m_bHasChangeTeamThisRound, false, linux_diff_player);
				set_pdata_int(pPlayer, m_iSpawnCount, 1);
				if(IsSetBit(g_iBitUserAlive, pPlayer)) 
				{
					ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
					//user_kill(pPlayer);
				}
				
			}
			engclient_cmd(pPlayer, "jointeam", "2");
			if(!zl_boss_map()) if(get_pdata_int(pPlayer, m_iPlayerTeam, linux_diff_player) != 2) return 0;
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			g_iUserTeam[pPlayer] = 2;
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
			engclient_cmd(pPlayer, "joinclass", "1");
			
			new iRet;
			ExecuteForward(g_iForward[FORWARD_ON_SET_USER_TEAM], iRet, pPlayer);
			
			if(get_login(pPlayer)) formatex(Ranks[pPlayer], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankNameCT[jbe_get_user_ranks(pPlayer)] ,jbe_mysql_get_exp( pPlayer,2),jbe_get_user_exp_next(pPlayer));
			else Ranks[pPlayer] = "";
			
		}
		case 3:
		{
			if(!zl_boss_map()) 
			{
				if(IsSetBit(g_iBitUserAlive, pPlayer)) ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
			}
			engclient_cmd(pPlayer, "jointeam", "6");
			if(!zl_boss_map()) if(get_pdata_int(pPlayer, m_iPlayerTeam, linux_diff_player) != 3) return 0;
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			g_iUserTeam[pPlayer] = 3;
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
		}
	}
	return iTeam;
}

public _jbe_get_user_model(pPlayer, const szModel[], iLen)
{
	param_convert(2);
	return jbe_get_user_model(pPlayer, szModel, iLen);
}
public jbe_get_user_model(pPlayer, const szModel[], iLen) 
{
	//return get_entvar(pPlayer, var_model, szModel, iLen);
	return engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, pPlayer), "model", szModel, iLen);
}
public _jbe_set_user_model(pPlayer, const szModel[])
{
	param_convert(2);
	jbe_set_user_model(pPlayer, szModel);
}
public jbe_set_user_model(pPlayer, const szModel[])
{
	copy(g_szUserModel[pPlayer], charsmax(g_szUserModel[]), szModel);
	
	if(!strlen(g_szUserModel[pPlayer]))
		return;
	
	static Float:fGameTime, Float:fChangeTime; fGameTime = get_gametime();
	if(fGameTime - fChangeTime > 0.1)
	{
		jbe_set_user_model_fix(pPlayer+TASK_CHANGE_MODEL);
		fChangeTime = fGameTime;
	}
	else
	{
		set_task_ex((fChangeTime + 0.1) - fGameTime, "jbe_set_user_model_fix", pPlayer+TASK_CHANGE_MODEL);
		fChangeTime = fChangeTime + 0.1;
	}
}
public jbe_set_user_model_fix(pPlayer)
{
	pPlayer -= TASK_CHANGE_MODEL;
	engfunc(EngFunc_SetClientKeyValue, pPlayer, engfunc(EngFunc_GetInfoKeyBuffer, pPlayer), "model", g_szUserModel[pPlayer]);
	
	new szBuffer[64]; 
	formatex(szBuffer, charsmax(szBuffer), "models/player/%s/%s.mdl", g_szUserModel[pPlayer], g_szUserModel[pPlayer]);
	//set_pdata_int(pPlayer, g_szModelIndexPlayer, engfunc(EngFunc_ModelIndex, szBuffer), linux_diff_player);
	
	rg_set_user_model(pPlayer, g_szUserModel[pPlayer], true);
	
	SetBit(g_iBitUserModel, pPlayer);
	
	/*new SZModelReAPI[64], SZModelFM[64], SZModelCStrike[64];

	get_entvar(pPlayer, var_model, SZModelReAPI, charsmax(SZModelReAPI));
	pev(pPlayer, pev_model, SZModelFM, charsmax(SZModelFM));
	cs_get_user_model(pPlayer, SZModelCStrike, charsmax(SZModelCStrike));

	server_print("Current Model | ReAPI: %s", SZModelReAPI);
	server_print("Current Model | FakeMeta: %s", SZModelFM);
	server_print("Current Model | CStrike: %s", SZModelCStrike);*/
}



public jbe_menu_block(pPlayer) SetBit(g_iBitBlockMenu, pPlayer);
public jbe_menu_unblock(pPlayer) ClearBit(g_iBitBlockMenu, pPlayer);
public jbe_menu_blocked(pPlayer) return IsSetBit(g_iBitBlockMenu, pPlayer);

public jbe_is_user_free(pPlayer) return IsSetBit(g_iBitUserFree, pPlayer);
public jbe_add_user_free(pPlayer)
{
	if(g_iDayMode != 1 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)
	|| IsSetBit(g_iBitUserFree, pPlayer) || IsSetBit(g_iBitUserWanted, pPlayer)) return 0;
	SetBit(g_iBitUserFree, pPlayer);
	formatex(g_szFreeNames, charsmax(g_szFreeNames), "%s^n%n", g_szFreeNames, pPlayer);

	g_iFreeCount++;
	
	
	
	if(g_iFreeCount > 0)
	{
		formatex(szFree, charsmax(szFree), "На отдыхе %d зек(ов)" , g_iFreeCount);
	}else szFree = "";

	
	if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
	{

		jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
		
		set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
		//jbe_set_user_skin(pPlayer, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
	}
	else 
	{
	
		jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
		set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD]);
		//jbe_set_user_skin(pPlayer, g_szConfigs[CVARS_SKIN_FD]);
	}
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_ADD_USER_FREE], iRet, pPlayer);
	
	g_iGameTimeFD[pPlayer] = get_gametime() + g_iAllCvars[FREE_DAY_ID];
	set_task_ex(float(g_iAllCvars[FREE_DAY_ID]), "jbe_sub_user_free_ex", pPlayer+TASK_FREE_DAY_ENDED);
	if(get_login(pPlayer) && g_iPlayersNum[1] >= 5)
	{
		if(g_iUserStats[pPlayer][QUEST_3] < g_iQuestCvars[QUEST_FREEDAY] && IsNotSetBit(g_iBitUserQuestForFree, pPlayer))
		{
			g_iUserStats[pPlayer][QUEST_3]++;
			SetBit(g_iBitUserQuestForFree, pPlayer);
		}
	}else UTIL_SayText(pPlayer, "!g* !yКвест за фд не засчитан т.к. мало зеков или вы не авторизованы");
	
	return 1;
}
public jbe_add_user_free_next_round(pPlayer)
{
	if(g_iUserTeam[pPlayer] != 1) return 0;
	SetBit(g_iBitUserFreeNextRound, pPlayer);
	return 1;
}
public jbe_sub_user_free_ex(pPlayer)
{
	if(pPlayer > TASK_FREE_DAY_ENDED) pPlayer -= TASK_FREE_DAY_ENDED;
	if(IsNotSetBit(g_iBitUserFree, pPlayer)) return 0;
	ClearBit(g_iBitUserFree, pPlayer);
	g_iFreeCount--;
	
	if(g_iFreeCount > 0)
	{
		formatex(szFree, charsmax(szFree), "На отдыхе %d зек(ов)" , g_iFreeCount);
	}else szFree = "";


	if(g_szFreeNames[0] != 0)
	{
		new szName[34];
		get_user_name(pPlayer, szName, charsmax(szName));
		format(szName, charsmax(szName), "^n%s", szName);
		replace(g_szFreeNames, charsmax(g_szFreeNames), szName, "");

	}
	if(task_exists(pPlayer+TASK_FREE_DAY_ENDED)) remove_task(pPlayer+TASK_FREE_DAY_ENDED);

	set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);


	set_hudmessage(0, 255, 0, -1.0, 0.72, 0, 0.0, 5.8, 5.2, 5.2, -1);
	ShowSyncHudMsg
	(
		0, g_iSyncMainDeadInformer, "У игрока %n^nзакончился свободный день!", pPlayer
	);
	//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	//emit_sound(0, CHAN_AUTO, "jb_engine/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_SUB_USER_FREE], iRet, pPlayer, 2);
	
	
	return 1;
}

public jbe_sub_user_free(pPlayer)
{
	if(pPlayer > TASK_FREE_DAY_ENDED) pPlayer -= TASK_FREE_DAY_ENDED;
	if(IsNotSetBit(g_iBitUserFree, pPlayer)) return 0;
	ClearBit(g_iBitUserFree, pPlayer);
	g_iFreeCount--;
	
	if(g_iFreeCount > 0)
	{
		formatex(szFree, charsmax(szFree), "На отдыхе %d зек(ов)" , g_iFreeCount);
	}else szFree = "";


	if(g_szFreeNames[0] != 0)
	{
		new szName[34];
		get_user_name(pPlayer, szName, charsmax(szName));
		format(szName, charsmax(szName), "^n%s", szName);
		replace(g_szFreeNames, charsmax(g_szFreeNames), szName, "");
		//g_iFreeLang = (g_szFreeNames[0] != 0);
	}
	if(task_exists(pPlayer+TASK_FREE_DAY_ENDED)) remove_task(pPlayer+TASK_FREE_DAY_ENDED);
	//if(IsSetBit(g_iBitUserAlive, pPlayer)) 
	//{
	
	set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
	
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_SUB_USER_FREE], iRet, pPlayer, 2);
	//}
	return 1;
}

public jbe_free_day_start()
{
	if(g_iDayMode != 1) return 0;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(g_iUserTeam[iPlayer] == 1 && IsSetBit(g_iBitUserAlive, iPlayer) && IsNotSetBit(g_iBitUserWanted, iPlayer))
		{
			if(IsSetBit(g_iBitUserFree, iPlayer)) remove_task(iPlayer+TASK_FREE_DAY_ENDED);
			else
			{
				SetBit(g_iBitUserFree, iPlayer);
				if(jbe_is_user_flags(iPlayer, FLAGSGIRL))
				{
		
					jbe_set_user_model(iPlayer, g_szPlayerModel[GIRL]);
					set_entvar(iPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
					set_entvar(iPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
	
				}
				else 
				{

					jbe_set_user_model(iPlayer, g_szPlayerModel[PRISONER]);
					set_entvar(iPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
					set_entvar(iPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD]);
		
				}
			}
		}
	}
	if(task_exists(TASK_CHIEF_CHOICE_TIME))
	{
		remove_task(TASK_CHIEF_CHOICE_TIME);
	}
	g_szFreeNames = "";
	//g_iFreeLang = 0;
	jbe_open_doors();
	jbe_set_day_mode(2);
	g_iDayModeTimer = g_iAllCvars[FREE_DAY_ALL] + 1;
	set_task_ex(1.0, "jbe_free_day_ended_task", TASK_FREE_DAY_ENDED, _, _, SetTask_RepeatTimes, g_iDayModeTimer);
	return 1;
}
public jbe_free_day_ended_task()
{
	if(--g_iDayModeTimer) formatex(g_szDayModeTimer, charsmax(g_szDayModeTimer), "- %s", UTIL_FixTime(g_iDayModeTimer));
	else jbe_free_day_ended();
}
public jbe_free_day_ended()
{
	if(g_iDayMode != 2) return 0;
	g_szDayModeTimer = "";
	if(task_exists(TASK_FREE_DAY_ENDED)) remove_task(TASK_FREE_DAY_ENDED);
	//new iRandom;
	jbe_set_day_mode(1);
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(g_iUserTeam[iPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, iPlayer) || IsSetBit(g_iBitUserWanted, iPlayer)) continue;

		if(IsSetBit(g_iBitUserFree, iPlayer)) ClearBit(g_iBitUserFree, iPlayer);
		set_entvar(iPlayer, var_skin, g_iUserSkin[iPlayer]);
	}
	
	
	g_iFreeCount = 0;
	
	szFree = "";
	
	UTIL_SendAudio(0, _, "jb_engine/bell.wav");
	
	return 1;
}

public jbe_is_user_wanted(pPlayer) return IsSetBit(g_iBitUserWanted, pPlayer);
public jbe_add_user_wanted(pPlayer)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)
	|| IsSetBit(g_iBitUserWanted, pPlayer)) return 0;
	SetBit(g_iBitUserWanted, pPlayer);
	new szName[34];
	get_user_name(pPlayer, szName, charsmax(szName));
	formatex(g_szWantedNames, charsmax(g_szWantedNames), "%s^n%s", g_szWantedNames, szName);
	//g_iWantedLang = 1;
	g_iWantedCount++;
	
	if(g_iWantedCount > 0)
	{
		formatex(szWanted, charsmax(szWanted), "Бунтари %d зек(ов)" , g_iWantedCount);
	}else szWanted = "";
	

	if(IsSetBit(g_iBitUserFree, pPlayer))
	{
		if(g_iDayMode == 1) 
		{
			g_iFreeCount--;
			
			if(g_iFreeCount > 0)
			{
				formatex(szFree, charsmax(szFree), "На отдыхе %d зек(ов)" , g_iFreeCount);
			}else szFree = "";
		}
		
		


		ClearBit(g_iBitUserFree, pPlayer);
		if(g_szFreeNames[0] != 0)
		{
			format(szName, charsmax(szName), "^n%s", szName);
			replace(g_szFreeNames, charsmax(g_szFreeNames), szName, "");
			//g_iFreeLang = (g_szFreeNames[0] != 0);
		}
		if(g_iDayMode == 1 && task_exists(pPlayer+TASK_FREE_DAY_ENDED)) remove_task(pPlayer+TASK_FREE_DAY_ENDED);
	}

	if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
	{

		jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL]);
		set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_WANTED_GIRLS]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_BODY_NUM]);
	
	}
	else 
	{

		jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[PR_BODY_NUM]);
		set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_WANTED]);

	}
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_ADD_USER_WANTED], iRet, pPlayer);
	
	if(g_iAlivePlayersNum[1] >= 5)
	{
		if(get_login(pPlayer) && g_iUserStats[pPlayer][QUEST_2] <= g_iQuestCvars[QUEST_WANTED] && IsNotSetBit(g_iBitUserQuestForWanted, pPlayer))
		{
			
				g_iUserStats[pPlayer][QUEST_2]++;
				SetBit(g_iBitUserQuestForWanted, pPlayer);
		}
	}
	
	return 1;
}
public jbe_sub_user_wanted(pPlayer)
{
	if(IsNotSetBit(g_iBitUserWanted, pPlayer)) return 0;
	ClearBit(g_iBitUserWanted, pPlayer);
	g_iWantedCount--;
	
	if(g_iWantedCount > 0)
	{
		formatex(szWanted, charsmax(szWanted), "Бунтари %d зек(ов)" , g_iWantedCount);
	}else szWanted = "";
	
	if(g_szWantedNames[0] != 0)
	{
		new szName[34];
		get_user_name(pPlayer, szName, charsmax(szName));
		format(szName, charsmax(szName), "^n%s", szName);
		replace(g_szWantedNames, charsmax(g_szWantedNames), szName, "");
		//g_iWantedLang = (g_szWantedNames[0] != 0);
	}

	if(IsSetBit(g_iBitUserAlive, pPlayer))
	{
		//new iRandom = random_num(g_szConfigs[CVARS_SKIN_MIN], g_szConfigs[CVARS_SKIN_MAX]);
		if(g_iDayMode == 2)
		{
			SetBit(g_iBitUserFree, pPlayer);
			if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
			{
				set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
				//jbe_set_user_skin(pPlayer, g_szConfigs[CVARS_SKIN_FD_GIRLS]);
			}
			else
			{
				set_entvar(pPlayer, var_skin, g_szConfigs[CVARS_SKIN_FD]);

			}
		}
		else 
		{
			set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);

			
		}
		new iRet;
		ExecuteForward(g_iForward[FORWARD_ON_SUB_USER_FREE], iRet, pPlayer, 1);
	}
	else
	{
		set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);

	}
	return 1;
}

public jbe_is_user_chief(pPlayer) return (pPlayer == g_iChiefId);
public jbe_set_user_chief(pPlayer)
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 2 || IsNotSetBit(g_iBitUserAlive, pPlayer)) return 0;
	if(g_iChiefStatus == 1)
	{
		jbe_set_user_model(g_iChiefId, g_szPlayerModel[GUARD]);
		set_entvar(g_iChiefId, var_body, g_szPlayerBodyModels[GUARD_BODY_NUM]);
		
		//if(g_bSoccerGame) remove_task(g_iChiefId+TASK_SHOW_SOCCER_SCORE);
		if(jbe_get_user_godmode(g_iChiefId)) jbe_set_user_godmode(g_iChiefId, 0);
	}
	if(task_exists(TASK_CHIEF_CHOICE_TIME)) remove_task(TASK_CHIEF_CHOICE_TIME);
	get_user_name(pPlayer, g_szChiefName, charsmax(g_szChiefName));
	g_iChiefStatus = 1;
	g_iChiefId = pPlayer;
	
	
	if(jbe_is_user_flags(pPlayer, FLAGSGIRL))
	{
		jbe_set_user_model(pPlayer, g_szPlayerModel[GIRL_GR]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[GIRL_GR_BODY_NUM]);
		jbe_set_user_rendering(pPlayer, kRenderFxGlowShell, 255, 65, 255, kRenderNormal, 0);
	}
	else 
	{
		jbe_set_user_model(pPlayer, g_szPlayerModel[CHIEF]);
		set_entvar(pPlayer, var_body, g_szPlayerBodyModels[CHIEF_BODY_NUM]);
	}
	
	new iRet;
	ExecuteForward(g_iForward[FORWARD_ON_CHIEF_SET], iRet, pPlayer);

	return 1;
}
public jbe_get_chief_status() return g_iChiefStatus;
public jbe_get_chief_id() return g_iChiefId;



public jbe_prisoners_divide_color(iTeam)
{
	if(g_iDayMode != 1 || g_iAlivePlayersNum[1] < 2 || iTeam < 2 || iTeam > 4) return 0;
	new const szLangPlayer[][] = {"JBE_HUD_ID_YOU_TEAM_ORANGE", "JBE_HUD_ID_YOU_TEAM_GRAY", "JBE_HUD_ID_YOU_TEAM_YELLOW", "JBE_HUD_ID_YOU_TEAM_BLUE"};

	UTIL_SayText(0, "!g* !yНачальник разделил заключенных на !g%d !yкоманды", iTeam);

	static iPlayers[MAX_PLAYERS], iPlayerCount, iPlayer;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "TERRORIST");
	SortIntegers(iPlayers, iPlayerCount, Sort_Random);

	for(new i, iCount, iColor; i < iPlayerCount; i++)
	{
		iPlayer = iPlayers[i];

		if(g_iUserTeam[iPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, iPlayer) || IsSetBit(g_iBitUserFree, iPlayer)
		|| IsSetBit(g_iBitUserWanted, iPlayer) || jbe_is_user_duel(iPlayer)) continue;

		UTIL_SayText(iPlayer, "!g * %L", iPlayer, szLangPlayer[iColor]);
		g_iUserSkin[iPlayer] = (iCount % iTeam);
		set_entvar(iPlayer, var_skin, g_iUserSkin[iPlayer]);
		iCount++;

		if(++iColor >= iTeam) iColor = 0;

	}
	if(g_iViewInformerSkinNum) 
		jbe_get_count_skin();


	return 1;
}



public jbe_register_day_mode(szLang[32], iBlock, iTime)
{
	param_convert(1);
	new aDataDayMode[DATA_DAY_MODE];
	copy(aDataDayMode[LANG_MODE], charsmax(aDataDayMode[LANG_MODE]), szLang);
	aDataDayMode[MODE_BLOCK_DAYS] = iBlock;
	aDataDayMode[MODE_TIMER] = iTime;
	ArrayPushArray(g_aDataDayMode, aDataDayMode);
	g_iDayModeListSize++;
	return g_iDayModeListSize - 1;
}

public jbe_get_user_voice(pPlayer) return IsSetBit(g_iBitUserVoice, pPlayer);
public jbe_set_user_voice(pPlayer)
{
	//if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)) return 0;
	SetBit(g_iBitUserVoice, pPlayer);
	new ret;
	ExecuteForward(g_iForward[FORWARD_ON_USER_VOICE], ret, pPlayer);
	//return 1;
}

public jbe_clear_user_voice(pPlayer)
{
	//if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)) return 0;
	ClearBit(g_iBitUserVoice, pPlayer);
	//return 1;
}
public jbe_set_user_voice_next_round(pPlayer)
{
	if(g_iUserTeam[pPlayer] != 1) return 0;
	SetBit(g_iBitUserVoiceNextRound, pPlayer);
	return 1;
}

public _jbe_get_user_rendering(pPlayer, &iRenderFx, &iRed, &iGreen, &iBlue, &iRenderMode, &iRenderAmt)
{
	for(new i = 2; i <= 7; i++) param_convert(i);
	jbe_get_user_rendering(pPlayer, iRenderFx, iRed, iGreen, iBlue, iRenderMode, iRenderAmt);
}
public jbe_get_user_rendering(pPlayer, &iRenderFx, &iRed, &iGreen, &iBlue, &iRenderMode, &iRenderAmt)
{
	new Float:fRenderColor[3];
	iRenderFx = get_entvar(pPlayer, var_renderfx);
	get_entvar(pPlayer, var_rendercolor, fRenderColor);
	iRed = floatround(fRenderColor[0]);
	iGreen = floatround(fRenderColor[1]);
	iBlue = floatround(fRenderColor[2]);
	iRenderMode = get_entvar(pPlayer, var_rendermode);
	new Float:fRenderAmt;
	get_entvar(pPlayer, var_renderamt, fRenderAmt);
	iRenderAmt = floatround(fRenderAmt);
}
public jbe_set_user_rendering(pPlayer, iRenderFx, iRed, iGreen, iBlue, iRenderMode, iRenderAmt)
{
	new Float:flRenderColor[3];
	flRenderColor[0] = float(iRed);
	flRenderColor[1] = float(iGreen);
	flRenderColor[2] = float(iBlue);
	set_entvar(pPlayer, var_renderfx, iRenderFx);
	set_entvar(pPlayer, var_rendercolor, flRenderColor);
	set_entvar(pPlayer, var_rendermode, iRenderMode);
	set_entvar(pPlayer, var_renderamt, float(iRenderAmt));
}
/*===== <- Нативы <- =====*///}

/*===== -> Стоки -> =====*///{


stock fm_get_aiming_position(pPlayer, Float:vecReturn[3])
{
	new Float:vecOrigin[3], Float:vecViewOfs[3], Float:vecAngle[3], Float:vecForward[3];
	get_entvar(pPlayer, var_origin, vecOrigin);
	get_entvar(pPlayer, var_view_ofs, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	get_entvar(pPlayer, var_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, 8192.0, vecForward);
	xs_vec_add(vecOrigin, vecForward, vecForward);
	engfunc(EngFunc_TraceLine, vecOrigin, vecForward, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecReturn);
}





stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

stock xs_vec_add(const Float:vec1[], const Float:vec2[], Float:out[])
{
	out[0] = vec1[0] + vec2[0];
	out[1] = vec1[1] + vec2[1];
	out[2] = vec1[2] + vec2[2];
}

stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}


stock UTIL_SendAudio(pPlayer, iPitch = 100, const szPathSound[], any:...)
{
	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] UTIL_SendAudio");
	}
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(MSG_BROADCAST, MsgId_SendAudio);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SendAudio, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
	}
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] UTIL_ScreenFade");
	}
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(MSG_BROADCAST, MsgId_ScreenFade);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
		default:
		{
			#if JBE_MODE_DEBUG == 1
			if( IsNotSetBit( g_iBitUserConnected, pPlayer ) ) 
			{
				log_to_file( "addons/amxmodx/jbe_debug/message.log", "[ScreenFade] Invalid ID: %d", pPlayer );
				return;
			}
			#endif
			
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
	}
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

/*stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
	
	#if JBE_MODE_DEBUG == 1
	g_iUtilSayTextCallBack[ 0 ]++;
	g_iUtilSayTextCallBack[ 1 ]++;
	#endif
}*/








stock CREATE_BEAMFOLLOW(pEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	#if JBE_MODE_DEBUG == 1
	if( !pev_valid( pEntity ) ) 
	{
		log_to_file( "addons/amxmodx/jbe_debug/message.log", "[CREATE_BEAMFOLLOW] Invalid Entity: %d", pEntity );
		return;
	}
	g_iStockCallback[ 0 ][ 0 ]++;
	g_iStockCallback[ 0 ][ 1 ]++;
	#endif
	
	if(IsNotSetBit(g_iBitUserConnected, pEntity)) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] CREATE_BEAMFOLLOW");
	}
	
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
	#if JBE_MODE_DEBUG == 1
	if(!is_entity(pEntity))
	{
		log_to_file( "addons/amxmodx/jbe_debug/message.log", "[CREATE_KILLBEAM] Invalid ID: %d", pEntity );
		return;
	}
	g_iStockCallback[ 1 ][ 0 ]++;
	g_iStockCallback[ 1 ][ 1 ]++;
	#endif
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] CREATE_KILLBEAM");
	}
	
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(pEntity);
	message_end();
}

stock UTIL_GetReplace(repl[])
{
	new szBuffer[128];
	format(szBuffer, 127, "%L", LANG_SERVER, repl);
	return szBuffer;
}

stock UTIL_Name(pId)
{
	static szBuffer[33];
	get_user_name(pId, szBuffer, charsmax(szBuffer));
	return szBuffer;
}

stock rg_set_entity_visibility(entity, visible = 1) 
{
    set_entvar(entity, var_effects, visible == 1 ? get_entvar(entity, var_effects) & ~EF_NODRAW : get_entvar(entity, var_effects) | EF_NODRAW);
    return 1;
}

/*stock set_entity_visibility(entity, visible = 1) 
{
    set_pev(entity, pev_effects, visible == 1 ? pev(entity, pev_effects) & ~EF_NODRAW : pev(entity, pev_effects) | EF_NODRAW);
    return 1;
}*/

stock rg_set_entity_shadows(entity, visible =1)
{
	set_entvar(entity, var_effects, visible == 1 ? get_entvar(entity, var_effects) & ~EF_NOSHADOW : get_entvar(entity, var_effects) | EF_NOSHADOW);
    return 1;
}


stock set_dead_attrib(pId)
{
	const DEAD_FLAG = (1 << 0);
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] set_dead_attrib");
	}
	message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
	write_byte(pId);
	write_byte(DEAD_FLAG);
	message_end();
}

stock jbe_spawn_effects(pId)
{
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[JBE_CORE] jbe_spawn_effects");
	}
	message_begin( MSG_ONE_UNRELIABLE, MsgId_ScreenShake, _, pId );
	write_short( 9999999 ); //amount
	write_short( 9999 ); //duration
	write_short( 999 ); //frequency
	message_end( );
}


stock UTIL_FixTime(iTimer)
{
	new szTime[10], iMin = floatround(iTimer / 60.0, floatround_floor), iSec = iTimer - (iMin * 60);
	formatex(szTime, charsmax(szTime), "%d:%s%d", iMin, iSec > 9 ? "" : "0" , iSec);
	return szTime;
}


/*stock IsValidMap(const szBossMapname[]) {

	new szMapname[32]; get_mapname(szMapname, charsmax(szMapname));
	return equal(szMapname, szBossMapname);

}*/

UTIL_FixedUnsigned16(const Float:Value, const Scale) 
	return clamp(floatround(Value * Scale), 0, 0xFFFF);


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
	
	return iLen;
}

stock is_enable()
{
	if(jbe_status_block(1)) return true;
	else return false;
}






Show_InformerSettings(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yНастройка Информера^n^n");
	
	#if defined INFORMER_MAIN
	FormatItem("\y1. \rПоложение информера^n^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wРанг: \r%s ^n", !g_iUserInformer[pId][INFORMER_RANK] ? "Видно" : "Скрыто"), iKeys |= (1<<1);
	FormatItem("\y3. \wДень недели: \r%s ^n", !g_iUserInformer[pId][INFORMER_DAYWEEK] ? "Видно" : "Скрыто"), iKeys |= (1<<2);
	FormatItem("\y4. \wРежим дня: \r%s ^n", !g_iUserInformer[pId][INFORMER_DAYMODE] ? "Видно" : "Скрыто"), iKeys |= (1<<3);
	FormatItem("\y5. \wНачальник: \r%s ^n", !g_iUserInformer[pId][INFORMER_CHIEF] ? "Видно" : "Скрыто"), iKeys |= (1<<4);
	FormatItem("\y6. \wКол-во Зеков: \r%s ^n", !g_iUserInformer[pId][INFORMER_PRISONCOUNT] ? "Видно" : "Скрыто"), iKeys |= (1<<5);
	FormatItem("\y7. \wКол-во Охраны: \r%s ^n", !g_iUserInformer[pId][INFORMER_GUARDCOUNT] ? "Видно" : "Скрыто"), iKeys |= (1<<6);
	FormatItem("\y8. \wВремя: \r%s ^n", !g_iUserInformer[pId][INFORMER_TIME] ? "Видно" : "Скрыто"), iKeys |= (1<<7);
	#else
	FormatItem("\y1. \yПоложение информера^n^n");
	FormatItem("\y2. \dРанг: \y%s ^n", !g_iUserInformer[pId][INFORMER_RANK] ? "ON" : "OFF");
	FormatItem("\y3. \dДень недели: \y%s ^n", !g_iUserInformer[pId][INFORMER_DAYWEEK] ? "ON" : "OFF");
	FormatItem("\y4. \dРежим дня: \y%s ^n", !g_iUserInformer[pId][INFORMER_DAYMODE] ? "ON" : "OFF");
	FormatItem("\y5. \dНачальник: \y%s ^n", !g_iUserInformer[pId][INFORMER_CHIEF] ? "ON" : "OFF");
	FormatItem("\y6. \dКол-во Зека: \y%s ^n", !g_iUserInformer[pId][INFORMER_PRISONCOUNT] ? "ON" : "OFF");
	FormatItem("\y7. \dКол-во Охраны: \y%s ^n", !g_iUserInformer[pId][INFORMER_GUARDCOUNT] ? "ON" : "OFF");
	FormatItem("\y8. \dВремя: \y%s ^n", !g_iUserInformer[pId][INFORMER_TIME] ? "ON" : "OFF");
	#endif

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_InformerSettings");
}

public Handle_InformerSettings(pId, iKey)
{
	switch(iKey)
	{
		case 0: return Show_InformerPosition(pId);
		case 1:
		{
			g_iUserInformer[pId][INFORMER_RANK] = !g_iUserInformer[pId][INFORMER_RANK];
			
			switch(g_iUserInformer[pId][INFORMER_RANK])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					switch(jbe_get_user_team(pId))
					{
						case 1: 
						{
							formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankName[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,1),jbe_get_user_exp_next(pId));
						}
						case 2: 
						{
							formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankNameCT[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,2),jbe_get_user_exp_next(pId));
						}
						default: formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "^n^n");
					}
				}
			}
		
		
		}
		case 2:
		{
			g_iUserInformer[pId][INFORMER_DAYWEEK] = !g_iUserInformer[pId][INFORMER_DAYWEEK];
			
			switch(g_iUserInformer[pId][INFORMER_DAYWEEK])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][DAYWEEK_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					formatex(g_iUserInformer[pId][DAYWEEK_FORMATEX], FORMATEX_INFORMER, "%L, День %d^n",LANG_PLAYER, g_szDaysWeek[g_iDayWeek], g_iDay);
				}
			}
		
		
		}
		case 3:
		{
			g_iUserInformer[pId][INFORMER_DAYMODE] = !g_iUserInformer[pId][INFORMER_DAYMODE];
			
			switch(g_iUserInformer[pId][INFORMER_DAYMODE])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][DAYMODE_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					formatex(g_iUserInformer[pId][DAYMODE_FORMATEX], FORMATEX_INFORMER, "Режим: %L %s^n", LANG_PLAYER, g_szDayMode, g_szDayModeTimer);
				}
			}
		
		
		}
		case 4:
		{
			g_iUserInformer[pId][INFORMER_CHIEF] = !g_iUserInformer[pId][INFORMER_CHIEF];
			
			switch(g_iUserInformer[pId][INFORMER_CHIEF])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][CHIEF_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					formatex(g_iUserInformer[pId][CHIEF_FORMATEX], FORMATEX_INFORMER, "Начальник: %L%s^n", LANG_PLAYER, g_szChiefStatus[g_iChiefStatus], g_szChiefName);
				}
			}
		
		
		}
		case 5:
		{
			g_iUserInformer[pId][INFORMER_PRISONCOUNT] = !g_iUserInformer[pId][INFORMER_PRISONCOUNT];
			
			switch(g_iUserInformer[pId][INFORMER_PRISONCOUNT])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][PRISONCOUNT_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					formatex(g_iUserInformer[pId][PRISONCOUNT_FORMATEX], FORMATEX_INFORMER, "Заключенные: %d/%d^n",g_iAlivePlayersNum[1], g_iPlayersNum[1]);
				}
			}
		
		
		}
		case 6:
		{
			g_iUserInformer[pId][INFORMER_GUARDCOUNT] = !g_iUserInformer[pId][INFORMER_GUARDCOUNT];
			
			switch(g_iUserInformer[pId][INFORMER_GUARDCOUNT])
			{
				case true:
				{
					formatex(g_iUserInformer[pId][GUARDCOUNT_FORMATEX], FORMATEX_INFORMER, "");

				}
				case false:
				{
					formatex(g_iUserInformer[pId][GUARDCOUNT_FORMATEX], FORMATEX_INFORMER, "Охранники: %d|%d^n",g_iAlivePlayersNum[2], g_iPlayersNum[2]);
				}
			}
		}
		case 7: g_iUserInformer[pId][INFORMER_TIME] = !g_iUserInformer[pId][INFORMER_TIME];
		

		case 9: return Show_PlayerSettingsMenu(pId);
	}
	return Show_InformerSettings(pId);
}



Show_InformerPosition(pId)
{
	new szMenu[512], iKeys, iLen;
	
	FormatMain("\yТекущие настройки:^nRGB %d|%d|%d^nPos X-%.3f | Y-%-3f^n^n", g_iUserInformer[pId][INFO_POS_RED],g_iUserInformer[pId][INFO_POS_GREEN],g_iUserInformer[pId][INFO_POS_BLUE],g_iUserInformer[pId][INFO_POS_FLOAT_X],g_iUserInformer[pId][INFO_POS_FLOAT_Y]);
	
	FormatItem("\y1. \wЦвет RED: \y%d^n" , g_iUserInformer[pId][INFO_POS_RED]), iKeys |= (1<<0);
	FormatItem("\y2. \wЦвет GREEN: \y%d^n" , g_iUserInformer[pId][INFO_POS_GREEN]), iKeys |= (1<<1);
	FormatItem("\y3. \wЦвет BLUE: \y%d^n^n" , g_iUserInformer[pId][INFO_POS_BLUE]), iKeys |= (1<<2);
	
	FormatItem("\y4. \wПоложение абсцисс: \yось-%s^n" , g_iUserInformer[pId][INFO_POS_ABS] ? "X" : "Y"), iKeys |= (1<<3);

	switch(g_iUserInformer[pId][INFO_POS_ABS])
	{
		case true:
		{
			FormatItem("\y5. \wПрибавить: %.3f^n" , g_iUserInformer[pId][INFO_POS_FLOAT_X]), iKeys |= (1<<4);
			FormatItem("\y6. \wУбавить: %.3f^n" , g_iUserInformer[pId][INFO_POS_FLOAT_X]), iKeys |= (1<<5);
		}
		case false:
		{
			FormatItem("\y5. \wПрибавить: %.3f^n" , g_iUserInformer[pId][INFO_POS_FLOAT_Y]), iKeys |= (1<<4);
			FormatItem("\y6. \wУбавить: %.3f^n" , g_iUserInformer[pId][INFO_POS_FLOAT_Y]), iKeys |= (1<<5);
		}
	}
	

	FormatItem("^n\y7. \rСбросить цвет^n"), iKeys |= (1<<6);
	FormatItem("\y8. \rСбросить координат^n"), iKeys |= (1<<7);
	
	FormatItem("^n^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_InformerPosition");
}

public Handle_InformerPosition(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			UTIL_SayText(pId, "!g[POSINFORM] !yВыбери цвет !gRED !yв диапазоне от !g1 !yдо !g255!y.");
			g_iUserInformer[pId][INFO_POS_NUMBER] = 1;
			client_cmd(pId, "messagemode ColorInformer");
		}
		case 1: 
		{
			UTIL_SayText(pId, "!g[POSINFORM] !yВыбери цвет !gGREEN !yв диапазоне от !g1 !yдо !g255!y.");
			g_iUserInformer[pId][INFO_POS_NUMBER] = 2;
			client_cmd(pId, "messagemode ColorInformer");
		}
		case 2: 
		{
			UTIL_SayText(pId, "!g[POSINFORM] !yВыбери цвет !gBLUE !yв диапазоне от !g1 !yдо !g255!y.");
			g_iUserInformer[pId][INFO_POS_NUMBER] = 3;
			client_cmd(pId, "messagemode ColorInformer");
		}
		case 3: 
		{
			g_iUserInformer[pId][INFO_POS_ABS] = !g_iUserInformer[pId][INFO_POS_ABS];
			return Show_InformerPosition(pId);
		}
	
	
		case 4:	
		{
			switch(g_iUserInformer[pId][INFO_POS_ABS])
			{
				case true:
				{
					if(g_iUserInformer[pId][INFO_POS_FLOAT_X] < 1.0 || g_iUserInformer[pId][INFO_POS_FLOAT_X] < 0.00)
						g_iUserInformer[pId][INFO_POS_FLOAT_X] += 0.05;
					else g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.01;
				}
				case false:
				{
					if(g_iUserInformer[pId][INFO_POS_FLOAT_Y] < 1.0 || g_iUserInformer[pId][INFO_POS_FLOAT_Y] < 0.00)
						g_iUserInformer[pId][INFO_POS_FLOAT_Y] += 0.05;
					else g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.01;
				}
			}
			return Show_InformerPosition(pId);
		}
		case 5:
		{
			switch(g_iUserInformer[pId][INFO_POS_ABS])
			{
				case true:
				{
					if(g_iUserInformer[pId][INFO_POS_FLOAT_X] < 1.0 || g_iUserInformer[pId][INFO_POS_FLOAT_X] < 0.00)
						g_iUserInformer[pId][INFO_POS_FLOAT_X] -= 0.05;
					else g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.01;
				}
				case false:
				{
					if(g_iUserInformer[pId][INFO_POS_FLOAT_Y] < 1.0 || g_iUserInformer[pId][INFO_POS_FLOAT_Y] < 0.00)
						g_iUserInformer[pId][INFO_POS_FLOAT_Y] -= 0.05;
					else g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.01;
				}
			}
			return Show_InformerPosition(pId);
		}
		
		case 6:
		{
			g_iUserInformer[pId][INFO_POS_RED] = 255;
			g_iUserInformer[pId][INFO_POS_GREEN] = 255;
			g_iUserInformer[pId][INFO_POS_BLUE] = 0;
			return Show_InformerPosition(pId);
		}
		case 7:
		{
			g_iUserInformer[pId][INFO_POS_FLOAT_X] = 0.70;
			g_iUserInformer[pId][INFO_POS_FLOAT_Y] = 0.05;
			return Show_InformerPosition(pId);
		}

		case 9: return Show_InformerSettings(pId);

	}
	
	return PLUGIN_HANDLED;



}

public ColorInformer(id)
{
	new Args1[15];
	read_args(Args1, charsmax(Args1));
	remove_quotes(Args1);
	if(strlen( Args1 ) > 3)
	{
		UTIL_SayText(id, "!g* !yВы ввели слишком !gбольшое число !y[!gMax:255!y]");
		return Show_InformerPosition(id);
	}
	if(strlen( Args1 ) == 0)
	{
		UTIL_SayText(id, "!g* !yПустое значение !gневозможно");
		return Show_InformerPosition(id);
	}
	if(str_to_num( Args1 ) < 0)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение меньше !g0!");
		return Show_InformerPosition(id);
	}
	if(str_to_num( Args1 ) > 255)
	{
		UTIL_SayText(id, "!g* !yНельзя выставить значение больше !g255!");
		return Show_InformerPosition(id);
	}
	for(new x; x < strlen( Args1 ); x++)
	{
		if(!isdigit( Args1[x] ))
		{
			UTIL_SayText(id, "!g* !yЗначение должна быть только !gчислом");
			return Show_InformerPosition(id);
		}
	}
	new szAmount1 = str_to_num( Args1 );
	
	switch(g_iUserInformer[id][INFO_POS_NUMBER])
	{
		case 1: g_iUserInformer[id][INFO_POS_RED] = szAmount1;
		case 2: g_iUserInformer[id][INFO_POS_GREEN] = szAmount1;
		case 3: g_iUserInformer[id][INFO_POS_BLUE] = szAmount1;
	}
	
	return Show_InformerPosition(id);
}




stock jbe_settings_playerinformer(pId)
{
	switch(g_iUserInformer[pId][INFORMER_TIME])
	{
		case true: formatex(g_iUserInformer[pId][TIME_FORMATEX], FORMATEX_INFORMER, "");
		case false: formatex(g_iUserInformer[pId][TIME_FORMATEX], FORMATEX_INFORMER, "^nВремя: %s", CurrentTime);
	}
	
	

	if(g_iDayMode != 2 && g_iUserTeam[pId] == 1 && IsSetBit(g_iBitUserFree, pId))
	{
		static Float: fCurTime; fCurTime = get_gametime();
		if(g_iGameTimeFD[pId] >= fCurTime)
		{
			formatex(g_iUserInformer[pId][TIMEFD_FORMATEX], FORMATEX_INFORMER, "Таймер  вашего ФД - %s" , UTIL_FixTime(floatround(g_iGameTimeFD[pId]) - floatround(fCurTime)));
		}
	}else formatex(g_iUserInformer[pId][TIMEFD_FORMATEX], FORMATEX_INFORMER, "");

	switch(g_iUserInformer[pId][INFORMER_RANK])
	{
		case true:
		{
			if(get_login(pId))
			{
				formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "");
			}else formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "Наш форум: frallion.ru^n^n");
		}
		case false:
		{
			if(get_login(pId))
			{
				switch(jbe_get_user_team(pId))
				{
					case 1: 
					{
						formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankName[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,1),jbe_get_user_exp_next(pId));
					}
					case 2: 
					{
						formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankNameCT[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,2),jbe_get_user_exp_next(pId));
					}
					default: formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "");
				}
			}else formatex(g_iUserInformer[pId][RANK_FORMATEX], FORMATEX_INFORMER, "Наш форум: frallion.ru^n^n");
		}
	}

	switch(g_iUserInformer[pId][INFORMER_DAYWEEK])
	{
		case true:
		{
			formatex(g_iUserInformer[pId][DAYWEEK_FORMATEX], FORMATEX_INFORMER, "");

		}
		case false:
		{
			formatex(g_iUserInformer[pId][DAYWEEK_FORMATEX], FORMATEX_INFORMER, "%L, День %d^n",LANG_PLAYER, g_szDaysWeek[g_iDayWeek], g_iDay);
		}
	}

	switch(g_iUserInformer[pId][INFORMER_DAYMODE])
	{
		case true:
		{
			formatex(g_iUserInformer[pId][DAYMODE_FORMATEX], FORMATEX_INFORMER, "");

		}
		case false:
		{
			formatex(g_iUserInformer[pId][DAYMODE_FORMATEX], FORMATEX_INFORMER, "Режим: %L %s^n", LANG_PLAYER, g_szDayMode, g_szDayModeTimer);
		}
	}

	switch(g_iUserInformer[pId][INFORMER_CHIEF])
	{
		case true:
		{
			formatex(g_iUserInformer[pId][CHIEF_FORMATEX], FORMATEX_INFORMER, "");

		}
		case false:
		{
			formatex(g_iUserInformer[pId][CHIEF_FORMATEX], FORMATEX_INFORMER, "Начальник: %L%s^n", LANG_PLAYER, g_szChiefStatus[g_iChiefStatus], g_szChiefName);
		}
	}

	switch(g_iUserInformer[pId][INFORMER_PRISONCOUNT])
	{
		case true:
		{
			formatex(g_iUserInformer[pId][PRISONCOUNT_FORMATEX], FORMATEX_INFORMER, "");

		}
		case false:
		{
			formatex(g_iUserInformer[pId][PRISONCOUNT_FORMATEX], FORMATEX_INFORMER, "Заключенные: %d/%d^n",g_iAlivePlayersNum[1], g_iPlayersNum[1]);
		}
	}

	switch(g_iUserInformer[pId][INFORMER_GUARDCOUNT])
	{
		case true:
		{
			formatex(g_iUserInformer[pId][GUARDCOUNT_FORMATEX], FORMATEX_INFORMER, "");

		}
		case false:
		{
			formatex(g_iUserInformer[pId][GUARDCOUNT_FORMATEX], FORMATEX_INFORMER, "Охранники: %d|%d^n",g_iAlivePlayersNum[2], g_iPlayersNum[2]);
		}
	}
}



public jbe_update_rank(pId)
{
	/*switch(jbe_get_user_team(pId))
	{
		case 1: 
		{
			formatex(Ranks[pId], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankName[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,1),jbe_get_user_exp_next(pId));
		}
		case 2: 
		{
			formatex(Ranks[pId], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankNameCT[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,2),jbe_get_user_exp_next(pId));
		}
		default: formatex(Ranks[pId], charsmax(Ranks[]), "^n^n");
	}*/
}

public jbe_update_rank_ex(pId)
{
	pId -= TASK_UPDATE_RANK;
	
	if(get_login(pId))
	{
		switch(jbe_get_user_team(pId))
		{
			case 1: 
			{
				formatex(Ranks[pId], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankName[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,1),jbe_get_user_exp_next(pId));
			}
			case 2: 
			{
				formatex(Ranks[pId], charsmax(Ranks[]), "%L - [%d\%d]^n^n", LANG_PLAYER, g_szRankNameCT[jbe_get_user_ranks(pId)] ,jbe_mysql_get_exp( pId,2),jbe_get_user_exp_next(pId));
			}
			default: formatex(Ranks[pId], charsmax(Ranks[]), "^n^n");
		}
	}else Ranks[pId] = "";
}

public jbe_regs_logout(pId, Login[]) Ranks[pId] = "";

public cmdWho(id)
{
	if(jbe_is_user_flags(id, FLAGSADMIN))
	{

		new players[MAX_PLAYERS], inum, cl_on_server[64], authid[32], name[MAX_NAME_LENGTH], flags, sflags[32], plr;
		new lImm[16], lRes[16], lAccess[16], lYes[16], lNo[16];
		
		formatex(lImm, charsmax(lImm), "%L", id, "IMMU");
		formatex(lRes, charsmax(lRes), "%L", id, "RESERV");
		formatex(lAccess, charsmax(lAccess), "%L", id, "ACCESS");
		formatex(lYes, charsmax(lYes), "%L", id, "YES");
		formatex(lNo, charsmax(lNo), "%L", id, "NO");
		
		
		get_players(players, inum);
		format(cl_on_server, charsmax(cl_on_server), "%L", id, "CLIENTS_ON_SERVER");
		client_print(id,print_console,"^n%s:^n #  %-16.15s %-20s %-8s %-4.3s %-4.3s %s", cl_on_server, "nick", "authid", "userid", lImm, lRes, lAccess);
		
		for (new a = 0; a < inum; ++a)
		{
			plr = players[a];
			get_user_authid(plr, authid, charsmax(authid));
			get_user_name(plr, name, charsmax(name));
			flags = get_user_flags(plr);
			get_flags(flags, sflags, charsmax(sflags));
			client_print(id,print_console,"^n%2d  %-16.15s %-20s %-8d %-6.5s %-6.5s %s", plr, name, authid, 
			get_user_userid(plr), (flags&ADMIN_IMMUNITY) ? lYes : lNo, (flags&ADMIN_RESERVATION) ? lYes : lNo, sflags);
		}
		
		client_print(id,print_console,"^n%L", id, "TOTAL_NUM", inum);
		get_user_authid(id, authid, charsmax(authid));
		get_user_name(id, name, charsmax(name));
		log_amx("Cmd: ^"%s<%d><%s><>^" ask for players list", name, get_user_userid(id), authid) ;
	}
	return PLUGIN_HANDLED;
}

Show_MenuPn(pId)
{
	new szMenu[512], iLen, iKeys = (1<<1|1<<3|1<<4|1<<5|1<<8|1<<9);
	
	FormatMain("\yМеню Заключенного^n^n");
	
	FormatItem("\y1. \wВыбрать перчатки \r(в работе)^n");
	FormatItem("\y2. \wЛохотрон^n");
	FormatItem("\y3. \wМеню Авторитетного \r(в работе)^n");
	FormatItem("\y4. \wЦитаты^n");
	FormatItem("\y5. \wВид от 3-го лица^n");
	FormatItem("\y6. \wНоминировать карту^n");
	
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_MenuPn");
}


public Handle_MenuPn(pId, iKey)
{
	if(g_iUserTeam[pId] != 1)
	{
		UTIL_SayText(pId, "!g* !yДоступен только заключенным");
		return PLUGIN_HANDLED;
	}
	
	
	switch(iKey)
	{
		case 0: return client_cmd(pId, "knife");
		case 1: return client_cmd(pId, "lox");
		case 2: return PLUGIN_HANDLED;
		case 3: return client_cmd(pId, "radio1");
		case 4: return client_cmd(pId, "cam");
		case 5: return client_cmd(pId, "say /maps");
		case 9: return PLUGIN_HANDLED;
	}

	return Show_MenuPn(pId);
}

Show_RulesMenu(pId)
{
	new szMenu[512], iLen, iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	
	FormatMain("\yПравила Сервера^n^n");
	
	FormatItem("\y1. \wОсновные Правила^n");
	FormatItem("\y2. \wПравила Jail-Мода^n");
	FormatItem("\y3. \wСокращенные Правила \r(в работе)^n");
	FormatItem("\y4. \wИнформация о Сервере^n");
	

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_RulesMenu");
}


public Handle_MainRulesMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			UTIL_SayText(pId, "!g* !yВсе необходимые информация выведено в !tконсоль !g(` ~ Тильда)");
			
			client_print(pId,print_console,"^n************************************^n");  
			client_print(pId,print_console,"*********Основные Правила***********^n");  
			//client_print(pId,print_console,"https://fraggers.ru/forum/topic?id=85");  
			client_print(pId,print_console,"^n************************************^n");  
		
		}
		case 1: 
		{
			UTIL_SayText(pId, "!g* !yВсе необходимые информация выведено в !tконсоль !g(` ~ Тильда)");
			
			client_print(pId,print_console,"^n************************************^n");  
			client_print(pId,print_console,"*********Правила Jail-Мода**********^n");   
			//client_print(pId,print_console,"https://fraggers.ru/forum/topic?id=100");  
			client_print(pId,print_console,"^n************************************^n");   
		
		}
		
		case 2:
		{
			UTIL_SayText(pId, "!g* !yВсе необходимые информация выведено в !tконсоль !g(` ~ Тильда)");
			
			client_print(pId,print_console,"^n************************************^n");  
			client_print(pId,print_console,"**********Сокращенные Правила*******^n");  
			//client_print(pId,print_console,"https://fraggers.ru/forum/topic?id=137");  
			client_print(pId,print_console,"^n************************************^n");   
		
		}
		case 3: return client_cmd(pId, "sborkainfo");
		
		case 9: return PLUGIN_HANDLED;
	}

	return Show_RulesMenu(pId);
}

CalculateElapsed(seconds) {
   new iMinutes, iSeconds, iChoice;
   new gszElapsed[64],iLen;
   static szMinutes[][] = {
      "минута",
      "минуты",
      "минут"
   };
   static szSeconds[][] = {
      "секунда",
      "секунды",
      "секунд"
   };

   iMinutes = seconds / 60;
   iSeconds = seconds - iMinutes * 60;

   if (iMinutes) {
      switch (iMinutes) {    // correct case up to 20
         case 1    : iChoice = 0;
         case 2..4 : iChoice = 1;
         default   : iChoice = 2;
      }
	  iLen += formatex(gszElapsed[iLen], charsmax(gszElapsed) - iLen, iSeconds ? "%d %s " : "%d %s", iMinutes, szMinutes[iChoice]);
   }
   if (iSeconds) {
      switch (iSeconds) {
         case 1, 21, 31, 41, 51 : iChoice = 0;
         case 2..4, 22..24, 32..34, 42..44, 52..54 : iChoice = 1;
         default : iChoice = 2;
      }
	  iLen += formatex(gszElapsed[iLen], charsmax(gszElapsed) - iLen,  " %d %s", iSeconds, szSeconds[iChoice]);
   }
   return gszElapsed;
}