#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >
#include < reapi >

#define NAME 			"AlienBoss"
#define VERSION			"2.0.2"
#define AUTHOR			"Alexander.3"

#define MAPCHOOSER
#define PLAYER_HP
#define NEW_SEARCH
//#define MESSAGE
//#define LASER

////////////////////////
/*------- CODE -------*/
////////////////////////
enum {
	RUN,
	ATTACK,
	// Color
	RED,
	YELLOW,
	BLUE,
	GREEN,
	//Other
	CAST,
	PHASE2,
	MAHADASH
}

#define MsgId_ScreenShake 97
#define MsgId_ScreenFade 98
#define MsgId_RoundTime 101

native jbe_totalalievplayers();

new const Resource[][] = {
	"models/zl/npc/alien/zl_alien.mdl",		// 0
	"models/zl/npc/alien/zl_ship.mdl",		// 1
	"models/zl/npc/alien/zl_light_of_dead.mdl",	// 2
	"sprites/zl/npc/alien/hpbar.spr",		// 3
	"sprites/shockwave.spr",			// 4
	"sprites/zl/npc/alien/fluxing.spr",		// 5
	"sprites/laserbeam.spr",			// 6
	"models/zl/npc/alien/zl_mine.mdl",		// 7
	"sprites/zl/npc/alien/white.spr"		// 8
}

new const SoundList[][] = {
	"zl/npc/alien/event_death.wav",		// 0 -
	"zl/npc/alien/event_10.wav",		// 1 -
	"zl/npc/alien/event_10_2.wav",		// 2 -
	"zl/npc/alien/event_blue.wav",		// 3 -
	"zl/npc/alien/event_blue2.wav",		// 4 -
	"zl/npc/alien/event_gravity_death.wav",	// 5 -
	"zl/npc/alien/event_phase2.wav",	// 6 -
	"zl/npc/alien/event_red.wav",		// 7 -
	"zl/npc/alien/event_red2.wav",		// 8 -
	"zl/npc/alien/event_start.wav",		// 9 -
	"zl/npc/alien/event_yellow.wav",	// 10 -
	"zl/npc/alien/event20.wav",		// 11 -
	"zl/npc/alien/event30.wav",		// 12 -
	"zl/npc/alien/event_40.wav",		// 13 -
	"zl/zombie_scenario_ready.mp3",		// 14
	"zl/scenario_rush.mp3",			// 15
	"zl/scenario_normal.mp3",		// 16
	"zl/npc/alien/cast.wav",		// 17
	"zl/npc/alien/shokwave.wav",		// 18
	"zl/npc/alien/swing.wav",		// 19
	"zl/npc/alien/step1.wav"		// 20
}

#define E_MAXBOMB	16
#define E_MAXZOMBIE	10
static g_Resource[sizeof Resource]
static e_zombie[E_MAXZOMBIE], e_coord[3], e_light, e_boss, e_glow, e_multi, e_laser, e_go, e_bomb[E_MAXBOMB]
static g_Alien, g_Health, g_PlayerSpeed[33], g_PlayerBuffer[33], g_ZombieBuffer[sizeof e_zombie],
	g_MineEnt[sizeof e_bomb], g_MineExpl[sizeof e_bomb],
	// 0 - RedYellow
	// 1 - RedBlue
	// 2 - RedGreen
	// 3 - YellowBlue
	// 4 - YellowGreen
	// 5 - YellowBlue
	// 6 - Phase2
	// 7 - Purple
	// 8 - Green
	//-- WAVE
	// 9 - PreGREEN
	// 10 - PostGREEN
	// 11 - BLUE
	// 12 - WaveAbility
	// 13 - SpeedNormal
	// 14 - White
	g_Ability[15]
new const FILE_SETTING[] = "zl_alienboss.ini"
new boss_hp, prepare_time, boss_speed, blood_color, damage_shockwave, damage_boss_attack, Float:mahadash_time,
	zombie_normal_num, zombie_normal_health, zombie_normal_damage, zombie_normal_speed,
	damage_sw_maximum, zombie_spawn_time, zombie_max_num, zombie_max_health, zombie_max_damage, zombie_max_speed,
	damage_sw_minimum, zombie_min_num, zombie_min_health, zombie_min_damage, zombie_min_speed, player_min_speed, Float:player_speed_time,
	poison_red_num, poison_yellow_num, poison_blue_num, poison_max_damage, poison_normal_damage, poison_min_damage,
	zombie_phase_time, zombie_add_time,
	damage_laser, damage_mine, mine_time, mine_num, mine_num_last,
	Float:damage_return, damage_time,
	blue_speed_time, blue_speed_player, green_gravity_time,
	lighting_num, lighting_count, lighting_damage	
#if defined MAPCHOOSER
native zl_vote_start()
#else
new boss_nextmap[32]
#endif

new g_iSyncMain;

native zl_zombie_create(Float:Origin[3], Health, Speed, Damage)
native zl_zombie_valid(index)
native zl_boss_map()
native zl_boss_valid(index)
native zl_player_alive()
native zl_player_random()

#define pev_num				pev_euser2
#define pev_ability			pev_euser3
#define pev_victim			pev_euser4

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (zl_boss_map() != 2) {
		pause("ad")
		return
	}
		
	RegisterHam(Ham_Player_PreThink, "player", "Think_Player", 1)
	RegisterHam(Ham_BloodColor, "info_target", "Hook_BloodColor")
	RegisterHam(Ham_TakeDamage, "info_target", "Hook_TakeDamage")
	RegisterHam(Ham_Killed, "info_target", "Hook_Killed")
	RegisterHam(Ham_Killed, "player", "Hook_Killed", 1)
	RegisterHam(Ham_Spawn, "player", "Hook_Spawn")
	
	register_think("Mine", "Think_Mine")
	register_think("Ship", "Think_Ship")
	register_think("Timer", "Think_Timer")
	register_think("Health", "Think_Health")
	register_think("AlienBoss", "Think_Boss")
	register_think("Lighting", "Think_Lighting")
	
	register_touch("AlienBoss", "*", "Touch_Boss")
	register_touch("player", "player", "Touch_Player")
	register_touch("player", "Mine", "Touch_Player")
	
	register_dictionary("zl_alienboss.txt")
	
	MapEvent()
	g_iSyncMain = CreateHudSyncObj()
}

