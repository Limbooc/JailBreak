#include <amxmodx>
#include <center_msg_fix>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>
#include <engine>

new g_iGlobalDebug;
#include <util_saytext>


#define CVAR_SPEED 		350.0  		//Скорость

#define SOUND_VALUE		2			//уровень звука молота и бенеза


forward jbe_load_stats(pId);
forward jbe_save_stats(pId);
forward jbe_lr_duels();

native jbe_get_user_ranks(pId);

#pragma semicolon 1

#define QUESTNUM 75

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1], 
	g_iMenuTarget[MAX_PLAYERS + 1];


#define MsgId_Money 102

#define MsgId_SayText 76
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))



//#define DEBUG

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

#define MsgId_ScreenFade 98
#define MsgId_ScreenShake 97
#define MsgId_SendAudio 100


#define linux_diff_player 5



#define IUSER1_ANTIGRAVITY_KEY 235883
#define IUSER1_FROSTNADE_KEY 235884
#define IUSER1_GALOGRAMMA_KEY 235885
#define IUSER1_REMOVEGUN_KEY 235886

#define rg_set_weapon_ammo(%0,%1) set_member(%0, m_Weapon_iClip, %1)

#if cellbits == 32
const OFFSET_CLIPAMMO = 51;
#else
const OFFSET_CLIPAMMO = 65;
#endif
const OFFSET_LINUX_WEAPONS = 4;

new const ITEM_CLASSNAME[] = "weapon_knife";

new g_iButt[MAX_PLAYERS + 1];
//new g_iChips[MAX_PLAYERS + 1];
new g_iShopCvars[37];
new g_iTransferMoneyBut[3];
new g_iFwdDropLom;

native jbe_playersnum(iType);
native jbe_is_user_blind(pId);
native jbe_restartgame();
public jbe_set_user_godmode(pId, bType) set_entvar( pId, var_takedamage, !bType ? DAMAGE_YES : DAMAGE_NO );
public bool: jbe_get_user_godmode(pId) return bool:( get_entvar(pId, var_takedamage) == DAMAGE_NO );

new g_iUserDoubleDamage[MAX_PLAYERS + 1],
	g_iUserGravity[MAX_PLAYERS + 1];
	
new g_iBitUserHealt,
	g_iBitUserArmor;
	
new g_iBitUserFree;

enum _:(+= 101)
{
	FIX_TASK_LATCH_KEY  = 500000,
	TASK_ANTIGRAVITY,
	TASK_FROSTNADE_DEFROST,
	TASK_GALOGRAMMA_DE,
	TASK_FREEZE,
	TASK_REGEN_HP,
	TASK_RESETHUD
}

enum _:SHOPCVARS
{
	ITEMS_FD 	= 0,						
	ITEMS_CLOTHING, 								
	ITEMS_LATCHKEY, 								
	ITEMS_SHAHID,
	ITEMS_SHAHID_RADIUS,
	ITEMS_SHAHID_DAMAGE,
	ITEMS_GRENADE_ANTI,
	ITEMS_GRENADE_FROST,
	ITEMS_GRENADE_GAL,
	ITEMS_GRENADE_COUNT,
	///////////////
	SKILLS_GRAVITY,
	SKILLS_SPEED,
	SKILLS_HP,
	//SKILLS_AP,
	SKILLS_BHOP,
	SKILLS_DDAMAGE,
	/////////////
	//WEAPONS_GLOCK18,
	//WEAPONS_TMP,
	//WEAPONS_DEAGLE,
	WEAPONS_MOLOT,
	WEAPONS_BENZ,
	//////////////
	OTHER_MICRO,
	OTHER_LOTO,
	OTHER_RANDOMGLOW,
	OTHER_WANTEDSUB,
	/////////////
	SHOP_CT_ELECTRO,
	SHOP_CT_FORMA,
	SHOP_CT_SPEED,
	SHOP_CT_FIELD,
	SHOP_CT_HEALT,
	SHOP_CT_UNLIMAM,
	SHOP_CT_REGEN,
	SHOP_CT_GRENA,
	SHOP_CT_GODMODE,
	SHOP_CT_ELECTROTIME,
	ITEMS_GRENADE_COUNT_GR,
	SIMON_SHOP_BOG_ROUND
}


new g_iCvarStats[SHOPCVARS];
enum _:(+= 1)
{
	MONEY_1 = 0,
	MONEY_2,
	MONEY_3
}

native jbe_show_mainmenu(pId);
native jbe_get_soccergame();
native jbe_is_user_duel(pId);
native jbe_iduel_status();
native jbe_set_user_clothingtype(pId, iType);

native get_login(pId);
native jbe_mysql_stats_systems_add(pId, iType, iNum);
native jbe_mysql_stats_systems_get(pId, iType);

native get_frozen_status(pId);
native set_frozen_status(pId);
native jbe_set_user_model_ex(pId, iType);

native jbe_is_user_has_crowbar(pId);

native jbe_status_block(iType);

native jbe_globalnyizapret();

new g_iSimonShopBog[MAX_PLAYERS + 1];
new g_iBitFastRun,
	g_iBitAutoBhop,
	g_iBitDoubleDamage,
	g_iBitClothingGuard,
	g_iBitClothingType,
	g_iBitLotteryTicket,
	g_iBitRandomGlow,
	g_iBitLatchkey,
	g_gUserForJihad,
	g_iBitUserJihadUsed,
	g_iBitUserHasHE,
	g_iBitUserHasFL,
	g_iBitUserHasSM,
	g_iBitUserHasUsp,
	g_iBitUserHasTMP,
	g_iBitUserHasDeagle,
	g_iBitUserMolot,
	g_iBitUserSaw,
	g_iBitWeaponStatus,
	g_iBitAntiGravity,
	g_iBitUserAntiGravity,
	
	g_iBitFrostNade,
	g_iBitUserFrozen,
	
	g_iBitGalogramma,
	g_iBitUserGalogramma,
	
	g_iBitUserElectroShoker,
	g_iBitUserShopModel,
	g_iBitUserShopDamageReduce,
	g_iBitUserUnlimAmmo,
	g_iBitRemoveGun;

new	g_iSpiteExlplosion,
	g_pSpriteBeam,
	g_pSpriteWave,
	g_pModelGlass,
	SpriteElectro;	
	
new Float: fCurTime[MAX_PLAYERS + 1],
	Float: fNextTime[MAX_PLAYERS + 1]; 
	
new g_iQuestShahid,
	g_iQuestMazhor;



public plugin_init()
{
	register_plugin("[JBE] JailShops API", "1.0", "DalgaPups");
	
	
	//register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");

	
//	register_menucmd(register_menuid("Show_MainShopMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_MainShopMenu");
	register_menucmd(register_menuid("Show_PnShopMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_PnShopMenu");
	register_menucmd(register_menuid("Show_GrShopMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_GrShopMenu");
	register_menucmd(register_menuid("Show_GrShop_2Menu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_GrShop_2Menu");
	register_menucmd(register_menuid("Show_ItemsShopMenu"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_ItemsShopMenu");
	register_menucmd(register_menuid("Show_SkillsShopMenu"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_SkillsShopMenu");
	register_menucmd(register_menuid("Show_WeaponsShopMenu"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_WeaponsShopMenu");
	register_menucmd(register_menuid("Show_OthersShopMenu"), 	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_OthersShopMenu");
	
	
	#define RegisterMenu(%1,%2) 					register_menucmd(register_menuid(%1), 1023, %2)
	
	//RegisterMenu("Show_MainTransferMenu",  "Handle_MainTransferMenu");
	//RegisterMenu("Show_MenuMoneyTransfer",  "Handle_MenuMoneyTransfer");
	//RegisterMenu("Show_MoneyAmountMenu",  "Handle_MoneyAmountMenu");
	//RegisterMenu("Show_MoneyTransfer",  "Handle_MoneyTransfer");
	
	#undef RegisterMenu
	
	
	

	//register_clcmd("valyuta_transfer", "ClCmd_ZlMoneyTransfer");
	
	cvars_init();
	
	register_clcmd("say /shop", "ClCmd_ShopMenu");
	register_clcmd("shop", "ClCmd_ShopMenu");
	
	register_clcmd("buy", "ClCmd_BuyMenu");
	
	register_clcmd("drop", "ClCmd_Drop");
	
	//register_clcmd("radio1", "ClCmd_Radio1");
	register_clcmd("radio2", "ClCmd_Radio2");
	register_clcmd("radio3", "ClCmd_Radio3");

	g_iFwdDropLom = CreateMultiForward("jbe_shop_knifeweapons", ET_CONTINUE, FP_CELL) ;
	
	#if defined DEBUG
	register_clcmd("say /butt", "ClCmd_setbutt");
	#endif
	
	//RegisterHookChain(RG_CBasePlayer_Spawn, 						"HC_CBasePlayer_PlayerSpawn", 		true);
	RegisterHookChain(RG_CBasePlayer_Jump, 							"HC_CBasePlayer_PlayerJump_Post", 		true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false);
	RegisterHookChain(RG_CBasePlayer_Killed, 						"HC_CBasePlayer_PlayerKilled_Post", 	true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, 				"HC_CBasePlayer_PlayerResetMaxSpeed_Post", 	true);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, 			"CBasePlayerWeapon_DefaultDeploy_Pre", 		false);
	//RegisterHam(Ham_Item_Deploy, 				"weapon_knife", 	"Ham_KnifeDeploy_Post", 				true);

	

	

	
	RegisterHam(Ham_Weapon_PrimaryAttack, 		"weapon_knife", 	"Ham_KnifePrimaryAttack_Post", 			true);
	RegisterHam(Ham_Weapon_SecondaryAttack, 	"weapon_knife", 	"Ham_KnifeSecondaryAttack_Post", 		true);
	
	
	register_forward(FM_SetModel, 									"FakeMeta_SetModel", 					false);
	RegisterHam(Ham_Touch, 						"grenade", 			"Ham_GrenadeTouch_Post",		 		true);
	
	
	register_forward(FM_EmitSound, 									"FakeMeta_EmitSound", 					false);
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "3=1");
	
	//register_message(MsgId_Money, "Message_Money");
	//register_event("ResetHUD", "Event_ResetHUD", "be");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

public ClCmd_BuyMenu(pId)
{
	switch(jbe_get_user_team(pId))
	{
		case 1: return Show_PnShopMenu(pId);
		case 2: return Show_GrShopMenu(pId);
	}
	return PLUGIN_HANDLED;
}



public plugin_precache()
{
	LOAD_CONFIGURATION();
	
	//precache_generic("jb_engine/shop/heartbomb_exp.wav");
	//precache_generic("jb_engine/other/jihad.wav");
	
	g_iSpiteExlplosion = 	engfunc(EngFunc_PrecacheModel, 			"sprites/dexplo.spr");
	g_pSpriteBeam = 		engfunc(EngFunc_PrecacheModel, 			"sprites/333.spr");
	g_pSpriteWave = 		engfunc(EngFunc_PrecacheModel,		 	"sprites/shockwave.spr");
	g_pModelGlass = 		engfunc(EngFunc_PrecacheModel, 			"models/glassgibs.mdl");
	
	SpriteElectro = 		engfunc(EngFunc_PrecacheModel, 			"sprites/spark1.spr");
	
	engfunc(EngFunc_PrecacheSound, "jb_engine/weapons/spark.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/other/jihad.wav");
	engfunc(EngFunc_PrecacheSound, "jb_engine/shop/heartbomb_exp.wav");
}

public plugin_natives()
{
	register_native("jbe_user_clothingtype", "jbe_user_clothingtype", 1);
	register_native("jbe_is_user_clothing", "jbe_is_user_clothing", 1);
	register_native("jbe_show_shopmenu", "ClCmd_ShopMenu", 1);
	register_native("jbe_get_butt", "jbe_get_butt", 1);
	register_native("jbe_set_butt", "jbe_set_butt", 1);
	register_native("jbe_set_butt_ex", "jbe_set_butt_ex", 1);
	//register_native("jbe_get_chips", "jbe_get_chips", 1);
	//register_native("jbe_set_chips", "jbe_set_chips", 1);
	
	register_native("jbe_remove_shop_pn" , "jbe_remove_shop_pn", 1);
	register_native("jbe_has_user_weaponknife", "jbe_has_user_weaponknife", 1);
	register_native("jbe_shop_is_user_speed", "jbe_shop_is_user_speed", 1);
}


public jbe_shop_is_user_speed(id) 
{
	if(IsSetBit(g_iBitAutoBhop, id) || IsSetBit(g_iBitFastRun, id))
		return true;
	return false;
}
cvars_init()
{
	register_cvar("jbe_pn_price_item_fd", 			"12");
	register_cvar("jbe_pn_price_item_latchkey", 	"9");
	register_cvar("jbe_pn_price_item_closhing", 	"10");
	register_cvar("jbe_pn_price_item_shahid", 		"6");
	register_cvar("jbe_pn_price_item_grenade_anti", "5");
	register_cvar("jbe_pn_price_item_grenade_frost", "5");
	register_cvar("jbe_pn_price_item_grenade_gal", 	"5");
	register_cvar("jbe_pn_price_item_grenade_count", "5");
	
	register_cvar("jbe_pn_price_skills_gravity", 	"12");
	register_cvar("jbe_pn_price_skills_speed", 		"5");
	register_cvar("jbe_pn_price_skills_hp", 		"3");
	//register_cvar("jbe_pn_price_skills_ap", 		"2");
	register_cvar("jbe_pn_price_skills_bhop", 		"7");
	register_cvar("jbe_pn_price_skills_ddamage", 	"8");
	
	register_cvar("jbe_pn_price_weapon_glock", 		"8");
	register_cvar("jbe_pn_price_weapon_tmp", 		"5");
	register_cvar("jbe_pn_price_weapon_deagle", 	"4");
	register_cvar("jbe_pn_price_weapon_molot", 		"6");
	register_cvar("jbe_pn_price_weapon_benzo", 		"1");
	
	
	register_cvar("jbe_pn_price_other_micro", 		"1");
	register_cvar("jbe_pn_price_other_loto", 		"2");
	register_cvar("jbe_pn_price_other_glow", 		"3");
	register_cvar("jbe_pn_price_other_wantedsub", 	"4");
	
	register_cvar("jbe_gr_price_electro", 			"300");
	register_cvar("jbe_gr_price_inviz_hat", 		"600");
	register_cvar("jbe_gr_price_speed", 			"750");
	register_cvar("jbe_gr_price_field", 			"400");
	register_cvar("jbe_gr_price_unlimammo", 		"450");
	register_cvar("jbe_gr_price_regenhp", 			"250");
	register_cvar("jbe_gr_price_healt", 			"500");
	register_cvar("jbe_gr_price_grenade", 			"400");
	register_cvar("jbe_gr_price_godmode", 			"400");
	register_cvar("jbe_simon_price_bog_round", 			"400");
	
	register_cvar("jbe_gr_electro_time", 			"10");
	
	register_cvar("jbe_count_butt_1", 				"3200");
	register_cvar("jbe_count_butt_2", 				"9600");
	register_cvar("jbe_count_butt_3", 				"16000");
	register_cvar("jbe_gr_price_item_grenade_count" , "3");
	
	register_cvar( "jbe_jahid_radius", "300" );
	register_cvar( "jbe_jahid_damage", "200.0" );
	
	
}

public plugin_cfg()
{
	new pcvar;
	
	pcvar = create_cvar("amx_shop_rang_fd", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_FD]);						
	
	pcvar = create_cvar("amx_shop_rang_clothing", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_CLOTHING]);		
		
	pcvar = create_cvar("amx_shop_rang_latchkey", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_LATCHKEY]);
		
	pcvar = create_cvar("amx_shop_rang_shahid", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_SHAHID]);
	
	
	pcvar = create_cvar("amx_shop_rang_grenade_anti", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_GRENADE_ANTI]);
	
	pcvar = create_cvar("amx_shop_rang_grenade_frost", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_GRENADE_FROST]);
	
	pcvar = create_cvar("amx_shop_rang_grenade_gal", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[ITEMS_GRENADE_GAL]);

	pcvar = create_cvar("amx_shop_rang_gravity", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_GRAVITY]);
	
	pcvar = create_cvar("amx_shop_rang_speed", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_SPEED]);
	
	pcvar = create_cvar("amx_shop_rang_hp", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_HP]);
	
	//pcvar = create_cvar("amx_shop_rang_ap", "0", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_AP]);
	
	pcvar = create_cvar("amx_shop_rang_bhop", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_BHOP]);
	
	pcvar = create_cvar("amx_shop_rang_ddamage", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SKILLS_DDAMAGE]);
	
	//pcvar = create_cvar("amx_shop_rang_glock", "0", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iCvarStats[WEAPONS_GLOCK18]);
	
	//pcvar = create_cvar("amx_shop_rang_tmp", "0", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iCvarStats[WEAPONS_TMP]);
	
	//pcvar = create_cvar("amx_shop_rang_deagle", "0", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iCvarStats[WEAPONS_DEAGLE]);
	
	pcvar = create_cvar("amx_shop_rang_molot", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[WEAPONS_MOLOT]);
	
	pcvar = create_cvar("amx_shop_rang_benz", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[WEAPONS_BENZ]);
	//////////////
	pcvar = create_cvar("amx_shop_rang_micro", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[OTHER_MICRO]);
	
	pcvar = create_cvar("amx_shop_rang_loto", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[OTHER_LOTO]);
	
	pcvar = create_cvar("amx_shop_rang_randomglow", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[OTHER_RANDOMGLOW]);
	
	pcvar = create_cvar("amx_shop_rang_wantedsub", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[OTHER_WANTEDSUB]);
	/////////////
	pcvar = create_cvar("amx_shop_rang_ct_electro", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_ELECTRO]);
	
	pcvar = create_cvar("amx_shop_rang_ct_forma", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_FORMA]);
	
	pcvar = create_cvar("amx_shop_rang_ct_speed", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_SPEED]);
	
	pcvar = create_cvar("amx_shop_rang_ct_field", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_FIELD]);
	
	pcvar = create_cvar("amx_shop_rang_ct_health", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_HEALT]);
	
	pcvar = create_cvar("amx_shop_rang_ct_unlimammo", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_UNLIMAM]);
	
	pcvar = create_cvar("amx_shop_rang_ct_regen", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_REGEN]);
	
	pcvar = create_cvar("amx_shop_rang_ct_grena", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_GRENA]);
	
	pcvar = create_cvar("amx_shop_rang_ct_godmoe", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iCvarStats[SHOP_CT_GODMODE]);
	
	pcvar = create_cvar("jbe_pn_price_item_fd", "12", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_FD]);				
	
	pcvar = create_cvar("jbe_pn_price_item_latchkey", "9", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_LATCHKEY]);	

	pcvar = create_cvar("jbe_pn_price_item_closhing", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_CLOTHING]);	
	
	pcvar = create_cvar("jbe_pn_price_item_shahid", "6", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_SHAHID]);	

	pcvar = create_cvar("jbe_jahid_radius", "300.0", FCVAR_SERVER, "");
	bind_pcvar_float(pcvar, Float:g_iShopCvars[ITEMS_SHAHID_RADIUS]);	
	
	pcvar = create_cvar("jbe_jahid_damage", "200.0", FCVAR_SERVER, "");
	bind_pcvar_float(pcvar, Float:g_iShopCvars[ITEMS_SHAHID_DAMAGE]);	
	
	pcvar = create_cvar("jbe_pn_price_item_grenade_anti", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_GRENADE_ANTI]);	
	
	pcvar = create_cvar("jbe_pn_price_item_grenade_frost", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_GRENADE_FROST]);
	
	pcvar = create_cvar("jbe_pn_price_item_grenade_gal", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_GRENADE_GAL]);	
	
	pcvar = create_cvar("jbe_pn_price_item_grenade_count", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_GRENADE_COUNT]);
	
	pcvar = create_cvar("jbe_pn_price_skills_gravity", "12", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_GRAVITY]);		
	
	pcvar = create_cvar("jbe_pn_price_skills_speed", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_SPEED]);			
	
	pcvar = create_cvar("jbe_pn_price_skills_hp", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_HP]);			
	
	//pcvar = create_cvar("jbe_pn_price_skills_ap", "2", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_AP]);			
	
	pcvar = create_cvar("jbe_pn_price_skills_bhop", "7", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_BHOP]);			
	
	pcvar = create_cvar("jbe_pn_price_skills_ddamage", "8", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SKILLS_DDAMAGE]);		
	
	
	//pcvar = create_cvar("jbe_pn_price_weapon_glock", "8", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iShopCvars[WEAPONS_GLOCK18]);		
	
	//pcvar = create_cvar("jbe_pn_price_weapon_tmp", "5", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iShopCvars[WEAPONS_TMP]);			
	
	//pcvar = create_cvar("jbe_pn_price_weapon_deagle", "4", FCVAR_SERVER, "");
	//bind_pcvar_num(pcvar, g_iShopCvars[WEAPONS_DEAGLE]);		
	
	pcvar = create_cvar("jbe_pn_price_weapon_molot", "6", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[WEAPONS_MOLOT]);		
	
	pcvar = create_cvar("jbe_pn_price_weapon_benzo", "1", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[WEAPONS_BENZ]);			
	
	pcvar = create_cvar("jbe_pn_price_other_micro", "1", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[OTHER_MICRO]);			
	
	pcvar = create_cvar("jbe_pn_price_other_loto", "2", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[OTHER_LOTO]);			
	
	pcvar = create_cvar("jbe_pn_price_other_glow", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[OTHER_RANDOMGLOW]);		
	
	pcvar = create_cvar("jbe_pn_price_other_wantedsub", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[OTHER_WANTEDSUB]);		
	
	
	pcvar = create_cvar("jbe_gr_price_electro", "12", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_ELECTRO]);		
	
	pcvar = create_cvar("jbe_gr_price_inviz_hat", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_FORMA]);		
	
	pcvar = create_cvar("jbe_gr_price_speed", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_SPEED]);		
	
	pcvar = create_cvar("jbe_gr_price_field", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_FIELD]);		
	
	pcvar = create_cvar("jbe_gr_price_healt", "7", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_HEALT]);		
	
	pcvar = create_cvar("jbe_gr_price_unlimammo", "8", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_UNLIMAM]);		
	
	pcvar = create_cvar("jbe_gr_price_regenhp", "5", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_REGEN]);		
	
	pcvar = create_cvar("jbe_gr_price_grenade", "4", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_GRENA]);		
	
	pcvar = create_cvar("jbe_gr_price_godmode", "15", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_GODMODE]);		
	
	pcvar = create_cvar("jbe_simon_price_bog_round", "20", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SIMON_SHOP_BOG_ROUND]);	
	
	
	
	pcvar = create_cvar("jbe_gr_electro_time", "10", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[SHOP_CT_ELECTROTIME]);		
	
	pcvar = create_cvar("jbe_gr_price_item_grenade_count", "3", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iShopCvars[ITEMS_GRENADE_COUNT_GR]);
	
	
	
	pcvar = create_cvar("jbe_quest_shahid", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestShahid);	
	
	pcvar = create_cvar("jbe_quest_mazhor", "0", FCVAR_SERVER, "");
	bind_pcvar_num(pcvar, g_iQuestMazhor);	
	
	//AutoExecConfig();
	AutoExecConfig(true, "Jail_Shop_Price");
	

}



