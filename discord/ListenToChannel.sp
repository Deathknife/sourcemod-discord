public int Native_DiscordBot_StartTimer(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	DiscordChannel channel = GetNativeCell(2);
	
	GetMessages(bot, channel);
}

public void GetMessages(DiscordBot bot, DiscordChannel channel) {
	char channelID[32];
	channel.GetID(channelID, sizeof(channelID));
	
	char lastMessage[64];
	channel.GetLastMessageID(lastMessage, sizeof(lastMessage));
	
	char url[256];
	FormatEx(url, sizeof(url), "channels/%s/messages?limit=%i&after=%s", channelID, 100, lastMessage);
	
	Handle request = PrepareRequest(bot, url, _, null, OnGetMessage);
	
	DataPack dp = new DataPack();
	WritePackCell(dp, bot);
	WritePackCell(dp, channel);
	
	char route[128];
	FormatEx(route, sizeof(route), "channels/%s", channelID);
	
	SteamWorks_SetHTTPRequestContextValue(request, dp, UrlToDP(route));
	
	DiscordSendRequest(request, route);
}

public Action CheckMessageTimer(Handle timer, any dpt) {
	DataPack dp = view_as<DataPack>(dpt);
	ResetPack(dp);
	DiscordBot Bot = ReadPackCell(dp);
	DiscordChannel Channel = ReadPackCell(dp);
	delete dp;
	
	GetMessages(Bot, Channel);
}

public int OnGetMessage(Handle request, bool failure, int offset, int statuscode, any dp) {
	if(failure || statuscode != 200) {
		LogError("[DISCORD] Couldn't Retrieve Guilds - Fail %i %i", failure, statuscode);
		delete request;
		delete view_as<Handle>(dp);
		return;
	}
	SteamWorks_GetHTTPResponseBodyCallback(request, OnGetMessage_Data, dp);
	delete request;
}

public int OnGetMessage_Data(const char[] data, any dpt) {
	DataPack dp = view_as<DataPack>(dpt);
	ResetPack(dp);
	DiscordBot Bot = ReadPackCell(dp);
	DiscordChannel Channel = ReadPackCell(dp);
	//delete dp;
	
	if(!Bot.IsListeningToChannel(Channel)) {
		delete dp;
		return;
	}
	
	Handle hJson = json_load(data);
	
	if(json_is_array(hJson)) {
		for(int i = json_array_size(hJson) - 1; i >= 0; i--) {
			Handle hObject = json_array_get(hJson, i);
			
			//The reason we find Channel for each message instead of global incase
			//Bot stops listening for the channel while we are still sending messages
			char channelID[32];
			JsonObjectGetString(hObject, "channel_id", channelID, sizeof(channelID));
			
			//Find Channel corresponding to Channel id
			//DiscordChannel Channel = Bot.GetListeningChannelByID(channelID);
			if(!Bot.IsListeningToChannelID(channelID)) {
				//Channel is no longer listed to, remove any handles & stop
				delete hObject;
				delete hJson;
				delete dp;
				return;
			}
			
			static char message[2048];
			JsonObjectGetString(hObject, "content", message, sizeof(message));
			
			char id[32];
			JsonObjectGetString(hObject, "id", id, sizeof(id));
			
			if(i == 0) {
				Channel.SetLastMessageID(id);
			}
			
			Handle hAuthor = json_object_get(hObject, "author");
			
			char userID[32];
			JsonObjectGetString(hAuthor, "id", userID, sizeof(userID));
			
			char name[32];
			char discriminator[4];
			
			JsonObjectGetString(hAuthor, "username", name, sizeof(name));
			JsonObjectGetString(hAuthor, "discriminator", discriminator, sizeof(discriminator));
			
			delete hAuthor;
			
			//Get info and fire forward
			if(Channel.MessageCallback != null) {
				Call_StartForward(Channel.MessageCallback);
				Call_PushCell(Bot);
				Call_PushCell(Channel);
				
				Call_PushString(message);
				Call_PushString(id);
				
				Call_PushString(userID);
				Call_PushString(name);
				Call_PushString(discriminator);
				
				Call_PushCell(hObject);
				Call_Finish();
			}
			
			delete hObject;
		}
	}
	
	CreateTimer(Bot.MessageCheckInterval, CheckMessageTimer, dp);
	
	delete hJson;
}