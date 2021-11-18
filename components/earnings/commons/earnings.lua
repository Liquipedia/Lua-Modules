---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomEarnings = Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true})

-- overwrite functions if needed
-- e.g. divisionFactor if there are other modes
-- or if the default mode is different

return Class.export(CustomEarnings)
