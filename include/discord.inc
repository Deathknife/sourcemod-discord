#if defined _discord_included
	#endinput
#endif
#define _discord_included

typedef DiscordGuildsRetrieve = function void (DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data);

typedef DiscordGuildsRetrievedAll = function void (DiscordBot bot, ArrayList id, ArrayList name, ArrayList icon, ArrayList owner, ArrayList permissions, any data);

//Channel are Handles that are closed immediately after forwards called. To keep, clone. Or store id if thats what you want
typedef DiscordGuildChannelsRetrieve = function void (DiscordBot bot, char[] guild, DiscordChannel Channel, any data);

typedef DiscordGuildChannelsRetrieveAll = function void (DiscordBot bot, char[] guild, ArrayList Channels, any data);

typeset OnChannelMessage { 
	function void(DiscordBot bot, DiscordChannel channel, const char[] message);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator);
	function void(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator, Handle hJson);
};

typedef OnGetReactions = function void (DiscordBot bot, ArrayList Users, char[] channelID, const char[] messageID, const char[] emoji, any data);

methodmap DiscordChannel < StringMap {
	public DiscordChannel() {
		StringMap mp = new StringMap();
		return view_as<DiscordChannel>(mp);
	}
	
	public native void SendMessage(DiscordBot Bot, char[] message);

	public void GetGuildID(char[] buffer, int maxlength) {
		GetTrieString(this, "guild_id", buffer, maxlength);
	}
	
	public void GetID(char[] buffer, int maxlength) {
		GetTrieString(this, "id", buffer, maxlength);
	}
	
	public void GetName(char[] buffer, int maxlength) {
		GetTrieString(this, "name", buffer, maxlength);
	}
	
	public void GetType(char[] buffer, int maxlength) {
		GetTrieString(this, "type", buffer, maxlength);
	}
	
	property int Position {
		public get() {
			int value;
			GetTrieValue(this, "position", value);
			return value;
		}
	}
	
	property bool IsPrivate {
		public get() {
			int value;
			GetTrieValue(this, "is_private", value);
			return view_as<bool>(value);
		}
	}
	
	public void GetTopic(char[] buffer, int maxlength) {
		GetTrieString(this, "topic", buffer, maxlength);
	}
	
	public void GetLastMessageID(char[] buffer, int maxlength) {
		GetTrieString(this, "last_message_id", buffer, maxlength);
	}
	
	public void SetLastMessageID(char[] id) {
		SetTrieString(this, "last_message_id", id);
	}
	
	property int Bitrate {
		public get() {
			int value;
			GetTrieValue(this, "bitrate", value);
			return value;
		}
	}
	
	property int UserLimit {
		public get() {
			int value;
			GetTrieValue(this, "user_limit", value);
			return value;
		}
	}
	
	property bool IsText {
		public get() {
			char type[8];
			this.GetType(type, sizeof(type));
			if(StrEqual(type, "text", false)) return true;
			return false;
		}
	}
	
	property Handle MessageCallback {
		public get() {
			Handle fForward = null;
			if(!GetTrieValue(this, "callback", fForward)) {
				return null;
			}
			
			return fForward;
		}
		
		public set(Handle value) {
			SetTrieValue(this, "callback", value);
		}
	}
	
	property Handle MessageTimer {
		public get() {
			Handle hTimer = null;
			if(!GetTrieValue(this, "htimer", hTimer)) {
				return null;
			}
			
			return hTimer;
		}
		
		public set(Handle value) {
			SetTrieValue(this, "htimer", value);
		}
	}
	
	property Handle MessageRequest {
		public get() {
			Handle hTimer = null;
			if(!GetTrieValue(this, "hrequest", hTimer)) {
				return null;
			}
			
			return hTimer;
		}
		
		public set(Handle value) {
			SetTrieValue(this, "hrequest", value);
		}
	}
	
	public native void Destroy();
}

