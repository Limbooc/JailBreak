#include <amxmodx>
#include <fakemeta> // Закомментируйте или удалите, если не хотите использовать модуль fakemeta. [Для АМХХ 1.8.3 лучше оставить как есть]

#if (AMXX_VERSION_NUM < 183) || defined NO_NATIVE_COLORCHAT
    #include <colorchat>
#else
    #define DontChange print_team_default
    #define Blue print_team_blue
    #define Red print_team_red
    #define Grey print_team_grey
#endif

#define PLUGIN "Map Manager"
#define AUTHOR "Mistrick | neygomon"

#pragma semicolon 1

#define SELECT_MAPS 4            // Число карт в голосовании. Максимум 8
#define VOTE_TIME 10            // Время голосования
#define NOMINATE_MAX 4            // Максимальное число номинаций
#define NOMINATE_PLAYER_MAX 1        // Максимальное число карт для номиначии одним игроком
#define MAP_BLOCK 5             // Количество последних сыгранных карт, которые не будут предлагаться для голосования
#define HUD_RESULT_COLOR 0, 55, 255     // Цвет результатов голосования
#define MAPSMENU             // Включить или выключить say /maps (По дефолту выключен)
//#define DEBUG             // Сообщения для отладки. Файл mapmanager_debug.log
#define CSDM             // Включать на серверах с бесконечными раундами... CSDM/GG/Soccer Jam
#define MINIMAPS             // Включить поддержку второго списка карт (По дефолту выключен)
                    // [Если включаете, то создайте minimaps.ini в amxmodx/configs] [аля night mode]
#if defined MINIMAPS
    #define MINIMAPS_START 23     // Время начала подгрузки карт minimaps [аля night mode]
    #define MINIMAPS_END 8     // Время окончания подгрузки карт minimaps [аля night mode]
#endif
#if defined CSDM
    #define VERSION "0.5.7 CSDM"
#else
    #define VERSION "0.5.7 RND"
#endif

#define TASK_TIMER 978462
#define TASK_VOTEMENU 978162

enum _:BLOCKED_DATA { MAP[33], COUNT }
enum _:NOMINATE_DATA { MAP[33], PLAYER, ID }

new const FILE_BLOCKEDMAPS[] = "addons/amxmodx/data/blockedmaps.ini";

new const PREFIX[] = "^1[^4MapManager^1]";
 
new Array:g_iMapsArray, Array:g_iNominateArray;

new g_pLoadMapsType, g_pShowSelects, g_pShowResultAfterVote, g_pShowResultType;
new g_pTimeLimit, g_pExendedMax;
new g_pExendedTime, g_pRockEnable, g_pRockPercent, g_pRockDelay, g_pRockShow, g_pNextMap, g_pFriendlyFire, g_pBlockPlayers, g_pAdminVoteWeight, g_pAdminRTVWeight;

new bool:g_bBeInVote, bool:g_bVoteFinished, bool:g_bRockVote, bool:g_bHasVoted[33], bool:g_bRockVoted[33];

new g_iExtendedMax, g_iStartPlugin, g_iLoadMaps;
new g_iInMenu[SELECT_MAPS], g_iVoteItem[SELECT_MAPS + 1], g_iTotal, g_iVoteTime, g_iRockVote;
new g_iNominatedMaps[33];
#if defined MAPSMENU
    new g_iPage[33];
#endif

#if !defined CSDM
    new pcv_mp_buytime, g_buytime, pcv_mp_roundtime, Float:flt_roundtime, g_pShowHUDLastRound;
    new bool:g_buytimeRepare = false;
#endif
 
new g_msgScreenFade, fade, pcv_mp_freezetime, g_freezetime, g_timelimit;
new bool:g_freezetimeRepare = false, bool:g_timelimitRepare = false, bool:g_Work = false;

new g_szInMenuMapName[SELECT_MAPS][33], g_BlockedMaps[MAP_BLOCK][BLOCKED_DATA], g_szCurrentMap[32];

