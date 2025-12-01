---
-- @Liquipedia
-- page=Module:MatchTicker/DisplayComponents/Entity
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local Carousel = Lua.import('Module:Widget/Basic/Carousel')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchCard = Lua.import('Module:Widget/Match/Card')
local Switch = Lua.import('Module:Widget/Switch')

---@class EntityMatchTickerMatch
---@operator call({config: MatchTickerConfig, match: table}): EntityMatchTickerMatch
---@field config MatchTickerConfig
---@field match table
local Match = Class.new(
	function(self, args)
		self.config = args.config
		self.match = args.match
	end
)

---@return Widget
function Match:create()
	return MatchCard{
		match = MatchGroupUtil.matchFromRecord(self.match),
		hideTournament = self.config.hideTournament,
		displayGameIcons = self.config.displayGameIcons,
		onlyHighlightOnValue = self.config.onlyHighlightOnValue,
		variant = 'vertical',
		gameData = {
			asGame = self.match.asGame,
			gameIds = self.match.asGameIndexes,
			map = self.match.map,
			mapDisplayName = self.match.extradata and self.match.extradata.displayname
		}
	}
end

---@class EntityMatchTickerContainer
---@operator call({config: MatchTickerConfig, matches: table[]}): EntityMatchTickerContainer
---@field config MatchTickerConfig
---@field matches table[]
local Container = Class.new(
	function(self, args)
		self.config = args.config
		self.matches = args.matches
	end
)

---@return Widget?
function Container:create()
	if not self.matches or #self.matches == 0 then
		return nil
	end

	local carousel = Carousel{
		children = Array.map(self.matches, function(match)
			return Match{config = self.config, match = match}:create()
		end),
		itemMinWidth = '18rem',
		gap = '0.5rem',
	}

	return HtmlWidgets.Div{
		css = {['margin-bottom'] = '1rem'},
		children = {
			HtmlWidgets.H2{
				css = {
					['font-size'] = '1.5rem',
					['font-weight'] = 'bold',
					color = 'var(--clr-primary)',
					['margin-bottom'] = '1rem',
				},
				children = 'Upcoming Matches',
			},
			Switch{
				label = 'Show countdown',
				switchGroup = 'countdown',
				storeValue = true,
				defaultActive = true,
				css = {margin = '1rem 0', ['justify-content'] = 'center'},
				content = carousel,
			},
		},
	}
end

return {
	Match = Match,
	Container = Container,
}
