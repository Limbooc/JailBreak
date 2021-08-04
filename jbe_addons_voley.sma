#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < reapi >



native jbe_box_status(status, pId = 0);
native jbe_is_user_connected(pid);
new g_iGlobalDebug;
#include <util_saytext>
#define FormatMain(%0) 							(iLen = formatex(szMenu, charsmax(szMenu), %0))
#define FormatItem(%0) 							(iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, %0))

#define BALL_TRAIL
#define BALL_DEFAULT_SPEED 			200
#define BALL_DEFAULT_VELOCITY		550.0

native jbe_is_user_alive(pid);
native jbe_get_user_team(pId);
native jbe_box_menu(pId);
static const BALL_BOUNCE_GROUND[ ] = "jb_engine/soccer/bounce_ball.wav";
static const g_szBallModel[ ]	 = "models/jb_engine/soccer/volleyball.mdl";
static const g_szBallName[ ] 	 = "volley";
native jbe_open_main_menu(pId, iMenu);
new bool:g_iBallOrigin,
	bool:g_iBallStatus;
	
new g_iBall, 
	g_iTrailSprite,
	g_iSpeedBall,
	g_iSyncSoccerBallInformer;

new Float:g_vOrigin[ 3 ];
new Float:g_iSpeedVelocityBall;

new HamHook:g_iHamHookVolley[1];


