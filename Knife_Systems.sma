#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <knife_systems>


native jbe_has_user_weaponknife(pId);
native jbe_restartgame();

new const ITEM_CLASSNAME[] = "weapon_knife";


#define PLUGIN_NAME					"Knife Systems"
#define PLUGIN_VERSION				"1.0"
#define PLUGIN_AUTHOR				"DalgaPups"



#define MsgId_SayText 				76
#define PLAYERS_PER_PAGE 			8
//#define m_pPlayer   				41
//#define m_flNextAttack  			83
#define linux_diff_weapon  			4
#define m_flLastEventCheck 			38
#define linux_diff_animating		4
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle			48
#define m_iPrimaryAmmoType			49
#define m_iClip						51
#define m_fInReload					54
#define m_iDirection				60
#define m_flAccuracy 				62
#define m_iShotsFired				64
#define m_fWeaponState				74
#define m_iLastZoom 				109
#define m_fResumeZoom      			110
#define m_rgAmmo_CBasePlayer		376
#define extra_offset_weapon			4
#define extra_offset_player			5
#define WEAPON_TIME_NEXT_ATTACK 	0.5




#define _call.%0(%1,%2) 				Weapon_On%0(%1,%2,get_pdata_int(%1, m_iClip, extra_offset_weapon),GetAmmoInventory(%2, PrimaryAmmoIndex(%1))) 

#define IsValidPev(%0) 				(pev_valid(%0) == 2)
#define is_user_valid(%0) 			(%0 && %0 <= MaxClients)

#define FormatMain(%0) 				(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 				(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()				message_end()

#define WRITE_ANGLE(%0)				engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)				write_byte(%0)
#define WRITE_COORD(%0)				engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)			write_string(%0)
#define WRITE_SHORT(%0)				write_short(%0)


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

const OFFSET_WEAPONOWNER = 41
const m_pActiveItem = 373;

const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const PDATA_SAFE = 2

new g_iMenuPosition[MAX_PLAYERS + 1];

enum eData_Players
{
	eData_Index,
	eData_Skin,
	eData_Body,
	eData_V_MODELS[32],
	eData_P_MODELS[32]
};

new g_iPlayerData[MAX_PLAYERS + 1][eData_Players];


new Array:g_aWeaponSkins, g_iWeaponSkinsCount;

new g_iFwdHandleMenu,
	g_iFwdSelectKnife;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	
	register_menucmd(register_menuid("Show_WeaponsGuardMenu"), 1023, 	"Handle_WeaponsGuardMenu");
	
	
	//RegisterHam(Ham_Item_Deploy, 				ITEM_CLASSNAME, 		"Ham_KnifeDeploy_Post", 				true);
	RegisterHam(Ham_Weapon_PrimaryAttack,		ITEM_CLASSNAME, 		"HamHook_Item_PrimaryAttack",			false);
	RegisterHam(Ham_Weapon_SecondaryAttack, 	ITEM_CLASSNAME, 		"HamHook_Item_SecondaryAttack",			false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	 	ITEM_CLASSNAME, 		"Ham_KnifePrimaryAttack_Post", 			true);
	RegisterHam(Ham_Weapon_SecondaryAttack, 	ITEM_CLASSNAME, 		"Ham_KnifeSecondaryAttack_Post", 		true);
	
	//L 03/18/2021 - 19:21:42: Invalid index 109 (count: 1)
	//L 03/18/2021 - 19:21:42: [AMXX] Displaying debug trace (plugin "Knife_Systems.amxx", version "1.0")
	//L 03/18/2021 - 19:21:42: [AMXX] Run time error 10: native error (native "ArrayGetArray")
	//L 03/18/2021 - 19:21:42: [AMXX]    [0] Knife_Systems.sma::FM_Hook_UpdateClientData_Post (line 837)
	//register_forward(FM_UpdateClientData, 								"FM_Hook_UpdateClientData_Post", 		true);
	register_forward(FM_EmitSound, 										"FakeMeta_EmitSound", 					false);
	
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", 		false);
	
	
	g_iFwdHandleMenu = CreateMultiForward("fwd_result_handle_menu", ET_STOP, FP_CELL, FP_CELL, FP_CELL) ;
	g_iFwdSelectKnife = CreateMultiForward("fwd_selected_knife", ET_STOP, FP_CELL) ;
}



