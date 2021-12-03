---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require("Module:Lua")

return Lua.import('Module:Matches/match2', {requireDevIfEnabled = true})
