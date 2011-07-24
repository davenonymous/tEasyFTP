#pragma semicolon 1
#include <sourcemod>
#include <teasyftp>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled = false;

new Handle:g_hCvarFtpTarget = INVALID_HANDLE;
new String:g_sFtpTarget[255];


new String:g_sDemoPath[PLATFORM_MAX_PATH];
new bool:g_bRecording = false;

public Plugin:myinfo =
{
	name 		= "tAutoDemoUpload",
	author 		= "Thrawn",
	description = "Uploads demo files to a remote ftp server",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tautodemoupload_version", VERSION, "Uploads demo files to a remote ftp server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tautodemoupload_enable", "1", "Automatically upload demos when finished recording.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	g_hCvarFtpTarget = CreateConVar("sm_tautodemoupload_ftptarget", "demos", "The ftp target to use for uploads.", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarFtpTarget, Cvar_Changed);

	AddCommandListener(CommandListener_Record, "tv_record");
	AddCommandListener(CommandListener_StopRecord, "tv_stoprecord");
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);

	GetConVarString(g_hCvarFtpTarget, g_sFtpTarget, sizeof(g_sFtpTarget));
	if(!g_bEnabled)return;
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public OnMapStart() {
	if(GetConVarValueInt("tv_enable") != 1) {
		SetFailState("SourceTV System is disabled. You don't need this plugin.");
		return;
	}

	g_bRecording = false;
}

public Action:CommandListener_Record(client, const String:command[], argc) {
	if(g_bRecording)return;

	GetCmdArg(1, g_sDemoPath, sizeof(g_sDemoPath));

	if(!StrEqual(g_sDemoPath, "")) {
		g_bRecording = true;
	}

	// Append missing .dem
	if(strlen(g_sDemoPath) < 4 || strncmp(g_sDemoPath[strlen(g_sDemoPath)-4], ".dem", 4, false) != 0) {
		Format(g_sDemoPath, sizeof(g_sDemoPath), "%s.dem", g_sDemoPath);
	}
}

public Action:CommandListener_StopRecord(client, const String:command[], argc) {
	if(g_bRecording) {
		new Handle:hDataPack = CreateDataPack();
		CreateDataTimer(5.0, Timer_UploadDemo, hDataPack);
		WritePackString(hDataPack, g_sDemoPath);

		Format(g_sDemoPath, sizeof(g_sDemoPath), "");
	}

	g_bRecording = false;
}

public Action:Timer_UploadDemo(Handle:timer, Handle:hDataPack) {
	ResetPack(hDataPack);

	decl String:sDemoPath[PLATFORM_MAX_PATH];
	ReadPackString(hDataPack, sDemoPath, sizeof(sDemoPath));

	EasyFTP_UploadFile(g_sFtpTarget, sDemoPath, "/", onComplete);
}

public onComplete(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], iErrorCode) {
	// LogMessage("Finished uploading %s to %s (code: %i)", sLocalFile, sTarget, iErrorCode);
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && GetAdminFlag(GetUserAdmin(client), Admin_Reservation)) {
			if(iErrorCode == 0) {
				PrintToChat(client, "[SourceTV] Demo uploaded successfully");
			} else {
				PrintToChat(client, "[SourceTV] Failed uploading the demo. Check the server log files.");
			}
		}
	}
}

public GetConVarValueInt(const String:sConVar[]) {
	new Handle:hConVar = FindConVar(sConVar);
	new iResult = GetConVarInt(hConVar);
	CloseHandle(hConVar);
	return iResult;
}