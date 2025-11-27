---
-- @Liquipedia
-- page=Module:TeamParticipants/Repository
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')

local prizePoolVars = PageVariableNamespace('PrizePool')
local teamCardsVars = PageVariableNamespace('TeamCards')
local globalVars = PageVariableNamespace()

local TeamParticipantsRepository = {}

--- Save a team participant to lpdb placement table, after merging data from prizepool if exists
---@param participant TeamParticipant
function TeamParticipantsRepository.save(participant)
	-- Since we merge data from prizepool and teamparticipants, we need to first fetch the existing record from prizepool
	local lpdbData = TeamParticipantsRepository.getPrizepoolRecordForTeam(participant.opponent) or {}

	local function generateObjectName()
		local team = Opponent.toName(participant.opponent)
		local isTbd = Opponent.isTbd(participant.opponent)

		if not isTbd then
			return 'ranking_' .. mw.ustring.lower(team)
		end

		-- Ensure names are unique for TBDs
		local storageName = 'participant_' .. mw.ustring.lower(team)
		local tbdCounter = tonumber(teamCardsVars:get('TBDs')) or 1

		storageName = storageName .. '_' .. tbdCounter
		teamCardsVars:set('TBDs', tbdCounter + 1)

		return storageName
	end

	-- Use the tournament defaults if no data is provided from prizepool
	-- TODO: Refactor in the future to have a util function deal with this, including prizepool, broadcasters, etc.
	lpdbData.objectName = lpdbData.objectName or generateObjectName()
	lpdbData.tournament = lpdbData.tournament or Variables.varDefault('tournament_name')
	lpdbData.parent = lpdbData.parent or Variables.varDefault('tournament_parent')
	lpdbData.series = lpdbData.series or Variables.varDefault('tournament_series')
	lpdbData.shortname = lpdbData.shortname or Variables.varDefault('tournament_tickername')
	lpdbData.mode = lpdbData.mode or Variables.varDefault('tournament_mode')
	lpdbData.type = lpdbData.type or Variables.varDefault('tournament_type')
	lpdbData.liquipediatier = lpdbData.liquipediatier or Variables.varDefault('tournament_liquipediatier')
	lpdbData.liquipediatiertype = lpdbData.liquipediatiertype or Variables.varDefault('tournament_liquipediatiertype')
	lpdbData.publishertier = lpdbData.publishertier or Variables.varDefault('tournament_publishertier')
	lpdbData.icon = lpdbData.icon or Variables.varDefault('tournament_icon')
	lpdbData.icondark = lpdbData.icondark or Variables.varDefault('tournament_icondark')
	lpdbData.game = lpdbData.game or Variables.varDefault('tournament_game')
	lpdbData.startdate = lpdbData.startdate or Variables.varDefault('tournament_startdate')
	lpdbData.date = lpdbData.date or Variables.varDefault('tournament_enddate')

	if participant.qualification then
		lpdbData.qualifier = participant.qualification.text
		if participant.qualification.type == 'tournament' then
			lpdbData.qualifierpage = participant.qualification.tournament.pageName
		elseif participant.qualification.type == 'external' then
			lpdbData.qualifierurl = participant.qualification.url
		end
	end

	lpdbData.extradata = lpdbData.extradata or {}
	lpdbData.extradata.opponentaliases = participant.aliases
	if participant.potentialQualifiers and #participant.potentialQualifiers > 0 then
		local serializedQualifiers = Array.map(participant.potentialQualifiers, Opponent.toName)
		lpdbData.extradata.potentialQualifiers = serializedQualifiers
	end

	-- Remove players that did not play
	local activeOpponent = Table.deepCopy(participant.opponent)
	activeOpponent.players = Array.filter(activeOpponent.players or {}, function(player)
		return player.extradata.played
	end)
	-- Add full opponent data for played opponents
	lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(activeOpponent, { setPlayersInTeam = true }))
	-- Legacy participant fields
	lpdbData = Table.mergeInto(lpdbData, Opponent.toLegacyParticipantData(activeOpponent))
	lpdbData.players = lpdbData.opponentplayers

	-- Calculate individual prize money (prize money per player on team)
	if lpdbData.prizemoney then
		local filteredPlayers = Array.filter(activeOpponent.players, function(player)
			return player.extradata.type ~= 'staff'
		end)
		local numberOfPlayersOnTeam = math.max(#(filteredPlayers), 1)
		lpdbData.individualprizemoney = lpdbData.prizemoney / numberOfPlayersOnTeam
	end

	mw.ext.LiquipediaDB.lpdb_placement(lpdbData.objectName, Json.stringifySubTables(lpdbData))
end

--- Set wiki variables for team participants to be used in other modules/templates, primarily matches
--- This matches with what HiddenDataBox also does
--- We should change all usages to be more sane structure instead of flat variables in the future
---@param participant TeamParticipant
function TeamParticipantsRepository.setPageVars(participant)
	Array.forEach(participant.aliases or {}, function(teamTemplate)
		local teamName = TeamTemplate.getPageName(teamTemplate)
		if not teamName then
			return
		end
		local teamPrefixes = {
			teamName:gsub('_', ' '),
			teamName:gsub(' ', '_'),
		}
		local playerCount, staffCount = 0, 0
		Array.forEach(participant.opponent.players or {}, function(player)
			local playerPrefix
			if player.extradata.type == 'staff' then
				staffCount = staffCount + 1
				playerPrefix = 'c' .. staffCount
			else
				playerCount = playerCount + 1
				playerPrefix = 'p' .. playerCount
			end

			Array.forEach(teamPrefixes, function(teamPrefix)
				local combinedPrefix = teamPrefix .. '_' .. playerPrefix
				globalVars:set(combinedPrefix, player.pageName)
				globalVars:set(combinedPrefix .. 'flag', player.flag)
				globalVars:set(combinedPrefix .. 'dn', player.displayName)
				-- TODO: joindate, leavedate
			end)
		end)
	end)
end

---@param opponent standardOpponent
---@return placement?
function TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)
	local prizepoolRecords = TeamParticipantsRepository.getPrizepoolRecords()
	return Array.find(prizepoolRecords, function(record)
		return Opponent.same(opponent, Opponent.fromLpdbStruct(record))
	end)
end

---@return placement[]
TeamParticipantsRepository.getPrizepoolRecords = FnUtil.memoize(function()
	return Array.flatten(Array.mapIndexes(function(prizePoolIndex)
		return Json.parseIfString(prizePoolVars:get('placementRecords.' .. prizePoolIndex))
	end))
end)

return TeamParticipantsRepository