enum
{
	SND_MOLOT_DEPLOY = 1,
	SND_MOLOT_HITWALL,
	SND_MOLOT_SLASH,
	SND_MOLOT_STAB,
	SND_MOLOT_HIT,
	SND_SAW_DEPLOY,
	SND_SAW_HITWALL,
	SND_SAW_SLASH,
	SND_SAW_STAB,
	SND_SAW_HIT,
	SND_ELECTRO_DEPLOY,
	SND_ELECTRO_HITWALL,
	SND_ELECTRO_SLASH,
	SND_ELECTRO_STAB,
	SND_ELECTRO_HIT
};

enum _:SOUND_HAND
{
	MOLOT_DEPLOY = 1,
	MOLOT_HITWALL,
	MOLOT_SLASH,
	MOLOT_STAB,
	MOLOT_HIT,
	SAW_DEPLOY,
	SAW_HITWALL,
	SAW_SLASH,
	SAW_STAB,
	SAW_HIT,
	ELECTRO_DEPLOY,
	ELECTRO_HITWALL,
	ELECTRO_SLASH,
	ELECTRO_STAB,
	ELECTRO_HIT
};

new g_szKnifeSound[SOUND_HAND][64];

enum
{
	MOLOT_P = 1,
	MOLOT_V,
	SAW_P,
	SAW_V,
	ELECTRO_P,
	ELECTRO_V
};

enum _:PLAYER_HAND
{
	MDL_MOLOT_P = 1,
	MDL_MOLOT_V,
	MDL_SAW_P,
	MDL_SAW_V,
	MDL_ELECTRO_P,
	MDL_ELECTRO_V
};

new g_szPlayerHand[PLAYER_HAND][64];

enum
{
	SELECT_SOUND = 1,
	SELECT_MODELS
};



LOAD_CONFIGURATION()
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
// CONFIG.INI
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/shop_config.ini", szCfgDir);
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
			case SELECT_SOUND:
			{
				if(equal(szKey, 		"SND_MOLOT_DEPLOY"))		copy(g_szKnifeSound[MOLOT_DEPLOY], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_MOLOT_HITWALL")) 		copy(g_szKnifeSound[MOLOT_HITWALL], 		charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_MOLOT_SLASH")) 		copy(g_szKnifeSound[MOLOT_SLASH], 			charsmax(g_szKnifeSound[]), szValue);		
				else if(equal(szKey, 	"SND_MOLOT_STAB")) 			copy(g_szKnifeSound[MOLOT_STAB], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_MOLOT_HIT")) 			copy(g_szKnifeSound[MOLOT_HIT], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_DEPLOY")) 			copy(g_szKnifeSound[SAW_DEPLOY], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_HITWALL")) 		copy(g_szKnifeSound[SAW_HITWALL], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_SLASH")) 			copy(g_szKnifeSound[SAW_SLASH], 			charsmax(g_szKnifeSound[]), szValue);		
				else if(equal(szKey, 	"SND_SAW_STAB")) 			copy(g_szKnifeSound[SAW_STAB], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_SAW_HIT")) 			copy(g_szKnifeSound[SAW_HIT], 				charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_ELECTRO_DEPLOY")) 		copy(g_szKnifeSound[ELECTRO_DEPLOY], 		charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_ELECTRO_HITWALL")) 	copy(g_szKnifeSound[ELECTRO_HITWALL], 		charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_ELECTRO_SLASH")) 		copy(g_szKnifeSound[ELECTRO_SLASH], 		charsmax(g_szKnifeSound[]), szValue);		
				else if(equal(szKey, 	"SND_ELECTRO_STAB")) 		copy(g_szKnifeSound[ELECTRO_STAB], 			charsmax(g_szKnifeSound[]), szValue);
				else if(equal(szKey, 	"SND_ELECTRO_HIT")) 		copy(g_szKnifeSound[ELECTRO_HIT], 			charsmax(g_szKnifeSound[]), szValue);
			}
			case SELECT_MODELS:
			{
				if(equal(szKey, 		"MDL_MOLOT_P"))				copy(g_szPlayerHand[MOLOT_P], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_MOLOT_V"))				copy(g_szPlayerHand[MOLOT_V], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_SAW_P"))				copy(g_szPlayerHand[SAW_P], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_SAW_V"))				copy(g_szPlayerHand[SAW_V], 		charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_ELECTRO_P"))			copy(g_szPlayerHand[ELECTRO_P], 	charsmax(g_szPlayerHand[]), szValue);
				else if(equal(szKey, 	"MDL_ELECTRO_V"))			copy(g_szPlayerHand[ELECTRO_V], 	charsmax(g_szPlayerHand[]), szValue);
			}
		}
	}
	fclose(iFile);

	PRECACHE_MODELS();
}



PRECACHE_MODELS()
{
	new i, szBuffer[64];
	for(i = 0; i < sizeof(g_szKnifeSound); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szKnifeSound[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	for(i = 0; i < sizeof(g_szPlayerHand); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szPlayerHand[i]);
		engfunc(EngFunc_PrecacheModel, szBuffer);
	}
}

public plugin_end() 
{

	DestroyForward(g_iFwdDropLom);
}


public Message_Money() return PLUGIN_HANDLED;

public Event_ResetHUD(pId)
{
	if(!jbe_is_user_connected(pId) && jbe_restartgame()) return;
	
	if(!task_exists(pId + TASK_RESETHUD))
		set_task_ex(1.0, "Event_ResetHUD_ex", pId + TASK_RESETHUD);
}

public Event_ResetHUD_ex(pId)
{
	pId -= TASK_RESETHUD;
	
	if(!jbe_is_user_connected(pId) && jbe_get_user_team(pId) == 3) return;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] Event_ResetHUD");
	}
	
	//server_print("fdsfdsfds");
	
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_Money, _, pId);
	write_long(g_iButt[pId]);
	write_byte(0);
	message_end();
}


public jbe_set_butt(pId, iNum) 
{
	
		new Money = iNum - g_iButt[pId];
	
	
	g_iButt[pId] = iNum;
	
	if(is_user_bot(pId)) return;
	
	if(jbe_is_user_connected(pId))
	{
		if(g_iGlobalDebug)
		{
			
			log_to_file("globaldebug.log", "[SHOP_ADDONS] MsgId_Money, %n | %d", pId, Money);
		}
		/*engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_Money, {0.0, 0.0, 0.0}, pId);
		write_long(iNum);
		write_byte(1);
		message_end();*/
	
		rg_add_account(pId, iNum, AS_SET);
	}
}
public jbe_get_butt(pId) return g_iButt[pId];

public jbe_set_butt_ex(pId, iNum) 
{
	g_iButt[pId] = iNum;
	
	if(is_user_bot(pId)) return;
	
	if(jbe_is_user_connected(pId))
	{
		/*if(g_iGlobalDebug)
		{
			new Money = iNum - g_iButt[pId];
			log_to_file("globaldebug.log", "[SHOP_ADDONS] MsgId_Money_ex, %n | %d", pId, Money);
		}
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_Money, {0.0, 0.0, 0.0}, pId);
		write_long(iNum);
		write_byte(0);
		message_end();*/
	
		rg_add_account(pId, iNum, AS_SET);
	}
}

//public jbe_set_chips(pId, iNum) g_iButt[pId] = iNum;
//public jbe_get_chips(pId) return g_iButt[pId];

public jbe_user_clothingtype(pId) return IsSetBit(g_iBitClothingType, pId);
public jbe_is_user_clothing(pId) return IsSetBit(g_iBitClothingGuard, pId);
public jbe_has_user_weaponknife(pId) 
{
	if(IsSetBit(g_iBitWeaponStatus,pId) || IsSetBit(g_iBitUserElectroShoker,pId))
		return true;
	return false;
}

