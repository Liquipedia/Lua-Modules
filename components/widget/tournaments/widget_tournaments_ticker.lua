---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
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
	filterGroups = {'liquipediatier'},
	upcomingDays = 5,
	completedDays = 5,
}

---@return Widget
function TournamentsTickerWidget:render()
	local filterGroups = self.props.filterGroups
	local upcomingDays = self.props.upcomingDays
	local completedDays = self.props.completedDays

	--- These thresholds makes very little sense, but it's converted from legacy.
	--- Let's revisit them with product, design and community at the later date
	local tierThresholdModifiers = {
		[1] = 55,
		[2] = 55,
		[3] = 22,
		[4] = 0,
		[5] = 0,
		['qualifier'] = -2,
	}

	local function isWithinDateRange(tournament)
		local modifiedThreshold = tierThresholdModifiers[tournament.liquipediaTierType]
			or tierThresholdModifiers[tournament.liquipediaTier]
		local startDate = DateExt.getCurrentTimestamp() + (upcomingDays + modifiedThreshold) * 24 * 60 * 60
		local endDate = DateExt.getCurrentTimestamp() - (completedDays - modifiedThreshold) * 24 * 60 * 60

		return tournament.startDate.timestamp >= startDate and tournament.endDate.timestamp <= endDate
	end

	local allTournaments = Array.filter(Tournament.getAllTournaments(), function(tournament)
		return tournament.status == '' and tournament.liquipediaTierType ~= 'points' and isWithinDateRange(tournament)
	end)

	local function filterByPhase(phase)
		return function(tournament)
			return tournament.phase == phase
		end
	end

	local function sortByDate(a, b)
		if a.endDate.timestamp ~= b.endDate.timestamp then
			return a.endDate.timestamp > b.endDate.timestamp
		end
		return a.startDate.timestamp > b.startDate.timestamp
	end

	local function sortByDateUpcoming(a, b)
		if a.startDate.timestamp ~= b.startDate.timestamp then
			return a.startDate.timestamp > b.startDate.timestamp
		end
		return a.endDate.timestamp > b.endDate.timestamp
	end

	local upcomingTournaments = Array.sortBy(Array.filter(allTournaments, filterByPhase('UPCOMING')), sortByDateUpcoming)
	local ongoingTournaments = Array.sortBy(Array.filter(allTournaments, filterByPhase('ONGOING')), sortByDate)
	local completedTournaments = Array.sortBy(Array.filter(allTournaments, filterByPhase('FINISHED')), sortByDate)

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
					Sublist{title = 'Upcoming', tournaments = upcomingTournaments, filterGroups = filterGroups} ,
					Sublist{title = 'Ongoing', tournaments = ongoingTournaments, filterGroups = filterGroups},
					Sublist{title = 'Completed', tournaments = completedTournaments, filterGroups = filterGroups},
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
