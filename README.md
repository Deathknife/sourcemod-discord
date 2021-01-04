# sourcemod-discord
Discord API for Sourcemod. There's a lot more to add. Changes will be happening that will break existing plugins, sorry. Still a bit messy

# IMPORTANT
Before you are able to send messages, you have to create a websocket connection with the bot atleast once. Simply, do this:
http://web.archive.org/web/20171202000621/http://scooterx3.net/2016-05-25/discord-bot.html

(Or paste this into browser -> console: http://pastebin.com/3g2HbTjY )

## Installation
- Put discord.inc in your include folder
- Compile discord_api.sp and put it in your sourcemod/plugins folder
- Install smjansson and SteamWorks extension (Might need to restart server after)

Optional examples:
- Edit the .sp by replacing `<Bot Token>` with your bot token.
- Compile and place in sourcemod/plugins

Bot Token can be obtained from:

https://discord.com/developers/applications/me

Create a new user and turn into bot account, reveal Token and copy.

## Features
- List all guilds
- List all Channels for guilds
- Send Messages to Channel
- Listen for messages for Channel

## API
For full list view `discord.inc` and take a look at `discord_test.sp` for examples.

### Note
> DiscordBot and DiscordChannel are both Handles. Everytime DiscordBot is passed, it's the same Handle to the Bot. This should not be closed unless you don't need that Bot anymore. DiscordChannel are handles to the Channel. Everytime Channel is passed the handle is closed after. If you need to keep the Channel Handle, Clone it. E.g `DiscordChannel newChannel = CloneHandle(Channel);`


### OnChannelMessage
Both Bot and channel are destroyed after it's called.