public client_disconnected(pId)
{
	if(!is_user_connected(pId)) return;
	
	ClearBit(g_iBitFastRun, pId);
	ClearBit(g_iBitAutoBhop, pId);
	ClearBit(g_iBitDoubleDamage, pId);
	ClearBit(g_iBitClothingGuard, pId);
	ClearBit(g_iBitClothingType, pId);
	ClearBit(g_iBitLotteryTicket, pId);
	ClearBit(g_iBitRandomGlow, pId);
	ClearBit(g_iBitLatchkey, pId);
	ClearBit(g_gUserForJihad, pId);
	ClearBit(g_iBitUserJihadUsed, pId);
	
	ClearBit(g_iBitUserHasHE, pId);
	ClearBit(g_iBitUserHasSM, pId);
	ClearBit(g_iBitUserHasFL, pId);
	
	ClearBit(g_iBitUserHasUsp, pId);
	ClearBit(g_iBitUserHasTMP, pId);
	ClearBit(g_iBitUserHasDeagle, pId);
	
	ClearBit(g_iBitUserMolot, pId);
	ClearBit(g_iBitUserSaw, pId);
	ClearBit(g_iBitWeaponStatus, pId);
	
	ClearBit(g_iBitAntiGravity, pId);
	ClearBit(g_iBitUserAntiGravity, pId);
	
	if(task_exists(pId+TASK_ANTIGRAVITY)) remove_task(pId+TASK_ANTIGRAVITY);
	if(task_exists(pId+TASK_FROSTNADE_DEFROST)) remove_task(pId+TASK_FROSTNADE_DEFROST);
	if(task_exists(pId+TASK_GALOGRAMMA_DE)) remove_task(pId+TASK_GALOGRAMMA_DE);
	
	ClearBit(g_iBitFrostNade, pId);
	ClearBit(g_iBitUserFrozen, pId);
	
	ClearBit(g_iBitGalogramma, pId);
	ClearBit(g_iBitUserGalogramma, pId);
	
	ClearBit(g_iBitUserElectroShoker, pId);
	ClearBit(g_iBitUserShopModel,pId);
	ClearBit(g_iBitUserShopDamageReduce,pId);
	ClearBit(g_iBitUserUnlimAmmo,pId);
	ClearBit(g_iBitRemoveGun, pId);
	
	if(task_exists(pId + TASK_REGEN_HP)) remove_task(pId + TASK_REGEN_HP);
	
	
	ClearBit(g_iBitUserHealt , pId);
	ClearBit(g_iBitUserArmor, pId);
	
	g_iSimonShopBog[pId] = 0;
	
	
	
}

forward jbe_fwr_event_hltv();
public jbe_fwr_event_hltv()
{
	g_iBitFastRun = 0;
	g_iBitAutoBhop = 0;
	g_iBitDoubleDamage = 0;
	g_iBitClothingGuard = 0;
	g_iBitClothingType = 0;
	g_iBitLotteryTicket = 0;
	g_iBitRandomGlow = 0;
	g_iBitLatchkey = 0;
	g_gUserForJihad = 0;
	g_iBitUserJihadUsed = 0;
	
	g_iBitUserHasHE = 0;
	g_iBitUserHasFL = 0;
	g_iBitUserHasSM = 0;
	
	g_iBitUserHasUsp = 0;
	g_iBitUserHasTMP = 0;
	g_iBitUserHasDeagle = 0;
	
	g_iBitUserMolot = 0;
	g_iBitUserSaw = 0;
	g_iBitWeaponStatus = 0;
	
	g_iBitAntiGravity = 0;
	g_iBitUserAntiGravity = 0;
	
	g_iBitGalogramma = 0;
	g_iBitFrostNade = 0;
	
	g_iBitUserFrozen = 0;
	g_iBitUserGalogramma = 0;
	
	g_iBitUserElectroShoker = 0;
	g_iBitUserShopModel = 0;
	g_iBitUserShopDamageReduce = 0;
	g_iBitUserUnlimAmmo = 0;
	
	g_iBitUserArmor = 0;
	g_iBitUserHealt = 0;
	
	g_iBitUserFree = 0;
	
	g_iBitRemoveGun = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i)) continue;
		
		if(task_exists(i + TASK_REGEN_HP)) remove_task(i + TASK_REGEN_HP);
		if(jbe_get_user_team(i) == 2)
		{
			g_iSimonShopBog[i]++;
		}
		if(jbe_get_user_team(i) != 1) continue;
		
		g_iUserGravity[i]++;
		g_iUserDoubleDamage[i]++;
	}
	
	g_iShopCvars[ITEMS_GRENADE_COUNT]	= get_cvar_num("jbe_pn_price_item_grenade_count");
}

#if defined DEBUG
public ClCmd_setbutt(pId) g_iButt[pId] = 500;
#endif

public ClCmd_ShopMenu(pId) 
{
	if(jbe_get_soccergame()) UTIL_SayText(pId, "!g* !yВключен футбол, магазин запрещен");
	else if(jbe_is_user_duel(pId)) UTIL_SayText(pId, "!g* !yВы дуэлянт, магазин запрещен");
	else if(jbe_get_day_mode() == 3) return PLUGIN_HANDLED;
	else 
	{
		switch(jbe_get_user_team(pId))
		{
			case 1: return Show_PnShopMenu(pId);
			case 2: return Show_GrShopMenu(pId);
		}
	}
	return PLUGIN_HANDLED;
}



public HC_CBasePlayer_PlayerKilled_Post(iVictim, iKiller)
{
	if(!is_user_alive(iVictim)) return;
	
	if(jbe_get_day_mode() == 1 ||jbe_get_day_mode() == 2)
	{

			ClearBit(g_iBitClothingGuard, iVictim);
			ClearBit(g_iBitClothingType, iVictim);
			ClearBit(g_iBitAutoBhop, iVictim);
			
			ClearBit(g_iBitDoubleDamage, iVictim);
			ClearBit(g_iBitLatchkey, iVictim);
			ClearBit(g_gUserForJihad, iVictim);
			ClearBit(g_iBitUserJihadUsed, iVictim);
			ClearBit(g_iBitUserHasHE, iVictim);
			ClearBit(g_iBitUserHasUsp, iVictim);
			ClearBit(g_iBitUserHasTMP, iVictim);
			ClearBit(g_iBitUserHasDeagle, iVictim);
			
			ClearBit(g_iBitUserMolot, iVictim);
			ClearBit(g_iBitUserSaw, iVictim);
			ClearBit(g_iBitWeaponStatus, iVictim);
			
			ClearBit(g_iBitAntiGravity, iVictim);
			ClearBit(g_iBitFrostNade, iVictim);
			ClearBit(g_iBitGalogramma, iVictim);
			
			if(IsSetBit(g_iBitUserAntiGravity, iVictim))
			{
				ClearBit(g_iBitUserAntiGravity, iVictim);
				if(task_exists(iVictim+TASK_ANTIGRAVITY)) remove_task(iVictim+TASK_ANTIGRAVITY);
			}
			
			if(IsSetBit(g_iBitUserFrozen, iVictim))
			{
				ClearBit(g_iBitUserFrozen, iVictim);
				if(task_exists(iVictim+TASK_FROSTNADE_DEFROST)) remove_task(iVictim+TASK_FROSTNADE_DEFROST);
			}
			
			if(IsSetBit(g_iBitUserGalogramma, iVictim))
			{
				ClearBit(g_iBitUserGalogramma, iVictim);
				if(task_exists(iVictim+TASK_GALOGRAMMA_DE)) remove_task(iVictim+TASK_GALOGRAMMA_DE);
			}
		
		if(IsSetBit(g_iBitUserElectroShoker, iVictim)) ClearBit(g_iBitUserElectroShoker, iVictim);
		if(IsSetBit(g_iBitUserShopModel, iVictim)) ClearBit(g_iBitUserShopModel, iVictim);
		if(IsSetBit(g_iBitFastRun, iVictim)) ClearBit(g_iBitFastRun, iVictim);
		if(IsSetBit(g_iBitUserShopDamageReduce, iVictim)) ClearBit(g_iBitUserShopDamageReduce, iVictim);
		if(IsSetBit(g_iBitUserUnlimAmmo, iVictim)) ClearBit(g_iBitUserUnlimAmmo,iVictim);
		if(IsSetBit(g_iBitRemoveGun, iVictim)) ClearBit(g_iBitRemoveGun, iVictim);
		if(task_exists(iVictim + TASK_REGEN_HP)) remove_task(iVictim + TASK_REGEN_HP);
		
		
	}
	
}

public jbe_lr_duels()
{
	g_iBitFastRun = 0;
	g_iBitAutoBhop = 0;
	g_iBitDoubleDamage = 0;
	g_iBitClothingGuard = 0;
	g_iBitClothingType = 0;
	g_iBitLotteryTicket = 0;
	g_iBitRandomGlow = 0;
	g_iBitLatchkey = 0;
	g_gUserForJihad = 0;
	g_iBitUserJihadUsed = 0;
	
	g_iBitUserHasHE = 0;
	g_iBitUserHasFL = 0;
	g_iBitUserHasSM = 0;
	
	g_iBitUserHasUsp = 0;
	g_iBitUserHasTMP = 0;
	g_iBitUserHasDeagle = 0;
	
	g_iBitUserMolot = 0;
	g_iBitUserSaw = 0;
	g_iBitWeaponStatus = 0;
	
	g_iBitAntiGravity = 0;
	g_iBitUserAntiGravity = 0;
	
	g_iBitGalogramma = 0;
	g_iBitFrostNade = 0;
	
	g_iBitUserFrozen = 0;
	g_iBitUserGalogramma = 0;
	
	g_iBitUserElectroShoker = 0;
	g_iBitUserShopModel = 0;
	g_iBitUserShopDamageReduce = 0;
	g_iBitUserUnlimAmmo = 0;
	
	g_iBitUserArmor = 0;
	g_iBitUserHealt = 0;
	
	g_iBitRemoveGun = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i)) continue;
		
		if(task_exists(i + TASK_REGEN_HP)) remove_task(i + TASK_REGEN_HP);
	}
}

public client_putinserver(pId)
{
	g_iUserGravity[pId] = 2;
	g_iUserDoubleDamage[pId] = 4;
}
public HC_CBasePlayer_PlayerJump_Post(pId)
{
	if((jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2) && (!jbe_is_user_duel(pId) || !jbe_get_soccergame()))
	{
		if(IsSetBit(g_iBitAutoBhop, pId) && get_entvar(pId, var_flags) & (FL_ONGROUND|FL_CONVEYOR))
		{
			new Float:vecVelocity[3];
			get_entvar(pId, var_velocity, vecVelocity);
			vecVelocity[2] = 250.0;
			set_entvar(pId, var_velocity, vecVelocity);
			set_entvar(pId, var_gaitsequence, 6);
		}
	}
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker))
	{
		new Float:fDamageOld = fDamage;
		if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
		{
			if(g_iBitDoubleDamage && IsSetBit(g_iBitDoubleDamage, iAttacker)) fDamage = (fDamage * 2.0);
			if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, iAttacker) && get_user_weapon(iAttacker) == CSW_KNIFE)
			{
				if(IsSetBit(g_iBitUserMolot, iAttacker)) fDamage = (fDamage * 1.2);
				if(IsSetBit(g_iBitUserSaw, iAttacker)) fDamage = (fDamage * 1.5);
			}
			if(get_user_weapon(iAttacker) == CSW_KNIFE && IsSetBit(g_iBitUserElectroShoker, iAttacker) && jbe_get_user_team(iVictim) == 1 && !jbe_iduel_status())
			{
				
				fCurTime[iVictim] = get_gametime();
				
				/*new Float:originF[3], originF2[3];
				get_entvar(iVictim, var_origin, originF);
				get_user_origin(iVictim, originF2);*/
				
				//electro_ring(originF);
				//electro_sound(originF2);
				
				if(fNextTime[iVictim] >= fCurTime[iVictim] && fCurTime[iVictim] > 0.0)
				{
					new number[15];

					new szTime = (floatround(fNextTime[iVictim]) - floatround(fCurTime[iVictim]));
					get_ending(szTime, "секунд", "секунда", "секунды", charsmax(number), number);
					CenterMsgFix_PrintMsg(iAttacker, print_center, "Эектро-шок для данного игрока перезарядиться через %i %s", szTime, number);
					return HC_CONTINUE;
				}

				if(!get_frozen_status(iVictim))
				{	
					set_frozen_status(iVictim);
					set_task(4.0, "delete_froze", iVictim + TASK_FREEZE);
					fNextTime[iVictim] = fCurTime[iVictim] + g_iShopCvars[SHOP_CT_ELECTROTIME];
				}
				
				SetHookChainArg(3,ATYPE_FLOAT, 5.0);
				
				return HC_CONTINUE;
			}
			if(IsSetBit(g_iBitUserShopDamageReduce, iVictim) && jbe_get_user_team(iVictim) == 2) fDamage = (fDamage * 0.5);
		}
		
		if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
	}
	return HC_CONTINUE;
}

public HC_CBasePlayer_PlayerResetMaxSpeed_Post(pId)
{
	if(jbe_get_day_mode() == 3)
		return HC_CONTINUE;
	
	if(IsSetBit(g_iBitFastRun, pId))
		set_entvar(pId, var_maxspeed, CVAR_SPEED);

	return HC_CONTINUE;
}


public delete_froze(tid)
{
	new id = tid - TASK_FREEZE;
	if (is_user_connected(id) && get_frozen_status(id))
	{
		set_frozen_status(id);
	}
}

public electro_sound(idOrigin[3])
{
	new Entity = rg_create_entity("info_target");
	new Float:origin[3];
	IVecFVec(idOrigin, origin);
	entity_set_origin(Entity, origin);
	emit_sound(Entity, CHAN_WEAPON, "jb_engine/weapons/spark.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	remove_entity(Entity);
}

public electro_ring(const Float:originF3[3])
{

	
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
	new id = get_member(iEntity, m_pPlayer);
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id))
	{
		if(IsSetBit(g_iBitUserMolot, id)) set_member(id, m_flNextAttack, 0.9);
		if(IsSetBit(g_iBitUserSaw, id)) set_member(id, m_flNextAttack, 1.1);
		return;
	}
}
public Ham_KnifeSecondaryAttack_Post(iEntity)
{
	new id = get_member(iEntity, m_pPlayer);
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id))
	{
		if(IsSetBit(g_iBitUserMolot, id)) set_member(id, m_flNextAttack, 1.2);
		if(IsSetBit(g_iBitUserSaw, id)) set_member(id, m_flNextAttack, 1.5);
		return;
	}

}

public ClCmd_Radio1(pId)
{
	if(jbe_get_user_team(pId) == 1 && IsSetBit(g_iBitClothingGuard, pId))
	{
		if(jbe_get_soccergame() /*|| jbe_is_user_boxing(pId)*/) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_BLOCKED_CLOTHING_GUARD");
		else
		{
			if(IsSetBit(g_iBitClothingType, pId))
			{
				jbe_set_user_clothingtype(pId, 1);
				UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_REMOVE_CLOTHING_GUARD");
			}
			else
			{
				jbe_set_user_clothingtype(pId, 2);
				UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_DRESSED_CLOTHING_GUARD");
			}
			InvertBit(g_iBitClothingType, pId);
		}
	}
	return PLUGIN_HANDLED;
	
	
}

