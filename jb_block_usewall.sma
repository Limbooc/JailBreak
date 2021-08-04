/* ---------------------------------------------------------------------------- */

public stock const PluginName[] = "[JB] Button lock through walls";
public stock const PluginVersion[] = "1.0.0";
public stock const PluginAuthor[] = "vk/felhalas";

/* ---------------------------------------------------------------------------- */

#include <amxmodx>
#include <hamsandwich>

/* ---------------------------------------------------------------------------- */

public plugin_init() {

	register_plugin( PluginName, PluginVersion, PluginAuthor );
	register_cvar( "jb_buttonlock_version", PluginVersion, FCVAR_SERVER | FCVAR_SPONLY );

	RegisterHam( Ham_Use, "func_button", "@CHam_UseObject_Pre", .Post = false );
}

/* ---------------------------------------------------------------------------- */

@CHam_UseObject_Pre( iEntity, pPlayer ) {

	if( iEntity <= 0 || !ExecuteHam( Ham_IsInWorld, iEntity ) || !is_user_alive( pPlayer ) )
		return HAM_IGNORED;

	new iTarget;

	get_user_aiming( pPlayer, iTarget );

	if( iTarget == iEntity )
		return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

/* ---------------------------------------------------------------------------- */