---
-- @Liquipedia
-- page=Module:TeamParticipants/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local RoleUtil = Lua.import('Module:Role/Util')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local TeamParticipantsWikiParser = {}

---@alias TeamParticipant {opponent: standardOpponent, notes: {text: string, highlighted: boolean}[], aliases: string[],
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
	local aliases = Array.parseCommaSeparatedString(input.aliases, ';')
	table.insert(aliases, Opponent.toName(opponent))
	return {
		opponent = opponent,
		qualifierText = input.qualifier,
		qualifierPage = input.qualifierpage,
		qualifierUrl = input.qualifierurl,
		aliases = Array.flatMap(aliases, function(alias)
			return TeamTemplate.queryHistoricalNames(alias)
		end),
		notes = Array.map(input.notes or {}, function(note)
			local text = note[1]
			if not text then
				return nil
			end
			return {
				text = text,
				highlighted = Logic.readBool(note.highlighted),
			}
		end),
	}
end

---@param input table
---@return standardPlayer[]
function TeamParticipantsWikiParser.parsePlayers(input)
	return Array.map(input.players or {}, TeamParticipantsWikiParser.parsePlayer)
end

---@param playerInput table
---@return standardPlayer
function TeamParticipantsWikiParser.parsePlayer(playerInput)
	return {
		displayName = playerInput[1],
		flag = playerInput.flag,
		pageName = playerInput.link,
		team = playerInput.team,
		faction = playerInput.faction,
		extradata = {
			roles = RoleUtil.readRoleArgs(playerInput.role),
			trophies = tonumber(playerInput.trophies),
			type = playerInput.type or 'player',
		},
	}
end

return TeamParticipantsWikiParser