public ClCmd_Drop(pId)
{
	if(IsSetBit(g_gUserForJihad, pId) && IsNotSetBit(g_iBitUserJihadUsed, pId) && jbe_get_user_team(pId) == 1 && jbe_is_user_alive(pId))
	{
		emit_sound(pId, CHAN_AUTO, "jb_engine/other/jihad.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_task_ex(2.0, "explos", pId);
		Effects_one(pId);
		UTIL_ScreenShake(pId, (1<<15), (1<<14), (1<<15));
		rg_send_bartime(pId, floatround(2.0), false);
		jbe_add_user_wanted(pId);
		SetBit(g_iBitUserJihadUsed, pId);
		if(jbe_playersnum(1) >= 5 && get_login(pId))
		{
			if(jbe_mysql_stats_systems_get(pId, 76) <= g_iQuestShahid)
			{
				jbe_mysql_stats_systems_add(pId, 76, jbe_mysql_stats_systems_get(pId, 76) + 1); 
			}
		}else UTIL_SayText(pId, "!g* !yКвест Шахида не засчитан, мало зека");
	}
	return PLUGIN_CONTINUE;
}

/*public Show_MainShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("Магазин:^n^n");
	
	if(jbe_is_user_alive(pId) && (jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2) && !jbe_is_user_duel(pId))
	{
		FormatItem("\y1. \wДля Заключенных^n"), iKeys |= 1<<0;
		FormatItem("\y2. \wДля Охраны^n^n"), iKeys |= 1<<1;
	}else
	{
		FormatItem("\y1. \dДля Заключенных^n");
		FormatItem("\y2. \dДля Охраны^n^n");
	}
	
	FormatItem("\y3. \wОбменный пункт^n"), iKeys |= 1<<2;

	if(jbe_is_user_alive(pId) && !jbe_is_user_wanted(pId) && !jbe_is_user_free(pId) && jbe_get_day_mode() < 3)
	{
		FormatItem("\y4. \rСбросить магазин^n"), iKeys |= 1<<3;
	}else FormatItem("\y4. \dСбросить магазин^n");
	
	FormatItem("^n\y9. \wНазад^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_MainShopMenu");
}

public Handle_MainShopMenu(pId, iKey)
{

	switch(iKey)
	{
		case 0: 
		{
			if(is_enable())
			{
				UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
				return PLUGIN_HANDLED;
			}
			if(jbe_globalnyizapret())
			{
				UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
				return PLUGIN_HANDLED;
			}
			return Show_PnShopMenu(pId);
		}
		case 1: 
		{
			if(is_enable())
			{
				UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
				return PLUGIN_HANDLED;
			}
			if(jbe_globalnyizapret())
			{
				UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
				return PLUGIN_HANDLED;
			}
			return Show_GrShopMenu(pId);
		}
		
	case 2: 
		{
			if(jbe_playersnum(1) > 5 || jbe_playersnum(2) != 0)
			{
				return Show_MainTransferMenu(pId);
			}
			else 
			{
				UTIL_SayText(pId, "!g* !yМало зеков или за охраны нет играющих!");
				return PLUGIN_HANDLED;
			}
			return Show_MainTransferMenu(pId);
		}
		case 3:
		{
			if(jbe_is_user_alive(pId) && !jbe_is_user_wanted(pId) && !jbe_is_user_free(pId) && jbe_get_day_mode() < 3)
			//if(g_iUserTeam[Players] == 1 && IsSetBit(g_iBitUserAlive, Players) && IsNotSetBit(g_iBitUserFree, Players) && IsNotSetBit(g_iBitUserWanted, Players))
			{
				jbe_remove_shop_pn(pId);
				set_entvar(pId, var_gravity, 1.0);
				rg_reset_maxspeed(pId);
				//set_entvar(pId, var_maxspeed, 250.0);
				//set_entvar(pId, var_health, 100.0);

				jbe_set_user_rendering(pId, kRenderFxGlowShell,0,0,0,kRenderNormal,25);
				UTIL_SayText(pId, "!g* !yВы !yзабрали с себя !gмагазины !y(гравитация, скорость и тп.)");
				static Float: fCurTime[MAX_PLAYERS + 1], Float: fNextTime[MAX_PLAYERS + 1]; fCurTime[pId] = get_gametime();
				if(fNextTime[pId] <= fCurTime[pId])
				{
					UTIL_SayText(0, "!g* !y%s !g%n !yзабрал с себя !gмагазины !y(гравитация, скорость и тп.)",jbe_get_user_team(pId) ? "Заключенный" : "Охрана", pId);
					fNextTime[pId] = (fCurTime[pId] + 5.0);
				}
			}
		
		
		}

		case 8: return jbe_show_mainmenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainShopMenu(pId);
}

Show_MainTransferMenu(pId)
{
	new szMenu[512], iKeys = (1<<9), iLen;
	
	FormatMain("\yОбменный пункт:^nУ вас: %d бчк. и %d бчк.^n^n", g_iButt[pId], g_iButt[pId]);
	
	FormatItem("\y1. \wПередать бычки/бчкы^n^n"), iKeys |= 1<<0;
	

	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_1])
	{
		FormatItem("\y2. \wОбмен: \y%d$ на 1 бычок^n", g_iTransferMoneyBut[MONEY_1]), iKeys |= 1<<1;
	}else FormatItem("\y2. \dОбмен: %d$ на 1 бычок^n", g_iTransferMoneyBut[MONEY_1]);
	
	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_2])
	{
		FormatItem("\y3. \wОбмен: \y%d$ на 3 бычка^n",g_iTransferMoneyBut[MONEY_2]), iKeys |= 1<<2;
	}else FormatItem("\y3. \dОбмен: %d$ на 3 бычка^n",g_iTransferMoneyBut[MONEY_2]);
	
	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_3])
	{
		FormatItem("\y4. \wОбмен: \y%d$ на 5 бчк.^n",g_iTransferMoneyBut[MONEY_3]), iKeys |= 1<<3;
	}else FormatItem("\y4. \dОбмен: %d$ на 5 бчк.^n^n",g_iTransferMoneyBut[MONEY_3]);
	

	
	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_1])
	{
		FormatItem("\y5. \wОбмен: \y%d$ на 1 бчк^n", g_iTransferMoneyBut[MONEY_1]), iKeys |= 1<<4;
	}else FormatItem("\y5. \dОбмен: %d$ на 1 бчк^n", g_iTransferMoneyBut[MONEY_1]);
	
	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_2])
	{
		FormatItem("\y6. \wОбмен: \y%d$ на 3 бчка^n",g_iTransferMoneyBut[MONEY_2]), iKeys |= 1<<5;
	}else FormatItem("\y6. \dОбмен: %d$ на 3 бчка^n",g_iTransferMoneyBut[MONEY_2]);
	
	if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_3])
	{
		FormatItem("\y7. \wОбмен: \y%d$ на 5 бчк.^n",g_iTransferMoneyBut[MONEY_3]), iKeys |= 1<<6;
	}else FormatItem("\y7. \dОбмен: %d$ на 5 бчк.^n^n",g_iTransferMoneyBut[MONEY_3]);
	
	if(g_iButt[pId]) FormatItem("\y8. \wКонверт: \y1Бычок на 1бчк^n"), iKeys |= 1<<7;
	else FormatItem("\y8. \dКонверт: \y1Бычок на 1бчк^n");
	
	if(g_iButt[pId]) FormatItem("\y9. \wКонверт: \y1бчк на 1Бычок^n"), iKeys |= 1<<8;
	else FormatItem("\y9. \dКонверт: 1бчк на 1Бычок^n");

	
	FormatItem("^n\y0. \wНазад");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_MainTransferMenu");
}

public Handle_MainTransferMenu(pId, iKey)
{
	if(!get_login(pId))
	{
		UTIL_SayText(pId, "!g* !yТребуется авторизациии. !gsay /reg");
		return Show_MainTransferMenu(pId);
	}
	switch(iKey)
	{
		case 0: return Cmd_MoneyTransferMenu(pId);
		case 1: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_1])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_1], 1);
				jbe_set_butt(pId, g_iButt[pId] + 1);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g1 !yбычок.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_1], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		case 2: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_2])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_2], 1);
				jbe_set_butt(pId, g_iButt[pId] + 3);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g3 !yбычки.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_2], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		case 3: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_3])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_3], 1);
				jbe_set_butt(pId, g_iButt[pId] + 5);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g5 !yбычки.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_3], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		
		
		case 4: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_1])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_1], 1);
				jbe_set_butt(pId,g_iButt[pId] + 1);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g1 !yбчк.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_1], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		case 5: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_2])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_2], 1);
				jbe_set_butt(pId,g_iButt[pId] + 3);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g3 !yбчка.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_2], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		case 6: 
		{
			if(jbe_get_user_money(pId) >= g_iTransferMoneyBut[MONEY_3])
			{
				jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iTransferMoneyBut[MONEY_3], 1);
				jbe_set_butt(pId,g_iButt[pId] + 5);
				UTIL_SayText(pId, "!g* !yВы успешно обменяли !g%d$ !yна !g5 !yбчков.У вас всего: !g%d бчк.", g_iTransferMoneyBut[MONEY_3], g_iButt[pId]);
			}
			else UTIL_SayText(pId, "!g* !yУ вас недостаточно денег для выполнение обмена");
		}
		case 7: 
		{
			if(g_iButt[pId])
			{
				g_iButt[pId]--;
				g_iButt[pId]++;
				UTIL_SayText(pId, "!g* !yВы успешно обменяли 1 !gбычок !yна 1 !gбчк!y.У вас на счету: !g[!y%d !gбчк. и !y%d !gбчк.]", g_iButt[pId], g_iButt[pId]);
			}
		}
		case 8: 
		{
			if(g_iButt[pId])
			{
				g_iButt[pId]++;
				g_iButt[pId]--;
				UTIL_SayText(pId, "!g* !yВы успешно обменяли 1 !gбчк !yна 1 !gбычок!y.У вас на счету: !g[!y%d !gбчк. и !y%d !gбчк.]", g_iButt[pId], g_iButt[pId]);
			}
		}
		case 9: return Show_MainShopMenu(pId);
	}
	return Show_MainTransferMenu(pId);
}

new g_iTransferStatus[MAX_PLAYERS + 1];

Cmd_MoneyTransferMenu(pId) return Show_MenuMoneyTransfer(pId, g_iMenuPosition[pId] = 0);
Show_MenuMoneyTransfer(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	#define PLAYERS_TEMP_PER_PAGE 7
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i) || i == pId) continue;
		g_iMenuPlayers[pId][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_TEMP_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_TEMP_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_TEMP_PER_PAGE;
	new iEnd = iStart + PLAYERS_TEMP_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_TEMP_PER_PAGE + ((iPlayersNum % PLAYERS_TEMP_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_MainTransferMenu(pId);
		}
		default: 
		{
			if(!g_iTransferStatus[pId])
			FormatMain("\yВыберите кому переводить \w[%d|%d]^n\dНа Вашем счету: %d бычков^n^n", iPos + 1, iPagesNum, g_iButt[pId]);
			else FormatMain("\yВыберите кому переводить \w[%d|%d]^n\dНа Вашем счету: %d бчк^n^n", iPos + 1, iPagesNum, g_iButt[pId]);
		}
	}
	new i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[pId][a];
		
		if(get_login(i))
		{
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%n ^n", ++b, i);
		}else FormatItem("\y%d. \d%n \r[no reg]^n", ++b, i);
	}
	//for(new i = b; i < PLAYERS_TEMP_PER_PAGE; i++) FormatItem("^n");
	FormatItem("^n\y8. \wПередать \r%s^n", g_iTransferStatus[pId] ? "Бычки" : "бчкы"), iKeys |= (1<<7);
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_MenuMoneyTransfer");
}

public Handle_MenuMoneyTransfer(pId, iKey)
{
	#define PLAYERS_TEMP_PER_PAGE 7
	switch(iKey)
	{
		case 7: 
		{
			g_iTransferStatus[pId] = !g_iTransferStatus[pId];
			return Show_MenuMoneyTransfer(pId, g_iMenuPosition[pId]);
		}
		case 8: return Show_MenuMoneyTransfer(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_MenuMoneyTransfer(pId, --g_iMenuPosition[pId]);
		default:
		{
			g_iMenuTarget[pId] = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_TEMP_PER_PAGE + iKey];
			return Show_MoneyAmountMenu(pId);
		}
	}
	return PLUGIN_HANDLED;
}

Show_MoneyAmountMenu(pId)
{
	
	new szMenu[512], iKeys = (1<<8|1<<9),  iLen;
	
	switch(g_iTransferStatus[pId])
	{
		case false: FormatMain("\y%L^n\d%L^n", pId, "JBE_MENU_MONEY_AMOUNT_TITLE", pId, "JBE_MENU_MONEY_YOU_AMOUNT", g_iButt[pId]);
		case true: FormatMain("\y%L^n\d%L^n", pId, "JBE_MENU_MONEY_AMOUNT_TITLE", pId, "JBE_MENU_MONEY_YOU_AMOUNT", g_iButt[pId]);
	}
	if(!g_iTransferStatus[pId] && g_iButt[pId])
	{
		FormatItem("\y1. \w%d$^n", floatround(g_iButt[pId] * 0.10, floatround_ceil));
		FormatItem("\y2. \w%d$^n", floatround(g_iButt[pId] * 0.25, floatround_ceil));
		FormatItem("\y3. \w%d$^n", floatround(g_iButt[pId] * 0.50, floatround_ceil));
		FormatItem("\y4. \w%d$^n", floatround(g_iButt[pId] * 0.75, floatround_ceil));
		FormatItem("\y5. \w%d$^n^n^n", g_iButt[pId]);
		FormatItem("\y8. \w%L^n", pId, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
		iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4|1<<7);
	}
	else if(g_iTransferStatus[pId] && g_iButt[pId])
	{
		FormatItem("\y1. \w%d$^n", floatround(g_iButt[pId] * 0.10, floatround_ceil));
		FormatItem("\y2. \w%d$^n", floatround(g_iButt[pId] * 0.25, floatround_ceil));
		FormatItem("\y3. \w%d$^n", floatround(g_iButt[pId] * 0.50, floatround_ceil));
		FormatItem("\y4. \w%d$^n", floatround(g_iButt[pId] * 0.75, floatround_ceil));
		FormatItem("\y5. \w%d$^n^n^n", g_iButt[pId]);
		FormatItem("\y8. \w%L^n", pId, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
		iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4|1<<7);
	}
	else
	{
		FormatItem("\y1. \d0$^n\y2. \d0$^n\y3. \d0$^n\y4. \d0$^n\y5. \d0$^n^n^n");
		FormatItem("\y8. \d%L^n", pId, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
	}
	FormatItem("^n\y9. \w%L", pId, "JBE_MENU_BACK");
	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_MoneyAmountMenu");
}

public Handle_MoneyAmountMenu(pId, iKey)
{
	if(!g_iTransferStatus[pId])
	{
		switch(iKey)
		{
			case 0: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.10, floatround_ceil));
			case 1: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.25, floatround_ceil));
			case 2: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.50, floatround_ceil));
			case 3: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.75, floatround_ceil));
			case 4: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], g_iButt[pId]);
			case 7: client_cmd(pId, "messagemode ^"valyuta_transfer %d^"", g_iMenuTarget[pId]);
			case 8: return Show_MenuMoneyTransfer(pId, g_iMenuPosition[pId]);
		}
	}else
	{
		switch(iKey)
		{
			case 0: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.10, floatround_ceil));
			case 1: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.25, floatround_ceil));
			case 2: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.50, floatround_ceil));
			case 3: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], floatround(g_iButt[pId] * 0.75, floatround_ceil));
			case 4: ClCmd_ZlMoneyTransfer(pId, g_iMenuTarget[pId], g_iButt[pId]);
			case 7: client_cmd(pId, "messagemode ^"valyuta_transfer %d^"", g_iMenuTarget[pId]);
			case 8: return Show_MenuMoneyTransfer(pId, g_iMenuPosition[pId]);
		}
	
	}
	return PLUGIN_HANDLED;
}

public ClCmd_ZlMoneyTransfer(pId, iTarget, iMoney)
{
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
	if(pId == iTarget || !jbe_is_user_valid(iTarget) || !jbe_is_user_connected(iTarget)) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_UNKNOWN_PLAYER");
	else 
	if(!g_iTransferStatus[pId] && g_iButt[pId] < iMoney) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_SUFFICIENT_FUNDS");
	else if(g_iTransferStatus[pId] && g_iButt[pId] < iMoney) UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_SUFFICIENT_FUNDS");
	else if(iMoney <= 0) UTIL_SayText(pId, "!g * !tМинимальная !yсумма для перевода !g1 %s!y.", g_iTransferStatus[pId] ? "бычок" : "бчк");
	else
	{
		switch(g_iTransferStatus[pId])
		{
			case false:
			{
				g_iButt[iTarget] += iMoney;
				g_iButt[pId] -= iMoney;
			}

			case true:
			{
				g_iChips[iTarget] += iMoney;
				g_iButt[pId] -= iMoney;
			}
		}

		new szName[32], szNameTarget[32];
		get_user_name(pId, szName, charsmax(szName));
		get_user_name(iTarget, szNameTarget, charsmax(szNameTarget));
		UTIL_SayText(0, "!g * !t%s !yперевёл !g%d !y%s !yна счёт !t%s!y." , szName, iMoney, g_iTransferStatus[pId] ? "бычки" : "бчкы", szNameTarget);
	}
	return PLUGIN_HANDLED;
}*/


Show_GrShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<7|1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин охранников:^nУ вас \r%d бчк^n^n", g_iButt[pId]);
	
	if(g_iShopCvars[SHOP_CT_ELECTRO] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitUserElectroShoker, pId))
	{
		FormatItem("\y1. \wЭлектрошокер \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_ELECTRO]), iKeys |= 1<<0;
	}
	else FormatItem("\y1. \dЭлектрошокер \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_ELECTRO]);

	if(g_iShopCvars[SHOP_CT_FORMA] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitUserShopModel, pId))
	{
		FormatItem("\y2. \wФорма Зека \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_FORMA]), iKeys |= 1<<1;
	}else FormatItem("\y2. \dФорма Зека \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_FORMA]);
	
	if(g_iShopCvars[SHOP_CT_SPEED] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitFastRun, pId))
	{
		FormatItem("\y3. \wСкорость \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_SPEED]), iKeys |= 1<<2;
	}else FormatItem("\y3. \dСкорость \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_SPEED]);
	
	if(g_iShopCvars[SHOP_CT_FIELD] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitUserShopDamageReduce, pId))
	{
		FormatItem("\y4. \wЭнерго щит \y[%d бчк.]^n^n", g_iShopCvars[SHOP_CT_FIELD]), iKeys |= 1<<3;
	}else FormatItem("\y4. \dЭнерго щит \y[%d бчк.]^n^n", g_iShopCvars[SHOP_CT_FIELD]);

	if(g_iShopCvars[SHOP_CT_HEALT] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && get_user_health(pId) < 150)
	{
		FormatItem("\y5. \wМед Пакет \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_HEALT]), iKeys |= 1<<4;
	}else FormatItem("\y5. \dМед Пакет \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_HEALT]);

	if(g_iShopCvars[SHOP_CT_UNLIMAM] <= g_iButt[pId] && IsNotSetBit(g_iBitUserUnlimAmmo, pId) && jbe_get_user_team(pId) == 2)
	{
		FormatItem("\y6. \wБесконечные патроны \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_UNLIMAM]), iKeys |= 1<<5;
	}else FormatItem("\y6. \dБесконечные патроны \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_UNLIMAM]);
	
	if(g_iShopCvars[SHOP_CT_REGEN] <= g_iButt[pId] && !task_exists(TASK_REGEN_HP + pId) && jbe_get_user_team(pId) == 2)
	{
		FormatItem("\y7. \wРегенерация ХП \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_REGEN]), iKeys |= 1<<6;
	}else FormatItem("\y7. \dРегенерация ХП \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_REGEN]);
	

	FormatItem("^n\y9. \wДалее^n\y0. \wВыход");
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_GrShopMenu");
}


public Handle_GrShopMenu(pId, iKey)
{
	//if(iKey == 7)
	//	return Show_MainShopMenu(pId);
	if(iKey == 8)
		return Show_GrShop_2Menu(pId);
	else if(iKey == 9) 
		return PLUGIN_HANDLED;
		
	
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId) || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	

	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}

	switch(iKey)
	{
		case 0: 
		{
			if(g_iShopCvars[SHOP_CT_ELECTRO] <= g_iButt[pId])
			{
				//jbe_set_user_money(pId, jbe_get_user_money(pId) - g_iShopCvars[SHOP_CT_ELECTRO], 1);
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_ELECTRO]);
				Effects_two(pId);
				
				SetBit(g_iBitUserElectroShoker, pId);
				
				if(get_user_weapon(pId) == CSW_KNIFE)
				{
					new iActiveItem = get_member(pId, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
			}
		}
		case 1: 
		{
			if(g_iShopCvars[SHOP_CT_FORMA] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_FORMA]);
				Effects_two(pId);
				SetBit(g_iBitUserShopModel,pId);
				jbe_set_user_model_ex(pId, 1);
				UTIL_SayText(pId, "!g* !yВы переоделись в форму заключенных");
			}
		}
		case 2: 
		{
			if(g_iShopCvars[SHOP_CT_SPEED] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_SPEED]);
				Effects_two(pId);
				SetBit(g_iBitFastRun, pId);
				rg_reset_maxspeed(pId);
			}
		}
		case 3: 
		{
			if(g_iShopCvars[SHOP_CT_FIELD] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_FIELD]);
				Effects_two(pId);
				SetBit(g_iBitUserShopDamageReduce, pId);
				UTIL_SayText(pId, "!g* !yВы приобрели Энерго-Щит, Щит поглащает половина полученного урона");
				jbe_set_user_rendering(pId, kRenderFxGlowShell, 128, 255, 255, kRenderNormal, 0);
			}
		}
		case 4: 
		{
			if(g_iShopCvars[SHOP_CT_HEALT] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_HEALT]);
				Effects_two(pId);
				set_entvar(pId, var_health, 200.0);
			}
		}
		case 5: 
		{
			if(g_iShopCvars[SHOP_CT_UNLIMAM] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_UNLIMAM]);
				Effects_two(pId);
				SetBit(g_iBitUserUnlimAmmo, pId);
			}
		}
		case 6: 
		{
			if(g_iShopCvars[SHOP_CT_REGEN] <= g_iButt[pId])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_REGEN]);
				Effects_two(pId);
				set_task_ex(1.0, "jbe_task_regen", pId + TASK_REGEN_HP, .flags = SetTask_Repeat);
			}
		}
	}

	return Show_GrShopMenu(pId);
}

