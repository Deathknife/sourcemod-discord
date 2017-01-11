# discord_test.sp
On the command: `sm_getguilds` / `!getguilds` the plugin will list all guilds and channels in the client console. It will hook into every channel and print any messages in discord channel to the server console. If the message is `Ping` it will reply with `Pong`. `sm_recreatebot` will delete the bot and create it again(for testing purposes)

Not recommended to use this plugin on live server.

# discord_announcement.sp
The plugin will hook into any channels with the name of `server-announcement` and print any messages sent in that channel to all players on servers with the `[Announcement]` prefix.

Should be fine to have this on a live server.

# discord_calladmin.sp
The plugin finds all channels with the name of `call-admin` and stores them. When a client types `!calladmin` it will send a message to all those channels.

Should be fine to have this on a live server.