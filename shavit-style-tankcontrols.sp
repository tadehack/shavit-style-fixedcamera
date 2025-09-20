#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shavit>
#include <clientprefs>

// Global Variables -------------------------------------------------------

ConVar g_cvSpecialString;

char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bThirdPersonEnabled[MAXPLAYERS + 1];
bool g_bUseHardcodedKey[MAXPLAYERS + 1];
bool g_bNightVisionIsEnabled[MAXPLAYERS + 1];

int g_iCameraRotation[MAXPLAYERS + 1];
int g_iLastButtons[MAXPLAYERS + 1];
int g_iFov[MAXPLAYERS + 1];

float g_storedAngles[MAXPLAYERS + 1][3];

Cookie g_cToggleTCKeysCookie;
Cookie g_cFovCookie;
Cookie g_cNvgCookie;

// Plugin Info -----------------------------------------------------------

public Plugin myinfo = {
	name = "Shavit - Tank Controls Style",
	author = "devins, shinoum", 
	description = "Tank-style thirdperson camera style for CS:S Bhop Timer",
	version = "1.1.3",
	url = "https://github.com/NSchrot/shavit-style-tankcontrols"
}

// Plugin Starts ---------------------------------------------------------

public void OnPluginStart()
{
	g_cvSpecialString = CreateConVar("ss_tankcontrols_specialstring", "tcontrols", "Special string for Tank Controls style detection");
	g_cvSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_cvSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));

	HookEvent("player_spawn", OnPlayerSpawn);

	// Commands ---------

	RegConsoleCmd("tcright", Command_RotateCameraRight, "Rotate camera right");
	RegConsoleCmd("tcleft", Command_RotateCameraLeft, "Rotate camera left");
	RegConsoleCmd("tcnvg", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("toggletckeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");

	// SM commands ------

	// Nightvision
	RegConsoleCmd("sm_tcnightvision", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nightvision", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_tcnvg", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nvg", Command_ToggleNightVision, "Toggle Night Vision Goggles");
	RegConsoleCmd("sm_nv", Command_ToggleNightVision, "Toggle Night Vision Goggles");

	// Toggle Shift / E Keys
	RegConsoleCmd("sm_toggletckeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_usetckeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_usehckeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");
	RegConsoleCmd("sm_tckeys", Command_ToggleHardCodedBinds, "Toggle hardcoded Shift/E camera rotation binds");

	// Field of View
	RegConsoleCmd("sm_tcfov", Command_ApplyFOV, "Apply User Inserted FOV");
	RegConsoleCmd("sm_fov", Command_ApplyFOV, "Apply User Inserted FOV");

	// Commands & Help
	RegConsoleCmd("sm_tccommands", Command_TcHelp, "Open Tank Controls commands & help menu");
	RegConsoleCmd("sm_tchelp", Command_TcHelp, "Open Tank Controls commands & help menu");

	// Main Menu
	RegConsoleCmd("sm_tcsettings", Command_TcMenu, "Open Tank Controls settings menu");
	RegConsoleCmd("sm_tcoptions", Command_TcMenu, "Open Tank Controls settings menu");
	RegConsoleCmd("sm_tcmenu", Command_TcMenu, "Open Tank Controls settings menu");

	// Cookies ---------

	g_cToggleTCKeysCookie = new Cookie("Toggle_TCKeys", "Toggle Hardcoded binds state", CookieAccess_Protected);
	g_cFovCookie = new Cookie("fov", "fov state", CookieAccess_Protected);
	g_cNvgCookie = new Cookie("nvg", "nvg state", CookieAccess_Protected);

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

// Ons -------------------------------------------------------------------------------------

public void OnClientPutInServer(int client)
{
    OnClientCookiesCached(client);

    if (IsInTCStyle(client))
	{
		g_iCameraRotation[client] = 0;
		g_iLastButtons[client] = 0;
		g_bThirdPersonEnabled[client] = true;
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	char buffer[8];
	
	// Load Use TC Hardcoded binds cookie
	g_cToggleTCKeysCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    g_bUseHardcodedKey[client] = true;
	    g_cToggleTCKeysCookie.Set(client, "0");
	}
	else
	{
	    g_bUseHardcodedKey[client] = (StringToInt(buffer) == 1);
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
}

public void OnClientDisconnect(int client)
{
	if (g_bThirdPersonEnabled[client])
		DisableThirdPerson(client);
}

// fix for fov being reset after dropping or picking up a weapon
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
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client] || !g_bUseHardcodedKey[client])
		return Plugin_Continue;

	if (buttons & IN_USE)
	{
		if (!(g_iLastButtons[client] & IN_USE))
			Command_RotateCameraRight(client, 0);
	}
	
	if (buttons & IN_SPEED)
	{
		if (!(g_iLastButtons[client] & IN_SPEED))
			Command_RotateCameraLeft(client, 0);
	}

	g_iLastButtons[client] = buttons;
	
	return Plugin_Continue;
}

