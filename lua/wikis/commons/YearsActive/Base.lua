---
-- @Liquipedia
-- page=Module:YearsActive/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ActiveYears = {}

local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Info = mw.loadData('Module:Info')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Set = require('Module:Set')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENT_YEAR = tonumber(os.date('%Y'))

-- overwritable per wiki
ActiveYears.startYear = Info.startYear
ActiveYears.defaultNumberOfStoredPlayersPerPlacement = 10
ActiveYears.additionalConditions = ''
ActiveYears.noResultsText = 'Player has no results.'

---
-- Entry point
-- @player - the player/individual for whom the active years shall be determined
-- @mode - (optional) the mode to calculate earnings for (used for LPDB conditions)
-- @noRedirect - (optional) player redirects get not resolved before query
-- @prefix - (optional) the prefix under which the players are stored in the placements
-- @playerPositionLimit - (optional) the number for how many params the query should look in LPDB
function ActiveYears.display(args)
	args = args or {}
	local player = args.player

	if String.isEmpty(player) then
		error('No player specified')
	end
	if not Logic.readBool(args.noRedirect) then
		player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	else
		player = player:gsub('_', ' ')
	end

	-- since TeamCards on some wikis store players with underscores and some with spaces
	-- we need to check for both options
	local playerAsPageName = player:gsub(' ', '_')

	local prefix = args.prefix or 'p'

	local playerPositionLimit = tonumber(args.playerPositionLimit) or ActiveYears.defaultNumberOfStoredPlayersPerPlacement
	if playerPositionLimit <=0 then
		error('"playerPositionLimit" has to be >= 1')
	end

	-- Build conditions
	local conditions = ActiveYears._buildConditions(player, playerAsPageName, playerPositionLimit, prefix, args.mode)

	return ActiveYears._calculate(conditions)
end

function ActiveYears._buildConditions(player, playerAsPageName, playerPositionLimit, prefix, mode)
	local playerConditionTree = ConditionTree(BooleanOperator.any)
	if prefix == 'p' then
		playerConditionTree:add({
			ConditionNode(ColumnName('participant'), Comparator.eq, player),
			ConditionNode(ColumnName('participant'), Comparator.eq, playerAsPageName),
		})
	end
	for playerIndex = 1, playerPositionLimit do
		playerConditionTree:add({
			ConditionNode(ColumnName('players_' .. prefix .. playerIndex), Comparator.eq, player),
			ConditionNode(ColumnName('players_' .. prefix .. playerIndex), Comparator.eq, playerAsPageName),
		})
	end

	local conditionTree = ConditionTree(BooleanOperator.all):add({
		playerConditionTree,
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('date_year'), Comparator.ge, ActiveYears.startYear),
	})

	if String.isNotEmpty(mode) then
		conditionTree:add({
			ConditionNode(ColumnName('mode'), Comparator.eq, mode),
		})
	end

	return conditionTree:toString() .. ActiveYears.additionalConditions
end

function ActiveYears._calculate(conditions)
	-- Get years
	local years = ActiveYears._getYears(conditions)
	if Table.isEmpty(years) then
		return ActiveYears.noResultsText
	end

	return ActiveYears.displayYears(years)
end

function ActiveYears.displayYears(years)
	-- Sort years chronologically
	table.sort(years)

	-- Generate output for activity ranges
	local output = table.concat(ActiveYears._groupYears(years), ',</br>')

	-- Return text with years active
	return output
end

function ActiveYears._getYears(conditions)
	local years = Set{}
	local checkYear = function(placement)
		-- set the year in which the placement happened as true (i.e. active)
		local year = tonumber(string.sub(placement.date, 1, 4))
		years:add(year)
	end
	local queryParameters = {
		conditions = conditions,
		order = 'date asc',
		query = 'date',
	}
	Lpdb.executeMassQuery('placement', queryParameters, checkYear)

	return years:toArray()
end

function ActiveYears._groupYears(sortedYears)
	if Logic.isEmpty(sortedYears) then return {} end

	local startYear
	local endYear
	local yearRanges = {}

	for index, year in ipairs(sortedYears) do
		if index == 1 then
			startYear = year
		elseif year - endYear > 1 then
		-- If the difference is greater than 1 we have skipped a year, so we have to insert
			yearRanges = ActiveYears._insertYears(startYear, endYear, yearRanges)
			startYear = year
		end
		endYear = year
	end

	if endYear >= CURRENT_YEAR then
		table.insert(yearRanges, tostring(startYear) .. ' - ' .. '<b>Present</b>')
	else
		yearRanges = ActiveYears._insertYears(startYear, endYear, yearRanges)
	end

	return yearRanges
end

function ActiveYears._insertYears(startYear, endYear, yearRanges)
	if startYear == endYear then
		table.insert(yearRanges, tostring(startYear))
	else
		table.insert(yearRanges, tostring(startYear) .. ' - ' .. tostring(endYear))
	end

	return yearRanges
end

return Class.export(ActiveYears, {exports = {'display'}})
