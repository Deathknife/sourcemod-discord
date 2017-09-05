#pragma semicolon 1

#define PLUGIN_VERSION "1.10"

#include <sourcemod>
#include <discord>

#define BOT_TOKEN ""
#define WEBHOOK ""

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
	RegConsoleCmd("sm_sendmsg", Cmd_SendMsg);
	RegConsoleCmd("sm_sendmsgembed", Cmd_SendMsgEmbed);
	RegConsoleCmd("sm_getroles", Cmd_GetRoles);
}

public void OnAllPluginsLoaded() {
	gBot = new DiscordBot(BOT_TOKEN);
}

public Action Cmd_Webhook(int client, int argc) {
	DiscordWebHook hook = new DiscordWebHook(WEBHOOK);
	hook.SlackMode = true;

	hook.SetContent("@here");
	hook.SetUsername("Server");

	SlackEmbed Embed = new SlackEmbed();

	Embed.SetColor("#ff2222");
	Embed.SetTitle("Testing WebHook");
	Embed.AddField("Field1", "Test1", true);
	Embed.AddField("abc def", "deef", true);

	hook.Embed(Embed);

	hook.Send();
	delete hook;

	hook = new DiscordWebHook(WEBHOOK);
	hook.SlackMode = false;
	hook.SetUsername("Testing");
	hook.SetContent("Testing 1 2 3");

	MessageEmbed embed = new MessageEmbed();
	embed.SetTitle("TestEmbed");
	embed.SetUrl("http://google.com");
	embed.Color = 0x00ff00;
	embed.SetFooter("Footer text", "https://camo.githubusercontent.com/8593f18483b8bc603725d988c3fba1d728bc27d4/68747470733a2f2f646973636f72646170702e636f6d2f6173736574732f32633231616564613136646533353462613533333435353161383833623438312e706e67");
	embed.SetThumbnailUrl("https://camo.githubusercontent.com/8593f18483b8bc603725d988c3fba1d728bc27d4/68747470733a2f2f646973636f72646170702e636f6d2f6173736574732f32633231616564613136646533353462613533333435353161383833623438312e706e67");
	embed.SetImageUrl("https://www.robotcarnival.net/wp-content/uploads/2017/06/discord.png");
	embed.AddField("asd", "fgh", true);
	embed.AddField("asd", "fgh", true);
	embed.AddField("asd", "fgh", false);
	embed.AddField("asd", "fgh", false);
	hook.Embed(embed);
	hook.Send();
	delete hook;
}

public Action Cmd_GetRoles(int client, int argc) {
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command cannot be used from console.");
		return Plugin_Handled;
	}

	gBot.GetGuilds(GuildListGetRoles, _, GetClientUserId(client));
	ReplyToCommand(client, "Trying!");
	return Plugin_Handled;
}

public void GuildListGetRoles(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data) {
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		bot.GetGuildRoles(id, OnGetRoles, data);
	}
}

public void OnGetRoles(DiscordBot bot, char[] guild, RoleList roles, any data) {
	PrintToChatAll("%i a", data);
	int client = GetClientOfUserId(data);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		PrintToConsole(client, "Roles for guild %s", guild);
		for(int i = 0; i < roles.Size; i++) {
			Role role = roles.Get(i);
			char id[64];
			char name[64];
			role.GetID(id, sizeof(id));
			role.GetName(name, sizeof(name));
			PrintToConsole(client, "Role %s %s", id, name);
		}
	}
}

public Action Cmd_GetGuilds(int client, int argc) {
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command cannot be used from console.");
		return Plugin_Handled;
	}

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

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, DiscordMessage message) {
	char sMessage[2048];
	message.GetContent(sMessage, sizeof(sMessage));

	char sAuthor[128];
	message.GetAuthor().GetUsername(sAuthor, sizeof(sAuthor));

	PrintToChatAll("[DISCORD] %s: %s", sAuthor, sMessage);

	if(StrEqual(sMessage, "Ping", false)) {
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
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command cannot be used from console.");
		return Plugin_Handled;
	}

	if(argc != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sendmsg <channelid> <message>.");
		return Plugin_Handled;
	}

	char channelid[64];
	GetCmdArg(1, channelid, sizeof(channelid));

	char message[256];
	GetCmdArg(2, message, sizeof(message));

	gBot.SendMessageToChannelID(channelid, message, OnMessageSent, GetClientUserId(client));

	return Plugin_Handled;
}

public Action Cmd_SendMsgEmbed(int client, int argc) {
	if(argc != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sendmsgembed <channelid>.");
		return Plugin_Handled;
	}

	char channelid[64];
	GetCmdArg(1, channelid, sizeof(channelid));

	MessageEmbed Embed = new MessageEmbed();

	Embed.Color = 0x00ff00;
	Embed.SetTitle("Testing SendMessageEmbed");
	Embed.AddField("Field1", "Test1", true);
	Embed.AddField("abc def", "deef", true);
	Embed.AddField("Field1", "Test1", false);
	Embed.AddField("abc def", "deef", false);
	Embed.SetFooter("Footer text.");

	gBot.SendMessageEmbedToChannelID(channelid, "Message", Embed);

	return Plugin_Handled;
}

public void OnMessageSent(DiscordBot bot, char[] channel, DiscordMessage message, any data)
{
	int client = GetClientOfUserId(data);
	ReplyToCommand(client, "Message sent!");
}