// Style Changed ---------------------------------------------------------------------------

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
    if (!IsValidClient(client))
        return;

    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool bIsInTCStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

    if (bIsInTCStyle && !g_bThirdPersonEnabled[client])
    {
        EnableThirdPerson(client);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);
    }
    else if (!bIsInTCStyle && g_bThirdPersonEnabled[client])
    {
        DisableThirdPerson(client);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
    }
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}

// Timers ----------------------------------------------------------------------------------

public Action Timer_ReEnableThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonEnabled[client])
	{
		SetViewAngles(client);
		CreateTimer(0.03, Timer_RefreshCameraAngle, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public Action Timer_RefreshCameraAngle(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Stop;
	
	SetViewAngles(client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);

	RestorePlayerViewAngles(client);
	
	return Plugin_Stop;
}

// Functions -------------------------------------------------------------------------------

void SetViewAngles(int client)
{
	float idealAngles[3];
	idealAngles[0] = 45.0;
	idealAngles[1] = float(g_iCameraRotation[client]); 
	idealAngles[2] = 0.0;  
	
	TeleportEntity(client, NULL_VECTOR, idealAngles, NULL_VECTOR);
}

public void StorePlayerViewAngles(int client)
{
    if(!IsValidClient(client))
        return;

    GetClientEyeAngles(client, g_storedAngles[client]);
}

public void RestorePlayerViewAngles(int client)
{
    if(!IsValidClient(client))
        return;

    TeleportEntity(client, NULL_VECTOR, g_storedAngles[client], NULL_VECTOR);
}

void EnableThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	g_bThirdPersonEnabled[client] = true;
	g_iCameraRotation[client] = 0;

	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	CreateTimer(0.05, Timer_ReEnableThirdPerson, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffUse \x07A082FFShift \x07ffffff/ \x07A082FFE \x07ffffffto rotate the camera angle");
	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffType \x07A082FF/tchelp \x07ffffffto see additional commands");
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

void SaveSettingToCookie(Cookie cookie, int client, int value)
{
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", value);
	cookie.Set(client, buffer);
}

public bool IsInTCStyle(int client)
{
	int style = Shavit_GetBhopStyle(client);
    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool isInTCStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

	if (isInTCStyle)
		return true;
	else
		return false;
}

// Commands ----------------------------------------------------------------------------------------

public Action Command_RotateCameraRight(int client, int args)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Handled;

	StorePlayerViewAngles(client);
	
	switch(g_iCameraRotation[client])
	{
		case 0: g_iCameraRotation[client] = -90;
		case -90: g_iCameraRotation[client] = 180;
		case 180: g_iCameraRotation[client] = 90;
		case 90: g_iCameraRotation[client] = 0;
	}

	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetViewAngles(client);
	CreateTimer(0.03, Timer_RefreshCameraAngle, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action Command_RotateCameraLeft(int client, int args)
{
	if (!IsValidClient(client) || !g_bThirdPersonEnabled[client])
		return Plugin_Handled;

	StorePlayerViewAngles(client);

	switch(g_iCameraRotation[client])
	{
		case 0: g_iCameraRotation[client] = 90;
		case 90: g_iCameraRotation[client] = 180;
		case 180: g_iCameraRotation[client] = -90;
		case -90: g_iCameraRotation[client] = 0;
	}

	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetViewAngles(client);
	CreateTimer(0.03, Timer_RefreshCameraAngle, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action Command_ToggleHardCodedBinds(int client, int args)
{
	if (!IsValidClient(client) || !IsInTCStyle(client))
		return Plugin_Handled;
	
	g_bUseHardcodedKey[client] = !g_bUseHardcodedKey[client];

	SaveSettingToCookie(g_cToggleTCKeysCookie, client, g_bUseHardcodedKey[client]);
	
	if (g_bUseHardcodedKey[client])
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffShift / E camera rotation binds: \x078efeffOn");
	else
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffShift / E camera rotation binds: \x07A082FFOff");
	
	return Plugin_Handled;
}

public Action Command_ToggleNightVision(int client, int args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

    if (IsInTCStyle(client))
    {
        g_bNightVisionIsEnabled[client] = !g_bNightVisionIsEnabled[client];
        SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);

		SaveSettingToCookie(g_cNvgCookie, client, g_bNightVisionIsEnabled[client]);

        Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffNight Vision: %s",
            g_bNightVisionIsEnabled[client] ? "\x078efeffOn" : "\x07A082FFOff");
    }

    return Plugin_Handled;
}

public Action Command_ApplyFOV(int client, int args)
{
	if (!IsValidClient(client) || !IsInTCStyle(client))
		return Plugin_Handled;

	// If no FOV value is given
	if (args < 1)
	{
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffCurrent FOV: \x07A082FF%i \x07ffffff(Default: 105 | Game Default: 90)", g_iFov[client]);
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffUsage: /tcfov \x07A082FF<value>");
		Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07A082FFChanging the FOV affects mouse sensitivity!");
		ShowFovMenu(client);
		
		return Plugin_Handled;
	}

	int iMinFov = 80;
	int imaxFov = 120;
	int iFov = GetCmdArgInt(1);
	
	if (iFov < iMinFov)
		iFov = iMinFov;
	else if (iFov > imaxFov)
		iFov = imaxFov;

	g_iFov[client] = iFov;

	SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);

	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07ffffffFOV set to: \x07A082FF%i \x07ffffff(Default: 105 | Game Default: 90)", g_iFov[client]);
	Shavit_PrintToChat(client, "\x078efeffTank Controls: \x07A082FFChanging the FOV affects mouse sensitivity!");

	return Plugin_Handled;
}

public Action Command_TcMenu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!IsInTCStyle(client))
	{
		Shavit_PrintToChat(client, "\x07ffffffThis command is only available in the \x07A082FFTank Controls \x07ffffffstyle");
		return Plugin_Handled;
	}

	ShowMainMenu(client);

	return Plugin_Handled;
}

public Action Command_TcHelp(int client, int args)
{
	if (!IsValidClient(client) || !IsInTCStyle(client))
		return Plugin_Handled;
	
	ShowHelpMenu(client);

	return Plugin_Handled;
}

// Menus ------------------------------------------------------------------------

void ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Tank Controls\n \n");
	
	char bindStatus[32];
	Format(bindStatus, sizeof(bindStatus), "Shift / E Binds: %s", g_bUseHardcodedKey[client] ? "On" : "Off");
	menu.AddItem("binds", bindStatus);
	
	char nvgStatus[32];
	Format(nvgStatus, sizeof(nvgStatus), "Night Vision: %s", g_bNightVisionIsEnabled[client] ? "On" : "Off");
	menu.AddItem("nvg", nvgStatus);
	
	menu.AddItem("fov", "FOV\n \n");

	menu.AddItem("help", "Commands & Help");
	
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
			
			if (StrEqual(info, "binds"))
			{
				g_bUseHardcodedKey[client] = !g_bUseHardcodedKey[client];
				SaveSettingToCookie(g_cToggleTCKeysCookie, client, g_bUseHardcodedKey[client]);
				ShowMainMenu(client);
			}
			else if (StrEqual(info, "nvg"))
			{
				g_bNightVisionIsEnabled[client] = !g_bNightVisionIsEnabled[client];
				SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);
				SaveSettingToCookie(g_cNvgCookie, client, g_bNightVisionIsEnabled[client]);
				ShowMainMenu(client);
			}
			else if (StrEqual(info, "fov"))
			{
				ShowFovMenu(client);
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

void ShowFovMenu(int client)
{
	Menu menu = new Menu(FovMenuHandler, MENU_ACTIONS_DEFAULT);
	
	char title[64];
	Format(title, sizeof(title), "Tank Controls | FOV\n \nCurrent FOV: %d\n ", g_iFov[client]);
	menu.SetTitle(title);
	
	menu.AddItem("increase", "++");
	menu.AddItem("decrease", "--\n \n");

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
			
			if (StrEqual(info, "increase"))
			{
				if (g_iFov[client] < 120)
				{
					g_iFov[client] += 5;
					SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					
					// Apply FOV if in third person
					if (g_bThirdPersonEnabled[client])
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
				}

				ShowFovMenu(client);
			}
			else if (StrEqual(info, "decrease"))
			{
				if (g_iFov[client] > 80)
				{
					g_iFov[client] -= 5;
					SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					
					// Apply FOV if in third person
					if (g_bThirdPersonEnabled[client])
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
				}

				ShowFovMenu(client);
			}
			else if (StrEqual(info, "back"))
			{
				ShowMainMenu(client);
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
    menu.SetTitle("Tank Controls | Commands / Help\n \n");
    
    menu.AddItem("", "Camera Angle: Shift / E or bind a key to tcleft / tcright\n \n", ITEMDRAW_DISABLED);

	menu.AddItem("", "/toggletckeys: Toggle Shift / E binds", ITEMDRAW_DISABLED);
    menu.AddItem("", "/tcnvg: Toggle Night Vision", ITEMDRAW_DISABLED);
	menu.AddItem("", "/tcfov: Adjust FOV (80-120)\n \n", ITEMDRAW_DISABLED);

	menu.AddItem("", "/tcmenu: Main Menu", ITEMDRAW_DISABLED);
	menu.AddItem("", "/tchelp: This Menu\n \n", ITEMDRAW_DISABLED);

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
