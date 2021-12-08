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
local Logic = require("Module:Logic")
local Table = require("Module:Table")

local MatchTicker = Class.new()

local _LIMIT_INCREASE = 20
local _DEFAULT_LIMIT = 20
local Lpdb = Class.new(
	function(self)
		self.queryColumns = {
			'match2opponents',
			'winner',
			'pagename',
			'tournament',
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
		self.orderValue = 'date asc, liquipediatier asc, tournament asc'
		self.limitValue = _DEFAULT_LIMIT + _LIMIT_INCREASE
	end
)

function Lpdb:addQueryColumn(queryColumn)
	table.insert(self.queryColumns, queryColumn)
	return self
end

function Lpdb:order(order)
	self.orderValue = order
	return self
end

function Lpdb:conditions(conditions)
	self.conditions = conditions
	return self
end

function Lpdb:limit(limit)
	-- increase the limit in case we have inelligable matches
	self.limitValue = limit + _LIMIT_INCREASE
	return self
end

function Lpdb:get()
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = self.conditions,
		order = self.orderValue,
		query = table.concat(self.queryColumns, ', '),
		limit = self.limitValue
	})

	if type(data[1]) == 'table' then
		return data
	end
end

local LpdbConditions = Class.new(
	function(self)
		self.conditions = {}
		self.connector = ' AND '
	end
)

function LpdbConditions:changeConnector(connector)
	self.connector = connector
	return self
end

function LpdbConditions:addCondition(condition)
	if String.isNotEmpty(condition) then
		table.insert(self.conditions, condition)
	end
	return self
end

local _CURRENT_DATE_STAMP = os.date('%Y-%m-%d %H:%M', os.time(os.date("!*t")))
MatchTicker.maximumLiveHoursOfMatches = 3
function LpdbConditions:addDefaultConditions(args)
	if not Logic.readBool(args.notExact) then
		table.insert(self.conditions, '[[dateexact::1]]')
	end
	if Logic.readBool(args.recent) then
		table.insert(self.conditions, '[[finished::1]]')
		table.insert(self.conditions, '[[date::<' .. _CURRENT_DATE_STAMP .. ']]')
	else
		table.insert(self.conditions, '[[finished::0]]')
		if Logic.readBool(args.ongoing) then
			local secondsLive = 60 * 60 * MatchTicker.maximumLiveHoursOfMatches
			local timeStamp = os.date("%Y-%m-%d %H:%M", os.time(os.date("!*t")) - secondsLive)
			table.insert(self.conditions, '[[date::>' .. timeStamp .. ']]')
			if not Logic.readBool(args.upcoming) then
				table.insert(self.conditions, '[[date::<' .. _CURRENT_DATE_STAMP .. ']]')
			end
		elseif Logic.readBool(args.upcoming) then
			table.insert(self.conditions, '[[date::>' .. _CURRENT_DATE_STAMP .. ']]')
		end
	end

	if String.isNotEmpty(args.team) then
		table.insert(self.conditions, '[[opponent::' .. args.team .. ']]')
	elseif String.isNotEmpty(args.player) then
		table.insert(self.conditions, '([[player::' .. args.player .. ']] OR [[opponent::' .. args.player .. ']])')
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
		tournament = args['tournament' .. tournamentIndex]
	end
	if not Table.isEmpty(tournamentConditions) then
		table.insert(
			self.conditions,
			'(' .. table.concat(tournamentConditions, ' OR ') .. ')'
		)
	end

	return self
end

function LpdbConditions:build()
	local conditions = table.concat(self.conditions, self.connector)
	if String.isEmpty(conditions) then
		error('No valid Conditions specified')
	end
	return conditions
end

local Header = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('infobox-header wiki-backgroundcolor-light')
	end
)

function Header:text(text)
	self.root:wikitext(text)
	return self
end

function Header:addClass(class)
	self.root:addClass(class)
	return self
end

function Header:create()
	return self.root
end

local Match = Class.new(
	function(self)
		self.root = mw.html.create('table')
			:addClass('wikitable wikitable-striped infobox_matches_content')
	end
)

function Match:addClass(class)
	self.root:addClass(class)
	return self
end

function Match:upperRow(upperRow)
	self.upperRow = upperRow
	return self
end

function Match:lowerRow(lowerRow)
	self.lowerRow = lowerRow
	return self
end

function Match:create()
	return self.root
		:node(self.upperRow)
		:node(self.lowerRow)
end

local UpperRow = Class.new(
	function(self)
		self.root = mw.html.create('tr')
	end
)