Show_GrShop_2Menu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин охранников:^nУ вас \r%d бчк^n^n", g_iButt[pId]);
	
	if(g_iShopCvars[SHOP_CT_GRENA] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && IsNotSetBit(g_iBitRemoveGun, pId) && g_iShopCvars[ITEMS_GRENADE_COUNT_GR])
	{
		FormatItem("\y1. \wОбезоруживающая граната \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_GRENA]), iKeys |= 1<<0;
	}else FormatItem("\y1. \dОбезоруживающая граната \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_GRENA]);
	
	
	FormatItem("\dГраната в наличии - %d^n", g_iShopCvars[ITEMS_GRENADE_COUNT_GR]);
	
	if(g_iSimonShopBog[pId] >= g_iShopCvars[SIMON_SHOP_BOG_ROUND] && g_iShopCvars[SHOP_CT_GODMODE] <= g_iButt[pId] && jbe_get_user_team(pId) == 2 && jbe_is_user_chief(pId) && !jbe_get_user_godmode(pId))
	{
		FormatItem("\y2. \wБессмертие \y[%d бчк.] (Начальник)^n", g_iShopCvars[SHOP_CT_GODMODE]), iKeys |= 1<<1;
	}else FormatItem("\y2. \dБессмертие \y[%d бчк.]^n", g_iShopCvars[SHOP_CT_GODMODE]);
	
	FormatItem("^n^n\y0. \wНазад");
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_GrShop_2Menu");
}


public Handle_GrShop_2Menu(pId, iKey)
{


	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}
	
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId) || !jbe_is_user_alive(pId) || jbe_iduel_status()) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0: 
		{
			if(g_iShopCvars[SHOP_CT_GRENA] <= g_iButt[pId] && IsNotSetBit(g_iBitRemoveGun, pId) && g_iShopCvars[ITEMS_GRENADE_COUNT_GR])
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_GRENA]);
				Effects_two(pId);
				SetBit(g_iBitRemoveGun, pId);
				rg_give_item(pId, "weapon_smokegrenade", GT_REPLACE);
				g_iShopCvars[ITEMS_GRENADE_COUNT_GR]--;
			}
		}
		case 1: 
		{
			if(g_iShopCvars[SHOP_CT_GODMODE] <= g_iButt[pId] && !jbe_get_user_godmode(pId) && jbe_is_user_chief(pId))
			{
				jbe_set_butt(pId,g_iButt[pId] - g_iShopCvars[SHOP_CT_GODMODE]);
				Effects_two(pId);
				jbe_set_user_godmode(pId, 1);
				g_iSimonShopBog[pId] = 0;
				UTIL_SayText(0, "!g* !yНачальник купил себе !gбессмертие");
			}
		}
		case 9: return Show_GrShopMenu(pId);
		default:  return Show_GrShop_2Menu(pId);
	}

	return Show_GrShop_2Menu(pId);
}


public Show_PnShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин зеков^nУ вас \r%d \yбычков^n^n", g_iButt[pId]);
	
	FormatItem("\y1. \wСнаряжение^n"), iKeys |= 1<<0;
	FormatItem("\y2. \wУмения^n"), iKeys |= 1<<1;
	FormatItem("\y3. \wВооружение^n"), iKeys |= 1<<2;
	FormatItem("\y4. \wОстальное^n^n"), iKeys |= 1<<3;
	
	if(jbe_is_user_alive(pId) && !jbe_is_user_wanted(pId) && !jbe_is_user_free(pId) && jbe_get_day_mode() < 3)
	{
		FormatItem("\y5. \rСбросить магазин^n"), iKeys |= 1<<4;
	}else FormatItem("\y5. \dСбросить магазин^n");
	
	
	
	
	FormatItem("^n^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_PnShopMenu");
}

public Handle_PnShopMenu(pId, iKey)
{
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId) || !jbe_is_user_alive(pId)) return PLUGIN_HANDLED;
	
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		case 0: return Show_ItemsShopMenu(pId);
		case 1: return Show_SkillsShopMenu(pId);
		case 2: return Show_WeaponsShopMenu(pId);
		case 3: return Show_OthersShopMenu(pId);
		
		case 4:
		{
			if(jbe_is_user_alive(pId) && !jbe_is_user_wanted(pId) && !jbe_is_user_free(pId) && jbe_get_day_mode() < 3)
			{
				jbe_remove_shop_pn(pId);
				set_entvar(pId, var_gravity, 1.0);
				rg_reset_maxspeed(pId);

				jbe_set_user_rendering(pId, kRenderFxGlowShell,0,0,0,kRenderNormal,25);
				UTIL_SayText(pId, "!g* !yВы !yзабрали с себя !gмагазины !y(гравитация, скорость и тп.)");
				static Float: fCurTime[MAX_PLAYERS + 1], Float: fNextTime[MAX_PLAYERS + 1]; fCurTime[pId] = get_gametime();
				if(fNextTime[pId] <= fCurTime[pId])
				{
					UTIL_SayText(0, "!g* !y%s !g%n !yзабрал с себя !gмагазины !y(гравитация, скорость и тп.)",jbe_get_user_team(pId) ? "Заключенный" : "Охрана", pId);
					fNextTime[pId] = (fCurTime[pId] + 15.0);
				}
			}
		}
		
		
		case 9: return PLUGIN_HANDLED;
	}
	return Show_PnShopMenu(pId);
}

//Снаряжение
Show_ItemsShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин зеков: снаряжение^nУ вас \r%d \yбычков^n^n", g_iButt[pId]);
	
	if(g_iShopCvars[ITEMS_FD] <= g_iButt[pId] && !jbe_is_user_free(pId) && !jbe_is_user_wanted(pId) && jbe_get_user_team(pId) == 1)
	{
		if(IsNotSetBit(g_iBitUserFree, pId))
		{
			if(!g_iCvarStats[ITEMS_FD] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_FD])
			{
				FormatItem("\y1. \wСвободный день \y[%d бчк.]^n", g_iShopCvars[ITEMS_FD]), iKeys |= 1<<0;
			}else FormatItem("\y1. \dСвободный день \r[%d ур.]^n", g_iCvarStats[ITEMS_FD]);
			
		}else FormatItem("\y1. \dСвободный день \y[%d бчк.] (1 раз за раунд)^n", g_iShopCvars[ITEMS_FD]);
	}
	else FormatItem("\y1. \dСвободный день \y[%d бчк.]^n", g_iShopCvars[ITEMS_FD]);
	
	if(g_iShopCvars[ITEMS_CLOTHING] <= g_iButt[pId] && IsNotSetBit(g_iBitClothingGuard, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_CLOTHING] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_CLOTHING])
		{
			FormatItem("\y2. \wМаскировка \y[%d бчк.]^n", g_iShopCvars[ITEMS_CLOTHING]), iKeys |= 1<<1;
		}else FormatItem("\y2. \dМаскировка \r[%d ур.]^n", g_iCvarStats[ITEMS_CLOTHING]);
	}
	else FormatItem("\y2. \dМаскировка \y[%d бчк.]^n", g_iShopCvars[ITEMS_CLOTHING]);
	
	
	if(g_iShopCvars[ITEMS_LATCHKEY] <= g_iButt[pId] && IsNotSetBit(g_iBitLatchkey, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_LATCHKEY] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_LATCHKEY])
		{
			FormatItem("\y3. \wОтмычка \y[%d бчк.]^n", g_iShopCvars[ITEMS_LATCHKEY]), iKeys |= 1<<2;
		}else FormatItem("\y3. \dОтмычка \r[%d ур.]^n", g_iCvarStats[ITEMS_LATCHKEY]);
	}
	else FormatItem("\y3. \dОтмычка \y[%d бчк.]^n", g_iShopCvars[ITEMS_LATCHKEY]);
	
	if(g_iShopCvars[ITEMS_SHAHID] <= g_iButt[pId] && IsNotSetBit(g_gUserForJihad,pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_SHAHID] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_SHAHID])
		{
			FormatItem("\y4. \wПояс Шахида \y[%d бчк.]^n^n", g_iShopCvars[ITEMS_SHAHID]), iKeys |= 1<<3;
		}else FormatItem("\y4. \dПояс Шахида \r[%d ур.]^n^n", g_iCvarStats[ITEMS_SHAHID]);
	}
	else FormatItem("\y4. \dПояс Шахида \y[%d бчк.]^n^n", g_iShopCvars[ITEMS_SHAHID]);
	
	
	FormatItem("\yГраната в наличии: [%d]^n", g_iShopCvars[ITEMS_GRENADE_COUNT]);
	
	if(g_iShopCvars[ITEMS_GRENADE_ANTI] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasSM, pId) && g_iShopCvars[ITEMS_GRENADE_COUNT] && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_GRENADE_ANTI] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_GRENADE_ANTI])
		{
			FormatItem("\y5. \wАнтигравитационная \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_ANTI]), iKeys |= 1<<4;
		}else FormatItem("\y5. \dАнтигравитационная \r[%d ур.]^n", g_iCvarStats[ITEMS_GRENADE_ANTI]);
	}
	else FormatItem("\y5. \dАнтигравитационная \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_ANTI]);
	
	if(g_iShopCvars[ITEMS_GRENADE_FROST] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasFL, pId) && g_iShopCvars[ITEMS_GRENADE_COUNT] && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_GRENADE_FROST] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_GRENADE_FROST])
		{
			FormatItem("\y6. \wЗамораживающая \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_FROST]), iKeys |= 1<<5;
		}else FormatItem("\y6. \dЗамораживающая \r[%d ур.]^n", g_iCvarStats[ITEMS_GRENADE_FROST]);
	}
	else FormatItem("\y6. \dЗамораживающая \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_FROST]);
	
	if(g_iShopCvars[ITEMS_GRENADE_GAL] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasHE, pId) && g_iShopCvars[ITEMS_GRENADE_COUNT] && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[ITEMS_GRENADE_GAL] || jbe_get_user_ranks(pId) >= g_iCvarStats[ITEMS_GRENADE_GAL])
		{
			FormatItem("\y7. \wГаллюциногенная \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_GAL]), iKeys |= 1<<6;
		}else FormatItem("\y7. \dГаллюциногенная \r[%d ур.]^n", g_iCvarStats[ITEMS_GRENADE_GAL]);
	}
	else FormatItem("\y7. \dГаллюциногенная \y[%d бчк.]^n", g_iShopCvars[ITEMS_GRENADE_GAL]);
	
	
	
	FormatItem("^n\y9. \wНазад^n\y0. \wВыход");
	
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_ItemsShopMenu");
}


