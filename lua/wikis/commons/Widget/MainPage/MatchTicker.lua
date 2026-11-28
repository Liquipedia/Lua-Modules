---
-- @Liquipedia
-- page=Module:Widget/MainPage/MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/FilterableContainer')

local Component = Lua.import('Module:Widget/Component')

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
---@return VNode
local function MainPageMatchTicker(props)
	return MatchTickerContainer{
		displayGameIcons = props.displayGameIcons,
		filterGroupPrefix = props.filterGroupPrefix,
		showFilterButtons = props.filterGroupPrefix ~= nil,
		showAllLink = props.showMatchesPortal and props.matchesPortal or nil,
	}
end

return Component.component(MainPageMatchTicker, defaultProps)
