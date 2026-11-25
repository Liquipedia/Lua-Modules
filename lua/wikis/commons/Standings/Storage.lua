---
-- @Liquipedia
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')

local StandingsStorage = {}
local DISQUALIFIED = 'dq'
-- TODO: Store as 'group' instead of 'league'
local STORAGE_TYPE = {group = 'league'}

---@class StandingsTableStorage
---@field standingsindex integer
---@field title string?
---@field type StandingsTableTypes
---@field entries StandingEntriesStorage[]
---@field matches string[]
---@field roundcount integer
---@field hasdraw boolean
---@field hasovertime boolean
---@field haspoints boolean
---@field finished boolean
---@field enddate string?
---@field extradata table

---@class StandingEntriesStorage
---@field standingsindex integer
---@field roundindex integer
---@field slotindex integer
---@field opponent standardOpponent
---@field participant string?
---@field placement string?
---@field points number
---@field definitestatus string?
---@field currentstatus string?
---@field placementchange integer?
---@field diff integer?
---@field match table?
---@field game table?
---@field overtime table?
---@field extradata table

---@param data table
---@param options? {storeLpdb?: boolean}
---@return table? standingsTable
---@return table[]? entries
function StandingsStorage.run(data, options)
	if Table.isEmpty(data) then
		return
	end

	data.roundcount = tonumber(data.roundcount) or Array.reduce(
		Array.map(data.entries, function (entry) return tonumber (entry.roundindex) end),
		math.max)

	-- An opponent has an entry for every round, all with the same opponent struct
	local toLpdbStruct = FnUtil.memoize(Opponent.toLpdbStruct)
	local entries = Array.map(data.entries, function (entry)
		return StandingsStorage.entry(entry, data.standingsindex, toLpdbStruct)
	end)

	local standingsTable = StandingsStorage.table(data)
	if StandingsStorage.shouldStoreLpdb(options) then
		StandingsStorage.saveLpdb(standingsTable, entries)
	end
	return standingsTable, entries
end

---@param data table
---@return table
function StandingsStorage.table(data)
	local title = data.title or ''
	local cleanedTitle = title:gsub('<.->.-</.->', '')

	local standingsIndex = tonumber(data.standingsindex)

	if not standingsIndex then
		error('No standingsindex specified')
	end

	local tournamentContext = Tournament.partialTournamentFromContext()

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
		hasovertime = data.hasovertime,
		haspoints = data.haspoints,
	}

	return {
		tournament = tournamentContext.fullName or '',
		parent = tournamentContext.pageName or '',
		standingsindex = standingsIndex,
		title = mw.text.trim(cleanedTitle),
		section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
		type = StandingsStorage.toStorageType(data.type),
		matches = Json.stringify(data.matches or {}, {asArray = true}),
		config = config,
		extradata = Table.merge(extradata, data.extradata),
	}
end

---@param tableType string
---@return string
function StandingsStorage.toStorageType(tableType)
	return STORAGE_TYPE[tableType] or tableType
end

---@param storedType string
---@return string
function StandingsStorage.fromStorageType(storedType)
	return Table.getKeyOfValue(STORAGE_TYPE, storedType) or storedType
end