methodmap DiscordBot < StringMap {
	public DiscordBot(const char[] token) {
		StringMap mp = new StringMap();
		SetTrieString(mp, "token", token);
		return view_as<DiscordBot>(mp);
	}
	
	/*
	Remove any data associated with the bot
	Still have to delete the handle afterwards
	 */
	public void DestroyData() {
		ArrayList alChannels = null;
		GetTrieValue(this, "channels", alChannels);
		
		if(alChannels != null) {
			for(int i = 0; i < alChannels.Length; i++) {
				DiscordChannel tempChannel = alChannels.Get(i);
				
				tempChannel.Destroy();
				
				if(tempChannel.MessageCallback != null) {
					delete tempChannel.MessageCallback;
					tempChannel.MessageCallback = null;
				}
					
				delete tempChannel;
			}
			delete alChannels;
		}
		SetTrieValue(this, "channels", view_as<Handle>(null));
	}
	
	property float MessageCheckInterval {
		public get() {
			float val;
			if(!GetTrieValue(this, "messageinterval", val)) {
				return 2.0;
			}
			return val;
		}
		public set(float value) {
			SetTrieValue(this, "messageinterval", value);
		}
	}
	
	public native void StartTimer(DiscordChannel Channel);
	
	/** 
	 * Retrieves a list of Channels the bot is listening to for messages
	 */
	public ArrayList GetListeningChannels() {
		ArrayList alChannels = null;
		GetTrieValue(this, "channels", alChannels);
		return alChannels;
	}
	
	/**
	 * Checks if the bot is listening to channel for messages
	 * @param DiscordChannel Channel
	 */
	public bool IsListeningToChannel(DiscordChannel Channel) {
		char id[32];
		Channel.GetID(id, sizeof(id));
		
		ArrayList channels = this.GetListeningChannels();
		if(channels == null) return false;
		
		for(int i = 0; i < channels.Length; i++) {
			DiscordChannel tempChannel = channels.Get(i);
			static char tempID[32];
			tempChannel.GetID(tempID, sizeof(tempID));
			if(StrEqual(id, tempID, false)) {
				//delete channels;
				return true;
			}
		}
		//delete channels;
		return false;
	}
	
	/**
	 * Checks if the bot is listening to channel for messages
	 * @param DiscordChannel Channel
	 */
	public bool IsListeningToChannelID(char[] id) {
		ArrayList channels = this.GetListeningChannels();
		if(channels == null) return false;
		
		for(int i = 0; i < channels.Length; i++) {
			DiscordChannel tempChannel = channels.Get(i);
			static char tempID[32];
			tempChannel.GetID(tempID, sizeof(tempID));
			if(StrEqual(id, tempID, false)) {
				//delete channels;
				return true;
			}
		}
		//delete channels;
		return false;
	}
	
	/**
	 * Stops the bot from listening to that channel for messages
	 * @param DiscordChannel Channel
	 */
	public void StopListeningToChannel(DiscordChannel Channel) {
		char id[32];
		Channel.GetID(id, sizeof(id));
		
		ArrayList channels = this.GetListeningChannels();
		if(channels == null) return;
		
		for(int i = 0; i < channels.Length; i++) {
			DiscordChannel tempChannel = channels.Get(i);
			static char tempID[32];
			tempChannel.GetID(tempID, sizeof(tempID));
			if(StrEqual(id, tempID, false)) {
				if(tempChannel.MessageCallback != null) {
					delete tempChannel.MessageCallback;
					tempChannel.MessageCallback = null;
				}
				
				tempChannel.Destroy();
				
				channels.Erase(i);
				
				delete tempChannel;
			}
		}
		//delete channels;
	}
	
	/**
	 * Stops the bot from listening to that channel id for messages
	 * @param DiscordChannel Channel
	 */
	public void StopListeningToChannelID(char[] ChannelID) {
		ArrayList channels = this.GetListeningChannels();
		
		if(channels == null) return;
		
		for(int i = 0; i < channels.Length; i++) {
			DiscordChannel tempChannel = channels.Get(i);
			static char tempID[32];
			tempChannel.GetID(tempID, sizeof(tempID));
			if(StrEqual(ChannelID, tempID, false)) {
				if(tempChannel.MessageCallback != null) {
					delete tempChannel.MessageCallback;
					tempChannel.MessageCallback = null;
				}
				
				tempChannel.Destroy();
				
				channels.Erase(i);
				delete tempChannel;
			}
		}
		//delete channels;
	}
	
	public DiscordChannel GetListeningChannelByID(char[] ChannelID) {
		ArrayList channels = this.GetListeningChannels();
		if(channels == null) return null;
		for(int i = 0; i < channels.Length; i++) {
			DiscordChannel tempChannel = channels.Get(i);
			static char tempID[32];
			tempChannel.GetID(tempID, sizeof(tempID));
			if(StrEqual(ChannelID, tempID, false)) {
				//delete channels;
				return tempChannel;
			}
		}
		return null;
	}
	
	/**
	 * Start listening to the channel for messages.
	 * The Channel handle is duplicated. Feel free to close yours.
	 * @param DiscordChannel Channel
	 */
	public void StartListeningToChannel(DiscordChannel Channel, OnChannelMessage callback) {
		if(this.IsListeningToChannel(Channel)) return;
		
		DiscordChannel newChannel = view_as<DiscordChannel>(CloneHandle(Channel));
		ArrayList alChannels = this.GetListeningChannels();
		
		if(alChannels == null) {
			alChannels = new ArrayList();
			SetTrieValue(this, "channels", alChannels);
		}
		
		alChannels.Push(newChannel);
		//delete alChannels;
		
		Handle fForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String, Param_String, Param_String, Param_String, Param_Cell);
		AddToForward(fForward, GetMyHandle(), callback);
		newChannel.MessageCallback = fForward;
		
		this.StartTimer(newChannel);
	}
	
	
	public native void AddReactionID(char[] channel, char[] messageid, char[] emoji);
	
	public void AddReaction(DiscordChannel channel, char[] messageid, char[] emoji) {
		char channelid[64];
		channel.GetID(channelid, sizeof(channelid));
		this.AddReactionID(channelid, messageid, emoji);
	}
	
	public native void DeleteReactionID(char[] channel, char[] messageid, char[] emoji, char[] user);
	
	public void DeleteReaction(DiscordChannel channel, char[] messageid, char[] emoji, char[] user) {
		char chid[64];
		channel.GetID(chid, sizeof(chid));
		this.DeleteReactionID(chid, messageid, emoji, user);
	}
	
	public void DeleteReactionSelf(DiscordChannel channel, char[] messageid, char[] emoji) {
		this.DeleteReaction(channel, messageid, emoji, "@me");
	}
	public void DeleteReactionAll(DiscordChannel channel, char[] messageid, char[] emoji) {
		this.DeleteReaction(channel, messageid, emoji, "@all");
	}
	
	public void DeleteReactionSelfID(char[] channel, char[] messageid, char[] emoji) {
		this.DeleteReactionID(channel, messageid, emoji, "@me");
	}
	public void DeleteReactionAllID(char[] channel, char[] messageid, char[] emoji) {
		this.DeleteReactionID(channel, messageid, emoji, "@all");
	}
	
	public native void GetReactionID(char[] channel, char[] messageid, char[] emoji, OnGetReactions fCallback=INVALID_FUNCTION, any data=0);
	
	public void GetReaction(DiscordChannel channel, char[] messageid, char[] emoji, OnGetReactions fCallback=INVALID_FUNCTION, any data=0) {
		char id[64];
		channel.GetID(id, sizeof(id));
		this.GetReactionID(id, messageid, emoji, fCallback, data);
	}
	
	public native void GetToken(char[] token, int maxlength);
	
	public native void SendMessage(DiscordChannel channel, char[] message);
	
	public native void SendMessageToChannelID(char[] channel, char[] message);
	
	public native void GetGuilds(DiscordGuildsRetrieve fCallback = INVALID_FUNCTION, DiscordGuildsRetrievedAll fCallbackAll = INVALID_FUNCTION, any data=0);
	
	public native void GetGuildChannels(char[] guild, DiscordGuildChannelsRetrieve fCallback = INVALID_FUNCTION, DiscordGuildChannelsRetrieveAll fCallbackAll = INVALID_FUNCTION, any data=0);
}

