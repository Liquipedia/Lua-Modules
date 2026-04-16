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
	if Logic.isEmpty(self.props.children) then
		return
	elseif Logic.isEmpty(self.props.gamesSectionName) and Logic.isEmpty(self.props.gamesSectionResult) then
		return HtmlWidgets.Div{
			classes = {'brkts-popup-body-grid'},
			css = self.props.css,
			children = self.props.children,
		}
	end
	return GeneralCollapsible{
		titleWidget = HtmlWidgets.Div{
			classes = {
				'general-collapsible-default-header',
				'brkts-popup-body-grid-header'
			},
			children = {
				HtmlWidgets.Div{children = self.props.gamesSectionName},
				HtmlWidgets.Div{children = self.props.gamesSectionResult},
				CollapsibleToggle{},
			}
		},
		collapseAreaCss = self.props.css,
		collapseAreaClasses = {'brkts-popup-body-grid'},
		children = self.props.children,
		shouldCollapse = true,
	}
end

return MatchSummaryGamesContainer
