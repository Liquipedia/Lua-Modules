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

--classes here step by step



MatchTickerDisplay.Header = Header
MatchTickerDisplay.Match = Match
MatchTickerDisplay.UpperRow = UpperRow
MatchTickerDisplay.LowerRow = LowerRow
MatchTickerDisplay.Versus = Versus
MatchTickerDisplay.Wrapper = Wrapper
MatchTickerDisplay.HelperFunctions = HelperFunctions

return MatchTickerDisplay
