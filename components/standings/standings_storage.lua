---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Flags = require('Module:Flags')
local Variables = require('Module:Variables')

local StandingsStorage = {}

function StandingsStorage.run(index, data)
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
			scoreboard = mw.ext.LiquipediaDB.lpdb_create_json({
				match = data.match, -- [won, draw, lost]
				overtime = data.overtime, -- [won, draw, lost]
				game = data.game, -- [won, draw, lost]
				points = data.points,
				diff = data.diff,
				buchholz = data.buchholz,
			}),
			standingsindex = data.standingsindex,
			section = Variables.varDefault('last_heading', ''):gsub('<.->', ''),
			roundindex = data.roundindex,
			parent = Variables.varDefault('tournament_parent', ''),
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(data.extradata or {})
		}
	)
end

function StandingsStorage.fromTemplate(frame)
	local data = Arguments.getArgs(frame)

	if not data.standingsindex or not data.roundindex or not data.placement then
		return
	end
	if not data.team and not data.player then
		return
	end

	if data.team then
		-- attempts to find [[teamPage|teamDisplay]] and skips images (images have multiple |)
		local teamPage = string.match(data.team, '%[%[([^|]-)|[^|]-%]%]')
		local date = Variables.varDefaultMulti('tournament_startdate', 'tournament_enddate', nil)
		local team

		-- Input contains an actual team
		if data.team and mw.ext.TeamTemplate.teamexists(data.team) then
			team = mw.ext.TeamTemplate.raw(data.team, date)
		-- Input is link (possiblity with icon etc), and we managed to parse it
		elseif teamPage and mw.ext.TeamTemplate.teamexists(teamPage) then
			team = mw.ext.TeamTemplate.raw(teamPage, date)
		end

		if team then
			data.participant = team.page
			data.participantdisplay = team.name
			data.icon = team.image
			data.icondark = team.imagedark
		else
			data.participant = 'tbd'
			data.participantdisplay = 'TBD'
		end
	elseif data.player then
		data.participant, data.participantdisplay = string.match(data.player, '%[%[([^|]-)|([^|]-)%]%]')
		-- TODO: sanity checks and parse flag
		-- TODO: handle more input cases
	end

	data.match = {data.win_m, data.tie_m, data.lose_m}
	data.game = {data.win_g, data.tie_g, data.lose_g}
	return StandingsStorage.run(data.placement, data)
end

return StandingsStorage
