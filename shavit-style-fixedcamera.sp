#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shavit>
#include <clientprefs>

// Global Variables -------------------------------------------------------

ConVar g_hMpForceCamera;
ConVar g_cvSpecialString;

char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bThirdPersonEnabled[MAXPLAYERS + 1];
bool g_bUseDiagonalCamera[MAXPLAYERS + 1];
bool g_bUseHardcodedBinds[MAXPLAYERS + 1];
bool g_bPressedHardcodedBind[MAXPLAYERS + 1];
bool g_bNightVisionIsEnabled[MAXPLAYERS + 1];
bool g_bMovementBlocked[MAXPLAYERS + 1];

int g_iCameraAngle[MAXPLAYERS + 1];
int g_iLastButtons[MAXPLAYERS + 1];
int g_iFov[MAXPLAYERS + 1];
int g_iMinFov = 80;
int g_iMaxFov = 125;

float g_fStoredAngles[MAXPLAYERS + 1][3];
float g_fCameraDelayOffset[MAXPLAYERS + 1];
float idealAngles[3];

Cookie g_cUseDiagonalCameraCookie;
Cookie g_cCameraDelayOffsetCookie;
Cookie g_cUseHardCodedBindsCookie;
Cookie g_cNvgCookie;
Cookie g_cFovCookie;

// Plugin Info -----------------------------------------------------------

public Plugin myinfo = {
	name = "Shavit - Fixed Camera Style",
	author = "devins, shinoum", 
	description = "Fixed Camera Style for CS:S Bhop Timer",
	version = "1.2.1",
	url = "https://github.com/NSchrot/shavit-style-fixedcamera"
}

// Plugin Starts ---------------------------------------------------------

