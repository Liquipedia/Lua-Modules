---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchTable = Lua.import('Module:MatchTable', {requireDevIfEnabled = true})

local CustomMatchTable = {}

---@param args table
---@return Html
function CustomMatchTable.results(args)
	return MatchTable(args):init():query():build()
end

return Class.export(CustomMatchTable)
