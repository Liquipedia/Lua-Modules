---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Display/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local StandingsDisplay = Lua.import('Module:Standings/Display')

local SwissStandingsDisplay = Class.new(StandingsDisplay)

function SwissStandingsDisplay:build()

	-- todo: build the actual display
end

return SwissStandingsDisplay