public Think_Boss(Ent) {
	if (pev(Ent, pev_deadflag) == DEAD_DYING)
		return
		
	static Float: fCurTime; fCurTime = get_gametime();
		
	if (!zl_player_alive()) {
		Anim(Ent, 2, 1.0)
		set_pev(Ent, pev_nextthink, fCurTime + 6.1)
		return
	}
	
		
	static Float:tMahadash
	if (tMahadash <= fCurTime) {
		tMahadash = fCurTime + mahadash_time
		
		if (pev(Ent, pev_ability) == RUN && pev(Ent, pev_takedamage) == DAMAGE_YES) {
			set_pev(Ent, pev_num, 0)
			set_pev(Ent, pev_ability, MAHADASH)
		}
	}
		
	switch(pev(Ent, pev_ability)) {
		case RUN: {
			new Float:Velocity[3], Float:Angle[3]
			static Target
			if (!is_user_alive(Target)) {
				Target = zl_player_random()
				set_pev(Ent, pev_nextthink, fCurTime + 0.1)
				return
			}
			if (!pev(Ent, pev_num)) {
				set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
				Anim(Ent, 3, 1.8)
				set_pev(Ent, pev_num, 1)
			}
			#if defined NEW_SEARCH
			new Len, LenBuff = 99999
			for(new i = 1; i <= MaxClients; i++) {
				if (!is_user_alive(i) || is_user_bot(i))
					continue
				
				Len = Move(Ent, i, 500.0, Velocity, Angle)
				if (Len < LenBuff) {
					LenBuff = Len
					Target = i
				}
			}
			#endif
			Move(Ent, Target, float(boss_speed) + g_Ability[3], Velocity, Angle)
			Velocity[2] = 0.0
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_nextthink, fCurTime + 0.1)
		}
		case ATTACK:{
			switch(pev(Ent, pev_num)) {
				case 0: {
					Sound(Ent, 19, 0)
					Anim(Ent, 6, 1.0)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_nextthink, fCurTime + 0.6); return
				}
				case 1: {
					new Float:Velocity[3], Float:Angle[3], Len
					new victim = pev(Ent, pev_victim)
					
					Len = Move(Ent, victim, 2000.0, Velocity, Angle)
					if ( Len <= 165 ) {
						Velocity[2] = 500.0
						if(g_Ability[3] || g_Ability[6]) {
							ExecuteHamB(Ham_Killed, victim, victim, 2)
							if (!g_Ability[6]) g_Ability[3] += 10
						}
						else boss_damage(victim, damage_boss_attack, {255, 0, 0})
						set_pev(victim, pev_velocity, Velocity)
					}
				}
			}
			set_pev(Ent, pev_num, 0)
			set_pev(Ent, pev_ability, RUN)
			set_pev(Ent, pev_nextthink, fCurTime + 0.6)
		}
		case CAST: {
			static CurrentColor, Fluxing
			switch (pev(Ent, pev_num)) {
				case 0: {
					if (g_Ability[6]) {
						set_pev(Ent, pev_nextthink, fCurTime + 0.1)
						set_pev(Ent, pev_num, 1)
						return
					}
					new Float:Velocity[3], Float:Angle[3], Len
					Len = Move(Ent, e_go, 200.0, Velocity, Angle)
					Velocity[2] = 0.0
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_angles, Angle)
					if (Len < 200) set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_nextthink, fCurTime + 0.1)
					return
					
				}
				case 1: {	
					if(!g_Ability[12] && g_Ability[6]) {
							CurrentColor = boss_ability(1)		
							
					} else if(g_Ability[12]) {
						CurrentColor = boss_wave()
					}
					if (!CurrentColor) {
						CurrentColor = boss_color()
						set_pev(Ent, pev_nextthink, fCurTime + 0.1)
						return
					}
					
					Anim(Ent, 2, 1.0)

					static iszInfoTarget = 0;
					if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) Fluxing = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
					
					if (!pev_valid(Fluxing))
						return
						
					new Float:Origin[3]; pev(Ent, pev_origin, Origin); Origin[2] += 110
					engfunc(EngFunc_SetOrigin, Fluxing, Origin)
					engfunc(EngFunc_SetModel, Fluxing, Resource[5])				
					switch(CurrentColor) {
						case 1: { set_rendering(Fluxing, kRenderFxNone, 255, 165, 10, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 255, 165, 10, kRenderNormal, 30); } // Red + Yellow
						case 2: { set_rendering(Fluxing, kRenderFxNone, 139, 0, 255, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 139, 0, 255, kRenderNormal, 30); Sound(0, 4, 1); } // Red + Blue
						case 3: { set_rendering(Fluxing, kRenderFxNone, 150, 75, 0, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 150, 75, 0, kRenderNormal, 30); Sound(0, 7, 1); } // Red + Green
						case 4: { set_rendering(Fluxing, kRenderFxNone, 0, 255, 0, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 30); Sound(0, 3, 1); } // Yellow + Blue
						case 5: { set_rendering(Fluxing, kRenderFxNone, 102, 255, 0, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 102, 255, 0, kRenderNormal, 30); Sound(0, 10, 1); } // Yellow + Green
						case 6: { set_rendering(Fluxing, kRenderFxNone, 48, 213, 200, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 48, 213, 200, kRenderNormal, 30); Sound(0, 7, 1); } // Blue + Green
						// Phase 2
						case 7: { set_rendering(Fluxing, kRenderFxNone, 255, 0, 247, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 255, 0, 247, kRenderNormal, 30); Sound(0, 13, 1); } // Purple
						case 8: { set_rendering(Fluxing, kRenderFxNone, 119, 146, 59, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 119, 146, 59, kRenderNormal, 30); Sound(0, 12, 1); } // LightGreen
						// Wawe
						case 9: { set_rendering(Fluxing, kRenderFxNone, 255, 0, 0, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30); } // RED
						case 10: { set_rendering(Fluxing, kRenderFxNone, 0, 255, 0, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 30); } // GREEN
						case 11: { set_rendering(Fluxing, kRenderFxNone, 0, 0, 255, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 30); } // BLUE
						
						case 12: { set_rendering(Fluxing, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255); set_rendering(Ent, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 30); Sound(0, 1, 1); } // WHITE
					}
					set_pev(Ent, pev_nextthink, fCurTime + 0.1)
					set_pev(Fluxing, pev_framerate, 5.0)
					dllfunc(DLLFunc_Spawn, Fluxing)	
					set_pev(Ent, pev_num, 2)
					return
				}
				case 2: {
					static num
					new Float:Velocity[3], Float:Angle[3]
					for(new i = 1; i <= MaxClients; i++) {
						if (!is_user_alive(i) || is_user_bot(i))
							continue
							
						Move(i, Ent, 800.0, Velocity, Angle)
						set_pev(i, pev_velocity, Velocity)
					}
					num++
					if (num >= 10) {
						set_pev(Ent, pev_num, 3)
						num = 0
					}
					set_pev(Ent, pev_nextthink, fCurTime + 0.3)
				}
				case 3: {
					
					set_pev(Ent, pev_nextthink, fCurTime + 2.2)
					engfunc(EngFunc_RemoveEntity, Fluxing)
					set_pev(Ent, pev_num, 4)
					Anim(Ent, 5, 1.0)
					Sound(Ent, 18, 0)
				}
				case 4: {
					switch (CurrentColor) {
						case 1: { g_Ability[0] = true; set_pev(Ent, pev_fuser1, fCurTime + 5.0); boss_zombie(zombie_max_health, zombie_max_speed, zombie_max_damage, zombie_max_num); }
						case 2: { g_Ability[1] = true; set_pev(Ent, pev_fuser1, fCurTime + player_speed_time); boss_zombie(zombie_min_health, zombie_min_speed, zombie_min_damage, zombie_min_num); }
						case 3: { g_Ability[2] = true; boss_zombie(zombie_normal_health, zombie_normal_speed, zombie_normal_damage, zombie_normal_num); boss_infect(poison_red_num); }
						case 4: { g_Ability[3] = true; set_pev(Ent, pev_fuser1, fCurTime + player_speed_time); }
						case 5: { g_Ability[4] = true; boss_infect(poison_yellow_num); }
						case 6: { g_Ability[5] = true; set_pev(Ent, pev_fuser1, fCurTime + player_speed_time); boss_infect(poison_blue_num); }
						// Phase 2
						case 7: { g_Ability[7] = true; set_pev(Ent, pev_fuser1, fCurTime + mine_time); boss_purple(1); }
						case 8: { g_Ability[8] = true; set_pev(Ent, pev_fuser1, fCurTime + damage_time); }
						
						case 9: {}
						case 10: { g_Ability[9] = true; set_pev(Ent, pev_fuser3, fCurTime + 1.0); }
						case 11: { g_Ability[11] = true; set_pev(Ent, pev_fuser2, fCurTime + blue_speed_time); }
						case 12: { g_Ability[14] = true; set_pev(Ent, pev_fuser1, fCurTime + 5.0); }
					}
					Anim(Ent, 2, 1.0)
					boss_shockwave(CurrentColor)
					Sound(Ent, 17, 0)
					if (g_Ability[8]) { Anim(g_Alien, 2, 1.0); return; }
					set_rendering(Ent)
					if (g_Ability[12]) {
						set_pev(Ent, pev_nextthink, fCurTime + 1.0)
						set_pev(Ent, pev_num, 0)
						return
					}
					if (CurrentColor == 1) Sound(0, 8, 1)
					CurrentColor = 0
					set_pev(Ent, pev_nextthink, fCurTime + 0.3)
					set_pev(Ent, pev_num, 0)
					set_pev(Ent, pev_ability, RUN)
				}
			}
		}
		case PHASE2: {
			switch (pev(Ent, pev_num)) {
				case 0: {
					new Float:Velocity[3], Float:Angle[3], Len
					Len = Move(Ent, e_go, 200.0, Velocity, Angle)
					Velocity[2] = 0.0
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_angles, Angle)
					if (Len < 200) {
						set_pev(Ent, pev_nextthink, fCurTime + 2.0)
						set_pev(Ent, pev_num, 1)
						Anim(Ent, 2, 1.0)
						Sound(0, 6, 1)
						g_Ability[6] = 1
						return
					}
					set_pev(Ent, pev_nextthink, fCurTime + 0.1)
					return
				}
				case 1: { Light(Ent, 1, 80, 50, {255, 0, 247}); set_pev(Ent, pev_num, 2); set_pev(Ent, pev_nextthink, fCurTime + 2.0); }
				case 2: { Light(Ent, 1, 80, 50, {119, 146, 59}); set_pev(Ent, pev_num, 3); set_pev(Ent, pev_nextthink, fCurTime + 2.0); }
				case 3: { Light(Ent, 1, 80, 50, {150, 0, 24}); set_pev(Ent, pev_num, 4); set_pev(Ent, pev_nextthink, fCurTime + 2.0); }
				case 4: { Light(Ent, 1, 80, 50, {255, 255, 255}); set_pev(Ent, pev_num, 0); set_pev(Ent, pev_ability, MAHADASH); set_pev(Ent, pev_nextthink, fCurTime + 2.0); }
			}
		}
		case MAHADASH: {
			static Float:Velocity[3], Float:Angle[3]
			switch (pev(Ent, pev_num)) {
				case 0: {
					new Player = zl_player_random()
					if (!is_user_alive(Player) || is_user_bot(Player)) {
						set_pev(Ent, pev_nextthink, fCurTime + 0.1)
						Player = zl_player_random()
						return
					}				
					Move(Ent, Player, 2000.0, Velocity, Angle)
					set_pev(Ent, pev_nextthink, fCurTime + 0.6)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_angles, Angle)
					set_pev(Ent, pev_num, 1)
					Anim(Ent, 7, 1.5)
					set_pev(Ent, pev_movetype, MOVETYPE_FLY)
				}
				case 1: {
					BeamFollow(Ent, 2, 70, {255, 0, 0})
					set_pev(Ent, pev_nextthink, fCurTime + 0.6)
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_num, 2)
				}
				case 2: {
					BeamKill(Ent)
					set_pev(Ent, pev_nextthink, fCurTime + 0.1)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
				}
			}
		}
	}
}

