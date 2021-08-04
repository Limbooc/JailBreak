#include <amxmodx> 
#include <fakemeta> 
#include <hamsandwich> 
#include <reapi> 
#include <jbe_core> 
#include <engine> 

#define AUTO_OFF

//#define LOG_FILE

#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

forward jbe_fwr_roundend();

native Cmd_CostumesMenu(id);
native jbe_iduel_status();

new bool:g_iStatusBlock;
new bool:g_iEnableCamera;

#define CAMERA_MODEL "models/rpgrocket.mdl"


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

new HookChain:HookPlayer_Spawn;

new g_iBitUserCamera;



#define VERSION "0.0.3" 

#define USE_TOGGLE 3

#define MAX_BACKWARD_UNITS	-200.0
#define MAX_FORWARD_UNITS	200.0

new g_iPlayerCamera[MAX_PLAYERS + 1], Float:g_camera_position[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Camera View Menu", VERSION, "ConnorMcLeod & Natsheh & DalgaPups") 
	
	register_clcmd("say /cam", "camera_menu")
	register_clcmd("say_team /cam", "camera_menu")
	
	register_clcmd("camera", "camera_menu")
	register_clcmd("cam", "camera_menu")
	
	register_forward(FM_SetView, "SetView") 
	RegisterHam(Ham_Think, "trigger_camera", "Camera_Think")
	
	DisableHookChain(HookPlayer_Spawn   = 			RegisterHookChain(RG_CBasePlayer_Spawn, 			"HC_CBasePlayer_PlayerSpawn_Post", true));
	
	register_menucmd(register_menuid("Show_3dMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_3mMenu");
}

public camera_menu(pId) 
{
	if(jbe_get_day_mode() <3 ) return Show_3dMenu(pId)
	
	return PLUGIN_HANDLED;
}

public plugin_precache()
{
	precache_model(CAMERA_MODEL);


}



Show_3dMenu(id) 
{
	if(!jbe_is_user_alive(id) && jbe_get_day_mode() > 2) return PLUGIN_HANDLED;
	
	new szMenu[512], iKeys = (1<<0|1<<8|1<<9), iLen;
	
	new bool:mode = (g_iPlayerCamera[id] > 0) ? true:false;
	
	FormatMain("\yВид Камеры^n^n");
	
	FormatItem("\y1. \y%s вид от 3-го лица!^n", (mode) ? "Выключить":"Включить");
	
	if(mode)
	{
		FormatItem("\y2. \wПриблизить вперед^n"), iKeys |= (1<<1);
		FormatItem("\y3. \wОтдалить назад^n"), iKeys |= (1<<2);
	}
	
	if(jbe_is_user_chief(id))
	{
		FormatItem("^n\y4. \y%s \wзапрет на 3D-Камеру^n", g_iStatusBlock ? "Выключить" : "Включить"), iKeys |= (1<<3);
		//FormatItem("\y5. \wПринудительно \y%s \wвсем зекам 3D-Камеру: ^n", g_iEnableCamera ? "выключить" : "включить"), iKeys |= (1<<4);
	}
	
	
	FormatItem("^n^n^n\y9. \wНазад^n");
	FormatItem("\y0. \wВыход");

	return show_menu(id, iKeys, szMenu, -1, "Show_3dMenu");
}

public Handle_3mMenu(id, iKey)
{
	if(!jbe_is_user_alive(id) && jbe_get_day_mode() > 2) return PLUGIN_HANDLED;
	
	
	switch(iKey)
	{
		case 0:
		{
			if(jbe_get_user_team(id) == 1)
			{
				if(!g_iStatusBlock)
				{
					if(g_iPlayerCamera[id] > 0)
					{
						if(g_iEnableCamera)
						{
							UTIL_SayText(id, "!g* !yПринудительно включили камеру");
						}
						else
						{
							disable_camera(id)
						}
					}
					else
					{
						g_camera_position[id] = -150.0;
						enable_camera(id)
					}
				}
				else
				{
					UTIL_SayText(id, "!g* !yВключен запрет на 3D-Камеру");
				}
			}
			else
			{
				if(g_iPlayerCamera[id] > 0)
				{
					disable_camera(id)
				}
				else
				{
					g_camera_position[id] = -150.0;
					enable_camera(id)
				}
			}
		}
		case 1: if(g_camera_position[id] < MAX_FORWARD_UNITS) g_camera_position[id] += 50.0;
		case 2: if(g_camera_position[id] > MAX_BACKWARD_UNITS) g_camera_position[id] -= 50.0;
		case 3:
		{	
			if(jbe_is_user_chief(id) && !jbe_iduel_status())
			{
				g_iStatusBlock = !g_iStatusBlock;
				
				
				if(g_iStatusBlock)
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(!is_user_alive(i) || jbe_get_user_team(i) != 1 || g_iPlayerCamera[i] == 0) continue;
						
						disable_camera(i);
					}
				}
				UTIL_SayText(0, "!g* !yНачальник %s запрет на 3D-камеру", g_iStatusBlock ? "дал" : "убрал");
			}
		
		}
		/*case 4:
		{
			if(jbe_is_user_chief(id) && !jbe_iduel_status())
			{
				g_iEnableCamera = !g_iEnableCamera;
				
				
				
				switch(g_iEnableCamera)
				
				{
					case true:
					{
						for(new i = 1; i <= MaxClients; i++)
						{
							if(!is_user_alive(i) || jbe_get_user_team(i) != 1) continue;
							
							if(g_iPlayerCamera[i] > 0)
							{
								disable_camera(i);
							}
							//g_camera_position[i] = -150.0;
							//enable_camera(i);
							enable_force_camera(i)

						}
						
						EnableHookChain(HookPlayer_Spawn);
					}
					case false:
					{
						for(new i = 1; i <= MaxClients; i++)
						{
							if(!is_user_alive(i) || jbe_get_user_team(i) != 1) continue;
							
							disable_force_camera(i);
						}
						DisableHookChain(HookPlayer_Spawn);
					}
				}
				UTIL_SayText(0, "!g* !yНачальник !gпринудительно !t%s !yвсем 3D-камеру", g_iEnableCamera ? "включил" : "выключил");
			}
		
		}*/
		case 8: return Cmd_CostumesMenu(id);
		case 9: return PLUGIN_HANDLED;
	
	}
	return Show_3dMenu(id);


}

