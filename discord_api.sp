#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>
#include <discord>
#include <SteamWorks>
#include <smjansson>

#include "discord/SendMessage.sp"
#include "discord/GetGuilds.sp"
#include "discord/GetGuildChannels.sp"

#define MAXBOTS 128

bool bBotUsed[MAXBOTS] = {false, ...}; 	//Specifies if bot id is being used
char cBotToken[MAXBOTS][128];			//Token corresponding to bot(used for Auth)

public Plugin myinfo =  {
	name = "Discord API",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("DiscordBot.DiscordBot", Native_DiscordBot_Instance);
	CreateNative("DiscordBot.GetToken", Native_DiscordBot_Token_Get);
	
	CreateNative("DiscordBot.SendMessage", Native_DiscordBot_SendMessage);
	CreateNative("DiscordBot.SendMessageToChannelID", Native_DiscordBot_SendMessageToChannel);
	
	CreateNative("DiscordBot.GetGuilds", Native_DiscordBot_GetGuilds);
	CreateNative("DiscordBot.GetGuildChannels", Native_DiscordBot_GetGuildChannels);
	
	CreateNative("DiscordChannel.SendMessage", Native_DiscordChannel_SendMessage);
	
	return APLRes_Success;
}

public void OnPluginStart() {
}

public int Native_DiscordBot_Instance(Handle plugin, int numParams) {
	//Find closest bBotUsed
	for(int i = 0; i < MAXBOTS; i++) {
		if(!bBotUsed[i]) {
			char token[128];
			GetNativeString(1, token, sizeof(token));
			
			bBotUsed[i] = true;
			strcopy(cBotToken[i], sizeof(cBotToken[]), token);
			
			return i;
		}
	}
	ThrowNativeError(SP_ERROR_NATIVE, "Bot limit reached");
	return -1;
}

public int Native_DiscordBot_Token_Get(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	SetNativeString(2, cBotToken[bot], GetNativeCell(3));
}

stock void BuildAuthHeader(Handle request, DiscordBot Bot) {
	static char buffer[256];
	FormatEx(buffer, sizeof(buffer), "Bot %s", cBotToken[Bot]);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Authorization", buffer);
}

stock Handle PrepareRequest(DiscordBot bot, char[] url, EHTTPMethod method=k_EHTTPMethodGET, Handle hJson=null, SteamWorksHTTPDataReceived DataReceived = INVALID_FUNCTION, SteamWorksHTTPRequestCompleted RequestCompleted = INVALID_FUNCTION) {
	static char stringJson[16384];
	stringJson[0] = '\0';
	if(hJson != null) {
		json_dump(hJson, stringJson, sizeof(stringJson), 0, true);
	}
	
	//Format url
	static char turl[128];
	FormatEx(turl, sizeof(turl), "https://discordapp.com/api/%s", url);
	
	Handle request = SteamWorks_CreateHTTPRequest(method, turl);
	
	BuildAuthHeader(request, bot);
	
	SteamWorks_SetHTTPRequestRawPostBody(request, "application/json; charset=UTF-8", stringJson, strlen(stringJson));
	
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 30);
	
	if(RequestCompleted == INVALID_FUNCTION) {
		//I had some bugs previously where it wouldn't send request and return code 0 if I didn't set request completed.
		//This is just a safety then, my issue could have been something else and I will test more later on
		RequestCompleted = HTTPCompleted;
	}
	
	if(DataReceived == INVALID_FUNCTION) {
		//Need to close the request handle
		DataReceived = HTTPDataReceive;
	}
	
	SteamWorks_SetHTTPCallbacks(request, RequestCompleted, INVALID_FUNCTION, DataReceived);
	if(hJson != null) delete hJson;
	
	return request;
}

public int HTTPCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statuscode, any data, any data2) {
}

public int HTTPDataReceive(Handle request, bool failure, int offset, int statuscode, any dp) {
	delete request;
}

int JsonObjectGetInt(Handle hElement, char[] key) {
	Handle hObject = json_object_get(hElement, key);
	if(hObject == INVALID_HANDLE) return 0;
	
	int value;
	if(json_is_integer(hObject)) {
		value = json_integer_value(hObject);
	}else if(json_is_string(hObject)) {
		char buffer[12];
		json_string_value(hObject, buffer, sizeof(buffer));
		value = StringToInt(buffer);
	}
	CloseHandle(hObject);
	return value;
}

stock void JsonObjectGetString(Handle hElement, char[] key, char[] buffer, maxlength) {
	Handle hObject = json_object_get(hElement, key);
	if(hObject == INVALID_HANDLE) return;
	
	if(json_is_integer(hObject)) {
		IntToString(json_integer_value(hObject), buffer, maxlength);
	}else if(json_is_string(hObject)) {
		json_string_value(hObject, buffer, maxlength);
	}else if(json_is_real(hObject)) {
		FloatToString(json_real_value(hObject), buffer, maxlength);
	}
	CloseHandle(hObject);
}

stock bool JsonObjectGetBool(Handle hElement, char[] key, bool defaultvalue=false) {
	Handle hObject = json_object_get(hElement, key);
	if(hObject == INVALID_HANDLE) return defaultvalue;
	
	bool ObjectBool = defaultvalue;
	
	if(json_is_integer(hObject)) {
		ObjectBool = view_as<bool>(json_integer_value(hObject));
	}else if(json_is_string(hObject)) {
		char buffer[11];
		json_string_value(hObject, buffer, sizeof(buffer));
		if(StrEqual(buffer, "true", false)) {
			ObjectBool = true;
		}else if(StrEqual(buffer, "false", false)) {
			ObjectBool = false;
		}else {
			int x = StringToInt(buffer);
			ObjectBool = view_as<bool>(x);
		}
	}else if(json_is_real(hObject)) {
		ObjectBool = view_as<bool>(RoundToFloor(json_real_value(hObject)));
	}else if(json_is_true(hObject)) {
		ObjectBool = true;
	}else if(json_is_false(hObject)) {
		ObjectBool = false;
	}
	CloseHandle(hObject);
	return ObjectBool;
}

stock DiscordChannel CreateChannelFromJson(Handle hJson) {
	DiscordChannel Channel = new DiscordChannel();
	
	Handle hIterator = json_object_iter(hJson);
	while(hIterator != INVALID_HANDLE) {
		char key[64];
		json_object_iter_key(hIterator, key, sizeof(key));
		
		Handle hElement = json_object_iter_value(hIterator);
		
		if(json_is_string(hElement)) {
			char buffer[128];
			json_string_value(hElement, buffer, sizeof(buffer));
			SetTrieString(Channel, key, buffer);
		}else if(json_is_integer(hElement)) {
			SetTrieValue(Channel, key, json_integer_value(hElement));
		}else if(json_is_true(hElement)) {
			SetTrieValue(Channel, key, 1);
		}else if(json_is_false(hElement)) {
			SetTrieValue(Channel, key, 0);
		}
		
		delete hElement;
		hIterator = json_object_iter_next(hJson, hIterator);
	}
	return Channel;
}