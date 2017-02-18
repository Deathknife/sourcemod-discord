#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <csgocolors>
#include <discord>

public Plugin myinfo = {
	name = "Announcements from Discord",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

DiscordBot gBot = null;

public void OnPluginStart() {
	//
}

public OnAllPluginsLoaded() {
	//Create bot with a token
	gBot = new DiscordBot("<Bot Token>");
	
	//Check for messages every 5 seconds. Default is 1 second. Since this is announcement, time accuracy is not necessary
	gBot.MessageCheckInterval = 5.0;
	
	//Get all guilds then channels to find any channel with the name of server-announcement
	gBot.GetGuilds(GuildList);
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data) {
	//Retrieve all channels for the guild
	bot.GetGuildChannels(id, ChannelList);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data) {
	//Verify that the channel is a text channel
	if(Channel.IsText) {
		//Get name of channel
		char name[32];
		Channel.GetName(name, sizeof(name));
		
		//Compare name of channel to 'server-announcement'
		if(StrEqual(name, "server-announcement", false)) {
			//Start listening to channel
			bot.StartListeningToChannel(Channel, OnMessage);
		}
	}
}

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, const char[] message) {
	//Received a message, print it out.
	CPrintToChatAll("{green}[Announcement]{normal} %s", message);
}