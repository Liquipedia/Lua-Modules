---
-- @Liquipedia
-- wiki=rocketleague 
-- page=Module:YearsActive
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomActiveYears = Lua.import('Module:YearsActive/Base', {requireDevIfEnabled = true})

-- wiki specific settings
CustomActiveYears.startYear = 1995
CustomActiveYears.defaultNumberOfStoredPlayersPerMatch = 6
CustomActiveYears.additionalConditions = ''

-- legacy entry point
function CustomActiveYears.get(input)
	local args = input.args
	return CustomActiveYears.display(args)
end

return Class.export(CustomActiveYears)