public Think_Ship(Ent) {
	static Float:Velocity[3], Float:Angle[3], Beam
	static Float: fCurTime; fCurTime = get_gametime();
	
	switch (pev(Ent, pev_num)) {
		case 0: {
			#if defined PLAYER_HP
			g_Health = PlayerHp(boss_hp)
			#else
			g_Health = boss_hp
			#endif
			Move(Ent, e_coord[1], 500.0, Velocity, Angle)
			set_pev(Ent, pev_body, 1)
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_num, 1)
		}
		case 1: { 
			if (Move(Ent, e_coord[1], 500.0, Velocity, Angle) < 50) {
				static iszInfoTarget = 0;
				if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) Beam = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
				
				if (!pev_valid(Beam))
					return
				//Beam = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
				new Float:Origin[3]; pev(e_light, pev_origin, Origin)
				engfunc(EngFunc_SetModel, Beam, Resource[2])
				engfunc(EngFunc_SetSize, Beam, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
				engfunc(EngFunc_SetOrigin, Beam, Origin)
				set_pev(Beam, pev_effects, pev(Beam, pev_effects) | EF_NODRAW)
				set_pev(Beam, pev_solid, SOLID_NOT)
				set_pev(Beam, pev_movetype, MOVETYPE_FLY)
				set_pev(Ent, pev_velocity, {0.0, 0.0, 0.0})
				set_pev(Ent, pev_nextthink, fCurTime + 0.5)
				set_pev(Ent, pev_body, 0)
				SpawnBoss(float(g_Health))
				set_pev(Ent, pev_num, 2)
				return
			}
		}
		case 2: {
			set_rendering(e_glow, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 90)
			set_pev(Ent, pev_nextthink, fCurTime + 0.5)
			set_pev(Ent, pev_num, 3)
			return
		}
		case 3: {
			static alpha
			set_pev(Beam, pev_effects, pev(Beam, pev_effects) & ~EF_NODRAW) 
			set_rendering(e_glow, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 90)
			set_rendering(g_Alien, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, alpha)
			alpha += 5
			
			if (alpha + 5 >= 255) {
				set_rendering(g_Alien, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255)
				set_pev(Ent, pev_nextthink, fCurTime + 0.5)
				set_pev(Ent, pev_num, 4)
				return
			}
		}
		case 4: { engfunc(EngFunc_RemoveEntity, Beam); set_pev(Ent, pev_nextthink, fCurTime + 0.5); set_pev(Ent, pev_num, 5); return; }
		case 5: { engfunc(EngFunc_RemoveEntity, e_glow); set_pev(Ent, pev_nextthink, fCurTime + 0.5); set_pev(Ent, pev_num, 6); return; }
		case 6: {
			Move(Ent, e_coord[2], 500.0, Velocity, Angle)
			set_pev(g_Alien, pev_euser1, 1)
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_body, 1)
			set_pev(Ent, pev_num, 7)
		}
		case 7: if (Move(Ent, e_coord[2], 500.0, Velocity, Angle) < 200) { engfunc(EngFunc_RemoveEntity, Ent); return; }
	}
	set_pev(Ent, pev_nextthink, fCurTime + 0.1)
}

public Think_Health(Ent) {
	static Float:Origin[3], Float:Health, Float:hpbuff
	static Float: fCurTime; fCurTime = get_gametime();
	pev(g_Alien, pev_origin, Origin)
	Origin[2] += 230.0
	set_pev(Ent, pev_origin, Origin)
	pev(g_Alien, pev_health, hpbuff)
			
	Health = hpbuff * 100.0 / g_Health
	set_pev(Ent, pev_frame, Health)
	
	switch (pev(g_Alien, pev_euser1)) {
		case 0: { set_pev(Ent, pev_nextthink, fCurTime + 1.0); return; }
		case 1: {
			Sound(0, 9, 1)
			set_pev(Ent, pev_effects, pev(Ent, pev_effects) & ~EF_NODRAW)
			set_pev(Ent, pev_nextthink, fCurTime + 8.1)
			set_pev(g_Alien, pev_nextthink, fCurTime + 8.0)
			set_pev(g_Alien, pev_euser1, 2)
			return
		}
		case 2: {
			client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[15])
			set_pev(g_Alien, pev_takedamage, DAMAGE_YES)
			set_pev(g_Alien, pev_euser1, 3)
		}
	}
	
	switch (floatround(Health, floatround_round)) {
		case 0..10: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 8) { set_pev(g_Alien, pev_button, 9); boss_ability(0); }
		case 11..20: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 7) { set_pev(g_Alien, pev_button, 8); boss_ability(0); Sound(0, 11, 1); }
		case 21..30: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 6) { set_pev(g_Alien, pev_button, 7); boss_ability(0); }
		case 31..44: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 5) { set_pev(g_Alien, pev_button, 6); boss_ability(0); }
		case 45..54: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 4) { set_pev(g_Alien, pev_button, 5); boss_ability(0); }
		case 55..64: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 3) { set_pev(g_Alien, pev_button, 4); boss_ability(0); }
		case 65..74: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 2) { set_pev(g_Alien, pev_button, 3); boss_ability(0); }
		case 75..84: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 1) { set_pev(g_Alien, pev_button, 2); boss_ability(0); }
		case 85..95: if(pev(g_Alien, pev_ability) == RUN) if(pev(g_Alien, pev_button) == 0) { set_pev(g_Alien, pev_button, 1); boss_ability(0); }
	}
	
	set_pev(Ent, pev_nextthink, fCurTime + 0.1)
}

