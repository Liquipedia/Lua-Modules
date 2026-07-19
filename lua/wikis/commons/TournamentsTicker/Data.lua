---
-- @Liquipedia
-- page=Module:TournamentsTicker/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local Operator = Lua.import('Module:Operator')

local Tournament = Lua.import('Module:Tournament')

local TournamentsTickerData = {}

---@class TournamentsTickerDataProps
---@field upcomingDays number
---@field completedDays number
---@field modifierTier1 number?
---@field modifierTier2 number?
---@field modifierTier3 number?
---@field modifierTier4 number?
---@field modifierTier5 number?
---@field modifierTierMisc number?
---@field modifierTypeQualifier number?

---@class TournamentsTickerDataResult
---@field upcoming StandardTournament[]
---@field ongoing StandardTournament[]
---@field completed StandardTournament[]

---@param props TournamentsTickerDataProps
---@return TournamentsTickerDataResult
function TournamentsTickerData.get(props)
	local upcomingDays = props.upcomingDays or 5
	local completedDays = props.completedDays or 5

	local tierThresholdModifiers = {
		[1] = props.modifierTier1,
		[2] = props.modifierTier2,
		[3] = props.modifierTier3,
		[4] = props.modifierTier4,
		[5] = props.modifierTier5,
		[-1] = props.modifierTierMisc,
	}

	--- The Tier Type thresholds only affect completed tournaments.
	local tierTypeThresholdModifiers = {
		['qualifier'] = props.modifierTypeQualifier,
	}

	local currentTimestamp = DateExt.getCurrentTimestamp()

	---@param tournament StandardTournament
	---@return boolean
	local function isWithinDateRange(tournament)
		local modifiedThreshold = tierThresholdModifiers[tournament.liquipediaTier] or 0
		local modifiedCompletedThreshold = tierTypeThresholdModifiers[tournament.liquipediaTierType] or modifiedThreshold

		if not tournament.startDate then
			return false
		end

		local startDateThreshold = currentTimestamp + DateExt.daysToSeconds(upcomingDays + modifiedThreshold)
		local endDateThreshold = currentTimestamp - DateExt.daysToSeconds(completedDays + modifiedCompletedThreshold)

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

	---@param phase TournamentPhase
	---@return fun(tournament: StandardTournament): boolean
	local function filterByPhase(phase)
		return function(tournament)
			return tournament.phase == phase
		end
	end

	local upcomingTournaments = Array.filter(allTournaments, filterByPhase('UPCOMING'))
	local ongoingTournaments = Array.filter(allTournaments, filterByPhase('ONGOING'))
	local completedTournaments = Array.filter(allTournaments, filterByPhase('FINISHED'))
	table.sort(upcomingTournaments, sortByDateUpcoming)
	table.sort(ongoingTournaments, sortByDate)
	table.sort(completedTournaments, sortByDate)

	return {
		upcoming = upcomingTournaments,
		ongoing = ongoingTournaments,
		completed = completedTournaments,
	}
end

return TournamentsTickerData