public plugin_natives() 
{
	set_native_filter("native_filter");
	register_native("api_get_knife_systems", 	"native_api_get_knife_systems");
	register_native("api_set_knife_systems", 	"native_api_set_knife_systems");
	register_native("api_get_knife_id", 			"native_api_get_skin_id");
	register_native("api_open_knifemenu", 		"native_open_knifemenu" , 1);
}


public native_open_knifemenu(pId) return Show_WeaponsGuardMenu(pId, g_iMenuPosition[pId] = 0);
public native_api_get_skin_id() 
{
	new id, iLen, DisciLen;
	id = get_param(1);
	iLen = get_param(3);
	
	if(iLen != 0)
	{
		new aDataSkinInfo[DATA_SKIN_INFO];
		ArrayGetArray(g_aWeaponSkins, g_iPlayerData[id][eData_Skin], aDataSkinInfo, sizeof(aDataSkinInfo));
		set_string(2, aDataSkinInfo[SKIN_NAME], charsmax(aDataSkinInfo[SKIN_NAME]));
		
		DisciLen = get_param(5);
		if(DisciLen != 0 && strlen(aDataSkinInfo[DISCRIPTION]))
		{
			set_string(4, aDataSkinInfo[DISCRIPTION], charsmax(aDataSkinInfo[DISCRIPTION]));
		}
	}
	
	
	return g_iPlayerData[id][eData_Index];
}

public native_filter(const GName[], index, trap)
	return !trap ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	
	
