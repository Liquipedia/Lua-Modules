---
-- @Liquipedia
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Tier = Lua.import('Module:Tier/Custom')

local ResultsTable = Lua.import('Module:ResultsTable')
local AwardsTable = Lua.import('Module:ResultsTable/Award')

local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

local CustomResultsTable = Class.new(ResultsTable)
local CustomAwardsTable = Class.new(AwardsTable)
local Custom = {}

CustomResultsTable.tierDisplay = Custom.tierDisplay
CustomAwardsTable.tierDisplay = Custom.tierDisplay


-- Template entry point for results and achievements tables
---@param args table
---@return VNode
function Custom.results(args)
	args.gameIcons = true
	args.showType = true
	local resultsTable = CustomResultsTable(args)

	return resultsTable:create():build()
end

-- Template entry point for awards tables
---@param args table
---@return VNode
function Custom.awards(args)
	args.gameIcons = true
	args.showType = true
	local awardsTable = CustomAwardsTable(args)

	return awardsTable:create():build()
end

---CS tier display overwrite for results, achievements and awards tables
---@param placement table
---@return string?
---@return string
function Custom:tierDisplay(placement)
	local tier, tierType, options = Tier.parseFromQueryData(placement)
	options.link = true
	options.onlyTierTypeIfBoth = false
	options.onlyDisplayPrioritized = true

	if not Tier.isValid(tier, tierType) then
		return INVALID_TIER_DISPLAY, INVALID_TIER_SORT
	end
	---@cast tier -string

	return Tier.display(tier, tierType, options), Tier.toSortValue(tier, tierType)
end

return Class.export(Custom, {exports = {'results', 'awards'}})
