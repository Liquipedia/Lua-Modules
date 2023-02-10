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
	if mode == 'doubles' then
		return 2
	elseif mode == 'singles' then
		return 1
	end

	return 5
end

return Class.export(CustomEarnings)