public void OnPluginStart()
{
	g_hMpForceCamera = FindConVar("mp_forcecamera");
	g_cvSpecialString = CreateConVar("ss_fixedcamera_specialstring", "fixedcamera", "Special string for Fixed Camera style detection");
	g_cvSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_cvSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));

	HookEvent("player_spawn", OnPlayerSpawn);

	// Commands ---------

	// Camera Controls
	RegConsoleCmd("fcleft", Command_RotateCameraLeft, "Rotate camera left");
	RegConsoleCmd("fcright", Command_RotateCameraRight, "Rotate camera right");
	RegConsoleCmd("fc180", Command_RotateCamera180, "Rotate camera 180 degrees");
	RegConsoleCmd("fcdiagonal", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");

	// Toggle Diagonal Camera Angles
	RegConsoleCmd("sm_fcdiagonalcamera", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");
	RegConsoleCmd("sm_fcdiagonalangles", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");
	RegConsoleCmd("sm_diagonalcamera", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");
	RegConsoleCmd("sm_diagonalangles", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");
	RegConsoleCmd("sm_fcdiagonal", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");
	RegConsoleCmd("sm_diagonal", Command_ToggleDiagonalCamera, "Toggle between straight / diagonal camera angles");

	// Toggle Shift / E Keys
	RegConsoleCmd("sm_fchardcodedbinds", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_fctogglebinds", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_fctogglekeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_fchardcoded", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_hardcoded", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_fcusekeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");

	// Nightvision
	RegConsoleCmd("sm_fcnightvision", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nightvision", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_fcnvg", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nvg", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nv", Command_ToggleNightVision, "Toggle Night Vision Goggles");

	// Field of View
	RegConsoleCmd("sm_fcfieldofview", Command_ApplyFOV, "Apply User Inserted FOV");
	RegConsoleCmd("sm_fieldofview", Command_ApplyFOV, "Apply User Inserted FOV");
	RegConsoleCmd("sm_fcfov", Command_ApplyFOV, "Apply User Inserted FOV");
	RegConsoleCmd("sm_fov", Command_ApplyFOV, "Apply User Inserted FOV");

	// Main Menu
	RegConsoleCmd("sm_fcsettings", Command_MainMenu, "Open Fixed Camera settings menu");
	RegConsoleCmd("sm_fcoptions", Command_MainMenu, "Open Fixed Camera settings menu");
	RegConsoleCmd("sm_fcmenu", Command_MainMenu, "Open Fixed Camera settings menu");

	// Camera Controls Menu
	RegConsoleCmd("sm_fccameracontrols", Command_CameraControlsMenu, "Open Camera Controls menu");
	RegConsoleCmd("sm_fccamera", Command_CameraControlsMenu, "Open Camera Controls menu");

	// Camera Delay Offset Menu
	RegConsoleCmd("sm_fccameradelayoffset", Command_CameraDelayOffsetMenu, "Open Camera Delay Offset menu");
	RegConsoleCmd("sm_fccameraoffset", Command_CameraDelayOffsetMenu, "Open Camera Delay Offset menu");
	RegConsoleCmd("sm_fccameradelay", Command_CameraDelayOffsetMenu, "Open Camera Delay Offset menu");
	RegConsoleCmd("sm_fcoffset", Command_CameraDelayOffsetMenu, "Open Camera Delay Offset menu");
	RegConsoleCmd("sm_fcdelay", Command_CameraDelayOffsetMenu, "Open Camera Delay Offset menu");

	// Commands & Binds
	RegConsoleCmd("sm_fccommands", Command_Help, "Open Fixed Camera Commands & Binds menu");
	RegConsoleCmd("sm_fcbinds", Command_Help, "Open Fixed Camera Commands & Binds menu");
	RegConsoleCmd("sm_fchelp", Command_Help, "Open Fixed Camera Commands & Binds menu");

	// Initialize Cookies ---------

	g_cUseDiagonalCameraCookie = new Cookie("Toggle_Diagonal", "Diagonal Camera state", CookieAccess_Protected);
	g_cCameraDelayOffsetCookie = new Cookie("CameraDelayOffset", "Camera Delay Offset state", CookieAccess_Protected);
	g_cUseHardCodedBindsCookie = new Cookie("Toggle_HardCodedKeys", "Toggle Hardcoded Binds state", CookieAccess_Protected);
	g_cNvgCookie = new Cookie("nvg", "nvg state", CookieAccess_Protected);
	g_cFovCookie = new Cookie("fov", "fov state", CookieAccess_Protected);

	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			OnClientPutInServer(client);
			
			if (AreClientCookiesCached(client))
			    OnClientCookiesCached(client);
		}
	}

	AutoExecConfig();
}

// On Clients / Players --------------------------------------------------------------------

public void OnClientPutInServer(int client)
{
    OnClientCookiesCached(client);

    if (IsInFCStyle(client))
	{
		g_iCameraAngle[client] = 0;
		g_iLastButtons[client] = 0;
		g_bThirdPersonEnabled[client] = true;
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	char buffer[8];
	
	// Load Diagonal Camera cookie
	g_cUseDiagonalCameraCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    g_bUseDiagonalCamera[client] = false;
	    g_cUseDiagonalCameraCookie.Set(client, "0");
	}
	else
	{
	    g_bUseDiagonalCamera[client] = (StringToInt(buffer) == 1);
	}

	// Load Camera Delay Offset cookie
	g_cCameraDelayOffsetCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
		g_fCameraDelayOffset[client] = 0.0;
		g_cCameraDelayOffsetCookie.Set(client, "0.0");
	}
	else
	{
		g_fCameraDelayOffset[client] = StringToFloat(buffer);
	}
	
	// Load Use Hardcoded binds cookie
	g_cUseHardCodedBindsCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    g_bUseHardcodedBinds[client] = true;
	    g_cUseHardCodedBindsCookie.Set(client, "1");
	}
	else
	{
	    g_bUseHardcodedBinds[client] = (StringToInt(buffer) == 1);
	}

	// Load Night Vision Goggles cookie
	g_cNvgCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    g_bNightVisionIsEnabled[client] = false;
	    g_cNvgCookie.Set(client, "0");
	}
	else
	{
	    g_bNightVisionIsEnabled[client] = (StringToInt(buffer) == 1);
	}

	// Load FOV Cookie
	g_cFovCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
		g_iFov[client] = 105;
		g_cFovCookie.Set(client, "105");
	}
	else
	{
		g_iFov[client] = StringToInt(buffer);
	}
}

public void OnClientDisconnect(int client)
{
	if (g_bThirdPersonEnabled[client])
		DisableThirdPerson(client);

	g_bMovementBlocked[client] = false;
}

