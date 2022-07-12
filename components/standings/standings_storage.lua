---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Flags = require('Module:Flags')
local Json = require('Module:Json')
local Opponent = require('Module:Opponent')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local StandingsStorage = {}
local ALLOWED_SCORE_BOARD_KEYS = {'w', 'd', 'l'}
local SCOREBOARD_FALLBACK = {w = 0, d = 0, l = 0}
local SCOREBOARD_LEGACY_FALLBACK = {0, 0, 0}

function StandingsStorage.run(data)
	if Table.isEmpty(data) then
		return
	end

	if data.opponentLibrary then
		Opponent = require('Module:'.. data.opponentLibrary)
	end

	local standingsIndex = tonumber(data.standingsindex) or 0

	data.roundcount = tonumber(data.roundcount) or Array.reduce(
		Array.map(data.entries, function (entry) return tonumber (entry.roundindex) end),
		math.max)

	StandingsStorage.table(data)

	Array.forEach(data.entries, function (entry)
		StandingsStorage.entry(entry, standingsIndex)
		StandingsStorage.runLegacy(entry.slotIndex, entry) -- Deprecated
	end)
end

function StandingsStorage.table(data)
	local title = data.title or ''
	local cleanedTitle = title:gsub('<.->.-</.->', '')

	local extradata = {
		roundcount = data.roundcount,
		stagename = data.stagename or Variables.varDefault('bracket_header'),
	}

	mw.ext.LiquipediaDB.lpdb_standingstable('standingsTable_' .. data.standingsindex,
		{
			tournament = Variables.varDefault('tournament_name', ''),
			parent = Variables.varDefault('tournament_parent', ''),
			standingsindex = tonumber(data.standingsindex),
			title = mw.text.trim(cleanedTitle),
			section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
			type = data.type,
			matches = mw.ext.LiquipediaDB.lpdb_create_json(data.matches or {}),
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(Table.merge(extradata, data.extradata)),
		}
	)
end

function StandingsStorage.entry(entry, standingsIndex)
	local roundIndex = tonumber(entry.roundindex)
	local slotIndex = tonumber(entry.slotindex)

	local extradata = {
		enddate = entry.enddate,
		roundfinished = entry.finished,
		placerange = entry.placerange,
		slotindex = slotIndex,
	}

	local lpdbEntry = {
		parent = Variables.varDefault('tournament_parent', ''),
		standingsindex = standingsIndex,
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
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(Table.merge(extradata, entry.extradata)),
	}

	mw.ext.LiquipediaDB.lpdb_standingsentry(
		'standing_' .. standingsIndex .. '_' .. entry.roundindex .. '_' .. slotIndex,
		Table.merge(lpdbEntry, Opponent.toLpdbStruct(entry.opponent))
	)
end

function StandingsStorage.toScoreBoardEntry(data)
	if Table.isEmpty(data) then
		return
	end

	local filterScoreBoard = function (_, key)
		return ALLOWED_SCORE_BOARD_KEYS[key] and true or false
	end

	-- Need to use Array.filter here. Because strangely enough Table.filter has no access to keys...
	local scoreBoard = Table.mapValues(Array.filter(data, filterScoreBoard), tonumber)

	if not scoreBoard.w or not scoreBoard.l then
		mw.logObject(scoreBoard, 'invalid scoreBoardEntry')
		return SCOREBOARD_FALLBACK
	end

	return scoreBoard
end

--- @deprecated
function StandingsStorage.runLegacy(index, data)
	local title = data.title or ''
	local cleanedTitle = title:gsub('<.->.-</.->', '')
	mw.ext.LiquipediaDB.lpdb_standing(
		'standing_' .. data.standingsindex .. '_' .. data.roundindex .. '_' .. index,
		{
			title = mw.text.trim(cleanedTitle),
			tournament = data.tournament,
			type = data.type,
			participant = data.participant,
			participantdisplay = data.participantdisplay,
			participantflag = Flags.CountryCode(data.participantflag),
			icon = data.icon,
			icondark = data.icondark,
			placement = data.placement or data.rank,
			definitestatus = data.definitestatus or data.bg,
			currentstatus = data.currentstatus or data.pbg,
			change = data.change,
			scoreboard = mw.ext.LiquipediaDB.lpdb_create_json{
				-- [won, draw, lost]
				match = StandingsStorage.verifyScoreBoardEntry(Table.mapValues(data.match or {}, tonumber)),
				overtime = StandingsStorage.verifyScoreBoardEntry(Table.mapValues(data.overtime or {}, tonumber)),
				game = StandingsStorage.verifyScoreBoardEntry(Table.mapValues(data.game or {}, tonumber)),
				points = tonumber(data.points),
				diff = tonumber(data.diff),
				buchholz = tonumber(data.buchholz),
			},
			standingsindex = tonumber(data.standingsindex),
			roundindex = tonumber(data.roundindex),
			section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
			parent = Variables.varDefault('tournament_parent', ''),
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(data.extradata or {})
		}
	)
end

---@deprecated
function StandingsStorage.verifyScoreBoardEntry(entry)
	-- A valid scoreboard entry must have 3 values in an array
	if #entry ~= 3 then
		return SCOREBOARD_LEGACY_FALLBACK
	end
	return entry
end

function StandingsStorage.fromTemplateHeader(frame)
	local data = Arguments.getArgs(frame)

	if not data.standingsindex then
		return
	end

	return StandingsStorage.table(data)
end

function StandingsStorage.fromTemplateEntry(frame)
	local data = Arguments.getArgs(frame)

	if not data.standingsindex or not data.roundindex or not data.placement then
		return
	end
	if not data.team and not data.player then
		return
	end

	local date = Variables.varDefault('tournament_startdate', Variables.varDefault('tournament_enddate'))

	local opponentArgs
	if data.opponent then
		opponentArgs = Json.parseIfString(data.opponent)
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

		opponentArgs = {type = 'team'}

		if team then
			opponentArgs.team = team.templatename

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
	elseif data.player then
		-- TODO: sanity checks and parse flag
		-- TODO: handle more input cases
		data.participant, data.participantdisplay = string.match(data.player, '%[%[([^|]-)|([^|]-)%]%]')
		opponentArgs = {link = data.participant, name = data.participantdisplay}
	end

	data.opponent = Opponent.resolve(Opponent.readOpponentArgs(opponentArgs) or Opponent.tbd(), date)

	data.match = {w = data.win_m, d = data.tie_m, l = data.lose_m}
	data.game = {w = data.win_g, d = data.tie_g, l = data.lose_g}
	StandingsStorage.entry(data, data.standingsindex)

	data.match = {data.win_m, data.tie_m, data.lose_m}
	data.game = {data.win_g, data.tie_g, data.lose_g}
	StandingsStorage.runLegacy(data.standingsindex, data)
end

-- Legacy input
function StandingsStorage.fromTemplate(frame)
	return StandingsStorage.fromTemplateEntry(frame)
end

return StandingsStorage
