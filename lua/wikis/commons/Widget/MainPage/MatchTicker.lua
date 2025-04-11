---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchTicker: Widget
---@field props { matchesPortal: string? }
---@operator call(table): MatchTicker
local MatchTicker = Class.new(Widget)
MatchTicker.defaultProps = {
	matchesPortal = 'Liquipedia:Matches'
}

---@return Widget[]
function MatchTicker:render()
	return WidgetUtil.collect(
		MatchTickerContainer{},
		HtmlWidgets.Div{
			css = {
				['white-space'] = 'nowrap',
				display = 'block',
				margin = '0 10px',
				['font-size'] = '15px',
				['font-style'] = 'italic',
				['text-align'] = 'center',
			},
			children = { Link{ children = 'See more matches', link = self.props.matchesPortal} }
		}
	)
end

return MatchTicker
