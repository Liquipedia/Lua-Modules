---
-- @Liquipedia
-- page=Module:TeamParticipants/Repository
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Variables = Lua.import('Module:Variables')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local ConditionUtil = Condition.Util
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Opponent = Lua.import('Module:Opponent/Custom')

local prizePoolVars = PageVariableNamespace('PrizePool')
local teamCardsVars = PageVariableNamespace('TeamCards')
local globalVars = PageVariableNamespace()

local TeamParticipantsRepository = {}

local function shouldStorePlayer(player)
	return player.extradata.results
end

--- Save a team participant to lpdb placement table, after merging data from prizepool if exists
---@param participant TeamParticipant
function TeamParticipantsRepository.save(participant)
	-- Since we merge data from prizepool and teamparticipants, we need to first fetch the existing record from prizepool
	-- Records can come from multiple prizepools, such as from both normal prizepool and an award
	local lpdbDatas = TeamParticipantsRepository.getPrizepoolRecordsForTeam(participant.opponent) or {}

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
	if not lpdbDatas[1] then
		---@diagnostic disable-next-line: missing-fields
		lpdbDatas[1] = {
			objectName = generateObjectName(),
			tournament = Variables.varDefault('tournament_name') or '',
			parent = Variables.varDefault('tournament_parent') or '',
			series = Variables.varDefault('tournament_series') or '',
			shortname = Variables.varDefault('tournament_tickername') or '',
			mode = Variables.varDefault('tournament_mode') or '',
			type = Variables.varDefault('tournament_type') or '',
			liquipediatier = Variables.varDefault('tournament_liquipediatier') or '',
			liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype') or '',
			publishertier = Variables.varDefault('tournament_publishertier') or '',
			icon = Variables.varDefault('tournament_icon') or '',
			icondark = Variables.varDefault('tournament_icondark') or '',
			game = Variables.varDefault('tournament_game') or '',
			startdate = Variables.varDefault('tournament_startdate') or '',
			date = Variables.varDefault('tournament_enddate') or '',
		}
	end

	Array.forEach(lpdbDatas, function(lpdbData)
		-- Remove players that should not be counted for results
		local activeOpponent = Table.deepCopy(participant.opponent)
		activeOpponent.players = Array.filter(activeOpponent.players or {}, shouldStorePlayer)
		-- Add full opponent data for players with results with this team
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

		if lpdbData.mode ~= 'award_individual' then
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
		end

		mw.ext.LiquipediaDB.lpdb_placement(lpdbData.objectName, Json.stringifySubTables(lpdbData))
	end)
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
			if not shouldStorePlayer(player) then
				return
			end
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
				globalVars:set(combinedPrefix .. 'id', player.apiId)
				globalVars:set(combinedPrefix .. 'faction', player.faction)
				globalVars:set(combinedPrefix .. 'joindate', player.extradata.joinDate)
				globalVars:set(combinedPrefix .. 'leavedate', player.extradata.leaveDate)
			end)
		end)
	end)
end

