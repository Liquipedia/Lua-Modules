---
-- @Liquipedia
-- page=Module:TeamParticipants/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local TeamParticipantsWikiParser = {}

---@param args table
---@return {opponents: standardOpponent[]}
function TeamParticipantsWikiParser.parseWikiInput(args)
	local date = DateExt.readTimestamp(args.date) or DateExt.getContextualDateOrNow()

	---@type StandingTableOpponentData[]
	local opponents = Array.map(args, function (opponentData)
		return TeamParticipantsWikiParser.parseOpponent(opponentData, date)
	end)

	return {
		opponents = opponents
	}
end

function TeamParticipantsWikiParser.parseOpponent(input, date)
	local opponent = Opponent.readOpponentArgs(Table.merge(input, {
		type = Opponent.team,
	}))
	opponent.players = TeamParticipantsWikiParser.parsePlayers(input)
	opponent = Opponent.resolve(opponent, date, {syncPlayer = true})
	return {
		opponentData = opponent,
		qualifierText = input.qualifier,
		qualifierPage = input.qualifierpage,
		qualifierUrl = input.qualifierurl,
		notes = input.notes,
	}
end

---@param input table
---@return standardPlayer[]
function TeamParticipantsWikiParser.parsePlayers(input)
	return Array.map(input.players or {}, function(playerInput)
		return {
			displayName = playerInput[1],
			flag = playerInput.flag,
			pageName = playerInput.link,
			team = playerInput.team,
			faction = playerInput.faction,
			extradata = {
				role = playerInput.role,
				trophies = playerInput.trophies,
				tab = playerInput.tab,
			},
		}
	end)
end

return TeamParticipantsWikiParser
