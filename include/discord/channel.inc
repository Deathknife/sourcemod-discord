enum ChannelType {
	GUILD_TEXT = 0,
	DM = 1,
	GUILD_VOICE = 2,
	GROUP_DM = 3,
	GUILD_CATEGORY = 4
};

methodmap DiscordChannel < StringMap {
	public DiscordChannel() {
		Handle hObj = json_object();
		return view_as<DiscordChannel>(hObj);
	}
	
	public native void SendMessage(DiscordBot Bot, char[] message, OnMessageSent fCallback=INVALID_FUNCTION, any data=0);

	public void GetGuildID(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "guild_id", buffer, maxlength);
	}
	
	public void GetID(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "id", buffer, maxlength);
	}
	
	public void GetName(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "name", buffer, maxlength);
	}
	
	public ChannelType GetType() {
		view_as<ChannelType>(JsonObjectGetInt(this, "type"));
	}
	
	property int Position {
		public get() {
			return JsonObjectGetInt(this, "position");
		}
	}
	
	property bool IsPrivate {
		public get() {
			return JsonObjectGetBool(this, "is_private");
		}
	}
	
	public void GetTopic(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "topic", buffer, maxlength);
	}
	
	public void GetLastMessageID(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "last_message_id", buffer, maxlength);
	}
	
	public void SetLastMessageID(char[] id) {
		json_object_set_new(this, "last_message_id", json_string(id));
	}
	
	property int Bitrate {
		public get() {
			return JsonObjectGetInt(this, "bitrate");
		}
	}
	
	property int UserLimit {
		public get() {
			return JsonObjectGetInt(this, "user_limit");
		}
	}
	
	property bool IsText {
		public get() {
			return this.GetType() == GUILD_TEXT;
		}
	}
}