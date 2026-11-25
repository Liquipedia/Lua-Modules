---
-- @Liquipedia
-- page=Module:Widget/MainPage/MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/FilterableContainer')

local Component = Lua.import('Module:Widget/Component')
local FilterButtons = Lua.import('Module:Widget/FilterButtons')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local defaultProps = {
	matchesPortal = 'Liquipedia:Matches',
	showMatchesPortal = true,
}

---@class MainPageMatchTickerProps
---@field matchesPortal string?
---@field displayGameIcons boolean?
---@field showMatchesPortal boolean?
---@field filterGroupPrefix string? if set, the ticker renders its own filter buttons using this filter group prefix;
---otherwise it is controlled by the default filter buttons placed elsewhere on the page

---@param props MainPageMatchTickerProps
---@return Renderable[]
local function MainPageMatchTicker(props)
	return WidgetUtil.collect(
		props.filterGroupPrefix and Html.Div{
			css = {width = '100%', ['margin-bottom'] = '0.5rem'},
			children = FilterButtons{filterGroupPrefix = props.filterGroupPrefix},
		} or nil,
		MatchTickerContainer{
			displayGameIcons = props.displayGameIcons,
			filterGroupPrefix = props.filterGroupPrefix,
		},
		props.showMatchesPortal and Html.Div{
			css = {
				['white-space'] = 'nowrap',
				display = 'block',
				margin = '0 10px',
				['font-size'] = '15px',
				['font-style'] = 'italic',
				['text-align'] = 'center',
				padding = '0.5rem 1rem',
			},
			children = Html.Div{
				classes = {'mobile-only'},
				children = Link{ children = 'See more matches', link = props.matchesPortal}
			}
		} or nil
	)
end

return Component.component(MainPageMatchTicker, defaultProps)
