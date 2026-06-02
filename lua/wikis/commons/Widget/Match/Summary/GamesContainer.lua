---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GamesContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')

---@class MatchSummaryGamesContainerProps
---@field children? Renderable|Renderable[]
---@field css? table<string, string|number>
---@field gamesSectionName? Renderable|Renderable[]
---@field gamesSectionResult? Renderable|Renderable[]

---@param props MatchSummaryGamesContainerProps
---@return VNode?
local function MatchSummaryGamesContainer(props)
	if Logic.isEmpty(props.children) then
		return
	elseif Logic.isEmpty(props.gamesSectionName) and Logic.isEmpty(props.gamesSectionResult) then
		return Html.Div{
			classes = {'brkts-popup-body-grid'},
			css = props.css,
			children = props.children,
		}
	end
	return GeneralCollapsible{
		titleWidget = Html.Div{
			classes = {
				'general-collapsible-default-header',
				'brkts-popup-body-grid-header'
			},
			children = {
				Html.Div{children = props.gamesSectionName},
				Html.Div{children = props.gamesSectionResult},
				CollapsibleToggle{},
			}
		},
		collapseAreaCss = props.css,
		collapseAreaClasses = {'brkts-popup-body-grid'},
		children = props.children,
		shouldCollapse = true,
	}
end

return Component.component(MatchSummaryGamesContainer)
