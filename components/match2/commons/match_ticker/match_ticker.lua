---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchTicker = Class.new()

MatchTicker.Display = Lua.import('Module:MatchTicker/Display', {requireDevIfEnabled = true})

MatchTicker.Query = Lua.import('Module:MatchTicker/Query', {requireDevIfEnabled = true})

MatchTicker.HelperFunctions = Lua.import('Module:MatchTicker/Helpers/Custom', {requireDevIfEnabled = true})

--overwrite stuff if needed

return MatchTicker
