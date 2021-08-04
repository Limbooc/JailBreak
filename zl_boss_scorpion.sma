/* 
	ScorpionBoss
	
	www.ZombieLite.Ru
	www.Alexander3.Ru
*/

#include < zl_scorpion >

#define NAME	"ScorpionBoss"
#define AUTHOR	"Alexander.3"

#define PLAYER_HP

#define STORM	5
#define NUM_TENTACLE	9
#define OFFSET_TENTACLE 150.0

static g_Resource[][] = {
	"models/zl/npc/scorpion/zl_scorpion_f.mdl",
	"models/zl/npc/scorpion/zl_tornado.mdl",
	"sprites/zl/npc/scorpion/zl_healthbar.spr",
	"models/zl/npc/scorpion/zl_swing.mdl", // 3
	"models/zl/npc/scorpion/zl_tentacle.mdl",
	"models/zl/npc/scorpion/zl_hole.mdl",
	"sprites/laserbeam.spr",				// 6
	"sprites/zl/npc/scorpion/zl_focus.spr",
	"sprites/zl/npc/scorpion/zl_healing.spr",	
	"models/zl/npc/scorpion/zl_tentacle_sign.mdl",		// 9
	"models/zl/npc/scorpion/zl_tentacle2.mdl"		// 10
	
	
}

new const g_SoundList[][] = {
	"zl/npc/scorpion/appear.wav",
	"zl/npc/scorpion/attack1.wav",
	"zl/npc/scorpion/attack2.wav",
	"zl/npc/scorpion/attack3.wav",		// 3
	"zl/npc/scorpion/dash_end.wav",		// 4
	"zl/npc/scorpion/dash_start.wav",		// 5
	"zl/npc/scorpion/death.wav",
	"zl/npc/scorpion/guard_start.wav",		// 7
	"zl/npc/scorpion/guard_loop.wav",
	"zl/npc/scorpion/guard_end.wav",
	"zl/npc/scorpion/idle.wav",		// 10
	"zl/npc/scorpion/step1.wav",
	"zl/npc/scorpion/step2.wav",
	"zl/npc/scorpion/storm_down.wav",
	"zl/npc/scorpion/storm_down2.wav",	// 14
	"zl/npc/scorpion/storm_prepare.wav",
	"zl/npc/scorpion/storm_end.wav",
	"zl/npc/scorpion/tentacle1.wav",
	"zl/npc/scorpion/tentacle2.wav",
	"zl/npc/scorpion/tentacle3.wav",	
	"zl/npc/scorpion/sandstorm.wav",		// 20
	"zl/npc/scorpion/windstorm.wav"
}

enum {
	IDLE,
	RUN,
	ATTACK,
	TENTACLE,
	DASH,
	DOWN0,
	DOWN1,
	TENTACLE2,
	REGENERATION
}

static g_Scorpion, g_Ability, g_Tentacle[NUM_TENTACLE]
static i_Resource[sizeof g_Resource], g_MaxPlayer
static e_storm_start[STORM + 1], e_storm_end[STORM + 1]
static e_down[3] // 0 - First, 1 - Phase2, 2 - Two
static Float:g_Damage, g_Phase = 0, Float:g_LiderDamage[33]
static zl_cvar[5], Float:zl_fcvar[2]


public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (zl_boss_map() != 7) {
		pause("ad")
		return
	}
	
	map_load()
	
	register_think("scorpion_storm", "think_storm")
	register_think("scorpion_swing", "think_swing")
	register_think("scorpion_tornado", "think_tornado")
	register_think("scorpion_hole", "think_hole")
	register_think("scorpion_tentacle", "think_tentacle")
	register_think("scorpion_regeneration", "think_regeneration")
	register_think("scorpion_hpbar", "think_healthbar")
	register_think("boss_scorpion", "think_boss")	
	
	register_touch("boss_scorpion", "player", "touch_boss")
	
	RegisterHam(Ham_TakeDamage, "info_target", "Hook_Damage", 0)
	
	g_MaxPlayer = get_maxplayers()
}

