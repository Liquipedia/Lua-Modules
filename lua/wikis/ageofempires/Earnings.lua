---
-- @Liquipedia
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local CustomEarnings = Lua.import('Module:Earnings/Base')

CustomEarnings.defaultNumberOfStoredPlayersPerMatch = 15

-- Use placement field individualprizemoney in case of player earnings
CustomEarnings.divisionFactorPlayer = nil

return CustomEarnings
