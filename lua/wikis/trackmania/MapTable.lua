---
-- @Liquipedia
-- page=Module:MapTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MapTableController = Lua.import('Module:MapTable/Controller')

--- see Module:MapTable/Controller for the entry point
return {run = MapTableController.run}