new const g_szPrefixes[][] = {"cs_", "as_", "de_"};
new const g_szSound[][] = { "",    "fvox/one",    "fvox/two",    "fvox/three" };

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
 
    g_pLoadMapsType = register_cvar("mm_loadmapstype", "1");//0 - load all maps from maps folder, 1 - load maps from file
    g_pShowSelects = register_cvar("mm_showselects", "1");//0 - disable, 1 - all, 2 - self
    g_pShowResultAfterVote = register_cvar("mm_show_result_aftervote", "1");//0 - disable, 1 - enable
    g_pShowResultType = register_cvar("mm_showresulttype", "0");//0 - menu, 1 - hud
    g_pBlockPlayers = register_cvar("mm_block_players", "1"); // 1 - yes, 0 - off
    g_pExendedTime = register_cvar("mm_extendedtime", "10"); //minutes
    g_pExendedMax = register_cvar("mm_extendedmap_max", "2"); // количество продлений
    g_pAdminVoteWeight = register_cvar("mm_adminvote_weight", "1"); // вес голоса админа при голосовании [флаг ADMIN_MENU]
    g_pAdminRTVWeight = register_cvar("mm_adminrtv_weight", "1"); // вес голоса админа в RTV [флаг ADMIN_MENU]
    #if !defined CSDM
        g_pShowHUDLastRound = register_cvar("mm_show_lastround", "1"); // показывать HUD последнего раунда или нет
    #endif
 
    g_pNextMap = register_cvar("amx_nextmap", "");
 
    g_pRockEnable = register_cvar("mm_rtv_enable", "1");//0 - disable, 1 - enable
    g_pRockPercent = register_cvar("mm_rtv_percent", "60");
    g_pRockDelay = register_cvar("mm_rtv_delay", "3");//minutes
    g_pRockShow = register_cvar("mm_rtv_show", "0");//0 - all, 1 - self

    register_concmd("amx_rtv", "Command_StartVote", ADMIN_MAP);
    register_clcmd("say ff", "Command_FriendlyFire");
#if defined MAPSMENU
    register_clcmd("say maps", "Command_MapsList");
    register_clcmd("say /maps", "Command_MapsList");
#endif
    register_clcmd("say rtv", "Command_RTV");
    register_clcmd("say /rtv", "Command_RTV");
    register_clcmd("say nextmap", "Command_Nextmap");
    register_clcmd("say timeleft", "Command_Timeleft");
    register_clcmd("say thetime", "Command_TheTime");
    register_clcmd("say currentmap", "Command_CurrentMap");
    register_clcmd("say", "Command_Say");
    register_clcmd("say_team", "Command_Say");
    #if !defined CSDM
        register_event("HLTV", "Event_RoundStart", "a", "1=0", "2=0");
    #endif
    register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
 
    register_cvar ("nmm_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
 
    register_menucmd(register_menuid("Vote_Menu"), 1023, "VoteMenu_Handler");
#if defined MAPSMENU
    register_menucmd(register_menuid("MapsList_Menu"), 1023, "MapsListMenu_Handler");
#endif
    g_iNominateArray = ArrayCreate(NOMINATE_DATA);
    g_iStartPlugin = get_systime();
 
    g_msgScreenFade = get_user_msgid ("ScreenFade");
    pcv_mp_freezetime = get_cvar_pointer ("mp_freezetime");
    #if !defined CSDM
        pcv_mp_buytime = get_cvar_pointer ("mp_buytime");
        pcv_mp_roundtime = get_cvar_pointer ("mp_roundtime");
    #endif
    g_pTimeLimit = get_cvar_pointer("mp_timelimit");
    g_pFriendlyFire = get_cvar_pointer("mp_friendlyfire");
     
    Load_BlockedMaps();
    Load_MapList();
 
    set_task(15.0, "CheckTime", .flags = "b");
 
    // set_cvar_string("mapcyclefile", FILE_MAPS);
#if defined DEBUG
    log_to_file("mapmanager_debug.log", "PLUGIN_INIT: %s", g_szCurrentMap);
#endif
}

public plugin_cfg()
{
    #if !defined CSDM
        flt_roundtime = get_pcvar_float(pcv_mp_roundtime);
    #endif
    set_cvar_float("sv_restart", 1.0);
#if defined DEBUG
    log_to_file("mapmanager_debug.log", "[plugin_cfg] g_pTimeLimit: %d", get_pcvar_num(g_pTimeLimit));
#endif
}
 
public plugin_end()
{
    if(g_freezetimeRepare)
        set_pcvar_num(pcv_mp_freezetime, g_freezetime);
    #if !defined CSDM
        if(g_buytimeRepare)
            set_pcvar_num(pcv_mp_buytime, g_buytime);
    #endif
    if(g_timelimitRepare)
        set_pcvar_num(g_pTimeLimit, g_timelimit);
#if defined DEBUG
    log_to_file("mapmanager_debug.log", "[plugin_end] g_timelimitRepare: %d | g_pTimeLimit: %d", g_timelimitRepare, get_pcvar_num(g_pTimeLimit));
#endif    
    new const TEMP_FILE[] = "addons/amxmodx/data/temp.ini";
    new iTemp = fopen(TEMP_FILE, "wt");
 
    for(new i = 0; i < MAP_BLOCK; i++)
    {
        if(g_BlockedMaps[i][COUNT])
            fprintf(iTemp, "^"%s^" ^"%d^"^n", g_BlockedMaps[i][MAP], g_BlockedMaps[i][COUNT]);
    }
 
    fprintf(iTemp, "^"%s^" ^"%d^"^n", g_szCurrentMap, MAP_BLOCK);
    fclose(iTemp);
 
    delete_file(FILE_BLOCKEDMAPS);
#if defined DEBUG
    new iRename = rename_file(TEMP_FILE, FILE_BLOCKEDMAPS, 1);
    log_to_file("mapmanager_debug.log", "PLUGIN_END: File Renamed? %d", iRename);
    log_to_file("mapmanager_debug.log", "- - - - - - - - - - - - - - -");
#else
    rename_file(TEMP_FILE, FILE_BLOCKEDMAPS, 1);
#endif
}