public Think_Timer(Ent) {
	static Float: fCurTime; fCurTime = get_gametime();
	if (!zl_player_alive()) {
		set_pev(Ent, pev_nextthink, fCurTime + 1.0)
		return
	}
	
	if (pev(g_Alien, pev_deadflag) == DEAD_DYING)
		return
	
	static Counter
	switch(pev(Ent, pev_num)) {
		case 0: 
		{ 
			Counter = prepare_time; set_pev(Ent, pev_num, 1); 
			}
		case 1: 
		{ 
			Counter --; 
			if(Counter > 0) 
			{
				
				
				set_hudmessage(255, 255, 255, -1.0, 0.72, 0, 0.0, 0.8, 0.2, 0.2, -1);
				ShowSyncHudMsg(0, g_iSyncMain, "До битвы с боссом Alienом^n осталось: %i секунд.",Counter);
			}
			if(Counter && Counter < 6) client_cmd(0, "spk zl/gameplay/szTimer/%d", Counter)	
			if (Counter <= 0) 
			{ 
				EventPrepare(); 
				set_pev(Ent, pev_num, 2); 
				}
		}
		case 2: { Counter ++; }
	}
	
	set_pev(Ent, pev_nextthink, fCurTime + 1.0)


	message_begin(MSG_ALL, MsgId_RoundTime)
	write_short(Counter) 
	message_end()
	
	
	if (pev(g_Alien, pev_fuser4) <= fCurTime) {
		if (g_Ability[6]) {
			if (g_Ability[6] <= 10) 
				boss_zombie(zombie_normal_health, zombie_normal_speed, zombie_normal_damage, g_Ability[6])
			else
				boss_zombie(zombie_normal_health, zombie_normal_speed, zombie_normal_damage, 10)
			set_pev(g_Alien, pev_fuser4, fCurTime + float(zombie_phase_time))
		}
	}
	static Float:TimeBuff
	if (g_Ability[6]) {
		if (TimeBuff < fCurTime) {
			TimeBuff = fCurTime + float(zombie_add_time)
			g_Ability[6]++
		}
	}
		
	if (pev(g_Alien, pev_fuser2) <= fCurTime) {
		if (g_Ability[11]) {
			for(new id = 1; id <= MaxClients; id++) {
				g_PlayerSpeed[id] = -1
				if (is_user_connected(id)) BeamKill(id)
			}
			g_Ability[11] = false
		}
	}
	
	if (pev(g_Alien, pev_fuser1) <= fCurTime) {
		if (g_Ability[0]) {
			boss_zombie(zombie_max_health, zombie_max_speed, zombie_max_damage, 1)
			set_pev(g_Alien, pev_fuser1, fCurTime + float(zombie_spawn_time))
		}
		if (g_Ability[3] || g_Ability[1] || g_Ability[5]) {
			for(new id = 1; id <= MaxClients; id++) {
				g_PlayerSpeed[id] = -1
				if (is_user_connected(id)) BeamKill(id)
				if (g_Ability[3] || g_Ability[5]) set_pev(g_Alien, pev_fuser1, fCurTime + 99999.9)
			}
			g_Ability[1] = false
		}
		if (g_Ability[7]) {
			boss_purple(2)
			set_pev(g_Alien, pev_fuser1, fCurTime + float((mine_time + 4)))
		}
		if (g_Ability[8]) {
			set_pev(g_Alien, pev_nextthink, fCurTime + 0.3)
			set_pev(g_Alien, pev_ability, RUN)
			set_pev(g_Alien, pev_num, 0)
			set_rendering(g_Alien)
			g_Ability[8] = false
		}
		if (g_Ability[14]) {
			static num
			if (num < lighting_count) {
				boss_lighting()
				set_pev(g_Alien, pev_fuser1, fCurTime + 5.0)
				num++
			} else g_Ability[14] = false
		}
	}
	
	if (pev(g_Alien, pev_fuser3) <= fCurTime) {
		if (g_Ability[9]) {
			for(new id = 1; id <= MaxClients; id++) {
				if (!is_user_alive(g_PlayerBuffer[id]))
					continue
					
				set_pev(g_PlayerBuffer[id], pev_gravity, 0.01)
			}
			set_pev(g_Alien, pev_fuser3, fCurTime + green_gravity_time)
			g_Ability[9] = false
			g_Ability[10] = true
			return
		}
		if (g_Ability[10]) {
			for(new id = 1; id <= MaxClients; id++) {
				if (!is_user_alive(g_PlayerBuffer[id]))
					continue
				
				Sound(g_PlayerBuffer[id], 5, 1)
				set_pev(g_PlayerBuffer[id], pev_gravity, 9.9)
			}
			set_pev(g_Alien, pev_fuser3, fCurTime + 2.0)
			g_Ability[10] = false
			g_Ability[13] = true
			return
		}
		if (g_Ability[13]) {
			for(new id = 1; id <= MaxClients; id++) {
				if (!is_user_alive(g_PlayerBuffer[id]))
					continue
				
				set_pev(g_PlayerBuffer[id], pev_gravity, 0.8)
				g_PlayerBuffer[id] = -1
			}
			g_Ability[13] = false
		}
	}
}

public Think_Player(id) {
	if (!is_user_alive(g_PlayerSpeed[id]))
		return HAM_IGNORED
	
	if (g_Ability[11]) set_pev(id, pev_maxspeed, float(blue_speed_player))
	if (g_Ability[1] || g_Ability[3] || g_Ability[5]) set_pev(id, pev_maxspeed, float(player_min_speed))
	return HAM_IGNORED
}

public Think_Mine(Ent) {
	if(!pev_valid(Ent))
		return
	
	for(new i; i < sizeof e_bomb; ++i)
		if(pev_valid(g_MineExpl[i])) {
			dllfunc(DLLFunc_Use, g_MineExpl[i], g_MineExpl[i])
			g_MineExpl[i] = -1
			g_MineEnt[i] = -1
		}
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Think_Lighting(Ent) {		
	static victim = -1
	new Float:Origin[3]; pev(Ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(0)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0]) 
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 1000.0)
	write_short(g_Resource[6])
	write_byte(1)
	write_byte(5)
	write_byte(2)
	write_byte(20)
	write_byte(80)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	message_end()
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 80.0)))    
		if (is_user_alive(victim)) {
			if (pev(g_Alien, pev_weaponanim) == 0) {
				set_pev(g_Alien, pev_weaponanim, 1)
				Sound(0, 2, 1)
			}
			ExecuteHamB(Ham_TakeDamage, victim, 0, victim, float(lighting_damage), DMG_BLAST)
		}
			
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Touch_Boss(Boss, Ent) {
	if (pev(Boss, pev_ability) == ATTACK)
		return
		
	if (pev_valid(Ent) && g_Ability[6] && !g_Ability[7]) {
		for (new i; i < sizeof e_bomb; ++i) {
			if (g_MineEnt[i] == Ent) {
				if (pev_valid(g_MineExpl[i])) { dllfunc(DLLFunc_Use, g_MineExpl[i], g_MineExpl[i]); g_MineExpl[i] = -1; }
				if (pev_valid(g_MineEnt[i]))  { engfunc(EngFunc_RemoveEntity, g_MineEnt[i]); g_MineEnt[i] = -1; }
			}
		}
	}
				
		
	if (pev(Boss, pev_ability) == MAHADASH) {
		static Float:Origin[3]
		pev(Boss, pev_origin, Origin)
		if(TraceCheckCollides(Origin, 50.0)) {
			if (is_user_alive(Ent)) ExecuteHamB(Ham_Killed, Ent, Ent, 2)
			set_pev(Boss, pev_movetype, MOVETYPE_NONE)
			set_pev(Boss, pev_velocity, {0.0, 0.0, 0.0})
		}
		return
	}
		
	if (pev(Boss, pev_ability) != RUN)
		return
	
	if (!is_user_alive(Ent))
		return
		
	set_pev(Boss, pev_ability, ATTACK)
	set_pev(Boss, pev_victim, Ent)
	set_pev(Boss, pev_num, 0)
}

