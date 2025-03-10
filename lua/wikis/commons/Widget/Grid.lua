---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Grid
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local GridWidgets = {}

GridWidgets.Container = Lua.import('Module:Widget/Grid/Container')
GridWidgets.Cell = Lua.import('Module:Widget/Grid/Cell')

return GridWidgets
