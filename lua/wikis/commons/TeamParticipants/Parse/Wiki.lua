---
-- @Liquipedia
-- page=Module:TeamParticipants/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local RoleUtil = Lua.import('Module:Role/Util')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local TeamParticipantsWikiParser = {}

---@alias TeamParticipant {opponent: standardOpponent, notes: {text: string, highlighted: boolean}[], aliases: string[],
---qualification: QualificationStructure?, shouldImportFromDb: boolean, date: integer,
---potentialQualifiers: standardOpponent[]?, warnings: string[]?}

---@alias QualificationMethod 'invite'|'qual'
---@alias QualificationType 'tournament'|'external'|'other'

---@alias QualificationStructure {method: QualificationMethod, type: QualificationType,
---tournament?: StandardTournament, url?: string, text?: string}

---@param args table
---@return {participants: TeamParticipant[]}
function TeamParticipantsWikiParser.parseWikiInput(args)
	local date = DateExt.parseIsoDate(args.date) or DateExt.parseIsoDate(DateExt.getContextualDateOrNow())
	local playerNumber = args.playernumber

	local participants = Array.map(args, function (input)
		return TeamParticipantsWikiParser.parseParticipant(input, date, playerNumber)
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
---@param playerNumber number
---@return TeamParticipant
function TeamParticipantsWikiParser.parseParticipant(input, date, playerNumber)
	local potentialQualifiers = {}
	local opponent
	local warnings = {}

	if input.contenders then
		opponent = Opponent.tbd(Opponent.team)
		local contenderNames = input.contenders

		if type(contenderNames) ~= 'table' then
			table.insert(warnings, 'Invalid contenders: expected a list of non-empty strings')
		else
			Array.forEach(contenderNames, function(name, idx)
				if type(name) ~= 'string' or name == '' then
					table.insert(warnings, string.format('Invalid contender entry at position %d: %s', idx, tostring(name)))
					return
				end
				table.insert(potentialQualifiers, Opponent.readOpponentArgs({type = Opponent.team, template = name}))
			end)
		end
		opponent.players = {}
	else
		opponent = Opponent.readOpponentArgs(Table.merge(input, {
			type = Opponent.team,
		}))
		opponent.players = TeamParticipantsWikiParser.parsePlayers(input)
		opponent = Opponent.resolve(opponent, DateExt.toYmdInUtc(date), {syncPlayer = true})

		TeamParticipantsWikiParser.fillIncompleteRoster(opponent, playerNumber)
	end

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
		potentialQualifiers = potentialQualifiers,
		warnings = warnings,
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

---@param opponent standardOpponent
---@param playerNumber number?
function TeamParticipantsWikiParser.fillIncompleteRoster(opponent, playerNumber)
	local expectedPlayerCount = playerNumber or (Info.config.participants and Info.config.participants.defaultPlayerNumber)
	if not expectedPlayerCount or not opponent.players then
		return
	end

	local actualPlayerCount = #opponent.players
	if actualPlayerCount >= expectedPlayerCount then
		return
	end

	local tbdPlayers = TeamParticipantsWikiParser.createTBDPlayers(
		expectedPlayerCount - actualPlayerCount,
		actualPlayerCount + 1
	)
	Array.forEach(tbdPlayers, function(tbdPlayer)
		table.insert(opponent.players, tbdPlayer)
	end)
end

---@param count number
---@param startIndex number?
---@return standardPlayer[]
function TeamParticipantsWikiParser.createTBDPlayers(count, startIndex)
	startIndex = startIndex or 1
	return Array.map(Array.range(startIndex, startIndex + count - 1), function(i)
		local player = Opponent.readPlayerArgs({[i] = 'TBD'}, i)
		player.extradata = {
			roles = {},
			trophies = 0,
			type = 'player',
		}
		return player
	end)
end

return TeamParticipantsWikiParser