methodmap DiscordWebHook < StringMap {
	public DiscordWebHook(char[] url) {
		StringMap mp = new StringMap();
		SetTrieString(mp, "url", url);
		return view_as<DiscordWebHook>(mp);
	}
	
	public void GetUrl(char[] buffer, int maxlength) {
		GetTrieString(this, "url", buffer, maxlength);
	}
	
	property bool SlackMode {
		public get() {
			bool value = false;
			if(!GetTrieValue(this, "slack", value)) {
				return false;
			}
			
			return value;
		}
		
		public set(bool value) {
			SetTrieValue(this, "slack", value);
		}
	}
	
	public native void AddField(char[] title, char[] value, bool short);
	
	public native void DeleteFields();
	
	/*
	Handle to JSON array for fields
	 */
	property Handle FieldHandle {
		public get() {
			Handle value = null;
			if(!GetTrieValue(this, "FieldHandle", value)) {
				return null;
			}
			return value;
		}
		
		public set(Handle value) {
			SetTrieValue(this, "FieldHandle", value);
		}
	}
	
	property bool tts {
		public get() {
			bool value = false;
			if(!GetTrieValue(this, "tts", value)) {
				return false;
			}
			
			return value;
		}
		
		public set(bool value) {
			SetTrieValue(this, "tts", value);
		}
	}
	
	public bool GetUsername(char[] buffer, int maxlength) {
		return GetTrieString(this, "username", buffer, maxlength);
	}
	
	public void SetUsername(char[] name) {
		SetTrieString(this, "username", name);
	}
	
	public bool GetColor(char[] buffer, int maxlength) {
		return GetTrieString(this, "color", buffer, maxlength);
	}
	
	public void SetColor(char[] color) {
		SetTrieString(this, "color", color);
	}
	
	public bool GetTitle(char[] buffer, int maxlength) {
		return GetTrieString(this, "title", buffer, maxlength);
	}
	
	public void SetTitle(char[] title) {
		SetTrieString(this, "title", title);
	}
	
	public bool GetContent(char[] buffer, int maxlength) {
		return GetTrieString(this, "content", buffer, maxlength);
	}
	
	public void SetContent(char[] content) {
		SetTrieString(this, "content", content);
	}
	
	/*property Handle OnComplete {
		public get() {
			Handle fForward = null;
			if(!GetTrieValue(this, "callback", fForward)) {
				return null;
			}
			
			return fForward;
		}
		
		public set(Handle value) {
			SetTrieValue(this, "callback", value);
			SetTrieValue(this, "plugin", GetMyHandle());
		}
	}
	
	property Handle CallbackPlugin {
		public get() {
			Handle value = null;
			if(!GetTrieValue(this, "plugin", value)) {
				return null;
			}
			
			return value;
		}
	}*/
	
	public native void Send();
}

/*
{
    "id": "80351110224678912",
    "username": "Nelly",
    "discriminator": "1337",
    "avatar": "8342729096ea3675442027381ff50dfe",
    "verified": true,
    "email": "nelly@discordapp.com"
}
 */
//It's a JSON Handle with the above info
methodmap DiscordUser < Handle {
	public native void GetID(char[] buffer, int maxlength);
	
	public native void GetUsername(char[] buffer, int maxlength);
	
	public native void GetDiscriminator(char[] buffer, int maxlength);
	public int GetDiscriminatorInt() {
		char buffer[16];
		this.GetDiscriminator(buffer, sizeof(buffer));
		return StringToInt(buffer);
	}
	
	public native void GetAvatar(char[] buffer, int maxlength);
	
	public native bool IsVerified();
	
	public native void GetEmail(char[] buffer, int maxlength);
}