//Снаряжение
public Handle_ItemsShopMenu(pId, iKey)
{
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	

	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		case 0: 
		{
			if(g_iShopCvars[ITEMS_FD] <= g_iButt[pId] && !jbe_is_user_free(pId) && !jbe_is_user_wanted(pId) && IsNotSetBit(g_iBitUserFree, pId))
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_FD]);
				jbe_add_user_free(pId);
				Effects_two(pId);
				
				SetBit(g_iBitUserFree, pId);
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) <= g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_FD]); 
				}
			}
		}
		
		case 1: 
		{
			if(g_iShopCvars[ITEMS_CLOTHING] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_CLOTHING]);
				SetBit(g_iBitClothingGuard, pId);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_CLOTHING]); 
				}
			}
		}
		case 2: 
		{
			if(g_iShopCvars[ITEMS_LATCHKEY] <= g_iButt[pId])
			{
				SetBit(g_iBitLatchkey, pId);
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_LATCHKEY]);
				UTIL_SayText(pId, "%L", pId, "JBE_MENU_ID_LATCHKEY_USE", pId, "JBE_PREFIX_CHAT");
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_LATCHKEY]); 
				}
			}
		}
		
		case 3: 
		{
			if(g_iShopCvars[ITEMS_SHAHID] <= g_iButt[pId] && jbe_is_user_alive(pId))
			{
				SetBit(g_gUserForJihad, pId);
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_SHAHID]);
				UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_JIHAD_ACTIVE");
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_SHAHID]); 
				}
			}
		}
		case 4: 
		{
			if(g_iShopCvars[ITEMS_GRENADE_ANTI] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_GRENADE_ANTI]);
				rg_give_item(pId, "weapon_smokegrenade", GT_APPEND);
				SetBit(g_iBitAntiGravity, pId);
				Effects_two(pId);
				SetBit(g_iBitUserHasSM, pId);
				g_iShopCvars[ITEMS_GRENADE_COUNT]--;
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_GRENADE_ANTI]); 
				}
			}
		}
		case 5: 
		{
			if(g_iShopCvars[ITEMS_GRENADE_FROST] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_GRENADE_FROST]);
				rg_give_item(pId, "weapon_flashbang", GT_APPEND);
				SetBit(g_iBitFrostNade, pId);
				Effects_two(pId);
				SetBit(g_iBitUserHasFL, pId);
				g_iShopCvars[ITEMS_GRENADE_COUNT]--;
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_GRENADE_FROST]); 
				}
			}
		}
		case 6: 
		{
			if(g_iShopCvars[ITEMS_GRENADE_GAL] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[ITEMS_GRENADE_GAL]);
				rg_give_item(pId, "weapon_hegrenade", GT_APPEND);
				SetBit(g_iBitGalogramma, pId);
				Effects_two(pId);
				SetBit(g_iBitUserHasHE, pId);
				g_iShopCvars[ITEMS_GRENADE_COUNT]--;
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[ITEMS_GRENADE_GAL]); 
				}
			}
		}
		
		case 8: return Show_PnShopMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ItemsShopMenu(pId);
}

//Умение
Show_SkillsShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин зеков: умение^nУ вас \r%d \yбычков^n^n", g_iButt[pId]);
	
	if(g_iShopCvars[SKILLS_GRAVITY] <= g_iButt[pId] && get_entvar(pId, var_gravity) == 1.0 && jbe_get_user_team(pId) == 1)
	{
		if(g_iUserGravity[pId] > 3)
		{
			if(!g_iCvarStats[SKILLS_GRAVITY] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_GRAVITY])
			{
				FormatItem("\y1. \wГравитация \y[%d бчк.]^n", g_iShopCvars[SKILLS_GRAVITY]), iKeys |= 1<<0;
			}else FormatItem("\y1. \dГравитация \r[%d ур.]^n", g_iCvarStats[SKILLS_GRAVITY]);
		}else FormatItem("\y1. \dГравитация \y[раз в 3 рнд.]^n");
	}
	else FormatItem("\y1. \dГравитация \y[%d бчк.]^n", g_iShopCvars[SKILLS_GRAVITY]);
	
	if(g_iShopCvars[SKILLS_SPEED] <= g_iButt[pId] && IsNotSetBit(g_iBitFastRun, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[SKILLS_SPEED] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_GRAVITY])
		{
			FormatItem("\y2. \wСкорость \y[%d бчк.]^n", g_iShopCvars[SKILLS_SPEED]), iKeys |= 1<<1;
		}else FormatItem("\y2. \dСкорость \r[%d ур.]^n", g_iCvarStats[SKILLS_SPEED]);
	}
	else FormatItem("\y2. \dСкорость \y[%d бчк.]^n", g_iShopCvars[SKILLS_SPEED]);
		
	if(g_iShopCvars[SKILLS_HP] <= g_iButt[pId] && get_user_health(pId) < 255 && jbe_get_user_team(pId) == 1 && IsNotSetBit(g_iBitUserHealt, pId))
	{
		if(!g_iCvarStats[SKILLS_HP] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_HP])
		{
			FormatItem("\y3. \w+255 ХП \y[%d бчк.]^n", g_iShopCvars[SKILLS_HP]), iKeys |= 1<<2;
		}else FormatItem("\y3. \d+255 ХП \r[%d ур.]^n", g_iCvarStats[SKILLS_HP]);
	}
	else FormatItem("\y3. \d+255 ХП \y[%d бчк.]^n", g_iShopCvars[SKILLS_HP]);
		
	/*if(g_iShopCvars[SKILLS_AP] <= g_iButt[pId] && get_user_armor(pId) < 255 && jbe_get_user_team(pId) == 1 && IsNotSetBit(g_iBitUserArmor, pId))
	{
		if(!g_iCvarStats[SKILLS_AP] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_AP])
		{
			FormatItem("\y4. \w+255 АП \y[%d бчк.]^n", g_iShopCvars[SKILLS_AP]), iKeys |= 1<<3;
		}else FormatItem("\y4. \d+255 АП \r[%d ур.]^n", g_iCvarStats[SKILLS_AP]);
	}
	else FormatItem("\y4. \d+255 АП \y[%d бчк.]^n", g_iShopCvars[SKILLS_AP]);*/
		
	if(g_iShopCvars[SKILLS_BHOP] <= g_iButt[pId] && IsNotSetBit(g_iBitAutoBhop, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[SKILLS_BHOP] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_BHOP])
		{
			FormatItem("\y4. \wРаспрыжка \y[%d бчк.]^n", g_iShopCvars[SKILLS_BHOP]), iKeys |= 1<<3;
		}else FormatItem("\y4. \dРаспрыжка \r[%d ур.]^n", g_iCvarStats[SKILLS_BHOP]);
	}
	else FormatItem("\y4. \dРаспрыжка \y[%d бчк.]^n", g_iShopCvars[SKILLS_BHOP]);
		
	if(g_iShopCvars[SKILLS_DDAMAGE] <= g_iButt[pId] && IsNotSetBit(g_iBitDoubleDamage, pId) && jbe_get_user_team(pId) == 1)
	{
		if(g_iUserDoubleDamage[pId] > 5)
		{
			if(!g_iCvarStats[SKILLS_DDAMAGE] || jbe_get_user_ranks(pId) >= g_iCvarStats[SKILLS_DDAMAGE])
			{
				FormatItem("\y5. \wУдвоенный урон \y[%d бчк.]^n",g_iShopCvars[SKILLS_DDAMAGE]), iKeys |= 1<<4;
			}else FormatItem("\y5. \dУдвоенный урон \r[%d ур.]^n",g_iCvarStats[SKILLS_DDAMAGE]);
		}else FormatItem("\y5. \dУдвоенный урон \y[Раз в 5 рнд.]^n");
	}
	else FormatItem("\y5. \dУдвоенный урон \y[%d бчк.]^n",g_iShopCvars[SKILLS_DDAMAGE]);
	
	
	FormatItem("^n\y9. \wНазад^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_SkillsShopMenu");
}

//Умение
public Handle_SkillsShopMenu(pId, iKey)
{
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	
	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}
	switch(iKey)
	{
		case 0: 
		{
			if(g_iShopCvars[SKILLS_GRAVITY] <= g_iButt[pId] && g_iUserGravity[pId] >= 4)
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_GRAVITY]);
				set_entvar(pId, var_gravity, 0.2);
				Effects_two(pId);
				
				g_iUserGravity[pId] = 0;
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_GRAVITY]); 
				}
			}
		}
		case 1: 
		{
			if(g_iShopCvars[SKILLS_SPEED] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_SPEED]);
				SetBit(g_iBitFastRun, pId);
				rg_reset_maxspeed(pId);
				Effects_two(pId);
				
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_SPEED]); 
				}
			}
		}
		case 2: 
		{
			if(g_iShopCvars[SKILLS_HP] <= g_iButt[pId] && get_user_health(pId) < 255)
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_HP]);
				set_entvar(pId, var_health, 255.0);
				SetBit(g_iBitUserHealt, pId);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_HP]); 
				}
			}
		}
		/*case 3: 
		{
			if(g_iShopCvars[SKILLS_AP] <= g_iButt[pId] && get_user_armor(pId) < 255)
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_AP]);
				rg_set_user_armor(pId, 255, ARMOR_VESTHELM);
				Effects_two(pId);
				SetBit(g_iBitUserArmor, pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_AP]); 
				}
			}
		}*/
		
		case 3: 
		{
			if(g_iShopCvars[SKILLS_BHOP] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_BHOP]);
				SetBit(g_iBitAutoBhop, pId);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_BHOP]); 
				}
			}
		}
		case 4: 
		{
			if(g_iShopCvars[SKILLS_DDAMAGE] <= g_iButt[pId] && g_iUserDoubleDamage[pId] >= 5)
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[SKILLS_DDAMAGE]);
				SetBit(g_iBitDoubleDamage, pId);
				g_iUserDoubleDamage[pId] = 0;
				
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[SKILLS_DDAMAGE]); 
				}
			}
		}
		
		case 8: return Show_PnShopMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_SkillsShopMenu(pId);
}


//Вооружение
Show_WeaponsShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин зеков: вооружение^nУ вас \r%d \yбычков^n^n", g_iButt[pId]);
	
	/*if(g_iShopCvars[WEAPONS_GLOCK18] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasUsp, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[WEAPONS_GLOCK18] || jbe_get_user_ranks(pId) >=g_iCvarStats[WEAPONS_GLOCK18])
		{
			FormatItem("\y1. \wUSP-S \y[12 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_GLOCK18]), iKeys |= 1<<0;
		}else FormatItem("\y1. \dUSP-S \y[12 птр.] [%d ур.]^n", g_iCvarStats[WEAPONS_GLOCK18]);
	}
	else FormatItem("\y1. \dUSP-S \y[12 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_GLOCK18]);
	
	if(g_iShopCvars[WEAPONS_TMP] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasTMP, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[WEAPONS_TMP] || jbe_get_user_ranks(pId) >= g_iCvarStats[WEAPONS_TMP])
		{
			FormatItem("\y2. \wTMP \y[30 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_TMP]), iKeys |= 1<<1;
		}else FormatItem("\y2. \wTMP \y[30 птр.] [%d ур.]^n", g_iCvarStats[WEAPONS_TMP]);
	}
	else FormatItem("\y2. \dTMP \y[30 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_TMP]);
	
	if(g_iShopCvars[WEAPONS_DEAGLE] <= g_iButt[pId] && IsNotSetBit(g_iBitUserHasDeagle, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[WEAPONS_DEAGLE] || jbe_get_user_ranks(pId) >= g_iCvarStats[WEAPONS_DEAGLE])
		{
			FormatItem("\y3. \wDesert Eagle \y[7 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_DEAGLE]), iKeys |= 1<<2;
		}else FormatItem("\y3. \dDesert Eagle \y[7 птр.] [%d ур.]^n", g_iCvarStats[WEAPONS_DEAGLE]);
	}
	else FormatItem("\y3. \dDesert Eagle \y[7 птр.] [%d бчк.]^n", g_iShopCvars[WEAPONS_DEAGLE]);
	*/
	if(g_iShopCvars[WEAPONS_MOLOT] <= g_iButt[pId] && IsNotSetBit(g_iBitUserMolot, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[WEAPONS_MOLOT] || jbe_get_user_ranks(pId) >= g_iCvarStats[WEAPONS_MOLOT])
		{
			FormatItem("\y1. \wМолоток \y[%d бчк.]^n", g_iShopCvars[WEAPONS_MOLOT]), iKeys |= 1<<0;
		}else FormatItem("\y1. \dМолоток \r[%d ур.]^n", g_iCvarStats[WEAPONS_MOLOT]);
	}
	else FormatItem("\y1. \dМолоток \y[%d бчк.]^n", g_iShopCvars[WEAPONS_MOLOT]);
	
	if(g_iShopCvars[WEAPONS_BENZ] <= g_iButt[pId] && IsNotSetBit(g_iBitUserSaw, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[WEAPONS_BENZ] || jbe_get_user_ranks(pId) >= g_iCvarStats[WEAPONS_MOLOT])
		{
			FormatItem("\y2. \wБензопила \y[%d бчк.]^n", g_iShopCvars[WEAPONS_BENZ]), iKeys |= 1<<1;
		}else FormatItem("\y2. \dБензопила \r[%d ур.]^n", g_iCvarStats[WEAPONS_BENZ]);
	}
	else FormatItem("\y2. \dБензопила \y[%d бчк.]^n", g_iShopCvars[WEAPONS_BENZ]);
	
	
	
	
	FormatItem("^n\y9. \wНазад^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_WeaponsShopMenu");
}

//Вооружение
public Handle_WeaponsShopMenu(pId, iKey)
{
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	

	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		/*case 0: 
		{
			if(g_iShopCvars[WEAPONS_GLOCK18] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[WEAPONS_GLOCK18]);
				rg_give_item_ex(pId, "weapon_usp", GT_REPLACE);
				Effects_two(pId);
				SetBit(g_iBitUserHasUsp, pId);
				//set_pdata_int(rg_give_item(g_iDuelUsersId[0], "weapon_deagle" , GT_REPLACE), OFFSET_CLIPAMMO, 1, OFFSET_LINUX_WEAPONS);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[WEAPONS_GLOCK18]); 
				}
			}
		}
		case 1: 
		{
			if(g_iShopCvars[WEAPONS_TMP] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[WEAPONS_TMP]);
				rg_give_item_ex(pId, "weapon_tmp", GT_REPLACE);
				SetBit(g_iBitUserHasTMP, pId);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[WEAPONS_TMP]); 
				}
			}
		}
		case 2: 
		{
			if(g_iShopCvars[WEAPONS_DEAGLE] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[WEAPONS_DEAGLE]);
				rg_give_item_ex(pId, "weapon_deagle", GT_REPLACE);
				Effects_two(pId);
				SetBit(g_iBitUserHasDeagle, pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[WEAPONS_DEAGLE]); 
				}
			}
		}*/
		case 0: 
		{
			if(g_iShopCvars[WEAPONS_MOLOT] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[WEAPONS_MOLOT]);
				Effects_two(pId);
				
				SetBit(g_iBitUserMolot, pId);
				ClearBit(g_iBitUserSaw, pId);
				if(jbe_is_user_has_crowbar(pId))
				{
					new g_ForwardResult;
					ExecuteForward(g_iFwdDropLom , g_ForwardResult , pId);
				}
				if(IsSetBit(g_iBitWeaponStatus, pId) && get_user_weapon(pId) == CSW_KNIFE)
				{
					new iActiveItem = get_member(pId, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
				else UTIL_SayText(pId, "%L", pId, "JBE_CHAT_ID_SHOP_WEAPON_HELP", pId, "JBE_PREFIX_CHAT");
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[WEAPONS_MOLOT]); 
				}
			}
		}
		
		case 1: 
		{
			if(g_iShopCvars[WEAPONS_BENZ] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[WEAPONS_BENZ]);
				Effects_two(pId);
				
				SetBit(g_iBitUserSaw, pId);
				ClearBit(g_iBitUserMolot, pId);

				if(jbe_is_user_has_crowbar(pId))
				{
					new g_ForwardResult;
					ExecuteForward(g_iFwdDropLom , g_ForwardResult , pId);
				}
				
				if(IsSetBit(g_iBitWeaponStatus, pId) && get_user_weapon(pId) == CSW_KNIFE)
				{
					new iActiveItem = get_member(pId, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
				else UTIL_SayText(pId, "%L", pId, "JBE_CHAT_ID_SHOP_WEAPON_HELP", pId, "JBE_PREFIX_CHAT");
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[WEAPONS_BENZ]); 
				}
			}
		}
		
		case 8: return Show_PnShopMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_WeaponsShopMenu(pId);
}


