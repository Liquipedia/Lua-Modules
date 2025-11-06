---
-- @Liquipedia
-- page=Module:TeamParticipants/Repository
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Lpdb = Lua.import('Module:Lpdb')
local Page = Lua.import('Module:Page')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')

local prizePoolVars = PageVariableNamespace('PrizePool')
local teamCardsVars = PageVariableNamespace('TeamCards')

---@class TeamParticipantsEntity
---@field pagename string
---@field opponent standardOpponent
---@field qualifierText string?
---@field qualifierPage string?
---@field qualifierUrl string?

local TeamParticipantsRepository = {}

---@param TeamParticipant table
function TeamParticipantsRepository.save(TeamParticipant)
	-- Since we merge data from prizepool and teamparticipants, we need to first fetch the existing record from prizepool
	local lpdbData = TeamParticipantsRepository.getPrizepoolRecordForTeam(TeamParticipant.opponentData) or {}

	local function generateObjectName()
		local team = Opponent.toName(TeamParticipant.opponentData)
		local isTbd = Opponent.isTbd(TeamParticipant.opponentData)

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

	lpdbData.qualifier = TeamParticipant.qualifierText
	lpdbData.qualifierpage = TeamParticipant.qualifierPage
	lpdbData.qualifierurl = TeamParticipant.qualifierUrl
	lpdbData.extradata = lpdbData.extradata or {}

	lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(TeamParticipant.opponentData, {setPlayersInTeam = true}))
	-- Legacy participant fields
	lpdbData = Table.mergeInto(lpdbData, Opponent.toLegacyParticipantData(TeamParticipant.opponentData))
	lpdbData.players = lpdbData.opponentplayers

	local numberOfPlayersOnTeam = #(TeamParticipant.opponentData.players or {})
	if numberOfPlayersOnTeam == 0 then
		numberOfPlayersOnTeam = 1
	end
	lpdbData.individualprizemoney = (lpdbData.prizemoney or 0) / numberOfPlayersOnTeam

	-- TODO: Store aliases (page names) for opponents
	-- TODO: Store page vars

	lpdbData = Json.stringifySubTables(lpdbData)

	mw.ext.LiquipediaDB.lpdb_placement(lpdbData.objectName, lpdbData)
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

---@param pageName string
---@return TeamParticipantsEntity[]
function TeamParticipantsRepository.getAllByPageName(pageName)
	---@type placement[]
	local records = {}
	Lpdb.executeMassQuery(
		'placement',
		{
			conditions = tostring(
				Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, Page.pageifyLink(pageName))
			),
		},
		function(record)
			table.insert(records, record)
		end
	)
	return Array.map(records, TeamParticipantsRepository.entityFromRecord)
end

---@param record placement
---@return TeamParticipantsEntity
function TeamParticipantsRepository.entityFromRecord(record)
	---@type TeamParticipantsEntity
	local entity = {
		pagename = record.pagename,
		opponent = Opponent.fromLpdbStruct(record),
		qualifierText = record.qualifier,
		qualifierPage = record.qualifierpage,
		qualifierUrl = record.qualifierurl,
	}
	return entity
end

return TeamParticipantsRepository
