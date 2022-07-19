---
-- @Liquipedia
-- wiki=commons
-- page=Module:MvpTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MvpTable = Lua.import('Module:MvpTable', {requireDevIfEnabled = true})

-- overwrite functions in this module on your custom wiki
-- e.g. `MvpTable.processData`

return Class.export(MvpTable)
