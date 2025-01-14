---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournaments/Ticker/Sublist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TournamentLabel = Lua.import('Module:Widget/Tournament/Label')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerWidget:render()
	if not self.props.tournaments then
		return
	end

	local filters = Array.map(FilterConfig.categories, Operator.property('property')) or {}

	local createFilterWrapper = function(tournament, child)
		return Array.reduce(filters, function(prev, filter)
			return HtmlWidgets.Div{
				attributes = {
					['data-filter-group'] = 'filterbuttons-' .. string.lower(filter),
					['data-filter-category'] = tournament[filter],
					['data-curated'] = tournament.featured and '' or nil,
				},
				children = prev,
			}
		end, child)
	end

	local list = HtmlWidgets.Ul{
		classes = {'tournaments-list-type-list'},
		children = Array.map(self.props.tournaments, function(tournament)
			return HtmlWidgets.Li{children = createFilterWrapper(tournament, TournamentLabel{tournament = tournament})}
		end),
	}

	return HtmlWidgets.Li{
		attributes = {
			['data-filter-hideable-group'] = '',
			['data-filter-effect'] = 'fade',
		},
		children = {
			HtmlWidgets.Span{
				classes = {'tournaments-list-heading'},
				children = self.props.title,
			},
			HtmlWidgets.Div{
				children = list,
			}
		},
	}
end

return TournamentsTickerWidget
