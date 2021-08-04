#include <amxmodx>
#include <g3_mafia>
#include <jbe_core>
#include <fakemeta>


#define TASK_UPDATE_BOX			0.5				//Частота обновление координат маркера
#define VISIBLE_PRISON							//Видит ли Мафиозы маркеры своих мафиоз
#define MaskEnt(%0)    (1<<((%0) & 31))			//Маска для певгрупа


new g_pEntity[MAX_PLAYERS + 1];
new g_iBitUserEffected;


new const CLASSNAME[] = "Mafia"
new const SPRITE[] = "sprites/Mafia.spr"



#define setBit(%0,%1)                            	((%0) |= (1 << (%1)))
#define clearBit(%0,%1)                         	((%0) &= ~(1 << (%1)))
#define isSetBit(%0,%1)                         	((%0) & (1 << (%1)))


public plugin_init()
{
	register_plugin("G3 Mafia Addons", "1.0", "DalgaPups");
}


public plugin_precache() precache_model(SPRITE)


public client_disconnected(pId)
{
	if(g3_mafia_api(FuncId_MafiaStatus))
	{
		RemoveEntity(pId)
		jbe_set_group_visible(pId, false);
	}
}

public client_putinserver(pId)
{	
	set_pev(pId, pev_groupinfo, pev(pId, pev_groupinfo) | (MaskEnt(1) | MaskEnt(2)));
	
	if(g3_mafia_api(FuncId_MafiaStatus))
	{
		//Пеф груп применяется не сразу, поэтому поставил задержку
		set_task(0.5, "task_visible", pId + 456756);
	}
}

public task_visible(pId)
{
	pId -= 456756;
	jbe_set_group_visible(pId, false);
}
public g3_mafia_forward(eData_MafiaForwardId:iFunc, pId, bool:bStatus)
{
	if(iFunc == ForwardId_MafiaSetUserRole)
	{
		switch(bStatus)
		{
			case true:
			{
				if(g3_mafia_api(FuncId_MafiaUserStatus, pId) == 6)
				{
					if(!g_pEntity[pId] && is_user_alive(pId))
					{
						static iszFuncWall = 0, pEnt;
						if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "info_target"))) pEnt = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
						
						if(!pEnt) 
							abort(AMX_ERR_GENERAL, "Can't create entity")
						
						
						setBit(g_iBitUserEffected, pId);
						
						new Float:Origin[3];
						
						set_pev(pEnt, pev_classname, CLASSNAME);

						pev(pId, pev_origin, Origin);
						engfunc(EngFunc_SetSize, pEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
						engfunc(EngFunc_SetOrigin, pEnt, Origin);
						engfunc(EngFunc_SetModel, pEnt, SPRITE);
						set_pev(pEnt, pev_owner, pId);

						g_pEntity[pId] = pEnt
						
						set_pev(pEnt, pev_groupinfo, pev(pEnt, pev_groupinfo) | MaskEnt(1));
						
						#if defined VISIBLE_PRISON
						jbe_set_group_visible(pId, true);
						#endif
					}
				}
				else
				{
				
				}
			}
			case false:
			{
				RemoveEntity(pId)
				jbe_set_group_visible(pId, false);
			}
		}
	}
	if(iFunc == ForwardId_MafiaEnd)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			RemoveEntity(i)
			
			jbe_set_group_visible(i, false);
		}
	}
	if(iFunc == ForwardId_MafiaStart)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			jbe_set_group_visible(i, false);
			
			if(jbe_is_user_chief(i))
			{
			
				jbe_set_group_visible(i, true);
			}
		}
			
	}

}
new Float:gLastAimDetail[MAX_PLAYERS + 1];
public client_PreThink(pId)
{
	//Для обновление координат маркера
	if(g3_mafia_api(FuncId_MafiaStatus))
	{
		static Float:fGmTime; fGmTime = get_gametime();
		if(g3_mafia_api(FuncId_MafiaUserStatus, pId) == 6 && gLastAimDetail[pId] < fGmTime)
		{
			new Float:Origin[3];
			pev(pId, pev_origin, Origin);
			Origin[2] += 50;
			set_pev(g_pEntity[pId], pev_origin, Origin);
			gLastAimDetail[pId] = floatadd ( TASK_UPDATE_BOX, fGmTime );
		}
	}
}


public jbe_set_group_visible(pId, bool:visible)
{
	set_pev(pId, pev_groupinfo, visible == true ? MaskEnt(1) | MaskEnt(2) : ~MaskEnt(1) | MaskEnt(2));
}

public RemoveEntity(pPlayer) 
{
	if(!isSetBit(g_iBitUserEffected, pPlayer))
		return
	clearBit(g_iBitUserEffected, pPlayer)
	
	if(g_pEntity[pPlayer]) 
	{
		set_pev(g_pEntity[pPlayer], pev_flags, FL_KILLME)
		g_pEntity[pPlayer] = 0
	}
}