---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingsStorage = {}
local ALLOWED_SCORE_BOARD_KEYS = {'w', 'd', 'l'}
local SCOREBOARD_FALLBACK = {w = 0, d = 0, l = 0}
local DISQUALIFIED = 'dq'

---@enum standingType
StandingsStorage.STANDING_TYPES = {
	SWISS = 'swiss',
	LEAGUE = 'league',
}

---@class standingStorageStruct: standingstable
---@field entries standingsentry[]

---@param data table
function StandingsStorage.run(data)
	if Table.isEmpty(data) then
		return
	end

	data.roundcount = tonumber(data.roundcount) or Array.reduce(
		Array.map(data.entries, function (entry) return tonumber (entry.roundindex) end),
		math.max)

	StandingsStorage.table(data)

	Array.forEach(data.entries, function (entry)
		StandingsStorage.entry(entry, data.standingsindex)
	end)
end

---@param data table
function StandingsStorage.table(data)
	if not StandingsStorage.shouldStore() then
		return
	end

	local title = data.title or ''
	local cleanedTitle = title:gsub('<.->.-</.->', '')

	local standingsIndex = tonumber(data.standingsindex)

	if not standingsIndex then
		error('No standingsindex specified')
	end

	local extradata = {
		enddate = data.enddate,
		finished = data.finished,
		hasdraw = data.hasdraw,
		hasovertime = data.hasovertime,
		roundcount = data.roundcount,
		stagename = data.stagename or Variables.varDefault('bracket_header'),
	}

	local config = {
		hasdraws = data.hasdraw,
		hasovertimes = data.hasovertime,
		haspoints = data.haspoints,
	}

	mw.ext.LiquipediaDB.lpdb_standingstable('standingsTable_' .. data.standingsindex,
		{
			tournament = Variables.varDefault('tournament_name', ''),
			parent = Variables.varDefault('tournament_parent', ''),
			standingsindex = standingsIndex,
			title = mw.text.trim(cleanedTitle),
			section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
			type = data.type,
			matches = Json.stringify(data.matches or {}, {asArray = true}),
			config = mw.ext.LiquipediaDB.lpdb_create_json(config),
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(Table.merge(extradata, data.extradata)),
		}
	)
end

---@param entry table
---@param standingsIndex number
function StandingsStorage.entry(entry, standingsIndex)
	if not StandingsStorage.shouldStore() then
		return
	end

	local roundIndex = tonumber(entry.roundindex)
	local slotIndex = tonumber(entry.slotindex)
	local standingsIndexNumber = tonumber(standingsIndex)

	if not standingsIndexNumber or not roundIndex or not slotIndex then
		return
	end

	local extradata = {
		enddate = entry.enddate,
		roundfinished = entry.finished,
		placerange = entry.placerange,
		slotindex = slotIndex,
	}

	local lpdbEntry = {
		parent = Variables.varDefault('tournament_parent', ''),
		standingsindex = standingsIndexNumber,
		placement = entry.placement or entry.rank,
		definitestatus = entry.definitestatus or entry.bg,
		currentstatus = entry.currentstatus or entry.pbg,
		placementchange = entry.placementchange or entry.change,
		scoreboard = mw.ext.LiquipediaDB.lpdb_create_json{
			match = StandingsStorage.toScoreBoardEntry(entry.match),
			overtime = StandingsStorage.toScoreBoardEntry(entry.overtime),
			game = StandingsStorage.toScoreBoardEntry(entry.game),
			points = tonumber(entry.points),
			diff = tonumber(entry.diff),
			buchholz = tonumber(entry.buchholz),
		},
		roundindex = roundIndex,
		slotindex = slotIndex,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(Table.merge(extradata, entry.extradata)),
	}

	lpdbEntry.currentstatus = lpdbEntry.currentstatus or lpdbEntry.definitestatus

	mw.ext.LiquipediaDB.lpdb_standingsentry(
		'standing_' .. standingsIndexNumber .. '_' .. roundIndex .. '_' .. slotIndex,
		Table.merge(lpdbEntry, Opponent.toLpdbStruct(entry.opponent))
	)
end

---@return boolean
function StandingsStorage.shouldStore()
	return Namespace.isMain() and not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