public client_disconnect(id)
{
    if(task_exists(id + TASK_VOTEMENU)) remove_task(id + TASK_VOTEMENU);
    if(g_bRockVoted[id])
    {
        g_bRockVoted[id] = false;
        if(get_user_flags(id) & ADMIN_MENU && get_pcvar_num(g_pAdminRTVWeight) != 0)
            g_iRockVote -= get_pcvar_num(g_pAdminRTVWeight);
        else
            g_iRockVote--;
    }
    if(g_iNominatedMaps[id])
        clear_nominated_maps(id);
}

//***** Commands *****//
public Command_StartVote(id, flag)
{
    if(~get_user_flags(id) & flag) return PLUGIN_HANDLED;
 
    if(g_Work)
    {
        if(id == 0)
            console_print(0, "[MapManager] VoteMap has already started");
        else
            console_print(id, "[MapManager] Голосование уже запущено! Ожидайте.");
    }
    else
    {
        if(id == 0)
            console_print(0, "[MapManager] VoteMap started");
        else
            console_print(id, "[MapManager] Голосование за досрочную смену карты запущено");
        #if !defined CSDM
            g_Work = true;
        #else
            StartVote(0);
        #endif
        client_print_color(0, DontChange, "%s^1 ^4Администратор ^1запустил ^3досрочное ^1голосование.", PREFIX);
     
        new name[32];
        get_user_name(id, name, charsmax(name));
        log_amx("Администратор %s запустил досрочное голосование", name);
        #if !defined CSDM
            if(get_pcvar_num(g_pShowHUDLastRound))
                hud_lastround();
        #endif
    }    
 

    return PLUGIN_HANDLED;
}

public Command_FriendlyFire(id)
    client_print_color(0, DontChange, "%s^1 На сервере^3 %s^1 огонь по своим.", PREFIX, get_pcvar_num(g_pFriendlyFire) ? "разрешён" : "запрещён");
 
public Command_TheTime(id)
{
    new time[64];
    get_time ("%d.%m.%Y - %H:%M:%S", time, sizeof (time) - 1);
    client_print_color(id, DontChange, "%s^1 Текущее время: ^3 %s^1", PREFIX, time);
}

#if defined MAPSMENU
public Command_MapsList(id)
    Show_MapsListMenu(id, g_iPage[id] = 0);
 
public Show_MapsListMenu(id, iPage)
{
#if defined _fakemeta_included
    set_pdata_int( id, 205, 0 );
#endif
    if(iPage < 0) return PLUGIN_HANDLED;
 
    new iMax = ArraySize(g_iMapsArray);
    new i = min(iPage * 8, iMax);
    new iStart = i - (i % 8);
    new iEnd = min(iStart + 8, iMax);
 
    iPage = iStart / 8;
    g_iPage[id] = iPage;
 
    new szMenu[512], iLen = 0, iLen_Max = charsmax(szMenu), szMapName[32];
 
    iLen = formatex(szMenu, iLen_Max, "\yСписок карт \w[%d/%d]:^n", iPage + 1, ((iMax - 1) / 8) + 1);
 
    new Keys, Item, iBlock, iNominator;
 
    for (i = iStart; i < iEnd; i++)
    {
        ArrayGetString(g_iMapsArray, i, szMapName, charsmax(szMapName));
        iBlock = get_blocked_map_count(szMapName);
        iNominator = is_map_nominated(szMapName);
        if(iBlock)
            iLen += formatex(szMenu[iLen], iLen_Max - iLen, "^n\r%d.\d %s[\r%d\d]", ++Item, szMapName, iBlock);
        else if(iNominator)
        {
            if(iNominator == id)
            {
                Keys |= (1 << Item);
                iLen += formatex(szMenu[iLen], iLen_Max - iLen, "^n\r%d.\w %s[\y*\w]", ++Item, szMapName);
             
            }
            else
                iLen += formatex(szMenu[iLen], iLen_Max - iLen, "^n\r%d.\d %s[\y*\d]", ++Item, szMapName);
        }
        else
        {
            Keys |= (1 << Item);
            iLen += formatex(szMenu[iLen], iLen_Max - iLen, "^n\r%d.\w %s", ++Item, szMapName);
        }
    }
    while(Item <= 8)
    {
        Item++;
        iLen += formatex(szMenu[iLen], iLen_Max - iLen, "^n");
    }
    if (iEnd < iMax)
    {
        Keys |= (1 << 8)|(1 << 9);    
        formatex(szMenu[iLen], iLen_Max - iLen, "^n\r9.\w %Вперед^n\r0.\w %s", iPage ? "Назад" : "Выход");
    }
    else
    {
        Keys |= (1 << 9);
        formatex(szMenu[iLen], iLen_Max - iLen, "^n^n\r0.\w %s", iPage ? "Назад" : "Выход");
    }
    show_menu(id, Keys, szMenu, -1, "MapsList_Menu");
    return PLUGIN_HANDLED;
}

