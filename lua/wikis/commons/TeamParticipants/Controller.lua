---
-- @Liquipedia
-- page=Module:TeamParticipants/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Json = Lua.import('Module:Json')

local TeamParticipantsWikiParser = Lua.import('Module:TeamParticipants/Parse/Wiki')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')

local TeamParticipantsDisplay = Lua.import('Module:Widget/Participants/Team/CardsGroup')

local TeamParticipantsController = {}

---@param frame Frame
---@return Widget
function TeamParticipantsController.fromTemplate(frame)
	local args = Json.parseStringified(Arguments.getArgs(frame))
	local parsedData = TeamParticipantsWikiParser.parseWikiInput(args)
	TeamParticipantsRepository.save(parsedData)
	return TeamParticipantsDisplay{
		pageName = mw.title.getCurrentTitle().text
	}
end

return TeamParticipantsController
