#include "CAP.inc"

const CLIENT_MAX = 33;			//32 + Console
const PLAYER_CLASS_MAX = 9;		//Scout, Soldier, Pyro, etc..
const STEAMID_MAX = 30;

new CLIENT_LAST = CLIENT_MAX;

static bool:isEnabled_class[PLAYER_CLASS_MAX];
static bool:player_class[CLIENT_MAX][PLAYER_CLASS_MAX];
static player_Statis[CLIENT_MAX];							//0:Not Ready, 1:Ready, 2:Captain, 3:Picked

//0 - BLU, 1 - RED
static captains[2];
static String:captains_SteamID[2][STEAMID_MAX];
static captains_turn;

static playerspicked_count;
const PLAYERS_ON_TEAM_MAX = 6;//Change to a static? Possibly for Highlander, or ultiduo. --WS
/*--------------------------------------------------------------------------------
/ Getters
/-------------------------------------------------------------------------------*/
PLAYERS_GetCaptainClient(id)
{
	return captains[id];
}

String:PLAYERS_GetCaptainSteamID(id)
{
	return captains_SteamID[id];
}

bool:PLAYERS_isHumanNotCap(client)
{
	return client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (player_Statis[client] < 2);	//DEBUG if(IsClientInGame(client))
}

bool:PLAYERS_isClass(client, class)
{
	return player_class[client][class];
}

bool:PLAYER_isClassEnabled(class)
{
	return isEnabled_class[class];
}

PLAYERS_GetClassStrings(String:playerstrings_out[PLAYER_CLASS_MAX][MENUITEM_NAME_MAXLEN])
{
	static String:PlayerStrings[PLAYER_CLASS_MAX][MENUITEM_NAME_MAXLEN] = {"Scout", "Soldier", "Pyro", "Demo", "Heavy", "Engineer", "Medic", "Sniper", "Spy"};
	
	for(new i = 0; i < PLAYER_CLASS_MAX; i++){
		playerstrings_out[i] = PlayerStrings[i];
	}
}
/*--------------------------------------------------------------------------------
/ Setters
/-------------------------------------------------------------------------------*/
PLAYERS_Reset()
{
	captains[0] = 0;
	captains[1] = 0;
	captains_SteamID[0] = "";
	captains_SteamID[1] = "";
	captains_turn = 0;
	
	playerspicked_count = 0;
	
	//TODO Get Cvar of enabled classes, then set them
}

PLAYERS_SetCaptainClient(cap_id, client)
{
	player_Statis[client] = 2;
	captains[cap_id] = client;
	
	if(cap_id == 0)
		ChangeClientTeam(client, 3);
	else
		ChangeClientTeam(client, 2);
}

PLAYERS_SetCaptainSteamID(id, const String:steamid[])
{
	strcopy(captains_SteamID[id], STEAMID_MAX, steamid);
}

PLAYERS_ToggleClass(client, class)
{
	if(player_class[client][class])
		player_class[client][class] = false;
	else
		player_class[client][class] = true;
}

/*--------------------------------------------------------------------------------
/ Utilities
/-------------------------------------------------------------------------------*/
//Test for client 0
PLAYERS_GetClientEnd()
{
	for(new i = MaxClients; i > 0;i--){
		if(IsClientInGame(i) && !IsFakeClient(i)){
			CLIENT_LAST = i;
			return;
		}
	}
}

PLAYERS_GetClass(client)
{
	PLAYERS_ClearPlayer(client);
	LoadChooseClassMenu(client);
}

//TODO: Make more efficient, add static list of players and remove one each time a class is picked
PLAYERS_ClassPicked(client)
{
	player_Statis[client] = 1;
	
	new players_choosing_count = 0;
	new String:players_choosing[CLIENT_MAX][PLAYER_NAME_MAXLEN];
	
	for(new i = 1; i <= CLIENT_LAST ;i++){
		if(PLAYERS_isHumanNotCap(i) && player_Statis[i] == 0)
			GetClientName(i, players_choosing[players_choosing_count++], PLAYER_NAME_MAXLEN);
	}
	
	if(players_choosing_count != 0){
		new String:players_choosing_string[CLIENT_MAX*PLAYER_NAME_MAXLEN];
		ImplodeStrings(players_choosing, players_choosing_count, ", ", players_choosing_string, CLIENT_MAX*PLAYER_NAME_MAXLEN);
		PrintHintTextToAll("Waiting for Players: \n %s", players_choosing_string);
	}
	else
		CaptainMode();
}

bool:PLAYERS_CaptainPicksPlayer(captain_id,player_client)
{
	if(captain_id != captains_turn)
		return false;
	
	player_Statis[player_client] = 3;
	
	if(captain_id == 0){
		ChangeClientTeam(player_client, 3);
		captains_turn = 1;
		LoadCaptainPickMenu(captains[captains_turn]);
	}
	else{
		ChangeClientTeam(player_client, 2);
		captains_turn = 0;
		
		playerspicked_count++;
		if(playerspicked_count >= (PLAYERS_ON_TEAM_MAX - 1))
			StopPlugin("Teams Full");
		else
			LoadCaptainPickMenu(captains[captains_turn]);
	}

	return true;
}

PLAYERS_ClearPlayer(client)
{
	for(new i = 0; i < PLAYER_CLASS_MAX; i++){
		player_class[client][i] = false;
	}
	player_Statis[client] = 0;
}
/*--------------------------------------------------------------------------------
/ Private Helper Functions
/-------------------------------------------------------------------------------*/
