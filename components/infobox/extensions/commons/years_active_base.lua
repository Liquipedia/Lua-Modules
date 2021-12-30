---
-- @Liquipedia
-- wiki=commons
-- page=Module:YearsActive/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ActiveYears = {}

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Info = mw.loadData('Module:Info')

local _DEFAULT_DATE = '1970-01-01 00:00:00'
local _CURRENT_YEAR = tonumber(os.date('%Y'))
local _MAX_QUERY_LIMIT = 5000

-- overwritable per wiki
ActiveYears.startYear = Info.startYear
ActiveYears.defaultNumberOfStoredPlayersPerMatch = 10
ActiveYears.additionalConditions = ''

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

	local playerPositionLimit = tonumber(args.playerPositionLimit) or ActiveYears.defaultNumberOfStoredPlayersPerMatch
	if playerPositionLimit <=0 then
		error('"playerPositionLimit" has to be >= 1')
	end

	local conditions = '([[participant::' .. player .. ']] OR [[participant::' .. playerAsPageName .. ']]'
	for playerIndex = 1, playerPositionLimit do
		conditions = conditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. player .. ']]'
		conditions = conditions .. ' OR [[players_' .. prefix .. playerIndex .. '::' .. playerAsPageName .. ']]'
	end
	conditions = conditions .. ')'

	conditions = conditions .. ' AND [[date::!' .. _DEFAULT_DATE .. ']] AND (' ..
		'[[date_year::>' .. ActiveYears.startYear .. ']] OR ' ..
		'[[date_year::' .. ActiveYears.startYear .. ']])'

	if String.isNotEmpty(args.mode) then
		conditions = conditions .. ' AND [[mode::' .. args.mode .. ']]'
	end

	conditions = conditions .. ActiveYears.additionalConditions

	return ActiveYears._calculate(conditions)
end

function ActiveYears._calculate(conditions)
	local years = {}
	local offset = 0
	local count = _MAX_QUERY_LIMIT

	while count == _MAX_QUERY_LIMIT do
		local lpdbQueryData = mw.ext.LiquipediaDB.lpdb('placement', {
			order = 'date asc',
			conditions = conditions,
			query = 'date',
			limit = _MAX_QUERY_LIMIT,
			offset = offset
		})

		if offset == 0 and #lpdbQueryData == 0 then
			return 'Player has no results.'
		end

		-- Find all years for which the player has at least one placement
		for _, item in ipairs(lpdbQueryData) do
			local year = tonumber(string.sub(item.date, 1, 4))
			years[year] = true
		end

		count = #lpdbQueryData
		offset = offset + _MAX_QUERY_LIMIT
	end

	-- Sort years chronologically
	local sortedYears = {}
	for year in pairs(years) do
		table.insert(sortedYears, year)
	end
	table.sort(sortedYears)

	-- Determine activity ranges by grouping consecutive years
	local startYear
	local endYear
	local yearRanges = {}
	for index, year in ipairs(sortedYears) do
		if index == 1 then
			startYear = year
			endYear = year
		else
			if year - endYear == 1 then
				endYear = year
			else
				if startYear == endYear then
					table.insert(yearRanges, tostring(startYear))
				else
					table.insert(yearRanges, tostring(startYear) .. ' - ' .. tostring(endYear))
				end
				startYear = year
				endYear = year
			end
		end
	end
	if endYear == _CURRENT_YEAR then
		table.insert(yearRanges, tostring(startYear) .. ' - ' .. "'''Present'''")
	else
		if startYear == endYear then
			table.insert(yearRanges, tostring(startYear))
		else
			table.insert(yearRanges, tostring(startYear) .. ' - ' .. tostring(endYear))
		end
	end

	-- Generate output for activity ranges
	local output = table.concat(yearRanges, ',</br>')

	-- Return text with years active
	return output
end

return Class.export(ActiveYears)
