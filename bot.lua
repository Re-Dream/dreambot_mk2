
-- some fuckery
_G.require = require
setfenv(1, _G)
Msg = print

-- loading

-- helpers
require("./libs/math_extension.lua")
require("./libs/string_extension.lua")
require("./libs/table_extension.lua")
require("./libs/misc_helpers.lua")
inspect = require("./libs/inspect.lua")
os.linux = package.config:sub(1, 1) == "/"

timer = require("timer") -- js like timers
fs = require("fs")

http = require("http")
https = require("https")
querystring = require("querystring")

json = require("json")
xml = require("./libs/xml.lua").newParser()
base64 = require("base64")

childprocess = require("childprocess")

local _, magick = pcall(require, "magick")
_G.magick = magick

-- discordia stuff
discordia = require("discordia")
discordia.extensions() -- I had no idea this was a thing, some of my code is being overwritten, careful there.
enums = discordia.enums
Color = discordia.Color

-- prepare bot
client = discordia.Client()
bot = {
	config = require("./config.lua"),
	start = os.time(),
	client = client,
	notifyOwners = function(content)
		for id, _ in next, config.owners do
			client:getUser(id):send(content)
		end
	end,
	github = (function()
		local remotes = io.popen("git remote -v"):read("*all")
		local remote = remotes:match("origin\t(https://[%w%/%-%_%.]*)")
		return remote
	end)() .. "/tree/master",
	funcToGithub = function(func)
		local info = debug.getinfo(func)
		if info.source == "eval" then return info.source end
		local src = info.source:gsub("^@", "")
		local s, e = info.linedefined, info.lastlinedefined
		local cwd = process.cwd():gsub("\\", "/")
		local filePath = src:sub(cwd:len() + 2) -- gsub wouldn't work. trailing space i guess
		return bot.github .. "/" .. filePath .. "#L" .. s .. "-L" .. e
	end,
	errorToGithub = function(str)
		local cwd = process.cwd():gsub("\\", "/")
		str = str:gsub("<", "\\<")
		str = str:gsub(">", "\\>")
		str = str:gsub(cwd .. "/(.-):(%d+):?", "[%1:%2:](" .. bot.github .. "/" .. "%1#L%2)")
		return str
	end
}
config = bot.config

paging = require("./paging.lua")
event = require("./events.lua")

-- commands
require("./commands.lua")
client:on("ready", function()
	local prefix = bot.commandPrefixes[1]
	client:setGame({ name = prefix .. "help", type = 2 }) -- Listening to d$help
	-- client:setGame({ name = "you 👀", type = 3 }) -- Watching you :eyes:

	local errorlog = fs.readFileSync("errorlog")
	if errorlog and errorlog:trim() ~= "" then
		bot.notifyOwners((":warning: Bot didn't exit cleanly: ```\n%s\n```"):format(errorlog))
		fs.writeFileSync("errorlog", "")
	end
end)
process:on("exit", function()
	fs.writeFileSync("errorlog", "") -- if we quit cleanly then don't care about errors
end)

client:run("Bot " .. config.token)

