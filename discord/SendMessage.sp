public int Native_DiscordBot_SendMessageToChannel(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	char channel[32];
	static char message[2048];
	GetNativeString(2, channel, sizeof(channel));
	GetNativeString(3, message, sizeof(message));
	
	SendMessage(bot, channel, message);
}

public int Native_DiscordBot_SendMessage(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	
	DiscordChannel Channel = GetNativeCell(2);
	char channelID[32];
	Channel.GetID(channelID, sizeof(channelID));
	
	static char message[2048];
	GetNativeString(3, message, sizeof(message));
	
	SendMessage(bot, channelID, message);
}

public int Native_DiscordChannel_SendMessage(Handle plugin, int numParams) {
	DiscordChannel channel = view_as<DiscordChannel>(GetNativeCell(1));
	
	char channelID[32];
	channel.GetID(channelID, sizeof(channelID));
	
	DiscordBot bot = GetNativeCell(2);
	
	static char message[2048];
	GetNativeString(3, message, sizeof(message));
	
	SendMessage(bot, channelID, message);
}

static void SendMessage(DiscordBot bot, char[] channel, char[] message) {
	Handle hJson = json_object();
	
	json_object_set_new(hJson, "content", json_string(message));
	
	char url[64];
	FormatEx(url, sizeof(url), "channels/%s/messages", channel);
	
	Handle request = PrepareRequest(bot, url, k_EHTTPMethodPOST, hJson);
	
	SteamWorks_SendHTTPRequest(request);
}