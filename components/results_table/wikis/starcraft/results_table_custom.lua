---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Tier = require('Module:Tier')

local ResultsTable = Lua.import('Module:ResultsTable', {requireDevIfEnabled = true})
local AwardsTable = Lua.import('Module:ResultsTable/Award', {requireDevIfEnabled = true})

local UNDEFINED_TIER = 'undefined'

local CustomResultsTable = {}

-- Template entry point for results and achievements tables
function CustomResultsTable.results(args)
	local resultsTable = ResultsTable(args)

	-- overwrite functions
	resultsTable.tierDisplay = CustomResultsTable.tierDisplay

	return resultsTable:create():build()
end

-- Template entry point for awards tables
function CustomResultsTable.awards(args)
	local awardsTable = AwardsTable(args)

	-- overwrite functions
	awardsTable.tierDisplay = CustomResultsTable.tierDisplay

	return awardsTable:create():build()
end

function CustomResultsTable:tierDisplay(placement)
	local tierDisplay = Tier.text.tiers[placement.liquipediatier] or UNDEFINED_TIER

	tierDisplay = Page.makeInternalLink(
		{},
		tierDisplay,
		tierDisplay .. ' Tournaments'
	)

	local tierTypeDisplay = Tier.text.typesShort[(placement.liquipediatiertype or ''):lower()]

	local sortValue = placement.liquipediatier .. (tierTypeDisplay or '')

	if not tierTypeDisplay then
		return tierDisplay, sortValue
	end

	return tierDisplay .. ' (' .. tierTypeDisplay .. ')', sortValue
end

return Class.export(CustomResultsTable)