public MapsListMenu_Handler(id, key)
{
    switch (key)
    {
        case 8: Show_MapsListMenu(id, ++g_iPage[id]);
        case 9: Show_MapsListMenu(id, --g_iPage[id]);
        default:
        {        
            new szMapName[33]; ArrayGetString(g_iMapsArray, key + g_iPage[id] * 8, szMapName, charsmax(szMapName));
            if(g_iNominatedMaps[id] && is_map_nominated(szMapName))
                remove_nominated_map(id, szMapName);
            else
                NominateMap(id, szMapName);
        }
    }
    return PLUGIN_HANDLED;
}
#endif

public Command_RTV(id)
{
    if(g_bVoteFinished || g_bBeInVote) return PLUGIN_HANDLED;
 
    if(!get_pcvar_num(g_pRockEnable)) return PLUGIN_CONTINUE;
 
    if(get_systime() - g_iStartPlugin < get_pcvar_num(g_pRockDelay) * 60)
    {
        new iMin = 1 + (get_pcvar_num(g_pRockDelay) * 60 - (get_systime() - g_iStartPlugin)) / 60;
        new szMin[16]; get_ending(iMin, "минут", "минута", "минуты", szMin, charsmax(szMin));
             
        client_print_color(id, DontChange, "%s^1 Вы не можете голосовать ^3за досрочную смену ^4карты^1. Осталось: ^4%d ^1%s.", PREFIX, iMin, szMin);
        return PLUGIN_HANDLED;
    }
 
    if(!g_bRockVoted[id])
    {
        g_bRockVoted[id] = true;
        if(get_user_flags(id) & ADMIN_MENU && get_pcvar_num(g_pAdminRTVWeight) != 0)
            g_iRockVote += get_pcvar_num(g_pAdminRTVWeight);
        else
            g_iRockVote++;
     
        new iVote = floatround(get_players_num() * get_pcvar_num(g_pRockPercent) / 100.0, floatround_ceil) - g_iRockVote;
     
        if(iVote > 0)
        {
            new szVote[16];    get_ending(iVote, "голосов", "голос", "голоса", szVote, charsmax(szVote));
         
            switch(get_pcvar_num(g_pRockShow))
            {
                case 0:
                {
                    new szName[33];
                    get_user_name(id, szName, charsmax(szName));
                    client_print_color(0, DontChange, "%s^3 %s^1 проголосовал ^3за смену ^4карты^1. Осталось: ^4%d ^1%s.", PREFIX, szName, iVote, szVote);
#if defined DEBUG
                    log_to_file("mapmanager_debug.log", "%s проголосовал за смену карты. Осталось: %d %s.", szName, iVote, szVote);
#else
                    log_amx("%s проголосовал за смену карты. Осталось: %d %s.", szName, iVote, szVote);
#endif                
                }
                case 1: client_print_color(id, DontChange, "%s^1 Ваш голос ^3учтён^1. Осталось:^4 %d ^1%s.", PREFIX, iVote, szVote);
            }
        }
        else
        {
            #if !defined CSDM
            g_bRockVote = true;
            g_Work = true;
            client_print_color(0, DontChange, "%s^1 Голосование за смену карты будет в новом раунде.", PREFIX);
#if defined DEBUG
            log_to_file("mapmanager_debug.log", "Голосование за смену карты будет в новом раунде.");
#endif
            #else
            StartVote(0);
            #endif
             
        }
    }
    else
    {
        new iVote = floatround(get_players_num() * get_pcvar_num(g_pRockPercent) / 100.0, floatround_ceil) - g_iRockVote;
        new szVote[16];    get_ending(iVote, "голосов", "голос", "голоса", szVote, charsmax(szVote));
        client_print_color(id, DontChange, "%s^1 Вы уже ^3голосовали^1. Осталось: ^4%d ^1%s.", PREFIX, iVote, szVote);
    }
 
    return PLUGIN_HANDLED;
}

public Command_Nextmap(id)
{
    new szMap[33]; get_pcvar_string(g_pNextMap, szMap, charsmax(szMap));
    client_print_color(0, Blue, "%s^1 Следующая карта: ^3%s^1.", PREFIX, szMap);
}[/CODE