public think_boss( boss ) {
	if (pev(boss, pev_deadflag) == DEAD_DYING) {
		return
	}
	
	if (zl_player_alive() < 1) {
		zl_anim(boss, 1, 1.0)
		set_pev(boss, pev_movetype, MOVETYPE_NONE)
		set_pev(boss, pev_nextthink, get_gametime() + 0.1)
		return
	}
	static Float:timer
	if (timer <= get_gametime() && pev(boss, pev_sequence) == 4 && g_Ability == RUN) {
		timer = get_gametime() + zl_fcvar[0]
		if (g_Phase < 5)
			g_Ability = TENTACLE
		else {
			switch(random(3)) {
				case 0: g_Ability = TENTACLE
				case 1: g_Ability = TENTACLE2
				case 2: g_Ability = DOWN0
			}
		}
	}
	
	switch(g_Ability) {
		case IDLE: zl_anim(boss, 2, 1.0)
		case RUN: {
			static victim
			
			if (!is_user_alive(victim)) {
				victim = zl_player_choose(boss, 0)
			}
			
			if (pev(boss, pev_sequence) != 4) {
				set_pev(boss, pev_movetype, MOVETYPE_PUSHSTEP)
				zl_anim(boss, 4, 1.0)
			}
			
			static Float:velocity[3], Float:angle[3]
			zl_move(boss, victim, float(zl_cvar[1]), velocity, angle)
			set_pev(boss, pev_velocity, velocity)
			set_pev(boss, pev_angles, angle)
			set_pev(boss, pev_nextthink, get_gametime() + 0.1)
		}
		case ATTACK: {
			set_pev(boss, pev_movetype, MOVETYPE_NONE)
			
			static rnd, victim
			
			if (!rnd) {
				rnd = random_num(1, 3)
				victim = pev(boss, pev_victim)
			}
			
			switch(rnd) {
				case 1: {
					static num
					switch(num) {
						case 0: {
							zl_anim(boss, 5, 1.0)
							set_pev(boss, pev_nextthink, get_gametime() + 1.0)
							num++
						}
						case 1: {
							set_pev(boss, pev_nextthink, get_gametime() + 1.0)
							
							if (is_user_alive(victim)) {
								if (entity_range(victim, boss) < 290)
									ExecuteHamB(Ham_Killed, victim, victim, 2)
							}
								
							g_Ability = 1
							num = 0
							rnd = 0
						}
					}
				}
				case 2: {
					static num
					switch(num) {
						case 0: {
							zl_anim(boss, 6, 1.0)
							set_pev(boss, pev_nextthink, get_gametime() + 1.3)
							num++
						}
						case 1: {
							set_pev(boss, pev_nextthink, get_gametime() + 1.0)
							
							if (is_user_alive(victim)) {
								if (entity_range(victim, boss) < 320) {
									new i
									for (i = 1; i <= g_MaxPlayer; ++i) {
										if (i == victim)
											continue
											
										if (!is_user_alive(i))
											continue
											
										if( entity_range(victim, i) > 200)
											continue
											
										zl_slap(i, 1000, zl_cvar[2], 0)
										zl_screenfade(i, 1, 1, {50, 0, 0}, 50, 1)
										zl_screenshake(i, 15, 3)
									}
									ExecuteHamB(Ham_Killed, victim, victim, 2)
								}
							}
							g_Ability = 1
							num = 0
							rnd = 0
						}
					}
				}
				case 3: {
					static num
					switch(num) {
						case 0: {
							zl_anim(boss, 7, 1.0)
							set_pev(boss, pev_nextthink, get_gametime() + 1.6)
							num++
						}
						case 1: {
							set_pev(boss, pev_nextthink, get_gametime() + 3.0)
							
							new Float:origin[3]
							pev(boss, pev_origin, origin)
							origin[2] -= 33.0
							
							new swing = create_entity("info_target")
							engfunc(EngFunc_SetModel, swing, g_Resource[3])							
							engfunc(EngFunc_SetOrigin, swing, origin)
							set_rendering(swing, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
							set_pev(swing, pev_classname, "scorpion_swing")
							set_pev(swing, pev_nextthink, get_gametime() + 0.1)
							zl_anim(swing, 0, 1.0)
							
							new i
							for(i = 1; i<=g_MaxPlayer; ++i) {
								if (!is_user_alive(i))
									continue

								if (entity_range(i, boss) < 465) {
									zl_slap(i, 1000, zl_cvar[2], 0)
									zl_screenfade(i, 1, 1, {50, 0, 0}, 50, 1)
									zl_screenshake(i, 15, 3)
								}
							}	
							g_Ability = 1
							num = 0
							rnd = 0
						}
					}
				}
			}
			
		}
		case TENTACLE: {
			static Float:origin[NUM_TENTACLE][3]
			static num
			
			switch(num) {
				case 0: {
					set_pev(boss, pev_movetype, MOVETYPE_NONE)
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					zl_anim(boss, 2, 1.0)					
					new i, s, TentaclePlayer[32]
					for(i = 1; i<=g_MaxPlayer; ++i) {
						if (!is_user_alive(i))
							continue
							
						if (entity_range(i, boss) < 630) {
							TentaclePlayer[s] = i
							s++
						}
					}
					if (s == 0) {
						set_pev(boss, pev_victim, 0)
						set_pev(boss, pev_nextthink, get_gametime() + 0.1)
						g_Ability = DASH
						return
					}
					
					/* set origin victim */
					new Float:origin_victim[3], Float:origin_boss[3], Float:vector[3]
					
					new victim = TentaclePlayer[((s == 1) ? 0 : (random(s)))]
										
					pev(victim, pev_origin, origin_victim)
					pev(boss, pev_origin, origin_boss)
					xs_vec_sub(origin_victim, origin_boss, vector)
					vector_to_angle(vector, vector)
					set_pev(boss, pev_angles, vector)
										
					for(i = 0; i < NUM_TENTACLE; ++i)
						origin[i][2] = origin_victim[2] - 35.0
					
					origin[0][0] = origin_victim[0]
					origin[0][1] = origin_victim[1]
					
					origin[1][0] = origin_victim[0] + OFFSET_TENTACLE
					origin[1][1] = origin_victim[1] - OFFSET_TENTACLE
					
					origin[2][0] = origin_victim[0] - OFFSET_TENTACLE
					origin[2][1] = origin_victim[1]
					
					origin[3][0] = origin_victim[0] 
					origin[3][1] = origin_victim[1] - OFFSET_TENTACLE
					
					origin[4][0] = origin_victim[0] + OFFSET_TENTACLE
					origin[4][1] = origin_victim[1]
					
					origin[5][0] = origin_victim[0] + OFFSET_TENTACLE
					origin[5][1] = origin_victim[1] + OFFSET_TENTACLE
					
					origin[6][0] = origin_victim[0]
					origin[6][1] = origin_victim[1] + OFFSET_TENTACLE
					
					origin[7][0] = origin_victim[0] - OFFSET_TENTACLE
					origin[7][1] = origin_victim[1] + OFFSET_TENTACLE
						
					origin[8][0] = origin_victim[0] - OFFSET_TENTACLE
					origin[8][1] = origin_victim[1] - OFFSET_TENTACLE
					
					num++
				}
				case 1: {
					set_pev(boss, pev_nextthink, get_gametime() + 2.3)
					zl_anim(boss, 8, 2.5)
					zl_sound(0, g_SoundList[17], 0)
					num++
				}
				case 2: {					
					new i
					for (i = 0; i<NUM_TENTACLE; ++i) {
						g_Tentacle[i] = create_entity("info_target")
						engfunc(EngFunc_SetModel, g_Tentacle[i], g_Resource[4])
						engfunc(EngFunc_SetOrigin, g_Tentacle[i], origin[i])
						set_pev(g_Tentacle[i], pev_classname, "scorpion_tentacle")
						zl_anim(g_Tentacle[i], 0, 1.0)
					}
					
					new victim, player[32], count
					
					for(i = 1; i <= g_MaxPlayer; ++i) {
						if(!is_user_alive(i))
							continue
							
						if (entity_range(g_Tentacle[0], i) > 220)
							continue
						
						set_rendering(i, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 50)
						if(~pev(i, pev_flags) & FL_FROZEN) set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN)
						player[count] = i
						count++
					}
					
					//clear
					num = 0
					set_pev(boss, pev_nextthink, get_gametime() + 2.0)
					g_Ability = DASH
					
					if (count == 0) {
						victim = zl_player_choose(boss, ZL_CHOOSE_RANDOM)
						set_pev(boss, pev_victim, victim)
						return
					}
					
					victim = player[((count == 1) ? 0 : (random(count)))]
					set_pev(boss, pev_victim, victim)
				}
			}
		}
		case DASH: {
			static num, Float:origin_end[3]
			switch(num) {
				case 0: {
					new victim = pev(boss, pev_victim)
					set_pev(boss, pev_nextthink, get_gametime() + 1.5)
					set_pev(boss, pev_movetype, MOVETYPE_NONE)
					zl_anim(boss, 17, 1.0)
					num++
					
					if (!is_user_alive(victim))
						victim = zl_player_choose(boss, ZL_CHOOSE_MAX)
					
					new Float:origin_start[3], Float:vector[3], Float:angle[3]
					pev(boss, pev_origin, origin_start)
					pev(victim, pev_origin, origin_end)
					origin_end[2] = origin_start[2]
					xs_vec_sub(origin_end, origin_start, vector)
					vector_to_angle(vector, angle)
					set_pev(boss, pev_angles, angle)
				}
				case 1: {
					static Float:origin_boss[3], Float:vector[3], Float:len
					pev(boss, pev_origin, origin_boss)
					xs_vec_sub(origin_end, origin_boss, vector)
					len = xs_vec_len(vector)
					xs_vec_normalize(vector, vector)
					xs_vec_mul_scalar(vector, 1500.0, vector)
										
					if(pev(boss, pev_sequence) != 18) {
						set_pev(boss, pev_movetype, MOVETYPE_FLY)
						zl_anim(boss, 18, 1.0)
					}
					
					if(len <= 100) {
						static e
						while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "scorpion_tentacle"))) {
							if(pev_valid(e)) {
								engfunc(EngFunc_RemoveEntity, e)
							}
						}
						
						new i
						for(i=1; i<=g_MaxPlayer; ++i) {
							if(!is_user_alive(i))
								continue
								
							if(pev(i, pev_flags) & FL_FROZEN) {
								set_rendering(i)
								set_pev(i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN)
							}
						}
						
						set_pev(boss, pev_nextthink, get_gametime() + 1.6)
						set_pev(boss, pev_movetype, MOVETYPE_NONE)
						zl_anim(boss, 19, 1.0)
						g_Ability = RUN
						num = 0
						return
					}
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					set_pev(boss, pev_velocity, vector)
				}
			}
		}
		case DOWN0: { // FirstDown
			static num
			switch(num) {
				case 0: {
					if (pev(boss, pev_movetype) != MOVETYPE_FLY)
						set_pev(boss, pev_movetype, MOVETYPE_FLY)
						
					if (pev(boss, pev_sequence) != 4)
						zl_anim(boss, 4, 1.0)
					
					static len, Float:velocity[3], Float:angle[3], Float:origin[3]
					static rnd
					if (rnd == 0) {
						rnd = (random(2) ? e_down[0] : e_down[2])
					}
					len = zl_move(boss, rnd, float(zl_cvar[1]), velocity, angle)
					set_pev(boss, pev_angles, angle)
					set_pev(boss, pev_velocity, velocity)
					
					if(len < 70) {
						pev(boss, pev_origin, origin)
						new hole = create_entity("info_target")
						origin[2] -= 30.0
						engfunc(EngFunc_SetOrigin, hole, origin)
						engfunc(EngFunc_SetModel, hole, g_Resource[5])
						set_pev(boss, pev_solid, SOLID_NOT)
						set_pev(boss, pev_nextthink, get_gametime() + 8.0)
						set_pev(hole, pev_nextthink, get_gametime() + 0.1)
						set_pev(hole, pev_classname, "scorpion_hole")
						zl_anim(boss, 10, 3.0)
						zl_anim(hole, 0, 0.2)
						zl_sound(0, g_SoundList[13], 0)
						num++
						rnd = 0
						return
					}
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
				}
				case 1: {
					new Float:origin[3]
					pev(e_down[random(3)], pev_origin, origin)
					engfunc(EngFunc_SetOrigin, boss, origin)
					set_pev(boss, pev_solid, SOLID_BBOX)
					set_pev(boss, pev_nextthink, get_gametime() + 6.2)
					zl_anim(boss, 12, 1.0)
					g_Ability = RUN
					num = 0
				}
			}
		}
		case DOWN1: { // Storm
			static num
			switch (num) {
				case 0: {
					if (pev(boss, pev_movetype) != MOVETYPE_FLY)
						set_pev(boss, pev_movetype, MOVETYPE_FLY)
						
					if (pev(boss, pev_sequence) != 4)
						zl_anim(boss, 4, 1.0)
					
					static len, Float:velocity[3], Float:angle[3]
					len = zl_move(boss, e_down[1], float(zl_cvar[1]), velocity, angle)
					set_pev(boss, pev_angles, angle)
					set_pev(boss, pev_velocity, velocity)
					
					if(len < 70) {
						set_pev(boss, pev_solid, SOLID_NOT)
						set_pev(boss, pev_nextthink, get_gametime() + 3.0)
						zl_anim(boss, 11, 3.0)
						zl_sound(0, g_SoundList[14], 0)
						num++
						return
					}
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
				}
				case 1: {
					new i, j, b, a[STORM]
					for(i = 0; i < sizeof a; i++)
						a[i] = i
						    
					for(i = 0; i < sizeof a; i++) {
						j = random(sizeof a - 1)
						b = a[i]
						a[i] = a[j]
						a[j] = b
					}
					
					new s = 0
					
					static stage
					switch(g_Phase) {
						case 6: stage = 2
						case 7: stage = 3
						case 8: stage = 4
						case 9: stage = 5
					}
					
					for (s = 0; s < stage; ++s) {		
						new storm = create_entity("info_target")
												
						new Float:origin[3], Float:origin2[3], Float:vector[3]
						new random_storm = 0
						if(g_Ability == 9) random_storm = random(2)
						
						if (random_storm == 0) {
							pev(e_storm_start[a[s]], pev_origin, origin)
							pev(e_storm_end[a[s]], pev_origin, origin2)
						} else {
							pev(e_storm_end[a[s]], pev_origin, origin)
							pev(e_storm_start[a[s]], pev_origin, origin2)
						}
						
						engfunc(EngFunc_SetOrigin, storm, origin)
						engfunc(EngFunc_SetModel, storm, g_Resource[1])
						set_pev(storm, pev_classname, "scorpion_storm")
						set_pev(storm, pev_nextthink, get_gametime() + 0.1)
						set_pev(storm, pev_solid, SOLID_NOT)
						set_pev(storm, pev_movetype, MOVETYPE_NOCLIP)
						
						xs_vec_sub(origin2, origin, vector)
						xs_vec_normalize(vector, vector)
						xs_vec_mul_scalar(vector, 500.0, vector)
						set_pev(storm, pev_velocity, vector)
						
						zl_anim(storm, 0, 1.0)
					}
					zl_sound(0, g_SoundList[21], 0)
					set_pev(boss, pev_nextthink, get_gametime() + 7.0)
					num++
					
				}
				case 2: {
					static e
					while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "scorpion_storm"))) {
						if(pev_valid(e)) {
							engfunc(EngFunc_RemoveEntity, e)
						}
					}
					new Float:origin[3]
					pev(e_down[random(3)], pev_origin, origin)
					engfunc(EngFunc_SetOrigin, boss, origin)
					set_pev(boss, pev_solid, SOLID_BBOX)
					set_pev(boss, pev_nextthink, get_gametime() + 6.2)
					zl_anim(boss, 12, 1.0)
					g_Ability = RUN
					num = 0
					
				}
			}
		}
		case TENTACLE2: { // Tentacle
			static num
			switch(num) {
				case 0: {
					set_pev(boss, pev_nextthink, get_gametime() + 3.0)
					set_pev(boss, pev_movetype, MOVETYPE_NONE)
					zl_anim(boss, 9, 1.0)
					num++
				}
				case 1: {
					new i, Float:origin[3], Float:end_origin[3]
					for(i = 1; i<=g_MaxPlayer; ++i) {
						if(!is_user_alive(i))
							continue
							
						pev(i, pev_origin, origin)
						
						/* vector create */
						origin[2] = origin[2] + 300.0
						end_origin[0] = origin[0]
						end_origin[1] = origin[1]
						end_origin[2] = origin[2] - 600.0
									
						new tr
						engfunc(EngFunc_TraceLine, origin, end_origin, IGNORE_MONSTERS, -1, tr)
						get_tr2(tr, TR_vecEndPos, end_origin)
						end_origin[2] += 1.0
						/* end vector create */
								
						new ts = create_entity("info_target")
						engfunc(EngFunc_SetModel, ts, g_Resource[9])
						engfunc(EngFunc_SetOrigin, ts, end_origin)
						set_pev(ts, pev_classname, "scorpion_tentacle")
					}
					num++
					set_pev(boss, pev_nextthink, get_gametime() + 3.0)
					zl_sound(0, g_SoundList[19], 0)
				}
				case 2: {
					static e
					while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "scorpion_tentacle"))) {
						if(pev_valid(e)) {
							engfunc(EngFunc_SetModel, e, g_Resource[10])
							zl_anim(e, 0, 0.8)
							set_pev(e, pev_nextthink, get_gametime() + 0.1)
						}
					}
					zl_sound(0, g_SoundList[18], 0)
					set_pev(boss, pev_nextthink, get_gametime() + 1.3)
					num++
				}
				case 3: {
					static e
					while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "scorpion_tentacle"))) {
						if(pev_valid(e)) {
							engfunc(EngFunc_RemoveEntity, e)
						}
					}
					num = 0
					g_Ability = RUN
					set_pev(boss, pev_nextthink, get_gametime() + 1.0)
				}
			}
			
		}
		case REGENERATION: {
			static num, victim
			switch(num) {
				case 0: {
					if (pev(boss, pev_sequence) != 2) {
						set_pev(boss, pev_movetype, MOVETYPE_NONE)
						zl_anim(boss, 2, 1.0)
					}
										
					new Float:dmg_buff, i = 1
					for (i = 1; i <= g_MaxPlayer; ++i) {
						if (!is_user_alive(i)) continue
								
						if (g_LiderDamage[i] > dmg_buff) {
							dmg_buff = g_LiderDamage[i]
							victim = i
						}
					}
					
					set_pev(boss, pev_victim, victim)
					new Float:angle[3]
					zl_move(boss, victim, _, _, angle)
					set_pev(boss, pev_angles, angle)
					
					set_pev(boss, pev_nextthink, get_gametime() + 2.1)
					zl_laser(boss | 0x3000, victim, {0, 255, 0}, 15, 0)
					set_rendering(victim, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 50)
					
					new name[32]
					get_user_name(victim, name, charsmax(name))
					//zl_colorchat(0, "!g[!yScorpion!g] !yAggressor focused in !g%s", name)
					//zl_colorchat(victim, "!g[!yScorpion!g] !yYou !gfocused!y, please in laser")
					
					set_dhudmessage(255, 0, 0, -1.0, 0.2, 0, 1.0, 1.0);
					show_dhudmessage(0, "Агрессор сфокусировался на игрока^n%s!", name);
					
					num++
				}
				case 1: {
					new Float:angle[3]
					pev(boss, pev_angles, angle)
					angle[1] = random_float(-180.0, 180.0)
					set_pev(boss, pev_angles, angle)
					set_pev(boss, pev_nextthink, get_gametime() + 4.0)
					zl_anim(boss, 13, 1.0)
					num++
				}
				case 2: {
					g_Damage = 0.0
					zl_anim(boss, 14, 1.0)
					
					new Float:angle[3], Float:origin[3]
					pev(boss, pev_angles, angle)
					pev(boss, pev_origin, origin)
					angle_vector(angle, ANGLEVECTOR_FORWARD, angle)
					origin[0] = origin[0] + angle[0] * 400.0
					origin[1] = origin[1] + angle[1] * 400.0
					origin[2] -= 32.0
					
					new buff_ent = create_entity("info_target")
					engfunc(EngFunc_SetOrigin, buff_ent, origin)
					engfunc(EngFunc_SetModel, buff_ent, g_Resource[7])
					set_pev(buff_ent, pev_classname, "scorpion_regeneration")
					set_pev(buff_ent, pev_nextthink, get_gametime() + 0.1)
					set_pev(boss, pev_nextthink, get_gametime() + 8.0)
					set_pev(buff_ent, pev_angles, {90.0, 0.0, 0.0})
					
					zl_laser(boss | 0x3000, buff_ent, {255, 0, 0}, 80, 50)
					num++
				}
				case 3: {
					if (pev(boss, pev_sequence) == 16) {
						set_pev(boss, pev_nextthink, get_gametime() + 1.9)
						set_pev(boss, pev_victim, 0)
						set_rendering(victim)
						g_Ability = RUN
						num = 0
						victim = 0
						return
					}
					zl_anim(boss, 15, 1.0)
					set_pev(boss, pev_nextthink, get_gametime() + 2.0)
					set_rendering(victim)
					set_pev(boss, pev_victim, 0)
					victim = 0
					num++
				}
				case 4: {
					new Float:origin[3]
					pev(boss, pev_origin, origin)
					
					message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
					write_byte(TE_SPRITE)
					engfunc(EngFunc_WriteCoord, origin[0]) // x
					engfunc(EngFunc_WriteCoord, origin[1]) // y
					engfunc(EngFunc_WriteCoord, origin[2] + 50.0) // z
					write_short(i_Resource[8]) // sprite index
					write_byte(50) // scale in 0.1's
					write_byte(200) // brightness
					message_end()
										
					zl_anim(boss, 2, 1.0)
					num++
					
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
				}
				case 5..22: {
					static Float:hp_max, Float:base_regen
					static Float:hp, pre
					pev(boss, pev_max_health, hp_max)
					pev(boss, pev_health, hp)
					
					if (pre == 0) {
 						g_Damage = g_Damage * zl_fcvar[1]
						g_Damage = g_Damage / 17.0
						//base_regen = hp_max / 10.0
						
						set_pev(boss, pev_health, hp+base_regen)						
						pre = 1 
						
						/* Update information for bugfixed */
						pev(boss, pev_health, hp)
						pev(boss, pev_max_health, hp_max)
					}
					
					if (hp <= hp_max) set_pev(boss, pev_health, hp+g_Damage)

					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					
					if(num == 22) {
						new Float:procent
						procent = (g_Damage * 17.0) * 100.0 / hp_max
						//zl_colorchat(0, "!g[!yScorpion!g] !yBoss healing !g%d%%", floatround(procent))
						
						set_dhudmessage(255, 0, 0, -1.0, 0.2, 0, 1.0, 1.0);
						show_dhudmessage(0, "Агрессор активировал регенерацию !g%d%%!", floatround(procent));
						pre = 0
					}
					
					num++
				}
				case 23: {
					g_Ability = RUN
					set_pev(boss, pev_nextthink, get_gametime() + 0.1)
					num = 0
				}
			}
		}
	}
}

