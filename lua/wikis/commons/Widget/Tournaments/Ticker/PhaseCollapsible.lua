---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/PhaseCollapsible
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')

---@class TournamentsTickerPhaseCollapsibleProps
---@field label string
---@field children Renderable|Renderable[]
---@field collapsed boolean?

---@param props TournamentsTickerPhaseCollapsibleProps
---@return VNode
local function TournamentsTickerPhaseCollapsible(props)
	return GeneralCollapsible{
		classes = {'tournaments-phase-collapsible'},
		shouldCollapse = props.collapsed,
		titleWidget = Html.Div{
			classes = {'tournaments-phase-collapsible__header'},
			attributes = {
				['data-collapsible-click-region'] = 'true',
			},
			children = {
				Html.Span{
					classes = {'tournaments-phase-collapsible__label'},
					children = props.label,
				},
				ChevronToggle{},
			},
		},
		children = props.children,
	}
end

return Component.component(TournamentsTickerPhaseCollapsible)
