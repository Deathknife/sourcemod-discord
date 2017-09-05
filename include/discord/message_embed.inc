methodmap MessageEmbed < Handle {
  public MessageEmbed() {
    Handle hObj = json_object();
    return view_as<MessageEmbed>(hObj);
  }

  public bool GetTitle(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "title", buffer, maxlength);
	}

	public void SetTitle(char[] title) {
		json_object_set_new(this, "title", json_string(title));
	}

  public bool GetDescription(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "description", buffer, maxlength);
	}

	public void SetDescription(char[] description) {
		json_object_set_new(this, "description", json_string(description));
	}

  public bool GetUrl(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "url", buffer, maxlength);
	}

	public void SetUrl(char[] url) {
		json_object_set_new(this, "url", json_string(url));
	}

  property int Color { // Hexadecimal RGB int (i.e 0xffffff for white, 0x00ff00 for green...)
		public get() {
			return JsonObjectGetInt(this, "color");
		}

		public set(int value) {
			json_object_set_new(this, "color", json_integer(value));
		}
	}

  public void SetFooter(char[] text, char[] icon_url) {
    Handle hObj = json_object();
    json_object_set_new(hObj, "text", json_string(text));
    json_object_set_new(hObj, "icon_url", json_string(icon_url));
    json_object_set_new(this, "footer", hObj);
  }

  public bool GetFooterText(char[] buffer, int maxlength) {
    return JsonObjectGetString(json_object_get(this, "footer"), "text", buffer, maxlength);
  }

  public bool GetFooterIconUrl(char[] buffer, int maxlength) {
    return JsonObjectGetString(json_object_get(this, "footer"), "icon_url", buffer, maxlength);
  }

  public bool GetImageUrl(char[] buffer, int maxlength) {
		return JsonObjectGetString(json_object_get(this, "image"), "url", buffer, maxlength);
	}

	public void SetImageUrl(char[] url) {
    Handle hObj = json_object();
    json_object_set_new(hObj, "url", json_string(url));
    json_object_set_new(this, "image", hObj);
	}

  public bool GetThumbnailUrl(char[] buffer, int maxlength) {
		return JsonObjectGetString(json_object_get(this, "thumbnail"), "url", buffer, maxlength);
	}

	public void SetThumbnailUrl(char[] url) {
    Handle hObj = json_object();
    json_object_set_new(hObj, "url", json_string(url));
    json_object_set_new(this, "thumbnail", hObj);
	}

  /**
	 * Note: Setting Fields will delete the handle!
	 */
	property Handle Fields {
		public get() {
			return json_object_get(this, "fields");
		}

		public set(Handle value) {
			json_object_set_new(this, "fields", value);
		}
	}

	public void AddField(char[] name, char[] value, bool inline) {
		Handle hObj = json_object();
		json_object_set_new(hObj, "name", json_string(name));
		json_object_set_new(hObj, "value", json_string(value));
		json_object_set_new(hObj, "inline", json_boolean(inline));
		Handle hArray = this.Fields;
		if(this.Fields == null) {
			hArray = json_array();
		}
		json_array_append_new(hArray, hObj);
		this.Fields = hArray;
	}
}
