---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker
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
local Logic = require("Module:Logic")
local Variables = require("Module:Variables")
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')

local OpponentDisplay, Opponent

local _CURRENT_DATE_STAMP = os.date('!%Y-%m-%d %H:%M')
local _ABBR_UTC = '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
local _SCORE_STATUS = 'S'
local _STATUS_RECENT = 'recent'
local _STATUS_ONGOING = 'ongoing'
local _STATUS_UPCOMING = 'upcoming'
local _DISPLAY_MODE_PLAYER = 'player'
local _DISPLAY_MODE_TEAM = 'team'
local _DISPLAY_MODE_TOURNAMENT = 'tournament'
local _DISPLAY_MODE_DEFAULT = 'default'
local _DEFAULT_ICON = 'InfoboxIcon_Tournament.png'
local _LIMIT_INCREASE = 20

local _lastMatchWasTbdVsTbd = false

local Matches = {}

-- main entry point
function Matches.run(args)
	OpponentDisplay, Opponent = Matches.requireOpponentModules()
	args = args or {}

	local displayMode, participant = Matches.displayMode(args)

	local status
	if Logic.readBool(args.recent) then
		status = _STATUS_RECENT
	elseif Logic.readBool(args.ongoing) then
		status = _STATUS_ONGOING
	else
		status = _STATUS_UPCOMING
	end

	local conditions = Matches._buildConditions(args, status, displayMode, participant)
	local query = Matches.buildQuery(args)
	local order = Matches.buildOrder(args, status)
	local limit = tonumber(args.limit or 20) or 20

	local data = Matches._getData(conditions, limit, query, order)

	--option to show upcoming and ongoing matches
	local status2
	local data2
	local limit2
	if status == _STATUS_ONGOING and Logic.readBool(args.upcoming) then
		status2 = _STATUS_UPCOMING
		limit2 = tonumber(args.limit2 or 20) or 20
		conditions = Matches._buildConditions(args, status2, displayMode, participant)
		data2 = Matches._getData(conditions, limit2, query, order)
		if data2 then
			args.headerText = 'Upcoming matches'
		end
	end

	if not data and not data2 then
		return ''
	end

	local header = Matches.header(args, displayMode, status)
	local innerWrapper = Matches.innerWrapper(args, displayMode)
	innerWrapper:node(header)

	local matchIndex = 1
	data = data or {}
	while data[matchIndex] and matchIndex <= limit do
		innerWrapper:node(Matches._row(data[matchIndex], status, displayMode, participant))
		matchIndex = matchIndex + 1
	end

	if data2 then
		local totalLimit = tonumber(args.totalLimit or '') or (limit + limit2)
		local matchIndex2 = 1
		while data2[matchIndex2] and matchIndex2 <= limit2 and matchIndex < totalLimit do
			innerWrapper:node(Matches._row(data2[matchIndex2], status2, displayMode, participant))
			matchIndex2 = matchIndex2 + 1
			matchIndex = matchIndex + 1
		end
	end

	return Matches.outerWrapper(innerWrapper, args, displayMode)
end

-- overridable
function Matches.header(args, displayMode, status)
	if Logic.readBool(args.noHeader) or displayMode == _DISPLAY_MODE_DEFAULT then
		return ''
	end

	local headerText = args.headerText
	if String.isEmpty(headerText) then
		headerText = string.gsub(status, '^%l', string.upper)
		headerText = headerText .. ' matches'
	end
	
	return mw.html.create('div')
		:addClass('infobox-header wiki-backgroundcolor-light')
		:wikitext(headerText)
end

-- overridable
function Matches.innerWrapper(args, displayMode)
	local innerWrapper = mw.html.create('div')
	if displayMode == _DISPLAY_MODE_TOURNAMENT and not Logic.readBool(args.noWrapper) then
		innerWrapper:addClass('fo-nttax-infobox wiki-bordercolor-light')
	end
	
	return innerWrapper
end

-- overridable
function Matches.outerWrapper(innerWrapper, args, displayMode)
	if displayMode == _DISPLAY_MODE_TOURNAMENT and not Logic.readBool(args.noWrapper) then
		local game = Variables.varDefault('tournament_game', '')
		return mw.html.create('div')
			:addClass('fo-nttax-infobox-wrapper infobox-' .. game)
			:node(innerWrapper)
	end

	return innerWrapper
end

-- overridable
function Matches.requireOpponentModules()
	return Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true}),
		Lua.import('Module:Opponent', {requireDevIfEnabled = true})
end

