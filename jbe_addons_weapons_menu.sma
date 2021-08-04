#include <amxmodx>
#include <reapi>
#include <amxmisc>
#include <reapi>
#include <jbe_core>
#include <fakemeta>

//#define DEBUG

native jbe_is_user_duel(pId)
native jbe_off_minigames()

new bool:g_iAmmoHas;


#define PLAYERS_PER_PAGE 8
const linux_diff_weapon = 4;
const m_iClip =  51;

new SzWpnCommand[MAX_PLAYERS + 1] = 0, SzWpn[MAX_PLAYERS + 1] = 0;

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], 
	g_iMenuPosition[MAX_PLAYERS + 1];


#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

public plugin_init()
{
	register_plugin("[JBE] Addons Give Weapons", "1.0.0", "DalgaPups");
	
	register_menucmd(register_menuid("Show_GolodnueIgru"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_GolodnueIgru");
	register_menucmd(register_menuid("Show_ChosMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<9), "Handle_ChosMenu");
	register_menucmd(register_menuid("Show_ChiefWeaponMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_ChiefWeaponMenu");
	
	#if defined DEBUG
	register_clcmd("say /gun", "jbe_open_weaponmenu");
	#endif
}

public plugin_natives()
{
	register_native("jbe_open_weaponmenu", "jbe_open_weaponmenu", 1);
}

public jbe_open_weaponmenu(pId) return Show_GolodnueIgru(pId)

public clcmd_gun(pId) 
{
	SzWpnCommand[pId] = 3;
	return Show_ChosMenu(pId);
}

Show_GolodnueIgru(pId)
{
	new szMenu[512], iLen, iKeys = (1<<0|1<<9);
	
	FormatMain("\yОружейнная^n^n");

	FormatItem("\y1. \wОружие себе^n"), iKeys |= (1<<0);
	FormatItem("\y2. \wОружие определенному игроку^n"), iKeys |= (1<<1);
	FormatItem("\y3. \wОружие для заключенного^n"), iKeys |= (1<<2);
	FormatItem("\y4. \wОружие для охранника^n^n"), iKeys |= (1<<3);
	FormatItem("\y5. \y%s патронами^n", !g_iAmmoHas ? "С" : "Без"), iKeys |= (1<<4);

	FormatItem("^n\y0. \wНазад");
	return show_menu(pId, iKeys, szMenu, -1, "Show_GolodnueIgru");
}

public Handle_GolodnueIgru(pId, key)
{
	switch(key)
	{
		case 0:
		{
			SzWpnCommand[pId] = 1;
			return Show_ChosMenu(pId);
		}
		case 1:
		{
			SzWpnCommand[pId] = 2;
			return Show_ChosMenu(pId);	
		}
		case 2:
		{
			SzWpnCommand[pId] = 3;
			return Show_ChosMenu(pId);		
		}
		case 3:
		{
			SzWpnCommand[pId] = 4;
			return Show_ChosMenu(pId);		
		}
		case 4: g_iAmmoHas = !g_iAmmoHas;
	
		case 5: return Show_GolodnueIgru(pId);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_GolodnueIgru(pId);
}



Show_ChosMenu(pId)
{


	new szMenu[512], iLen, iKey = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<9);
	FormatItem("\yВыберите оружие^n^n");
	FormatItem("\y1. \wДигл^n");
	FormatItem("\y2. \wЭмка^n");
	FormatItem("\y3. \wКалаш^n");
	FormatItem("\y4. \wАвп^n");
	FormatItem("\y5. \wФамас^n");
	FormatItem("\y6. \wПулемет^n");
	FormatItem("\y7. \wАуг^n");
	FormatItem("\y8. \wДробовик^n^n");
	FormatItem("^n\y0. \wНазад");
	return show_menu(pId, iKey, szMenu, -1, "Show_ChosMenu");
}

public Handle_ChosMenu(pId, key)
{

	new TmpName[32]; get_user_name(pId,TmpName, charsmax(TmpName));
	switch(key)
	{
		case 0:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_deagle");
							new iEntity = rg_give_item(pId, "weapon_deagle", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_deagle", GT_REPLACE, 35);
					}

					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_DEAGLE", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 1;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_deagle");
									new iEntity = rg_give_item(Players, "weapon_deagle", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_deagle", GT_REPLACE, 35);
							}
						}
					}

					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_DEAGLE", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_deagle");
									new iEntity = rg_give_item(Players, "weapon_deagle", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_deagle", GT_REPLACE, 35);
							}
						}
					}

					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_DEAGLE", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_m4a1");
							new iEntity = rg_give_item(pId, "weapon_m4a1", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_m4a1", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_M4A4", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 2;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_m4a1");
									new iEntity = rg_give_item(Players, "weapon_m4a1", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_m4a1", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_M4A4", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_m4a1");
									new iEntity = rg_give_item(Players, "weapon_m4a1", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_m4a1", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_M4A4", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_ak47");
							new iEntity = rg_give_item(pId, "weapon_ak47", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_ak47", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_AK47", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 3;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_ak47");
									new iEntity = rg_give_item(Players, "weapon_ak47", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_ak47", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AK47", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_ak47");
									new iEntity = rg_give_item(Players, "weapon_ak47", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_ak47", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AK47", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_awp");
							new iEntity = rg_give_item(pId, "weapon_awp");
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_awp", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_AWP", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 4;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_awp");
									new iEntity = rg_give_item(Players, "weapon_awp");
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_awp", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AWP", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_awp");
									new iEntity = rg_give_item(Players, "weapon_awp");
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_awp", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AWP", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_famas");
							new iEntity = rg_give_item(pId, "weapon_famas");
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_famas", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_FAMAS", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 5;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_famas");
									new iEntity = rg_give_item(Players, "weapon_famas");
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_famas", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_FAMAS", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_famas");
									new iEntity = rg_give_item(Players, "weapon_famas");
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_famas", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_FAMAS", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 5:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_m249");
							new iEntity = rg_give_item(pId, "weapon_m249", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_m249", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_M249", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 6;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_m249");
									new iEntity = rg_give_item(Players, "weapon_m249", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_m249", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_M249", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_m249");
									new iEntity = rg_give_item(Players, "weapon_m249", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_m249", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_M249", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 6:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_aug");
							new iEntity = rg_give_item(pId, "weapon_aug", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_aug", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_AUG", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 7;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_aug");
									new iEntity = rg_give_item(Players, "weapon_aug", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_aug", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AUG", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_aug");
									new iEntity = rg_give_item(Players, "weapon_aug", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_aug", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_AUG", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 7:
		{
			switch(SzWpnCommand[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(pId, "weapon_xm1014");
							new iEntity = rg_give_item(pId, "weapon_xm1014", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(pId,"weapon_xm1014", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_ME_XM1014", TmpName);
				}
				case 2:
				{
					SzWpn[pId] = 8;
					return Cmd_ChiefWeaponMenu(pId);
				}
				case 3:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_xm1014");
									new iEntity = rg_give_item(Players, "weapon_xm1014", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_xm1014", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_XM1014", TmpName);
				}
				case 4:
				{
					static iPlayers[MAX_PLAYERS], iPlayerCount;
					get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST");

					for(new i, Players; i < iPlayerCount; i++)
					{
						Players = iPlayers[i];
						
						if(jbe_is_user_alive(Players))
						{
							switch(g_iAmmoHas)
							{
								case true:
								{
									rg_remove_item(Players, "weapon_xm1014");
									new iEntity = rg_give_item(Players, "weapon_xm1014", GT_REPLACE);
									if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
								}
								case false: rg_give_item_ex(Players,"weapon_xm1014", GT_APPEND, 1000);
							}
						}
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PRISONER_XM1014", TmpName);
				}
				default: return PLUGIN_HANDLED;
			}
		}
		case 9: return Show_GolodnueIgru(pId);
	}
	return Show_ChosMenu(pId);
}

Cmd_ChiefWeaponMenu(pId) return Show_ChiefWeaponMenu(pId, g_iMenuPosition[pId] = 0);
Show_ChiefWeaponMenu(pId, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(jbe_get_user_team(i) != 1 || !jbe_is_user_alive(i)) continue;
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
	
			UTIL_SayText(pId, "%L", LANG_PLAYER, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_GolodnueIgru(pId);
		}
		default: FormatMain("\yВыдать оружие \r[\w%d|%d\r]^n^n", iPos + 1, iPagesNum);
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
	return show_menu(pId, iKeys, szMenu, -1, "Show_ChiefWeaponMenu");
}

public Handle_ChiefWeaponMenu(pId, iKey)
{

	switch(iKey)
	{
		case 8: return Show_ChiefWeaponMenu(pId, ++g_iMenuPosition[pId]);
		case 9: return Show_ChiefWeaponMenu(pId, --g_iMenuPosition[pId]);
		default:
		{
			new iTarget = g_iMenuPlayers[pId][g_iMenuPosition[pId] * PLAYERS_PER_PAGE + iKey];
			new TmpName1[MAX_PLAYERS + 1], TmpName2[MAX_PLAYERS + 1]; 
			get_user_name(iTarget, TmpName2, charsmax(TmpName2)); 
			get_user_name(pId, TmpName1, charsmax(TmpName1));
			switch(SzWpn[pId])
			{
				case 1:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_deagle");
							new iEntity = rg_give_item(iTarget, "weapon_deagle", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_xm1014", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_DEAGLE", TmpName1, TmpName2);
				}
				case 2:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_m4a1");
							new iEntity = rg_give_item(iTarget, "weapon_m4a1", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_m4a1", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_M4A4", TmpName1, TmpName2);
				}
				case 3:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_ak47");
							new iEntity = rg_give_item(iTarget, "weapon_ak47", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_ak47", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_AK47", TmpName1, TmpName2);
				}
				case 4:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_awp");
							new iEntity = rg_give_item(iTarget, "weapon_awp", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_awp", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_AWP", TmpName1, TmpName2);
				}
				case 5:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_famas");
							new iEntity = rg_give_item(iTarget, "weapon_famas", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_famas", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_FAMAS", TmpName1, TmpName2);
				}
				case 6:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_m249");
							new iEntity = rg_give_item(iTarget, "weapon_m249", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_m249", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_M249", TmpName1, TmpName2);
				}
				case 7:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_aug");
							new iEntity = rg_give_item(iTarget, "weapon_aug", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_aug", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_AUG", TmpName1, TmpName2);
				}
				case 8:
				{
					switch(g_iAmmoHas)
					{
						case true:
						{
							rg_remove_item(iTarget, "weapon_xm1014");
							new iEntity = rg_give_item(iTarget, "weapon_xm1014", GT_REPLACE);
							if(iEntity > 0) set_pdata_int(iEntity, m_iClip, -1, linux_diff_weapon);
						}
						case false: rg_give_item_ex(iTarget,"weapon_xm1014", GT_APPEND, 1000);
					}
					UTIL_SayText(0, "%L", LANG_PLAYER, "JBE_CHIEF_WEAPON_PLAYER_XM1014", TmpName1, TmpName2);
				}
			}
		}
	}
	return Show_ChosMenu(pId);
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammount = 0)
{
    rg_give_item(id, weapon, type);
    if(ammount) rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), ammount);
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