---@param playerPageNames string[]
---@param teamAliases string[]
---@param status 'active'|'activeAlt'|'inactive'|'former'
---@return table<string, string> -- pageName -> date (YYYY-MM-DD)
function TeamParticipantsRepository.getPlayerTransferDates(playerPageNames, teamAliases, status)
	if #playerPageNames == 0 then
		return {}
	end

	local startDate = Variables.varDefault('tournament_startdate', DateExt.getContextualDateOrNow())
	local endDate = Variables.varDefault('tournament_enddate', os.date('%F'))

	local toTeamFn, fromTeamFn
	if status == 'active' then
		toTeamFn, fromTeamFn = ConditionUtil.anyOf, ConditionUtil.noneOf
	elseif status == 'activeAlt' or status == 'inactive' then
		toTeamFn, fromTeamFn = ConditionUtil.anyOf, ConditionUtil.anyOf
	else -- former
		toTeamFn, fromTeamFn = ConditionUtil.noneOf, ConditionUtil.anyOf
	end

	local variantToCanonical = {}
	local nameVariants = {}
	Array.forEach(playerPageNames, function(name)
		variantToCanonical[name] = name
		table.insert(nameVariants, name)
		local alt = name:gsub('_', ' ')
		if alt ~= name then
			variantToCanonical[alt] = name
			table.insert(nameVariants, alt)
		end
	end)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.anyOf(ColumnName('player'), nameVariants),
		ConditionNode(ColumnName('date'), Comparator.ge, startDate),
		ConditionNode(ColumnName('date'), Comparator.le, endDate),
		toTeamFn(ColumnName('toteamtemplate'), teamAliases),
		fromTeamFn(ColumnName('fromteamtemplate'), teamAliases),
	}

	if status == 'active' then
		conditions:add(ConditionUtil.anyOf(ColumnName('role2'), {'', 'Loan'}))
	elseif status == 'activeAlt' then
		conditions:add(ConditionNode(ColumnName('role1'), Comparator.eq, 'Inactive'))
		conditions:add(ConditionNode(ColumnName('role2'), Comparator.eq, ''))
	elseif status == 'inactive' then
		conditions:add(ConditionNode(ColumnName('role2'), Comparator.eq, 'Inactive'))
	end

	local transferData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = tostring(conditions),
		order = 'date desc',
		limit = 5000,
	})

	local datesByPlayer = {}
	Array.forEach(transferData, function(row)
		local canonical = variantToCanonical[row.player]
		if canonical and not datesByPlayer[canonical] then
			datesByPlayer[canonical] = DateExt.toYmdInUtc(row.date)
		end
	end)
	return datesByPlayer
end

---@param players standardPlayer[]
---@param teamAliases string[]
---@return table<string, {joinDate: string?, leaveDate: string?}>
function TeamParticipantsRepository.getPlayersDates(players, teamAliases)
	local validPlayers = Array.filter(players, function(player)
		local pageName = Logic.nilIfEmpty(player.pageName)
		return pageName ~= nil and pageName:lower() ~= 'tbd'
	end)

	local datesByPlayer = {}
	Array.forEach(validPlayers, function(player)
		local extradata = player.extradata or {}
		datesByPlayer[player.pageName] = {
			joinDate = extradata.joinDate,
			leaveDate = extradata.leaveDate,
		}
	end)

	local function tryBatchQuery(playerSubset, status, field)
		local needsQuery = Array.filter(playerSubset, function(player)
			return Logic.isEmpty(datesByPlayer[player.pageName][field])
		end)
		if #needsQuery == 0 then
			return
		end
		local pageNames = Array.map(needsQuery, function(player) return player.pageName end)
		local fetched = TeamParticipantsRepository.getPlayerTransferDates(pageNames, teamAliases, status)
		Array.forEach(needsQuery, function(player)
			if fetched[player.pageName] then
				datesByPlayer[player.pageName][field] = fetched[player.pageName]
			end
		end)
	end

	tryBatchQuery(validPlayers, 'active', 'joinDate')
	tryBatchQuery(validPlayers, 'activeAlt', 'joinDate')

	local formerPlayers = Array.filter(validPlayers, function(player)
		return (player.extradata or {}).status == 'former'
	end)
	tryBatchQuery(formerPlayers, 'former', 'leaveDate')
	tryBatchQuery(formerPlayers, 'inactive', 'leaveDate')

	return datesByPlayer
end

---@param opponent standardOpponent
---@return placement[]
function TeamParticipantsRepository.getPrizepoolRecordsForTeam(opponent)
	if Opponent.isTbd(opponent) then
		return {}
	end
	local prizepoolRecords = TeamParticipantsRepository.getPrizepoolRecords()
	return Array.filter(prizepoolRecords, function(record)
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
