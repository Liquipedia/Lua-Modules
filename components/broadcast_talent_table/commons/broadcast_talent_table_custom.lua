---
-- @Liquipedia
-- wiki=commons
-- page=Module:BroadcastTalentTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BroadcastTalentTable = Lua.import('Module:BroadcastTalentTable', {requireDevIfEnabled = true})

local CustomBroadcastTalentTable = {}

function CustomBroadcastTalentTable.run(args)
	args = args or {}

	return BroadcastTalentTable(args):create()
end

return Class.export(CustomBroadcastTalentTable)
