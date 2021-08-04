#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>
#include <hamsandwich>
#include <reapi>

new g_iGlobalDebug;
#include <util_saytext>




#define ONLY_DEFAULT				//Стандартая система
//#define DEBUG_LOG					//режим разработчика


native jbe_has_user_weaponknife(iPlayer);

enum ak47_e
{
	KNIFE_DUMMY,
	KNIFE_IDLE1,
	KNIFE_RELOAD,
	KNIFE_DRAW,
	KNIFE_SHOOT1,
	KNIFE_SHOOT2,
	KNIFE_SHOOT3
};


enum _:SOUND_EVENTS
{
	SOUND_DEPLOY,
	SOUND_HITWALL,
	SOUND_STAB,
	SOUND_SLASH,
	SOUND_HIT
}

enum
{
	SELECT_PRISON = 1,
	SELECT_GUARD,
	SELECT_CVARS,
	SELECT_SOUND
};

new g_szSound[SOUND_EVENTS][64];


new bool:g_iDoorStatus;

#define PLAYERS_PER_PAGE 	8
	

#define WEAPON_REFERANCE			"weapon_knife"

// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41
const m_pActiveItem = 373;
#define m_pPlayer   41
#define m_flNextAttack  83
#define linux_diff_weapon  4
#define m_flLastEventCheck 38
#define linux_diff_animating 4
// CBasePlayerWeapon
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const PDATA_SAFE = 2


#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_iDirection			60
#define m_flAccuracy 			62
#define m_iShotsFired			64
#define m_fWeaponState			74
#define m_iLastZoom 			109
#define m_fResumeZoom      		110

#define IsValidPev(%0) 			(pev_valid(%0) == 2)



#define m_rgAmmo_CBasePlayer		376

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define WEAPON_TIME_NEXT_ATTACK 		0.5

#define _call.%0(%1,%2) \
								\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

native jbe_get_user_ranks(pId);
native jbe_iduel_status();
native get_login(pId);
native jbe_restartgame();

new g_iMenuPosition[MAX_PLAYERS + 1];


enum eData_Players
{
	eData_Index,
	eData_Skin,
	eData_Damage
};

new g_iPlayerData[MAX_PLAYERS + 1][eData_Players];

enum _:DATA_SKIN_INFO
{
	SKIN_INDEX[2],
	SKIN_NAME[32],
	V_MODEL[64],
	P_MODEL[64],
	BODY_NUM[2],
	WEAPON_LEVEL[5],
	WEAPON_DAMAGE[5]
};
new Array:g_aWeaponSkins, g_iWeaponSkinsCount;

#if !defined ONLY_DEFAULT
new g_iFakeMetaUpdateClientData;
new HamHook:g_iHamHookForwards[3];
new HookChain:g_iHookChainForwards;
#endif

new g_iFakeMetaEmitSound;

