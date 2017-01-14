public int Native_DiscordWebHook_Send(Handle plugin, int numParams) {
	DiscordWebHook hook = GetNativeCell(1);
	SendWebHook(view_as<DiscordWebHook>(CloneHandle(hook)));
}

public int Native_DiscordWebHook_AddField(Handle plugin, int numParams) {
	DiscordWebHook hook = GetNativeCell(1);
	if(hook.FieldHandle == null) {
		hook.FieldHandle = json_array();
	}
	
	char title[32];
	char value[64];
	bool short;
	
	GetNativeString(2, title, sizeof(title));
	GetNativeString(3, value, sizeof(value));
	short = GetNativeCell(4);
	
	Handle hJson = json_object();
	json_object_set_new(hJson, "title", json_string(title));
	json_object_set_new(hJson, "value", json_string(value));
	json_object_set_new(hJson, "short", (short ? json_true() : json_false() ) );
	json_array_append_new(hook.FieldHandle, hJson);
}

public int Native_DiscordWebHook_DeleteFields(Handle plugin, int numParams) {
	DiscordWebHook hook = GetNativeCell(1);
	if(hook.FieldHandle != null) {
		delete hook.FieldHandle;
	}
}

public void SendWebHook(DiscordWebHook hook) {
	Handle hJson = json_object();
	
	char url[256];
	hook.GetUrl(url, sizeof(url));
	
	Handle hAttachments = null;
	
	if(hook.SlackMode) {
		if(StrContains(url, "/slack") == -1) {
			Format(url, sizeof(url), "%s/slack", url);
		}
		
		hAttachments = json_object();
	}
	
	char username[32];
	if(hook.GetUsername(username, sizeof(username))) {
		json_object_set_new(hJson, "username", json_string(username));
	}
	
	if(hook.tts) {
		json_object_set_new(hJson, "tts", json_true());
	}
	
	if(hAttachments != null) {
		if(hook.FieldHandle != null) {
			json_object_set_new(hAttachments, "fields", hook.FieldHandle);
			hook.FieldHandle = null;
		}
		
		char color[16];
		if(hook.GetColor(color, sizeof(color))) {
			json_object_set_new(hAttachments, "color", json_string(color));
		}
		
		char title[32];
		if(hook.GetTitle(title, sizeof(title))) {
			json_object_set_new(hAttachments, "title", json_string(title));
		}
		
		Handle hArray = json_array();
		json_array_append_new(hArray, hAttachments);
		json_object_set_new(hJson, "attachments", hArray);
	}
	
	static char content[2048];
	if(hook.GetContent(content, sizeof(content))) {
		json_object_set_new(hJson, "content", json_string(content));
	}
	
	//Send
	Handle request = PrepareRequestRaw(null, url, k_EHTTPMethodPOST, hJson, SendWebHookReceiveData);
	if(request == null) {
		CreateTimer(2.0, SendWebHookDelayed, hook);
		return;
	}
	
	SteamWorks_SetHTTPRequestContextValue(request, hook, UrlToDP(url));
	
	DiscordSendRequest(request, url);
}

public Action SendWebHookDelayed(Handle timer, any data) {
	DiscordWebHook hook = view_as<DiscordWebHook>(data);
	
	SendWebHook(hook);
}

public SendWebHookReceiveData(Handle request, bool failure, int offset, int statuscode, any dp) {
	if(failure || statuscode != 200) {
		if(statuscode == 429) {
			
			SendWebHook(view_as<DiscordWebHook>(dp));
			
			delete request;
			return;
		}
		LogError("[DISCORD] Couldn't Send Webhook - Fail %i %i", failure, statuscode);
		delete request;
		delete view_as<Handle>(dp);
		return;
	}
	delete request;
	delete view_as<Handle>(dp);
}