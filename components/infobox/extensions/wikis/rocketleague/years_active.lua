---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:YearsActive
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Set = require('Module:Set')
local Table = require('Module:Table')

local CustomActiveYears = Lua.import('Module:YearsActive/Base', {requireDevIfEnabled = true})

-- wiki specific settings
CustomActiveYears.defaultNumberOfStoredPlayersPerPlacement = 6
CustomActiveYears.additionalConditions = ''

local _TALENT_POSITIONS = {
	'Analyst',
	'Caster',
	'Caster/Analyst',
	'Commentator',
	'Commentator/Analyst',
	'Desk Host',
	'Host',
	'Reporter',
	'Stage Host',
}

local _OBSERVER_POSITIONS = {
	'Observer',
	'Observer/Producer',
	'Producer/Observer',
}

-- legacy entry point
function CustomActiveYears.get(input)
	-- if invoked directly input == args
	-- if passed from modules it might be a table that holds the args table
	local args = input.args or input
	local display = CustomActiveYears.display(args)
	return display ~= 'Player has no results.' and display or nil
end

function CustomActiveYears.getTalent(talent)
	return CustomActiveYears._getBroadcaster(
		CustomActiveYears._getBroadcastConditions(talent, _TALENT_POSITIONS)
	)
end

function CustomActiveYears.getObserver(observer)
	return CustomActiveYears._getBroadcaster(
		CustomActiveYears._getBroadcastConditions(observer, _OBSERVER_POSITIONS)
	)
end

function CustomActiveYears._getBroadcastConditions(broadcaster, positions)
	broadcaster = mw.ext.TeamLiquidIntegration.resolve_redirect(broadcaster)

	-- Add a condition for each broadcaster position
	local conditions = {}
	for _, position in pairs(positions) do
		table.insert(conditions, '[[position' .. '::' .. position .. ']]')
	end

	return '[[page::' .. broadcaster .. ']] AND [[date::!1970-01-01 00:00:00]]' ..
		' AND (' .. table.concat(conditions, ' OR ') .. ')'
end

function CustomActiveYears._getBroadcaster(conditions)
	-- Get years
	local years = CustomActiveYears._getYearsBroadcast(conditions)
	if Table.isEmpty(years) then
		return
	end

	return CustomActiveYears._displayYears(years)
end

function CustomActiveYears._getYearsBroadcast(conditions)
	local years = Set{}
	local checkYear = function(broadcast)
		-- set the year in which the placement happened as true (i.e. active)
		local year = tonumber(string.sub(broadcast.date, 1, 4))
		years:add(year)
	end
	local queryParameters = {
		conditions = conditions,
		order = 'date asc',
		query = 'date, pagename',
	}
	Lpdb.executeMassQuery('broadcasters', queryParameters, checkYear)

	return years:toArray()
end

return Class.export(CustomActiveYears)
