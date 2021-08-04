//-----------
// RewardSystem
//
// NPC Forum
// http://zombielite.Ru/
// By Alexander.3
// http://Alexander3.Ru/
//
// Native:
// zl_give_reward(index, num)
// - index ( Player )
// - num ( Money )

#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >
#include < reapi >
#include < jbe_core >


forward jbe_load_stats(pId)
forward jbe_save_stats(pId)


#define NAME		"[ZL] RewardSystem"
#define VERSION		"1.3.1"
#define AUTHOR		"Alexander.3"

#define DMG
#define FRAG
#define KILL

#define MsgId_ScoreInfo 85

const spawn_money =  0

// DamageFunc
const dmg_max = 		5000
const dmg_reward_min =	2
const dmg_reward_max =	5

// FragDamage
const frag_dmg =	100
const frag_add =	1

// KilledFunc
const kReward =		5
const k_red =		255
const k_green =		0
const k_blue =		0

native jbe_mysql_stats_systems_get(pId, iType);
native jbe_mysql_stats_systems_add(pId, iType, iNumm);
native get_login(index);

native jbe_set_butt(pId, iNum);
native jbe_get_butt(pId);

enum _:BOSS
{
	BOSS_ALIEN,
	BOSS_OBERON,
	KILL_ALIEN,
	KILL_OBERON
};

new g_iBossStats[MAX_PLAYERS + 1][BOSS];


native zl_boss_map()
native zl_boss_valid(ent)

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)
	

	new HamHook:g_iFwdPlayerTakeDamage;
	new HamHook:g_iFwdPlayerSpawn;
	
	
	DisableHamForward( g_iFwdPlayerTakeDamage = RegisterHam(Ham_TakeDamage, "info_target", "TakeDamage_Boss"));
	DisableHamForward( g_iFwdPlayerSpawn = 		RegisterHam(Ham_Spawn, "player", "Hook_Spawn", 1));

	if(zl_boss_map())
	{
		EnableHamForward(g_iFwdPlayerTakeDamage)
		EnableHamForward(g_iFwdPlayerSpawn)
	}

}

public Hook_Spawn(id) {
	if (!is_user_connected(id))
		return HAM_IGNORED
		
	GiveMoney(id, spawn_money)
	return HAM_HANDLED
}

public TakeDamage_Boss(victim, wpn, attacker, Float:damage, damagebyte) {
	if (!pev_valid(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
		
	if (zl_boss_valid(victim)) {
		static Float:BossHealth
		pev(victim, pev_health, BossHealth)
		
		if (damage < BossHealth) {
			
			if(get_login(attacker))
			{
				switch(zl_boss_map())
				{
					case 1: g_iBossStats[attacker][BOSS_OBERON] += floatround(damage)
					case 2: g_iBossStats[attacker][BOSS_ALIEN] += floatround(damage)
				
				}
			}
			//UTIL_SayText(0, "DAMAGE %d | %d", g_iBossStats[attacker][BOSS_ALIEN], g_iBossStats[attacker][BOSS_OBERON]);
			#if defined DMG
			static Float:PlayerDamage[33]
			PlayerDamage[attacker] += damage
			#endif
			
			#if defined FRAG
			static Float:PlayerDamage2[33]
			PlayerDamage2[attacker] += damage
			#endif
			
			#if defined DMG
			if (PlayerDamage[attacker] > dmg_max) {
				new money = random_num(dmg_reward_min, dmg_reward_max)
				GiveMoney(attacker, money)
				
				PlayerDamage[attacker] = 0.0
				return HAM_HANDLED
			}
			#endif
			
			#if defined FRAG
			if (PlayerDamage2[attacker] > frag_dmg) 
			{
				set_entvar(attacker, var_frags, get_entvar(attacker, var_frags) + float(frag_add))
				
				new szDeaths = get_member(attacker, m_iDeaths);
				
				message_begin(MSG_BROADCAST, MsgId_ScoreInfo)
				write_byte(attacker)
				write_short(get_entvar(attacker, var_frags))
				write_short(szDeaths)
				write_short(0)
				write_short(jbe_get_user_team(attacker))
				message_end()
				
				PlayerDamage2[attacker] = 0.0
				return HAM_HANDLED
			}
			#endif
			
		} 
		else 
		{
			#if defined KILL
			MessageKilled(attacker)
			GiveMoney(attacker, kReward)
			#endif
			return HAM_IGNORED
		}
	}
	return HAM_HANDLED
}

public jbe_load_stats(pId)
{
	g_iBossStats[pId][BOSS_ALIEN] = 0;
	g_iBossStats[pId][BOSS_OBERON] = 0;
	g_iBossStats[pId][KILL_ALIEN] = 0;
	g_iBossStats[pId][KILL_OBERON] = 0;
	
	g_iBossStats[pId][BOSS_OBERON] = jbe_mysql_stats_systems_get(pId, 30);
	g_iBossStats[pId][BOSS_ALIEN] = jbe_mysql_stats_systems_get(pId, 31);
	g_iBossStats[pId][KILL_OBERON] = jbe_mysql_stats_systems_get(pId, 32);
	g_iBossStats[pId][KILL_ALIEN] = jbe_mysql_stats_systems_get(pId, 33);
	

}

public jbe_save_stats(pId)
{
	jbe_mysql_stats_systems_add(pId, 30, g_iBossStats[pId][BOSS_OBERON]); 
	jbe_mysql_stats_systems_add(pId, 31, g_iBossStats[pId][BOSS_ALIEN]); 
	jbe_mysql_stats_systems_add(pId, 32, g_iBossStats[pId][KILL_OBERON]); 
	jbe_mysql_stats_systems_add(pId, 33, g_iBossStats[pId][KILL_ALIEN]); 
	
	
	g_iBossStats[pId][BOSS_ALIEN] = 0;
	g_iBossStats[pId][BOSS_OBERON] = 0;
	g_iBossStats[pId][KILL_ALIEN] = 0;
	g_iBossStats[pId][KILL_OBERON] = 0;
}


MessageKilled(attacker) {

	set_dhudmessage(k_red, k_green, k_blue, 0.29, 0.49, 0, 6.0, 12.0)
	show_dhudmessage(0, "%n убилл Босса!!! За это он получил - %d бычков!", attacker, kReward)
	
	if(get_login(attacker))
	{
		switch(zl_boss_map())
		{
			case 1: g_iBossStats[attacker][KILL_OBERON]++;
			case 2: g_iBossStats[attacker][KILL_ALIEN]++;
		
		}
	}
}

public plugin_natives()
	register_native("zl_give_reward", "GiveMoney", 1)

public GiveMoney(index, num) {
	if (!is_user_connected(index))
		return
	if(zl_boss_map())
	{	
		//jbe_set_user_money(index, jbe_get_user_money(index) + num, 1);
		jbe_set_butt(index, jbe_get_butt(index) + num);
	}

}

/*public UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	client_print_color(pPlayer, 0, "%s", szBuffer);
}*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
