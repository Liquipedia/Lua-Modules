---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local StandingsStorage = {}

function StandingsStorage.run(index, data)
	mw.ext.LiquipediaDB.lpdb_standing(
		'standing_' .. data.standingsindex .. '_' .. data.itemindex,
		{
			title = data.title,
			tournament = data.tournament,
			participant = data.participant,
			participantdisplay = data.participantdisplay,
			participantflag = data.participantflag,
			icon = data.icon,
			placement = data.placement or data.rank,
			definitestatus = data.definitestatus or data.bg,
			currentstatus = data.currentstatus or data.pbg,
			change = data.change,
			scoreboard = mw.ext.LiquipediaDB.lpdb_create_json({
				match = data.match, -- [won, draw, lost]
				overtime = data.overtime, -- [won, draw, lost]
				points = data.points,
			}),
			standingsindex = data.standingsindex,
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({data.extradata or {}})
		}
	)
end

return StandingsStorage
