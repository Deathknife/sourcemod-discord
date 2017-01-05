#if defined _discord_included
	#endinput
#endif
#define _discord_included

methodmap DiscordBot  __nullable__ {
	public native DiscordBot(const char[] token);
	
	public native void GetToken(char[] token, int maxlength);
	
	public native void SendMessage(DiscordChannel channel, char[] message);
	
	public native void SendMessageToChannelID(char[] channel, char[] message);
	
	public native void GetGuilds(DiscordGuildsRetrieve fCallback = INVALID_FUNCTION, DiscordGuildsRetrievedAll fCallbackAll = INVALID_FUNCTION, any data=0);
	
	public native void GetGuildChannels(char[] guild, DiscordGuildChannelsRetrieve fCallback = INVALID_FUNCTION, DiscordGuildChannelsRetrieveAll fCallbackAll = INVALID_FUNCTION, any data=0);
}

typedef DiscordGuildsRetrieve = function void (DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data);

typedef DiscordGuildsRetrievedAll = function void (DiscordBot bot, ArrayList id, ArrayList name, ArrayList icon, ArrayList owner, ArrayList permissions, any data);

//Channel are Handles that are closed immediately after forwards called. To keep, clone. Or store id if thats what you want
typedef DiscordGuildChannelsRetrieve = function void (DiscordBot bot, char[] guild, DiscordChannel Channel, any data);

typedef DiscordGuildChannelsRetrieveAll = function void (DiscordBot bot, char[] guild, ArrayList Channels, any data);

methodmap DiscordChannel < StringMap {
	public DiscordChannel() {
		return view_as<DiscordChannel>(view_as<Handle>(new StringMap())); //not sure if necessary
	}
	
	public native void SendMessage(DiscordBot Bot, char[] message);

	public void GetGuild(char[] buffer, int maxlength) {
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
}