---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Widget = Lua.import('Module:Widget')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

local Tournament = Lua.import('Module:Tournament')

---@class TournamentsTickerListWidget: Widget
---@operator call(table): TournamentsTickerListWidget
local TournamentsTickerListWidget = Class.new(Widget)
TournamentsTickerListWidget.defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
}

---@return Widget
function TournamentsTickerListWidget:render()
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

	local tierTypeThresholdModifiers = {
		['qualifier'] = self.props.modifierTypeQualifier,
	}

	local currentTimestamp = DateExt.getCurrentTimestamp()
	local displayGameIcons = Logic.readBool(self.props.displayGameIcons)

	---@param tournament StandardTournament
	---@return boolean
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
			assert(tournament.endDate, 'Tournament without end date: ' .. tournament.pageName)
			return tournament.endDate.timestamp > endDateThreshold
		end
		return false
	end

	local lpdbFilter = Condition.Tree(Condition.BooleanOperator.all):add{
		Condition.Util.anyOf(Condition.ColumnName('status'), {'', 'finished'}),
		Condition.Node(Condition.ColumnName('liquipediatiertype'), Condition.Comparator.neq, 'Points')
	}

	local allTournaments = Tournament.getAllTournaments(lpdbFilter, function(tournament)
		return isWithinDateRange(tournament)
	end)

	---@param phase TournamentPhase
	---@return fun(tournament: StandardTournament): boolean
	local function filterByPhase(phase)
		return function(tournament)
			return tournament.phase == phase
		end
	end

	---@param a StandardTournament
	---@param b StandardTournament
	---@param dateProperty 'endDate'|'startDate'
	---@param operator fun(a: integer, b: integer): boolean
	---@return boolean?
	local function sortByDateProperty(a, b, dateProperty, operator)
		if not a[dateProperty] and not b[dateProperty] then return nil end
		if not a[dateProperty] then return true end
		if not b[dateProperty] then return false end
		if a[dateProperty].timestamp ~= b[dateProperty].timestamp then
			return operator(a[dateProperty].timestamp, b[dateProperty].timestamp)
		end
		return nil
	end

	---@param a StandardTournament
	---@param b StandardTournament
	---@return boolean
	local function sortByDate(a, b)
		local endDateSort = sortByDateProperty(a, b, 'endDate', Operator.gt)
		if endDateSort ~= nil then return endDateSort end
		local startDateSort = sortByDateProperty(a, b, 'startDate', Operator.gt)
		if startDateSort ~= nil then return startDateSort end
		return a.pageName < b.pageName
	end

	---@param a StandardTournament
	---@param b StandardTournament
	---@return boolean
	local function sortByDateUpcoming(a, b)
		local startDateSort = sortByDateProperty(a, b, 'startDate', Operator.gt)
		if startDateSort ~= nil then return startDateSort end
		local endDateSort = sortByDateProperty(a, b, 'endDate', Operator.gt)
		if endDateSort ~= nil then return endDateSort end
		return a.pageName < b.pageName
	end

	local upcomingTournaments = Array.filter(allTournaments, filterByPhase('UPCOMING'))
	local ongoingTournaments = Array.filter(allTournaments, filterByPhase('ONGOING'))
	local completedTournaments = Array.filter(allTournaments, filterByPhase('FINISHED'))
	table.sort(upcomingTournaments, sortByDateUpcoming)
	table.sort(ongoingTournaments, sortByDate)
	table.sort(completedTournaments, sortByDate)

	---@param tournament StandardTournament
	---@param child Widget
	---@return Widget
	local function createFilterWrapper(tournament, child)
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

	---@param tournaments StandardTournament[]
	---@return Widget
	local function buildTabContent(tournaments)
		local fallback = HtmlWidgets.Div{
			attributes = {
				['data-filter-hideable-group-fallback'] = '',
				['data-filter-effect'] = 'fade',
			},
			children = HtmlWidgets.Center{
				css = {margin = '1.5rem 0', ['font-style'] = 'italic'},
				children = I18n.translate('tournament-ticker-no-tournaments'),
			},
		}

		local list = HtmlWidgets.Ul{
			classes = {'tournaments-list-type-list'},
			children = Array.map(tournaments, function(tournament)
				return HtmlWidgets.Li{
					children = createFilterWrapper(tournament, ListItem{
						tournament = tournament,
						displayGameIcon = displayGameIcons,
					})
				}
			end),
		}

		return HtmlWidgets.Div{
			attributes = {
				['data-filter-hideable-group'] = '',
				['data-filter-effect'] = 'fade',
			},
			children = {list, fallback},
		}
	end

	return ContentSwitch{
		switchGroup = 'tournament-list-phase',
		defaultActive = 2,
		storeValue = false,
		tabs = {
			{label = 'Upcoming', value = 'upcoming', content = buildTabContent(upcomingTournaments)},
			{label = 'Ongoing', value = 'ongoing', content = buildTabContent(ongoingTournaments)},
			{label = 'Completed', value = 'completed', content = buildTabContent(completedTournaments)},
		},
	}
end

return TournamentsTickerListWidget
