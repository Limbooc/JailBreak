
	//Версия плагина: исключительно 1.9.0
#include amxmodx
#include fakemeta
#include amxmisc
#tryinclude jbe_core_func

#if defined __JBE_CORE_FUNC
#include jbe_chief_game
#else 
native jbe_get_chief_id();
#define UTIL_UserPrint(%1,%2) client_print_color(%1,%1,%2)
#endif


/* -> Бит сумм -> */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define InvertBit(%0,%1) ((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))

forward jbe_remove_user_chief_fwd(pId, iStatus);
native  jbe_open_main_menu(pId, iMenu)
new g_iUserAnswer;
new szMessage[128], iLen;
new iCount;
#define TaskId_EndGame 515372153
#define TASK_SHOW 		457456785678
new g_iSyncMainInformer;
new g_iCurrentWord;
new const g_szWordList[][] = {
	"Звезда", "Корреспондент", "Движение", "Фирма", "Рубеж", "Администрация", "Правительство", "Помощник", "Решение", "Ограничение", "Пропасть", "Середина", "Смех", "Цвет", "Вид", "Мальчишка", "Линия",
	"Вагон", "Храм", "Чувство", "Локатор", "Фольга", "Поролон", "Приемник", "Пальма", "Шприц", "Букашка", "Борода", "Пружина", "Завтрак", "Киоск", "Воробей", "Двигатель", "Прогресс", "Персик", "Флаг",
	"Дрожжи", "Кондуктор", "Мышка", "Крепость", "Волан", "Пиявка", "Вихрь", "Ласты", "Стрелка", "Банк", "Антрекот", "Наушники", "Самокат", "Водопад", "Ярмарка", "Сушка", "Студия", "Прививка", "Заря",
	"Карась", "Степь", "Яйцо", "Майка", "Водогрязеторфопарафинолечение", "Превысокомногорассмотрительствующий"
};

#if defined __JBE_CORE_FUNC
new g_iGameId;
public jbe_load_cvars() { g_iGameId = JBE_ChiefGameRegister("JBE_CHIEF_GAME:QUESTION"); }
#endif
public plugin_init() {
	register_plugin( "[UJBL_CG] Question", "vk/krisiso", "g3cKpunTop" );
	register_clcmd("say", "ClientCommand_Say");
	state dHookSay: Disabled;
	register_menucmd(register_menuid("ShowMenu_Question"), (1<<0|1<<1|1<<8|1<<9), "HandleMenu_Question");
	
	#if !defined __JBE_CORE_FUNC
	register_clcmd("say /chiefquestion", "gameopen");
	register_clcmd("chiefquestion", "gameopen");
	#endif
	
	g_iSyncMainInformer = CreateHudSyncObj();
}

#if defined __JBE_CORE_FUNC
public JBE_FWD_StartChiefGame(iKey, pId) {
	if(iKey == g_iGameId) {
		ShowMenu_Question(pId);
	}
}
#endif

public ClientCommand_Say(pId) <> { return PLUGIN_CONTINUE; }
public ClientCommand_Say(pId) <dHookSay: Disabled> { return PLUGIN_CONTINUE; }
public ClientCommand_Say(pId) <dHookSay: Enabled> { 
	new szArgs[64];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	if(equal(szArgs, g_szWordList[g_iCurrentWord]) && IsNotSetBit(g_iUserAnswer, pId)) 
	{
		if(iCount < 5)
		{
			
			iCount++;
			iLen += formatex(szMessage[ iLen ], charsmax(szMessage) - iLen, "^n%d. %n", iCount, pId);
			SetBit(g_iUserAnswer, pId);
		}
		else
		{
			@TK_EndGame();
			remove_task(TaskId_EndGame);
			remove_task(TASK_SHOW);
			g_iUserAnswer = 0;
			
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public gameopen(pId) 
{
	if(jbe_get_chief_id() != pId) 
		return 1;
	
	return ShowMenu_Question(pId);
}

#if defined __JBE_CORE_FUNC
ShowMenu_Question(pId) {
#else 
ShowMenu_Question(pId) {
	if(jbe_get_chief_id() != pId) return 1;
#endif
	#if defined __JBE_CORE_FUNC
	new szMenu[512], bitKeys = (1<<0|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "%L %L^n^n", LANG_PLAYER, "JBE_MENU_PREFIX", LANG_PLAYER, "JBE_CHIEF_GAME:QUESTION");
	#else 
	new szMenu[512], bitKeys = (1<<0|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "Меню 'Кто первый напишет?'^n^n");	
	#endif
	
	if(task_exists(TaskId_EndGame)) {
		bitKeys |= (1<<1);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \wСменить слово \r->^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2. \wЗавершить игру^n");
		#if defined __JBE_CORE_FUNC
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%L Слово: \y%s^n", pId, "JBE_KEY_LOCK", g_szWordList[g_iCurrentWord]);		
		#else 
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2 \dСлово: \y%s^n", g_szWordList[g_iCurrentWord]);
		#endif
	} 
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \wСгенерировать слово \r->^n");
	
	iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n^n\y9. \w%L", pId, "JBE_MENU_BACK");
	iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\y0. \w%L", pId, "JBE_MENU_EXIT");
	return show_menu(pId, bitKeys, szMenu, -1, "ShowMenu_Question"); 
} 

public HandleMenu_Question(pId, iKey) {
	switch(iKey) {
		case 0: {
			g_iCurrentWord = random(sizeof g_szWordList - 1);		
			if(!task_exists(TaskId_EndGame)) {
				set_task(30.0, "@TK_EndGame", TaskId_EndGame);
				UTIL_UserPrint(0, "Начальник ^4%n ^1сгенерировал слово: ^3%s", pId, g_szWordList[g_iCurrentWord]);
				
				iCount = 0;
				formatex(szMessage, charsmax(szMessage), "");
				iLen = 0;
				
				g_iUserAnswer = 0;
				iLen = formatex(szMessage[ iLen ], charsmax(szMessage) - iLen, "Слово^n%s^n", g_szWordList[g_iCurrentWord]);
				set_task_ex(1.0, "show_hud", TASK_SHOW, .flags = SetTask_Repeat);
				
				
			} else { 
				formatex(szMessage, charsmax(szMessage), "");
				iLen = 0;
				iLen = formatex(szMessage[ iLen ], charsmax(szMessage) - iLen, "Слово^n%s^n", g_szWordList[g_iCurrentWord]);
				change_task(TaskId_EndGame, 30.0);
				UTIL_UserPrint(0, "Начальник ^4%n ^1сменил слово: ^3%s", pId, g_szWordList[g_iCurrentWord]);
			}
			
			state dHookSay: Enabled;
			
			iCount = 0;

			g_iUserAnswer = 0;
		}
		case 1: {
			@TK_EndGame();
			remove_task(TaskId_EndGame);
			remove_task(TASK_SHOW);
			g_iUserAnswer = 0;
		}
		case 8: return jbe_open_main_menu(pId, 2);
		case 9: return PLUGIN_HANDLED;
	}
	return ShowMenu_Question(pId);
}

@TK_EndGame() {
	state dHookSay: Disabled; g_iCurrentWord = 0;
	if(task_exists(TASK_SHOW)) remove_task(TASK_SHOW);
	}


public jbe_remove_user_chief_fwd(pId, iStatus)
{
	if(task_exists(TaskId_EndGame))
	{
		@TK_EndGame();
		remove_task(TaskId_EndGame);
		remove_task(TASK_SHOW);
	}
}

public show_hud(pId)
{
	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 5.0, 5.0);
	ShowSyncHudMsg(0, g_iSyncMainInformer, "%s", szMessage);
}
