#include <amxmodx>
#include <fakemeta>
#include <zmb>
#include <reapi>
//native jbe_get_user_team(pId)

new g_iGunsEventBitsum = 0;
#define IsGunshotEvent(%1)      (g_iGunsEventBitsum & (1 << %1))
new g_iFwdPrecacheEvent;

#define MaskEnt(%0)    (1<<((%0) & 31))


new const EVENTS[][] = 
{
    "events/ak47.sc",
    "events/aug.sc",
    "events/awp.sc",
    "events/deagle.sc",
    "events/elite_left.sc",
    "events/elite_right.sc",
    "events/famas.sc",
    "events/fiveseven.sc",
    "events/g3sg1.sc",
    "events/galil.sc",
    "events/glock18.sc",
    //"events/knife.sc",
    "events/m249.sc",
    "events/m3.sc",
    "events/m4a1.sc",
    "events/mac10.sc",
    "events/mp5n.sc",
    "events/p228.sc",
    "events/p90.sc",
    "events/scout.sc",
    "events/sg550.sc",
    "events/sg552.sc",
    "events/tmp.sc",
    "events/ump45.sc",
    "events/usp.sc",
    "events/xm1014.sc"
};

new bool:g_iSoundOff;

#define is_user_valid(%0) (%0 && %0 <= MaxClients)
new g_iFakeMetaPlaybackEvent;

public plugin_precache()
{
	g_iFwdPrecacheEvent = register_forward(FM_PrecacheEvent, "PrecacheEvent", true);
}

public plugin_init()
{
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	unregister_forward(FM_PrecacheEvent, g_iFwdPrecacheEvent, true);
	
	//RegisterHookChain(RH_SV_StartSound, "RH_EmitSound", false);
	
	
	unregister_forward(FM_PlaybackEvent, g_iFakeMetaPlaybackEvent);
	register_clcmd("fnosound", "nosound");
}

public bio_fw_core_infect_post(pId, Attacker)
{
	set_pev(pId, pev_groupinfo, pev(pId, pev_groupinfo) | MaskEnt(pId));

}

public PrecacheEvent(type, const szEventTitle[])
{
    for(new i = 0; i < sizeof EVENTS; i++) 
    {
        if(equali(szEventTitle, EVENTS[i]))
        {
            g_iGunsEventBitsum |= (1 << get_orig_retval());
            break;
        }
    }
}

public nosound() 
{
	g_iSoundOff = !g_iSoundOff;
	server_print("g_iSoundOff")
	/*switch(g_iSoundOff)
	{
		case true: g_iFakeMetaPlaybackEvent = 		register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
		case false: unregister_forward(FM_PlaybackEvent, g_iFakeMetaPlaybackEvent);
	}*/
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!IsGunshotEvent(eventid) || !is_user_valid(invoker))
		return FMRES_IGNORED	
	
		
	if(g_iSoundOff)
		return FMRES_IGNORED	
		
	
	/*set_pev(invoker, pev_groupinfo, pev(invoker, pev_groupinfo) | MaskEnt(invoker));

	for(new i; i <= MaxClients; i++)
    {
        if(!is_user_connected(i) || !is_user_zombie(i)) continue;
		set_pev(i, pev_groupinfo, pev(i, pev_groupinfo) | MaskEnt(i));
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		set_pev(i, pev_groupinfo, pev(i, pev_groupinfo) | ~MaskEnt(i));
		
		return FMRES_SUPERCEDE;
	}
	set_pev(invoker, pev_groupinfo, pev(invoker, pev_groupinfo) | ~MaskEnt(invoker));*/
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE;
	//return FMRES_IGNORED
}