public plugin_init()
{
	register_menucmd(register_menuid("Show_WeaponsGuardMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_WeaponsGuardMenu");
	
	#if !defined ONLY_DEFAULT
	
	register_clcmd("say /knifedsaawd", 						"openmenu");
	register_clcmd("knifeadwad", 							"openmenu");
	#endif
	
	
	RegisterHam(Ham_Item_Deploy, 				"weapon_knife", 											"Ham_KnifeDeploy_Post", 				true);
	
	#if !defined ONLY_DEFAULT
	
	DisableHamForward(g_iHamHookForwards[1] = RegisterHam(Ham_Weapon_PrimaryAttack,	"weapon_knife", 		"HamHook_Item_PrimaryAttack",	false));
	DisableHamForward(g_iHamHookForwards[2] = RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", 		"HamHook_Item_SecondaryAttack",	false));
	DisableHookChain(g_iHookChainForwards =  RegisterHookChain(RG_CBasePlayer_TraceAttack,					"HC_CBasePlayer_TraceAttack_Player", 	false));
	g_iFakeMetaUpdateClientData = 	register_forward(FM_UpdateClientData, 									"FM_Hook_UpdateClientData_Post", 1);
	unregister_forward(FM_UpdateClientData, 	g_iFakeMetaUpdateClientData);
	#endif
	
	
	g_iFakeMetaEmitSound 		= 	register_forward(FM_EmitSound, 											"FakeMeta_EmitSound", false);
	unregister_forward(FM_EmitSound, 			g_iFakeMetaEmitSound);
	
}


#if !defined DEBUG_LOG
public jbe_fwd_door_status(DoorStatus)
{
	if(DoorStatus && !g_iDoorStatus)
		g_iDoorStatus = true;
}
#endif

public jbe_fwr_event_hltv()
{
	g_iDoorStatus = false;
}

public jbe_fwr_restart_game(iType)
{
	if(iType == 0)
	{
		#if !defined ONLY_DEFAULT
		
		g_iFakeMetaUpdateClientData = 	register_forward(FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", 1);
		
		EnableHamForward(g_iHamHookForwards[1]);
		EnableHamForward(g_iHamHookForwards[2]);
		EnableHookChain(g_iHookChainForwards);
		#endif
		
		g_iFakeMetaEmitSound 		= 	register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
	}

}

public Ham_KnifeDeploy_Post(iEntity)
{

	// Get weapon's owner
	static pId
	pId = fm_cs_get_weapon_ent_owner(iEntity)
	
	// Valid owner?
	if (!pev_valid(pId))
		return;

	if(!jbe_is_user_connected(pId) || !jbe_is_user_alive(pId) || jbe_has_user_weaponknife(pId))
		return;
	
	if(jbe_restartgame())
		return;
		
	#if defined ONLY_DEFAULT
	
	new aDataSkinInfo[DATA_SKIN_INFO];
	
	ArrayGetArray(g_aWeaponSkins, 0, aDataSkinInfo);
			
	if(aDataSkinInfo[V_MODEL]) set_pev(pId, pev_viewmodel, aDataSkinInfo[V_MODEL]);
	if(aDataSkinInfo[P_MODEL]) set_pev(pId, pev_weaponmodel, aDataSkinInfo[P_MODEL]);
	
	#else

	new aDataSkinInfo[DATA_SKIN_INFO];
	
	if(jbe_get_day_mode() || jbe_get_day_mode() < 3)
	{
		if(jbe_get_user_team(pId) == 2)
		{
			ArrayGetArray(g_aWeaponSkins, 0, aDataSkinInfo);
			
			if(aDataSkinInfo[V_MODEL]) set_pev(pId, pev_viewmodel, aDataSkinInfo[V_MODEL]);
			if(aDataSkinInfo[P_MODEL]) set_pev(pId, pev_weaponmodel, aDataSkinInfo[P_MODEL]);
		}
		else
		{
			
			ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);
			
			if(aDataSkinInfo[V_MODEL]) set_pev(pId, pev_viewmodel, aDataSkinInfo[V_MODEL]);
			if(aDataSkinInfo[P_MODEL]) set_pev(pId, pev_weaponmodel, aDataSkinInfo[P_MODEL]);
			
			set_pdata_float( iEntity, m_flLastEventCheck, get_gametime( ) + 0.2 , linux_diff_animating);
			SendWeaponAnim( pId, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]) );
		}
	}
	else
	{
		ArrayGetArray(g_aWeaponSkins, 0, aDataSkinInfo);
			
		if(aDataSkinInfo[V_MODEL]) set_pev(pId, pev_viewmodel, aDataSkinInfo[V_MODEL]);
		if(aDataSkinInfo[P_MODEL]) set_pev(pId, pev_weaponmodel, aDataSkinInfo[P_MODEL]);
	}
	
	#endif
	
}



public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.PrimaryAttack(iItem, iPlayer);
	return HAM_IGNORED;
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}


public HamHook_Item_SecondaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.SecondaryAttack(iItem, iPlayer);
	return HAM_IGNORED;
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !jbe_is_user_connected( iPlayer) || !g_iPlayerData[iPlayer][eData_Skin])
	{
		return false;
	}
	
	return true;
}