-- overridable
function Matches.displayMode(args)
	local displayMode
	local participant

	if String.isNotEmpty(args.player) then
		displayMode = _DISPLAY_MODE_PLAYER
		participant = mw.ext.TeamLiquidIntegration.resolve_redirect(args.player)
	elseif String.isNotEmpty(args.team) then
		displayMode = _DISPLAY_MODE_TEAM
		participant = mw.ext.TeamLiquidIntegration.resolve_redirect(args.team)
	elseif String.isNotEmpty(args.tournament) or String.isNotEmpty(args.tournament1) then
		displayMode = _DISPLAY_MODE_TOURNAMENT
	else
		displayMode = _DISPLAY_MODE_DEFAULT
	end

	return displayMode, participant
end

-- overridable
function Matches.ongoingTimeEndStamp()
	local hoursUntilExpire = 2
	local secondsUntilExpire = hoursUntilExpire * 60 * 60
	return os.date("!%Y-%m-%d %H:%M", os.time(os.date("!*t")) - secondsUntilExpire)
end

function Matches._buildConditions(args, status, displayMode, participant)
	local conditions = {
		'[[dateexact::1]]',
	}

	if status == _STATUS_RECENT then
		table.insert(conditions, '[[finished::1]]')
		table.insert(conditions, '[[date::<' .. _CURRENT_DATE_STAMP .. ']]')
	elseif status == _STATUS_ONGOING then
		table.insert(conditions, '[[finished::0]]')
		table.insert(conditions, '[[date::<' .. _CURRENT_DATE_STAMP .. ']]')
		table.insert(conditions, '[[date::<' .. _CURRENT_DATE_STAMP .. ']]')
		table.insert(conditions, '[[date::>' .. Matches.ongoingTimeEndStamp() .. ']]')
	else
		table.insert(conditions, '[[finished::0]]')
		table.insert(conditions, '[[date::>' .. _CURRENT_DATE_STAMP .. ']]')
	end

	if displayMode == _DISPLAY_MODE_TEAM then
		table.insert(conditions, '[[opponent::' .. participant .. ']]')
	elseif displayMode == _DISPLAY_MODE_PLAYER then
		table.insert(conditions, '[[player::' .. participant .. ']]')
	end

	local tournamentConditions = {}
	local tournament = args.tournament or args.tournament1
	local tournamentIndex = 1
	while String.isNotEmpty(tournament) do
		tournament = mw.ext.TeamLiquidIntegration.resolve_redirect(tournament)
		tournament = string.gsub(tournament, '%s', '_')
		table.insert(
			tournamentConditions,
			'[[pagename::' .. tournament .. ']]'
		)
		tournamentIndex = tournamentIndex + 1
		tournament = args[_DISPLAY_MODE_TOURNAMENT .. tournamentIndex]
	end
	if not Table.isEmpty(tournamentConditions) then
		table.insert(
			conditions,
			'(' .. table.concat(tournamentConditions, ' OR ') .. ')'
		)
	end

	Matches.adjustConditions(conditions, args, status, displayMode)

	return table.concat(conditions, ' AND ')
end

-- overridable
function Matches.buildOrder(args, status)
	if status == _STATUS_RECENT then
		return 'date desc, liquipediatier asc, tournament asc'
	else
		return 'date asc, liquipediatier asc, tournament asc'
	end
end

-- overridable
function Matches.buildQuery(args)
	local queryColumns = {
		'match2opponents',
		'winner',
		'pagename',
		_DISPLAY_MODE_TOURNAMENT,
		'tickername',
		'icon',
		'date',
		'publishertier',
		'vod',
		'stream',
		'extradata',
		'parent',
		'finished',
		'bestof',
		--'icondark',
		--readd this once it is fixed in lpdb
	}

	return table.concat(queryColumns, ', ')
end

function Matches._getData(conditions, limit, query, order)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		order = order,
		query = query,
		limit = limit + _LIMIT_INCREASE
		-- increase the limit in case we have matches with
		-- a inelligable opponent
	})

	if type(data[1]) == 'table' then
		return data
	end
end