-- overridable if wikis have custom modules
MatchTicker.OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
MatchTicker.Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local _RIGHT_SIDE = 'right'
local _LEFT_SIDE = 'left'
local _TBD = 'TBD'

function UpperRow:addOpponent(opponent, side, noLink)
	opponent = MatchTicker.Opponent.fromMatch2Record(opponent)
	local OpponentDisplay

	-- catch empty and 'TBD' opponents
	if MatchTicker.opponentIsTbdOrEmpty(opponent) then
		OpponentDisplay = mw.html.create('i')
			:wikitext(_TBD)
	else
		OpponentDisplay = MatchTicker.OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = side == _LEFT_SIDE,
			showLink = not noLink
		}
	end

	self[side] = mw.html.create('td')
		:addClass('team-' .. side)
		:node(OpponentDisplay)

	return self
end

function UpperRow:addClass(class)
	self.root:addClass(class)
	return self
end

function UpperRow:versus(versus)
	self.versusDisplay = mw.html.create('td')
		:addClass('versus')
		:node(versus)
	return self
end

function UpperRow:winner(winner)
	self.winnerValue = winner
	return self
end

local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2

function UpperRow:create()
	if self.winnerValue == _WINNER_LEFT then
		self[_LEFT_SIDE]:css('font-weight', 'bold')
	elseif self.winnerValue == _WINNER_RIGHT then
		self[_RIGHT_SIDE]:css('font-weight', 'bold')
	end

	return self.root
		:node(self[_LEFT_SIDE])
		:node(self.versusDisplay)
		:node(self[_RIGHT_SIDE])
end

local Versus = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.text = 'vs.'
	end
)

function Versus:bestOf(bestOf)
	if String.isNotEmpty(bestOf) then
		self.bestOfDisplay = mw.html.create('abbr')
			:attr('title', 'Best of ' .. bestOf)
			:wikitext('Bo' .. bestOf)
	end
	return self
end

function Versus:score(matchData)
	local leftScore, leftScore2, hasScore2, rightScore, rightScore2
	leftScore, leftScore2, hasScore2 = MatchTicker.getOpponentScore(
		matchData.match2opponents[1],
		matchData.winner == _WINNER_LEFT
	)
	rightScore, rightScore2, hasScore2 = MatchTicker.getOpponentScore(
		matchData.match2opponents[2],
		matchData.winner == _WINNER_RIGHT,
		hasScore2
	)
	self.text = leftScore .. ':' .. rightScore

	if hasScore2 then
		self.score2 = leftScore2 .. ':' .. rightScore2
	end

	return self
end

function Versus:create()
	local lowerText, upperText
	if self.score2 then
		upperText = self.score2
		lowerText = self.text
	else
		upperText = self.text
		lowerText = self.bestOfDisplay
	end
	if lowerText then
		return self.root
			:node(mw.html.create('div')
				:css('line-height', '1.1')
				:node(upperText)
			)
			:node(mw.html.create('div')
				:css('font-size', '80%')
				:css('padding-bottom', '1px')
				:wikitext('(')
				:node(lowerText)
				:wikitext(')')
			)
	end
	return self.root:wikitext(self.text)
end

local LowerRow = Class.new(
	function(self)
		self.root = mw.html.create('tr')
		self.tournamentDisplay = ''
	end
)

function LowerRow:addClass(class)
	self.root:addClass(class)
	return self
end

local _MATCH_FINISHED = 1
local _ABBR_UTC = '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
function LowerRow:countDown(matchData, countdownArgs)
	countdownArgs = countdownArgs or {}
	-- the countdown module needs the string
	countdownArgs.finished = matchData.finished == _MATCH_FINISHED and 'true'
	countdownArgs.date = matchData.date .. _ABBR_UTC

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:css('font-size', '11px')
		:node(Countdown._create(countdownArgs))
		:node('&nbsp;&nbsp;')

	if String.isNotEmpty(matchData.vod) then
		countdownDisplay:node(VodLink.display{vod = matchData.vod})
	end

	self.countDownDisplay = countdownDisplay
	return self
end

