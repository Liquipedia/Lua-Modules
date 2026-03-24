---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/PhaseCollapsible
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
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
	return HtmlWidgets.Div{
		classes = Array.extend(
			{'general-collapsible', 'tournaments-phase-collapsible'},
			self.props.collapsed and {'collapsed'} or nil
		),
		children = {
			HtmlWidgets.Div{
				classes = {'tournaments-phase-collapsible__header'},
				attributes = {
					['data-collapsible-click-region'] = 'true',
					['data-collapsible-exclude'] = '.general-collapsible-default-toggle',
				},
				children = {
					HtmlWidgets.Span{
						classes = {'tournaments-phase-collapsible__label'},
						children = self.props.label,
					},
					ChevronToggle{},
				},
			},
			HtmlWidgets.Div{
				classes = {'should-collapse'},
				children = self.props.children,
			},
		},
	}
end

return TournamentsTickerPhaseCollapsible
