#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shavit>

ConVar g_cvSpecialString;

char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bThirdPersonEnabled[MAXPLAYERS + 1];
int g_iCameraRotation[MAXPLAYERS + 1]; 
bool g_bAutoRotationEnabled[MAXPLAYERS + 1];

int g_iLastButtons[MAXPLAYERS + 1];
public Plugin myinfo = {
	name = "Shavit - Tank Controls Style",
	author = "devins", 
	description = "Tank-style thirdperson camera style for CS:S Bhop Timer",
	version = "1.0.0",
	url = "https://github.com/NSchrot/shavit-style-tankcontrols"
}

public void OnPluginStart()
{
	g_cvSpecialString = CreateConVar("ss_tankcontrols_specialstring", "tcontrols", "Special string for Tank Controls style detection");
	g_cvSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_cvSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	
	RegConsoleCmd("sm_tcright", Command_RotateCameraRight, "Rotate camera right");
	RegConsoleCmd("tcright", Command_RotateCameraRight, "Rotate camera right (bind)");
	RegConsoleCmd("sm_tcleft", Command_RotateCameraLeft, "Rotate camera left");
	RegConsoleCmd("tcleft", Command_RotateCameraLeft, "Rotate camera left (bind)");
	RegConsoleCmd("sm_toggletckeys", Command_ToggleAutoRotation, "Toggle automatic E/Shift rotation");
	RegConsoleCmd("toggletckeys", Command_ToggleAutoRotation, "Toggle automatic E/Shift rotation");

	for (int i = 1; i <= MaxClients; i++)
	{
		g_iCameraRotation[i] = 0;
		g_bThirdPersonEnabled[i] = false;
		g_bAutoRotationEnabled[i] = true;
		g_iLastButtons[i] = 0;
	}

	AutoExecConfig();
}

public void OnClientDisconnect(int client)
{
	g_bThirdPersonEnabled[client] = false;
	g_iCameraRotation[client] = 0;
	g_bAutoRotationEnabled[client] = true;
	g_iLastButtons[client] = 0;
	
	SDKUnhook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
}

// fix for fov being reset after dropping or picking up a weapon
public void OnClientPostThinkPost(int client)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return;
		
	if (GetEntProp(client, Prop_Send, "m_iFOV") != 105)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", 105);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client] || !g_bAutoRotationEnabled[client])
		return Plugin_Continue;
	
	if (buttons & IN_USE)
	{
		if (!(g_iLastButtons[client] & IN_USE))
		{
			Command_RotateCameraRight(client, 0);
		}
	}
	
	if (buttons & IN_SPEED)
	{
		if (!(g_iLastButtons[client] & IN_SPEED))
		{
			Command_RotateCameraLeft(client, 0);
		}
	}

	g_iLastButtons[client] = buttons;
	
	return Plugin_Continue;
}

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
	if (!IsValidClient(client))
		return;
	
	char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));

	bool bShouldEnable = (StrContains(sStyleSpecial, g_sSpecialString) != -1);
	
	if (bShouldEnable && !g_bThirdPersonEnabled[client])
	{
		EnableThirdPerson(client);
	}
	else if (!bShouldEnable && g_bThirdPersonEnabled[client])
	{
		DisableThirdPerson(client);
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		CreateTimer(0.5, Timer_ReEnableThirdPerson, GetClientSerial(client));
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{

	}
}

public Action Timer_ReEnableThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		SetIdealViewAngles(client);
		CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public Action Timer_SetInitialAngles(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Stop;
	
	float idealAngles[3];
	idealAngles[0] = 45.0;
	idealAngles[1] = float(g_iCameraRotation[client]);
	idealAngles[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, idealAngles, NULL_VECTOR);
	
	CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

void SetIdealViewAngles(int client)
{
	float idealAngles[3];
	idealAngles[0] = 45.0;
	idealAngles[1] = float(g_iCameraRotation[client]); 
	idealAngles[2] = 0.0;  
	
	TeleportEntity(client, NULL_VECTOR, idealAngles, NULL_VECTOR);
}

public Action Timer_ActivateThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Stop;
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iFOV", 105);
	
	return Plugin_Stop;
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}

public Action Timer_SimpleRefresh(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Stop;
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iFOV", 105);
	
	return Plugin_Stop;
}

void EnableThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	g_bThirdPersonEnabled[client] = true;
	g_iCameraRotation[client] = 0;
	
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	
	CreateTimer(0.1, Timer_SetInitialAngles, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffUse \x07A082FFShift \x07ffffff/ \x07A082FFE \x07ffffffto rotate the camera angle");
	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffOr bind a key to \x07A082FFtcleft \x07ffffff/ \x07A082FFtcright");
}

void DisableThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	g_bThirdPersonEnabled[client] = false;
	
	SDKUnhook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	
	float resetAngles[3] = {0.0, 0.0, 0.0};
	TeleportEntity(client, NULL_VECTOR, resetAngles, NULL_VECTOR);
}

public Action Command_RotateCameraRight(int client, int args)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Handled;
	
	switch(g_iCameraRotation[client])
	{
		case 0: g_iCameraRotation[client] = -90;
		case -90: g_iCameraRotation[client] = 180;
		case 180: g_iCameraRotation[client] = 90;
		case 90: g_iCameraRotation[client] = 0;
	}
	
	float angles[3];
	angles[0] = 45.0;
	angles[1] = float(g_iCameraRotation[client]);
	angles[2] = 0.0;
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	
	CreateTimer(0.1, Timer_SimpleRefresh, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Command_RotateCameraLeft(int client, int args)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Handled;

	switch(g_iCameraRotation[client])
	{
		case 0: g_iCameraRotation[client] = 90;
		case 90: g_iCameraRotation[client] = 180;
		case 180: g_iCameraRotation[client] = -90;
		case -90: g_iCameraRotation[client] = 0;
	}
	
	float angles[3];
	angles[0] = 45.0; 
	angles[1] = float(g_iCameraRotation[client]);
	angles[2] = 0.0; 
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	
	CreateTimer(0.05, Timer_SimpleRefresh, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Command_ToggleAutoRotation(int client, int args)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
	{
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffYou need to be in Tank Controls style to use this command!");
		return Plugin_Handled;
	}
	
	g_bAutoRotationEnabled[client] = !g_bAutoRotationEnabled[client];
	
	if (g_bAutoRotationEnabled[client])
	{
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffAuto rotation with \x07A082FFE \x07ffffff/ \x07A082FFShift \x07ffffffenabled");
	}
	else
	{
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffAuto rotation disabled. Use \x07A082FFtcright \x07ffffff/ \x07A082FFtcleft \x07ffffffcommands");
	}
	
	return Plugin_Handled;
}

