
#include <amxmodx>
#include <amxmisc>

#define TASK_SHOWQUEST 903345

new question[131]
new answer[64]
new quest[64]
new nick_winner[32]
new g_results
new string_num
new random_quest
new bl_QuestionAvail
new g_msgSayText

public plugin_init()
{
	register_plugin("QUESTIONS", "1.0", "QUESTIONS")

	register_clcmd("say","check_results")
	g_msgSayText = get_user_msgid("SayText")
	set_new_question()
}

public plugin_precache() 
{
	precache_sound("zj/pipewarp.wav")
}

public set_new_question()
{
	remove_task(TASK_SHOWQUEST)
	set_task(10.0, "set_question")
}

public set_question()
{
	g_results = false
	new txtlen
	string_num = file_size("addons/amxmodx/configs/questions.ini", 1)
	random_quest = random_num ( 1,string_num )
	read_file("addons/amxmodx/configs/questions.ini", random_quest, question, charsmax(question), txtlen)
	while ( (question[0] == ';' || equali(question,"")) )
	{
		random_quest = random_num ( 1,string_num )
		read_file("addons/amxmodx/configs/questions.ini", random_quest, question, charsmax(question), txtlen)
	}

	trim(question)
	parse(question, quest, sizeof(quest) , answer, sizeof(answer))
	remove_task()

	if(!bl_QuestionAvail)
	{
		bl_QuestionAvail = true
	}

	set_task(1.0, "set_quessst", TASK_SHOWQUEST, _, _, "b")
}

public set_quessst()
{
	set_dhudmessage(0, 255, 0, -1.0, 0.89, 0, 6.0, 1.0, 0.2, 0.2)
	show_dhudmessage(0, "%s", quest)
	if(g_results)
	{
		set_new_question()
	}
}

public check_results(id)
{
	static chat[192];
	read_args(chat, sizeof(chat) - 1);
	remove_quotes(chat);

	if ( !g_results && bl_QuestionAvail)
	{
		if (equali(chat, answer ))
		{
			g_results = true
			client_cmd(0, "spk zj/pipewarp" )
			get_user_name(id,nick_winner,31);
			new Win_num = random_num(7000, 14000)
			client_printcolor(0, "/g[FR-JAIL] /yНа вопрос ответил /ctr%s /yи получил + /g[%d $] /y!", nick_winner, Win_num)
		}
	}
}

stock client_printcolor(const id, const input[], any:...) 
{ 
    new iCount = 1, iPlayers[32] 
     
    static szMsg[191] 
    vformat(szMsg, charsmax(szMsg), input, 3) 
     
    replace_all(szMsg, 190, "/g", "^4") 
    replace_all(szMsg, 190, "/y", "^1") 
    replace_all(szMsg, 190, "/ctr", "^3") 
    replace_all(szMsg, 190, "/w", "^0") 
     
    if(id) iPlayers[0] = id 
    else get_players(iPlayers, iCount, "ch") 
         
    for (new i = 0; i < iCount; i++) 
    { 
        if (is_user_connected(iPlayers[i])) 
        { 
            message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayers[i]) 
            write_byte(iPlayers[i]) 
            write_string(szMsg) 
            message_end() 
        } 
    }
}