public Hook_Damage(boss, w, player, Float:dmg, dt) {	
	if (!zl_boss_valid( boss ))
		return HAM_IGNORED
	
	g_LiderDamage[player] += dmg
	
	if (g_Ability != REGENERATION)
		return HAM_IGNORED
	
	g_Damage += dmg
	return HAM_SUPERCEDE
}

public think_regeneration( e ) {
	static num
	switch (num) {
		case 0..80: {
			static victim
			victim = pev(g_Scorpion, pev_victim)
			set_pev(e, pev_nextthink, get_gametime() + 0.1)
			
			if (victim == 0) {
				num = 81
				return
			}
			
			if (entity_range(victim, e) < 40) {
				zl_anim(g_Scorpion, 16, 1.0)
				set_pev(g_Scorpion, pev_nextthink, get_gametime() + 0.1)
				num = 51
				return
			}	
			num++
		}
		case 81: {
			num = 0
			engfunc(EngFunc_RemoveEntity, e)
		}
	}
}

public think_hole( hole ) {
	#define TORNADO 8
	#define TORNADO_DEF	14
	#define TORNADO_OFFSET	100.0
	static num
	switch (num) {
		case 0: {
			static i, n, Float:velocity[3]
			for(i = 1; i<=g_MaxPlayer; ++i) {
				if (!is_user_alive(i))
					continue
				
				zl_move(i, hole, 900.0, velocity)
				set_pev(i, pev_velocity, velocity)
			}
			n++
			
			if(n > 30) {
				set_pev(hole, pev_effects, EF_NODRAW)
				set_pev(hole, pev_nextthink, get_gametime() + 3.0)
				n = 0
				num++
				return
			}
			set_pev(hole, pev_nextthink, get_gametime() + 0.1)
		}
		case 1: {
			new t, Float:origin[3], Float:origin_tornado[TORNADO][3]
			pev(hole, pev_origin, origin)
			
			origin_tornado[0][0] = origin[0] + TORNADO_OFFSET
			origin_tornado[0][1] = origin[1]
			
			origin_tornado[1][0] = origin[0] 
			origin_tornado[1][1] = origin[1] + TORNADO_OFFSET
			
			origin_tornado[2][0] = origin[0] + TORNADO_OFFSET
			origin_tornado[2][1] = origin[1] - TORNADO_OFFSET
			
			origin_tornado[3][0] = origin[0] - TORNADO_OFFSET
			origin_tornado[3][1] = origin[1] + TORNADO_OFFSET
			
			origin_tornado[4][0] = origin[0] + TORNADO_OFFSET
			origin_tornado[4][1] = origin[1] + TORNADO_OFFSET
			
			origin_tornado[5][0] = origin[0] - TORNADO_OFFSET
			origin_tornado[5][1] = origin[1] - TORNADO_OFFSET
			
			origin_tornado[6][0] = origin[0] - TORNADO_OFFSET
			origin_tornado[6][1] = origin[1]
			
			origin_tornado[7][0] = origin[0] 
			origin_tornado[7][1] = origin[1] - TORNADO_OFFSET			
		
			
			for (t = 0; t<TORNADO; ++t){
				origin_tornado[t][2] = origin[2]
				
				new Float:vector[3]
				xs_vec_sub(origin_tornado[t], origin, vector)
				xs_vec_normalize(vector, vector)
				xs_vec_mul_scalar(vector, 1500.0, vector)
				
				new tornado = create_entity("info_target")
				engfunc(EngFunc_SetModel, tornado, g_Resource[1])
				engfunc(EngFunc_SetOrigin, tornado, origin)
				set_pev(tornado, pev_movetype, MOVETYPE_FLY)
				set_pev(tornado, pev_solid, SOLID_NOT)
				set_pev(tornado, pev_velocity, vector)
				set_pev(tornado, pev_classname, "scorpion_tornado")
				set_pev(tornado, pev_nextthink, get_gametime() + 0.1)
				zl_anim(tornado, 0, 1.0)				
			}
			zl_sound(0, g_SoundList[20], 0)
			engfunc(EngFunc_RemoveEntity, hole)
			num = 0
		}
	}
}