public Touch_Player(Player, Infector) {

	if (is_user_alive(Player) && pev_valid(Infector) && g_Ability[6] && !g_Ability[7]) {
		for (new i; i < sizeof e_bomb; ++i) {
			if(g_MineEnt[i] == Infector) {
				if (pev_valid(g_MineExpl[i])) { dllfunc(DLLFunc_Use, g_MineExpl[i], g_MineExpl[i]); g_MineExpl[i] = -1; }
				if (pev_valid(g_MineEnt[i]))  { engfunc(EngFunc_RemoveEntity, g_MineEnt[i]); g_MineEnt[i] = -1; }
			}
		}
	}
	
	if (g_Ability[2] || g_Ability[4] || g_Ability[5]) {
		if (zl_zombie_valid(Infector) && zombie_poison(Infector)) {
			set_rendering(Player, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
			ScreenFade(Player, 0, 0, {0, 255, 0}, 80, 4)
			g_PlayerBuffer[Player] = Player
		}
		
		if (is_user_alive(Infector)) {
			if (is_user_alive(g_PlayerBuffer[Infector])) {
				set_rendering(Player, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
				ScreenFade(Player, 0, 0, {0, 255, 0}, 80, 4)
				g_PlayerBuffer[Player] = Player
			}
		}
	}
}

public EventPrepare() {
	static Float: fCurTime; fCurTime = get_gametime();
	new Ship = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	new Float:Origin[3]; pev(e_coord[0], pev_origin, Origin)
	
	engfunc(EngFunc_SetModel, Ship, Resource[1])
	engfunc(EngFunc_SetSize, Ship, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	engfunc(EngFunc_SetOrigin, Ship, Origin)
	
	set_pev(Ship, pev_classname, "Ship")
	set_pev(Ship, pev_solid, SOLID_NOT)
	set_pev(Ship, pev_movetype, MOVETYPE_FLY)
	set_pev(Ship, pev_nextthink, fCurTime + 0.1)
}

public SpawnBoss(Float:hp) {
	static Float: fCurTime; fCurTime = get_gametime();
	new Float:Origin[3], hpbar
	g_Alien = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	hpbar = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_rendering(g_Alien, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	pev(e_boss, pev_origin, Origin)
	
	engfunc(EngFunc_SetModel, g_Alien, Resource[0])
	engfunc(EngFunc_SetSize, g_Alien, Float:{-32.0, -32.0, -36.0}, Float:{32.0, 32.0, 96.0})
	engfunc(EngFunc_SetOrigin, g_Alien, Origin)
	
	set_pev(g_Alien, pev_classname, "AlienBoss")
	set_pev(g_Alien, pev_solid, SOLID_BBOX)
	set_pev(g_Alien, pev_movetype, MOVETYPE_TOSS)
	set_pev(g_Alien, pev_takedamage, DAMAGE_NO)
	set_pev(g_Alien, pev_deadflag, DEAD_NO)
	set_pev(g_Alien, pev_health, hp)
	
	Origin[2] += 230.0
	engfunc(EngFunc_SetOrigin, hpbar, Origin)
	engfunc(EngFunc_SetModel, hpbar, Resource[3])
	entity_set_float(hpbar, EV_FL_scale, 0.5)
	set_pev(hpbar, pev_effects, pev(hpbar, pev_effects) | EF_NODRAW)
	set_pev(hpbar, pev_nextthink, fCurTime + 1.0)
	set_pev(hpbar, pev_classname, "Health")
	set_pev(hpbar, pev_frame, 100.0)
	
	Anim(g_Alien, 2, 1.0)
}

public Hook_Killed(victim, attacker, corpse) {
	if (jbe_totalalievplayers() <= 0){
		set_task(6.0, "changemap2")
		return HAM_IGNORED
	}
	
	if (!zl_boss_valid(victim))
		return HAM_IGNORED
		
	if (pev(victim, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED
	
	Sound(0, 0, 1)
	Anim(victim, 1, 1.0)
	set_pev(victim, pev_solid, SOLID_NOT)
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(victim, pev_deadflag, DEAD_DYING)
	set_task(10.0, "changemap")
	return HAM_SUPERCEDE
}

public Hook_BloodColor(Ent) {
	if (!zl_boss_valid(Ent))
		return HAM_IGNORED
		
	SetHamReturnInteger(blood_color)
	return HAM_SUPERCEDE
}


public Hook_TakeDamage(victim, wpn, attacker, Float:damage, damagebyte) {
	if (g_Ability[8] && zl_boss_valid(victim)) {
		if(is_user_alive(attacker)) {
			boss_damage(attacker, floatround(damage * damage_return, floatround_round), {255, 0, 0})
			return HAM_SUPERCEDE
		}
	}
	
	if (zl_boss_valid(victim) || zl_zombie_valid(victim)) {
		if (!pev_valid(attacker))
			return HAM_IGNORED
		
		static ClassName[32]
		pev(attacker, pev_classname, ClassName, charsmax(ClassName))
		
		if(equal(ClassName, "env_explosion"))
			return HAM_SUPERCEDE
		
		#if defined LASER
		if(equal(ClassName, "trigger_hurt"))
			return HAM_SUPERCEDE
		#endif
	}
	return HAM_IGNORED
}

public Hook_Spawn(id) {	
	if (!g_Ability[6]) {
		if(pev(g_Alien, pev_takedamage) == DAMAGE_NO)	
			client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[14])
		else
			client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[16])
	} else client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[15])
}



public MapEvent() {
	static Float: fCurTime; fCurTime = get_gametime();
	new LaserDmg[4], BombDmg[4]
	
	formatex(LaserDmg, charsmax(LaserDmg), "%d", damage_laser)
	formatex(BombDmg, charsmax(LaserDmg), "%d", damage_mine)
	
	for (new i; i < sizeof e_zombie; ++i) {
		static ClassName[10]
		formatex(ClassName, charsmax(ClassName), "zombie_%d", i + 1)
		e_zombie[i] = engfunc(EngFunc_FindEntityByString, e_zombie[i], "targetname", ClassName)
	}
	for (new i; i < sizeof e_bomb; ++i) {
		static ClassName[10]
		formatex(ClassName, charsmax(ClassName), "bomb%d", i)
		e_bomb[i] = engfunc(EngFunc_FindEntityByString, e_bomb[i], "targetname", ClassName)
		DispatchKeyValue(e_bomb[i], "iMagnitude", BombDmg)
	}	
	e_laser = engfunc(EngFunc_FindEntityByString, e_laser, "targetname", "damage")
	e_coord[0] = engfunc(EngFunc_FindEntityByString, e_coord[0], "targetname", "ship_1")
	e_coord[1] = engfunc(EngFunc_FindEntityByString, e_coord[1], "targetname", "ship_2")
	e_coord[2] = engfunc(EngFunc_FindEntityByString, e_coord[2], "targetname", "ship_3")
	e_light = engfunc(EngFunc_FindEntityByString, e_light, "targetname", "light")
	e_boss = engfunc(EngFunc_FindEntityByString, e_boss, "targetname", "boss")
	e_glow = engfunc(EngFunc_FindEntityByString, e_glow, "targetname", "glow")
	e_multi = engfunc(EngFunc_FindEntityByString, e_multi, "targetname", "multi")
	e_go = engfunc(EngFunc_FindEntityByString, e_go, "targetname", "go")
	DispatchKeyValue(e_laser, "damage", LaserDmg)
	set_pev(e_coord[0], pev_classname, "Timer")
	set_pev(e_coord[0], pev_nextthink, fCurTime + 1.0)
}

public plugin_precache() {
	if(!zl_boss_map()) return;
	for (new i; i < sizeof Resource; i++)
		g_Resource[i] = precache_model(Resource[i])
		
	for (new i; i < sizeof SoundList; i++)
		precache_sound(SoundList[i])
}

public plugin_cfg()
	config_load()

public changemap() {
	#if defined MAPCHOOSER
	zl_vote_start()
	#else
	server_cmd("changelevel ^"%s^"", boss_nextmap)
	#endif
}

public changemap2()
{
	if(jbe_totalalievplayers() <= 0)
	{
		#if defined MAPCHOOSER
		zl_vote_start()
		#else
		is_map_valid(g_cfg_szmap) ? server_cmd("changelevel ^"%s^"", g_cfg_szmap) : server_cmd("restart")
		#endif
	}
}


zombie_poison(Infector) {
	for (new i; i < sizeof g_ZombieBuffer; ++i)
		if (g_ZombieBuffer[i] == Infector) return 1
	return 0
}

boss_ability(num) {
	static Float: fCurTime; fCurTime = get_gametime();
	switch(num) {
		case 0: {
			Anim(g_Alien, 3, 1.8)
			set_pev(g_Alien, pev_movetype, MOVETYPE_PUSHSTEP)
			set_pev(g_Alien, pev_nextthink, fCurTime + 0.3)
			set_pev(g_Alien, pev_num, 0)
			if (pev(g_Alien, pev_button) == 5) 
				set_pev(g_Alien, pev_ability, PHASE2)
			else 
				set_pev(g_Alien, pev_ability, CAST)
			boss_clear()
		}
		case 1: {
			switch (pev(g_Alien, pev_button)) {
				case 0..5: return 0
				case 6: return 7
				case 7: return 8
				case 8: { g_Ability[12] = true; boss_wave(); }
				case 9: return 12
			}
		}
	}
	return 0
}

boss_zombie(hp, speed, damage, num) {
	--num
	for (new i; i <= num; ++i) {
		new Float:Origin[3]
		pev(e_zombie[num ? i : random(10)], pev_origin, Origin)
		zl_zombie_create(Origin, hp, speed, damage)
	}
}

boss_damage(victim, damage, color[3]) {
	ExecuteHamB(Ham_TakeDamage, victim, 0, victim, float(damage), DMG_BLAST)
	ScreenFade(victim, 6, 0, color, 130, 1)
	ScreenShake(victim, ((1<<12) * 8), ((2<<12) * 7))
}

boss_color() {
	new i, j, b, a[6]
	for(i = 0; i < 6; i++)
		a[i] = i
	   
	for(i = 0; i < 6; i++) {
		j = random(6)
		b = a[i]
		a[i] = a[j]
		a[j] = b
	}
	new randoms = (a[random(6)] + 1)
	#if defined MESSAGE
	switch (randoms) {
		case 1: UTIL_SayText(0, "!y%L", LANG_PLAYER, "RED_YELLOW")
		case 2: UTIL_SayText(0, "!y%L", LANG_PLAYER, "RED_BLUE")
		case 3: UTIL_SayText(0, "!y%L", LANG_PLAYER, "RED_GREEN")
		case 4: UTIL_SayText(0, "!y%L", LANG_PLAYER, "YELLOW_BLUE")
		case 5: UTIL_SayText(0, "!y%L", LANG_PLAYER, "YELLOW_GREEN")
		case 6: UTIL_SayText(0, "!y%L", LANG_PLAYER, "BLUE_GREEN")
	}
	#endif
	return randoms
}

boss_shockwave(CurrentColor) {
	new Float:Origin[3], Float:Vector[3], Float:Angle[3], Dist, Len, bool:ground, Damage, Color[3], Width, Radius
	switch (CurrentColor) {
		case 1: { Dist = 450; ground = true, Damage = damage_sw_maximum, Color = {255, 165, 10}, Width = 35, Radius = 1000; }	/* RedYellow */
		case 2: { Dist = 221; ground = false, Damage = damage_sw_minimum, Color = {139, 0, 255}, Width = 140, Radius = 364; }	/* RedBlue */
		case 3: { Dist = 450; ground = true, Damage = damage_shockwave, Color = {150, 75, 0}, Width = 35, Radius = 1000; }		/* RedGreen */
		case 4: { Dist = 450; ground = false, Damage = damage_sw_maximum, Color = {0, 255, 0}, Width = 140, Radius = 1000; }	/* YellowBlue */
		case 5: { Dist = 450; ground = true, Damage = damage_shockwave, Color = {102, 255, 0}, Width = 35, Radius = 1000; }	/* YellowGreen */
		case 6: { Dist = 221; ground = false, Damage = damage_sw_minimum, Color = {48, 213, 200}, Width = 140, Radius = 364; } 	/* BlueGreen */
		// Phase2
		case 7: { Dist = 450; ground = true, Damage = damage_sw_minimum, Color = {255, 0, 247}, Width = 35, Radius = 1000; } 	/* Purple */
		case 8: { Dist = 450; ground = true, Damage = damage_sw_minimum, Color = {119, 146, 59}, Width = 35, Radius = 1000; } 	/* Green */
		// Wawe
		case 9: { Dist = 450; ground = true, Damage = damage_sw_minimum, Color = {255, 0, 0}, Width = 35, Radius = 1000; } 	/* RED */
		case 10: { Dist = 450; ground = true, Damage = damage_sw_minimum, Color = {0, 255, 0}, Width = 35, Radius = 1000; } 	/* GREEN */
		case 11: { Dist = 450; ground = false, Damage = damage_sw_minimum, Color = {0, 0, 255}, Width = 140, Radius = 1000; } 	/* BLUE */
		
		case 12: { Dist = 450; ground = true, Damage = damage_sw_minimum, Color = {255, 255, 255}, Width = 35, Radius = 1000; } 	/* WHITE */
	}
	for(new i = 1; i <= MaxClients; i++) {
		if (!is_user_alive(i) || is_user_bot(i))
			continue
							
		Len = Move(i, g_Alien, 800.0, Vector, Angle)
			
		if (Len > Dist)
			continue 
			
		if (ground) {
			if (pev(i, pev_flags) & FL_ONGROUND) {
				if (CurrentColor == 9) {
					ExecuteHamB(Ham_Killed, i, i, 2)
					continue
				}
				if (CurrentColor == 10)
					g_PlayerBuffer[i] = i
				boss_damage(i, Damage, Color)
			}
		} else {
			BeamFollow(i, floatround(player_speed_time, floatround_round), 10, Color)
			g_PlayerSpeed[i] = i
			boss_damage(i, Damage, Color)
		}
				
	}
	pev(g_Alien, pev_origin, Origin)
	ShockWave(Origin, 5, Width, float(Radius), Color)
}

boss_infect(num) {
	if (g_Ability[2]) {
		new zombie_num
		new ClassName[32]
		for (new i; i < sizeof e_zombie; ++i) {		
			formatex(ClassName, charsmax(ClassName), "NpcZombie_%d", i)
			g_ZombieBuffer[i] = engfunc(EngFunc_FindEntityByString, g_ZombieBuffer[i], "classname", ClassName)
				
			if (!pev_valid(g_ZombieBuffer[i]))
				continue
				
			if (zombie_num >= num) {
				g_ZombieBuffer[i] = -1
				continue
			}
				
			set_rendering(g_ZombieBuffer[i], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
			zombie_num++
		}
	}
	
	if (g_Ability[4] || g_Ability[5]) {
		for(new i = 1; i <= num; ++i) {
			g_PlayerBuffer[i] = zl_player_random()
			ScreenFade(g_PlayerBuffer[i], 0, 0, {0, 255, 0}, 80, 4)
			set_rendering(g_PlayerBuffer[i], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
		}
	}
}

boss_purple(num) {
	static Float: fCurTime; fCurTime = get_gametime();
	static i, j, b, a[sizeof e_bomb]
	switch(num) {
		case 1: {
			#if defined LASER
			dllfunc(DLLFunc_Use, e_multi, e_multi)
			#endif
		}
		case 2: {
			/* By PomanoB Thank you :) */
			for(i = 0; i < sizeof e_bomb; i++)
				a[i] = i
		     
			for(i = 0; i < sizeof e_bomb; i++) {
				j = random(sizeof e_bomb)
				b = a[i]
				a[i] = a[j]
				a[j] = b
			}
			for (new i; i < (g_Ability[7] ? (mine_num) : (mine_num_last)); i++) {
				new Float:Origin[3]
				pev(e_bomb[a[i]], pev_origin, Origin)
				Origin[2] += 1000.0
				
				new mine
				
				static iszInfoTarget = 0;
				if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) mine = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
				
				if (!pev_valid(mine))
					continue
					

				
				g_MineEnt[i] = -1
				g_MineExpl[i] = -1
				g_MineEnt[i] = mine
				g_MineExpl[i] = e_bomb[a[i]]
				engfunc(EngFunc_SetModel, mine, Resource[7])
				engfunc(EngFunc_SetSize, mine, Float:{-5.0, -5.0, -1.0}, Float:{5.0, 5.0, 1.0})
				engfunc(EngFunc_SetOrigin, mine, Origin)
				set_pev(mine, pev_classname, "Mine")
				set_pev(mine, pev_solid, SOLID_BBOX)
				set_pev(mine, pev_movetype, MOVETYPE_TOSS)
				if (g_Ability[7]) {
					new Float:velocity[3]
					velocity[0] = random_float(0.0, 500.0)
					velocity[1] = random_float(0.0, 500.0)
					velocity[2] = random_float(0.0, 500.0)
					set_pev(mine, pev_avelocity, velocity)
					set_pev(mine, pev_nextthink, fCurTime + 3.0)
					BeamFollow(mine, 1, 5, {255, 0, 247})
				} else BeamFollow(mine, 1, 4, {255, 255, 255})
			}
		}
	}
}

boss_wave() {
	static num
	num++
	if (num > 3)
		g_Ability[12] = false
	return random_num(9, 11)
}

boss_lighting() {
	static Float: fCurTime; fCurTime = get_gametime();
	if (!g_Ability[14])
		return
		
	new Num
	if (30 <= lighting_num <= 32)
		Num = MaxClients
	else
		Num = (lighting_num ? (lighting_num + 2) : (MaxClients))
		
	for(new i = 1; i <= Num; i++) {
		if (!is_user_alive(i) || is_user_bot(i))
			continue
		
		new Float:Origin[3]
		new Lighting
		
		static iszInfoTarget = 0;
		if(iszInfoTarget || (iszInfoTarget = engfunc(EngFunc_AllocString, "info_target"))) Lighting = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget);
		
		if (!pev_valid(Lighting))
			continue
			
		pev(i, pev_origin, Origin)
		Origin[2] -= 35.0
		engfunc(EngFunc_SetModel, Lighting, Resource[8])
		engfunc(EngFunc_SetOrigin, Lighting, Origin)
		set_pev(Lighting, pev_nextthink, fCurTime + 3.0)
		set_pev(Lighting, pev_classname, "Lighting")
		Origin[0] = 90.0
		Origin[1] = random_float(0.0, 100.0)
		Origin[2] = 0.0
		set_pev(Lighting, pev_angles, Origin)
	}
}

boss_clear() {
	if (g_Ability[2] || g_Ability[4] || g_Ability[5]) {
		for (new id = 1; id <= MaxClients; id++) {
			if (!is_user_alive(g_PlayerBuffer[id]))
				continue
			
			if (g_Ability[2]) boss_damage(g_PlayerBuffer[id], poison_normal_damage, {0, 255, 0})
			if (g_Ability[4]) boss_damage(g_PlayerBuffer[id], poison_max_damage, {0, 255, 0})
			if (g_Ability[5]) boss_damage(g_PlayerBuffer[id], poison_min_damage, {0, 255, 0})
			
			set_rendering(id)
			g_PlayerBuffer[id] = -1
		}
		if (g_Ability[2]) g_Ability[2] = false
		if (g_Ability[4]) g_Ability[4] = false
		if (g_Ability[5]) g_Ability[5] = false
	}
	if (g_Ability[0]) g_Ability[0] = false
	if (g_Ability[2]) g_Ability[2] = false
	if (g_Ability[3]) g_Ability[3] = false
	if (g_Ability[7]) {
		for(new i; i < sizeof e_bomb; ++i) {
			if (pev_valid(g_MineExpl[i])) { dllfunc(DLLFunc_Use, g_MineExpl[i], g_MineExpl[i]); g_MineExpl[i] = -1; }
			if (pev_valid(g_MineEnt[i]))  { engfunc(EngFunc_RemoveEntity, g_MineEnt[i]); g_MineEnt[i] = -1; }
		}
		#if defined LASER
		dllfunc(DLLFunc_Use, e_multi, e_multi)
		#endif
		g_Ability[7] = false
		boss_purple(2)
	}
}

config_load() {
	if (zl_boss_map() != 2)
		return
		
	new path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/zl/%s", path, FILE_SETTING)
    
	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	new linedata[1024], key[64], value[960], section
	new file = fopen(path, "rt")
    
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
       
		if (!linedata[0] || linedata[0] == '/') continue;
		if (linedata[0] == '[') { section++; continue; }
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)
		
		switch (section) { 
			case 1: {
				if (equal(key, "HEALTH"))
					boss_hp = str_to_num(value)
				else if (equal(key, "PREPARE"))
					prepare_time = str_to_num(value)
				else if (equal(key, "SPEED"))
					boss_speed = str_to_num(value)
				else if (equal(key, "BLOOD_COLOR"))
					blood_color = str_to_num(value)
				#if !defined MAPCHOOSER
				else if (equal(key, "NEXT_MAP"))
					copy(boss_nextmap, charsmax(boss_nextmap), value)
				#endif
				else if (equal(key, "DMG_SW"))
					damage_shockwave = str_to_num(value)
				else if (equal(key, "DMG_ATTACK"))
					damage_boss_attack = str_to_num(value)
				else if (equal(key, "TIME_MAHADASH"))
					mahadash_time = str_to_float(value)
			}
			case 2: {
				if (equal(key, "ZM_NORMAL_NUM"))
					zombie_normal_num = str_to_num(value)
				else if (equal(key, "ZM_NORMAL_HEALTH"))
					zombie_normal_health = str_to_num(value)  
				else if (equal(key, "ZM_NORMAL_DAMAGE"))
					zombie_normal_damage = str_to_num(value)
				else if (equal(key, "ZM_NORMAL_SPEED"))
					zombie_normal_speed = str_to_num(value)
			}
			case 3: {
				if (equal(key, "DMG_SW_MAX"))
					damage_sw_maximum = str_to_num(value)
				else if (equal(key, "ZM_TIME_SPAWN"))
					zombie_spawn_time = str_to_num(value)  
				else if (equal(key, "ZM_MAX_NUM"))
					zombie_max_num = str_to_num(value)
				else if (equal(key, "ZM_MAX_HEALTH"))
					zombie_max_health = str_to_num(value)
				else if (equal(key, "ZM_MAX_DAMAGE"))
					zombie_max_damage = str_to_num(value)
				else if (equal(key, "ZM_MAX_SPEED"))
					zombie_max_speed = str_to_num(value)
			}
			case 4: {
				if (equal(key, "ZM_MIN_NUM"))
					zombie_min_num = str_to_num(value)
				else if (equal(key, "ZM_MIN_HEALTH"))
					zombie_min_health = str_to_num(value)  
				else if (equal(key, "ZM_MIN_DAMAGE"))
					zombie_min_damage = str_to_num(value)
				else if (equal(key, "ZM_MIN_SPEED"))
					zombie_min_speed = str_to_num(value)
				else if (equal(key, "PLAYER_MIN_SPEED"))
					player_min_speed = str_to_num(value)
				else if (equal(key, "PLAYER_SPEED_TIME"))
					player_speed_time = str_to_float(value)
			}
			case 5: {
				if (equal(key, "POISON_RED_NUM"))
					poison_red_num = str_to_num(value)
				else if (equal(key, "POISON_YELLOW_NUM"))
					poison_yellow_num = str_to_num(value)  
				else if (equal(key, "POISON_BLUE_NUM"))
					poison_blue_num = str_to_num(value)
				else if (equal(key, "POISON_MAX_DAMAGE"))
					poison_max_damage = str_to_num(value)
				else if (equal(key, "POISON_NORMAL_DMG"))
					poison_normal_damage = str_to_num(value)
				else if (equal(key, "POISON_MIN_DAMAGE"))
					poison_min_damage = str_to_num(value)
			}
			case 6: {
				if (equal(key, "ZOMBIE_PHASE_NUM"))
					zombie_phase_time = str_to_num(value)
				else if (equal(key, "ZOMBIE_ADD_TIME"))
					zombie_add_time = str_to_num(value)  
			}
			case 7: {
				if (equal(key, "DAMAGE_LASER"))
					damage_laser = str_to_num(value)
				else if (equal(key, "DAMAGE_MINE"))
					damage_mine = str_to_num(value)  
				else if (equal(key, "MINE_TIME"))
					mine_time = str_to_num(value)
				else if (equal(key, "MINE_NUM"))
					mine_num = str_to_num(value)
				else if (equal(key, "MINE_NUM_LAST"))
					mine_num_last = str_to_num(value)
			}
			case 8: {
				if (equal(key, "DAMAGE_RETURN"))
					damage_return = str_to_float(value)
				else if (equal(key, "PROTECT_TIME"))
					damage_time = str_to_num(value)  
			}
			case 9: {
				if (equal(key, "BLUE_SPEED_TIME"))
					blue_speed_time = str_to_num(value)
				else if (equal(key, "BLUE_SPEED_PLAYER"))
					blue_speed_player = str_to_num(value)  
				else if (equal(key, "GREEN_TIME"))
					green_gravity_time = str_to_num(value)  
			}
			case 10: {
				if (equal(key, "LIGHTING_NUM"))
					lighting_num = str_to_num(value)
				else if (equal(key, "LIGHTING_COUNT"))
					lighting_count = str_to_num(value)  
				else if (equal(key, "LIGHTING_DAMAGE"))
					lighting_damage = str_to_num(value)  
			}
		}
	}
	if (file) fclose(file)
}

/*========================
// STOCK 
========================*/

stock bool:TraceCheckCollides(Float:origin[3], const Float:BOUNDS) {
	new Float:traceEnds[8][3], Float:traceHit[3], hitEnt
	traceEnds[0][0] = origin[0] - BOUNDS
	traceEnds[0][1] = origin[1] - BOUNDS
	traceEnds[0][2] = origin[2] - BOUNDS

	traceEnds[1][0] = origin[0] - BOUNDS
	traceEnds[1][1] = origin[1] - BOUNDS
	traceEnds[1][2] = origin[2] + BOUNDS

	traceEnds[2][0] = origin[0] + BOUNDS
	traceEnds[2][1] = origin[1] - BOUNDS
	traceEnds[2][2] = origin[2] + BOUNDS

	traceEnds[3][0] = origin[0] + BOUNDS
	traceEnds[3][1] = origin[1] - BOUNDS
	traceEnds[3][2] = origin[2] - BOUNDS
     
	traceEnds[4][0] = origin[0] - BOUNDS
	traceEnds[4][1] = origin[1] + BOUNDS
	traceEnds[4][2] = origin[2] - BOUNDS

	traceEnds[5][0] = origin[0] - BOUNDS
	traceEnds[5][1] = origin[1] + BOUNDS
	traceEnds[5][2] = origin[2] + BOUNDS

	traceEnds[6][0] = origin[0] + BOUNDS
	traceEnds[6][1] = origin[1] + BOUNDS
	traceEnds[6][2] = origin[2] + BOUNDS

	traceEnds[7][0] = origin[0] + BOUNDS
	traceEnds[7][1] = origin[1] + BOUNDS
	traceEnds[7][2] = origin[2] - BOUNDS

	for (new i = 0; i < 8; i++) {
		if (point_contents(traceEnds[i]) != CONTENTS_EMPTY)
			return true

		hitEnt = trace_line(0, origin, traceEnds[i], traceHit)
		if (hitEnt != 0) return true
		
		for (new j = 0; j < 3; j++) {
			if (traceEnds[i][j] != traceHit[j])
				return true
		}
	}
	return false
}

stock Move(Start, End, Float:speed, Float:Velocity[], Float:Angles[]) {
	new Float:Origin[3], Float:Origin2[3], Float:Angle[3], Float:Vector[3], Float:Len
	pev(Start, pev_origin, Origin2)
	pev(End, pev_origin, Origin)
	xs_vec_sub(Origin, Origin2, Vector)
	Len = xs_vec_len(Vector)
	vector_to_angle(Vector, Angle)
	Angles[0] = 0.0
	Angles[1] = Angle[1]
	Angles[2] = 0.0
	xs_vec_normalize(Vector, Vector)
	xs_vec_mul_scalar(Vector, speed, Velocity)
	return floatround(Len, floatround_round)
}

stock PlayerHp(hp) {
	new Count, Hp
	for(new id = 1; id <= MaxClients; id++)
		if (is_user_connected(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	return Hp
}

stock Anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}

stock Sound(Ent, Sound, type) {
	if (type)
		client_cmd(Ent, "spk ^"%s^"", SoundList[Sound]) 
	else
		engfunc(EngFunc_EmitSound, Ent, CHAN_AUTO, SoundList[Sound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock ScreenFade(id, Timer, FadeTime, Colors[3], Alpha, type) {
	if(id) if(!is_user_connected(id)) return

	if (Timer > 0xFFFF) Timer = 0xFFFF
	if (FadeTime <= 0) FadeTime = 4
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, MsgId_ScreenFade, _, id);
	write_short(Timer * 1 << 12)
	write_short(FadeTime * 1 << 12)
	switch (type) {
		case 1: write_short(0x0000)		// IN ( FFADE_IN )
		case 2: write_short(0x0001)		// OUT ( FFADE_OUT )
		case 3: write_short(0x0002)		// MODULATE ( FFADE_MODULATE )
		case 4: write_short(0x0004)		// STAYOUT ( FFADE_STAYOUT )
		default: write_short(0x0001)
	}
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}

stock ScreenShake(id, duration17, frequency) {
	if(id) if(!is_user_connected(id)) return
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, MsgId_ScreenShake, _, id ? id : 0);
	write_short(1<<14)
	write_short(duration17)
	write_short(frequency)
	message_end()
}

stock ShockWave(Float:Origin[3], Life, Width, Float:Radius, Color[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // x
	engfunc(EngFunc_WriteCoord, Origin[1]) // y
	engfunc(EngFunc_WriteCoord, Origin[2]-40.0) // z
	engfunc(EngFunc_WriteCoord, Origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, Origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, Origin[2]+Radius) // z axis
	write_short(g_Resource[4]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(Life) // life (4)
	write_byte(Width) // width (20)
	write_byte(0) // noise
	write_byte(Color[0]) // red
	write_byte(Color[1]) // green
	write_byte(Color[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}

stock Light(Ent, Time, Radius, Rate, Colors[3]) {
	if(!pev_valid(Ent)) return
	new Float:Origin[3]; pev(Ent, pev_origin, Origin)
		
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // x
	engfunc(EngFunc_WriteCoord, Origin[1]) // y
	engfunc(EngFunc_WriteCoord, Origin[2]) // z
	write_byte(Radius) // radius
	write_byte(Colors[0]) // r
	write_byte(Colors[1]) // g
	write_byte(Colors[2]) // b
	write_byte(10 * Time) //life
	write_byte(Rate) //decay rate
	message_end()
}

stock BeamFollow(id, Life, Size, Color[3]) {
	if (is_user_alive(id) || pev_valid(id)) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)     // TE_BEAMFOLLOW ( msg #22) create a line of decaying beam segments until entity stops moving
	write_byte(TE_BEAMFOLLOW)                // msg id
	write_short(id)                // short (entity:attachment to follow)
	write_short(g_Resource[6])         // short (sprite index)
	write_byte(Life * 10)                // byte (life in 0.1's)
	write_byte(Size)                // byte (line width in 0.1's)
	write_byte(Color[0])                // byte (color)
	write_byte(Color[1])                // byte (color)
	write_byte(Color[2])                // byte (color)
	write_byte(255)                // byte (brightness)
	message_end()
}
}

stock BeamKill(id) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(id)
	message_end()
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