//Остальное
Show_OthersShopMenu(pId)
{
	new szMenu[512], iKeys = (1<<8|1<<9), iLen;
	
	FormatMain("\yМагазин зеков: остальное^nУ вас \r%d \yбычков^n^n", g_iButt[pId]);
	
	if(g_iShopCvars[OTHER_MICRO] <= g_iButt[pId] && !jbe_get_user_voice(pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[OTHER_MICRO] || jbe_get_user_ranks(pId) >= g_iCvarStats[OTHER_MICRO])
		{
			FormatItem("\y1. \wДоступ в микрофон \y[%d бчк.]^n", g_iShopCvars[OTHER_MICRO]), iKeys |= 1<<0;
		}else FormatItem("\y1. \dДоступ в микрофон \r[%d ур.]^n", g_iCvarStats[OTHER_MICRO]);
	}else FormatItem("\y1. \dДоступ в микрофон \y[%d бчк.]^n", g_iShopCvars[OTHER_MICRO]);
	
	if(g_iShopCvars[OTHER_LOTO] <= g_iButt[pId] && IsNotSetBit(g_iBitLotteryTicket, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[OTHER_LOTO] || jbe_get_user_ranks(pId) >= g_iCvarStats[OTHER_LOTO])
		{
			FormatItem("\y2. \wСыграть в лотырею (Шанс 4 к 20) \y[%d бчк.]^n", g_iShopCvars[OTHER_LOTO]), iKeys |= 1<<1;
		}else FormatItem("\y2. \dСыграть в лотырею (Шанс 4 к 20) \r[%d ур.]^n", g_iCvarStats[OTHER_LOTO]);
	}else FormatItem("\y2. \dСыграть в лотырею \y[%d бчк.]^n", g_iShopCvars[OTHER_LOTO]);
	
	if(g_iShopCvars[OTHER_RANDOMGLOW] <= g_iButt[pId] && IsNotSetBit(g_iBitRandomGlow, pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[OTHER_RANDOMGLOW] || jbe_get_user_ranks(pId) >= g_iCvarStats[OTHER_RANDOMGLOW])
		{
			FormatItem("\y3. \wСлучайное свечение \y[%d бчк.]^n", g_iShopCvars[OTHER_RANDOMGLOW]), iKeys |= 1<<2;
		}else FormatItem("\y3. \dСлучайное свечение \r[%d ур.]^n", g_iCvarStats[OTHER_RANDOMGLOW]);
	}else FormatItem("\y3. \dСлучайное свечение \y[%d бчк.]^n", g_iShopCvars[OTHER_RANDOMGLOW]);
	
	if(g_iShopCvars[OTHER_WANTEDSUB] <= g_iButt[pId] && jbe_is_user_wanted(pId) && jbe_get_user_team(pId) == 1)
	{
		if(!g_iCvarStats[OTHER_WANTEDSUB] || jbe_get_user_ranks(pId) >= g_iCvarStats[OTHER_WANTEDSUB])
		{
			FormatItem("\y4. \wЗамять дело \y[%d бчк.]^n", g_iShopCvars[OTHER_WANTEDSUB]), iKeys |= 1<<3;
		}else FormatItem("\y4. \dЗамять дело \r[%d ур.]^n", g_iCvarStats[OTHER_WANTEDSUB]);
	}else FormatItem("\y4. \dЗамять дело \y[%d бчк.]^n", g_iShopCvars[OTHER_WANTEDSUB]);

	
	FormatItem("^n\y9. \wНазад^n\y0. \wВыход");
	
	return show_menu(pId, iKeys, szMenu, -1, "Show_OthersShopMenu");
}

//Остальное
public Handle_OthersShopMenu(pId, iKey)
{
	if(jbe_get_day_mode() == 3 || jbe_get_soccergame() || jbe_is_user_duel(pId)) return PLUGIN_HANDLED;
	
	if(is_enable())
	{
		UTIL_SayText(pId, "!g* !yСтоит админский запрет на магазин");
		return PLUGIN_HANDLED;
	}
	if(jbe_globalnyizapret())
	{
		UTIL_SayText(pId, "!g* !yСтоит глобальный запрет на магазин");
		return PLUGIN_HANDLED;
	}

	if(!jbe_is_user_alive(pId))
	{
		UTIL_SayText(pId, "!g* !yМагазин не доступен, вы мертвы!");
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		case 0: 
		{
			if(g_iShopCvars[OTHER_MICRO] <= g_iButt[pId])
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[OTHER_MICRO]);
				jbe_set_user_voice(pId);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[OTHER_MICRO]); 
				}
			}
		}
		case 1: 
		{
			if(g_iShopCvars[OTHER_LOTO] <= g_iButt[pId] && IsNotSetBit(g_iBitLotteryTicket, pId))
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[OTHER_LOTO]);
				SetBit(g_iBitLotteryTicket, pId);
				/*if(g_iUserQuest[pId][QUEST_7] < QUESTMONEY)
				{
					g_iUserQuest[pId][QUEST_7] += iPriceLotteryTicket;
				}*/
				
				new iPrize;
				switch(random_num(0, 20))
				{
					case 0: iPrize = 15;
					case 2: iPrize = 20;
					case 4: iPrize = 25;
					case 5: iPrize = 35;
				}
				if(iPrize)
				{
					UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_LOTTERY_WIN", iPrize);
					//jbe_set_user_money(pId, jbe_get_user_money(pId) + iPrize, 1);
					//g_iButt[pId] += iPrize;
					jbe_set_butt(pId, g_iButt[pId] + iPrize);
					Effects_two(pId);
					
				}
				else UTIL_SayText(pId, "!g * %L", pId, "JBE_CHAT_ID_LOTTERY_LOSS");
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[OTHER_LOTO]); 
				}
			}
		}
		case 2: 
		{
			if(g_iShopCvars[OTHER_RANDOMGLOW] <= g_iButt[pId] && IsNotSetBit(g_iBitRandomGlow, pId))
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[OTHER_RANDOMGLOW]);
				SetBit(g_iBitRandomGlow, pId);
				jbe_set_user_rendering(pId, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, 0);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[OTHER_RANDOMGLOW]); 
				}
			}
		}
		case 3: 
		{
			if(g_iShopCvars[OTHER_WANTEDSUB] <= g_iButt[pId] && jbe_is_user_wanted(pId))
			{
				jbe_set_butt(pId, g_iButt[pId] - g_iShopCvars[OTHER_WANTEDSUB]);
				jbe_sub_user_wanted(pId);
				//jbe_set_user_rendering(pId, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, 0);
				Effects_two(pId);
				
				if(get_login(pId) && jbe_mysql_stats_systems_get(pId, QUESTNUM) < g_iQuestMazhor)
				{
					jbe_mysql_stats_systems_add(pId, QUESTNUM, jbe_mysql_stats_systems_get(pId, QUESTNUM) + g_iShopCvars[OTHER_WANTEDSUB]); 
				}
			}
		}
		
		case 8: return Show_PnShopMenu(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_OthersShopMenu(pId);
}

public ClCmd_Radio2(id)
{
	if(jbe_get_user_team(id) == 1 && get_user_weapon(id) == CSW_KNIFE && (IsSetBit(g_iBitUserMolot, id) || IsSetBit(g_iBitUserSaw, id)))
	{
		if(jbe_get_soccergame() || jbe_is_user_duel(id))
		{
			UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_SHOP_WEAPON_BLOCKED", id, "JBE_PREFIX_CHAT");
			return PLUGIN_HANDLED;
		}
		if(get_member(id, m_flNextAttack) < 0.1)
		{
			new iActiveItem = get_member(id, m_pActiveItem);
			if(iActiveItem > 0)
			{
				InvertBit(g_iBitWeaponStatus, id);
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(id, 3);
				if(jbe_is_user_has_crowbar(id) && IsSetBit(g_iBitWeaponStatus, id))
				{
					new g_ForwardResult;
					ExecuteForward(g_iFwdDropLom , g_ForwardResult , id);
				}
			}
		}
	}
	return PLUGIN_HANDLED;
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

public ClCmd_Radio3(id)
{
	if(jbe_get_user_team(id) == 1 && IsSetBit(g_iBitLatchkey, id))
	{
		new iTarget, iBody;
		get_user_aiming(id, iTarget, iBody, 30);
		if(is_entity(iTarget))
		{
			new szClassName[32];
			get_entvar(iTarget, var_classname, szClassName, charsmax(szClassName));
			
			if(szClassName[5] == 'd' && szClassName[6] == 'o' && szClassName[7] == 'o' && szClassName[8] == 'r') 
			{
				new iRandom = random_num(3 ,10);
				if(task_exists(FIX_TASK_LATCH_KEY + id))
				{
					UTIL_SayText(id, "!g* !yНедавно вы использовали отмычку, подождите несколько секунд.");
					return PLUGIN_HANDLED;
				}
				if(jbe_is_user_valid(id) && jbe_is_user_alive(id))
				{
					if(g_iGlobalDebug)
					{
						log_to_file("globaldebug.log", "[SHOP_ADDONS] ClCmd_Radio3");
					}
					message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id);
					write_short(iRandom);
					message_end();
				}
				set_task(float(iRandom), "FuncOpenDoorLatchKey", FIX_TASK_LATCH_KEY + id);
			}
			else UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR", id, "JBE_PREFIX_CHAT");
		}
		else UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR", id, "JBE_PREFIX_CHAT");
	}
	return PLUGIN_HANDLED;
}

public FuncOpenDoorLatchKey(i_Task) {
	new id = i_Task - FIX_TASK_LATCH_KEY;
	
	if(jbe_is_user_alive(id) && IsSetBit(g_iBitLatchkey, id)) {
		new iTarget, iBody;
		get_user_aiming(id, iTarget, iBody, 30);
		if(is_entity(iTarget))
		{
			new szClassName[32];
			get_entvar(iTarget, var_classname, szClassName, charsmax(szClassName));
				
			if(szClassName[5] == 'd' && szClassName[6] == 'o' && szClassName[7] == 'o' && szClassName[8] == 'r') {
				switch(random_num(0,10)) 
				{
					case 1.3: {
						UTIL_SayText(id, "%L У вас сломалась отмычка!", id, "JBE_PREFIX_CHAT");
						ClearBit(g_iBitLatchkey, id);
					}
					case 5: {
						UTIL_SayText(id, "%L Вам удалось открыть клетку!", id, "JBE_PREFIX_CHAT");
						ClearBit(g_iBitLatchkey, id);
						dllfunc(DLLFunc_Use, iTarget, id);
					}
					default: UTIL_SayText(id, "%L Неудача, попробуйте снова!", id, "JBE_PREFIX_CHAT");
				}
			}
			else UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR", id, "JBE_PREFIX_CHAT");
		}
		else UTIL_SayText(id, "%L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR", id, "JBE_PREFIX_CHAT");
	}
	
	remove_task(i_Task);
}

public explos(pId)
{
	if(IsNotSetBit(g_gUserForJihad, pId)) return PLUGIN_HANDLED;
	
	BloodEffects(pId);
	Blast_ExplodeDamage( pId, Float:g_iShopCvars[ITEMS_SHAHID_DAMAGE], Float:g_iShopCvars[ITEMS_SHAHID_RADIUS] );
	ExecuteHamB(Ham_Killed, pId, pId, 2);
	return PLUGIN_HANDLED;
}

public BloodEffects(pId)
{
	if(!is_user_connected(pId)) return 0;
	
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] BloodEffects");
	}
	new iAimOrigin[3];
	get_user_origin(pId, iAimOrigin);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);     // Начало
	write_byte(TE_EXPLOSION);             // Индекс сообщения (message_const.inc)
 
	/* Координаты */
	write_coord(iAimOrigin[0]);             // x
	write_coord(iAimOrigin[1]);            // y
	write_coord(iAimOrigin[2]);            // z
		 
	write_short(g_iSpiteExlplosion);        // Тот самый индекс
	 
	write_byte(50);    // Размер спрайта указывать в десятых(0.1)
	write_byte(10);    // Скорость проигрывания анимации
	write_byte(0);    // Флаги
	
	message_end();
	return 0;
}


stock Blast_ExplodeDamage( entid, Float:damage, Float:range ) 
{
	new Float:flOrigin1[ 3 ];
	get_entvar( entid, var_origin, flOrigin1 );

	new Float:flDistance;
	new Float:flTmpDmg;
	new Float:flOrigin2[ 3 ];
	
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

	for(new i, Players; i < iPlayerCount; i++)
	{
		Players = iPlayers[i];
		
		if(jbe_is_user_alive(Players) && jbe_get_user_team(entid) != jbe_get_user_team(Players))
		{
			get_entvar( Players, var_origin, flOrigin2 );
			flDistance = get_distance_f( flOrigin1, flOrigin2 );
		
			if( flDistance <= range ) 
			{
				flTmpDmg = damage - ( damage / range ) * flDistance;
				ExecuteHamB(Ham_TakeDamage, Players, 0, entid, flTmpDmg, DMG_BULLET);

				#if defined DEBUG
				UTIL_SayText(0, "DMG %.1f, CT - %d", flTmpDmg, get_user_health(Players));
				#endif
			}
		}
	}
}

stock Effects_one(pId)
{
	if(!is_user_connected(pId) || jbe_is_user_blind(pId)) return 0;
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] Effects_one");
	}
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0,0,0}, pId);
	write_short(1<<15);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(255);
	write_byte(10);
	write_byte(0);
	write_byte(200);
	message_end();
	return 0;
}



stock Effects_two(pId)
{
	if(!is_user_connected(pId) || jbe_is_user_blind(pId)) return 0;
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] Effects_two");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0,0,0}, pId);
	write_short(1<<12);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(75);
	write_byte(0);
	write_byte(255);
	write_byte(75);
	message_end();
	
	return 0;
}


