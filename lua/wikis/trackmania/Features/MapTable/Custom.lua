---
-- @Liquipedia
-- page=Module:Features/MapTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MapTableController = Lua.import('Module:Features/MapTable/Controller')

--- see Module:Features/MapTable/Controller for the entry point
return {run = MapTableController.run}
