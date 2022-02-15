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
CustomActiveYears.defaultNumberOfStoredPlayersPerPlacement = 6
CustomActiveYears.additionalConditions = ''

-- legacy entry point
function CustomActiveYears.get(input)
	-- if invoked directly input == args
	-- if passed from modules it might be a table that holds the args table
	local args = input.args or input
	return CustomActiveYears.display(args)
end

return Class.export(CustomActiveYears)
