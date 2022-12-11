---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local ResultsTable = Lua.import('Module:ResultsTable', {requireDevIfEnabled = true})
local AwardsTable = Lua.import('Module:ResultsTable/Award', {requireDevIfEnabled = true})

local CustomResultsTable = {}

-- Template entry point for results and achievements tables
function CustomResultsTable.run(frame)
	local args = Arguments.getArgs(frame)

	if Logic.readBool(args.awards) then
		return CustomResultsTable.awards(args)
	end

	local resultsTable = ResultsTable(args)

	return resultsTable:create():build()
end

-- Template entry point for awards tables
function CustomResultsTable.awards(args)
	local awardsTable = AwardsTable(args)

	return awardsTable:create():build()
end

return CustomResultsTable