public client_putinserver(id)
{
	//if(is_user_bot(id) || is_user_hltv(id))
	//	return;
	
	new aDataSkinInfo[DATA_SKIN_INFO];
		

	ArrayGetArray(g_aWeaponSkins, 0, aDataSkinInfo, sizeof(aDataSkinInfo));
	
	//g_iPlayerData[id][eData_Index] = aDataSkinInfo[SKIN_INDEX];
	g_iPlayerData[id][eData_Skin] = 0;
	
	formatex(g_iPlayerData[id][eData_V_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[V_MODEL]);
	formatex(g_iPlayerData[id][eData_P_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[P_MODEL]);
}



public Array:native_api_get_knife_systems() return g_aWeaponSkins;



public native_api_set_knife_systems()
{
	new szKnifeName[64], id, ArrayIndex;
	id = get_param(1);
	get_string(2, szKnifeName, charsmax(szKnifeName));
	ArrayIndex = get_param(3);
	
	if(ArrayIndex != -1)
	{
		new aDataSkinInfo[DATA_SKIN_INFO];
		ArrayGetArray(g_aWeaponSkins, ArrayIndex, aDataSkinInfo, sizeof(aDataSkinInfo));
	
		g_iPlayerData[id][eData_Index] = str_to_num(aDataSkinInfo[SKIN_INDEX]);
		g_iPlayerData[id][eData_Skin] = ArrayIndex;
		g_iPlayerData[id][eData_Body] = str_to_num(aDataSkinInfo[BODY_NUM]);
		formatex(g_iPlayerData[id][eData_V_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[V_MODEL]);
		formatex(g_iPlayerData[id][eData_P_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[P_MODEL]);
		
		if(has_knife_in_hand(id))
		{
			new iActiveItem = get_member(id, m_pActiveItem);
			ExecuteHamB(Ham_Item_Deploy, iActiveItem);
			if(aDataSkinInfo[BODY_NUM])  SendWeaponAnim( id, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]));
		}
		
		new iRet;
		ExecuteForward(g_iFwdSelectKnife , iRet , id);
		
		return 1;
	}
	
	if(strlen(szKnifeName))
	{
		new aDataSkinInfo[DATA_SKIN_INFO];
		
		if(equal(szKnifeName, "None"))
		{
			ArrayGetArray(g_aWeaponSkins, 0, aDataSkinInfo, sizeof(aDataSkinInfo));
			
			g_iPlayerData[id][eData_Index] = str_to_num(aDataSkinInfo[SKIN_INDEX]);
			g_iPlayerData[id][eData_Skin] = 0;
			
			formatex(g_iPlayerData[id][eData_V_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[V_MODEL]);
			formatex(g_iPlayerData[id][eData_P_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[P_MODEL]);

			if(has_knife_in_hand(id))
			{
				new iActiveItem = get_member(id, m_pActiveItem);
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				if(aDataSkinInfo[BODY_NUM])  SendWeaponAnim( id, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]));
			}
			new iRet;
			ExecuteForward(g_iFwdSelectKnife , iRet , id);
			return 1;
		}
		
		for(new index = 0; index < ArraySize(g_aWeaponSkins); index++)
		{
			ArrayGetArray(g_aWeaponSkins, index, aDataSkinInfo, sizeof(aDataSkinInfo));
			
			if(equal(aDataSkinInfo[SKIN_NAME], szKnifeName))
			{
				g_iPlayerData[id][eData_Index] = str_to_num(aDataSkinInfo[SKIN_INDEX]);
				g_iPlayerData[id][eData_Skin] = index;
				g_iPlayerData[id][eData_Body] = str_to_num(aDataSkinInfo[BODY_NUM]);
				formatex(g_iPlayerData[id][eData_V_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[V_MODEL]);
				formatex(g_iPlayerData[id][eData_P_MODELS], charsmax(g_iPlayerData[]), "%s", aDataSkinInfo[P_MODEL]);

				if(has_knife_in_hand(id))
				{
					new iActiveItem = get_member(id, m_pActiveItem);
					ExecuteHamB(Ham_Item_Deploy, iActiveItem);
					if(aDataSkinInfo[BODY_NUM])  SendWeaponAnim( id, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]));
				}
				new iRet;
				ExecuteForward(g_iFwdSelectKnife , iRet , id);
				break;
			}
		}
	}
	return 0;
}


public client_disconnected(pId)
{
	g_iPlayerData[pId][eData_Skin] = 0;
	g_iPlayerData[pId][eData_V_MODELS] = EOS;
	g_iPlayerData[pId][eData_P_MODELS] = EOS;
	g_iPlayerData[pId][eData_Body] = 0;
}

public plugin_end()
{
	DestroyForward(g_iFwdHandleMenu);
	DestroyForward(g_iFwdSelectKnife);
}


public CBasePlayerWeapon_DefaultDeploy_Pre(const iEntity, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) {
    if (FClassnameIs(iEntity, ITEM_CLASSNAME)) 
	{
		new pId = get_member(iEntity, m_pPlayer);
		
		if(!is_user_connected(pId) || !is_user_alive(pId) || jbe_restartgame() || jbe_has_user_weaponknife(pId) || get_member(pId, m_bOwnsShield))
			return HC_CONTINUE;
		
		//if(is_user_hltv(pId) || is_user_bot(pId)) return HC_CONTINUE;
		
		
		new aDataSkinInfo[DATA_SKIN_INFO];
		
		ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);

		//server_print("%s %s", g_iPlayerData[pId][eData_V_MODELS], g_iPlayerData[pId][eData_P_MODELS]);
		SetHookChainArg(2, ATYPE_STRING, aDataSkinInfo[V_MODEL]);
		SetHookChainArg(3, ATYPE_STRING, aDataSkinInfo[P_MODEL]);
		
		if(g_iPlayerData[pId][eData_Skin]) 
		{
			set_member( iEntity, m_flLastEventCheck, get_gametime( ) + 0.1);
			SendWeaponAnim( pId, KNIFE_DRAW,str_to_num(aDataSkinInfo[BODY_NUM]) );
			
		}	
    }
	return HC_CONTINUE;
}


