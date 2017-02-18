#pragma semicolon 1

#define PLUGIN_VERSION "1.10"

#include <sourcemod>
#include <discord>

#define BOT_TOKEN ""

public Plugin myinfo = 
{
	name = "Discord Test",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

DiscordBot gBot;

public void OnPluginStart() {
	RegConsoleCmd("sm_getguilds", Cmd_GetGuilds);
	RegConsoleCmd("sm_recreatebot", Cmd_RecreateBot);
	RegConsoleCmd("sm_webhooktest", Cmd_Webhook);
}

public void OnAllPluginsLoaded() {
	gBot = new DiscordBot(BOT_TOKEN);
}

public Action Cmd_Webhook(int client, int argc) {
	DiscordWebHook hook = new DiscordWebHook("");
	hook.SlackMode = true;
	
	hook.SetContent("@here");
	hook.SetUsername("Server");
	
	MessageEmbed Embed = new MessageEmbed();
	
	Embed.SetColor("#ff2222");
	Embed.SetTitle("Testing WebHook");
	Embed.AddField("Field1", "Test1", true);
	Embed.AddField("abc def", "deef", true);
	
	hook.Embed(Embed);
	
	hook.Send();
	delete hook;
	
	hook = new DiscordWebHook("");
	hook.SetUsername("Testing");
	hook.SlackMode = false;
	hook.SetContent("Testing 1 2 3");
	hook.Send();
	delete hook;
}


public Action Cmd_GetGuilds(int client, int argc) {
	gBot.GetGuilds(GuildList, GuildListAll, GetClientUserId(client));
	ReplyToCommand(client, "Trying!");
	return Plugin_Handled;
}

public Action Cmd_RecreateBot(int client, int argc) {
	if(gBot != null) {
		gBot.StopListening();
		delete gBot;
	}
	gBot = new DiscordBot(BOT_TOKEN);
	ReplyToCommand(client, "Recreated");
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data) {
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		PrintToConsole(client, "Guild [%s] [%s] [%s] [%i] [%i]", id, name, icon, owner, permissions);
		gBot.GetGuildChannels(id, ChannelList, INVALID_FUNCTION, data);
	}
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data) {
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		char name[32];
		char id[32];
		Channel.GetID(id, sizeof(id));
		Channel.GetName(name, sizeof(name));
		PrintToConsole(client, "Channel for Guild(%s) - [%s] [%s]", guild, id, name);
		
		if(Channel.IsText) {
			//Send a message with all ways
			//gBot.SendMessage(Channel, "Sending message with DiscordBot.SendMessage");
			//gBot.SendMessageToChannelID(id, "Sending message with DiscordBot.SendMessageToChannelID");
			//Channel.SendMessage(gBot, "Sending message with DiscordChannel.SendMessage");
			
			gBot.StartListeningToChannel(Channel, OnMessage);
		}
	}
}

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, const char[] message) {
	PrintToServer("Message from discord: %s", message);
	
	if(StrEqual(message, "Ping", false)) {
		gBot.SendMessage(Channel, "Pong!");
	}
}

public void GuildListAll(DiscordBot bot, ArrayList Alid, ArrayList Alname, ArrayList Alicon, ArrayList Alowner, ArrayList Alpermissions, any data) {
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		char id[32];
		char name[64];
		char icon[128];
		bool owner;
		int permissions;
		
		PrintToConsole(client, "Dumping Guilds from arraylist");
		
		for(int i = 0; i < Alid.Length; i++) {
			GetArrayString(Alid, i, id, sizeof(id));
			GetArrayString(Alname, i, name, sizeof(name));
			GetArrayString(Alicon, i, icon, sizeof(icon));
			owner = GetArrayCell(Alowner, i);
			permissions = GetArrayCell(Alpermissions, i);
			PrintToConsole(client, "Guild: [%s] [%s] [%s] [%i] [%i]", id, name, icon, owner, permissions);
		}
	}
}

public Action Cmd_SendMsg(int client, int argc) {
	//
}