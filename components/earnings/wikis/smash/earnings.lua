---
-- @Liquipedia
-- wiki=smash
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomEarnings = Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true})

---@diagnostic disable-next-line: duplicate-set-field
CustomEarnings.divisionFactorPlayer = function(mode)
	return 1
	-- Currently 1 due to Smash storing indiv earnings in prizemoney field
	-- for duo opponents and no usage of teamCard
end

-- legacy mode since data on this wiki is legacy
CustomEarnings.legacyMode = true

return Class.export(CustomEarnings)
