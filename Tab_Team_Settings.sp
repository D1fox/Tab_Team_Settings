#pragma semicolon 1
#pragma newdecls required

#include <cstrike>

public Plugin myinfo = 
{
	name		= "[CS:GO] Tab Team Settings",
	version		= "1.1.0",
	description	= "Клан-тег, имя, логотип команды",
	author		= "D1fox",
}

bool bLate;
char sTeamtag[2][16];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("Плагин только для CS:GO!");

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_tab_team_reload", Cmd_Reload, ADMFLAG_ROOT, "Reload config");

	LoadConfig();

	HookEvent("player_team", Event_Team);
	HookEvent("player_spawn", Event_Team);
}

public Action Cmd_Reload(int client, int args)
{
	bLate = true;
	LoadConfig();
	return Plugin_Handled;
}

static void LoadConfig()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/tab_team_settings.ini");

	KeyValues kv = new KeyValues("TabTeamSettings");
	if(!kv.ImportFromFile(buffer))
	{
		LogError("Конфиг '%s' не найден", buffer);
		return;
	}

	buffer[0] = 0;
	bool def = view_as<bool>(kv.GetNum("Дефолт лого команды", 1));
	if(!def) kv.GetString("Лого команды контр-террористов", buffer, sizeof(buffer));
	SetConVarString(FindConVar("mp_teamlogo_1"), buffer);
	if(!def) kv.GetString("Лого команды террористов", buffer, sizeof(buffer));
	SetConVarString(FindConVar("mp_teamlogo_2"), buffer);

	kv.Rewind();
	buffer[0] = 0;
	def = view_as<bool>(kv.GetNum("Дефолт имя команды", 1));
	if(!def) kv.GetString("Название команды контр-террористов", buffer, sizeof(buffer));
	SetConVarString(FindConVar("mp_teamname_1"), buffer);
	if(!def) kv.GetString("Название команды террористов", buffer, sizeof(buffer));
	SetConVarString(FindConVar("mp_teamname_2"), buffer);

	kv.Rewind();
	def = view_as<bool>(kv.GetNum("Дефолт тег команды", 1));
	if(!def)
	{
		kv.GetString("Тег команды контр-террористов", sTeamtag[1], sizeof(sTeamtag[]));
		kv.GetString("Тег команды террористов", sTeamtag[0], sizeof(sTeamtag[]));
	}
	else sTeamtag[1][0] = sTeamtag[0][0] = 0;

	delete kv;

	if(bLate)
	{
		bLate = false;
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) SetTag(i, GetClientTeam(i));
	}
}

public void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	if(name[7] == 't' && event.GetInt("disconnect")) return;

	static int client, team;
	if((client = GetClientOfUserId(event.GetInt("userid"))))
	{
		team = name[7] == 't' ? event.GetInt("team") : GetClientTeam(client);
//		PrintToServer("%N's team: #%i (%s)", client, team, team < CS_TEAM_T ? "" : sTeamtag[team-2]); // Дебаг
		SetTag(client, team);
	}
}

stock void SetTag(int client, int team)
{
	CS_SetClientClanTag(client, team < CS_TEAM_T ? "" : sTeamtag[team-2]);
}