stock enable_force_camera(id)
{
	client_cmd(id, "stopsound");
	set_view(id,CAMERA_3RDPERSON)
	client_cmd(id, "stopsound");
	SetBit(g_iBitUserCamera, id);
}

stock disable_force_camera(id)
{
	client_cmd(id, "stopsound");
	set_view(id,CAMERA_NONE)
	client_cmd(id, "stopsound");
	ClearBit(g_iBitUserCamera, id);
}

#if defined AUTO_OFF
public jbe_lr_duels()
{
	jbe_fwr_roundend()
}
public HC_CBasePlayer_PlayerSpawn_Post(pId)
{
	if(jbe_get_user_team(pId) == 1 && g_iEnableCamera)
	{
		//g_camera_position[pId] = -150.0;
		//enable_camera(pId);
		enable_force_camera(pId);
	}

}

public jbe_fwr_roundend()
{
	g_iStatusBlock = false;
	if(g_iEnableCamera)
	{
		DisableHookChain(HookPlayer_Spawn);
		g_iEnableCamera = false;
	}
	

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!jbe_is_user_connected(i) || g_iPlayerCamera[i] < 1) continue;
		
		disable_camera(i);
	}
	
	if(g_iBitUserCamera)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!jbe_is_user_connected(i) || IsNotSetBit(g_iBitUserCamera, i)) continue;
			
			disable_force_camera(i);
		}
	}
	
	g_iBitUserCamera = 0;
}

#endif

public disable_camera(id)
{
	client_cmd(id, "stopsound");
	new iEnt = g_iPlayerCamera[id];
	if(pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt);
	g_iPlayerCamera[id] = 0;
	g_camera_position[id] = -100.0;
	
	engfunc(EngFunc_SetView, id, id);
	client_cmd(id, "stopsound");
	
	#if defined LOG_FILE
	log_to_file("log.log", "[camera] Camera OFF | %n ", id);
	#endif
}

