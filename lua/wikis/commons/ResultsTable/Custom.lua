---
-- @Liquipedia
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ResultsTable = Lua.import('Module:ResultsTable')
local AwardsTable = Lua.import('Module:ResultsTable/Award')

local CustomResultsTable = {}

-- Template entry point for results and achievements tables
---@param args table
---@return Html
function CustomResultsTable.results(args)
	return ResultsTable(args):create():build()
end

-- Template entry point for awards tables
---@param args table
---@return Html
function CustomResultsTable.awards(args)
	return AwardsTable(args):create():build()
end

return Class.export(CustomResultsTable, {exports = {'results', 'awards'}})
