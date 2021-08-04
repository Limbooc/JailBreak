#include <amxmodx>
#include <reapi>

#pragma semicolon 1

#define bit_set(%0,%1) (%1 |= (1<<%0))
#define bit_clear(%0,%1) (%1 &= ~(1<<%0))
#define bit_valid(%0,%1) (%1 & (1<<%0))

const VALID_PROTOCOL = 48;
new g_i48pBitsum;

public plugin_init() {
    register_plugin("query_client_cvar test", "0.1", "Subb98");
    register_clcmd("say /check", "CmdCheck");
}

public client_authorized(id) {
    bit_clear(id, g_i48pBitsum);
    if(REU_GetProtocol(id) == VALID_PROTOCOL) {
        log_amx("protocol = %d", VALID_PROTOCOL);
        bit_set(id, g_i48pBitsum);
    }
}

public CmdCheck(const id) {
    if(bit_valid(id, g_i48pBitsum)) {
        query_client_cvar(id, "ex_interp", "CvarResult");
        log_amx("start check: userid = #%d, cvar = ^"ex_interp^"", get_user_userid(id));
    }
}

public CvarResult(const id, const cvar[], const value[]) {
    log_amx("finish check: userid = #%d, cvar = ^"%s^", value = ^"%s^"", get_user_userid(id), cvar, value);
} 