Weapon_OnFire(const iPlayer, const iItem, const Float:iTime, const iAnim)
{
	set_pdata_float(iItem, m_flTimeWeaponIdle, iTime, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, iTime, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, iTime, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, iAnim);
}
Weapon_SendAnim(const iPlayer, const iAnim)
{

	new aDataSkinInfo[DATA_SKIN_INFO];
	ArrayGetArray(g_aWeaponSkins, g_iPlayerData[iPlayer][eData_Skin], aDataSkinInfo);

	set_pev(iPlayer, pev_weaponanim, iAnim);

	if(jbe_is_user_connected(iPlayer))
	{
		MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
		WRITE_BYTE(iAnim);
		WRITE_BYTE(aDataSkinInfo[BODY_NUM]);
		MESSAGE_END();
	}
}


Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iClip
	
	Weapon_OnFire(iPlayer, iItem, WEAPON_TIME_NEXT_ATTACK, KNIFE_SHOOT1);
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iClip
	
	
	Weapon_OnFire(iPlayer, iItem, WEAPON_TIME_NEXT_ATTACK, KNIFE_SHOOT3);
}

public FakeMeta_EmitSound(pId, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(jbe_is_user_valid(pId))
	{
	
		if(jbe_has_user_weaponknife(pId))
			return FMRES_IGNORED;
			
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e')
		{
			switch(szSample[17])
			{
				case 'l': emit_sound(pId, iChannel, g_szSound[SOUND_DEPLOY] , fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
				case 'w': emit_sound(pId, iChannel, g_szSound[SOUND_HITWALL], fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
				case 's': emit_sound(pId, iChannel, g_szSound[SOUND_SLASH], fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
				case 'b': emit_sound(pId, iChannel, g_szSound[SOUND_STAB], fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
				default: emit_sound(pId, iChannel, g_szSound[SOUND_HIT], fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
			}
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}


public openmenu(pId) return Cmd_WeaponsGuardMenu(pId);
public plugin_precache()
{
	LOAD_CONFIGURATION();
	
	
	new szCfgDir[64], szCfgFile[128]; 
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/knife_systems.ini", szCfgDir);
	new file = fopen(szCfgFile, "rt");
	if(!file)
	{
		new error[100];
		formatex(error, charsmax(error), "[JBE] Отсутсвтует: %s!", szCfgFile);
		set_fail_state(error);
		return;
	}
	g_aWeaponSkins = ArrayCreate(DATA_SKIN_INFO, 1);
	new szBuffer[512], aDataSkinInfo[DATA_SKIN_INFO];
	while(!feof(file))
	{
		fgets(file, szBuffer, charsmax(szBuffer));
		if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#') continue;
		parse(szBuffer, 
		aDataSkinInfo[SKIN_NAME],		charsmax(aDataSkinInfo[SKIN_NAME]), 
		aDataSkinInfo[V_MODEL],			charsmax(aDataSkinInfo[V_MODEL]), 
		aDataSkinInfo[P_MODEL],			charsmax(aDataSkinInfo[P_MODEL]), 
		aDataSkinInfo[BODY_NUM],		charsmax(aDataSkinInfo[BODY_NUM]),
		aDataSkinInfo[WEAPON_LEVEL],	charsmax(aDataSkinInfo[WEAPON_LEVEL]),
		aDataSkinInfo[WEAPON_DAMAGE],	charsmax(aDataSkinInfo[WEAPON_DAMAGE])
		);
		
		
		
		if(file_exists(aDataSkinInfo[V_MODEL])) 
		{ 
			precache_model(aDataSkinInfo[V_MODEL]); 
			aDataSkinInfo[V_MODEL] = engfunc(EngFunc_AllocString, aDataSkinInfo[V_MODEL]); 
		}
		
		if(file_exists(aDataSkinInfo[P_MODEL])) 
		{ 
			precache_model(aDataSkinInfo[P_MODEL]); 
			aDataSkinInfo[P_MODEL] = engfunc(EngFunc_AllocString, aDataSkinInfo[P_MODEL]); 
		}
		
		aDataSkinInfo[SKIN_INDEX]++;
		
		#if defined DEBUG_LOG
		server_print("%s | %s", aDataSkinInfo[SKIN_NAME], aDataSkinInfo[WEAPON_LEVEL]);
		#endif
		ArrayPushArray(g_aWeaponSkins, aDataSkinInfo);
		
		aDataSkinInfo[V_MODEL] = 0; 
		aDataSkinInfo[P_MODEL] = 0; 
	}
	fclose(file);
	
	g_iWeaponSkinsCount = ArraySize( g_aWeaponSkins );
	
	if(!g_iWeaponSkinsCount /*|| g_iWeaponSkinsCount > 9*/)
	{
		ArrayDestroy(g_aWeaponSkins);
		set_fail_state("[JBE] ERROR. g_iWeaponSkinsCount is empty!");
	}
}

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
			
			}
			case SELECT_GUARD:
			{
			
			}
			case SELECT_CVARS:
			{

			}
			case SELECT_SOUND:
			{
				if(equal(szKey, 			"SOUND_DEPLOY"))						formatex(g_szSound[SOUND_DEPLOY], 				charsmax(g_szSound[]), szValue);
				else if(equal(szKey, 		"SOUND_HITWALL"))						formatex(g_szSound[SOUND_HITWALL], 				charsmax(g_szSound[]), szValue);
				else if(equal(szKey, 		"SOUND_SLASH"))							formatex(g_szSound[SOUND_SLASH], 				charsmax(g_szSound[]), szValue);
				else if(equal(szKey, 		"SOUND_STAB"))							formatex(g_szSound[SOUND_STAB], 				charsmax(g_szSound[]), szValue);
				else if(equal(szKey, 		"SOUND_HIT"))							formatex(g_szSound[SOUND_HIT], 					charsmax(g_szSound[]), szValue);
			}
			
		}
		
	}
	fclose(iFile);

	PRECACHE_MODELS();
}

PRECACHE_MODELS()
{
	new i, szBuffer[64];

	for(i = 0; i < sizeof(g_szSound); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "%s", g_szSound[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
}

Cmd_WeaponsGuardMenu(id) return Show_WeaponsGuardMenu(id, g_iMenuPosition[id] = 0);

Show_WeaponsGuardMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new g_ArraySize = ArraySize( g_aWeaponSkins );
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_ArraySize ) iStart = g_ArraySize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_ArraySize) iEnd = g_ArraySize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_ArraySize / PLAYERS_PER_PAGE + ((g_ArraySize % PLAYERS_PER_PAGE) ? 1 : 0));
	
	new aDataSkinInfo[DATA_SKIN_INFO];
	
	FormatMain("\yВыберите перчатки \d[%d|%d]^n^n", iPos + 1, iPagesNum);
	new iKeys = (1<<9), b;
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aWeaponSkins, a, aDataSkinInfo);
		
		if(jbe_get_user_ranks(pId) >= str_to_num(aDataSkinInfo[WEAPON_LEVEL]))
		{
			
			if(g_iPlayerData[pId][eData_Skin] == a)
			{
				FormatItem("\y%d. \d%s \y-Текущий^n", ++b, aDataSkinInfo[SKIN_NAME]);
			}
			else
			{
				iKeys |= (1<<b);
				FormatItem("\y%d. \w%s^n", ++b, aDataSkinInfo[SKIN_NAME]);
			}
		}
		else 
		{
			if(!get_login(pId))
			{
				FormatItem("\y%d. \d%s^n", ++b, aDataSkinInfo[SKIN_NAME]);
			}
			else
			{
				FormatItem("\y%d. \d%s \r-%s уровень^n", ++b, aDataSkinInfo[SKIN_NAME], aDataSkinInfo[WEAPON_LEVEL]);
			}
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_ArraySize)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \w%L^n\y0. \w%L", pId, "JBE_MENU_NEXT", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else FormatItem("^n^n\y0. \w%L", pId, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(pId, iKeys, szMenu, -1, "Show_WeaponsGuardMenu");
}