public think_tornado( t ) {
	static n
	n++
	
	new i 
	for(i = 1; i<=g_MaxPlayer; ++i) {
		if(!is_user_alive(i))
			continue
		
		if (entity_range(i, t) < 260) {
			set_pev(i, pev_velocity, {0.0, 0.0, 900.0}) // Fucking nigga
		}
	}
	
	if (n > 50) {
		n = 0
		static e
		while ( (e = engfunc(EngFunc_FindEntityByString, e, "classname", "scorpion_tornado")) )
			if(pev_valid(e)) engfunc(EngFunc_RemoveEntity, e)
		return
	}
	
	set_pev(t, pev_nextthink, get_gametime() + 0.1)
}

public touch_boss(boss, player) {
	if (g_Ability == ATTACK || g_Ability == REGENERATION) return
	if (g_Ability == RUN) {	
		if (pev(boss, pev_sequence) != 4) return
		set_pev(boss, pev_victim, player)
		g_Ability = 2
		return
	}
	
	if (is_user_alive(player)) {
		ExecuteHamB(Ham_Killed, player, player, 2)
		set_rendering(player)
	}
}

public think_storm( tornado ) {	
	if (!pev_valid(tornado))
		return
		
	new i
	for(i = 1; i<=g_MaxPlayer; ++i) {
		if(!is_user_alive(i))
			continue
			
		if (entity_range(i, tornado) < 400) {
			zl_damage(i, zl_cvar[3], 0)
			set_pev(i, pev_velocity, {0.0, 0.0, 700.0})
		}
	}
	set_pev(tornado, pev_nextthink, get_gametime() + 0.1)
}

