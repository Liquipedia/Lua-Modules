---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchesTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchesTable = Lua.import('Module:MatchesTable', {requireDevIfEnabled = true})

local CustomMatchesTable = {}

function CustomMatchesTable.run(args)
	return MatchesTable(args):build():create()
end

return Class.export(CustomMatchesTable)