public FakeMeta_EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(jbe_is_user_valid(id))
	{
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e')
		{
			if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id))
			{
				fVolume = (fVolume / SOUND_VALUE);
				switch(szSample[17])
				{
					case 'l':
					{
						if(IsSetBit(g_iBitUserMolot, id)) emit_sound(id, iChannel, g_szKnifeSound[MOLOT_DEPLOY], fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
						else if(IsSetBit(g_iBitUserSaw, id)) emit_sound(id, iChannel, g_szKnifeSound[SAW_DEPLOY], fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
					}
					case 'w':
					{
						if(IsSetBit(g_iBitUserMolot, id)) emit_sound(id, iChannel, g_szKnifeSound[MOLOT_HITWALL], fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
						else if(IsSetBit(g_iBitUserSaw, id)) emit_sound(id, iChannel, g_szKnifeSound[SAW_HITWALL], fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
					}
					case 's':
					{
						if(IsSetBit(g_iBitUserMolot, id)) emit_sound(id, iChannel, g_szKnifeSound[MOLOT_SLASH], fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
						else if(IsSetBit(g_iBitUserSaw, id)) emit_sound(id, iChannel, g_szKnifeSound[SAW_SLASH], fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
					}
					case 'b':
					{
						if(IsSetBit(g_iBitUserMolot, id)) emit_sound(id, iChannel, g_szKnifeSound[MOLOT_STAB], fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
						else if(IsSetBit(g_iBitUserSaw, id)) emit_sound(id, iChannel, g_szKnifeSound[SAW_STAB], fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					}
					default:
					{
						if(IsSetBit(g_iBitUserMolot, id)) emit_sound(id, iChannel, g_szKnifeSound[MOLOT_HIT], fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						else if(IsSetBit(g_iBitUserSaw, id)) emit_sound(id, iChannel, g_szKnifeSound[SAW_HIT], fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
					}
				}
				return FMRES_SUPERCEDE;
			}
		}
	}
	return FMRES_IGNORED;
}

public CBasePlayerWeapon_DefaultDeploy_Pre(const iEntity, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) {

    if (FClassnameIs(iEntity, ITEM_CLASSNAME)) 
	{
		new pId = get_member(iEntity, m_pPlayer);
		
		if(IsSetBit(g_iBitUserMolot, pId))
		{
			SetHookChainArg(2, ATYPE_STRING, g_szPlayerHand[MOLOT_V]);
			SetHookChainArg(3, ATYPE_STRING, g_szPlayerHand[MOLOT_P]);
			set_member(pId, m_flNextAttack, 0.9);
		}
		if(IsSetBit(g_iBitUserSaw, pId))
		{
			SetHookChainArg(2, ATYPE_STRING, g_szPlayerHand[SAW_V]);
			SetHookChainArg(3, ATYPE_STRING, g_szPlayerHand[SAW_P]);
			set_member(pId, m_flNextAttack, 0.9);
		}
		if(IsSetBit(g_iBitUserElectroShoker, pId) && jbe_get_user_team(pId) == 2)
		{
			SetHookChainArg(2, ATYPE_STRING, g_szPlayerHand[ELECTRO_V]);
			SetHookChainArg(3, ATYPE_STRING, g_szPlayerHand[ELECTRO_P]);
			set_member(pId, m_flNextAttack, 0.9);
		}	
    }
	return HC_CONTINUE;
}

/*public Ham_KnifeDeploy_Post(iEntity)
{
	new id = get_member(iEntity, m_pPlayer);
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id))
	{
		if(IsSetBit(g_iBitUserMolot, id)) jbe_set_molot_model(id);
		if(IsSetBit(g_iBitUserSaw, id)) jbe_set_saw_model(id);
		return;
	}
	if(IsSetBit(g_iBitUserElectroShoker, id) && jbe_get_user_team(id) == 2)
	{
		jbe_set_electro_model(id);
		return;
	}
}*/

public jbe_day_mode_start(iDayMode, iAdmin)
{
	if(iAdmin)
	{
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if(!jbe_is_user_alive(iPlayer)) continue;
			if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, iPlayer))
			{
				ClearBit(g_iBitWeaponStatus, iPlayer);
				if(get_user_weapon(iPlayer) == CSW_KNIFE)
				{
					new iActiveItem = get_member(iPlayer, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
			}
			if(g_iBitUserAntiGravity && IsSetBit(g_iBitUserAntiGravity, iPlayer))
			{
				ClearBit(g_iBitUserAntiGravity, iPlayer);
				if(task_exists(iPlayer+TASK_ANTIGRAVITY)) remove_task(iPlayer+TASK_ANTIGRAVITY);
			}
			if(g_iBitUserFrozen && IsSetBit(g_iBitUserFrozen, iPlayer))
			{
				ClearBit(g_iBitUserFrozen, iPlayer);
				if(task_exists(iPlayer+TASK_FROSTNADE_DEFROST)) remove_task(iPlayer+TASK_FROSTNADE_DEFROST);
			}
			
			if(g_iBitUserGalogramma && IsSetBit(g_iBitUserGalogramma, iPlayer))
			{
				ClearBit(g_iBitUserGalogramma, iPlayer);
				if(task_exists(iPlayer+TASK_GALOGRAMMA_DE)) remove_task(iPlayer+TASK_GALOGRAMMA_DE);
			}
		}
	}
}



public FakeMeta_SetModel(iEntity, szModel[])
{
	if((g_iBitAntiGravity || g_iBitRemoveGun) && szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'm')
	{
		new iOwner = get_entvar(iEntity, var_owner);
		if(IsSetBit(g_iBitAntiGravity, iOwner) && jbe_get_user_team(iOwner) == 1)
		{
			set_entvar(iEntity, var_iuser1, IUSER1_ANTIGRAVITY_KEY);
			ClearBit(g_iBitAntiGravity, iOwner);
			CREATE_BEAMFOLLOW(iEntity, g_pSpriteBeam, 10, 10, 0, 255, 255, 255);
		}
		if(IsSetBit(g_iBitRemoveGun, iOwner) && jbe_get_user_team(iOwner) == 2)
		{
			set_entvar(iEntity, var_iuser1, IUSER1_REMOVEGUN_KEY);
			ClearBit(g_iBitRemoveGun, iOwner);
			CREATE_BEAMFOLLOW(iEntity, g_pSpriteBeam, 10, 10, 0, 255, 255, 255);
			UTIL_SayText(0, "!g* !yОхрана бросил обезоруживающий гранату!");
		}
	}

	if(g_iBitFrostNade && szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'f' && szModel[10] == 'l')
	{
		new iOwner = get_entvar(iEntity, var_owner);
		if(IsSetBit(g_iBitFrostNade, iOwner) && jbe_get_user_team(iOwner) == 1)
		{
			set_entvar(iEntity, var_iuser1, IUSER1_FROSTNADE_KEY);
			ClearBit(g_iBitFrostNade, iOwner);
			CREATE_BEAMFOLLOW(iEntity, g_pSpriteBeam, 10, 10, 0, 110, 255, 200);
		}
	}
	if(g_iBitGalogramma && szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'h' && szModel[10] == 'e')
	{
		new iOwner = get_entvar(iEntity, var_owner);
		if(IsSetBit(g_iBitGalogramma, iOwner) && jbe_get_user_team(iOwner) == 1)
		{
			set_entvar(iEntity, var_iuser1, IUSER1_GALOGRAMMA_KEY);
			ClearBit(g_iBitGalogramma, iOwner);
			CREATE_BEAMFOLLOW(iEntity, g_pSpriteBeam, 10, 10, 0, 110, 100, 100);
		}
	}
	
}

enum //Координаты вращения
{
	Float:x = 400.0, 	// x
	Float:y = 999.0, 	// y
	Float:z = 400.0 	// z
}

public Ham_GrenadeTouch_Post(iTouched)
{
	if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
	{
		new Float:vecOrigin[3], pId;
		get_entvar(iTouched, var_origin, vecOrigin);
		
		
		if(get_entvar(iTouched, var_iuser1) == IUSER1_ANTIGRAVITY_KEY)
		{
			while((pId = engfunc(EngFunc_FindEntityInSphere, pId, vecOrigin, 150.0)))
			{
				if(jbe_is_user_valid(pId) && jbe_get_user_team(pId) == 1)
				{
					set_entvar(pId, var_gravity, 0.000001);
					set_entvar(pId, var_velocity, {0.0, 0.0, 100.0});
					user_slap(pId, 0,0);
					UTIL_SendAudio(pId, _, "jb_engine/shop/heartbomb_exp.wav");
					SetBit(g_iBitUserAntiGravity, pId);
					
					if(task_exists(pId+TASK_ANTIGRAVITY)) change_task(pId+TASK_ANTIGRAVITY, 1.0);
					else set_task_ex(1.0, "jbe_user_degravity", pId+TASK_ANTIGRAVITY);
				}
			}
			CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 110, 255, 255, _);
			engfunc(EngFunc_RemoveEntity, iTouched);
		}
		else
		if(get_entvar(iTouched, var_iuser1) == IUSER1_REMOVEGUN_KEY)
		{
			while((pId = engfunc(EngFunc_FindEntityInSphere, pId, vecOrigin, 150.0)))
			{
				if(jbe_is_user_valid(pId) && jbe_get_user_team(pId) == 1)
				{
					rg_remove_all_items(pId);
					rg_give_item(pId, "weapon_knife");
					UTIL_SayText(pId, "!g* !yВы были обезаружены");
				}
			}
			CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 110, 255, 255, _);
			engfunc(EngFunc_RemoveEntity, iTouched);
		}
		else
		if(get_entvar(iTouched, var_iuser1) == IUSER1_FROSTNADE_KEY)
		{
			while((pId = engfunc(EngFunc_FindEntityInSphere, pId, vecOrigin, 150.0)))
			{
				if(jbe_is_user_valid(pId) && jbe_get_user_team(pId) == 2)
				{
					/*
					set_entvar(pId, var_flags, get_entvar(pId, var_flags) | FL_FROZEN);
					set_pdata_float(pId, m_flNextAttack, 6.0, linux_diff_player);
					jbe_set_user_rendering(pId, kRenderFxGlowShell, 0, 110, 255, kRenderNormal, 0);
					UTIL_SendAudio(pId, _, "jb_engine/shop/heartbomb_exp.wav");
					SetBit(g_iBitUserFrozen, pId);
					if(task_exists(pId+TASK_FROSTNADE_DEFROST)) change_task(pId+TASK_FROSTNADE_DEFROST, 6.0);
					else set_task_ex(6.0, "jbe_user_defrost", pId+TASK_FROSTNADE_DEFROST);*/
					
					if(!get_frozen_status(pId)) 
					{
						set_frozen_status(pId);
						if(task_exists(pId+TASK_FROSTNADE_DEFROST)) change_task(pId+TASK_FROSTNADE_DEFROST, 6.0);
						else set_task_ex(6.0, "jbe_user_defrost", pId+TASK_FROSTNADE_DEFROST);
						UTIL_SendAudio(pId, _, "jb_engine/shop/heartbomb_exp.wav");
					}
				}
			}
			CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 110, 255, 255, _);
			engfunc(EngFunc_RemoveEntity, iTouched);
		}
		else
		if(get_entvar(iTouched, var_iuser1) == IUSER1_GALOGRAMMA_KEY)
		{
			while((pId = engfunc(EngFunc_FindEntityInSphere, pId, vecOrigin, 150.0)))
			{
				if(jbe_is_user_valid(pId))
				{
					set_entvar(pId, var_punchangle, Float:{x, y, z});
					Effects_one(pId);
					SetBit(g_iBitUserGalogramma, pId);
					UTIL_SendAudio(pId, _, "jb_engine/shop/heartbomb_exp.wav");
					if(task_exists(pId+TASK_GALOGRAMMA_DE)) change_task(pId+TASK_GALOGRAMMA_DE, 5.0);
					else set_task_ex(5.0, "jbe_user_galogramm", pId+TASK_GALOGRAMMA_DE);
				}
			}
			CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 110, 255, 255, _);
			engfunc(EngFunc_RemoveEntity, iTouched);
			
		}
		
	}
}

public jbe_user_degravity(pPlayer)
{
	pPlayer -= TASK_ANTIGRAVITY;
	if(IsNotSetBit(g_iBitUserAntiGravity, pPlayer) || !jbe_is_user_alive(pPlayer)) return;
	ClearBit(g_iBitUserAntiGravity, pPlayer);
	set_pev(pPlayer, pev_gravity, 1.0);
}

public jbe_user_defrost(pPlayer)
{
	pPlayer -= TASK_FROSTNADE_DEFROST;
	
	if(get_frozen_status(pPlayer)) set_frozen_status(pPlayer);
	/*
	if(IsNotSetBit(g_iBitUserFrozen, pPlayer)) return;
	ClearBit(g_iBitUserFrozen, pPlayer);
	set_entvar(pPlayer, var_flags, get_entvar(pPlayer, var_flags) & ~FL_FROZEN);
	set_pdata_float(pPlayer, m_flNextAttack, 0.0, linux_diff_player);
	jbe_set_user_rendering(pPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	new Float:vecOrigin[3]; 
	get_entvar(pPlayer, var_origin, vecOrigin);
	CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_pModelGlass, 10, 25, 0x01);*/
}

public jbe_user_galogramm(pPlayer)
{
	pPlayer -= TASK_GALOGRAMMA_DE;
	if(IsNotSetBit(g_iBitUserGalogramma, pPlayer)) return;
	ClearBit(g_iBitUserGalogramma, pPlayer);
}

public Event_CurWeapon(pId)
{
	if(IsNotSetBit(g_iBitUserUnlimAmmo, pId))
		return PLUGIN_CONTINUE;

	enum { weapon = 2 };

	new iWeapon = read_data(weapon);

	new iClip = rg_get_weapon_info(iWeapon, WI_GUN_CLIP_SIZE);

	if(iClip < 0)
		return PLUGIN_CONTINUE;

	rg_set_weapon_ammo(get_member(pId, m_pActiveItem), iClip + 1);

	return PLUGIN_CONTINUE;
}



/*jbe_set_molot_model(pPlayer)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szPlayerHand[MOLOT_V]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szPlayerHand[MOLOT_P]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_pdata_float(pPlayer, m_flNextAttack, 0.9);
}

jbe_set_electro_model(pPlayer)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szPlayerHand[ELECTRO_V]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szPlayerHand[ELECTRO_P]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_pdata_float(pPlayer, m_flNextAttack, 0.9);
}

jbe_set_saw_model(pPlayer)
{
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szPlayerHand[SAW_V]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szPlayerHand[SAW_P]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_pdata_float(pPlayer, m_flNextAttack, 0.9);
}*/

public jbe_task_regen(pId)
{
	pId -= TASK_REGEN_HP;
	
	
	if(get_user_health(pId) <= 150 && /*!jbe_is_user_boxing(pId) && */!jbe_iduel_status())
	{
		new Float:Healt = get_entvar(pId, var_health);
		set_entvar(pId, var_health, Healt + 1.0);
	}
}

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

stock CREATE_BEAMFOLLOW(pEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] CREATE_BEAMFOLLOW");
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

stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32.0 + iRadius * 2);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock CREATE_BREAKMODEL(Float:vecOrigin[3], Float:vecSize[3] = {16.0, 16.0, 16.0}, Float:vecVelocity[3] = {25.0, 25.0, 25.0}, iRandomVelocity, pModel, iCount, iLife, iFlags)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 24);
	engfunc(EngFunc_WriteCoord, vecSize[0]);
	engfunc(EngFunc_WriteCoord, vecSize[1]);
	engfunc(EngFunc_WriteCoord, vecSize[2]);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(pModel);
	write_byte(iCount); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iFlags); // BREAK_GLASS 0x01, BREAK_METAL 0x02, BREAK_FLESH 0x04, BREAK_WOOD 0x08
	message_end();
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] UTIL_ScreenFade");
	}
	
	switch(pPlayer)
	{
		case 0:
		{
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MsgId_ScreenFade);
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
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
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

stock UTIL_SendAudio(pPlayer, iPitch = 100, const szPathSound[], any:...)
{

	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[SHOP_ADDONS] UTIL_SendAudio");
	}
	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
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

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
}

stock get_ending(num, const a[], const b[], const c[], lenght, output[])
{
	new num100 = num % 100, num10 = num % 10;
	if(num100 >= 5 && num100 <= 20 || num10 == 0 || num10 >= 5 && num10 <= 9)
		format(output, lenght, "%s", a);
	else if(num10 == 1)
		format(output, lenght, "%s", b);
	else if(num10 >= 2 && num10 <= 4)
		format(output, lenght, "%s", c);
}

public jbe_remove_shop_pn(pId)
{
	ClearBit(g_iBitFastRun, pId);
	
	ClearBit(g_iBitAutoBhop, pId);
	ClearBit(g_iBitDoubleDamage, pId);

	ClearBit(g_iBitRandomGlow, pId);
	
	ClearBit(g_iBitUserMolot, pId);
	ClearBit(g_iBitUserSaw, pId);
	
	
	if(get_user_weapon(pId) == CSW_KNIFE)
	{
		new iActiveItem = get_member(pId, m_pActiveItem);
		if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
	}
}

public jbe_load_stats(id)
{
	//g_iButt[id] = jbe_mysql_stats_systems_get(id, 10);
	//g_iChips[id] = jbe_mysql_stats_systems_get(id, 34);
	
	//server_print("%d | %d", g_iButt[id], g_iChips[id]);
}



public jbe_save_stats(id)
{
	//server_print("%d | %d", g_iButt[id], g_iChips[id]);
	//jbe_mysql_stats_systems_add(id, 10, g_iButt[id]);
	//jbe_mysql_stats_systems_add(id, 34, g_iChips[id]);
	//g_iChips[id] = 0;
	//g_iButt[id] = 0;
}

stock is_enable()
{
	if(jbe_status_block(0)) return true;
	else return false;
}

