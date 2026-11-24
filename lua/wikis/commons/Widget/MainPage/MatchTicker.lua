---
-- @Liquipedia
-- page=Module:Widget/MainPage/MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/FilterableContainer')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

local defaultProps = {
	matchesPortal = 'Liquipedia:Matches',
	showMatchesPortal = true,
}

---@class MainPageMatchTickerProps
---@field matchesPortal string?
---@field displayGameIcons boolean?
---@field showMatchesPortal boolean?
---@field filterGroupPrefix string? if set, renders its own filter popover with this prefix

---@param props MainPageMatchTickerProps
---@return Renderable[]
local function MainPageMatchTicker(props)
	return {
		MatchTickerContainer{
			displayGameIcons = props.displayGameIcons,
			filterGroupPrefix = props.filterGroupPrefix,
			showFilterButtons = props.filterGroupPrefix ~= nil,
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
		} or nil,
	}
end

return Component.component(MainPageMatchTicker, defaultProps)
