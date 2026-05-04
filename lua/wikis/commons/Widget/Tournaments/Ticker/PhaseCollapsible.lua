---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/PhaseCollapsible
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class TournamentsTickerPhaseCollapsibleProps
---@field label string
---@field children Widget|Widget[]
---@field collapsed boolean?

---@class TournamentsTickerPhaseCollapsible: Widget
---@operator call(TournamentsTickerPhaseCollapsibleProps): TournamentsTickerPhaseCollapsible
---@field props TournamentsTickerPhaseCollapsibleProps
local TournamentsTickerPhaseCollapsible = Class.new(Widget)

---@return Widget
function TournamentsTickerPhaseCollapsible:render()
	return GeneralCollapsible{
		classes = {'tournaments-phase-collapsible'},
		shouldCollapse = self.props.collapsed,
		titleWidget = HtmlWidgets.Div{
			classes = {'tournaments-phase-collapsible__header'},
			attributes = {
				['data-collapsible-click-region'] = 'true',
			},
			children = {
				HtmlWidgets.Span{
					classes = {'tournaments-phase-collapsible__label'},
					children = self.props.label,
				},
				ChevronToggle{},
			},
		},
		children = self.props.children,
	}
end

return TournamentsTickerPhaseCollapsible