public enable_camera(id)
{ 
	if(!jbe_is_user_alive(id)) return;
	
	new iEnt = g_iPlayerCamera[id] 

	if(!pev_valid(iEnt))
	{
		client_cmd(id, "stopsound");
		static iszTriggerCamera 
		if( !iszTriggerCamera ) 
		{ 
			iszTriggerCamera = engfunc(EngFunc_AllocString, "trigger_camera") 
		} 
		
		#if defined LOG_FILE
		log_to_file("log.log", "[camera] Camera ON | %n ", id);
		#endif
		iEnt = engfunc(EngFunc_CreateNamedEntity, iszTriggerCamera);
		
		if(pev_valid(iEnt))
		{
			set_kvd(0, KV_ClassName, "trigger_camera") 
			set_kvd(0, KV_fHandled, 0) 
			set_kvd(0, KV_KeyName, "wait") 
			set_kvd(0, KV_Value, "999999") 
			dllfunc(DLLFunc_KeyValue, iEnt, 0) 
		
			set_entvar(iEnt, var_spawnflags, SF_CAMERA_PLAYER_TARGET|SF_CAMERA_PLAYER_POSITION) 
			set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_ALWAYSTHINK) 
		
			dllfunc(DLLFunc_Spawn, iEnt)
		
			g_iPlayerCamera[id] = iEnt;
	 //   } 	
			new Float:flMaxSpeed, iFlags = get_entvar(id, var_flags) 
			get_entvar(id, var_maxspeed, flMaxSpeed)
			
			ExecuteHam(Ham_Use, iEnt, id, id, USE_TOGGLE, 1.0)
			
			set_entvar(id, var_flags, iFlags)
			// depending on mod, you may have to send SetClientMaxspeed here. 
			// engfunc(EngFunc_SetClientMaxspeed, id, flMaxSpeed) 
			set_entvar(id, var_maxspeed, flMaxSpeed)
			
			
		}
	}
}

public SetView(id, iEnt) 
{ 
	if(jbe_is_user_alive(id))
	{
		new iCamera = g_iPlayerCamera[id] 
		if( iCamera && iEnt != iCamera ) 
		{ 
			new szClassName[16] 
			get_entvar(iEnt, var_classname, szClassName, charsmax(szClassName)) 
			if(!equal(szClassName, "trigger_camera")) // should let real cams enabled 
			{ 
				client_cmd(id, "stopsound");
				engfunc(EngFunc_SetView, id, iCamera) // shouldn't be always needed 
				client_cmd(id, "stopsound");
				return FMRES_SUPERCEDE 
			} 
		} 
	} 
	return FMRES_IGNORED 
}

public client_disconnected(id) 
{ 
	if(g_iPlayerCamera[id])
	{
		disable_camera(id)
	} 
}
public client_putinserver(id) 
{
	g_iPlayerCamera[id] = 0
	g_camera_position[id] = -100.0;
} 

get_cam_owner(iEnt) 
{ 
	new players[32], pnum;
	get_players(players, pnum, "ch");
	
	for(new id, i; i < pnum; i++)
	{ 
		id = players[i];
		
		if(g_iPlayerCamera[id] == iEnt)
		{
			return id;
		}
	}
	
	return 0;
} 

public Camera_Think(iEnt)
{
	static id;
	if(!(id = get_cam_owner(iEnt))) return ;
	
	static Float:fVecPlayerOrigin[3], Float:fVecCameraOrigin[3], Float:fVecAngles[3], Float:fVec[3];
	
	get_entvar(id, var_origin, fVecPlayerOrigin) 
	get_entvar(id, var_view_ofs, fVecAngles) 
	fVecPlayerOrigin[2] += fVecAngles[2] 
	
	get_entvar(id, var_v_angle, fVecAngles) 
	
	angle_vector(fVecAngles, ANGLEVECTOR_FORWARD, fVec);
	static Float:units; units = g_camera_position[id];
	
	//Move back/forward to see ourself
	fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * units)
	fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * units) 
	fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * units) + 15.0
	
	static tr2; tr2 = create_tr2();
	engfunc(EngFunc_TraceLine, fVecPlayerOrigin, fVecCameraOrigin, IGNORE_MONSTERS, id, tr2)
	static Float:flFraction 
	get_tr2(tr2, TR_flFraction, flFraction)
	if( flFraction != 1.0 ) // adjust camera place if close to a wall 
	{
		flFraction *= units;
		fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * flFraction);
		fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * flFraction);
		fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * flFraction);
	}
	
	if(units > 0.0)
	{
		fVecAngles[0] *= fVecAngles[0] > 180.0 ? 1:-1
		fVecAngles[1] += fVecAngles[1] > 180.0 ? -180.0:180.0
	}
	
	set_entvar(iEnt, var_origin, fVecCameraOrigin); 
	set_entvar(iEnt, var_angles, fVecAngles);
	
	free_tr2(tr2);
	
	
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