local _DEFAULT_ICON = 'InfoboxIcon_Tournament.png'
function LowerRow:tournament(matchData)
	local icon = String.isNotEmpty(matchData.icon) and matchData.icon or _DEFAULT_ICON
	local iconDark = String.isNotEmpty(matchData.icondark) and matchData.icondark or icon
	local displayName = String.isNotEmpty(matchData.tickername) and matchData.tickername or matchData.tournament
	local link = String.isNotEmpty(matchData.parent) and matchData.parent or matchData.pagename

	local tournamentDisplay = mw.html.create('div')
		:css('min-width', '100px')
		:css('max-width', '155px')
		:css('float', 'right')
		:css('white-space', 'nowrap')
		:node(mw.html.create('span')
			:css('float', 'right')
			:node(LeagueIcon.display{
				icon = icon,
				iconDark = iconDark,
				link = link,
				name = matchData.tournament,
				options = {noTemplate = true},
			})
		)
		:node(mw.html.create('div')
			:css('overflow', 'hidden')
			:css('text-overflow', 'ellipsis')
			:css('max-width', '130px')
			:css('vertical-align', 'middle')
			:css('white-space', 'nowrap')
			:css('font-size', '11px')
			:css('height', '16px')
			:css('margin-top', '3px')
			:css('float', 'right')
			:wikitext('[[' .. link .. '|' .. displayName .. ']]&nbsp;&nbsp;')
		)

	self.tournamentDisplay = tournamentDisplay

	return self
end

function LowerRow:create()
	return self.root
		:node(mw.html.create('td')
			:addClass('match-filler')
			:attr('colspan', 3)
			:node(mw.html.create('span')
				:node(self.countDownDisplay)
				:node(self.tournamentDisplay)
			)
		)
end

local Wrapper = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.elements = {}
	end
)

function Wrapper:addElement(element, position)
	if position then
		table.insert(self.elements, position, element)
	else
		table.insert(self.elements, element)
	end
	return self
end

function Wrapper:addClass(class)
	self.root:addClass(class)
	return self
end

function Wrapper:addInnerWrapperClass(class)
	self.innerWrapperClass = class
	return self
end

function Wrapper:create()
	local innerWrapper = mw.html.create('div')
	if self.innerWrapperClass then
		innerWrapper:addClass(self.innerWrapperClass)
	end

	for _, element in ipairs(self.elements or {}) do
		innerWrapper:node(element)
	end

	return self.root:node(innerWrapper)
end

MatchTicker.Lpdb = Lpdb
MatchTicker.LpdbConditions = LpdbConditions
MatchTicker.Header = Header
MatchTicker.Match = Match
MatchTicker.UpperRow = UpperRow
MatchTicker.LowerRow = LowerRow
MatchTicker.Versus = Versus
MatchTicker.Wrapper = Wrapper

local _SCORE_STATUS = 'S'
function MatchTicker.getOpponentScore(opponent, isWinner, hasScore2)
	local score
	if opponent.status == _SCORE_STATUS then
		score = tonumber(opponent.score)
		if score == -1 then
			score = 0
		end
	else
		score = opponent.status or ''
	end
	if isWinner then
		score = '<b>' .. score .. '</b>'
	end

	local score2 = 0
	if type(opponent.extradata) == 'table' then
		score2 = tonumber(opponent.extradata.score2 or 0) or 0
	end
	if score2 > 0 then
		hasScore2 = true
		if isWinner then
			score = '<b>' .. score .. '</b>'
		end
	end

	return score, score2, hasScore2
end


local _DEFAULT_TBD_IDENTIFIER = 'tbd'
-- overridable value
MatchTicker.tbdIdentifier = _DEFAULT_TBD_IDENTIFIER
function MatchTicker.opponentIsTbdOrEmpty(opponent)
	local firstPlayer = (opponent.players or {})[1] or {}

	local listToCheck = {
		string.lower(firstPlayer.pageName or opponent.name or ''),
		string.lower(firstPlayer.displayName or ''),
		string.lower(opponent.template or ''),
	}

	return Table.includes(listToCheck, MatchTicker.tbdIdentifier)
		or Table.all(listToCheck, function(_, value) return String.isEmpty(value) end)
end

local _BYE_OPPONENT = 'bye'
function MatchTicker.isByeOpponent(opponent)
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return name == _BYE_OPPONENT
		or template == _BYE_OPPONENT
end

local _lastTournament
local _lastMatchWasTbd
function MatchTicker.checkForTbdMatches(opponent1, opponent2, currentTournament)
	local isTbdMatch  = MatchTicker.opponentIsTbdOrEmpty(opponent1) and MatchTicker.opponentIsTbdOrEmpty(opponent2)

	if isTbdMatch and _lastTournament == currentTournament then
		_lastMatchWasTbd = true
		isTbdMatch = _lastMatchWasTbd
	else
		isTbdMatch = false
		_lastMatchWasTbd = false
	end

	_lastTournament = currentTournament

	return isTbdMatch
end

return MatchTicker
