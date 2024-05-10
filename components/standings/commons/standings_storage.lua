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

return StandingsStorage
