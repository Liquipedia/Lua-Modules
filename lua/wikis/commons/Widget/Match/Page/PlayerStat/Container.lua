---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerStat/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPagePlayerStatContainerParameters
---@field columns integer
---@field children (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPagePlayerStatContainer: Widget
---@operator call(MatchPagePlayerStatContainerParameters): MatchPagePlayerStatContainer
---@field props MatchPagePlayerStatContainerParameters
local MatchPagePlayerStatContainer = Class.new(Widget)
MatchPagePlayerStatContainer.defaultProps = {
	columns = 6
}

---@return Widget
function MatchPagePlayerStatContainer:render()
	return Div{
		classes = {'match-bm-players-player-stats-container'},
		children = Div{
			classes = {
				'match-bm-players-player-stats',
				'match-bm-players-player-stats--col-' .. self.props.columns
			},
			children = self.props.children
		}
	}
end

return MatchPagePlayerStatContainer