-- main display component
function Matches._row(data, status, displayMode, participant)
	-- workaround for a lpdb bug
	-- remove when it is fixed
	MatchGroupWorkaround.applyPlayerBugWorkaround(data)

	-- if we have a display on team or player pages
	-- we want the participant (or the participants team)
	-- always on the left of the display
	if participant then
		data = Matches._orderOpponents(data, participant, displayMode)
	end

	local winner = tonumber(data.winner or 0) or 0
	data.winner = winner

	local opponentLeft = data.match2opponents[1]
	local opponentRight = data.match2opponents[2]

	if Matches._checkForInelligableMatches(opponentLeft, opponentRight, status) then
		return ''
	end

	local tableClass = Matches.getTableClass(data, status, displayMode)

	local versus = Matches.versus(
		opponentLeft,
		opponentRight,
		winner,
		data.bestof,
		Logic.readBool(data.finished),
		status
	)

	-- clean opponentData for display
	opponentLeft = Opponent.fromMatch2Record(opponentLeft)
	opponentRight = Opponent.fromMatch2Record(opponentRight)

	-- get OpponentDisplays
	opponentLeft = OpponentDisplay.InlineOpponent{
		opponent = opponentLeft,
		teamStyle = 'short',
	}
	opponentRight = OpponentDisplay.InlineOpponent{
		opponent = opponentRight,
		teamStyle = 'short',
		flip = true,
	}

	local upperRow = Matches._upperRow(opponentLeft, versus, opponentRight, winner, status, displayMode, data)
	local lowerRow = Matches._lowerRow(data, status)

	return mw.html.create('table')
		:addClass(tableClass)
		:node(upperRow)
		:node(lowerRow)
end

function Matches._orderOpponents(data, participant, displayMode)
	local hasToSwitch

	if displayMode == _DISPLAY_MODE_TEAM then
		if data.match2opponents[1].name ~= participant then
			hasToSwitch = true
		end
	else
		local players = data.match2opponents[1].match2players
		for _, player in pairs(players) do
			if player.name == participant then
				hasToSwitch = true
				break
			end
		end
	end

	if hasToSwitch then
		local tempOpponent = data.match2opponents[1]
		data.match2opponents[1] = data.match2opponents[2]
		data.match2opponents[2] = tempOpponent
		-- since we flipped the opponents we now also have to flip the winner
		data.winner = data.winner
		if data.winner == 1 then
			data.winner = 2
		elseif data.winner == 2 then
			data.winner = 1
		end
	end

	return data
end

function Matches._checkForInelligableMatches(opponent1, opponent2, status)
	return Matches._checkForTbdMatches(opponent1, opponent2)
		or Matches._checkForInelligableOpponent(opponent1, status)
		or Matches._checkForInelligableOpponent(opponent2, status)
		or (isTbdMatch and _lastMatchWasTbdVsTbd)
end

function Matches._checkForInelligableOpponent(opponent, status)
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return Table.includes(Matches.invalidOpponents(status), name)
		or Table.includes(Matches.invalidOpponents(status), template)
		or (String.isEmpty(name) and String.isEmpty(template))
end

function Matches._checkForTbdMatches(opponent1, opponent2)
	local isTbdMatch  = Matches._opponentIsTbd(opponent1) and Matches._opponentIsTbd(opponent2)
	if isTbdMatch then
		isTbdMatch = _lastMatchWasTbdVsTbd
		_lastMatchWasTbdVsTbd = true
	else
		_lastMatchWasTbdVsTbd = false
	end
	return isTbdMatch
end

function Matches._opponentIsTbd(opponent)
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return string.lower(opponent.name or '') == Matches.tbdIdentifier()
		or string.lower(opponent.template or '') == Matches.tbdIdentifier()
end

-- overridable
function Matches.invalidOpponents(status)
	if status == _STATUS_RECENT then
		return {
			Matches.tbdIdentifier(),
			'bye',
		}
	else
		return {
			'bye',
		}
	end
end

-- overridable
function Matches.tbdIdentifier()
	return 'tbd'
end

-- overridable
function Matches.getTableClass(data, status, displayMode)
	local tableClass = 'wikitable wikitable-striped infobox_matches_content'

	if status == _STATUS_RECENT and displayMode == _DISPLAY_MODE_DEFAULT then
		if data.winner == 1 then
			tableClass = tableClass .. ' recent-matches-left'
		elseif data.winner == 2 then
			tableClass = tableClass .. ' recent-matches-right'
		else
			tableClass = tableClass .. ' recent-matches-draw'
		end
	end

	if String.isNotEmpty(data.publishertier) then
		tableClass = tableClass .. '-publishertier'
	end

	return tableClass
end

