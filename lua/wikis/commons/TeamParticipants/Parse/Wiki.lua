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

---@alias TeamParticipant {opponent: standardOpponent, notes: string?,
---qualifierText: string?, qualifierPage: string?, qualifierUrl: string?}

---@param args table
---@return {participants: TeamParticipant[]}
function TeamParticipantsWikiParser.parseWikiInput(args)
	local date = DateExt.readTimestamp(args.date) or DateExt.getContextualDateOrNow()

	local participants = Array.map(args, function (input)
		return TeamParticipantsWikiParser.parseParticipant(input, date)
	end)

	return {
		participants = participants
	}
end

--- Parse a single participant from input
---@param input table
---@param date string|number|nil
---@return TeamParticipant
function TeamParticipantsWikiParser.parseParticipant(input, date)
	local opponent = Opponent.readOpponentArgs(Table.merge(input, {
		type = Opponent.team,
	}))
	opponent.players = TeamParticipantsWikiParser.parsePlayers(input)
	opponent = Opponent.resolve(opponent, date, {syncPlayer = true})
	return {
		opponent = opponent,
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
