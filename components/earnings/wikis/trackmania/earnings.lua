---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomEarnings = Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true})

-- Use placement field individualprizemoney in case of player earnings
CustomEarnings.divisionFactorPlayer = nil

return Class.export(CustomEarnings)
