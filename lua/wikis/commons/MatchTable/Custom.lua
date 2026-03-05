---
-- @Liquipedia
-- page=Module:MatchTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local MatchTable = Lua.import('Module:MatchTable')

local CustomMatchTable = {}

---@param args table
---@return Html
function CustomMatchTable.results(args)
	return MatchTable(args):readConfig():query():build()
end

return Class.export(CustomMatchTable, {exports = {'results'}})