/*public Ham_KnifeDeploy_Post(iEntity)
{
	static pId
	pId = fm_cs_get_weapon_ent_owner(iEntity)
	
	if (!pev_valid(pId))
		return;

	
	

	new aDataSkinInfo[DATA_SKIN_INFO];
	
	ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);
	

			
	if(strlen(aDataSkinInfo[V_MODEL])) set_pev(pId, pev_viewmodel, aDataSkinInfo[V_MODEL]);
	if(strlen(aDataSkinInfo[P_MODEL])) set_pev(pId, pev_weaponmodel, aDataSkinInfo[P_MODEL]);
	
	
	if(g_iPlayerData[pId][eData_Skin]) 
	{
		set_pdata_float( iEntity, m_flLastEventCheck, get_gametime( ) + 0.1 , linux_diff_animating);
		SendWeaponAnim( pId, KNIFE_DRAW,aDataSkinInfo[BODY_NUM] );
	}	
}*/


public Ham_KnifePrimaryAttack_Post(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	
	if(!is_user_connected(pId) || !is_user_alive(pId) || jbe_restartgame() || jbe_has_user_weaponknife(pId) || get_member(pId, m_bOwnsShield))
		return;
	
	new aDataSkinInfo[DATA_SKIN_INFO];
	
	ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);
	//server_print("1: %s", aDataSkinInfo[NEXTATTACK_1]);
	
	if(strlen(aDataSkinInfo[NEXTATTACK_1]) && str_to_float(aDataSkinInfo[NEXTATTACK_1]) != 0.0)
	{
		set_member(pId, m_flNextAttack, str_to_float(aDataSkinInfo[NEXTATTACK_1]));
		//server_print("2: %s", aDataSkinInfo[NEXTATTACK_1]);
	}
}




public Ham_KnifeSecondaryAttack_Post(iEntity)
{
	new pId = get_member(iEntity, m_pPlayer);
	
	if(!is_user_connected(pId) || !is_user_alive(pId) || jbe_restartgame() || jbe_has_user_weaponknife(pId) || get_member(pId, m_bOwnsShield))
		return;
	
	new aDataSkinInfo[DATA_SKIN_INFO];
	
	ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);
	
	if(strlen(aDataSkinInfo[NEXTATTACK_2]) && str_to_float(aDataSkinInfo[NEXTATTACK_2]) != 0.0)
		set_member(pId, m_flNextAttack, str_to_float(aDataSkinInfo[NEXTATTACK_2]));
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
	
	iPlayer = get_member(iItem, m_pPlayer);
	
	if (!IsValidPev(iPlayer) || !is_user_connected( iPlayer) || g_iPlayerData[iPlayer][eData_Skin] != -1)
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
	
	send_weaponanim(iPlayer, iAnim, str_to_num(aDataSkinInfo[BODY_NUM]));

	/*if(is_user_connected(iPlayer))
	{
		MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
		WRITE_BYTE(iAnim);
		WRITE_BYTE(aDataSkinInfo[BODY_NUM]);
		MESSAGE_END();
	}*/
}


Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iClip
	
	Weapon_OnFire(iPlayer, iItem, WEAPON_TIME_NEXT_ATTACK, KNIFE_SHOOT3);
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iClip
	
	
	Weapon_OnFire(iPlayer, iItem, WEAPON_TIME_NEXT_ATTACK, KNIFE_SHOOT1);
}

