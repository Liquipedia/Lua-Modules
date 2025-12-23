---
-- @Liquipedia
-- page=Module:MatchTicker/DisplayComponents/Entity
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local Carousel = Lua.import('Module:Widget/Basic/Carousel')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchCard = Lua.import('Module:Widget/Match/Card')
local Switch = Lua.import('Module:Widget/Switch')

---@class EntityMatchTickerMatch: MatchTickerMatchInterface
---@operator call({config: MatchTickerConfig, match: table}): EntityMatchTickerMatch
local MatchCardEntity = Class.new(
	function(self, args)
		self.config = args.config
		self.match = args.match
	end
)

---@return Widget
function MatchCardEntity:create()
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

---@class EntityMatchTickerContainer: MatchTickerContainerInterface
---@operator call({config: MatchTickerConfig, matches: table[]}): EntityMatchTickerContainer
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
			return MatchCardEntity{config = self.config, match = match}:create()
		end),
		itemWidth = '12.5rem',
		gap = '0.5rem',
	}

	return HtmlWidgets.Div{
		css = {['margin-bottom'] = '1rem'},
		children = {
			HtmlWidgets.H2{
				css = {border = 'unset'},
				children = I18n.translate('matchticker-upcoming-matches'),
			},
			Switch{
				label = 'Show countdown',
				switchGroup = 'countdown',
				storeValue = true,
				defaultActive = true,
				css = {margin = '0.75rem 0 1rem'},
				content = carousel,
			},
		},
	}
end

return {
	Match = MatchCardEntity,
	Container = Container,
}