public plugin_init( ) 
{
	register_plugin( "[JBE] Addons VoleyBall", "1.0", "DalgaPups" );
	
	DisableHamForward(g_iHamHookVolley[0] = RegisterHam( Ham_ObjectCaps, "player", "FwdHamObjectCaps", true ));

	register_touch( g_szBallName, "player", "FwdTouchPlayer" );
	
	new const szEntity[ ][ ] = {
		"info_target", "worldspawn", "func_wall", "func_door",  "func_door_rotating",
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train",
		"func_illusionary", "func_button", "func_rot_button", "func_rotating"
	}

	for( new i; i < sizeof szEntity; i++ )
	{
		register_touch( g_szBallName, szEntity[ i ], "FwdTouchWorld" );
	}

	register_menucmd(register_menuid("Show_VoleyBollMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_VoleyBollMenu");
	
	g_iSyncSoccerBallInformer = CreateHudSyncObj();
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	
	g_iGlobalDebug = get_cvar_num("jbe_cvar_debug");
}

new g_iBallTrailRGB[3]

public plugin_natives()
{
	register_native("jbe_get_volley", "jbe_get_volley", 1);
	register_native("jbe_open_volley", "jbe_open_volley", 1);
}

public jbe_open_volley(pId) return Show_VoleyBollMenu(pId);
public jbe_get_volley() return g_iBallStatus;

Show_VoleyBollMenu(pId)
{
	new szMenu[512], iLen, iKeys;
	
	FormatMain("\yМеню Волейбола^n^n");
	FormatItem("\y1. \w%s режим^n^n", g_iBallStatus ? "Выключить" : "Включить" ), iKeys |= (1<<0);
	switch(g_iBallStatus)
	{
		case true:
		{
			FormatItem("\y2. \w%s мяч^n", g_iBall ? "Убрать" : "Установить"), iKeys |= (1<<1);
			if(g_iBallOrigin) 
			{
				if(g_iBall) FormatItem("\y3. \wВернуть мяч на место^n"), iKeys |= (1<<2);
				else FormatItem("\y3. \dВернуть мяч на место (Мяча нету на карте) ^n");
			}
			else FormatItem("\y3. \dВернуть мяч на место (Нет координат)^n");
			
			FormatItem("\y4. \wУвеличить скорость мяча: \y%d^n" , g_iSpeedBall), iKeys |= (1<<3);
			FormatItem("\y5. \wУменьшить скорость мяча: \y%d^n", g_iSpeedBall), iKeys |= (1<<4);
			FormatItem("\y6. \wУв. Направление подкидывание мячя: \y%d^n", floatround(g_iSpeedVelocityBall)), iKeys |= (1<<5);
			FormatItem("\y7. \wУм. Направление подкидывание мячя: \y%d^n", floatround(g_iSpeedVelocityBall)), iKeys |= (1<<6);
			
			FormatItem("\y8. \wМеню сетки^n"), iKeys |= (1<<7);
		}
		case false:
		{
			FormatItem("\y2. \d%s мяч^n", g_iBall ? "Установить" : "Убрать");
			FormatItem("\y3. \dВернуть мяч на место^n");
			FormatItem("\y4. \dУвеличить скорость мяча^n" );
			FormatItem("\y5. \dУменьшить скорость мяча^n");
			FormatItem("\y6. \dУв. Направление подкидывание мячя: \y%d^n", floatround(g_iSpeedVelocityBall));
			FormatItem("\y7. \dУв. Направление подкидывание мячя: \y%d^n", floatround(g_iSpeedVelocityBall));
			FormatItem("\y8. \dМеню сетки^n");
		}
	}

	FormatItem("^n\y0. \w%L", pId, "JBE_MENU_BACK"), iKeys |= (1<<9);
	return show_menu(pId, iKeys, szMenu, -1, "Show_VoleyBollMenu");
}

public Handle_VoleyBollMenu(pId, iKey)
{
	switch(iKey)
	{
		case 0: 
		{
			g_iBallStatus = !g_iBallStatus;
			
			switch(g_iBallStatus)
			{
				case true:
				{
					g_iSpeedBall = BALL_DEFAULT_SPEED;
					g_iSpeedVelocityBall = BALL_DEFAULT_VELOCITY;
					EnableHamForward(g_iHamHookVolley[0]);
					jbe_box_status(true, pId);
				}
				case false:
				{
					jbe_soccer_disable_all()
				}
			}
		}
		case 1: 
		{
			if(g_iBall) jbe_soccer_remove_ball();
			else jbe_soccer_create_ball(pId);
		}
		case 2: jbe_soccer_update_ball();
		case 3: 
		{
			g_iSpeedBall += 50;
			
			if(g_iSpeedBall > 2000) g_iSpeedBall = BALL_DEFAULT_SPEED;
			
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n увеличил скорость волейбольного мяча до %i юнитов.", pId, g_iSpeedBall)
			UTIL_SayText(pId, "!g* !yСкорость мяча была увиличена !tдо - !g%dunits", g_iSpeedBall);
		}
		case 4: 
		{
			g_iSpeedBall -= 50;
			if(g_iSpeedBall < 0) g_iSpeedBall = BALL_DEFAULT_SPEED;
			
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n уменьшил скорость волейбольного мяча до %i юнитов.", pId, g_iSpeedBall)
			UTIL_SayText(pId, "!g* !yСкорость мяча была уменьшена !tдо - !g%dunits", g_iSpeedBall);
			
		}
		case 5: 
		{
			g_iSpeedVelocityBall += 50.0;
			
			if(g_iSpeedVelocityBall > 1000.0) g_iSpeedVelocityBall = BALL_DEFAULT_VELOCITY;
			
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n увеличил направление на вверх волейбольного мяча до %i юнитов.", pId, floatround(g_iSpeedVelocityBall))
			UTIL_SayText(pId, "!g* !yНаправление на вверх мяча была увеличена !tдо - !g%dunits", floatround(g_iSpeedVelocityBall));
		}
		case 6: 
		{
			g_iSpeedVelocityBall -= 50.0;
			if(g_iSpeedVelocityBall < 0.0) g_iSpeedVelocityBall = BALL_DEFAULT_VELOCITY;
			
			set_hudmessage(120, 120, 120, -1.0, 0.65, 0, 1.0, 5.0)
			ShowSyncHudMsg(0, g_iSyncSoccerBallInformer,  "%n уменьшил направление на вверх волейбольного мяча до %i юнитов.", pId, floatround(g_iSpeedVelocityBall))
			UTIL_SayText(pId, "!g* !yНаправление на вверх мяча была  уменьшена !tдо - !g%dunits", floatround(g_iSpeedVelocityBall));
			
		}
		case 7: return jbe_box_menu(pId);
		
		case 9: return jbe_open_main_menu(pId, 1);
	}
	return Show_VoleyBollMenu(pId);
}

public plugin_precache( ) 
{
	engfunc(EngFunc_PrecacheSound, BALL_BOUNCE_GROUND);
	engfunc(EngFunc_PrecacheModel, g_szBallModel);
	g_iTrailSprite = engfunc(EngFunc_PrecacheModel, "sprites/speed.spr");
}

public FwdHamObjectCaps( id ) 
{
	if(!g_iBallStatus) return;
	
	if( is_entity( g_iBall ) && jbe_is_user_alive(id)) 
	{
		static iOwner; iOwner = get_entvar( g_iBall, var_iuser1 );
		
		if( iOwner == id )
			jbe_soccer_kickball( id );
	}
}

public FwdThinkBall( iEntity ) {

	static Float:flGametime, Float:flLastThink;
	flGametime = get_gametime( );
	
	
	if(g_iGlobalDebug)
	{
		log_to_file("globaldebug.log", "[VOLEY] FwdThinkBall");
	}

	if(iEntity == g_iBall)
	{
		if(is_entity(iEntity))
		{
			static Float:vOrigin[ 3 ], Float:vBallVelocity[ 3 ];
			get_entvar( g_iBall, var_origin, vOrigin );
			get_entvar( g_iBall, var_velocity, vBallVelocity );


			static iOwner; iOwner = get_entvar( g_iBall, var_iuser1 );
			//static iSolid; iSolid = get_entvar( g_iBall, var_solid );
			
			if( iOwner > 0 ) 
			{
				jbe_set_ball_trail_color(iOwner)
#if defined BALL_TRAIL
				if( flLastThink < flGametime ) 
				{
					if( floatround( vector_length( vBallVelocity ) ) > 10 ) 
					{
						message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
						write_byte( TE_KILLBEAM );
						write_short( g_iBall );
						message_end( );
						
						message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
						write_byte( TE_BEAMFOLLOW );
						write_short( g_iBall );
						write_short( g_iTrailSprite );
						write_byte( 10 );
						write_byte( 10 );
						write_byte( g_iBallTrailRGB[0] );
						write_byte( g_iBallTrailRGB[1] );
						write_byte( g_iBallTrailRGB[2] );
						write_byte( 150 );
						message_end( );
					}
					
					flLastThink = flGametime + 3.0;
				}
#endif
				static Float:vOwnerOrigin[ 3 ];
				get_entvar( iOwner, var_origin, vOwnerOrigin );
				
				static const Float:vVelocity[ 3 ] = { 1.0, 1.0, 0.0 };
				
				if( !jbe_is_user_alive( iOwner ) ) 
				{
					set_entvar( g_iBall, var_iuser1, 0 );
					
					vOwnerOrigin[ 2 ] += 5.0;
					
					set_entvar( g_iBall, var_origin, vOwnerOrigin );
					set_entvar( g_iBall, var_velocity, vVelocity );
					
					set_entvar( iEntity, var_nextthink, flGametime + 0.05 );
					return;
				}
				
				//if( iSolid != SOLID_NOT )
				//	set_entvar(g_iBall, var_solid, SOLID_NOT );
				
				static Float:vAngles[ 3 ], Float:vReturn[ 3 ];
				get_entvar( iOwner, var_v_angle, vAngles );
				
				vReturn[ 0 ] = ( floatcos( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 0 ];
				vReturn[ 1 ] = ( floatsin( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 1 ];
				vReturn[ 2 ] = vOwnerOrigin[ 2 ];
				vReturn[ 2 ] -= ( get_entvar( iOwner,var_flags ) & FL_DUCKING ) ? 10 : 30;
				
				set_entvar( g_iBall, var_velocity, vVelocity );
				set_entvar( g_iBall, var_origin, vReturn );
			} 
			else 
			{
				//if( iSolid != SOLID_BBOX )
				//	set_entvar(g_iBall, var_solid, SOLID_BBOX );
				
				static Float:flLastVerticalOrigin;
				
				if( vBallVelocity[ 2 ] == 0.0 ) {
					static iCounts;
					
					if( flLastVerticalOrigin > vOrigin[ 2 ] ) 
					{
						iCounts++;
						
						if( iCounts > 10 ) {
							iCounts = 0;
							
							jbe_soccer_update_ball();
						}
					} 
					else 
					{
						iCounts = 0;
						
						if( PointContents( vOrigin ) != CONTENTS_EMPTY )
							jbe_soccer_update_ball();
					}
					
					flLastVerticalOrigin = vOrigin[ 2 ];
				}
			}
		}
		else jbe_soccer_remove_ball();
	}
	set_entvar( iEntity, var_nextthink, flGametime + 0.05 );
	return;
}

jbe_soccer_kickball( id ) 
{
	static Float:vOrigin[ 3 ];
	
	get_entvar( g_iBall, var_origin, vOrigin );
	
	if( PointContents( vOrigin ) != CONTENTS_EMPTY )
		return PLUGIN_HANDLED;

	new Float:vVelocity[ 3 ];
	velocity_by_aim( id, g_iSpeedBall, vVelocity );
	
	vVelocity[2] += g_iSpeedVelocityBall;
		
	set_entvar(g_iBall, var_solid, SOLID_BBOX );
	engfunc(EngFunc_SetSize, g_iBall, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0} );
	set_entvar( g_iBall,var_iuser1, 0 );
	set_entvar( g_iBall, var_velocity, vVelocity );
		
	return PLUGIN_CONTINUE;
}

// BALL TOUCHES
////////////////////////////////////////////////////////////
public FwdTouchPlayer( const iBall, const id ) {
	if( is_user_bot( id ))
		return PLUGIN_CONTINUE;
		
	if(!g_iBallStatus)
		return PLUGIN_CONTINUE;
	
	static iOwner; iOwner = get_entvar( iBall, var_iuser1 );
	
	if( iOwner == 0 )	
		set_entvar( iBall,var_iuser1, id );
	
	return PLUGIN_CONTINUE;
}

public FwdTouchWorld( const iBall, const World ) 
{	
	if(!g_iBallStatus)
		return PLUGIN_CONTINUE;
		
	static Float:vVelocity[ 3 ];
	get_entvar( iBall, var_velocity, vVelocity );
	
	if( floatround( vector_length( vVelocity ) ) > 10 ) {
		vVelocity[ 0 ] *= 0.75;
		vVelocity[ 1 ] *= 0.75;
		vVelocity[ 2 ] *= 0.75;
		
		set_entvar( iBall, var_velocity, vVelocity );
		
		rh_emit_sound2(iBall, 0, CHAN_ITEM, BALL_BOUNCE_GROUND, VOL_NORM, ATTN_NORM);
	}
	return PLUGIN_CONTINUE;
}

isBall(ent)
{
	new szClass[32];
	get_entvar(ent, var_classname, szClass, charsmax(szClass));
	return equal(szClass, g_szBallName);
}

public box_start_touch(box, pId, const szClass[])
{	
	if(isBall(pId)) 
	{
		if(is_entity(pId) && g_iBallStatus)
		{
			
			jbe_soccer_update_ball();
			emit_sound(0, CHAN_AUTO, "jb_engine/beep_1.wav", 0.5, ATTN_NORM, 0, PITCH_NORM);
			
		}
		
	}
	return PLUGIN_CONTINUE;
}

public LogEvent_RoundEnd()
{
	if(g_iBallStatus) jbe_soccer_disable_all();
}


// ENTITIES CREATING
////////////////////////////////////////////////////////////
jbe_soccer_create_ball(id) 
{
	if(g_iBall > 1) 
		jbe_soccer_remove_ball();
	
	static iszFuncWall = 0;
	if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_iBall = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);

	if( is_valid_ent( g_iBall ) ) 
	{
		g_iBallOrigin = true;
		set_entvar( g_iBall, var_classname, g_szBallName );
		set_entvar( g_iBall,var_solid, SOLID_BBOX );
		set_entvar( g_iBall,var_movetype, MOVETYPE_BOUNCE );
		set_entvar( g_iBall, var_gravity, 0.7 );
		engfunc(EngFunc_SetModel, g_iBall, g_szBallModel );
		engfunc(EngFunc_SetSize, g_iBall, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0} );
		set_entvar( g_iBall, var_framerate, 1.0 );
		set_entvar( g_iBall, var_sequence, 0 );

		fm_get_aiming_position(id, g_vOrigin);
		engfunc(EngFunc_SetOrigin, g_iBall, g_vOrigin);
		
		engfunc(EngFunc_DropToFloor, g_iBall);
		
		SetThink(g_iBall, "FwdThinkBall");
		set_entvar(g_iBall, var_nextthink, get_gametime() + 0.05);
		
		return g_iBall;
	}
	
	return -1;
}

stock jbe_soccer_remove_ball()
{
	if(g_iBall)
	{
		if(is_entity(g_iBall)) 
		{
			set_entvar(g_iBall, var_flags, get_entvar(g_iBall, var_flags) | FL_KILLME);
			set_entvar(g_iBall, var_nextthink, get_gametime());
			g_iBall = 0;
		}
	}
}

stock jbe_soccer_update_ball( ) {
	if( is_valid_ent( g_iBall ) ) {
		set_entvar( g_iBall, var_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
		set_entvar( g_iBall, var_origin, g_vOrigin );
			
		set_entvar( g_iBall,var_movetype, MOVETYPE_BOUNCE );
		engfunc(EngFunc_SetSize, g_iBall, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0} );
		set_entvar( g_iBall,var_iuser1, 0 );
		set_entvar( g_iBall, var_framerate, 1.0 );
		engfunc(EngFunc_DropToFloor, g_iBall);
	}
}

stock jbe_soccer_disable_all()
{
	jbe_soccer_remove_ball();
	
	g_iBallOrigin = false;
	g_iBallStatus = false;
	jbe_box_status(false);
	DisableHamForward(g_iHamHookVolley[0]);
}

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
