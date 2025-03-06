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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TournamentLabel = Lua.import('Module:Widget/Tournament/Label')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class TournamentsTickerSublistWidget: Widget
---@operator call(table): TournamentsTickerSublistWidget

local TournamentsTickerSublistWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerSublistWidget:render()
	if not self.props.tournaments then
		return
	end

	local createFilterWrapper = function(tournament, child)
		return Array.reduce(FilterConfig.categories, function(prev, filterCategory)
			local itemIsValid = filterCategory.itemIsValid or function(item) return true end
			local itemToPropertyValues = filterCategory.itemToPropertyValues or function(item) return item end
			local value = tournament[filterCategory.property]
			local filterValue = itemIsValid(value) and value or filterCategory.defaultItem
			return HtmlWidgets.Div{
				attributes = {
					['data-filter-group'] = 'filterbuttons-' .. filterCategory.name,
					['data-filter-category'] = itemToPropertyValues(filterValue),
					['data-curated'] = tournament.featured and '' or nil,
				},
				children = prev,
			}
		end, child)
	end

	local list = HtmlWidgets.Ul{
		classes = {'tournaments-list-type-list'},
		children = Array.map(self.props.tournaments, function(tournament)
			return HtmlWidgets.Li{children = createFilterWrapper(tournament, TournamentLabel{
				tournament = tournament,
				displayGameIcon = self.props.displayGameIcons
			})}
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

return TournamentsTickerSublistWidget
