---
-- @Liquipedia
-- wiki=commons
-- page=Module:YearsActive
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomActiveYears = Lua.import('Module:YearsActive/Base', {requireDevIfEnabled = true})

-- wiki specific settings
CustomActiveYears.defaultNumberOfStoredPlayersPerPlacement = 10
CustomActiveYears.additionalConditions = ''

return Class.export(CustomActiveYears)
