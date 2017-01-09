#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <csgocolors>
#include <discord>
#include <SteamWorks>

public Plugin myinfo = {
	name = "Call Admin to Discord",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

DiscordBot gBot = null;
ArrayList CallAdminChannels = null;

ConVar gHostPort;
ConVar gHostname;

//To prevent spam
int LastUsage[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegConsoleCmd("sm_calladmin", Cmd_CallAdmin);
	
	CallAdminChannels = new ArrayList();
	
	gHostname = FindConVar("hostname");
	gHostPort = FindConVar("hostport");
}

public OnAllPluginsLoaded() {
	//Create bot with a token
	gBot = new DiscordBot("<Bot Token>");
	
	//Get all guilds then channels to find any channel with the name of call-admin
	gBot.GetGuilds(GuildList);
}

public Action Cmd_CallAdmin(int client, int argc) {
	//Add minimum 60 seconds interval before calling an admin again
	if(GetTime() < LastUsage[client] + 60) {
		CReplyToCommand(client, "{red}Please wait before calling an admin again!");
		return Plugin_Continue;
	}
	
	//Format Message to send
	char message[256];
	
	char name[32];
	GetClientName(client, name, sizeof(name));
	//Replace ` with nothing as we will use `NAME` in discord message 
	ReplaceString(name, sizeof(name), "`", "");
	
	char authid[32];
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	
	char ip[64];
	GetIP(ip, sizeof(ip));
	
	char hostname[64];
	GetConVarString(gHostname, hostname, sizeof(hostname));
	
	FormatEx(message, sizeof(message), "`%s` (`%s`) has called an Admin on %s\nConnect: steam://connect/%s", name, authid, hostname, ip);
	
	//Send Message to all channels we stored
	for(int i = 0; i < CallAdminChannels.Length; i++) {
		DiscordChannel Channel = CallAdminChannels.Get(i);
		Channel.SendMessage(gBot, message);
	}
	CReplyToCommand(client, "{green}Called an Admin");
	LastUsage[client] = GetTime();
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) {
	LastUsage[client] = 0;
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data) {
	//Retrieve all channels for the guild
	PrintToServer("Guild %s", name);
	bot.GetGuildChannels(id, ChannelList);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data) {
	//Verify that the channel is a text channel
	if(Channel.IsText) {
		//Get name of channel
		char name[32];
		Channel.GetName(name, sizeof(name));
		PrintToServer("Channel name %s", name);
		
		//Compare name of channel to 'call-admin'
		if(StrEqual(name, "call-admin", false)) {
			//Store The Channel
			
			//Duplicate the Channel handle as the 'Channel' handle is closed after the forwards are called
			DiscordChannel newChannel = view_as<DiscordChannel>(CloneHandle(Channel));
			
			//Store it into array
			CallAdminChannels.Push(newChannel);
		}
	}
}

//Stores IP into buffer using SteamWorks
stock void GetIP(char[] buffer, int maxlength) {
	int ip[4];
	SteamWorks_GetPublicIP(ip);
	strcopy(buffer, maxlength, "");
			
	FormatEx(buffer, maxlength, "%d.%d.%d.%d:%d", ip[0], ip[1], ip[2], ip[3], gHostPort.IntValue);
}
