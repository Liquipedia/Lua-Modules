---
-- @Liquipedia
-- page=Module:GameTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local GameTable = Lua.import('Module:GameTable')

local CustomGameTable = {}

---@param args table
---@return Html
function CustomGameTable.results(args)
	return GameTable(args):readConfig():query():build()
end

return Class.export(CustomGameTable, {exports = {'results'}})
