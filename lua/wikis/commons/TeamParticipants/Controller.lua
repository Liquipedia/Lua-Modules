---
-- @Liquipedia
-- page=Module:TeamParticipants/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StandingsParseWiki = Lua.import('Module:TeamParticipants/Parse/Wiki')
local StandingsParseLpdb = Lua.import('Module:TeamParticipants/Parse/Lpdb')
local StandingsParser = Lua.import('Module:TeamParticipants/Parser')
local StandingsStorage = Lua.import('Module:TeamParticipants/Storage')

local StandingsDisplay = Lua.import('Module:Widget/Standings')

local TeamParticipantsController = {}

---@param frame Frame
---@return Widget
function TeamParticipantsController.fromTemplate(frame)
	local args = Arguments.getArgs(frame)

	local parsedData = StandingsParseWiki.parseWikiInput(args)

end

return TeamParticipantsController
