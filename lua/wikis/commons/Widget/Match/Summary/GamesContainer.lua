---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GamesContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryGamesContainerProps
---@field children? Renderable|Renderable[]
---@field css? table<string, string|number>
---@field gamesSectionName? Renderable|Renderable[]
---@field gamesSectionResult? Renderable|Renderable[]

---@class MatchSummaryGamesContainer: Widget
---@operator call(MatchSummaryGamesContainerProps): MatchSummaryGamesContainer
---@field props MatchSummaryGamesContainerProps
local MatchSummaryGamesContainer = Class.new(Widget)

---@return Widget?
function MatchSummaryGamesContainer:render()
	local props = self.props

	if Logic.isEmpty(props.children) then
		return
	elseif Logic.isEmpty(props.gamesSectionName) and Logic.isEmpty(props.gamesSectionResult) then
		return HtmlWidgets.Div{
			classes = {'brkts-popup-body-grid'},
			css = props.css,
			children = props.children,
		}
	end
	return GeneralCollapsible{
		titleWidget = HtmlWidgets.Div{
			classes = {
				'general-collapsible-default-header',
				'brkts-popup-body-grid-header'
			},
			children = {
				HtmlWidgets.Div{children = props.gamesSectionName},
				HtmlWidgets.Div{children = props.gamesSectionResult},
				CollapsibleToggle{},
			}
		},
		collapseAreaCss = props.css,
		collapseAreaClasses = {'brkts-popup-body-grid'},
		children = props.children,
		shouldCollapse = true,
	}
end

return MatchSummaryGamesContainer