---@param entry table
---@param standingsIndex number
---@param toLpdbStruct? fun(opponent: standardOpponent): table
---@return table?
function StandingsStorage.entry(entry, standingsIndex, toLpdbStruct)
	local roundIndex = tonumber(entry.roundindex)
	local slotIndex = tonumber(entry.slotindex)
	local standingsIndexNumber = tonumber(standingsIndex)

	if not standingsIndexNumber or not roundIndex or not slotIndex then
		return
	end

	local tournamentContext = Tournament.partialTournamentFromContext()

	local extradata = Table.mergeInto({
		enddate = entry.enddate,
		roundfinished = entry.finished,
		placerange = entry.placerange,
		slotindex = slotIndex,
		matchid = entry.matchid,
	}, entry.extradata)

	local lpdbEntry = Table.mergeInto({
		parent = tournamentContext.pageName or '',
		standingsindex = standingsIndexNumber,
		placement = entry.placement or entry.rank,
		definitestatus = entry.definitestatus or entry.bg,
		currentstatus = entry.currentstatus or entry.pbg,
		placementchange = entry.placementchange or entry.change,
		scoreboard = {
			match = StandingsStorage.toScoreBoardEntry(entry.match),
			overtime = StandingsStorage.toScoreBoardEntry(entry.overtime),
			game = StandingsStorage.toScoreBoardEntry(entry.game),
			points = tonumber(entry.points),
			diff = tonumber(entry.diff),
			buchholz = tonumber(entry.buchholz),
		},
		roundindex = roundIndex,
		slotindex = slotIndex,
		extradata = extradata,
	}, (toLpdbStruct or Opponent.toLpdbStruct)(entry.opponent))

	lpdbEntry.currentstatus = lpdbEntry.currentstatus or lpdbEntry.definitestatus

	return lpdbEntry
end

---@param standingsTable table?
---@param standingsEntries table[]?
function StandingsStorage.saveLpdb(standingsTable, standingsEntries)
	if standingsTable then
		mw.ext.LiquipediaDB.lpdb_standingstable(
			'standingsTable_' .. standingsTable.standingsindex,
			Json.stringifySubTables(standingsTable)
		)
	end

	Array.forEach(standingsEntries or {}, function(entry)
		mw.ext.LiquipediaDB.lpdb_standingsentry(
			'standing_' .. entry.standingsindex .. '_' .. entry.roundindex .. '_' .. entry.slotindex,
			Json.stringifySubTables(entry)
		)
	end)
end

---@param options? {storeLpdb?: boolean}
---@return boolean
function StandingsStorage.shouldStoreLpdb(options)
	return Lpdb.isStorageEnabled() and (options or {}).storeLpdb ~= false
end

---@param data table
---@return table
function StandingsStorage.toScoreBoardEntry(data)
	if Table.isEmpty(data) then
		return {w = 0, d = 0, l = 0}
	end

	local scoreBoard = {w = tonumber(data.w), d = tonumber(data.d), l = tonumber(data.l)}

	if not scoreBoard.w or not scoreBoard.l then
		mw.logObject(scoreBoard, 'invalid scoreBoardEntry')
		return {w = 0, d = 0, l = 0}
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

	if StandingsStorage.shouldStoreLpdb() then
		StandingsStorage.saveLpdb(StandingsStorage.table(data))
	end
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
		if data.team and TeamTemplate.exists(data.team) then
			team = TeamTemplate.getRaw(data.team, date)
		-- Input is link (possiblity with icon etc), and we managed to parse it
		elseif teamPage and TeamTemplate.exists(teamPage) then
			team = TeamTemplate.getRaw(teamPage, date)
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

	data.opponent = Opponent.resolve(Opponent.readOpponentArgs(opponentArgs), date)

	if (data.placement or ''):lower() == DISQUALIFIED then
		data.definitestatus = DISQUALIFIED
		data.currentstatus = DISQUALIFIED
	end

	data.placement = tonumber(data.placement)
	-- If template doesn't have slotIndex, use placement as workaround
	data.slotindex = tonumber(data.slotindex) or data.placement

	data.match = {w = data.win_m, d = data.tie_m, l = data.lose_m}
	data.game = {w = data.win_g, d = data.tie_g, l = data.lose_g}
	if StandingsStorage.shouldStoreLpdb() then
		StandingsStorage.saveLpdb(nil, {StandingsStorage.entry(data, data.standingsindex)})
	end
end

-- Legacy input method
---@deprecated
---@param frame table
function StandingsStorage.fromTemplate(frame)
	StandingsStorage.fromTemplateEntry(frame)
end

return StandingsStorage
