---
-- @Liquipedia
-- page=Module:TeamParticipants/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local TeamParticipantsWikiParser = Lua.import('Module:TeamParticipants/Parse/Wiki')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')

local TeamParticipantsDisplay = Lua.import('Module:Widget/Participants/Team/CardsGroup')

local TeamParticipantsController = {}

---@param frame Frame
---@return Widget
function TeamParticipantsController.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local parsedArgs = Json.parseStringifiedArgs(args)
	local parsedData = TeamParticipantsWikiParser.parseWikiInput(parsedArgs)

	local shouldStore =
		Logic.readBoolOrNil(args.store) ~= false and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))

	if shouldStore then
		Array.forEach(parsedData.participants, TeamParticipantsRepository.save)
	end
	Array.forEach(parsedData.participants, TeamParticipantsRepository.setPageVars)
	return TeamParticipantsDisplay{
		participants = parsedData.participants
	}
end

return TeamParticipantsController
