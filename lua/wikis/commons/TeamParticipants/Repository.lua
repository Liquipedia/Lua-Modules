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
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Opponent = Lua.import('Module:Opponent/Custom')

local prizePoolVars = PageVariableNamespace('PrizePool')
local teamCardsVars = PageVariableNamespace('TeamCards')
local globalVars = PageVariableNamespace()

local TeamParticipantsRepository = {}

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
		activeOpponent.players = Array.filter(activeOpponent.players or {}, function(player)
			return player.extradata.results
		end)
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

---@param playerPageName string
---@param teamAliases string[]
---@param status 'active'|'activeAlt'|'inactive'|'former'
---@return {joinDate: string?, leaveDate: string?}
function TeamParticipantsRepository.getPlayerTransferDate(playerPageName, teamAliases, status)
	local startDate = Variables.varDefault('tournament_startdate', DateExt.getContextualDateOrNow())
	local endDate = Variables.varDefault('tournament_enddate', os.date('%F'))

	local toTeamComparator, toTeamOperator, fromTeamComparator, fromTeamOperator
	if status == 'active' then
		toTeamComparator, toTeamOperator = Comparator.eq, BooleanOperator.any
		fromTeamComparator, fromTeamOperator = Comparator.neq, BooleanOperator.all
	elseif status == 'activeAlt' or status == 'inactive' then
		toTeamComparator, toTeamOperator = Comparator.eq, BooleanOperator.any
		fromTeamComparator, fromTeamOperator = Comparator.eq, BooleanOperator.any
	else -- former
		toTeamComparator, toTeamOperator = Comparator.neq, BooleanOperator.all
		fromTeamComparator, fromTeamOperator = Comparator.eq, BooleanOperator.any
	end

	local toTeamTree = ConditionTree(toTeamOperator)
	Array.forEach(teamAliases, function(alias)
		toTeamTree:add(ConditionNode(ColumnName('toteam'), toTeamComparator, alias))
	end)

	local fromTeamTree = ConditionTree(fromTeamOperator)
	Array.forEach(teamAliases, function(alias)
		fromTeamTree:add(ConditionNode(ColumnName('fromteam'), fromTeamComparator, alias))
	end)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('player'), Comparator.eq, playerPageName),
			ConditionNode(ColumnName('player'), Comparator.eq, playerPageName:gsub('_', ' ')),
		},
		ConditionNode(ColumnName('date'), Comparator.ge, startDate),
		ConditionNode(ColumnName('date'), Comparator.le, endDate),
		toTeamTree,
		fromTeamTree,
	}

	if status == 'active' then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('role2'), Comparator.eq, ''),
			ConditionNode(ColumnName('role2'), Comparator.eq, 'Loan'),
		})
	elseif status == 'activeAlt' then
		conditions:add(ConditionNode(ColumnName('role1'), Comparator.eq, 'Inactive'))
		conditions:add(ConditionNode(ColumnName('role2'), Comparator.eq, ''))
	elseif status == 'inactive' then
		conditions:add(ConditionNode(ColumnName('role2'), Comparator.eq, 'Inactive'))
	end

	local transferData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = tostring(conditions),
		order = 'date desc',
		limit = 1,
	})

	if not transferData[1] then
		return {}
	end

	if status == 'active' or status == 'activeAlt' then
		return {joinDate = DateExt.toYmdInUtc(transferData[1].date)}
	end
	return {leaveDate = DateExt.toYmdInUtc(transferData[1].date)}
end

---@param player standardPlayer
---@param teamAliases string[]
---@return {joinDate: string?, leaveDate: string?}
function TeamParticipantsRepository.getPlayerDates(player, teamAliases)
	local pageName = Logic.nilIfEmpty(player.pageName)
	if not pageName or pageName:lower() == 'tbd' then
		return {}
	end

	local extradata = player.extradata or {}
	local playerDates = {
		joinDate = extradata.joinDate,
		leaveDate = extradata.leaveDate,
	}

	if Logic.isNotEmpty(playerDates.joinDate) and Logic.isNotEmpty(playerDates.leaveDate) then
		return playerDates
	end

	local isFormer = extradata.status == 'former'

	playerDates = Table.merge(
		TeamParticipantsRepository.getPlayerTransferDate(pageName, teamAliases, 'active'),
		playerDates
	)
	if Logic.isEmpty(playerDates.joinDate) then
		playerDates = Table.merge(
			TeamParticipantsRepository.getPlayerTransferDate(pageName, teamAliases, 'activeAlt'),
			playerDates
		)
	end
	if isFormer then
		playerDates = Table.merge(
			TeamParticipantsRepository.getPlayerTransferDate(pageName, teamAliases, 'inactive'),
			playerDates
		)
		if Logic.isEmpty(playerDates.leaveDate) then
			playerDates = Table.merge(
				TeamParticipantsRepository.getPlayerTransferDate(pageName, teamAliases, 'former'),
				playerDates
			)
		end
	end

	return playerDates
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