public think_tentacle( e ) {
	new i
	for(i = 1; i<=g_MaxPlayer; ++i) {
		if(!is_user_alive(i))
			continue
			
		if (entity_range(i, e) < 60) {
			zl_damage(i, zl_cvar[4], 0)
			set_pev(i, pev_velocity, {0.0, 0.0, 700.0})
		}
	}
}

public think_swing( swing ) {
	static a
	if (a <= 0) a = 255
	
	set_rendering(swing, kRenderFxNone, 0, 0, 0, kRenderTransAdd, a)
	
	a = a - 10
	
	if (a <= 0) {
		engfunc(EngFunc_RemoveEntity, swing)
		return
	}
	
	set_pev(swing, pev_nextthink, get_gametime() + 0.1)
}

public think_healthbar( e ) {
	if (!pev_valid(e))
		return
		
	if (pev(g_Scorpion, pev_deadflag) == DEAD_DYING) {
		engfunc(EngFunc_RemoveEntity, e)
		return
	}
	static Float:hp_current, Float:hp_maximum, Float:percent
	pev(g_Scorpion, pev_max_health, hp_maximum)
	pev(g_Scorpion, pev_health, hp_current)
	percent = 100 - hp_current * 100.0 / hp_maximum
	
	set_pev(e, pev_frame, percent)
	set_pev(e, pev_nextthink, get_gametime() + 0.1)
	
	if(pev(g_Scorpion, pev_sequence) != 4 && g_Ability != RUN)
		return
	
	switch(100 - floatround(percent)) {
		case 81..90: {
			if (g_Phase != 1) {
				g_Phase = 1
				g_Ability = TENTACLE2
			}
		}
		case 71..80: {
			if (g_Phase != 2) {
				g_Phase = 2
				g_Ability = DOWN0
			}
		}
		case 61..70: {
			if (g_Phase != 3) {
				g_Phase = 3
				g_Ability = TENTACLE2
			}
		}
		case 51..60: {
			if (g_Phase != 4) {
				g_Phase = 4
				g_Ability = DOWN0
			}
		}
		case 41..50: {
			if (g_Phase != 5) {
				g_Phase = 5
				g_Ability = REGENERATION
			}
		}
		case 31..40: {
			if (g_Phase != 6) {
				g_Phase = 6
				g_Ability = DOWN1
			}
		}
		case 21..30: {
			if (g_Phase != 7) {
				g_Phase = 7
				g_Ability = DOWN1
			}
		}
		case 11..20: {
			if (g_Phase != 8) {
				g_Phase = 8
				g_Ability = DOWN1
			}
		}
		case 1..10: {
			if (g_Phase != 9) {
				g_Phase = 9
				g_Ability = DOWN1
			}
		}
	}
}

