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
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({data.extradata or {}})
		}
	)
end

function StandingsStorage.fromTemplate(frame)
	local data = Arguments.getArgs(frame)
	if not data.standingsindex or not data.roundindex or not data.placement then
		return
	end

	 -- finds [[page|display]] and skips images (images have multiple |)
	data.team = string.match(data.team, '%[%[([^|]-)|[^|]-%]%]')
	if data.team and mw.ext.TeamTemplate.teamexists(data.team) then
		local team = mw.ext.TeamTemplate.raw(data.team)
		data.participant = team.page
		data.participantdisplay = team.name
		data.participantflag = ''
		data.icon = team.image
		data.icondark = team.imagedark
	else
		data.participant = 'tbd'
		data.participantdisplay = 'TBD'
	end
	data.match = {data.win_m or 0, data.tie_m or 0, data.lost_m or 0}
	data.game = {data.win_g or 0, data.tie_g or 0, data.lost_g or 0}
	return StandingsStorage.run(data.placement, data)
end

return StandingsStorage
