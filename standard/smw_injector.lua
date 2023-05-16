---
-- @Liquipedia
-- wiki=commons
-- page=Module:Smw/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

--- @class SmwInjector
local Injector = Class.new()

function Injector:adjust(smwData, ...)
	return smwData
end

return Injector