public zl_timer(timer, prepare) {
	static bool:boss_spawn = false, hp
	if (prepare == 1) {
		set_pev(hp, pev_effects, pev(hp, pev_effects) & ~EF_NODRAW)
		set_pev(g_Scorpion, pev_deadflag, DEAD_NO)
		set_pev(g_Scorpion, pev_takedamage, DAMAGE_YES)
		set_pev(g_Scorpion, pev_nextthink, get_gametime() + 0.1)
		#if defined PLAYER_HP
		set_pev(g_Scorpion, pev_health, float(PlayerHp(zl_cvar[0])))
		set_pev(g_Scorpion, pev_max_health, float(PlayerHp(zl_cvar[0])))
		#else
		set_pev(g_Scorpion, pev_health, float(zl_cvar[0]))
		set_pev(g_Scorpion, pev_max_health, float(zl_cvar[0]))
		#endif
		g_Ability = 1
	}
	
	if (!boss_spawn) {
		// Boss
		engfunc(EngFunc_SetModel, g_Scorpion, g_Resource[0])
		engfunc(EngFunc_SetSize, g_Scorpion, Float:{-80.0, -80.0, -32.0}, Float:{80.0, 80.0, 96.0})
		
		
		set_pev(g_Scorpion, pev_deadflag, DEAD_RESPAWNABLE)
		set_pev(g_Scorpion, pev_takedamage, DAMAGE_NO)
		set_pev(g_Scorpion, pev_solid, SOLID_SLIDEBOX)
		set_pev(g_Scorpion, pev_movetype, MOVETYPE_TOSS)
		set_pev(g_Scorpion, pev_classname, "boss_scorpion")
		set_pev(g_Scorpion, pev_angles, {0.336914, 89.313354, 0.000000})
		set_pev(g_Scorpion, pev_euser2, 1)
		zl_anim(g_Scorpion, 1, 1.0)	
		
		// HpBar
		hp = create_entity("info_target")
		engfunc(EngFunc_SetModel, hp, g_Resource[2])
		set_pev(hp, pev_skin, g_Scorpion)
		set_pev(hp, pev_body, 1)
		set_pev(hp, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(hp, pev_classname, "scorpion_hpbar")
		set_pev(hp, pev_effects, EF_NODRAW)
		set_pev(hp, pev_scale, 0.6)
		
		set_pev(g_Scorpion, pev_nextthink, get_gametime() + 12.0)
		set_pev(hp, pev_nextthink, get_gametime() + 0.1)
		boss_spawn = !boss_spawn
	}
}

PlayerHp(hp) {
	new Count, Hp, id
	for(id = 1; id <= g_MaxPlayer; id++)
		if (is_user_alive(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	return Hp
}

public plugin_cfg() {			
	new path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/zl/zl_scorpionboss.ini", path)
    
	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	new linedata[2048], key[64], value[960], section
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
			case 1: { // GENERAL
				if (equal(key, "BOSS_HP"))
					zl_cvar[0] = str_to_num(value)
				else if (equal(key, "BOSS_SPEED"))
            				zl_cvar[1] = str_to_num(value)
				else if (equal(key, "BOSS_TIME_ABILITY"))
					zl_fcvar[0] = str_to_float(value)	
				else if (equal(key, "BOSS_DAMAGE_ATTACK"))
					zl_cvar[2] = str_to_num(value)
				else if (equal(key, "BOSS_REGEN_M"))
					zl_fcvar[1] = str_to_float(value)
				else if (equal(key, "BOSS_DAMAGE_STORM"))
					zl_cvar[3] = str_to_num(value)
				else if (equal(key, "BOSS_DAMAGE_TENTACLE"))
					zl_cvar[4] = str_to_num(value)
			}
		}
	}
	if (file) fclose(file)
}

map_load() {
	static i, szStrin[32]
	
	for (i = 0; i <= STORM; ++i) {
		format(szStrin, charsmax(szStrin), "go_%d", i + 1)
		e_storm_start[i] = engfunc(EngFunc_FindEntityByString, e_storm_start[i], "targetname", szStrin)
		
		format(szStrin, charsmax(szStrin), "go_end_%d", i + 1)
		e_storm_end[i] = engfunc(EngFunc_FindEntityByString, e_storm_end[i], "targetname", szStrin)
	}
	
	for (i = 0; i < 3; ++i) {
		format(szStrin, charsmax(szStrin), "down%d", i)
		e_down[i] = engfunc(EngFunc_FindEntityByString, e_down[i], "targetname", szStrin)
	}
	
	g_Scorpion = engfunc(EngFunc_FindEntityByString, g_Scorpion, "targetname", "boss_spawn")
	
}

public plugin_precache() {
	if (zl_boss_map() != 7)
		return
		
	static i
	for (i = 0; i < sizeof g_Resource; ++i)
		i_Resource[i] = precache_model(g_Resource[i])
		
	for (i = 0; i < sizeof g_SoundList; ++i)
		precache_sound(g_SoundList[i])
}

stock zl_laser(a, b, Color[3], timer, noise) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte( TE_BEAMENTS ) 
	write_short( a )
	write_short( b )
	write_short( i_Resource[6] )
	write_byte( 1 )		// framestart 
	write_byte( 1 )		// framerate 
	write_byte( timer )	// life in 0.1's 
	write_byte( 8 )		// width
	write_byte( noise )		// noise 
	write_byte( Color[0] )		// r, g, b 
	write_byte( Color[1] )	// r, g, b 
	write_byte( Color[2] ) 		// r, g, b 
	write_byte( 200 )	// brightness 
	write_byte( 0 )		// speed 
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
