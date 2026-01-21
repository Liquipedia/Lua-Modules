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
local Placement = Lua.import('Module:Placement')
local RoleUtil = Lua.import('Module:Role/Util')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local TeamParticipantsWikiParser = {}

---@alias TeamParticipant {opponent: standardOpponent, notes: {text: string, highlighted: boolean}[], aliases: string[],
---qualification: QualificationStructure?, shouldImportFromDb: boolean, date: integer,
---potentialQualifiers: standardOpponent[]?, warnings: string[]?, participantGroup: string?}

---@alias QualificationMethod 'invite'|'qual'
---@alias QualificationType 'tournament'|'internal'|'external'|'other'

---@alias QualificationStructure {method: QualificationMethod, type: QualificationType,
---page?: string, tournament?: StandardTournament, url?: string, text?: string, placement?: string}

---@param args table
---@return {participants: TeamParticipant[], expectedPlayerCount: integer?}
function TeamParticipantsWikiParser.parseWikiInput(args)
	local date = DateExt.parseIsoDate(args.date) or DateExt.parseIsoDate(DateExt.getContextualDateOrNow())
	local minimumPlayers = tonumber(args.minimumplayers)

	local participants = Array.map(args, function (input)
		return TeamParticipantsWikiParser.parseParticipant(input, date)
	end)

	return {
		participants = participants,
		expectedPlayerCount = minimumPlayers,
	}
end

---@param input string|number
---@return string
local function validatePlacement(input)
	local placement = Placement.raw(input)

	assert(not placement.unknown, 'Invalid placement: ' .. input)

	return table.concat(placement.placement, '-')
end

---@param input table?
---@return QualificationStructure?, string[]?
local function parseQualifier(input)
	if not input then
		return
	end
	local warnings = {}
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
		local tournamentPage = input.page
		if not tournamentPage then
			error('Tournament qualifier must have a page')
		end
		if String.startsWith(tournamentPage, '/') then
			tournamentPage = mw.title.getCurrentTitle().text .. tournamentPage
		end
		local tournament = Tournament.getTournament(tournamentPage)
		if not tournament then
			qualificationStructure.type = 'internal'
			qualificationStructure.page = input.page
		else
			qualificationStructure.tournament = tournament
		end
	elseif qualificationType == 'external' then
		qualificationStructure.url = input.url
	end

	if qualificationType == 'external' or qualificationType == 'internal' then
		assert(qualificationStructure.text, 'External or non-tournament qualifier must have text')
	end

	if input.placement then
		Logic.tryCatch(
			function()
				qualificationStructure.placement = validatePlacement(input.placement)
			end,
			function(errorMessage)
				table.insert(warnings, errorMessage)
			end
		)
	end

	if #warnings > 0 then
		return qualificationStructure, warnings
	end
	return qualificationStructure
end

--- Parse a single participant from input
---@param input table
---@param defaultDate osdateparam
---@return TeamParticipant
function TeamParticipantsWikiParser.parseParticipant(input, defaultDate)
	local potentialQualifiers = {}
	local opponent
	local warnings = {}

	local date = DateExt.parseIsoDate(input.date) or defaultDate -- TODO: fetch from wiki var too

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
	end

	local qualification, qualificationWarnings = parseQualifier(input.qualification)
	Array.extendWith(warnings, qualificationWarnings)

	local aliases = Array.parseCommaSeparatedString(input.aliases, ';')
	table.insert(aliases, Opponent.toName(opponent))

	return {
		opponent = opponent,
		qualification = qualification,
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
		participantGroup = String.nilIfEmpty(input.group),
		date = date,
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

	local playedInput = Logic.readBoolOrNil(playerInput.played)
	local resultsInput = Logic.readBoolOrNil(playerInput.results)
	local roles = RoleUtil.readRoleArgs(playerInput.role)
	local playerType = playerInput.type or 'player'

	local hasNoStaffRoles = Array.all(roles, function(role) return role.type ~= RoleUtil.ROLE_TYPE.STAFF end)

	if playerType ~= 'staff' and not hasNoStaffRoles then
		playerType = 'staff'
	end

	player.extradata = {
		roles = roles,
		trophies = tonumber(playerInput.trophies),
		type = playerType,
		played = Logic.nilOr(playedInput, true),
		results = Logic.nilOr(resultsInput, playedInput, true),
	}
	return player
end

---@param opponent standardOpponent
---@param minimumPlayers number?
function TeamParticipantsWikiParser.fillIncompleteRoster(opponent, minimumPlayers)
	local expectedPlayerCount = minimumPlayers or
		(Info.config.participants or {}).defaultPlayerNumber

	if not expectedPlayerCount or not opponent.players then
		return
	end

	local actualPlayers = Array.filter(opponent.players, function(player)
		return player.extradata.type == 'player'
	end)

	local actualPlayerCount = #actualPlayers
	if actualPlayerCount >= expectedPlayerCount then
		return
	end

	local tbdPlayers = TeamParticipantsWikiParser.createTBDPlayers(expectedPlayerCount - actualPlayerCount)
	Array.extendWith(opponent.players, tbdPlayers)
end

---@param count number
---@return standardPlayer[]
function TeamParticipantsWikiParser.createTBDPlayers(count)
	return Array.map(Array.range(1, count), function()
		return TeamParticipantsWikiParser.parsePlayer{'TBD'}
	end)
end

return TeamParticipantsWikiParser
