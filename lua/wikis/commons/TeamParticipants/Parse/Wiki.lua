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
local Tournament = Lua.import('Module:Tournament')

local TeamParticipantsWikiParser = {}

---@alias TeamParticipant {opponent: standardOpponent, notes: {text: string, highlighted: boolean}[], aliases: string[],
---qualification: QualificationStructure?, shouldImportFromDb: boolean, date: integer}

---@alias QualificationMethod 'invite'|'qual'
---@alias QualificationType 'tournament'|'external'|'other'

---@alias QualificationStructure {method: QualificationMethod, type: QualificationType,
---tournament?: StandardTournament, url?: string, text?: string}

---@param args table
---@return {participants: TeamParticipant[]}
function TeamParticipantsWikiParser.parseWikiInput(args)
	local date = DateExt.parseIsoDate(args.date) or DateExt.parseIsoDate(DateExt.getContextualDateOrNow())

	local participants = Array.map(args, function (input)
		return TeamParticipantsWikiParser.parseParticipant(input, date)
	end)

	return {
		participants = participants
	}
end

---@param input table?
---@return QualificationStructure?
local function parseQualifier(input)
	if not input then
		return
	end
	local qualificationMethod = input.method
	if not qualificationMethod then
		return
	end

	local qualificationType
	if input.page then
		qualificationType = 'tournament'
	elseif input.url then
		qualificationType = 'external'
	else
		qualificationType = 'other'
	end

	local qualificationStructure = {
		method = qualificationMethod,
		type = qualificationType,
		text = input.text
	}

	if qualificationType == 'tournament' then
		local tournament = Tournament.getTournament(input.page)
		if not tournament then
			qualificationStructure.type = 'other'
		else
			qualificationStructure.tournament = tournament
		end
	elseif qualificationType == 'external' then
		qualificationStructure.url = input.url
	end

	if qualificationType == 'external' and not qualificationStructure.text then
		error('External qualifier must have text')
	end

	return qualificationStructure
end

--- Parse a single participant from input
---@param input table
---@param date osdateparam
---@return TeamParticipant
function TeamParticipantsWikiParser.parseParticipant(input, date)
	local opponent = Opponent.readOpponentArgs(Table.merge(input, {
		type = Opponent.team,
	}))
	opponent.players = TeamParticipantsWikiParser.parsePlayers(input)
	opponent = Opponent.resolve(opponent, DateExt.toYmdInUtc(date), {syncPlayer = true})
	local aliases = Array.parseCommaSeparatedString(input.aliases, ';')
	table.insert(aliases, Opponent.toName(opponent))
	return {
		opponent = opponent,
		qualification = parseQualifier(input.qualification),
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
		shouldImportFromDb = Logic.readBool(input.import),
		date = DateExt.parseIsoDate(input.date) or date, -- TODO: fetch from wiki var too
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
	local player = Opponent.readSinglePlayerArgs(playerInput)
	player.extradata = {
		roles = RoleUtil.readRoleArgs(playerInput.role),
		trophies = tonumber(playerInput.trophies),
		type = playerInput.type or 'player',
	}
	return player
end

return TeamParticipantsWikiParser