public FakeMeta_EmitSound(pId, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(is_user_valid(pId))
	{
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e')
		{
			if(!is_user_connected(pId) || !is_user_alive(pId) || jbe_restartgame() || jbe_has_user_weaponknife(pId) || get_member(pId, m_bOwnsShield))
				return FMRES_IGNORED;
				
			if(is_user_bot(pId) || is_user_hltv(pId))
				return FMRES_IGNORED;
				
			new aDataSkinInfo[DATA_SKIN_INFO];

			ArrayGetArray(g_aWeaponSkins, g_iPlayerData[pId][eData_Skin], aDataSkinInfo);
			
			
			switch(szSample[17])
			{
				case 'l': 
				{
					if(strlen(aDataSkinInfo[DEPLOY])) 
					{
						//server_print("%s", aDataSkinInfo[DEPLOY]);
						emit_sound(pId, iChannel, aDataSkinInfo[DEPLOY] , fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
						return FMRES_SUPERCEDE;
					}
				}
				case 'w': 
				{
					if(strlen(aDataSkinInfo[HITWALL])) 
					{
						emit_sound(pId, iChannel, aDataSkinInfo[HITWALL], fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
						return FMRES_SUPERCEDE;
					}
				}
				case 's': 
				{
					if(strlen(aDataSkinInfo[SLASH])) 
					{
						emit_sound(pId, iChannel, aDataSkinInfo[SLASH], fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
						return FMRES_SUPERCEDE;
					}
				}
				case 'b': 
				{
					if(strlen(aDataSkinInfo[STAB])) 
					{
						emit_sound(pId, iChannel, aDataSkinInfo[STAB], fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
						return FMRES_SUPERCEDE;
					}
				}
				default: 
				{
					if(strlen(aDataSkinInfo[HIT])) 
					{
						emit_sound(pId, iChannel, aDataSkinInfo[HIT], fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						return FMRES_SUPERCEDE;
					}
				}
			}
		}
	}
	return FMRES_IGNORED;
}



public plugin_precache()
{
	new szCfgDir[64], szCfgFile[128]; 
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	formatex(szCfgFile, charsmax(szCfgFile), "%s/knife_systems.ini", szCfgDir);
	new file = fopen(szCfgFile, "rt");
	if(!file)
	{
		new error[100];
		formatex(error, charsmax(error), "Отсутсвтует: %s!", szCfgFile);
		set_fail_state(error);
		return;
	}
	g_aWeaponSkins = ArrayCreate(DATA_SKIN_INFO);
	new szBuffer[512], aDataSkinInfo[DATA_SKIN_INFO];
	
	new szText[1024], que_len;
	new szBufferPrecache[512], szDirFile[64];
		
	szText = "";
	
	while(!feof(file))
	{
		fgets(file, szBuffer, charsmax(szBuffer));
		if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#') continue;
		parse(szBuffer, 
		aDataSkinInfo[SKIN_NAME],		charsmax(aDataSkinInfo[SKIN_NAME]), 
		aDataSkinInfo[DISCRIPTION],		charsmax(aDataSkinInfo[DISCRIPTION]),
		aDataSkinInfo[BODY_NUM],		charsmax(aDataSkinInfo[BODY_NUM]),
		aDataSkinInfo[V_MODEL],			charsmax(aDataSkinInfo[V_MODEL]), 
		aDataSkinInfo[P_MODEL],			charsmax(aDataSkinInfo[P_MODEL]), 
		aDataSkinInfo[DEPLOY],			charsmax(aDataSkinInfo[DEPLOY]),
		aDataSkinInfo[HITWALL],			charsmax(aDataSkinInfo[HITWALL]),
		aDataSkinInfo[STAB],			charsmax(aDataSkinInfo[STAB]),
		aDataSkinInfo[SLASH],			charsmax(aDataSkinInfo[SLASH]),
		aDataSkinInfo[HIT],				charsmax(aDataSkinInfo[HIT]),
		aDataSkinInfo[NEXTATTACK_1],	charsmax(aDataSkinInfo[NEXTATTACK_1]),
		aDataSkinInfo[NEXTATTACK_2],	charsmax(aDataSkinInfo[NEXTATTACK_2])
		);
		
		
		
		
		if(aDataSkinInfo[SKIN_INDEX]) 
			que_len += formatex(szText[que_len],charsmax(szText) - que_len, "^n[%s] not found -", aDataSkinInfo[SKIN_NAME]);
		if(strlen(aDataSkinInfo[V_MODEL]))
		{
			//server_print("%d | %s", aDataSkinInfo[V_MODEL], aDataSkinInfo[V_MODEL]);
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "models/jb_engine/weapons/%s.mdl", aDataSkinInfo[V_MODEL]);
			if(file_exists(szBufferPrecache)) 
			{ 
				
				precache_model(szBufferPrecache);
				copy(aDataSkinInfo[V_MODEL], charsmax(aDataSkinInfo[V_MODEL]), szBufferPrecache);
				//aDataSkinInfo[V_MODEL] = engfunc(EngFunc_AllocString, szBufferPrecache); 
				//precache_model(aDataSkinInfo[V_MODEL]);
				//server_print("%d | %s", aDataSkinInfo[V_MODEL], aDataSkinInfo[V_MODEL]);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[V_MODEL]);
				aDataSkinInfo[V_MODEL] = "";
			}
		}
		
		if(strlen(aDataSkinInfo[P_MODEL]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "models/jb_engine/weapons/%s.mdl", aDataSkinInfo[P_MODEL]);
			if(file_exists(szBufferPrecache)) 
			{ 
				precache_model(szBufferPrecache);
				copy(aDataSkinInfo[P_MODEL], charsmax(aDataSkinInfo[P_MODEL]), szBufferPrecache);
				//aDataSkinInfo[P_MODEL] = engfunc(EngFunc_AllocString, szBufferPrecache); 
				//precache_model(szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[P_MODEL]);
				aDataSkinInfo[P_MODEL] = "";
			}
		}
		
		
		if(strlen(aDataSkinInfo[DEPLOY]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "%s", aDataSkinInfo[DEPLOY]);
			formatex(szDirFile, charsmax(szDirFile), "sound/%s", szBufferPrecache);

			if(file_exists(szDirFile)) 
			{ 
				engfunc(EngFunc_PrecacheSound, szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[DEPLOY]);
				aDataSkinInfo[DEPLOY] = "";
			}
		}
		
		if(strlen(aDataSkinInfo[HITWALL]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "%s", aDataSkinInfo[HITWALL]);
			formatex(szDirFile, charsmax(szDirFile), "sound/%s", szBufferPrecache);

			if(file_exists(szDirFile)) 
			{ 
				engfunc(EngFunc_PrecacheSound, szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[HITWALL]);
				aDataSkinInfo[HITWALL] = "";
			}
		}
		
		if(strlen(aDataSkinInfo[STAB]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "%s", aDataSkinInfo[STAB]);
			
			formatex(szDirFile, charsmax(szDirFile), "sound/%s", szBufferPrecache);

			if(file_exists(szDirFile)) 
			{ 
				engfunc(EngFunc_PrecacheSound, szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[STAB]);
				aDataSkinInfo[STAB] = "";
			}
		}
		if(strlen(aDataSkinInfo[SLASH]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "%s", aDataSkinInfo[SLASH]);
			formatex(szDirFile, charsmax(szDirFile), "sound/%s", szBufferPrecache);

			if(file_exists(szDirFile)) 
			{ 
				engfunc(EngFunc_PrecacheSound, szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[SLASH]);
				aDataSkinInfo[SLASH] = "";
			}
		}
		if(strlen(aDataSkinInfo[HIT]))
		{
			formatex(szBufferPrecache, charsmax(szBufferPrecache), "%s", aDataSkinInfo[HIT]);
			formatex(szDirFile, charsmax(szDirFile), "sound/%s", szBufferPrecache);

			if(file_exists(szDirFile)) 
			{ 
				engfunc(EngFunc_PrecacheSound, szBufferPrecache);
			}
			else
			{
				que_len += formatex(szText[que_len],charsmax(szText) - que_len, "[%s] ", aDataSkinInfo[HIT]);
				aDataSkinInfo[HIT] = "";
			}
		}
	
		
		aDataSkinInfo[SKIN_INDEX]++;
		
		ArrayPushArray(g_aWeaponSkins, aDataSkinInfo); 
	}
	
	if(strlen(szText))
	{
		UTIL_SetFileState("^nKnifeSystems", "%s", szText);
	}
	
	fclose(file);
	
	if(g_aWeaponSkins)
	{
		g_iWeaponSkinsCount = ArraySize( g_aWeaponSkins );

	}
	else
	{
		ArrayDestroy(g_aWeaponSkins);
		UTIL_SetFileState("KnifeSystems", "Knife not found!", szText);
	}
}



Show_WeaponsGuardMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iWeaponSkinsCount) iStart = g_iWeaponSkinsCount;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[pId] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iWeaponSkinsCount) iEnd = g_iWeaponSkinsCount;
	new szMenu[512], iLen, iPagesNum = (g_iWeaponSkinsCount / PLAYERS_PER_PAGE + ((g_iWeaponSkinsCount % PLAYERS_PER_PAGE) ? 1 : 0));



	
	new aDataSkinInfo[DATA_SKIN_INFO];
	
	FormatMain("\yВыберите перчатки \d[%d|%d]^n^n", iPos + 1, iPagesNum);
	new iKeys = (1<<9), b;
	
	new szDisciption[64];
	
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetArray(g_aWeaponSkins, a, aDataSkinInfo);
		
		if(g_iPlayerData[pId][eData_Skin] == a)
		{
			FormatItem("\y%d. \d%s \y-Текущий^n", ++b, aDataSkinInfo[SKIN_NAME]);
		}
		else
		{
			if(strlen(aDataSkinInfo[DISCRIPTION]))
				formatex(szDisciption, charsmax(szDisciption), "[%s]", aDataSkinInfo[DISCRIPTION])
			else formatex(szDisciption, charsmax(szDisciption), "");
			iKeys |= (1<<b);
			FormatItem("\y%d. \w%s \r%s^n", ++b, aDataSkinInfo[SKIN_NAME], szDisciption);
		}
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) FormatItem("^n");
	if(iEnd < g_iWeaponSkinsCount)
	{
		iKeys |= (1<<8);
		FormatItem("^n\y9. \wВперед^n\y0. \w%s", iPos ? "Назад" : "Выход");
	}
	else FormatItem("^n^n\y0. \w%s", iPos ? "Назад" : "Выход");
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
			new iArrayIndex = g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey;
			
			new iRet;
			ExecuteForward(g_iFwdHandleMenu , iRet , pId, iArrayIndex, iKey);
		}
	}
	return Show_WeaponsGuardMenu(pId, g_iMenuPosition[pId]);
}

