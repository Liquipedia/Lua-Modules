---
-- @Liquipedia
-- page=Module:MatchesScheduleDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local MatchesTable = Lua.import('Module:MatchesScheduleDisplay')

local CustomMatchesTable = {}

function CustomMatchesTable.run(args)
	return MatchesTable(args):create()
end

return Class.export(CustomMatchesTable, {exports = {'run'}})
