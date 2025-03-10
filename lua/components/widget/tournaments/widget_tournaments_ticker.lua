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
local Logic = require('Module:Logic')
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

	local tierThresholdModifiers = {
		[1] = self.props.modifierTier1,
		[2] = self.props.modifierTier2,
		[3] = self.props.modifierTier3,
		[4] = self.props.modifierTier4,
		[5] = self.props.modifierTier5,
		[-1] = self.props.modifierTierMisc,
	}

	--- The Tier Type thresholds only affect completed tournaments.
	local tierTypeThresholdModifiers = {
		['qualifier'] = self.props.modifierTypeQualifier,
	}

	local currentTimestamp = DateExt.getCurrentTimestamp()
	local function isWithinDateRange(tournament)
		local modifiedThreshold = tierThresholdModifiers[tournament.liquipediaTier] or 0
		local modifiedCompletedThreshold = tierTypeThresholdModifiers[tournament.liquipediaTierType] or modifiedThreshold

		if not tournament.startDate then
			return false
		end

		local startDateThreshold = currentTimestamp + (upcomingDays + modifiedThreshold) * 24 * 60 * 60
		local endDateThreshold = currentTimestamp - (completedDays + modifiedCompletedThreshold) * 24 * 60 * 60

		if tournament.phase == 'ONGOING' then
			return true
		elseif tournament.phase == 'UPCOMING' then
			return tournament.startDate.timestamp < startDateThreshold
		elseif tournament.phase == 'FINISHED' then
			return tournament.endDate.timestamp > endDateThreshold
		end
		return false
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
		if not a.endDate then
			return true
		end
		if not b.endDate then
			return false
		end
		if a.endDate.timestamp ~= b.endDate.timestamp then
			return a.endDate.timestamp > b.endDate.timestamp
		end
		return a.startDate.timestamp > b.startDate.timestamp
	end

	local function sortByDateUpcoming(a, b)
		if a.startDate.timestamp ~= b.startDate.timestamp then
			return a.startDate.timestamp > b.startDate.timestamp
		end
		if not a.endDate then
			return true
		end
		if not b.endDate then
			return false
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


	local displayGameIcons = Logic.readBool(self.props.displayGameIcons)

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Ul{
				classes = {'tournaments-list'},
				attributes = {
					['data-filter-hideable-group'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = {
					Sublist{title = 'Upcoming', tournaments = upcomingTournaments, displayGameIcons = displayGameIcons} ,
					Sublist{title = 'Ongoing', tournaments = ongoingTournaments, displayGameIcons = displayGameIcons},
					Sublist{title = 'Completed', tournaments = completedTournaments, displayGameIcons = displayGameIcons},
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