---@param data table
---@return table
function StandingsStorage.toScoreBoardEntry(data)
	if Table.isEmpty(data) then
		return Table.copy(SCOREBOARD_FALLBACK)
	end

	local filterScoreBoard = function (key, value)
		return Table.includes(ALLOWED_SCORE_BOARD_KEYS, key)
	end

	local scoreBoard = Table.mapValues(Table.filterByKey(data, filterScoreBoard), tonumber)

	if not scoreBoard.w or not scoreBoard.l then
		mw.logObject(scoreBoard, 'invalid scoreBoardEntry')
		return Table.copy(SCOREBOARD_FALLBACK)
	end

	return scoreBoard
end

---@param frame table
function StandingsStorage.fromTemplateHeader(frame)
	local data = Arguments.getArgs(frame)

	if not data.standingsindex then
		return
	end

	data.roundcount = tonumber(data.roundcount) or 1
	data.finished = Logic.readBool(data.finished)

	StandingsStorage.table(data)
end

---@param frame table
function StandingsStorage.fromTemplateEntry(frame)
	local data = Arguments.getArgs(frame)

	if not data.standingsindex or not data.roundindex or not data.placement then
		return
	end
	if not data.team and not data.player and not data.opponent then
		return
	end

	local date = Variables.varDefault('tournament_startdate', Variables.varDefault('tournament_enddate'))

	local opponentArgs
	if data.opponent then
		opponentArgs = Json.parseIfString(data.opponent)

	elseif data.player then
		-- TODO: sanity checks
		data.participant, data.participantdisplay = string.match(data.player, '%[%[([^|]-)|?([^|]-)%]%]')
		data.participantflag = string.match(data.player, '<span class="flag">%[%[File:[^|]-%.png|36x24px|([^|]-)|')

		data.participant = String.nilIfEmpty(data.participant)
		data.participantdisplay = String.nilIfEmpty(data.participantdisplay)
		data.participantflag = String.nilIfEmpty(data.participantflag)

		opponentArgs = {
			link = data.participant or data.participantdisplay or data.player,
			name = data.participantdisplay or data.participant or data.player,
			type = Opponent.solo,
			flag = data.participantflag or data.flag,
			team = data.team
		}
		local faction = string.match(data.player, '&nbsp;%[%[File:[^]]-|([^|]-)%]%]')
		if String.isNotEmpty(faction) then
			opponentArgs.faction = faction:sub(1, 1):lower()
		end

	elseif data.team then
		-- attempts to find [[teamPage|teamDisplay]] and skips images (images have multiple |)
		local teamPage = string.match(data.team, '%[%[([^|]-)|[^|]-%]%]')
		local team

		-- Input contains an actual team
		if data.team and mw.ext.TeamTemplate.teamexists(data.team) then
			team = mw.ext.TeamTemplate.raw(data.team, date)
		-- Input is link (possiblity with icon etc), and we managed to parse it
		elseif teamPage and mw.ext.TeamTemplate.teamexists(teamPage) then
			team = mw.ext.TeamTemplate.raw(teamPage, date)
		end

		opponentArgs = {type = Opponent.team}

		if team then
			opponentArgs.template = team.templatename

			-- Legacy
			data.participant = team.page
			data.participantdisplay = team.name
			data.icon = team.image
			data.icondark = team.imagedark
		else
			-- Legacy
			data.participant = 'tbd'
			data.participantdisplay = 'TBD'
		end
	end

	data.opponent = Opponent.resolve(Opponent.readOpponentArgs(opponentArgs) or Opponent.tbd(), date)

	if (data.placement or ''):lower() == DISQUALIFIED then
		data.definitestatus = DISQUALIFIED
		data.currentstatus = DISQUALIFIED
	end

	data.placement = tonumber(data.placement)
	-- If template doesn't have slotIndex, use placement as workaround
	data.slotindex = tonumber(data.slotindex) or data.placement

	data.match = {w = data.win_m, d = data.tie_m, l = data.lose_m}
	data.game = {w = data.win_g, d = data.tie_g, l = data.lose_g}
	StandingsStorage.entry(data, data.standingsindex)
end

-- Legacy input method
---@deprecated
---@param frame table
function StandingsStorage.fromTemplate(frame)
	StandingsStorage.fromTemplateEntry(frame)
end

---@param record standingStorageStruct
---@return standardStanding
function StandingsStorage.fromStorageStruct(record)
	--todo
end

