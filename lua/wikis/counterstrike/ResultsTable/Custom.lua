---
-- @Liquipedia
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Tier = Lua.import('Module:Tier/Custom')

local ResultsTable = Lua.import('Module:ResultsTable')
local AwardsTable = Lua.import('Module:ResultsTable/Award')

local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

local CustomResultsTable = {}

-- Template entry point for results and achievements tables
---@param args table
---@return Html
function CustomResultsTable.results(args)
	local resultsTable = ResultsTable(args)

	resultsTable.tierDisplay = CustomResultsTable.tierDisplay

	return resultsTable:create():build()
end

-- Template entry point for awards tables
---@param args table
---@return Html
function CustomResultsTable.awards(args)
	local awardsTable = AwardsTable(args)

	awardsTable.tierDisplay = CustomResultsTable.tierDisplay

	return awardsTable:create():build()
end

---CS tier display overwrite for results, achievements and awards tables
---@param placement table
---@return string?
---@return string
function CustomResultsTable:tierDisplay(placement)
	local tier, tierType, options = Tier.parseFromQueryData(placement)
	options.link = true
	options.onlyTierTypeIfBoth = false
	options.onlyDisplayPrioritized = true

	if not Tier.isValid(tier, tierType) then
		return INVALID_TIER_DISPLAY, INVALID_TIER_SORT
	end

	return Tier.display(tier, tierType, options), Tier.toSortValue(tier, tierType)
end

return Class.export(CustomResultsTable, {exports = {'results', 'awards'}})
