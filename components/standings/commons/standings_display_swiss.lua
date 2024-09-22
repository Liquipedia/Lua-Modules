---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Display/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local SwissStandingsDisplay = Class.new(function(self, group)
	self.group = group
end)

function SwissStandingsDisplay:build()

	-- todo: build the actual display
end

return SwissStandingsDisplay