// This fixes a bug where the FOV would be reset when dropping or picking up a weapon
public void OnClientPostThinkPost(int client)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return;
		
	if (GetEntProp(client, Prop_Send, "m_iFOV") != g_iFov[client])
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
		CreateTimer(0.05, Timer_ReEnableThirdPerson, GetClientSerial(client));
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Continue;

	if (g_bUseHardcodedBinds[client])
	{
		if (buttons & IN_SPEED)
		{
			if (!(g_iLastButtons[client] & IN_SPEED))
			{
				g_bPressedHardcodedBind[client] = true;
				Command_RotateCameraLeft(client, 0);
			}
		}
		
		if (buttons & IN_USE)
		{
			if (!(g_iLastButtons[client] & IN_USE))
			{
				g_bPressedHardcodedBind[client] = true;
				Command_RotateCameraRight(client, 0);
			}
		}
		
		if (buttons & IN_ATTACK3) // this is not automatically bound by the game but can be used
		{
			if (!(g_iLastButtons[client] & IN_ATTACK3))
			{
				g_bPressedHardcodedBind[client] = true;
				Command_RotateCamera180(client, 0);
			}
		}
	}

	g_iLastButtons[client] = buttons;

	// Block Movement keys when switching camera angle to prevent speed loss
	if (g_bMovementBlocked[client])
    {
        if (buttons & IN_FORWARD) buttons &= ~IN_FORWARD;
        if (buttons & IN_BACK) buttons &= ~IN_BACK;
        if (buttons & IN_MOVELEFT) buttons &= ~IN_MOVELEFT;
        if (buttons & IN_MOVERIGHT) buttons &= ~IN_MOVERIGHT;

        vel[0] = 0.0;
        vel[1] = 0.0;

        return Plugin_Changed;
    }
	
	return Plugin_Continue;
}

// Style Changed ---------------------------------------------------------------------------

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
    if (!IsValidClient(client))
        return;

    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool bIsInFCStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

    if (bIsInFCStyle && !g_bThirdPersonEnabled[client])
    {
        EnableThirdPerson(client);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);
    }
    else if (!bIsInFCStyle && g_bThirdPersonEnabled[client])
    {
        DisableThirdPerson(client);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
    }
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}

// Commands ---------------------------------------------------------------------------------

public Action Command_RotateCameraLeft(int client, int args)
{
    if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	RotateCameraAngle(client, 0);
	return Plugin_Handled;
}

public Action Command_RotateCameraRight(int client, int args)
{
    if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	RotateCameraAngle(client, 1);
	return Plugin_Handled;
}

public Action Command_RotateCamera180(int client, int args)
{
    if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	RotateCameraAngle(client, 2);
	return Plugin_Handled;
}

public Action Command_ToggleDiagonalCamera(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	RotateCameraAngle(client, 3);
	SaveSettingToCookie(g_cUseDiagonalCameraCookie, client, g_bUseDiagonalCamera[client]);
	return Plugin_Handled;
}

public Action Command_ToggleHardCodedBinds(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;
	
	g_bUseHardcodedBinds[client] = !g_bUseHardcodedBinds[client];

	SaveSettingToCookie(g_cUseHardCodedBindsCookie, client, g_bUseHardcodedBinds[client]);
	
	if (g_bUseHardcodedBinds[client])
		Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffShift / E camera rotation binds: \x078efeffOn");
	else
		Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffShift / E camera rotation binds: \x07A082FFOff");
	
	return Plugin_Handled;
}

public Action Command_ToggleNightVision(int client, int args)
{
    if (!IsValidClient(client) || !IsInFCStyle(client))
        return Plugin_Handled;

	g_bNightVisionIsEnabled[client] = !g_bNightVisionIsEnabled[client];
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);

	SaveSettingToCookie(g_cNvgCookie, client, g_bNightVisionIsEnabled[client]);

    return Plugin_Handled;
}

public Action Command_ApplyFOV(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	// If no FOV value is given
	if (args < 1)
	{
		Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffCurrent FOV: \x07A082FF%i \x07ffffff(Default: 105 | Game Default: 90)", g_iFov[client]);
		Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffUsage: /fcfov \x07A082FF<value>");
		Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07A082FFChanging the FOV affects mouse sensitivity!");
		ShowFovMenu(client);
		
		return Plugin_Handled;
	}

	int iFov = GetCmdArgInt(1);
	
	if (iFov < g_iMinFov)
		iFov = g_iMinFov;
	else if (iFov > g_iMaxFov)
		iFov = g_iMaxFov;

	g_iFov[client] = iFov;

	SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);

	Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffFOV set to: \x07A082FF%i \x07ffffff(Default: 105 | Game Default: 90)", g_iFov[client]);
	Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07A082FFChanging the FOV affects mouse sensitivity!");

	return Plugin_Handled;
}

