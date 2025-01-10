---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local I18n = require('Module:I18n')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local TournamentLabel = Lua.import('Module:Widget/Tournament/Label')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)
TournamentsTickerWidget.defaultProps = {
	filterGroups = {'liquipediatier'}
}

---@return Widget
function TournamentsTickerWidget:render()
	local filterGroups = self.props.filterGroups

	local allTournaments = TournamentTicker.getTournamentsFromDB()
	local upcoming = Array.filter(allTournaments, function(tournament)
		return tournament.status == 'UPCOMING'
	end)
	local ongoing = Array.filter(allTournaments, function(tournament)
		return tournament.status == 'ONGOING'
	end)
	local completed = Array.filter(allTournaments, function(tournament)
		return tournament.status == 'FINISHED'
	end)

	local createSubList = function(name, tournaments)
		local createFilterWrapper = function(tournament, child)
			return Array.reduce(filterGroups, function(prev, filter)
				return HtmlWidgets.Div{
					attributes = {
						['data-filter-group'] = 'filterbuttons-' .. filter,
						['data-filter-category'] = tournament[filter],
						['data-curated'] = tournament.featured and '' or nil,
					},
					children = prev,
				}
			end, child)
		end

		local list = HtmlWidgets.Ul{
			classes = {'tournaments-list-type-list'},
			children = Array.map(tournaments, function(tournament)
				return createFilterWrapper(tournament, TournamentLabel{tournament = tournament})
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
					children = {name},
				},
				HtmlWidgets.Div{
					children = {list},
				}
			},
		}
	end

	local fallbackElement = HtmlWidgets.Div{
		attributes = {
			['data-filter-hideable-group-fallback'] = '',
		},
		children = {
			HtmlWidgets.Center{
				css = {
					['margin'] = '1.5rem 0',
					['font-style'] = 'italic',
				},
				children = I18n.translate('tournament-ticker-no-tournaments'),
			}
		}
	}

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Ul{
				classes = {'tournaments-list'},
				attributes = {
					['data-filter-hideable-group'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = {
					createSubList('Upcoming', upcoming),
					createSubList('Ongoing', ongoing),
					createSubList('Completed', completed),
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