public Handle_WeaponsGuardMenu(pId, iKey)
{
	switch(iKey)
	{
		case 8: return Show_WeaponsGuardMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_WeaponsGuardMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			if(g_iDoorStatus && iKey != 0)
			{
				UTIL_SayText(pId, "!g* !yКлетки были открыты, выбор перчаток запрещены!")
				return PLUGIN_HANDLED;
			}
			new aDataSkinInfo[DATA_SKIN_INFO];
			
			new iArrayIndex = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			ArrayGetArray(g_aWeaponSkins, iArrayIndex, aDataSkinInfo);
			
			if(!get_login(pId) && (iKey != 0 || str_to_num(aDataSkinInfo[WEAPON_LEVEL]) > 0))
			{
				UTIL_SayText(pId, "!g* !yДанный тип перчаток не доступно вам, !gавторизуйтесь");
				return Cmd_WeaponsGuardMenu(pId)
			}
			if(jbe_get_user_ranks(pId) < str_to_num(aDataSkinInfo[WEAPON_LEVEL]))
			{
				UTIL_SayText(pId, "!g* !yК сожелению у вас низкий уровень для данного тип перчаток, необходимый уровень: !g%d", str_to_num(aDataSkinInfo[WEAPON_LEVEL]));
				return Cmd_WeaponsGuardMenu(pId)
			}
			if(jbe_get_user_team(pId) == 2 && iKey != 0)
			{
				UTIL_SayText(pId, "!g* !yПерчатки доступны только заключенным");
				return PLUGIN_HANDLED;
			}
			g_iPlayerData[pId][eData_Index] = aDataSkinInfo[SKIN_INDEX];
			g_iPlayerData[pId][eData_Skin] = iArrayIndex;
			
			if(aDataSkinInfo[WEAPON_DAMAGE]) g_iPlayerData[pId][eData_Damage] = str_to_num(aDataSkinInfo[WEAPON_DAMAGE]);
			else g_iPlayerData[pId][eData_Damage] = 0;
			
			if(iKey != 0 && jbe_get_user_team(pId) == 1)
			{
				new szMenu[180], iLen;
				
				iLen = formatex(szMenu[iLen],charsmax(szMenu) - iLen, "!g* !yВы надели перчатки !g%s!y.", aDataSkinInfo[SKIN_NAME]);
				
				
				if(str_to_num(aDataSkinInfo[WEAPON_DAMAGE]) != 0 ) iLen += formatex(szMenu[iLen],charsmax(szMenu) - iLen, "Процент прибавки урона: !g%d%%.", str_to_num(aDataSkinInfo[WEAPON_DAMAGE]));
				
				UTIL_SayText(pId, "%s", szMenu);
			}
			
			if(has_knife_in_hand(pId))
			{
				new iActiveItem = get_member(pId, m_pActiveItem);
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				if(aDataSkinInfo[BODY_NUM])  SendWeaponAnim( pId, KNIFE_DRAW, aDataSkinInfo[BODY_NUM]);
			}
		}
	}
	return Show_WeaponsGuardMenu(pId, g_iMenuPosition[pId]);
}



