#pragma semicolon 1

#define PLUGIN_VERSION "0.1.3"

#include <sourcemod>
#include <discord>
#include <SteamWorks>
#include <smjansson>

#include "discord/SendMessage.sp"
#include "discord/GetGuilds.sp"
#include "discord/GetGuildChannels.sp"
#include "discord/ListenToChannel.sp"

//For rate limitation
Handle hRateLimit = null;
Handle hRateReset = null;
Handle hRateLeft = null;

public Plugin myinfo =  {
	name = "Discord API",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("DiscordBot.GetToken", Native_DiscordBot_Token_Get);
	
	CreateNative("DiscordBot.SendMessage", Native_DiscordBot_SendMessage);
	CreateNative("DiscordBot.SendMessageToChannelID", Native_DiscordBot_SendMessageToChannel);
	
	CreateNative("DiscordBot.StartTimer", Native_DiscordBot_StartTimer);
	
	CreateNative("DiscordBot.GetGuilds", Native_DiscordBot_GetGuilds);
	CreateNative("DiscordBot.GetGuildChannels", Native_DiscordBot_GetGuildChannels);
	
	CreateNative("DiscordChannel.SendMessage", Native_DiscordChannel_SendMessage);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	hRateLeft = new StringMap();
	hRateReset = new StringMap();
	hRateLimit = new StringMap();
}

public int Native_DiscordBot_Token_Get(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	static char token[196];
	GetTrieString(bot, "token", token, sizeof(token));
	SetNativeString(2, token, GetNativeCell(3));
}

stock void BuildAuthHeader(Handle request, DiscordBot Bot) {
	static char buffer[256];
	static char token[196];
	GetTrieString(Bot, "token", token, sizeof(token));
	FormatEx(buffer, sizeof(buffer), "Bot %s", token);
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
	
	SteamWorks_SetHTTPCallbacks(request, RequestCompleted, HeadersReceived, DataReceived);
	if(hJson != null) delete hJson;
	
	return request;
}

public int HTTPCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statuscode, any data, any data2) {
}

public int HTTPDataReceive(Handle request, bool failure, int offset, int statuscode, any dp) {
	//Too many requests
	if(statuscode == 429) {
		//DataPack newDP = new DataPack();
		//WritePackCell(newDP, request);
		//WritePackCell(newDP, dp);
		
		float time = GetRandomFloat(5.0, 10.0);
		CreateTimer(time, SendRequestAgain, request);
		return;
	}
	delete request;
}

public int HeadersReceived(Handle request, bool failure, any data, any datapack) {
	DataPack dp = view_as<DataPack>(datapack);
	if(failure) {
		delete dp;
		return;
	}
	
	char xRateLimit[16];
	char xRateLeft[16];
	char xRateReset[32];
	
	bool exists = false;
	
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Limit", xRateLimit, sizeof(xRateLimit));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Remaining", xRateLeft, sizeof(xRateLeft));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Reset", xRateReset, sizeof(xRateReset));
	
	//Get url
	char route[128];
	ResetPack(dp);
	ReadPackString(dp, route, sizeof(route));
	delete dp;
	
	if(exists) {
		SetTrieValue(hRateReset, route, StringToInt(xRateReset));
		SetTrieValue(hRateLeft, route, StringToInt(xRateLeft));
		SetTrieValue(hRateLimit, route, StringToInt(xRateLimit));
	}else {
		SetTrieValue(hRateReset, route, -1);
		SetTrieValue(hRateLeft, route, -1);
		SetTrieValue(hRateLimit, route, -1);
	}
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

/*
This is rate limit imposing for per-route basis. Doesn't support global limit yet.
 */
public void DiscordSendRequest(Handle request, const char[] route) {
	//Check for reset
	int time = GetTime();
	int resetTime;
	
	int defLimit = 0;
	if(!GetTrieValue(hRateLimit, route, defLimit)) {
		defLimit = 1;
	}
	
	bool exists = GetTrieValue(hRateReset, route, resetTime);
	
	if(!exists) {
		SetTrieValue(hRateReset, route, GetTime() + 5);
		SetTrieValue(hRateLeft, route, defLimit - 1);
		SteamWorks_SendHTTPRequest(request);
		return;
	}
	
	if(time == -1) {
		//No x-rate-limit send
		SteamWorks_SendHTTPRequest(request);
		return;
	}
	
	if(time > resetTime) {
		SetTrieValue(hRateLeft, route, defLimit - 1);
		SteamWorks_SendHTTPRequest(request);
		return;
	}else {
		int left;
		GetTrieValue(hRateLeft, route, left);
		if(left == 0) {
			float remaining = float(resetTime) - float(time) + 1.0;
			Handle dp = new DataPack();
			WritePackCell(dp, request);
			WritePackString(dp, route);
			CreateTimer(remaining, SendRequestAgain, dp);
		}else {
			left--;
			SetTrieValue(hRateLeft, route, left);
			SteamWorks_SendHTTPRequest(request);
		}
	}
}

public Handle UrlToDP(char[] url) {
	DataPack dp = new DataPack();
	WritePackString(dp, url);
	return dp;
}

public Action SendRequestAgain(Handle timer, any dp) {
	ResetPack(dp);
	Handle request = ReadPackCell(dp);
	char route[128];
	ReadPackString(dp, route, sizeof(route));
	delete view_as<Handle>(dp);
	DiscordSendRequest(request, route);
}