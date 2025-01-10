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
local Sublist = Lua.import('Module:Widget/Tournaments/Ticker/Sublist')

local Tournament = Lua.import('Module:Tournament')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)
TournamentsTickerWidget.defaultProps = {
	filterGroups = {'liquipediatier'}
}

---@return Widget
function TournamentsTickerWidget:render()
	local filterGroups = self.props.filterGroups

	local allTournaments = Array.filter(Tournament.getAllTournaments(), function(tournament)
		return tournament.status ~= 'cancelled'
	end)

	local upcomingTournaments = Array.filter(allTournaments, function(tournament)
		return tournament.phase == 'UPCOMING'
	end)
	local ongoingTournaments = Array.filter(allTournaments, function(tournament)
		return tournament.phase == 'ONGOING'
	end)
	local completedTournaments = Array.filter(allTournaments, function(tournament)
		return tournament.phase == 'FINISHED'
	end)

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
					Sublist{title = 'Upcoming', tournaments = upcomingTournaments},
					Sublist{title = 'Ongoing', tournaments = ongoingTournaments},
					Sublist{title = 'Completed', tournaments = completedTournaments},
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
