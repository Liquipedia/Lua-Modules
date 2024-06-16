---
-- @Liquipedia
-- wiki=commons
-- page=Module:GameTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchTable = Lua.import('Module:GameTable')

local CustomMatchTable = {}

---@param args table
---@return Html
function CustomMatchTable.results(args)
	return MatchTable(args):readConfig():query():build()
end

return Class.export(CustomMatchTable)
