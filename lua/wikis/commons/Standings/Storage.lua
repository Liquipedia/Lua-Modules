---
-- @Liquipedia
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingsStorage = {}
local ALLOWED_SCORE_BOARD_KEYS = {'w', 'd', 'l'}
local SCOREBOARD_FALLBACK = {w = 0, d = 0, l = 0}
local DISQUALIFIED = 'dq'

---@class StandingsTableStorage
---@field standingsindex integer
---@field title string?
---@field type 'ffa'|'swiss'|'league'
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
---@param options? {saveVars?: boolean}
function StandingsStorage.run(data, options)
	if Table.isEmpty(data) then
		return
	end

	data.roundcount = tonumber(data.roundcount) or Array.reduce(
		Array.map(data.entries, function (entry) return tonumber (entry.roundindex) end),
		math.max)

	local entries = Array.map(data.entries, function (entry)
		return StandingsStorage.entry(entry, data.standingsindex)
	end)

	if StandingsStorage.shouldStoreLpdb() then
		StandingsStorage.saveLpdb(StandingsStorage.table(data), entries)
	end
	if options and options.saveVars then
		StandingsStorage.saveVars(StandingsStorage.table(data), entries)
	end
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

	return {
		tournament = Variables.varDefault('tournament_name', ''),
		parent = Variables.varDefault('tournament_parent', ''),
		standingsindex = standingsIndex,
		title = mw.text.trim(cleanedTitle),
		section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
		type = data.type,
		matches = Json.stringify(data.matches or {}, {asArray = true}),
		config = config,
		extradata = Table.merge(extradata, data.extradata),
	}
end

---@param entry table
---@param standingsIndex number
---@return table?
function StandingsStorage.entry(entry, standingsIndex)
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
		matchid = entry.matchid,
	}

	local lpdbEntry = {
		parent = Variables.varDefault('tournament_parent', ''),
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
		extradata = Table.merge(extradata, entry.extradata),
	}

	lpdbEntry.currentstatus = lpdbEntry.currentstatus or lpdbEntry.definitestatus

	return Table.merge(lpdbEntry, Opponent.toLpdbStruct(entry.opponent))
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

---@param standingsTable table?
---@param standingsEntries table[]?
function StandingsStorage.saveVars(standingsTable, standingsEntries)
	if standingsTable then
		-- We have a full standings here for storage, very simple
		-- Entries may be supplied later
		local wikiVariable = 'standings2_' .. standingsTable.standingsindex
		Variables.varDefine(wikiVariable, Json.stringify({
			standings = standingsTable,
			entries = standingsEntries or {},
		}))
	elseif standingsEntries and standingsEntries[1] then
		-- Entry that was supplied later on
		local wikiVariable = 'standings2_' .. standingsEntries[1].standingsindex
		local standings = Json.parseIfString(Variables.varDefault(wikiVariable))
		if not standings then
			mw.log('Could not store standings entry in wiki variables, unable to locate the standings table')
			return
		end
		if not standings.entries then
			mw.log('Could not store standings entry in wiki variables, invalid format')
			return
		end
		for _, entry in ipairs(standingsEntries) do
			table.insert(standings.entries, entry)
		end
		Variables.varDefine(wikiVariable, Json.stringify(standings))
	end
end

---@return boolean
function StandingsStorage.shouldStoreLpdb()
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