public Action Command_MainMenu(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	ShowMainMenu(client);

	return Plugin_Handled;
}

public Action Command_CameraControlsMenu(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	ShowCameraControlsMenu(client);

	return Plugin_Handled;
}

public Action Command_CameraDelayOffsetMenu(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;

	ShowCameraDelayOffsetMenu(client);

	return Plugin_Handled;
}

public Action Command_Help(int client, int args)
{
	if (!IsValidClient(client) || !IsInFCStyle(client))
		return Plugin_Handled;
	
	ShowHelpMenu(client);

	return Plugin_Handled;
}

// Timers ----------------------------------------------------------------------------------

public Action Timer_ReEnableThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		SetViewAngles(client);
		CreateTimer(0.1, Timer_RefreshCameraAngle, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);

		SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);
	}

	return Plugin_Stop;
}

public Action Timer_RefreshCameraAngle(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		SendConVarValue(client, g_hMpForceCamera, "1");
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);

		CreateTimer(0.05 + g_fCameraDelayOffset[client], Timer_RestorePlayerViewAngles, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

public Action Timer_RestorePlayerViewAngles(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		RestorePlayerViewAngles(client);

		//Shavit_PrintToChat(client, "Restored View Angles");

		CreateTimer(0.01 + g_fCameraDelayOffset[client] + 0.02, Timer_ReEnableMovementKeys, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

public Action Timer_ReEnableMovementKeys(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		g_bMovementBlocked[client] = false;
		g_bPressedHardcodedBind[client] = false;

		//Shavit_PrintToChat(client, "Re-enabled Movement Keys");
	}

	return Plugin_Stop;
}

// Functions -------------------------------------------------------------------------------

void RotateCameraAngle(int client, int mode)
{
	StorePlayerViewAngles(client);
    
    if (mode == 0) // Rotate Left
	{
		switch(g_iCameraAngle[client])
		{
			case 0: g_iCameraAngle[client] = 90;
			case 90: g_iCameraAngle[client] = 180;
			case 180: g_iCameraAngle[client] = -90;
			case -90: g_iCameraAngle[client] = 0;
		}
	}
	else if (mode == 1) // Rotate Right
	{
		switch(g_iCameraAngle[client])
		{
			case 0: g_iCameraAngle[client] = -90;
			case -90: g_iCameraAngle[client] = 180;
			case 180: g_iCameraAngle[client] = 90;
			case 90: g_iCameraAngle[client] = 0;
		}
	}
	else if (mode == 2) // Rotate 180
	{
		switch(g_iCameraAngle[client])
		{
			case 0: g_iCameraAngle[client] = 180;
			case 90: g_iCameraAngle[client] = -90;
			case 180: g_iCameraAngle[client] = 0;
			case -90: g_iCameraAngle[client] = 90;
		}
	}
	else  // (mode == 3) Toggle Diagonal Angles
	{
		g_bUseDiagonalCamera[client] = !g_bUseDiagonalCamera[client];
		g_bPressedHardcodedBind[client] = false;
	}
	
	SendConVarValue(client, g_hMpForceCamera, "0");
    g_bMovementBlocked[client] = true;
    
    SetViewAngles(client);

	// This is needed because for some reason when not using the hardcoded binds, it sometimes skips the vertical camera angle from SetViewAngles (wtf)
	// so we need a slightly higher timer for manual binds
	float iRefreshCameraDelay = 0.0;
	if (g_bPressedHardcodedBind[client])
		iRefreshCameraDelay = 0.015 + g_fCameraDelayOffset[client];
	else
		iRefreshCameraDelay = 0.025 + g_fCameraDelayOffset[client];

    CreateTimer(iRefreshCameraDelay, Timer_RefreshCameraAngle, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

void SetViewAngles(int client)
{
	// high ping fix: maybe we should set this variable as global and make it a client var as well?
	idealAngles[0] = 45.0;

	if (!g_bUseDiagonalCamera[client])
		idealAngles[1] = float(g_iCameraAngle[client]); 
	else
		idealAngles[1] = float(g_iCameraAngle[client] - 45);

	TeleportEntity(client, NULL_VECTOR, idealAngles, NULL_VECTOR);

	idealAngles[2] = 0.0;  
	
	// high ping fix: maybe we should only teleport the entity after the last Timer_RefreshCameraAngle timer?
	TeleportEntity(client, NULL_VECTOR, idealAngles, NULL_VECTOR);
}

public void StorePlayerViewAngles(int client)
{
    if(!IsValidClient(client))
        return;

    GetClientEyeAngles(client, g_fStoredAngles[client]);
}

public void RestorePlayerViewAngles(int client)
{
    if(!IsValidClient(client))
        return;

	TeleportEntity(client, NULL_VECTOR, g_fStoredAngles[client], NULL_VECTOR);
}

public void EnableThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	g_bThirdPersonEnabled[client] = true;
	g_iCameraAngle[client] = 0;

	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	CreateTimer(0.05, Timer_ReEnableThirdPerson, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffPress \x07A082FFShift \x07ffffff/ \x07A082FFE \x07ffffffto rotate the camera angle");
	Shavit_PrintToChat(client, "\x078efeffFixed Camera: \x07ffffffType \x07A082FF/fcmenu \x07fffffffor additional commands and help");
}

public void DisableThirdPerson(int client)
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

public bool IsInFCStyle(int client)
{
	int style = Shavit_GetBhopStyle(client);
    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool isInFCStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

	if (isInFCStyle)
		return true;
	else
		return false;
}

public void SaveSettingToCookie(Cookie cookie, int client, int value)
{
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", value);
	cookie.Set(client, buffer);
}

public void SaveFloatSettingToCookie(Cookie cookie, int client, float value)
{
	char buffer[8];
	Format(buffer, sizeof(buffer), "%f", value);
	cookie.Set(client, buffer);
}

// Menus ------------------------------------------------------------------------

void ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);

	menu.SetTitle("Fixed Camera\n \n");

	menu.AddItem("camControls", "Camera Controls");
	menu.AddItem("fov", "FOV\n \n");
	
	char bindStatus[32];
	Format(bindStatus, sizeof(bindStatus), "Shift / E Binds: %s", g_bUseHardcodedBinds[client] ? "On" : "Off");
	menu.AddItem("binds", bindStatus);
	
	char nvgStatus[32];
	Format(nvgStatus, sizeof(nvgStatus), "Night Vision: %s\n \n", g_bNightVisionIsEnabled[client] ? "On" : "Off");
	menu.AddItem("nvg", nvgStatus);

	menu.AddItem("help", "Commands & Binds");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));
			
			if (StrEqual(info, "camControls"))
			{
				ShowCameraControlsMenu(client);
			}
			else if (StrEqual(info, "fov"))
			{
				ShowFovMenu(client);
			}
			else if (StrEqual(info, "binds"))
			{
				g_bUseHardcodedBinds[client] = !g_bUseHardcodedBinds[client];
				SaveSettingToCookie(g_cUseHardCodedBindsCookie, client, g_bUseHardcodedBinds[client]);
				ShowMainMenu(client);
			}
			else if (StrEqual(info, "nvg"))
			{
				Command_ToggleNightVision(client, 0);
				ShowMainMenu(client);
			}
			else if (StrEqual(info, "help"))
			{
				ShowHelpMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowCameraControlsMenu(int client)
{
	Menu menu = new Menu(CameraControlsMenuHandler, MENU_ACTIONS_DEFAULT);

	menu.SetTitle("Fixed Camera | Camera Controls\n \nType /fchelp for binds\n \n");
	
	menu.AddItem("left", "Rotate Left");
	menu.AddItem("right", "Rotate Right");
	menu.AddItem("180", "Rotate 180\n \n");

	char diagonalCameraStatus[32];
	Format(diagonalCameraStatus, sizeof(diagonalCameraStatus), "Diagonal Camera: %s\n \n", g_bUseDiagonalCamera[client] ? "On" : "Off");
	menu.AddItem("diagonalCamera", diagonalCameraStatus);

	menu.AddItem("cameraDelayOffsetMenu", "Camera Delay Offset\n \n");

	menu.AddItem("mainMenu", "Back");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int CameraControlsMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));
			
			if (g_bThirdPersonEnabled[client])
			{
				if (StrEqual(info, "left"))
					Command_RotateCameraLeft(client, 0);
				else if (StrEqual(info, "right"))
					Command_RotateCameraRight(client, 0);
				else if (StrEqual(info, "180"))
					Command_RotateCamera180(client, 0);
				else if (StrEqual(info, "diagonalCamera"))
					Command_ToggleDiagonalCamera(client, 0);		

				if (StrEqual(info, "mainMenu"))
					ShowMainMenu(client);
				else if (StrEqual(info, "cameraDelayOffsetMenu"))
					ShowCameraDelayOffsetMenu(client);
				else
					ShowCameraControlsMenu(client);					
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowCameraDelayOffsetMenu(int client)
{
	Menu menu = new Menu(CameraDelayOffsetMenuHandler, MENU_ACTIONS_DEFAULT);
	
	menu.SetTitle("Fixed Camera | Camera Delay Offset\n \nWARNING: Only adjust this setting if you have high ping and is\nexperiencing issues when switching camera angles, such as:\n \n- Camera angle not applying properly when switching angles\n- Loosing speed when rotating the camera while holding a movement key\n \n \nCurrent Offset: %.2f\n \n ", g_fCameraDelayOffset[client] + 0.001);
	
	menu.AddItem("increase", "++");
	menu.AddItem("decrease", "--\n \n");

	menu.AddItem("default", "Default\n \n");

	menu.AddItem("back", "Back");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int CameraDelayOffsetMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));
			
			if (g_bThirdPersonEnabled[client])
			{
				if (StrEqual(info, "increase"))
				{
					if (g_fCameraDelayOffset[client] < 0.29)
					{
						g_fCameraDelayOffset[client] += 0.02;
						SaveFloatSettingToCookie(g_cCameraDelayOffsetCookie, client, g_fCameraDelayOffset[client]);
					}
				}
				else if (StrEqual(info, "decrease"))
				{
					if (g_fCameraDelayOffset[client] > 0.01)
					{
						g_fCameraDelayOffset[client] -= 0.02;
						SaveFloatSettingToCookie(g_cCameraDelayOffsetCookie, client, g_fCameraDelayOffset[client]);
					}
				}
				else if (StrEqual(info, "default"))
				{
					g_fCameraDelayOffset[client] = 0.0;
					SaveFloatSettingToCookie(g_cCameraDelayOffsetCookie, client, g_fCameraDelayOffset[client]);
				}

				if (StrEqual(info, "back"))
					ShowCameraControlsMenu(client);
				else
					ShowCameraDelayOffsetMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowFovMenu(int client)
{
	Menu menu = new Menu(FovMenuHandler, MENU_ACTIONS_DEFAULT);

	menu.SetTitle("Fixed Camera | FOV\n \nCurrent FOV: %d\n ", g_iFov[client]);
	
	menu.AddItem("increase", "++");
	menu.AddItem("decrease", "--\n \n");

	menu.AddItem("default", "Default");
	menu.AddItem("gameDefault", "Game Default\n \n");

	menu.AddItem("back", "Back");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FovMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));
			
			if (g_bThirdPersonEnabled[client])
			{
				if (StrEqual(info, "increase"))
				{
					if (g_iFov[client] < g_iMaxFov)
					{
						g_iFov[client] += 5;
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
						SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					}
				}
				else if (StrEqual(info, "decrease"))
				{
					if (g_iFov[client] > g_iMinFov)
					{
						g_iFov[client] -= 5;
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
						SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					}
				}
				else if (StrEqual(info, "default"))
				{
					g_iFov[client] = 105;
					SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
					SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
				}
				else if (StrEqual(info, "gameDefault"))
				{
					g_iFov[client] = 90;
					SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
					SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
				}
				
				if (StrEqual(info, "back"))
					ShowMainMenu(client);
				else
					ShowFovMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowHelpMenu(int client)
{
    Menu menu = new Menu(HelpMenuHandler, MENU_ACTIONS_DEFAULT);

    menu.SetTitle("Fixed Camera | Commands & Binds\n \nRotate Camera: Shift / E or bind a key to fcleft / fcright\nRotate Camera 180 Degrees: Bind a key to fc180\nToggle Diagonal Camera: Bind a key to fcdiagonal\n \nBind Example: bind mouse3 fc180\n \n/fcfov: Adjust FOV\n/fctogglebinds: Toggle Shift / E binds\n/fcnvg: Toggle Night Vision\n \n/fcmenu: Main Menu\n/fccamera: Camera Controls Menu\n/fcdelay: Camera Delay Offset Menu\n/fchelp: This Menu\n \n");

    menu.AddItem("mainmenu", "Main Menu");
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int HelpMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(option, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "mainmenu"))
				ShowMainMenu(client);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}