---@param group standardStanding
---@return table
function StandingsStorage.toStorageData(group)
	local standingsIndex = tonumber(Variables.varDefault('standingsindex'))
	Variables.varDefine('standingsindex', standingsIndex and standingsIndex + 1 or 0)

	--todo
end



Storage.store = Logic.wrapTryOrLog(function(groupTable, options)
	Storage.syncVariables(groupTable)

	if config.storeStanding then
		Storage.standardized(groupTable, config.toStandingRecords(groupTable))
	end
end)

--storage the new standardized way
function Storage.standardized(groupTable, records)
	local tableProps = groupTable.tableProps or {}
	local standingsIndex = globalVars:get('standingsindex')
	local groupTableStatus = groupTable.status or {}
	local roundCount = #groupTable.rounds

	local endTime = ''
	for _, record in pairs(records) do
		if ((record.extradata or {}).endTime or '') > endTime then
			endTime = record.extradata.endTime
		end
	end

	local finished = groupTableStatus.groupFinished

	local showMatchDraws = GroupTableLeague.Display.computeShowMatchDraws(groupTable) or nil
	-- store to lpdb_standingstable
	local standingsStorageData = {
		noLegacy = true,
		standingsindex = standingsIndex,
		title = tableProps.title,
		type = groupTable.structure.type or 'league',
		matches = Storage.getMatches(groupTable.matchRecords),
		roundCount = roundCount,
		extradata = {
			groupfinished = groupTableStatus.groupFinished,
			bracketindex = tonumber(globalVars:get('match2bracketindex')) or 0,
			endtime = endTime,
			placemapping = groupTable.placeMapping,
		},
		enddate = endTime,
		opponentLibrary = 'Opponent/Starcraft',
		hasovertime = false,
		hasdraw = showMatchDraws ~= nil,
		finished = finished,
	}

	local entries = {}
	for roundIndex = 1, roundCount do
		local results = groupTable.resultsByRound[roundIndex]

		local sortedOppIxs = Array.sortBy(Array.range(1, #groupTable.entries), function(oppIx)
			return results[oppIx].slotIndex
		end)

		Array.appendWith(entries, unpack(Array.map(sortedOppIxs, function(oppIx, slotIx)
			local entry = groupTable.entries[oppIx]
			if (entry.opponent or {}).type == Opponent.team then
				entry.opponent.template = entry.opponent.template or (entry.opponent.name or ''):lower()
			end
			return Table.deepMergeInto(
				Storage.resultPropsNew(oppIx, slotIx, roundIndex, groupTable, showMatchDraws, finished),
				{
					opponent = entry.opponent,
					roundindex = roundIndex,
					slotindex = slotIx,
				}
			)
		end)))
	end

	standingsStorageData.entries = entries

	StandingsStorage.run(standingsStorageData)
end

function Storage.getMatches(matches)
	local matchIds = {}
	for _, match in pairs(matches) do
		table.insert(matchIds, match.match2id)
	end

	return matchIds
end

function Storage.prepForNewScoreBoard(data, showMatchDraws)
	return {
		w = data[1],
		d = showMatchDraws and data[2] or nil,
		l = data[3],
	}
end

function Storage.resultPropsNew(opponentIndex, slotIndex, roundIndex, groupTable, showMatchDraws, finished)
	local slot = groupTable.slots[slotIndex]
	local entry = groupTable.entries[opponentIndex]
	local result = groupTable.resultsByRound[roundIndex][opponentIndex]
	result.rank = result.manualFinalTiebreak and finished and result.placeRange[1] == result.placeRange[2]
		and result.placeRangeIsExact and result.placeRange[1]
		or result.rank

	return {
		currentstatus = result.pbg,
		definitestatus = result.bg,
		diff = result.gameScore[1] - result.gameScore[3],
		extradata = {placerangeisexact = result.placeRangeIsExact},
		game = Storage.prepForNewScoreBoard(result.gameScore, showMatchDraws),
		match = Storage.prepForNewScoreBoard(result.matchScore, showMatchDraws),
		placement = result.rank,
		placementchange = result.rankChange and -result.rankChange,
		placerange = result.placeRange,
		points = groupTable.tableProps.hasPoints and result.points or nil,
		scoreboard = scoreboard,
		slotindex = slotIndex,
	}
end

--[[
Sets page variables expected by other templates.
]]


local StandingRecord = {}

function StandingRecord.toLpdbId(roundIndex, slotIndex)
	return table.concat({
		'standing',
		tonumber(globalVars:get('standingsindex')),
		roundIndex,
		slotIndex,
	}, '_')
end

function StandingRecord.toRecords(groupTable)
	-- Sort opponent results of the final round
	local results = groupTable.resultsByRound[#groupTable.rounds]
	local sortedOppIxs = Array.sortBy(Array.range(1, #groupTable.entries), function(oppIx)
		return results[oppIx].slotIndex
	end)

	local commonProps = StandingRecord.commonProps(groupTable)

	return Array.map(sortedOppIxs, function(oppIx, slotIx)
		local entry = groupTable.entries[oppIx]
		return Table.deepMergeInto(
			StandingRecord.resultProps(oppIx, slotIx, groupTable),
			StandingRecord.opponentProps(entry, groupTable),
			commonProps
		)
	end)
end

function StandingRecord.commonProps(groupTable)
	local matchGroupIds = Array.map(groupTable.matchRecords, function(matchRecord)
		return matchRecord.match2bracketid
	end)
	local pageNames = Array.map(groupTable.matchRecords, function(matchRecord)
		return matchRecord.pagename
	end)
	local endTime = GroupTableLeague.Status.getEndTime(groupTable.rounds, groupTable.matchRecords)

	local uniqueMatchGroupIds = Array.unique(matchGroupIds)

	local extradata = {
		bracketIndex = tonumber(globalVars:get('match2bracketindex')) or 0,
		endTime = DateExt.formatTimestamp('c', endTime),
		groupFinished = groupTable.status.groupFinished,
		finished = groupTable.status.groupFinished,
		matchGroupId = #uniqueMatchGroupIds == 1 and uniqueMatchGroupIds[1] or nil,
		roundFinished = groupTable.status.roundFinished,
		showMatchDraws = GroupTableLeague.Display.computeShowMatchDraws(groupTable) or nil,
		stageName = globalVars:get('bracket_header'),
	}

	local uniquePageNames = Array.unique(pageNames)

	return {
		extradata = extradata,
		roundindex = groupTable.status.currentRoundIndex,
		section = globalVars:get('last_heading') ~= nil and (globalVars:get('last_heading'):gsub('<.->', '')) or nil,
		standingsindex = globalVars:get('standingsindex'),
		title = groupTable.tableProps.title or 'Group',
		tournament = #uniquePageNames == 1 and uniquePageNames[1] or nil,
	}
end


function StandingRecord.resultProps(opponentIndex, slotIndex, groupTable)
	local slot = groupTable.slots[slotIndex]
	local entry = groupTable.entries[opponentIndex]
	local result = groupTable.resultsByRound[#groupTable.rounds][opponentIndex]

	local scoreboard = {
		diff = result.gameScore[1] - result.gameScore[3],
		game = result.gameScore,
		match = result.matchScore,
		points = groupTable.tableProps.hasPoints and result.points or nil,
	}
	local extradata = {
		opponent = entry.opponent,
		placeRange = result.placeRange,
		placeRangeIsExact = result.placeRangeIsExact,
		slotIndex = slotIndex,
	}
	return {
		change = result.rankChange and -result.rankChange,
		currentstatus = slot.pbg,
		definitestatus = result.bg,
		extradata = extradata,
		id = StandingRecord.toLpdbId(groupTable.status.currentRoundIndex, slotIndex),
		participant = Opponent.toName(entry.opponent):gsub(' ', '_'),
		placement = result.rank,
		scoreboard = scoreboard,
	}
end

function StandingRecord.opponentProps(entry, groupTable)
	local opponent = entry.opponent
	if opponent.type == 'team' then
		local raw = TeamTemplate.getRaw(opponent.template or opponent.name:gsub('_', ' '), groupTable.tableProps.resolveDate)
		return {
			icon = raw.image,
			icondark = raw.imagedark,
			participantdisplay = raw.name,
		}

	elseif Opponent.typeIsParty(opponent.type) then
		return {
			participantdisplay = opponent.players[1].displayName,
			participantflag = opponent.players[1].flag,
		}

	elseif opponent.type == 'literal' then
		return {
			participantdisplay = opponent.name,
		}
	end
end













return StandingsStorage