-- overridable
function Matches.versus(opponentLeft, opponentRight, winner, bestof, finished, status)
	local versus
	if status == _STATUS_UPCOMING then
		versus = 'vs.'
	else
		local leftScore = Matches.getOpponentScore(opponentLeft)
		local rightScore = Matches.getOpponentScore(opponentRight)

		versus = Matches.displayOpponentScore(leftScore, finished and winner == 1)
			.. ':'
			.. Matches.displayOpponentScore(rightScore, finished and winner == 2)
	end

	local bestof = tonumber(bestof or '')
	if bestof and status ~= _STATUS_RECENT then
		local bestofDisplay = mw.html.create('abbr')
			:attr('title', 'Best of ' .. bestof)
			:wikitext('Bo' .. bestof)

		local upperVersus = mw.html.create('div')
			:css('line-height', '1.1')
			:node(versus)

		local lowerVersus = mw.html.create('div')
			:css('font-size', '80%')
			:css('padding-bottom', '1px')
			:wikitext('(')
			:node(bestofDisplay)
			:wikitext(')')

		versus = mw.html.create('div')
			:node(upperVersus)
			:node(lowerVersus)
	end

	return versus
end

-- overridable
function Matches.getOpponentScore(opponent)
	local score
	if opponent.status == _SCORE_STATUS then
		score = opponent.score
	else
		score = opponent.status or ''
	end

	return score
end

-- overridable
function Matches.displayOpponentScore(score, isWinner)
	return (isWinner and '<b>' or '')
		.. score
		.. (isWinner and '</b>' or '')
end

function Matches._upperRow(opponentLeft, versus, opponentRight, winner, status, displayMode, data)
	local tdLeft = mw.html.create('td')
		:addClass('team-left')
		:node(opponentLeft)
	if winner == 1 then
		tdLeft:css('font-weight', 'bold')
	end
	local tdMiddle = mw.html.create('td')
		:addClass('versus')
		:node(versus)
	local tdRight = mw.html.create('td')
		:addClass('team-right')
		:node(opponentRight)
	if winner == 2 then
		tdRight:css('font-weight', 'bold')
	end

	local upperRow = mw.html.create('tr')
		:node(tdLeft)
		:node(tdMiddle)
		:node(tdRight)

	if
		status == _STATUS_RECENT and (
			displayMode == _DISPLAY_MODE_PLAYER or
			displayMode == _DISPLAY_MODE_TEAM
		)
	then
		if winner == 1 then
			upperRow:addClass('bg-win')
		elseif winner == 2 then
			upperRow:addClass('bg-down')
		else
			upperRow:addClass('bg-draw')
		end
	end

	upperRow = Matches.addUpperRowClass(upperRow, status, displayMode, data)

	return upperRow
end

function Matches.addUpperRowClass(upperRow, status, displayMode, data)
	return upperRow
end

function Matches._lowerRow(data, status)
	return mw.html.create('tr')
		:tag('td')
			:addClass('match-filler')
			:attr('colspan', 3)
			:node(mw.html.create('span')
				:node(Matches.countdownDisplay(data, status))
				:node(Matches.tournamentDisplay(data))
			)
end

-- overridable
function Matches.countdownDisplay(data, status)
	local finished = data.finished == 1 and 'true'
	--local date = mw.getContentLanguage():formatDate( 'F j, Y - G:i', data.date )
	local countdownArgs = {
		finished = finished,
		date = data.date .. _ABBR_UTC,
		separator = '&#8203;',
	}
	if status == _STATUS_RECENT then
		countdownArgs.rawdatetime = 'true'
	else
		countdownArgs.rawcountdown = 'true'
		for key, item in pairs(data.stream or {}) do
			countdownArgs[key] = item
		end
	end

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:css('font-size', '11px')
		:node(Countdown._create(countdownArgs))
		:node('&nbsp;&nbsp;')

	if status == _STATUS_RECENT and String.isNotEmpty(data.vod) then
		countdownDisplay:node(VodLink.display{vod = data.vod})
	end

	return countdownDisplay
end

-- overridable
function Matches.tournamentDisplay(data)
	local icon = String.isNotEmpty(data.icon) and data.icon or _DEFAULT_ICON
	local iconDark = String.isNotEmpty(data.icondark) and data.icondark or icon
	local displayName = String.isNotEmpty(data.tickername) and data.tickername or data.tournament
	local link = String.isNotEmpty(data.parent) and data.parent or data.pagename

	local tournamentDisplay = mw.html.create('div')
		:css('min-width', '150px')
		:css('max-width', '170px')
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
			:css('max-width', '145px')
			:css('vertical-align', 'middle')
			:css('white-space', 'nowrap')
			:css('font-size', '11px')
			:css('height', '16px')
			:css('margin-top', '3px')
			:css('float', 'right')
			:wikitext('[[' .. link .. '|' .. displayName .. ']]&nbsp;&nbsp;')
		)

	return tournamentDisplay
end

return Class.export(Matches)