stock bool:has_knife_in_hand(id){

    if(!jbe_is_user_alive(id)) return false;

    new iEnt = get_member(id, m_pActiveItem);
    if(!is_entity(iEnt)) return false;

    return (get_member(iEnt, m_iId) == WEAPON_KNIFE) ? true : false;
}






public FM_Hook_UpdateClientData_Post( iPlayer, SendWeapons, CD_Handle )
{
	if(!pev_valid(iPlayer) || !jbe_is_user_alive(iPlayer)) return FMRES_IGNORED;
	
	if(jbe_has_user_weaponknife(iPlayer)) return FMRES_IGNORED;
	
	enum
	{
		SPEC_MODE,
		SPEC_TARGET,

		SPEC_END

	}; static aSpecInfo[ 33 ][ SPEC_END ];

	static Float: flGameTime;
	static Float: flLastEventCheck;

	static iTarget;
	static iSpecMode;
	static iActiveItem;
	static iId;

	iTarget = ( iSpecMode = get_entvar( iPlayer, var_iuser1 ) ) ? get_entvar( iPlayer, var_iuser2 ) : iPlayer;

	iActiveItem = get_member( iTarget, m_pActiveItem );

	if( iActiveItem == NULLENT || !g_iPlayerData[iTarget][eData_Skin])
		return FMRES_IGNORED;
		
	iId = get_member( iActiveItem, m_iId );
	
	if( iId != CSW_KNIFE )
		return FMRES_IGNORED;
	

	flGameTime = get_gametime( );
	flLastEventCheck = get_pdata_float( iActiveItem, m_flLastEventCheck );

	if( iId == CSW_KNIFE )
	{
		if(!g_iPlayerData[iPlayer][eData_Skin])
			return FMRES_IGNORED;
			
		new aDataSkinInfo[DATA_SKIN_INFO];
		ArrayGetArray(g_aWeaponSkins, g_iPlayerData[iPlayer][eData_Skin], aDataSkinInfo);
		
		
		if( iSpecMode )
		{
			if( aSpecInfo[ iPlayer ][ SPEC_MODE ] != iSpecMode )
			{
				aSpecInfo[ iPlayer ][ SPEC_MODE ] = iSpecMode;
				aSpecInfo[ iPlayer ][ SPEC_TARGET ] = 0;
			}

			if( iSpecMode == OBS_IN_EYE && aSpecInfo[ iPlayer ][ SPEC_TARGET ] != iTarget )
			{
				aSpecInfo[ iPlayer ][ SPEC_TARGET ] = iTarget;

				SendWeaponAnim( iPlayer, KNIFE_DRAW, aDataSkinInfo[BODY_NUM] );
			}
		}

		if( !flLastEventCheck )
		{
			set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
			set_cd( CD_Handle, CD_WeaponAnim, KNIFE_DRAW );
			//SendWeaponAnim( iTarget, KNIFE_DUMMY, aDataSkinInfo[BODY_NUM]);
			//return FMRES_SUPERCEDE;
			return FMRES_IGNORED;
		}

		if( flLastEventCheck <= flGameTime )
		{
			SendWeaponAnim( iTarget, KNIFE_DRAW, aDataSkinInfo[BODY_NUM]);

			set_pdata_float( iActiveItem, m_flLastEventCheck, 0.0, linux_diff_animating );
		}
	}

	return FMRES_IGNORED;
}

