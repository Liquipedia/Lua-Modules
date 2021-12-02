---
-- @Liquipedia
-- wiki=commons
-- page=Module:RecentMatches
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local String = require('Module:StringUtils')
local Lua = require("Module:Lua")
local LeagueIcon = require("Module:LeagueIcon")
local VodLink = require("Module:VodLink")
local Table = require("Module:Table")

local OpponentDisplay, Opponent

local _CURRENT_DATE_STAMP = mw.getContentLanguage():formatDate('c')
local _ABBR_UTC = '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
local _SCORE_STATUS = 'S'
local _INVALID_OPPONENTS = {
	'tbd',
	'tba',
	'bye',
}

local RecentMatches = {}

function RecentMatches.run(args)
	OpponentDisplay, Opponent = RecentMatches.requireOpponentModules()
	args = args or {}
	local conditions = RecentMatches.buildConditions(args)
	local limit = tonumber(args.limit or 20) or 20

	local data = RecentMatches._getData(conditions, limit)

	if not data then
		return mw.html.create('div')
			:addClass('text-center')
			:wikitext('<br/>No Recent Results<br/><br/>')
	end

	local display = ''

	for _, item in ipairs(data) do
		display = display .. RecentMatches._row(item)
	end

	return display
end

function RecentMatches._displayOpponentScore(score, isWinner)
	return (isWinner and '<b>' or '')
		.. score
		.. (isWinner and '</b>' or '')
end

function RecentMatches._getData(conditions, limit)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		order = 'date desc, liquipediatier asc, tournament asc',
		query = 'match2opponents, winner, resulttype, pagename, tournament, '
			.. 'tickername, icon, date, publishertier, vod, extradata, parent',
			--readd icondark to the query once it is fixed in lpdb
		limit = limit
	})

	if type(data[1]) == 'table' then
		return data
	end
	mw.logObject(data)
end

function RecentMatches._getTableClass(winner, publishertier)
	local class = 'wikitable wikitable-striped infobox_matches_content recent-matches-'

	if winner == 1 then
		class = class .. 'left'
	elseif winner == 2 then
		class = class .. 'right'
	else
		class = class .. 'draw'
	end

	if String.isNotEmpty(publishertier) then
		class = class .. '-publishertier'
	end

	return class
end

function RecentMatches._checkForInelligableOpponent(opponent)
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return Table.includes(_INVALID_OPPONENTS, name)
		or Table.includes(_INVALID_OPPONENTS, template)
		or (String.isEmpty(name) and String.isEmpty(template))
end

function RecentMatches._row(data)
	local winner = tonumber(data.winner or 0) or 0
	local tableClass = RecentMatches._getTableClass(winner, data.publishertier or '')

	local output = mw.html.create('table')
		:addClass(tableClass)

	local opponentLeft = data.match2opponents[1]
	local opponentRight = data.match2opponents[2]

	if
		RecentMatches._checkForInelligableOpponent(opponentLeft) or
		RecentMatches._checkForInelligableOpponent(opponentRight)
	then
		return ''
	end

	local scoreDisplay = RecentMatches.scoreDisplay(opponentLeft, opponentRight, winner)

	-- clean opponentData for display
	opponentLeft = Opponent.fromMatch2Record(opponentLeft)
	opponentRight = Opponent.fromMatch2Record(opponentRight)

	-- get OpponentDisplays
	opponentLeft = OpponentDisplay.InlineOpponent{opponent = opponentLeft}
	opponentRight = OpponentDisplay.InlineOpponent{opponent = opponentRight, flip = true}

	local lowerRow = RecentMatches._lowerRow(data)

	output:tag('tr')
		:tag('td')
			:cssText(winner == 1 and 'font-weight:bold;' or '')
			:addClass('team-left')
			:node(opponentLeft)
		:tag('td')
			:addClass('versus')
			:node(scoreDisplay)
		:tag('td')
			:cssText(winner == 2 and 'font-weight:bold;' or '')
			:addClass('team-right')
			:node(opponentRight)
	:tag('tr')
		:tag('td')
			:addClass('match-filler')
			:attr('colspan', 3)
			:node(lowerRow)

	return tostring(output)
end

function RecentMatches._lowerRow(data)
	--countdown and vod stuff
	local date = mw.getContentLanguage():formatDate( 'F j, Y - G:i', data.date )
	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:css('font-size', '11px')
		:node(Countdown._create{
			rawdatetime = 'true',
			finished = 'true',
			date = date .. _ABBR_UTC,
			separator = '&#8203;',
		})
		:node('&nbsp;&nbsp;')
	if String.isNotEmpty(data.vod) then
		countdownDisplay:node(VodLink.display{vod = data.vod})
	end

	--tournament icon and link
	local icon = String.isNotEmpty(data.icon) and data.icon or 'InfoboxIcon_Tournament.png'
	local iconDark = String.isNotEmpty(data.icondark) and data.icondark or icon
	local displayName = String.isNotEmpty(data.tickername) and data.tickername or data.tournament
	local link = String.isNotEmpty(data.parent) and data.parent or data.pagename

	local tournamentDisplay = mw.html.create('div')
		:css('min-width', '175px')
		:css('max-width', '185px')
		:css('float', 'right')
		:css('white-space', 'nowrap')
		:node(mw.html.create('span')
			:css('float', 'right')
			:node(LeagueIcon.display{
				icon = icon,
				iconDark = iconDark,
				link = link,
				name = data.tournament,
				--size = '25px',
				options = {noTemplate = true},
			})
		)
		:node(mw.html.create('div')
			:css('overflow', 'hidden')
			:css('text-overflow', 'ellipsis')
			:css('max-width', '170px')
			:css('vertical-align', 'middle')
			:css('white-space', 'nowrap')
			:css('font-size', '11px')
			:css('height', '16px')
			:css('margin-top', '3px')
			:wikitext('[[' .. link .. '|' .. displayName .. ']]&nbsp;')
		)

	return mw.html.create('span')
		:node(countdownDisplay)
		:node(tournamentDisplay)
end

-- overridable functions
function RecentMatches.requireOpponentModules()
	return Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true}),
		Lua.import('Module:Opponent', {requireDevIfEnabled = true})
end

function RecentMatches.buildConditions(args)
	local featured = args.featured == 'true'

	local conditions = '[[dateexact::1]] AND [[finished::1]] AND [[date::<' .. _CURRENT_DATE_STAMP .. ']]'
	if featured then
		conditions = conditions .. ' AND [[publishertier::>]]'
	end

	return conditions
end

function RecentMatches.scoreDisplay(opponentLeft, opponentRight, winner)
	local leftScore = RecentMatches.getOpponentScore(opponentLeft)
	local rightScore = RecentMatches.getOpponentScore(opponentRight)

	local scoreDisplay = RecentMatches._displayOpponentScore(leftScore, winner == 1)
		.. ':'
		.. RecentMatches._displayOpponentScore(rightScore, winner == 2)

	return scoreDisplay
end

function RecentMatches.getOpponentScore(opponent)
	local score
	if opponent.status == _SCORE_STATUS then
		score = opponent.score
	else
		score = opponent.status or ''
	end

	return score
end

return Class.export(RecentMatches)