public FM_Hook_UpdateClientData_Post( iPlayer, SendWeapons, CD_Handle )
{
	if(!pev_valid(iPlayer) || !is_user_alive(iPlayer)) return FMRES_IGNORED;
	if(is_user_hltv(iPlayer) || is_user_bot(iPlayer)) return FMRES_IGNORED;
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
		if(!g_iPlayerData[iPlayer][eData_Skin] )
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

				SendWeaponAnim( iPlayer, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]) );
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
			SendWeaponAnim( iTarget, KNIFE_DRAW, str_to_num(aDataSkinInfo[BODY_NUM]));

			set_pdata_float( iActiveItem, m_flLastEventCheck, 0.0, linux_diff_animating );
		}
	}

	return FMRES_IGNORED;
}

stock SendWeaponAnim( iPlayer, iAnim, iBody )
{
	static i, iCount, iSpectator, iszSpectators[ MAX_PLAYERS ];

	set_entvar( iPlayer, var_weaponanim, iAnim );
	
	/*message_begin( MSG_ONE, SVC_WEAPONANIM, _, iPlayer );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );*/
	
	send_weaponanim(iPlayer, iAnim, iBody);

	if( get_entvar( iPlayer, var_iuser1 ) )
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

		send_weaponanim(iSpectator, iAnim, iBody);
	}
}

stock send_weaponanim(pId, iAnim, iBody)
{
	if(!is_user_connected(pId)) return;
	
	message_begin( MSG_ONE, SVC_WEAPONANIM, _, pId );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );
}





// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
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

stock bool:has_knife_in_hand(id){

    if(!is_user_alive(id)) return false;

    new iEnt = get_member(id, m_pActiveItem);
    if(is_nullent(iEnt)) return false;

    return (get_member(iEnt, m_iId) == WEAPON_KNIFE) ? true : false;
}


stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	
	while(replace(szBuffer, charsmax(szBuffer), "#", "")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!b", "^0")) {}
	


	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
	
	
}


stock UTIL_SetFileState(const szPlugin[], const szMessage[], any:...)	{
	new szLog[256];
	vformat(szLog, charsmax(szLog), szMessage, 3);
	
	new szDate[20];
	get_time("error_%Y%m%d.log", szDate, charsmax(szDate));
	
	log_to_file(szDate, "[%s] %s", szPlugin, szLog);
}