stock SendWeaponAnim( iPlayer, iAnim, iBody )
{
	//static i, iCount, iSpectator, iszSpectators[ MAX_PLAYERS ];

	set_entvar( iPlayer, var_weaponanim, iAnim );
	
	message_begin( MSG_ONE, SVC_WEAPONANIM, _, iPlayer );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

	/*if( get_entvar( iPlayer, var_iuser1 ) )
		return;

	get_players( iszSpectators, iCount, "bch" );

	for( i = 0; i < iCount; i++ )
	{
		iSpectator = iszSpectators[ i ];

		if( get_entvar( iSpectator, var_iuser1 ) != OBS_IN_EYE )
			continue;

		if( get_entvar( iSpectator, var_iuser2 ) != iPlayer )
			continue;

		set_entvar( iSpectator, var_weaponanim, iAnim );

		message_begin( MSG_ONE, SVC_WEAPONANIM, _, iSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}*/
}

public HC_CBasePlayer_TraceAttack_Player(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage)
{
	if(jbe_is_user_valid(iAttacker) && jbe_is_user_valid(iVictim))
	{
		if(jbe_get_day_mode() == 1 || jbe_get_day_mode() == 2)
		{
			if( iBitDamage & DMG_GRENADE )
				return HC_CONTINUE;
				
			if(!get_login(iAttacker) || !g_iPlayerData[iAttacker][eData_Skin] || !has_knife_in_hand(iAttacker) || jbe_iduel_status() || jbe_get_user_team(iVictim) != 2)
				return HC_CONTINUE;
				
			new Float:fDamageOld = fDamage;
			
			#if defined DEBUG_LOG
			server_print("1#: %.5f", fDamage);
			#endif
			if(g_iPlayerData[iAttacker][eData_Damage])
			{
				new Float:TempDamage = ((fDamage * g_iPlayerData[iAttacker][eData_Damage]) / 100);
				fDamage = (fDamage + TempDamage);
				
				#if defined DEBUG_LOG
				server_print("Calc: %d | %.5f", g_iPlayerData[iAttacker][eData_Damage], TempDamage);
				#endif
			}
			#if defined DEBUG_LOG
			server_print("2#: %.5f", fDamage);
			#endif
			
			if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
		}
	}
	return HC_CONTINUE;
}





public client_disconnected(pId)
{
	g_iPlayerData[pId][eData_Damage] = 0;
	g_iPlayerData[pId][eData_Skin] = 0;
}

public jbe_save_stats(pId)
{
	g_iPlayerData[pId][eData_Damage] = 0;
	g_iPlayerData[pId][eData_Skin] = 0;
}

// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}