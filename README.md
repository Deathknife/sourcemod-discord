# sourcemod-discord
Discord API for Sourcemod. There's a lot more to add.

# IMPORTANT
Before you are able to send messages, you have to create a websocket connection with the bot atleast once. Simply, do this:
http://scooterx3.net/?p=6

(Or paste this into browser -> console: http://pastebin.com/3g2HbTjY )

## Features
- List all guilds
- List all Channels for guilds
- Send Messages to Channel
- Listen for messages for Channel

## API
For full list view `discord.inc` and take a look at `discord_test.sp` for examples.

### Note
> DiscordBot and DiscordChannel are both Handles. Everytime DiscordBot is passed, it's the same Handle to the Bot. This should not be closed unless you don't need that Bot anymore(closing Bots isn't very safe atm, some handles are not closed). DiscordChannel are handles to the Channel. Everytime Channel is passed(unless mentioned otherwise, i.e `OnChannelMessage`) the handle is closed after. If you need to keep the Channel Handle, Clone it. E.g `DiscordChannel newChannel = CloneHandle(Channel);`


## Installation
- Put discord.inc in your include folder
- Compile discord_api.sp and put it in your sourcemod/plugins folder
- Install smjansson and SteamWorks extension (Might need to restart server after)

Optional examples:
- Edit the .sp by replacing `<Bot Token>` with your bot token.
- Compile and place in sourcemod/plugins

Bot Token can be obtained from:

https://discordapp.com/developers/applications/me

Create a new user and turn into bot account, reveal Token and copy.

&nbsp;

> DiscordBot

Creates a Bot Instance with specified token.
```
DiscordBot Bot = new DiscordBot("<bot token>");
```
&nbsp;

> DiscordBot.GetGuilds(DiscordGuildsRetrieve, DiscordsGuildRetrievedAll, any data)

Retrieves all guilds the Bot is in. Accepts INVALID_FUNCTION for Callbacks.
```
Bot.GetGuilds(GuildList, GuildListAll, GetClientUserId(client));
```
&nbsp;
> DiscordGuildsRetrieve(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data);

Callback for every guild retrieved. This will get called invidually for every guild.
``` 
public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data) {
    int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		PrintToConsole(client, "Guild [%s] [%s] [%s] [%i] [%i]", id, name, icon, owner, permissions);
	}
}
```
&nbsp;
> DiscordGuildsRetrievedAll(DiscordBot bot, ArrayList id, ArrayList name, ArrayList icon, ArrayList owner, ArrayList permissions, any data);

Callback for guild retrieval. Called once for all the guilds. ArrayList indexes are the same for each guild. i.e `id[3]` is the same guild as `name[3]`. The ArrayLists are closed after forwards are called.

```
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
```
&nbsp;
> DiscordBot.GetGuildChannels(id, DiscordGuildChannelsRetrieve, DiscordGuildChannelsRetrieveAll, any data);

Retrieves list of channels for the guild `id`. Accepts INVALID_FUNCTION as callbacks.

```
Bot.GetGuildChannels(id, ChannelList, INVALID_FUNCTION, data);
```

&nbsp;

> DiscordGuildChannelsRetrieve(DiscordBot bot, char[] guild, DiscordChannel Channel, any data);

Callback for retrieving Channels. Called each time for every Channel. 

```
public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data) {
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		char name[32];
		char id[32];
		Channel.GetID(id, sizeof(id));
		Channel.GetName(name, sizeof(name));
		PrintToConsole(client, "Channel for Guild(%s) - [%s] [%s]", guild, id, name);
	}
}
```

&nbsp;
>DiscordBot.SendMessage(DiscordChannel, message);
DiscordBot.SendMessageToChannelID(ChannelID, message);
Channel.SendMessage(DiscordBot, message);

Sends messages to channel.
```
Bot.SendMessage(Channel, "Sending message with DiscordBot.SendMessage");
Bot.SendMessageToChannelID(id, "Sending message with DiscordBot.SendMessageToChannelID");
Channel.SendMessage(gBot, "Sending message with DiscordChannel.SendMessage");
```

&nbsp;
> DiscordBot.StartListeningToChannel(Channel, OnChannelMessage);

Starts listening to a channel for messages. Calls OnChannelMessage callback for every message.
The Channel Handle is duplicated it, so you can close the Channel Handle after calling this.

The Channel handle passed in OnChannelMessage is not closed until plugin stops listening to messages to it. You should not rely on it.

```
typeset OnChannelMessage { 
	function void(DiscordBot bot, DiscordChannel channel, const char[] message);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator, Handle hJson);
};
```

Example:
```
Bot.StartListeningToChannel(Channel, OnMessage);

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, const char[] message) {
	if(StrEqual(message, "Ping", false)) {
		Bot.SendMessage(Channel, "Pong!");
	}
}
```