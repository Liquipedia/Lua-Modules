---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds DisplayComponents for the MatchTicker modules

local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local LeagueIcon = require('Module:LeagueIcon')
local VodLink = require('Module:VodLink')
local HelperFunctions = Lua.import('Module:MatchTicker/Helpers', {requireDevIfEnabled = true})

local MatchTickerDisplay = Class.new()

local _LEFT_SIDE = 1
local _RIGHT_SIDE = 2
local _TBD = 'TBD'
local _SIDE_CLASS = {
	'left',
	'right',
}
local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2
local _TOURNAMENT_DEFAULT_ICON = 'InfoboxIcon_Tournament.png'
local _MATCH_FINISHED = 1
local _ABBR_UTC = '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'

MatchTickerDisplay.OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
MatchTickerDisplay.Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

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

function UpperRow:addOpponent(opponent, side, noLink)
	opponent = MatchTickerDisplay.Opponent.fromMatch2Record(opponent)
	local OpponentDisplay

	-- catch empty and 'TBD' opponents
	if HelperFunctions.opponentIsTbdOrEmpty(opponent) then
		OpponentDisplay = mw.html.create('i')
			:wikitext(_TBD)
	else
		OpponentDisplay = MatchTickerDisplay.OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = side == _LEFT_SIDE,
			showLink = not noLink
		}
	end

	self[side] = mw.html.create('td')
		:addClass('team-' .. (_SIDE_CLASS[side] or ''))
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

function UpperRow:create()
	if self.winnerValue and self[self.winnerValue] then
		self[self.winnerValue]:css('font-weight', 'bold')
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
	leftScore, leftScore2, hasScore2 = HelperFunctions.getOpponentScore(
		matchData.match2opponents[1],
		matchData.winner == _WINNER_LEFT
	)
	rightScore, rightScore2, hasScore2 = HelperFunctions.getOpponentScore(
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
				:addClass('versus-lower')
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

function LowerRow:countDown(matchData, countdownArgs)
	countdownArgs = countdownArgs or {}
	-- the countdown module needs the string
	countdownArgs.finished = matchData.finished == _MATCH_FINISHED and 'true'
	countdownArgs.date = matchData.date .. _ABBR_UTC

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:node(Countdown._create(countdownArgs))
		:node('&nbsp;&nbsp;')

	if String.isNotEmpty(matchData.vod) then
		countdownDisplay:node(VodLink.display{vod = matchData.vod})
	end

	self.countDownDisplay = countdownDisplay
	return self
end

function LowerRow:tournament(matchData)
	local icon = String.isNotEmpty(matchData.icon) and matchData.icon or _TOURNAMENT_DEFAULT_ICON
	local iconDark = String.isNotEmpty(matchData.icondark) and matchData.icondark or icon
	local link = String.isNotEmpty(matchData.parent) and matchData.parent or matchData.pagename
	local displayName = String.isNotEmpty(matchData.tickername) and matchData.tickername
		or String.isNotEmpty(matchData.tickername) and matchData.tournament
		or string.gsub(matchData.pagename, '_', ' ')

	local tournamentDisplay = mw.html.create('div')
		:addClass('tournament')
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
			:addClass('tournament-text')
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

MatchTickerDisplay.Header = Header
MatchTickerDisplay.Match = Match
MatchTickerDisplay.UpperRow = UpperRow
MatchTickerDisplay.LowerRow = LowerRow
MatchTickerDisplay.Versus = Versus
MatchTickerDisplay.Wrapper = Wrapper
MatchTickerDisplay.HelperFunctions = HelperFunctions

return MatchTickerDisplay
