---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Condition = require('Module:Condition')
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
	upcomingDays = 5,
	completedDays = 5,
}

---@return Widget
function TournamentsTickerWidget:render()
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
			or 0

		local startDateThreshold = DateExt.getCurrentTimestamp() - (upcomingDays + modifiedThreshold) * 24 * 60 * 60
		if not tournament.startDate then
			return false
		end

		local endDateThreshold = DateExt.getCurrentTimestamp() + (completedDays + modifiedThreshold) * 24 * 60 * 60
		if not tournament.endDate then
			return tournament.startDate.timestamp >= startDateThreshold
		end

		return tournament.endDate.timestamp <= endDateThreshold and tournament.startDate.timestamp >= startDateThreshold
	end

	local lpdbFilter = Condition.Tree(Condition.BooleanOperator.all)
		:add(Condition.Tree(Condition.BooleanOperator.any)
			:add(Condition.Node(Condition.ColumnName('status'), Condition.Comparator.eq, ''))
			:add(Condition.Node(Condition.ColumnName('status'), Condition.Comparator.eq, 'finished'))
		)
		:add(Condition.Node(Condition.ColumnName('liquipediatiertype'), Condition.Comparator.eq, '!Points'))

	local allTournaments = Tournament.getAllTournaments(lpdbFilter, function(tournament)
		return isWithinDateRange(tournament)
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

	local upcomingTournaments = Array.filter(allTournaments, filterByPhase('UPCOMING'))
	local ongoingTournaments = Array.filter(allTournaments, filterByPhase('ONGOING'))
	local completedTournaments = Array.filter(allTournaments, filterByPhase('FINISHED'))
	table.sort(upcomingTournaments, sortByDateUpcoming)
	table.sort(ongoingTournaments, sortByDate)
	table.sort(completedTournaments, sortByDate)

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
					Sublist{title = 'Upcoming', tournaments = upcomingTournaments} ,
					Sublist{title = 'Ongoing', tournaments = ongoingTournaments},
					Sublist{title = 'Completed', tournaments = completedTournaments},
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
