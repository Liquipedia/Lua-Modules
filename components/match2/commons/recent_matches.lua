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
local _DEFAULT_ICON = 'InfoboxIcon_Tournament.png'
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
	local query = RecentMatches.buildQuery(args)
	local order = RecentMatches.buildOrder(args)
	local limit = tonumber(args.limit or 20) or 20

	local data = RecentMatches._getData(conditions, limit, query, order)

	if not data then
		return mw.html.create('div')
			:addClass('text-center')
			:wikitext('<br/>No Matches found<br/><br/>')
	end

	local display = mw.html.create('div')

	for _, item in ipairs(data) do
		display:node(RecentMatches._row(item))
	end

	return display
end

function RecentMatches._displayOpponentScore(score, isWinner)
	return (isWinner and '<b>' or '')
		.. score
		.. (isWinner and '</b>' or '')
end

function RecentMatches._getData(conditions, limit, query, order)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		order = order,
		query = query,
		limit = limit
	})

	if type(data[1]) == 'table' then
		return data
	end
	mw.logObject(data)
end

function RecentMatches._row(data)
	local winner = tonumber(data.winner or 0) or 0
	local tableClass = RecentMatches.getTableClass(winner, data.publishertier or '')

	local opponentLeft = data.match2opponents[1]
	local opponentRight = data.match2opponents[2]

	if
		RecentMatches.checkForInelligableOpponent(opponentLeft) or
		RecentMatches.checkForInelligableOpponent(opponentRight)
	then
		return ''
	end

	local versus = RecentMatches.versus(opponentLeft, opponentRight, winner, data.bestof)

	-- clean opponentData for display
	opponentLeft = Opponent.fromMatch2Record(opponentLeft)
	opponentRight = Opponent.fromMatch2Record(opponentRight)

	-- get OpponentDisplays
	opponentLeft = OpponentDisplay.InlineOpponent{opponent = opponentLeft}
	opponentRight = OpponentDisplay.InlineOpponent{opponent = opponentRight, flip = true}

	local lowerRow = mw.html.create('span')
		:node(RecentMatches.countdownDisplay(data))
		:node(RecentMatches.tournamentDisplay(data))

	local output = mw.html.create('table')
		:addClass(tableClass)
	output:tag('tr')
		:tag('td')
			:cssText(winner == 1 and 'font-weight:bold;' or '')
			:addClass('team-left')
			:node(opponentLeft)
		:tag('td')
			:addClass('versus')
			:node(versus)
		:tag('td')
			:cssText(winner == 2 and 'font-weight:bold;' or '')
			:addClass('team-right')
			:node(opponentRight)
	output:tag('tr')
		:tag('td')
			:addClass('match-filler')
			:attr('colspan', 3)
			:node(lowerRow)

	return output
end

-- overridable functions
function RecentMatches.getTableClass(winner, publishertier)
	local tableClass = 'wikitable wikitable-striped infobox_matches_content recent-matches-'

	if winner == 1 then
		tableClass = tableClass .. 'left'
	elseif winner == 2 then
		tableClass = tableClass .. 'right'
	else
		tableClass = tableClass .. 'draw'
	end

	if String.isNotEmpty(publishertier) then
		tableClass = tableClass .. '-publishertier'
	end

	return tableClass
end

function RecentMatches.checkForInelligableOpponent(opponent)
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return Table.includes(_INVALID_OPPONENTS, name)
		or Table.includes(_INVALID_OPPONENTS, template)
		or (String.isEmpty(name) and String.isEmpty(template))
end

function RecentMatches.tournamentDisplay(data)
	local icon = String.isNotEmpty(data.icon) and data.icon or _DEFAULT_ICON
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

	return tournamentDisplay
end

function RecentMatches.countdownDisplay(data)
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

	return countdownDisplay
end

function RecentMatches.requireOpponentModules()
	return Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true}),
		Lua.import('Module:Opponent', {requireDevIfEnabled = true})
end

function RecentMatches.buildOrder(args)
	return 'date desc, liquipediatier asc, tournament asc'
end

function RecentMatches.buildQuery(args)
	local queryColumns = {
		'match2opponents',
		'winner',
		'resulttype',
		'pagename',
		'tournament',
		'tickername',
		'icon',
		'date',
		'publishertier',
		'vod',
		'extradata',
		'parent',
		--'icondark',
		--readd this once it is fixed in lpdb
	}
	return table.concat(queryColumns, ', ')
end

function RecentMatches.buildConditions(args)
	return '[[dateexact::1]] AND [[finished::1]] AND [[date::<' .. _CURRENT_DATE_STAMP .. ']]'
end

function RecentMatches.versus(opponentLeft, opponentRight, winner, _)
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
