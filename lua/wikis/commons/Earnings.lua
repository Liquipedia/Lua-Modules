---
-- @Liquipedia
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local CustomEarnings = Lua.import('Module:Earnings/Base')

-- overwrite functions if needed
-- e.g. divisionFactor if there are other modes
-- or if the default mode is different

return CustomEarnings
