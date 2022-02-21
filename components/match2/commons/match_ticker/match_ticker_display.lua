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

--classes here step by step



MatchTickerDisplay.Header = Header
MatchTickerDisplay.Match = Match
MatchTickerDisplay.UpperRow = UpperRow
MatchTickerDisplay.LowerRow = LowerRow
MatchTickerDisplay.Versus = Versus
MatchTickerDisplay.Wrapper = Wrapper
MatchTickerDisplay.HelperFunctions = HelperFunctions

return MatchTickerDisplay
