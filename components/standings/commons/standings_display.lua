---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local SWISS_TYPE = 'swiss'

local StandingsDisplay = Class.new(function(self, group)
	self.group = group
end)

function StandingsDisplay:build()
	if self.group.type == SWISS_TYPE then
		local SwissDisplay = Lua.import('Module:Standings/Display/Swiss')
		return SwissDisplay(self.group):build()
	end

	-- todo: build the actual display
end

return StandingsDisplay
